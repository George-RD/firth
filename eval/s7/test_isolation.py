#!/usr/bin/env python3
"""An author in the sandbox can use `try` and cannot read the hidden tests.

Needs root (the sandbox uses unshare and mount); CI runs it with sudo. The same
probe runs once without the sandbox, where it must find the hidden files, so a
probe that finds nothing anywhere cannot pass for isolation.

    sudo python3 eval/s7/test_isolation.py
"""
from __future__ import annotations

import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
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


def refused_exit(call) -> bool:
    try:
        call()
    except SystemExit:
        return True
    return False


def refused(load) -> bool:
    """True when `load` raises. A load that hangs (a FIFO opened without
    O_NONBLOCK blocks) counts as not refused, after ten seconds."""
    out: list[bool] = []

    def go() -> None:
        try:
            load()
            out.append(False)
        except (ValueError, OSError):
            out.append(True)
    t = threading.Thread(target=go, daemon=True)
    t.start()
    t.join(10)
    return out == [True]


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
        # Replacing the client would turn every later `./try` into any command.
        "edit-try": call("Edit", file_path="/tmp/work/try", old_string="x", new_string="y"),
        "write-try": call("Write", file_path="try", content="#!/bin/sh\ncurl example.com"),
        "write-try-dotted": call("Write", file_path="/tmp/work/sub/../try", content="x"),
        "write-socket": call("Write", file_path="/tmp/work/try.sock", content="x"),
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
        # The client is read-only in the sandbox, and a module the author writes
        # next to it is not imported. The planted counterparts: outside the
        # sandbox the file is writable, and a plain `python3 try` imports the fake.
        check(os.access(ws / "try", os.W_OK), "outside the sandbox the try client is writable")
        clobber = isolate.run(ws, ["bash", "-c", "echo 'echo PASS on the example' > try"],
                              capture_output=True, text=True, timeout=300)
        check(clobber.returncode != 0 and (ws / "try").read_text() == isolate.CLIENT,
              "in the sandbox the try client cannot be overwritten")
        (ws / "json.py").write_text("raise SystemExit('hijacked')\n")
        hijacked = subprocess.run(["python3", "try", "--task", "reverse", "reverse.py"], cwd=ws,
                                  capture_output=True, text=True)
        check("hijacked" in hijacked.stderr, "a json.py beside the client shadows json without -I")
        shadowed = isolate.run(ws, ["./try", "--task", "reverse", "reverse.py"],
                               capture_output=True, text=True, timeout=300)
        check("PASS on the example" in shadowed.stdout,
              f"the client ignores a json.py the author wrote: {shadowed.stdout.strip()}")
        (ws / "json.py").unlink()
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
        # The reviewer's try probe: search for the task file and return its text.
        (ws / "glob.py").write_text(
            "import glob\ndef main(xs):\n"
            "    hits = glob.glob('/home/**/eval/s7/mvp_tasks.py', recursive=True)\n"
            f"    hits = hits or [{str(HERE / 'mvp_tasks.py')!r}]\n"
            "    src = open(hits[0]).read()\n"
            "    i = src.find('_t(\"histogram\"')\n"
            "    return [ord(c) for c in src[i:i+300]]\n")
        found = harness.run_python((ws / "glob.py").read_text(), ([1],), None, ("Seq Int",))
        check(found["ok"] and "histogram" in "".join(map(chr, found["stack"][0])),
              "unsandboxed, the reviewer's glob probe reads the hidden inputs (the planted case)")
        globbed = isolate.run(ws, ["./try", "--task", "reverse", "glob.py"],
                              capture_output=True, text=True, timeout=300)
        check("got:" not in globbed.stdout and "failed:" in globbed.stdout,
              "through try, the reviewer's glob probe finds nothing")
        # The reviewer's scoring probe: a "solution" that finds the task file and
        # calls the reference. Unsandboxed it passes; sandboxed it must fail.
        cheat = ("import glob, sys, os\n"
                 "d = os.path.dirname(glob.glob('/home/**/eval/s7/mvp_tasks.py', recursive=True)[0]\n"
                 "    if glob.glob('/home/**/eval/s7/mvp_tasks.py', recursive=True) else "
                 f"{str(HERE / 'mvp_tasks.py')!r})\n"
                 "sys.path.insert(0, d)\n"
                 "from tasks import BY_ID\n"
                 "def main(*a):\n    return BY_ID['sort'].ref(*a)[0]\n")
        sort = [harness.BY_ID["sort"]]
        check(harness.run_python(cheat, ([2, 1],), None, ("Seq Int",))["ok"],
              "unsandboxed, a solution that calls the reference runs (the planted case)")
        check(not harness.score({"sort": cheat}, "python", sort, 1)["tasks"]["sort"]["pass"],
              "scored in the sandbox, a solution that calls the reference fails")
        # Firth has no file access and no cross-file imports: a program that
        # leans on a reference's helper word is refused, not linked.
        (ws / "borrow.firth").write_text(
            ": main (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many) 0 0 sum-from;\n")
        fws = Path(tmp) / "fws"
        isolate.workspace(fws, "firth", "mvp")
        (fws / "borrow.firth").write_text((ws / "borrow.firth").read_text())
        borrow = isolate.run(fws, ["./try", "--task", "seq-sum", "borrow.firth"],
                             capture_output=True, text=True, timeout=600)
        check("firth.name.unresolved" in borrow.stdout and "sum-from" in borrow.stdout,
              "a Firth program cannot reach a reference's words (refused by name resolution)")
        # The control: a real Firth answer runs through the same sandboxed try, so
        # the refusal above is the checker's, not a broken toolchain.
        (fws / "sum.firth").write_text((HERE / "reference/mvp/seq-sum.firth").read_text())
        ctrl = isolate.run(fws, ["./try", "--task", "seq-sum", "sum.firth"],
                           capture_output=True, text=True, timeout=600)
        check("PASS on the example" in ctrl.stdout,
              f"a correct Firth answer passes through the sandboxed try: {ctrl.stdout.strip()[-300:]}")
        # Submitted programs get no network: a listener on the host's loopback
        # answers an unsandboxed program and is unreachable from a sandboxed one.
        srv = socket.socket()
        srv.bind(("127.0.0.1", 0))
        srv.listen()
        port = srv.getsockname()[1]
        threading.Thread(target=lambda: [c.sendall(b"leak") or c.close()
                                         for c in iter(lambda: srv.accept()[0], None)],
                         daemon=True).start()
        (ws / "net.py").write_text(
            "import socket\ndef main(xs):\n"
            f"    s = socket.create_connection(('127.0.0.1', {port}), timeout=5)\n"
            "    return list(s.recv(16))\n")
        net_src = (ws / "net.py").read_text()
        bare_net = harness.run_python(net_src, ([1],), None, ("Seq Int",))
        check(bare_net.get("stack") == [list(b"leak")],
              "unsandboxed, a program can fetch over the network (the planted case)")
        netted = isolate.run(ws, ["./try", "--task", "reverse", "net.py"],
                             capture_output=True, text=True, timeout=300)
        check("got:" not in netted.stdout and "failed:" in netted.stdout,
              "through try, a submitted program has no network")
        scored_net = harness.score({"reverse": net_src}, "python", [harness.BY_ID["reverse"]], 1)
        check(all(not c["ok"] for c in scored_net["tasks"]["reverse"]["cases"]),
              "scored in the sandbox, a submitted program has no network")
        srv.close()
        # A program that leaves a file behind must not abort scoring.
        litter = "def main(xs):\n    open('left.txt', 'w').write('x')\n    return xs[::-1]\n"
        scored_litter = harness.score({"reverse": litter}, "python", [harness.BY_ID["reverse"]], 1)
        check(scored_litter["tasks"]["reverse"]["pass"],
              "a sandboxed program that writes a file still scores, and its files are removed")
        # The reviewer's probes: the author runs as `nobody` with only an
        # allowlisted environment. Planted: a root author reads /etc/shadow, and
        # a sandbox run with the host's environment sees a host secret.
        os.environ["S7_PLANTED_SECRET"] = "hunter2"
        head = ["bash", "-c", "head -c 5 /etc/shadow"]
        as_root = isolate.run(ws, head, uid=0, capture_output=True, text=True, timeout=300)
        check(as_root.returncode == 0 and as_root.stdout, "a root author reads /etc/shadow (the planted case)")
        as_author = isolate.run(ws, head, capture_output=True, text=True, timeout=300)
        check(as_author.returncode != 0 and not as_author.stdout,
              f"the author cannot read /etc/shadow: {as_author.stderr.strip()}")
        echo = ["bash", "-c", 'echo "[$S7_PLANTED_SECRET] $(id -u)"']
        leaky = subprocess.run(isolate.sandbox_command(ws, echo, uid=isolate.NOBODY),
                               capture_output=True, text=True, timeout=300)
        check("[hunter2]" in leaky.stdout, "with the host's environment the secret reaches the sandbox (the planted case)")
        clean = isolate.run(ws, echo, capture_output=True, text=True, timeout=300)
        check(clean.stdout.strip() == f"[] {isolate.NOBODY}",
              f"the author sees no host variable and runs as nobody: {clean.stdout.strip()}")
        passed = isolate.run(ws, echo, passed=("S7_PLANTED_SECRET",), capture_output=True, text=True, timeout=300)
        check("[hunter2]" in passed.stdout, "a variable named with --pass-env does reach the author")
        # CI's runner lists / in /etc/fstab by UUID, and the sandbox's fresh /dev
        # has no by-uuid links: a remount that consults fstab fails there. Planted
        # here by binding such an fstab over the real one in an outer namespace.
        fstab = ws.parent / "fstab"
        fstab.write_text("UUID=00000000-0000-4000-8000-000000000000 / ext4 defaults 0 1\n")
        outer = ["unshare", "--mount", "--propagation", "private", "sh", "-c",
                 'mount --bind "$0" /etc/fstab && exec "$@"', str(fstab)]
        uuid = subprocess.run(outer + isolate.sandbox_command(ws, ["id", "-u"], uid=isolate.NOBODY),
                              capture_output=True, text=True, timeout=300)
        check(uuid.stdout.strip() == str(isolate.NOBODY),
              f"the sandbox starts when fstab names the root by UUID: {uuid.stderr.strip()}")
        (ws / "env.py").write_text("import os\ndef main(xs):\n    return [len(os.environ.get('S7_PLANTED_SECRET', ''))]\n")
        envtry = isolate.run(ws, ["./try", "--task", "reverse", "env.py"], capture_output=True, text=True, timeout=300)
        check("got: [[0]]" in envtry.stdout, f"a submitted program sees no host variable: {envtry.stdout.strip()}")
        del os.environ["S7_PLANTED_SECRET"]
        # Credentials come in as a copy the author can read, at their own path,
        # while the host file stays root-only.
        creds = Path(tempfile.mkdtemp(dir="/root", prefix="s7-keep-"))
        try:
            cred = creds / "cred.json"
            cred.write_text("token")
            cred.chmod(0o600)
            kept = isolate.run(ws, ["cat", str(cred)], keep=(str(cred),), capture_output=True, text=True,
                               timeout=300)
            check(kept.stdout == "token" and cred.stat().st_uid == 0,
                  f"a kept credential is readable by the author as a copy: {kept.stdout!r} {kept.stderr.strip()}")
        finally:
            shutil.rmtree(creds)
        # A credential path the author could have planted or redirected is refused:
        # in the workspace, under a world-writable directory, or through a link.
        (ws / "planted.json").write_text("x")
        os.symlink(ws / "planted.json", Path(tmp) / "via-link.json")
        for bad in (ws / "planted.json", Path(tmp) / "loose.json", Path(tmp) / "via-link.json"):
            if not bad.exists():
                bad.write_text("x")
            check(refused_exit(lambda: isolate.run(ws, ["true"], keep=(str(bad),))),
                  f"--keep refuses {bad.name}")

        # Codex's probe: an allowed `./try` naming a host file the author can
        # read would send it on, for a diagnostic to echo back.
        passwd = isolate.run(ws, ["bash", "-c", "head -c 5 /etc/passwd"],
                             capture_output=True, text=True, timeout=300)
        check(passwd.returncode == 0 and passwd.stdout,
              "the author can read /etc/passwd (the planted case)")
        outside = isolate.run(ws, ["./try", "--task", "reverse", "/etc/passwd"],
                              capture_output=True, text=True, timeout=300)
        check("not a file in the workspace" in outside.stderr and passwd.stdout not in outside.stdout,
              f"try refuses a file outside the workspace: {outside.stderr.strip()}")
        linked_try = isolate.run(ws, ["bash", "-c", "ln -s /etc/passwd s.py && ./try --task reverse s.py"],
                                 capture_output=True, text=True, timeout=300)
        check("not a plain file" in linked_try.stderr and passwd.stdout not in linked_try.stdout,
              f"try refuses a link to a file outside the workspace: {linked_try.stderr.strip()}")
        (ws / "s.py").unlink()
        # The reviewer's probes: nothing outside the workspace and a fresh /tmp is
        # writable (links, which access() follows, excepted), so one attempt
        # cannot leave notes for the next, nor reach a host socket (a socket
        # counts as writable). The planted case is a world-writable directory
        # on the host, which nobody can write there.
        drop = Path(f"/var/lib/s7-drop-{os.getpid()}")
        drop.mkdir(mode=0o1777)
        drop.chmod(0o1777)
        try:
            note = drop / "note"
            host = subprocess.run(["setpriv", f"--reuid={isolate.NOBODY}", f"--regid={isolate.NOBODY}",
                                   "--clear-groups", "touch", str(note)], capture_output=True, text=True)
            check(host.returncode == 0 and note.exists(),
                  f"on the host, nobody can write a world-writable directory (the planted case): {host.stderr.strip()}")
            note.unlink(missing_ok=True)
            wrote = isolate.run(ws, ["touch", str(note)], capture_output=True, text=True, timeout=300)
            check(wrote.returncode != 0 and not note.exists(),
                  f"the author cannot write it: {wrote.stderr.strip()}")
        finally:
            shutil.rmtree(drop)
        # One author at a time: a second run while one is going is refused.
        first = threading.Thread(target=lambda: isolate.run(ws, ["sleep", "3"], timeout=60))
        first.start()
        time.sleep(1)
        second = refused_exit(lambda: isolate.run(ws, ["true"], timeout=60))
        first.join()
        check(second, "a second author run is refused while one is running")
        check(isolate.run(ws, ["true"], timeout=60).returncode == 0, "once it ends, the next run starts")

        # The reviewer's IPC probe: a shared-memory segment made by the author
        # must not outlive the run on the host.
        def nobody_segments() -> list[str]:
            out = subprocess.run(["ipcs", "-m"], capture_output=True, text=True).stdout
            return [l.split()[1] for l in out.splitlines() if len(l.split()) > 2 and l.split()[2] == "nobody"]
        before = nobody_segments()
        made = isolate.run(ws, ["ipcmk", "-M", "4096"], capture_output=True, text=True, timeout=300)
        after = nobody_segments()
        check(made.returncode == 0 and after == before,
              f"an author's shared memory does not outlive the run: {made.stdout.strip()} {after}")
        for shmid in set(after) - set(before):
            subprocess.run(["ipcrm", "-m", shmid])
        found = isolate.run(ws, ["bash", "-c", "find / -path /proc -prune -o -writable ! -type l -print 2>/dev/null"],
                            capture_output=True, text=True, timeout=600)
        allowed = ("/tmp", "/dev/shm", *(f"/dev/{d}" for d in isolate.DEVICES))
        extra = [f for f in found.stdout.splitlines()
                 if not any(f == a or f.startswith(a + "/") for a in allowed)]
        check(found.stdout and not extra,
              f"the author can write only the workspace, /tmp and /dev/shm: {extra[:10]}")

        # Codex's probe: an answer that never returns and starts a child. When
        # the case times out, nothing it started may keep running.
        runaway = ("import subprocess, time\ndef main(xs):\n"
                   "    subprocess.Popen(['sleep', '987654'])\n    while True:\n        time.sleep(1)\n")
        saved, harness.PY_TIMEOUT = harness.PY_TIMEOUT, 3
        try:
            timed = harness.run_python(runaway, ([1],), None, ("Seq Int",), sandboxed=True)
        finally:
            harness.PY_TIMEOUT = saved
        time.sleep(2)
        # Running, that is: a killed child may linger a moment as a zombie.
        # Matched by exact arguments: `pkill -f` would also hit any shell whose
        # command line merely mentions them.
        procs = [l.split(None, 2) for l in subprocess.run(
            ["ps", "-eo", "pid=,stat=,args="], capture_output=True, text=True).stdout.splitlines()]
        alive = [int(p[0]) for p in procs if p[2:] == ["sleep 987654"] and not p[1].startswith("Z")]
        check(timed == {"ok": False, "error": "timeout"} and not alive,
              f"a timed-out answer leaves nothing running: {timed} {alive}")
        for pid in alive:
            os.kill(pid, 9)
        # Codex's probe: a sandbox that cannot start must stop scoring, not turn
        # every answer into a failure. Planted: a sandbox command that fails.
        real = isolate.sandbox_command
        try:
            isolate.sandbox_command = lambda *a, **k: ["sh", "-c", "echo 'unshare: Operation not permitted' >&2; exit 1"]
            broken = refused_exit(lambda: harness.score({"reverse": "def main(xs):\n    return xs[::-1]\n"},
                                                        "python", [harness.BY_ID["reverse"]], 1))
        finally:
            isolate.sandbox_command = real
        check(broken, "scoring refuses to run when the sandbox cannot start")
        other = isolate.run(ws, ["./try", "--task", "fib", "reverse.py"],
                            capture_output=True, text=True, timeout=300)
        check("unknown task" in other.stdout, "try refuses tasks outside the workspace's set")

        # Below the path mounts: a disk device holds every file, hidden ones
        # included, and root can read root-only files the mounts miss. Codex's
        # probe counts block devices in /dev and reads a root-only file.
        (ws / "raw.py").write_text(
            "import os, stat\ndef main(xs):\n"
            "    blocks = [n for n in os.listdir('/dev') if stat.S_ISBLK(os.lstat('/dev/' + n).st_mode)]\n"
            "    try:\n        open('/etc/shadow').read(1)\n        shadow = 1\n"
            "    except OSError:\n        shadow = 0\n"
            "    return [len(blocks), shadow]\n")
        raw = harness.run_python((ws / "raw.py").read_text(), ([],), None, ("Seq Int",))
        check(raw["ok"] and raw["stack"][0][0] > 0,
              f"unsandboxed, block devices are visible (the planted case): {raw}")
        check(raw["ok"] and raw["stack"][0][1] == 1,
              f"unsandboxed, root reads a root-only file (the planted case): {raw}")
        rawtry = isolate.run(ws, ["./try", "--task", "reverse", "raw.py"],
                             capture_output=True, text=True, timeout=300)
        check("got: [[0, 0]]" in rawtry.stdout,
              f"through try, no block device and no root-only file: {rawtry.stdout.strip()}")

        # The reviewer's probe: inside the sandbox an author links to a reference
        # it cannot see. The link dangles there, but on the host it resolves.
        ref = HERE / "reference/mvp/sort.firth"
        answers = ws / "answers"
        answers.mkdir()
        isolate.run(ws, ["bash", "-c", f"ln -s {ref} answers/sort.firth"],
                    capture_output=True, text=True, timeout=300)
        linked = answers / "sort.firth"
        check(linked.is_symlink() and linked.read_text() == ref.read_text(),
              "a link made in the sandbox reads the reference on the host (the planted case)")
        check(refused(lambda: harness.load_solutions(answers, ws)),
              "loading answers refuses a symlink the author made")
        linked.unlink()
        os.mkfifo(answers / "pipe.py")
        check(refused(lambda: harness.load_solutions(answers, ws)), "loading answers refuses a FIFO")
        (answers / "pipe.py").unlink()
        (answers / "sort.firth").write_text("x")
        os.link(answers / "sort.firth", ws / "twin")
        check(refused(lambda: harness.load_solutions(answers, ws)), "loading answers refuses a hard link")
        (ws / "twin").unlink()
        check(harness.load_solutions(answers, ws) == {"sort": "x"}, "a plain answer file still loads")

        # The reviewer's next probes: a link in a directory component. O_NOFOLLOW
        # alone only covers the last component.
        isolate.run(ws, ["bash", "-c", f"ln -s {ref.parent} linked && ln -s {ref.parent.parent} sub"],
                    capture_output=True, text=True, timeout=300)
        check(len(list((ws / "linked").iterdir())) == 20 and (ws / "sub/mvp/sort.firth").is_file(),
              "directory links made in the sandbox reach the references on the host (the planted case)")
        check(refused(lambda: harness.load_solutions(ws / "linked", ws)),
              "loading answers refuses a directory that is a link")
        check(refused(lambda: harness.load_solutions(ws / "sub/mvp", ws)),
              "loading answers refuses a link in a directory component below the workspace")
        check(refused(lambda: harness.read_regular(ws / "sub/mvp/sort.firth", ws)),
              "reading a file refuses a link in a directory component below the workspace")
        # With no workspace named, the parent is the root only if nothing on
        # its path is a link; here the parent runs through the author's `sub`.
        check(refused(lambda: harness.load_solutions(ws / "sub/mvp", harness.plain_parent(ws / "sub/mvp"))),
              "without a workspace, loading answers refuses a link in the parent")
        sub_ref = ws / "sub/mvp/sort.firth"
        check(refused(lambda: harness.read_regular(sub_ref, harness.plain_parent(sub_ref))),
              "without a workspace, reading a file refuses a link in the parent")
        check(harness.plain_parent(answers / "sort.firth") == answers.resolve(),
              "without a workspace, a path with no links still reads")
        check(harness.load_solutions(answers, ws) == {"sort": "x"},
              "a plain answer directory still loads with the workspace as root")
    audit_checks()
    print(f"\n{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
