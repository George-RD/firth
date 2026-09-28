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

    audit_subagent.py LOG.jsonl --prompt P --dir D --rounds R [--kept K] > transcript.json

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


def audit(events: list[dict], prompt: Path, run_dir: Path, kept: Path, rounds: int,
          lang: str = "firth") -> tuple[dict, list[str]]:
    reads = {str(prompt)}
    answer = re.compile(re.escape(str(run_dir)) + r"/answer-([1-9][0-9]*)\.md")
    repair = re.compile(re.escape(str(run_dir)) + r"/repair-([1-9][0-9]*)\.md")
    calls, models, times, bad = [], set(), [], []
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
            if name == "Read" and (path in reads or (r and int(r[1]) <= rounds)):
                rec["path"] = Path(path).name
            elif name == "Write" and w and int(w[1]) <= rounds + 1:
                content = str(inp.get("content", ""))
                rec.update(path=Path(path).name, content_chars=len(content),
                           content_sha256=hashlib.sha256(content.encode()).hexdigest())
                copy = kept / Path(path).name
                if not copy.is_file() or hashlib.sha256(copy.read_bytes()).hexdigest() != rec["content_sha256"]:
                    bad.append(f"{copy}: not what the author wrote")
            elif name == "SubagentHandback":
                rec["input"] = {"message": str(inp.get("message", ""))[:200]}
            else:
                rec["input"] = inp
                bad.append(f"{name}: {json.dumps(inp)[:200]}")
            calls.append(rec)
    bad += solutions_mismatch(kept)
    bad += repair_mismatch(kept, lang)
    bad += [f"{p}: beyond the {rounds} feedback round(s) the prompt allowed"
            for p in sorted(kept.iterdir()) if beyond(p.name, rounds)]
    log = {"note": "Trimmed log of the author sub-agent: every tool call it made, with written "
                   "content reduced to a hash. The full answers are the answer-*.md files next to this one.",
           "models": sorted(models), "started": min(times, default=None),
           "finished": max(times, default=None), "tool_calls": calls, "flagged": bad}
    return log, bad


def beyond(name: str, rounds: int) -> bool:
    """A kept answer, solutions or feedback file from a round the prompt did not allow."""
    m = re.fullmatch(r"(answer|solutions|repair|results)-([0-9]+)\.(md|json)", name)
    return bool(m) and int(m[2]) > (rounds if m[1] == "repair" else rounds + 1)


def repair_mismatch(kept: Path, lang: str) -> list[str]:
    """Each kept repair-N.md that is not the feedback `harness.py repair` builds
    from that round's solutions and results."""
    bad, n = [], 1
    while (kept / f"repair-{n}.md").is_file():
        sol, res = kept / f"solutions-{n}.json", kept / f"results-{n}.json"
        if not (sol.is_file() and res.is_file()):
            bad.append(f"{kept / f'repair-{n}.md'}: its round's solutions or results are not kept")
        else:
            want = repair(json.loads(sol.read_text()), json.loads(res.read_text()), lang, select("mvp"))
            if (kept / f"repair-{n}.md").read_text().rstrip("\n") != want.rstrip("\n"):
                bad.append(f"{kept / f'repair-{n}.md'}: not the feedback its round's results give")
        n += 1
    return bad


def solutions_mismatch(kept: Path) -> list[str]:
    """Each kept solutions-N.json that is not solutions-(N-1) updated with the
    tasks extracted from answer-N.md (Codex, on #147)."""
    bad, prev, n = [], {}, 1
    while (kept / f"answer-{n}.md").is_file():
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
        n += 1
    return bad


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    cli.add_argument("log", type=Path)
    cli.add_argument("--prompt", type=Path, required=True)
    cli.add_argument("--dir", type=Path, required=True)
    cli.add_argument("--kept", type=Path)
    cli.add_argument("--rounds", type=int, required=True, help="the feedback rounds the prompt allowed")
    cli.add_argument("--lang", default="firth", choices=["firth", "python"])
    a = cli.parse_args()
    events = [json.loads(l) for l in a.log.read_text().splitlines() if l.strip()]
    log, bad = audit(events, a.prompt, a.dir, a.kept or a.dir, a.rounds, a.lang)
    print(json.dumps(log, indent=2))
    for b in bad:
        print("FLAGGED", b, file=sys.stderr)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
