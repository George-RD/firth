#!/usr/bin/env python3
"""Checks for `author_tools.py`, the check that every kept author had exactly
Read, Write and the hand-back.

The logs here are written by hand in the shape of a sub-agent's raw session
log (`agent-<id>.meta.json` and `agent-<id>.jsonl`), not made by the check.
A clean author passes, and each planted log is refused for its own reason:
an extra session-messaging tool, a deferred tool, a missing Write, the wrong
agent type, no tool list, a moved working directory, a missing log, and an
empty id list. A voided author is not checked. The real probe log in
`runs/2026-10-11-tool-probe/` (a built-in agent type with Read and Edit) is
refused for its type and its Edit.

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
              delta=None, cwds=(CWD,), snapshot=True) -> None:
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

        def probe(agent, code, needle):
            expect(agent, ["--logs", t, "--cwd", CWD, "--probe", agent], code, needle, failures)

        probe("good", 0, "tools=Read,SubagentHandback,Write")
        probe("emptydelta", 0, "ok: every kept author")
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

        ids = logs / "agent-ids.txt"
        voids = logs / "voids.txt"
        ids.write_text("# name agent\nsonnet-firth-1 good\nsonnet-python-1 good2\n")
        expect("run", ["--logs", t, "--cwd", CWD, "--ids", str(ids)], 0,
               "ok: every kept author", failures)
        # One bad author among good ones refuses the run.
        ids.write_text("sonnet-firth-1 good\nhaiku-firth-2 extra\nsonnet-python-1 good2\n")
        expect("run with a bad author", ["--logs", t, "--cwd", CWD, "--ids", str(ids)], 1,
               "refused: 1 author(s)", failures)
        # The same author voided is listed and not checked.
        voids.write_text("haiku-firth-2 audit flag\n")
        expect("voided bad author", ["--logs", t, "--cwd", CWD, "--ids", str(ids),
                                     "--voids", str(voids)], 0,
               "haiku-firth-2 extra: void, not checked", failures)
        ids.write_text("# nothing\n")
        expect("empty ids", ["--logs", t, "--cwd", CWD, "--ids", str(ids)], 1,
               "names no author", failures)

    real = HERE / "runs" / "2026-10-11-tool-probe"
    expect("real probe log", ["--logs", str(real), "--cwd", "/home/user",
                              "--probe", "a973715484d11fd44"], 1,
           "tool list is ['Edit', 'Read', 'SubagentHandback'], not", failures)
    _, out = run(["--logs", str(real), "--cwd", "/home/user", "--probe", "a973715484d11fd44"])
    if out != (real / "check-output.txt").read_text():
        failures.append("real probe log: output differs from check-output.txt")

    for f in failures:
        print("FAIL", f)
    print(f"{'FAILED' if failures else 'ok'}: author tool-list check")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
