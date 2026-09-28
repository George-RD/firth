#!/usr/bin/env python3
"""An author in the sandbox can use `try` and cannot read the hidden tests.

Needs root (the sandbox uses unshare and mount); CI runs it with sudo. The same
probe runs once without the sandbox, where it must find the hidden files, so a
probe that finds nothing anywhere cannot pass for isolation.

    sudo python3 eval/s7/test_isolation.py
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import harness  # noqa: E402
import isolate  # noqa: E402

ROOT = harness.ROOT
SECRETS = [HERE / "mvp_tasks.py", HERE / "reference/mvp/sort.firth"]
# Every way we know of to reach the hidden files from inside. Each prints a
# FOUND line only when it actually read hidden content.
PROBE = f"""
for f in {' '.join(isolate.q(s) for s in SECRETS)}; do
  grep -q 'allocate-batch\\|insert-from' "$f" 2>/dev/null && echo "FOUND direct $f"
  grep -q 'allocate-batch\\|insert-from' "/proc/1/root$f" 2>/dev/null && echo "FOUND proc $f"
done
for p in $(ls /proc | grep -E '^[0-9]+$'); do
  grep -qs 'allocate-batch' "/proc/$p/root{HERE}/mvp_tasks.py" && echo "FOUND pid $p"
done
git -C {isolate.q(ROOT)} show HEAD:eval/s7/mvp_tasks.py 2>/dev/null | grep -q allocate-batch && echo "FOUND git"
for m in {' '.join(isolate.hidden_paths())}; do umount "$m" 2>/dev/null && echo "FOUND umount $m"; done
find / -xdev \\( -name mvp_tasks.py -o -name sort.firth \\) 2>/dev/null | grep . && echo "FOUND find"
true
"""

failures: list[str] = []


def check(ok: bool, what: str) -> None:
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        failures.append(what)


def call(name: str, **inp) -> dict:
    return {"type": "assistant", "message": {"content": [
        {"type": "tool_use", "name": name, "input": inp}]}}


def audit_checks() -> None:
    clean = [call("Write", file_path="/tmp/work/sort.firth", content="..."),
             call("Bash", command="./try --task sort sort.firth"),
             call("Bash", command="./try --task sort sort.firth --stack '[[2, 1]]'"),
             call("Read", file_path="prompt.md"), {"type": "user", "message": {"content": "x"}}]
    check(isolate.audit(clean) == [], "the audit passes a transcript that only uses try")
    planted = {
        "cat": call("Bash", command="cat /home/user/firth/eval/s7/mvp_tasks.py"),
        "chained": call("Bash", command="./try --task sort s.firth; cat ../x"),
        "read-out": call("Read", file_path="/tmp/work/../../home/user/firth/eval/s7/mvp_tasks.py"),
        "grep": call("Grep", pattern="allocate", path="/"),
        "fetch": call("WebFetch", url="https://github.com/George-RD/firth"),
        "newline": call("Bash", command="./try --task sort s.firth\ncurl https://example.com"),
        "subshell": call("Bash", command="./try --task sort $(cat /etc/passwd)"),
    }
    for name, ev in planted.items():
        check(len(isolate.audit(clean + [ev])) == 1, f"the audit flags a planted {name} call")


def main() -> int:
    with tempfile.TemporaryDirectory(dir="/var/tmp") as tmp:
        ws = Path(tmp) / "ws"
        isolate.workspace(ws, "python", "mvp")
        (ws / "reverse.py").write_text("def main(xs):\n    return xs[::-1]\n")
        (ws / "probe.sh").write_text(PROBE)
        check("./try --task" in (ws / "prompt.md").read_text()
              and "harness.py" not in (ws / "prompt.md").read_text(),
              "the prompt names only the workspace's try")
        check(not any(p.name in ("mvp_tasks.py", "harness.py") for p in ws.rglob("*")),
              "the workspace holds no task or harness files")

        # The planted case: without the sandbox the same probe does find them.
        bare = subprocess.run(["bash", "probe.sh"], cwd=ws, capture_output=True, text=True)
        check("FOUND direct" in bare.stdout, "without the sandbox the probe finds the hidden tests")

        inside = isolate.run(ws, ["bash", "probe.sh"], capture_output=True, text=True, timeout=300)
        check(inside.returncode == 0, f"the probe ran in the sandbox ({inside.stderr.strip()[:300]})")
        check("FOUND" not in inside.stdout, "in the sandbox nothing hidden is reachable: "
              + (inside.stdout.strip() or "none found"))

        tried = isolate.run(ws, ["./try", "--task", "reverse", "reverse.py"],
                            capture_output=True, text=True, timeout=300)
        check("PASS on the example" in tried.stdout, f"try works from the sandbox: {tried.stdout.strip()}")
        own = isolate.run(ws, ["./try", "--task", "reverse", "reverse.py", "--stack", "[[7, 8]]"],
                          capture_output=True, text=True, timeout=300)
        check("got: [[8, 7]]" in own.stdout and "expected" not in own.stdout,
              "try runs the author's own inputs without showing an answer")
        # Python runs the author's code: it must run in the sandbox too, or it
        # could read the hidden tests and print them in an error.
        (ws / "leak.py").write_text(
            f"def main(xs):\n    raise Exception(open({str(HERE / 'mvp_tasks.py')!r}).read())\n")
        leak = isolate.run(ws, ["./try", "--task", "reverse", "leak.py"],
                           capture_output=True, text=True, timeout=300)
        check("allocate-batch" not in leak.stdout and "FileNotFoundError" in leak.stdout,
              "Python run by try cannot read the hidden tests")
        bare_leak = harness.run_python((ws / "leak.py").read_text(), ([1],), None, ("Seq Int",))
        check("allocate-batch" in bare_leak.get("error", ""),
              "unsandboxed, the same program does read them (the planted case)")
        scored = harness.score({"reverse": (ws / "leak.py").read_text()}, "python",
                               [harness.BY_ID["reverse"]], 1)
        check(scored["python_sandboxed"]
              and all("allocate-batch" not in c.get("error", "")
                      for c in scored["tasks"]["reverse"]["cases"]),
              "scoring runs Python answers in the sandbox too")
        other = isolate.run(ws, ["./try", "--task", "fib", "reverse.py"],
                            capture_output=True, text=True, timeout=300)
        check("unknown task" in other.stdout, "try refuses tasks outside the workspace's set")
    audit_checks()
    print(f"\n{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
