#!/usr/bin/env python3
"""S7 run 14's author hook: stop an author's call that is not on its list, before it runs.

The skill `.claude/skills/s7-author-hook` registers a PreToolUse hook that
runs this for every tool call in the session, the runner's own included:

    python3 eval/s7/author_hook.py --state STATE --only s7-author < hook-input.json

With `--only TYPE` it decides only for calls whose hook input carries
`agent_type` TYPE (a sub-agent of that type; Claude Code adds `agent_id`
and `agent_type` to a sub-agent's hook input). Every other call passes
untouched (exit 0, no output) and is recorded in `seen.jsonl` beside STATE,
which is how `session.py` checks that the hook is registered before it
starts an author. A project sub-agent's own frontmatter hooks would be the
natural place, but Claude Code does not run them in a session that never
accepts workspace trust, which a cloud session never does
(`code.claude.com/docs/en/permissions`, "What runs before you trust a
folder"); a project skill's hooks do run there. Without `--only`, every
call is decided, as in the self-test's first half.

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

A denial is exit code 2 with the reason on stderr, which Claude Code turns
into the stopped call's result, so the author and `hook_denials` see the same
mark whatever the cause. Any failure the script can catch, including one
importing the audit (which imports the harness), denies the same way: the
hook fails closed. A crash or timeout it cannot catch lets the call run;
the audit then flags it, so it voids the sample and is reported as a hook
failure. The skill gives the hook an explicit timeout.
"""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
# `audit_subagent.HOOK_MARK`, repeated so that a denial can carry it when the
# audit cannot be imported; the self-test checks the two agree.
MARK = "[s7-author-hook]"
REASON = (f"{MARK} This call is not allowed in this evaluation, so it did not run. "
          "Use only the tools, files and command your instructions name.")
DENY = 2  # Claude Code blocks the call and shows stderr as its result


def decide(state: dict, call: dict) -> bool:
    if str(HERE) not in sys.path:
        sys.path.insert(0, str(HERE))
    from audit_subagent import HOOK_MARK, allowed, check_command
    if HOOK_MARK != MARK:
        raise ValueError(f"hook mark {MARK!r} differs from the audit's {HOOK_MARK!r}")
    run_dir = Path(state["dir"])
    checking = (check_command(Path(state["check_cmd"]), run_dir, "run14")
                if state.get("check_cmd") else None)
    return allowed(str(call.get("tool_name")), call.get("tool_input") or {},
                   Path(state["prompt"]), run_dir, int(state["rounds"]), checking)


def passed(state_path: Path, call: dict) -> tuple[int, str]:
    """A call that is not an author's: let it run, and record that the hook saw it."""
    try:
        inp = call.get("tool_input") or {}
        entry = {"at": datetime.now(timezone.utc).isoformat(), "tool_name": call.get("tool_name"),
                 "agent_type": call.get("agent_type"),
                 "command": str(inp.get("command"))[:300] if "command" in inp else None}
        state_path.parent.mkdir(parents=True, exist_ok=True)
        with open(state_path.parent / "seen.jsonl", "a") as f:
            f.write(json.dumps(entry) + "\n")
    except BaseException:
        pass  # unrecorded: `session.py` then finds the hook unregistered and stops
    return 0, ""


def main(argv: list[str], stdin: str) -> tuple[int, str]:
    """Returns the exit code and what to print on stderr: (0, "") allows the
    call, (2, REASON) stops it."""
    state, call, ok, why = None, {}, False, None
    try:
        if argv[:1] != ["--state"] or len(argv) not in (2, 4) or (len(argv) == 4 and argv[2] != "--only"):
            raise ValueError("usage: author_hook.py --state STATE [--only AGENT_TYPE]")
        if len(argv) == 4:
            call = json.loads(stdin)
            if call.get("agent_type") != argv[3]:
                return passed(Path(argv[1]), call)
        state = json.loads(Path(argv[1]).read_text())
        call = json.loads(stdin)
        ok = decide(state, call)
    except BaseException as e:  # fail closed, whatever went wrong
        ok, why = False, f"{type(e).__name__}: {e}"
    try:
        entry = {"at": datetime.now(timezone.utc).isoformat(),
                 "tool_use_id": call.get("tool_use_id"), "tool_name": call.get("tool_name"),
                 "agent_type": call.get("agent_type"), "sample": state and state.get("dir"),
                 "decision": "allow" if ok else "deny"}
        if why:
            entry["error"] = why
        with open(state["log"], "a") as f:
            f.write(json.dumps(entry) + "\n")
    except BaseException:
        pass  # no log: the audit then finds a marked result the log did not deny, and flags it
    return (0, "") if ok else (DENY, REASON)


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
            assert (code, out) == ((0, "") if want else (2, REASON)), (tool, inp, code, out)
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
        assert main(["--state", str(t / "none.json")], "{}") == (2, REASON)
        sf.write_text(json.dumps(state))
        assert main(["--state", str(sf)], "not json") == (2, REASON)
        log = [json.loads(l) for l in (t / "log.jsonl").read_text().splitlines()]
        assert len(log) == len(cases) + 5 + 1, len(log)
        assert [e["decision"] for e in log[:len(cases)]] == ["allow" if w else "deny" for *_, w in cases]
        assert log[0]["tool_use_id"] == "toolu_0"
        # As a process: a denial exits 2 with the mark on stderr, an allowed
        # call exits 0 silently, and an audit that cannot be imported denies
        # (a copy of this script beside a broken `audit_subagent.py`).
        import subprocess
        def run(script: Path, tool: str, inp: dict, tid: str):
            return subprocess.run([sys.executable, str(script), "--state", str(sf)],
                                  input=json.dumps({"tool_name": tool, "tool_input": inp,
                                                    "tool_use_id": tid}),
                                  capture_output=True, text=True, timeout=60)
        p = run(Path(__file__), "Glob", {"pattern": "*"}, "toolu_p1")
        assert (p.returncode, p.stderr.strip(), p.stdout) == (2, REASON, ""), p
        p = run(Path(__file__), "Bash", {"command": check}, "toolu_p2")
        assert (p.returncode, p.stderr, p.stdout) == (0, "", ""), p
        broken = t / "broken"
        broken.mkdir()
        (broken / "author_hook.py").write_text(Path(__file__).read_text())
        (broken / "audit_subagent.py").write_text("raise ImportError('planted')\n")
        p = run(broken / "author_hook.py", "Bash", {"command": check}, "toolu_p3")
        assert (p.returncode, p.stderr.strip()) == (2, REASON), p
        last = json.loads((t / "log.jsonl").read_text().splitlines()[-1])
        assert last["tool_use_id"] == "toolu_p3" and last["decision"] == "deny"
        assert "planted" in last["error"], last
        # --only s7-author, as the skill runs it: the runner's own calls and
        # other sub-agents' pass untouched and are recorded in seen.jsonl;
        # an author's call is decided as above.
        only = ["--state", str(sf), "--only", "s7-author"]
        seen = t / "seen.jsonl"
        for tool, inp, agent, want in [("Glob", {"pattern": "**/*"}, None, (0, "")),
                                       ("Bash", {"command": "ls /tmp"}, None, (0, "")),
                                       ("Glob", {"pattern": "*"}, "Explore", (0, "")),
                                       ("Glob", {"pattern": "*"}, "s7-author", (2, REASON)),
                                       ("Bash", {"command": check}, "s7-author", (0, ""))]:
            call = {"tool_name": tool, "tool_input": inp, "tool_use_id": "toolu_o"}
            if agent:
                call["agent_type"] = agent
            assert main(only, json.dumps(call)) == want, ("--only", tool, agent)
        rows = [json.loads(l) for l in seen.read_text().splitlines()]
        assert [(r["tool_name"], r["agent_type"], r["command"]) for r in rows] == [
            ("Glob", None, None), ("Bash", None, "ls /tmp"), ("Glob", "Explore", None)], rows
        # With no state file, a runner's call still passes; an author's is denied.
        gone = ["--state", str(t / "later" / "state.json"), "--only", "s7-author"]
        assert main(gone, json.dumps({"tool_name": "Bash", "tool_input": {"command": "x"}})) == (0, "")
        assert (t / "later" / "seen.jsonl").is_file()
        assert main(gone, json.dumps({"tool_name": "Bash", "tool_input": {"command": check},
                                      "agent_type": "s7-author"})) == (2, REASON)
        # Planted: a bad option list, and input that cannot be read, deny.
        assert main(["--state", str(sf), "--only"], json.dumps({"tool_name": "Glob"})) == (2, REASON)
        assert main(only, "not json") == (2, REASON)
        # The skill's own command, run by a shell as Claude Code runs it, with
        # its two paths pointed here: exit 0 for the runner, 2 with the mark
        # for an author's off-list call, and 1 (a non-blocking error, which
        # `session.py` catches as an unregistered hook) with no script.
        import re
        skill = (HERE.parents[1] / ".claude" / "skills" / "s7-author-hook" / "SKILL.md").read_text()
        cmd = json.loads(re.search(r'^ +command: (".*")$', skill, re.M).group(1))
        assert "--only s7-author" in cmd and cmd.count("/home/user/firth-r14/eval/s7/author_hook.py") == 2
        live = cmd.replace("/home/user/firth-r14/eval/s7/author_hook.py", str(Path(__file__))) \
                  .replace("/home/user/r14-hook/state.json", str(sf))
        def shell(c: str, call: dict):
            return subprocess.run(["sh", "-c", c], input=json.dumps(call), capture_output=True,
                                  text=True, timeout=60)
        p = shell(live, {"tool_name": "Bash", "tool_input": {"command": "ls"}})
        assert (p.returncode, p.stderr) == (0, ""), p
        p = shell(live, {"tool_name": "Glob", "tool_input": {"pattern": "*"}, "agent_type": "s7-author"})
        assert (p.returncode, p.stderr.strip()) == (2, REASON), p
        p = shell(live.replace(str(Path(__file__)), str(t / "missing.py")), {"tool_name": "Glob"})
        assert p.returncode == 1, p
        from audit_subagent import HOOK_MARK
        assert HOOK_MARK == MARK
        # Exit 2 is the only code that blocks: the expectations above are the
        # literal 2, not DENY, so a DENY that would fail open is caught.
        assert DENY == 2
    print("author_hook.py self-test: ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        raise SystemExit(0)
    try:
        text = sys.stdin.read()
    except BaseException:
        text = ""
    code, err = main(sys.argv[1:], text)
    if err:
        print(err, file=sys.stderr)
    raise SystemExit(code)
