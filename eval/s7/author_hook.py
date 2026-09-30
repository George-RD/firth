#!/usr/bin/env python3
"""S7 run 14's author hook: stop an author's call that is not on its list, before it runs.

A PreToolUse hook in the frontmatter of the S7 author agent definition runs
this for every tool call an author makes, and for no other agent's:

    python3 eval/s7/author_hook.py --state STATE < hook-input.json

STATE is a JSON file the driver writes before it starts an author (authors
run one at a time in a session, so there is one current author):

    {"prompt": ".../arm-b/prompt-firth.md", "dir": ".../arm-b/haiku-firth-3",
     "rounds": 2, "check_cmd": ".../eval/s7/harness.py" or null,
     "log": ".../driver/hook-log.jsonl"}

The decision is `audit_subagent.allowed`, the function the audit uses, with
run 14's forms of the check command when `check_cmd` is set, so the hook and
the audit cannot disagree about what is allowed. A call on the list gets no
output, so it runs as it would have. Any other call is denied with the same
reason in both arms, which the author sees. Every decision, allow or deny,
is appended to the log with the call's `tool_use_id`, which is how the audit
tells a stopped call from one that ran (`audit_subagent.py --hook-log`).
If the state or the input cannot be read, the call is denied: the hook fails
closed.
"""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_subagent import HOOK_MARK, allowed, check_command  # noqa: E402

REASON = (f"{HOOK_MARK} This call is not allowed in this evaluation, so it did not run. "
          "Use only the tools, files and command your instructions name.")


def decide(state: dict, call: dict) -> bool:
    run_dir = Path(state["dir"])
    checking = (check_command(Path(state["check_cmd"]), run_dir, "run14")
                if state.get("check_cmd") else None)
    return allowed(str(call.get("tool_name")), call.get("tool_input") or {},
                   Path(state["prompt"]), run_dir, int(state["rounds"]), checking)


def main(argv: list[str], stdin: str) -> tuple[int, str]:
    """Returns the exit code and what to print on stdout."""
    state, call, ok, why = None, {}, False, None
    try:
        if argv[:1] != ["--state"] or len(argv) != 2:
            raise ValueError("usage: author_hook.py --state STATE")
        state = json.loads(Path(argv[1]).read_text())
        call = json.loads(stdin)
        ok = decide(state, call)
    except Exception as e:  # fail closed
        why = f"{type(e).__name__}: {e}"
    entry = {"at": datetime.now(timezone.utc).isoformat(), "tool_use_id": call.get("tool_use_id"),
             "tool_name": call.get("tool_name"), "agent_type": call.get("agent_type"),
             "sample": state and state.get("dir"), "decision": "allow" if ok else "deny"}
    if why:
        entry["error"] = why
    try:
        with open(state["log"], "a") as f:
            f.write(json.dumps(entry) + "\n")
    except Exception:
        pass  # no log: the audit then finds a marked result the log did not deny, and flags it
    if ok:
        return 0, ""
    return 0, json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                                 "permissionDecision": "deny",
                                                 "permissionDecisionReason": REASON}})


def self_test() -> None:
    import tempfile
    with tempfile.TemporaryDirectory() as t:
        t = Path(t)
        run = t / "run"
        (run / "arm-b" / "haiku-firth-1").mkdir(parents=True)
        harness = t / "firth" / "eval" / "s7" / "harness.py"
        d = run / "arm-b" / "haiku-firth-1"
        state = {"prompt": str(run / "arm-b" / "prompt-firth.md"), "dir": str(d), "rounds": 2,
                 "check_cmd": str(harness), "log": str(t / "log.jsonl")}
        sf = t / "state.json"
        sf.write_text(json.dumps(state))
        check = f"python3 {harness} check --lang firth {d}/answer-1.md"
        cases = [
            ("Bash", {"command": check}, True),
            ("Bash", {"command": check + " 2>&1 | head -50"}, True),
            ("Bash", {"command": check + ' 2>&1 | grep -E "^(## |ok$)"'}, True),
            ("Bash", {"command": check + " | wc -l"}, False),
            ("Bash", {"command": f"grep -n x {d}/answer-1.md"}, False),
            ("Bash", {"command": check.replace("answer-1", "answer-4")}, False),
            ("Bash", {"command": check, "run_in_background": True}, False),
            ("Read", {"file_path": state["prompt"]}, True),
            ("Read", {"file_path": f"{d}/answer-2.md"}, True),
            ("Read", {"file_path": f"{d}/repair-2.md"}, True),
            ("Read", {"file_path": f"{d}/repair-3.md"}, False),
            ("Read", {"file_path": "/root/.claude/projects/x/tool-results/b1.txt"}, False),
            ("Read", {"file_path": str(run / "arm-b" / "haiku-firth-2" / "answer-1.md")}, False),
            ("Edit", {"file_path": f"{d}/answer-1.md", "old_string": "a", "new_string": "b"}, True),
            ("Write", {"file_path": f"{d}/answer-3.md", "content": ""}, True),
            ("Write", {"file_path": "/tmp/fix.py", "content": ""}, False),
            ("Glob", {"pattern": "**/*"}, False),
            ("SubagentHandback", {"message": "done"}, True),
        ]
        for i, (tool, inp, want) in enumerate(cases):
            code, out = main(["--state", str(sf)], json.dumps(
                {"hook_event_name": "PreToolUse", "tool_name": tool, "tool_input": inp,
                 "tool_use_id": f"toolu_{i}", "agent_type": "s7-author"}))
            assert code == 0, (tool, inp)
            assert (out == "") == want, (tool, inp, out)
            if not want:
                o = json.loads(out)["hookSpecificOutput"]
                assert o["permissionDecision"] == "deny" and HOOK_MARK in o["permissionDecisionReason"]
        # Arm A: no check command, so no Bash, no Edit and no Read of its answer.
        sa = dict(state, check_cmd=None)
        sf.write_text(json.dumps(sa))
        for tool, inp, want in [("Bash", {"command": check}, False),
                                ("Edit", {"file_path": f"{d}/answer-1.md"}, False),
                                ("Read", {"file_path": f"{d}/answer-1.md"}, False),
                                ("Write", {"file_path": f"{d}/answer-1.md", "content": ""}, True),
                                ("Read", {"file_path": f"{d}/repair-1.md"}, True)]:
            _, out = main(["--state", str(sf)], json.dumps({"tool_name": tool, "tool_input": inp,
                                                           "tool_use_id": "toolu_a"}))
            assert (out == "") == want, ("arm A", tool, inp, out)
        # Fail closed: a missing state file or unreadable input denies.
        assert main(["--state", str(t / "none.json")], "{}")[1] != ""
        sf.write_text(json.dumps(state))
        assert main(["--state", str(sf)], "not json")[1] != ""
        log = [json.loads(l) for l in (t / "log.jsonl").read_text().splitlines()]
        assert len(log) == len(cases) + 5 + 1, len(log)
        assert [e["decision"] for e in log[:len(cases)]] == ["allow" if w else "deny" for *_, w in cases]
        assert log[0]["tool_use_id"] == "toolu_0"
    print("author_hook.py self-test: ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        raise SystemExit(0)
    code, out = main(sys.argv[1:], sys.stdin.read())
    if out:
        print(out)
    raise SystemExit(code)
