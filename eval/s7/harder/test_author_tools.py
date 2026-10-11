#!/usr/bin/env python3
"""Checks for `author_tools.py`, the check that every author had exactly
Read, Write and the hand-back.

The logs here are written by hand in the shape of a sub-agent's raw session
log (`agent-<id>.meta.json` and `agent-<id>.jsonl`), not made by the check.
A clean author passes, and each planted log is refused for its own reason:
an extra session-messaging tool, a deferred tool, a missing Write, the wrong
agent type, no tool list, a moved working directory, a log line with no
working directory, a missing log, an empty id list, an author that ran but
is not listed (with or without a meta file), a name or id listed twice, no
probe row, a malformed row, half a log, a meta file with no type, and a
missing or empty log directory. A bad author is refused even if its sample
was voided. Of the two real probe logs in
`runs/2026-10-11-tool-probe/`, the built-in type with Read and Edit is
refused for its type and its Edit, and the `s7-harder-author` passes. Its
calls must show it read `probe-prompt.md` and wrote `tools-seen.txt`; an
altered copy of either, a tampered Write input and an extra call each fail.

    python3 eval/s7/harder/test_author_tools.py
"""
from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import author_tools  # noqa: E402

CWD = "/home/user/firth"
GOOD = ["Read", "Write", "SubagentHandback"]


def write_log(d: Path, agent: str, tools=GOOD, agent_type="s7-harder-author",
              delta=None, cwds=(CWD,), snapshot=True, nocwd=False) -> None:
    (d / f"agent-{agent}.meta.json").write_text(json.dumps(
        {"agentType": agent_type, "model": "sonnet"}))
    lines = [{"type": "user", "cwd": cwds[0]},
             {"type": "attachment", "cwd": cwds[0],
              "attachment": {"type": "prompt_snapshot", "systemPrompt": []}}]
    if delta is not None:
        lines.append({"type": "attachment", "cwd": cwds[0],
                      "attachment": {"type": "deferred_tools_delta", "addedNames": delta,
                                     "readdedNames": [], "removedNames": []}})
    lines.append({"type": "assistant", "cwd": cwds[-1]})
    if snapshot:
        lines.append({"type": "attachment", "cwd": cwds[-1], "attachment": {
            "type": "prompt_snapshot",
            "tools": [{"name": t, "description": "", "schema": {}} for t in tools]}})
    if nocwd:
        del lines[-2]["cwd"]
    (d / f"agent-{agent}.jsonl").write_text("".join(json.dumps(l) + "\n" for l in lines))


def run(argv: list[str]) -> tuple[int, str]:
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = author_tools.main(argv)
    return code, out.getvalue()


def expect(name: str, argv: list[str], code: int, needle: str, failures: list[str]) -> None:
    got, out = run(argv)
    if got != code or needle not in out:
        failures.append(f"{name}: exit {got} (wanted {code}), wanted {needle!r} in:\n{out}")


def provenance(lines: list[dict], prompt: str, seen: str) -> list[str]:
    """Why the probe log's calls do not show that the author read `prompt`
    and wrote `seen` (empty if they do)."""
    calls = [c for l in lines for c in l.get("tool_calls", [])]
    results = [r["content"] for l in lines if isinstance(l.get("content"), list)
               for r in l["content"] if r.get("type") == "tool_result"]
    names = [c["name"] for c in calls]
    if names != ["Read", "Write", "SubagentHandback"]:
        return [f"real s7-harder-author probe: calls {names}"]
    errors = []
    shown = "".join(l.split("\t", 1)[1] + "\n" for l in results[0].split("\n") if "\t" in l)
    if shown.rstrip("\n") != prompt.rstrip("\n"):
        errors.append("real s7-harder-author probe: Read result is not probe-prompt.md")
    if calls[1]["input"]["content"] != seen:
        errors.append("real s7-harder-author probe: Write content is not tools-seen.txt")
    return errors


def tamper(lines: list[dict], tool: str, key, value) -> list[dict]:
    """A copy of `lines` with `tool`'s input `key` set to `value`, or, with no
    key, that call made twice."""
    out = json.loads(json.dumps(lines))
    for l in out:
        for i, c in enumerate(l.get("tool_calls", [])):
            if c["name"] == tool:
                if key is None:
                    l["tool_calls"].insert(i, json.loads(json.dumps(c)))
                else:
                    c["input"][key] = value
                return out
    raise AssertionError(f"no {tool} call to tamper with")


def main() -> int:
    failures: list[str] = []
    with tempfile.TemporaryDirectory() as t:
        logs = Path(t)
        write_log(logs, "good")
        write_log(logs, "good2")
        write_log(logs, "extra", tools=GOOD + ["mcp__claude-code-remote__send_message"])
        write_log(logs, "deferred", delta=["SendMessage"])
        write_log(logs, "nowrite", tools=["Read", "SubagentHandback"])
        write_log(logs, "dup", tools=GOOD + ["Read"])
        write_log(logs, "type", agent_type="s7-author")
        write_log(logs, "nolist", snapshot=False)
        write_log(logs, "moved", cwds=(CWD, "/home/user/firth-ds"))
        write_log(logs, "elsewhere", cwds=("/home/user/firth-ds",))
        write_log(logs, "emptydelta", delta=[])
        write_log(logs, "nocwd", nocwd=True)

        def probe(agent, code, needle):
            expect(agent, ["--logs", t, "--cwd", CWD, "--probe", agent], code, needle, failures)

        probe("good", 0, "tools=Read,SubagentHandback,Write")
        probe("emptydelta", 0, "ok: every author")
        probe("extra", 1, "tool list is ['Read', 'SubagentHandback', 'Write', "
                          "'mcp__claude-code-remote__send_message']")
        probe("deferred", 1, "deferred tools added: ['SendMessage']")
        probe("nowrite", 1, "tool list is ['Read', 'SubagentHandback'], not")
        probe("dup", 1, "tool list is ['Read', 'Read', 'SubagentHandback', 'Write']")
        probe("type", 1, "agent type is 's7-author', not 's7-harder-author'")
        probe("nolist", 1, "no tool list in the log")
        probe("moved", 1, "working directory ['/home/user/firth', '/home/user/firth-ds']")
        probe("elsewhere", 1, "working directory ['/home/user/firth-ds']")
        probe("absent", 1, "no log for agent absent")
        probe("nocwd", 1, "line 3: no working directory")

        # A run directory holds only the logs of the sub-agents that ran.
        rd = logs / "run"
        rd.mkdir()
        r = str(rd)
        ids = rd.parent / "agent-ids.txt"
        voids = rd.parent / "voids.txt"
        for agent in ("p1", "good", "good2"):
            write_log(rd, agent)
        ids.write_text("# name agent\nprobe p1\nsonnet-firth-1 good\nsonnet-python-1 good2\n")
        expect("run", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 0,
               "ok: every author", failures)
        # An author that ran with a bad tool list but was left out of the list.
        write_log(rd, "extra", tools=GOOD + ["mcp__claude-code-remote__send_message"])
        expect("omitted bad author", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "agent extra ran in this session but is not in", failures)
        # Listed under another author's id, so its own log is never read.
        ids.write_text("probe p1\nsonnet-firth-1 good\nhaiku-firth-2 good\nsonnet-python-1 good2\n")
        expect("duplicate id", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "agent id good is listed twice", failures)
        ids.write_text("probe p1\nsonnet-firth-1 good\nsonnet-firth-1 extra\nsonnet-python-1 good2\n")
        expect("duplicate name", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "name sonnet-firth-1 is listed twice", failures)
        # Listed, the bad author refuses the run.
        ids.write_text("probe p1\nsonnet-firth-1 good\nhaiku-firth-2 extra\nsonnet-python-1 good2\n")
        expect("run with a bad author", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "refused: 1 problem(s)", failures)
        # A voided sample's author is still checked: the run had a wrong tool
        # list whether or not that sample counts. --voids is not an option.
        voids.write_text("haiku-firth-2 audit flag\n")
        expect("voided bad author", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "refused: 1 problem(s)", failures)
        try:
            with contextlib.redirect_stderr(io.StringIO()):
                run(["--logs", r, "--cwd", CWD, "--ids", str(ids), "--voids", str(voids)])
            failures.append("--voids accepted: it would let a voided author skip the check")
        except SystemExit:
            pass
        # The probe must be listed once.
        ids.write_text("sonnet-firth-1 good\nsonnet-python-1 good2\nhaiku-firth-2 extra\n")
        expect("no probe row", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "must list the probe author once", failures)
        # A row that is not "name agent-id".
        ids.write_text("probe p1\nsonnet-firth-1 good\nsonnet-python-1\nhaiku-firth-2 extra\n")
        expect("malformed row", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "row 'sonnet-python-1' in", failures)
        # An unlisted sub-agent whose log has no meta file still counts as run.
        (rd / "agent-extra.meta.json").unlink()
        ids.write_text("probe p1\nsonnet-firth-1 good\nsonnet-python-1 good2\n")
        expect("unlisted log without meta", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "agent extra ran in this session but is not in", failures)
        # Listed, half a log is refused.
        ids.write_text("probe p1\nsonnet-firth-1 good\nsonnet-python-1 good2\nhaiku-firth-2 extra\n")
        expect("half a log", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "no log for agent extra", failures)
        # A meta file with no agent type.
        (rd / "agent-extra.jsonl").unlink()
        write_log(rd, "notype", agent_type=None)
        ids.write_text("probe p1\nsonnet-firth-1 good\nsonnet-python-1 good2\nhaiku-firth-2 notype\n")
        expect("no agent type", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "agent type is None, not 's7-harder-author'", failures)
        # A log directory that is missing, or empty, checks nobody's tools.
        expect("missing log dir", ["--logs", str(logs / "absent"), "--cwd", CWD,
                                   "--ids", str(ids)], 1, "no log for agent p1", failures)
        (logs / "empty").mkdir()
        expect("empty log dir", ["--logs", str(logs / "empty"), "--cwd", CWD,
                                 "--ids", str(ids)], 1, "no log for agent p1", failures)
        ids.write_text("# nothing\n")
        expect("empty ids", ["--logs", r, "--cwd", CWD, "--ids", str(ids)], 1,
               "names no author", failures)

    real = HERE / "runs" / "2026-10-11-tool-probe"
    expect("real probe log", ["--logs", str(real), "--cwd", "/home/user",
                              "--probe", "a973715484d11fd44"], 1,
           "tool list is ['Edit', 'Read', 'SubagentHandback'], not", failures)
    _, out = run(["--logs", str(real), "--cwd", "/home/user", "--probe", "a973715484d11fd44"])
    if out != (real / "check-output.txt").read_text():
        failures.append("real probe log: output differs from check-output.txt")
    # The real s7-harder-author probe has exactly the allowed tools.
    expect("real s7-harder-author probe", ["--logs", str(real), "--cwd", "/home/user/firth",
                                           "--probe", "aeaa153e26921b4be"], 0,
           "type=s7-harder-author model=haiku cwd=/home/user/firth "
           "tools=Read,SubagentHandback,Write", failures)
    _, out = run(["--logs", str(real), "--cwd", "/home/user/firth", "--probe", "aeaa153e26921b4be"])
    if out != (real / "tool-probe.txt").read_text():
        failures.append("real s7-harder-author probe: output differs from tool-probe.txt")
    # Its log's own calls show where probe-prompt.md and tools-seen.txt came
    # from: the Read result is the prompt, and the Write content is the list.
    lines = [json.loads(l) for l in (real / "agent-aeaa153e26921b4be.jsonl").read_text().splitlines()]
    prompt = (real / "probe-prompt.md").read_text()
    seen = (real / "tools-seen.txt").read_text()
    failures += provenance(lines, prompt, seen)
    # Planted: an altered copy of each file, and a tampered call, each fail.
    planted = [
        ("altered prompt", lines, prompt.replace("no task", "no task at all"), seen,
         "Read result is not probe-prompt.md"),
        ("altered list", lines, prompt, seen.replace("Write", "Edit"),
         "Write content is not tools-seen.txt"),
        ("tampered Write input", tamper(lines, "Write", "content", "Read\nEdit\n"), prompt, seen,
         "Write content is not tools-seen.txt"),
        ("extra call", tamper(lines, "Write", None, None), prompt, seen,
         "calls ['Read', 'Write', 'Write', 'SubagentHandback']"),
    ]
    for name, ls, pr, sn, needle in planted:
        got = provenance(ls, pr, sn)
        if len(got) != 1 or needle not in got[0]:
            failures.append(f"planted {name}: wanted only {needle!r}, got {got}")

    for f in failures:
        print("FAIL", f)
    print(f"{'FAILED' if failures else 'ok'}: author tool-list check")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
