#!/usr/bin/env python3
"""Audit a sub-agent author's transcript and write the trimmed log kept with a run.

A sub-agent author (runs 4 and 5) is not sandboxed: it shares the eval
session's shell and files, so nothing but its own choice keeps it from reading
`mvp_tasks.py` or the references. This audit is what checks that choice. The
transcript is the sub-agent's JSONL log; tool calls are `tool_use` blocks in
assistant messages. Allowed, and nothing else:

- Read of the prompt file, or of `repair-<n>.md` in the author's directory;
- Write of `answer-<n>.md` in the author's directory, whose content must be
  the file that was scored (its SHA-256 is compared with the kept copy);
- the hand-back at the end.

With `--check-cmd HARNESS` (S7 run 12's arm B, whose prompt lets the author
run the checker on its own answer file), these are allowed as well:

- Bash running exactly `python3 HARNESS check --lang firth <dir>/answer-<n>.md`
  on one of the author's own answer files, and nothing else: no other
  command, path, option or shell syntax. With `--shell-forms` as well (S7
  run 13), that command may also carry these additions, in this order and
  nothing else, since each only reads the checker's own output:
  - the prefix `cd ROOT && `, where ROOT is the checkout HARNESS is in
    (`ROOT/eval/s7/harness.py`);
  - the suffix ` 2>&1`;
  - one pipe to `head -n N`, `head -N`, `tail -n N`, `tail -N`, or `grep`
    with options from `-n -i -v -c -E -A N -B N -C N` and one quoted
    pattern that does not start with `-` (in double quotes: no backquote, a
    backslash only before one of `| ( ) . ^ $ [ ]`, and `$` only before
    `"` or `|`), and after that grep, at most one more pipe to `head` or
    `tail` as above; then trailing spaces, and nothing else.
  Anything else is flagged: a file operand, any other option (`-f`, `-r`,
  `--include`), a second pipe, `;`, `&&` or `||` elsewhere, `$(`, a
  backquote, `<`, `>` or `>>`.
- Read, Write and Edit of the author's own `answer-<n>.md`, as often as it
  likes. Its writes and edits are replayed in order, and the file they leave
  must be the kept copy that was scored. A write or edit whose tool result
  is an error (an `old_string` not found, a refused write) changed nothing,
  so it is not replayed; its path is still checked. The replay matches
  `old_string` exactly; the Edit tool also accepts curly quotes for straight
  ones, so an answer holding curly quotes could be flagged although the edit
  succeeded.

A write whose tool result is an error is not compared with the kept copy in
either arm, since it wrote nothing. Only a `tool_result` block in a user-type
event, carrying the call's id, marks a call as failed. A kept `answer-<n>.md`
that no successful Write (or, with `--check-cmd`, Edit) in the log produced is
flagged.

Each kept `solutions-<n>.json`, which is what `score` read, must also be the
previous round's solutions updated with the tasks `extract` finds in
`answer-<n>.md`, so a merge between rounds cannot change what was scored.

Each kept `repair-<n>.md`, which is what the author read, must be what
`harness.py repair` builds from `solutions-<n>.json` and `results-<n>.json`,
so feedback cannot show more than the visible example (Codex, on #147).

`--rounds` is the number of feedback rounds the prompt allowed (`harness.py
prompt --rounds`): `repair-1` to `repair-<rounds>` and `answer-1` to
`answer-<rounds + 1>`. A read, write or kept file beyond that is flagged, so a
run cannot score more feedback than it reports (Codex, on #147).

    audit_subagent.py LOG.jsonl --prompt P --dir D --rounds R --lang L [--kept K]
        [--check-cmd HARNESS [--shell-forms]] > transcript.json

`--dir` is where the author wrote (as its log records it); `--kept` is where
the answers are kept now, when they were moved. Exits 1 if any call is flagged.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness import extract, repair, select  # noqa: E402


# `--shell-forms` (S7 run 13): what may follow the check command. A grep
# pattern is quoted and cannot start with `-`, so it cannot smuggle in an
# option such as `-r` (which searches the working directory) or `-f FILE`.
# In double quotes, a backslash may only escape a regex character, which the
# shell passes to grep unchanged, and `$` may only end the pattern or come
# before `|`, so nothing is expanded.
_PATTERN = (r"""(?:'(?!-)[^'\n]*'"""
            r"""|"(?!-)(?:[^"\\`$\n]|\\[|().^$\[\]]|\$(?=["|]))*")""")
_ENDS = r"(?:head|tail) (?:-n [0-9]+|-[0-9]+)"
_FILTER = (r"(?: \| (?:" + _ENDS + r"|grep(?: (?:-[nivcE]|-[ABC] [0-9]+))* " + _PATTERN
           + r"(?: \| " + _ENDS + r")?))?")


def check_command(check_cmd: Path, run_dir: Path, shell_forms: bool = False) -> re.Pattern:
    """The Bash command arm B may run; group 1 is the answer file's number."""
    core = (r"python3 " + re.escape(str(check_cmd)) + r" check --lang firth "
            + re.escape(str(run_dir)) + r"/answer-([1-9][0-9]*)\.md")
    if not shell_forms:
        return re.compile(core)
    root = re.escape(str(check_cmd.parents[2]))
    return re.compile(r"(?:cd " + root + r" && )?" + core + r"(?: 2>&1)?" + _FILTER + r" *")


def audit(events: list[dict], prompt: Path, run_dir: Path, kept: Path, rounds: int,
          lang: str, check_cmd: Path | None = None,
          shell_forms: bool = False) -> tuple[dict, list[str]]:
    reads = {str(prompt)}
    answer = re.compile(re.escape(str(run_dir)) + r"/answer-([1-9][0-9]*)\.md")
    repair = re.compile(re.escape(str(run_dir)) + r"/repair-([1-9][0-9]*)\.md")
    checking = check_command(check_cmd, run_dir, shell_forms) if check_cmd else None
    files: dict[str, str | None] = {}  # arm B: each answer file as its writes and edits leave it
    produced = set()  # answer files a successful Write or Edit of the author's made
    calls, models, times, bad = [], set(), [], []
    failed = errored(events)
    for ev in events:
        msg = ev.get("message") or {}
        if ev.get("type") != "assistant":
            continue
        # Only the author's own turns: the log also carries context the
        # sub-agent inherited from the session that started it, whose times
        # are hours earlier (Codex, on #147).
        if ev.get("timestamp"):
            times.append(ev["timestamp"])
        if msg.get("model"):
            models.add(msg["model"])
        for b in msg.get("content") or []:
            if not isinstance(b, dict) or b.get("type") != "tool_use":
                continue
            name, inp = b.get("name"), b.get("input") or {}
            path = str(inp.get("file_path", ""))
            rec = {"at": ev.get("timestamp"), "tool": name}
            r, w = repair.fullmatch(path), answer.fullmatch(path)
            own = bool(w and int(w[1]) <= rounds + 1)
            if checking and name == "Bash":
                c = checking.fullmatch(str(inp.get("command", "")))
                if c and int(c[1]) <= rounds + 1 and set(inp) <= {"command", "description", "timeout"}:
                    rec["check"] = f"answer-{c[1]}.md"
                    if shell_forms:
                        rec["command"] = str(inp["command"])
                else:
                    rec["input"] = inp
                    bad.append(f"{name}: {json.dumps(inp)[:200]}")
            elif checking and own and name in ("Read", "Write", "Edit"):
                rec["path"] = Path(path).name
                if name == "Read":
                    rec.update({k: inp[k] for k in ("offset", "limit") if k in inp})
                elif b.get("id") in failed:
                    rec["tool_error"] = True
                elif name == "Write":
                    produced.add(Path(path).name)
                    files[path] = str(inp.get("content", ""))
                    rec.update(content_chars=len(files[path]),
                               content_sha256=hashlib.sha256(files[path].encode()).hexdigest())
                else:
                    produced.add(Path(path).name)
                    files[path] = replay_edit(files.get(path), inp)
                    rec["edit_chars"] = len(str(inp.get("new_string", "")))
            elif name == "Read" and (path in reads or (r and int(r[1]) <= rounds)):
                rec["path"] = Path(path).name
                # Which part of the file the read asked for, so the log shows
                # whether the author read all of it (reviewer, on #169).
                rec.update({k: inp[k] for k in ("offset", "limit") if k in inp})
            elif name == "Write" and w and int(w[1]) <= rounds + 1:
                content = str(inp.get("content", ""))
                rec.update(path=Path(path).name, content_chars=len(content),
                           content_sha256=hashlib.sha256(content.encode()).hexdigest())
                copy = kept / Path(path).name
                if b.get("id") in failed:
                    rec["tool_error"] = True
                else:
                    produced.add(copy.name)
                    if not copy.is_file() or hashlib.sha256(copy.read_bytes()).hexdigest() != rec["content_sha256"]:
                        bad.append(f"{copy}: not what the author wrote")
            elif name == "SubagentHandback":
                # Whole, not truncated: the hand-back is evidence about what the
                # author saw (reviewer, on #181).
                rec["input"] = {"message": str(inp.get("message", ""))}
            else:
                rec["input"] = inp
                bad.append(f"{name}: {json.dumps(inp)[:200]}")
            calls.append(rec)
    for path, text in sorted(files.items()):
        copy = kept / Path(path).name
        if text is None:
            bad.append(f"{copy}: an edit of it could not be replayed")
        elif not copy.is_file() or copy.read_text() != text:
            bad.append(f"{copy}: not what the author's writes and edits left")
    # A kept answer the author's log never wrote was put there some other way
    # (reviewer, on #190).
    bad += [f"{kept / f'answer-{n}.md'}: no successful write or edit of the author's made it"
            for n in numbered(kept, "answer", "md") if f"answer-{n}.md" not in produced]
    bad += solutions_mismatch(kept)
    bad += repair_mismatch(kept, lang)
    bad += [f"{p}: beyond the {rounds} feedback round(s) the prompt allowed"
            for p in sorted(kept.iterdir()) if beyond(p.name, rounds)]
    log = {"note": "Trimmed log of the author sub-agent: every tool call it made, with written "
                   "content reduced to a hash. The full answers are the answer-*.md files next to this one.",
           "check_calls": sum("check" in c for c in calls),
           "models": sorted(models), "started": min(times, default=None),
           "finished": max(times, default=None), "tool_calls": calls, "flagged": bad}
    return log, bad


def errored(events: list[dict]) -> set[str]:
    """The ids of tool calls whose result the tool reported as an error. Only
    the harness's own tool results count: blocks in user-type events, with an
    id (reviewer, on #190)."""
    out = set()
    for ev in events:
        if ev.get("type") != "user":
            continue
        c = (ev.get("message") or {}).get("content")
        for b in c if isinstance(c, list) else []:
            if (isinstance(b, dict) and b.get("type") == "tool_result" and b.get("is_error")
                    and b.get("tool_use_id") is not None):
                out.add(b["tool_use_id"])
    return out


def replay_edit(text: str | None, inp: dict) -> str | None:
    """`text` after an Edit call, or None when it cannot be replayed: the file
    was not written first, or the old text is not in it exactly as the tool
    requires (once, unless every occurrence is replaced)."""
    old, new = str(inp.get("old_string", "")), str(inp.get("new_string", ""))
    if text is None or not old or old not in text:
        return None
    if inp.get("replace_all"):
        return text.replace(old, new)
    return text.replace(old, new, 1) if text.count(old) == 1 else None


def beyond(name: str, rounds: int) -> bool:
    """A kept answer, solutions or feedback file from a round the prompt did not allow."""
    m = re.fullmatch(r"(answer|solutions|repair|results)-([0-9]+)\.(md|json)", name)
    return bool(m) and int(m[2]) > (rounds if m[1] == "repair" else rounds + 1)


def numbered(kept: Path, kind: str, ext: str) -> list[int]:
    """The round numbers of every kept `kind-N.ext`, gaps included (Codex, on #152)."""
    return sorted(int(m[1]) for p in kept.iterdir()
                  if (m := re.fullmatch(rf"{kind}-([0-9]+)\.{ext}", p.name)))


def repair_mismatch(kept: Path, lang: str) -> list[str]:
    """Each kept repair-N.md that is not the feedback `harness.py repair` builds
    from that round's solutions and results."""
    bad = []
    for n in numbered(kept, "repair", "md"):
        sol, res = kept / f"solutions-{n}.json", kept / f"results-{n}.json"
        if not (sol.is_file() and res.is_file()):
            bad.append(f"{kept / f'repair-{n}.md'}: its round's solutions or results are not kept")
        else:
            want = repair(json.loads(sol.read_text()), json.loads(res.read_text()), lang, select("mvp"))
            if (kept / f"repair-{n}.md").read_text().rstrip("\n") != want.rstrip("\n"):
                bad.append(f"{kept / f'repair-{n}.md'}: not the feedback its round's results give")
    return bad


def solutions_mismatch(kept: Path) -> list[str]:
    """Each kept solutions-N.json that is not solutions-(N-1) updated with the
    tasks extracted from answer-N.md (Codex, on #147)."""
    bad, prev = [], {}
    last = max(numbered(kept, "answer", "md") + numbered(kept, "solutions", "json"), default=0)
    for n in range(1, last + 1):
        if not (kept / f"answer-{n}.md").is_file():
            # A gap would otherwise end the walk before later rounds were compared.
            # Keep walking so a later round's mismatch is listed too (CodeRabbit, on #152).
            bad.append(f"{kept / f'answer-{n}.md'}: missing (Codex, on #152)")
            # Later rounds build on this round's kept solutions (Codex, on #154).
            if (kept / f"solutions-{n}.json").is_file():
                prev = json.loads((kept / f"solutions-{n}.json").read_text())
            continue
        want = {**prev, **extract((kept / f"answer-{n}.md").read_text())}
        sol = kept / f"solutions-{n}.json"
        if sol.is_file():
            got = json.loads(sol.read_text())
            if got != want:
                diff = sorted(k for k in set(got) | set(want) if got.get(k) != want.get(k))
                bad.append(f"{sol}: not the answers as written (tasks {', '.join(diff)[:200]})")
            prev = got
        else:
            bad.append(f"{sol}: missing, so what was scored is not kept (Codex, on #147)")
            prev = want
    return bad


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    cli.add_argument("log", type=Path)
    cli.add_argument("--prompt", type=Path, required=True)
    cli.add_argument("--dir", type=Path, required=True)
    cli.add_argument("--kept", type=Path)
    cli.add_argument("--rounds", type=int, required=True, help="the feedback rounds the prompt allowed")
    cli.add_argument("--check-cmd", type=Path,
                     help="arm B of S7 runs 12 and 13: the harness whose `check` the author may run")
    cli.add_argument("--shell-forms", action="store_true",
                     help="arm B of S7 run 13: also allow the closed set of additions to the check "
                          "command listed above")
    cli.add_argument("--lang", required=True, choices=["firth", "python"],
                     help="the language the author wrote, which decides how its feedback is rebuilt")
    a = cli.parse_args()
    if a.shell_forms and not a.check_cmd:
        cli.error("--shell-forms needs --check-cmd")
    events = [json.loads(l) for l in a.log.read_text().splitlines() if l.strip()]
    log, bad = audit(events, a.prompt, a.dir, a.kept or a.dir, a.rounds, a.lang, a.check_cmd,
                     a.shell_forms)
    print(json.dumps(log, indent=2))
    for b in bad:
        print("FLAGGED", b, file=sys.stderr)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
