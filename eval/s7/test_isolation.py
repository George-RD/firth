#!/usr/bin/env python3
"""An author in the sandbox can use `try` and cannot read the hidden tests.

Needs root (the sandbox uses unshare and mount); CI runs it with sudo. The same
probe runs once without the sandbox, where it must find the hidden files, so a
probe that finds nothing anywhere cannot pass for isolation.

    sudo python3 eval/s7/test_isolation.py
"""
from __future__ import annotations

import json
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
# FOUND line only when it actually read hidden content. This probe also runs
# once outside the sandbox, as root, so it must never change the host: no
# umount, mount or write here (unmounting is tried only inside, see main).
PROBE = f"""
for f in {' '.join(isolate.q(s) for s in SECRETS)}; do
  grep -q 'allocate-batch\\|insert-from' "$f" 2>/dev/null && echo "FOUND direct $f"
  grep -q 'allocate-batch\\|insert-from' "/proc/1/root$f" 2>/dev/null && echo "FOUND proc $f"
done
for p in $(ls /proc | grep -E '^[0-9]+$'); do
  grep -qs 'allocate-batch' "/proc/$p/root{HERE}/mvp_tasks.py" && echo "FOUND pid $p"
done
git -C {isolate.q(ROOT)} show HEAD:eval/s7/mvp_tasks.py 2>/dev/null | grep -q allocate-batch && echo "FOUND git"
find / \\( -path /proc -o -path /sys -o -path /mnt \\) -prune -o \\( -name mvp_tasks.py -o -name sort.firth \\) -print 2>/dev/null | grep . && echo "FOUND find"
true
"""

# Stores or reads back a key in the caller's user keyring (add_key, keyctl).
KEYRING_FN = """
def keyring(mode):
    libc = ctypes.CDLL(None, use_errno=True)
    # A process that inherited another uid's session keyring (sudo, pam_keyinit)
    # does not possess its own user keyring, so it could not search or read the
    # key. Join a fresh session and link the user keyring into it, as an author
    # trying this channel would.
    libc.syscall(250, 1, None)
    libc.syscall(250, 8, -4, -3)
    if mode == "put":
        return 1 if libc.syscall(248, b"user", b"s7note", b"S7-NOTE", 7, -4) > 0 else 0
    kid = libc.syscall(250, 10, -4, b"user", b"s7note", 0)
    buf = ctypes.create_string_buffer(16)
    return 1 if kid > 0 and libc.syscall(250, 11, kid, buf, 16) > 0 and buf.value == b"S7-NOTE" else 0
"""
KEYRING = "import ctypes, sys\n" + KEYRING_FN + """
r = keyring(sys.argv[1])
print(("put " if sys.argv[1] == "put" else "get ") + str(r) + (" S7-NOTE" if sys.argv[1] == "get" and r else ""))
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


GIT = ["git", "-c", "user.email=s7@probe", "-c", "user.name=s7", "-c", "safe.directory=*"]


def mirror(under: Path) -> Path:
    """A shallow bare mirror of this checkout under UNDER; `git show` reads the
    hidden tests back from it."""
    bare = under / "mirror.git"
    subprocess.run(GIT + ["clone", "-q", "--bare", "--depth", "1", f"file://{ROOT}", str(bare)], check=True)
    return bare


def repo(under: Path, name: str, path: str, text: str) -> Path:
    """A one-commit repository at UNDER/NAME whose commit adds PATH with TEXT."""
    top = under / name
    subprocess.run(GIT + ["init", "-q", str(top)], check=True)
    (top / path).parent.mkdir(parents=True, exist_ok=True)
    (top / path).write_text(text)
    subprocess.run(GIT + ["-C", str(top), "add", "-A"], check=True)
    subprocess.run(GIT + ["-C", str(top), "commit", "-qm", "s"], check=True)
    (top / path).unlink()  # only the git storage holds it now
    return top


def layout_checks(ws: Path) -> None:
    """The reviewer's probe and its relatives: the repository is a worktree of
    a clone that shares objects with a local origin, all inside an enclosing
    checkout, with a copy of the clone beside it. Each holds its own secret.
    Planted under /opt, which the sandbox never shows, and outside every path
    the old denylist sandbox hid, where plain `cat` read the main checkout."""
    base = Path(f"/opt/s7-layout-{os.getpid()}")
    outer = base / "outer"
    origin, clone, wt, copy = outer / "origin", outer / "clone", outer / "wt", outer / "copy"
    git = ["git", "-c", "user.email=s7@probe", "-c", "user.name=s7", "-c", "safe.directory=*"]

    def commit(repo: Path, name: str, text: str) -> None:
        (repo / name).write_text(text + "\n")
        subprocess.run(git + ["-C", str(repo), "add", name], check=True)
        subprocess.run(git + ["-C", str(repo), "commit", "-qm", name], check=True)
    secrets = {"S7-PARENT-SECRET": outer / "parent.txt", "S7-MAIN-SECRET": clone / "main.txt",
               "S7-SIBLING-SECRET": copy / "sibling.txt"}
    try:
        outer.mkdir(parents=True)
        subprocess.run(git + ["init", "-q", str(outer)], check=True)
        commit(outer, "parent.txt", "S7-PARENT-SECRET")
        subprocess.run(git + ["init", "-q", str(origin)], check=True)
        commit(origin, "secret.txt", "S7-GIT-SECRET")
        subprocess.run(git + ["clone", "-q", "--shared", str(origin), str(clone)], check=True)
        commit(clone, "main.txt", "S7-MAIN-SECRET")
        subprocess.run(git + ["-C", str(clone), "worktree", "add", "-q", str(wt)], check=True)
        shutil.copytree(clone, copy, symlinks=True)
        (copy / "sibling.txt").write_text("S7-SIBLING-SECRET\n")
        read = ["bash", "-c", " ".join(f"cat {p};" for p in secrets.values())
                + f" git -c safe.directory='*' --git-dir={clone}/.git show HEAD:secret.txt;"
                f" cat {clone}/.git/HEAD {wt}/.git; ls {origin}/.git/objects; true"]
        bare = subprocess.run(read, capture_output=True, text=True)
        check(all(s in bare.stdout for s in (*secrets, "S7-GIT-SECRET")),
              "outside the sandbox the main checkout, parent, sibling and git storage are readable (the planted case)")
        real_root = harness.ROOT
        try:
            harness.ROOT = wt
            found = isolate.repository_paths(wt)
            want = [wt, clone, clone / ".git", origin, origin / ".git" / "objects", outer]
            check(all(str(p) in found for p in want),
                  f"the worktree's main checkout, storage, alternates, local remote and enclosing checkout are found: {found}")
            inside = subprocess.run(isolate.sandbox_command(ws, read, uid=isolate.NOBODY),
                                    env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
            check(inside.returncode == 0 and not inside.stdout.strip(),
                  f"in the sandbox none of them exists: {inside.stdout.strip()[:300]!r} {inside.stderr.strip()[:300]}")
            # Nothing allowed may expose them: a tool naming any of these paths,
            # or a directory holding them, is refused before the sandbox starts.
            for p in (*want, clone / ".git" / "worktrees", base, copy):
                check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"], tools=(str(p),))),
                      f"the sandbox refuses to show {p}")
            check(refused_exit(lambda: isolate.sandbox_command(clone / "ws", ["true"])),
                  "the sandbox refuses a workspace inside the main checkout")
        finally:
            harness.ROOT = real_root
        # A tool unrelated to the repository comes in read-only at its path.
        tool = base / "tool"
        tool.mkdir()
        (tool / "bin").write_text("S7-TOOL\n")
        shown = subprocess.run(isolate.sandbox_command(ws, ["bash", "-c", f"cat {tool}/bin; touch {tool}/x"],
                                                       uid=isolate.NOBODY, tools=(str(tool),)),
                               env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
        check(shown.stdout.strip() == "S7-TOOL" and not (tool / "x").exists(),
              f"a --tool directory is shown read-only: {shown.stdout.strip()!r} {shown.stderr.strip()[:200]}")
        check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"], tools=("relative/tool",))),
              "a --tool path that is not absolute and real is refused")
    finally:
        shutil.rmtree(base, ignore_errors=True)
    # Copies that no git metadata links to this checkout (Codex's and the
    # reviewer's probes): an exact copy, an older revision of the task file, a
    # directory named like the references, and a bare mirror read with
    # `git show`. Under /usr/share, which is shown, each makes the sandbox
    # refuse; planted: with the scan bypassed each is readable inside.
    share = Path(f"/usr/share/s7-copies-{os.getpid()}")
    old_rev = (HERE / "mvp_tasks.py").read_text() + "\n# an older revision\n"
    marker = "S7-MIRROR-SECRET allocate-batch"

    def plant(kind: str) -> tuple[Path, str]:
        """Plant one copy under SHARE; return it and a command that reads it."""
        if kind == "exact":
            f = share / "notes.txt"
            shutil.copyfile(HERE / "mvp_tasks.py", f)
        elif kind == "old revision":
            f = share / "eval/s7/mvp_tasks.py"
            f.parent.mkdir(parents=True)
            f.write_text(old_rev)
        elif kind == "references":
            f = share / "eval/s7/reference/notes.txt"
            f.parent.mkdir(parents=True)
            f.write_text(marker + "\n")
        else:
            f = mirror(share)
            return f, f"git -c safe.directory='*' --git-dir={f} show HEAD:eval/s7/mvp_tasks.py | grep -c allocate-batch"
        return f, f"grep -c allocate-batch {f}"
    for kind in ("exact", "old revision", "references", "mirror"):
        try:
            share.mkdir()
            f, read = plant(kind)
            isolate.hidden_copies.cache_clear()
            check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"])),
                  f"the sandbox refuses a shown directory holding {kind}")
            real_scan, isolate.hidden_copies = isolate.hidden_copies, lambda sources: []
            try:
                mutant = isolate.sandbox_command(ws, ["bash", "-c", read], uid=isolate.NOBODY)
            finally:
                isolate.hidden_copies = real_scan
            leaked = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
            check(leaked.stdout.strip() not in ("", "0"),
                  f"without the scan, the {kind} copy is readable in the sandbox (the planted case): {leaked.stdout.strip()!r}")
        finally:
            shutil.rmtree(share, ignore_errors=True)
            isolate.hidden_copies.cache_clear()
    # Git storage is refused only when it holds the hidden files. The CI
    # runner ships an unrelated checkout (/etc/skel/.nvm), which is shown.
    # Planted: a repository whose commit adds a newer revision of the task
    # file, matching no known blob, is refused by its path alone.
    try:
        share.mkdir()
        other = repo(share, "other", "README", "an unrelated tool\n")
        isolate.hidden_copies.cache_clear()
        read = subprocess.run(isolate.sandbox_command(ws, ["git", "-c", "safe.directory=*", "-C", str(other),
                                                           "log", "--format=%s"], uid=isolate.NOBODY),
                              env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
        check(read.stdout.strip() == "s", f"an unrelated repository is shown: {read.stdout.strip()!r} {read.stderr[:200]}")
        repo(share, "newer", "eval/s7/mvp_tasks.py", old_rev + "# a newer revision\n")
        isolate.hidden_copies.cache_clear()
        check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"])),
              "the sandbox refuses a repository with a revision of the hidden tests it has never seen")
        shutil.rmtree(share / "newer")
        # Codex's case: the revision is in an unreachable commit (no ref, no
        # reflog), which `git log --all` would miss; and the references
        # directory on its own, in a commit whose ref was deleted.
        lost = repo(share, "lost", "README", "a tool\n")
        g = GIT + ["-C", str(lost)]
        blob = subprocess.run(g + ["hash-object", "-w", "--stdin"], input=old_rev + "# unreachable\n",
                              capture_output=True, text=True, check=True).stdout.strip()
        tree = subprocess.run(g + ["mktree"], input=f"100644 blob {blob}\tmvp_tasks.py\n",
                              capture_output=True, text=True, check=True).stdout.strip()
        commit = subprocess.run(g + ["commit-tree", tree, "-m", "lost"], capture_output=True, text=True,
                                check=True).stdout.strip()
        isolate.hidden_copies.cache_clear()
        check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"])),
              "the sandbox refuses a repository whose revision of the hidden tests is unreachable")
        real_storage, isolate.firth_storage = isolate.firth_storage, lambda top, bare: None
        try:
            isolate.hidden_copies.cache_clear()
            seen = subprocess.run(isolate.sandbox_command(ws, ["git", "-c", "safe.directory=*", "-C", str(lost), "show",
                                                           f"{commit}:mvp_tasks.py"], uid=isolate.NOBODY),
                                  env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
            check("# unreachable" in seen.stdout,
                  f"without the storage check, the unreachable revision is read by its id (the planted case): {seen.stderr[:200]}")
        finally:
            isolate.firth_storage = real_storage
        shutil.rmtree(lost)
        refs = repo(share, "refs", "eval/s7/reference/mvp/new.firth", ": new-task ;\n")
        subprocess.run(GIT + ["-C", str(refs), "branch", "-q", "keep"], check=True)
        subprocess.run(GIT + ["-C", str(refs), "checkout", "-q", "--orphan", "other"], check=True)
        subprocess.run(GIT + ["-C", str(refs), "branch", "-q", "-D", "master", "main", "keep"], capture_output=True)
        isolate.hidden_copies.cache_clear()
        check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"])),
              "the sandbox refuses a repository holding an eval/s7/reference directory it has never seen")
        shutil.rmtree(refs)
        repo(share, "newer", "eval/s7/mvp_tasks.py", old_rev + "# a newer revision\n")
        real_storage, isolate.firth_storage = isolate.firth_storage, lambda top, bare: None
        try:
            isolate.hidden_copies.cache_clear()
            check(not refused_exit(lambda: isolate.sandbox_command(ws, ["true"])),
                  "without the storage check, that repository is shown (the planted case)")
        finally:
            isolate.firth_storage = real_storage
    finally:
        shutil.rmtree(share, ignore_errors=True)
        isolate.hidden_copies.cache_clear()
    # Codex's probe: a --tool that is a single file, a renamed exact copy of a
    # reference. Refused; planted: with the scan bypassed it is readable.
    lone = Path(f"/opt/s7-tool-{os.getpid()}")
    try:
        shutil.copyfile(HERE / "reference/mvp/sort.firth", lone)
        isolate.hidden_copies.cache_clear()
        check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"], tools=(str(lone),))),
              "the sandbox refuses a --tool file holding a copy of a reference")
        real_scan, isolate.hidden_copies = isolate.hidden_copies, lambda sources: []
        try:
            mutant = isolate.sandbox_command(ws, ["cat", str(lone)], uid=isolate.NOBODY, tools=(str(lone),))
        finally:
            isolate.hidden_copies = real_scan
        leaked = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
        check(leaked.stdout == (HERE / "reference/mvp/sort.firth").read_text(),
              "without the scan, the --tool file is readable in the sandbox (the planted case)")
    finally:
        lone.unlink(missing_ok=True)
        isolate.hidden_copies.cache_clear()
    # /usr/local and /usr/src are not shown at all: an older revision and a
    # bare mirror there are unreachable. Planted: with the covering mounts
    # removed from the sandbox, both are readable.
    local = Path(f"/usr/local/s7-copies-{os.getpid()}")
    try:
        (local / "eval/s7").mkdir(parents=True)
        (local / "eval/s7/mvp_tasks.py").write_text(old_rev)
        git_dir = mirror(local)
        read = ["bash", "-c", f"grep -c allocate-batch {local}/eval/s7/mvp_tasks.py; "
                f"git -c safe.directory='*' --git-dir={git_dir} show HEAD:eval/s7/mvp_tasks.py | grep -c allocate-batch; true"]
        isolate.hidden_copies.cache_clear()
        inside = subprocess.run(isolate.sandbox_command(ws, read, uid=isolate.NOBODY), env=isolate.sandbox_env(),
                                capture_output=True, text=True, timeout=300)
        check(inside.returncode == 0 and inside.stdout.split() in ([], ["0"], ["0", "0"]),
              f"an older revision and a bare mirror under /usr/local are not in the sandbox: {inside.stdout.strip()!r}")
        mutant = isolate.sandbox_command(ws, read, uid=isolate.NOBODY)
        i = mutant.index("-c") + 1
        mutant[i] = "\n".join(l for l in mutant[i].splitlines() if not any(u in l for u in isolate.UNSHOWN))
        leaked = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
        counts = leaked.stdout.split()
        check(len(counts) == 2 and all(c != "0" for c in counts),
              f"with /usr/local shown, both are readable (the planted case): {leaked.stdout.strip()!r}")
    finally:
        shutil.rmtree(local, ignore_errors=True)
        isolate.hidden_copies.cache_clear()
    # A repository under a system directory would be shown with it. Planted
    # under /usr/local: the sandbox refuses to start; the same layout under
    # /var/tmp, which is not shown, starts.
    for top, starts in ((Path(f"/usr/local/s7-repo-{os.getpid()}"), False),
                        (Path(f"/var/tmp/s7-repo-{os.getpid()}"), True)):
        real_root = harness.ROOT
        try:
            top.mkdir()
            subprocess.run(git + ["init", "-q", str(top)], check=True)
            harness.ROOT = top
            ran = not refused_exit(lambda: isolate.sandbox_command(ws, ["true"]))
            check(ran == starts, f"a repository at {top} {'starts' if starts else 'is refused'}")
        finally:
            harness.ROOT = real_root
            shutil.rmtree(top, ignore_errors=True)


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
        # Unmounting runs only here, in the sandbox, on a mount that exists only
        # there. Even a root author has no capability left to do it.
        unmounted = isolate.run(ws, ["bash", "-c", f"umount -l {isolate.INSIDE} && echo UNMOUNTED"], uid=0,
                                capture_output=True, text=True, timeout=300)
        check("UNMOUNTED" not in unmounted.stdout, f"a root author cannot unmount: {unmounted.stderr.strip()}")
        # CI's probe: an author wrote an AppArmor file under /sys. Kernel knobs
        # are out of reach even for a root author: /sys is not in the sandbox,
        # and /proc/sys is read-only. The write puts back the value just read,
        # so it changes nothing even where it succeeds. The planted case is the
        # sandbox with its read-only /proc/sys line removed, where the host
        # lets root write the knob at all.
        knob = "/proc/sys/kernel/domainname"
        poke = ["bash", "-c", f"ls /sys && echo SYS; v=$(cat {knob}) && printf '%s\\n' \"$v\" > {knob} && echo WROTE"]
        check(os.path.isdir("/sys/kernel"), "the host has /sys (the planted case)")
        if os.access(knob, os.W_OK):
            mutant = isolate.sandbox_command(ws, poke, uid=0)
            i = mutant.index("-c") + 1
            mutant[i] = "\n".join(l for l in mutant[i].splitlines() if "/proc/sys " not in l)
            poked = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
            check("WROTE" in poked.stdout, f"without the read-only /proc/sys, a root author writes {knob} (the planted case)")
        else:
            print(f"skip the host's {knob} is read-only here, so there is no planted case")
        knobs = isolate.run(ws, poke, uid=0, capture_output=True, text=True, timeout=300)
        check("SYS" not in knobs.stdout and "WROTE" not in knobs.stdout,
              f"a root author sees no /sys and cannot write /proc/sys: {knobs.stdout.strip()!r}")
        as_author = isolate.run(ws, head, capture_output=True, text=True, timeout=300)
        check(as_author.returncode != 0 and not as_author.stdout,
              f"the author cannot read /etc/shadow: {as_author.stderr.strip()}")
        echo = ["bash", "-c", 'echo "[$S7_PLANTED_SECRET] $(id -u)"']
        leaky = subprocess.run(isolate.sandbox_command(ws, echo, uid=isolate.NOBODY),
                               capture_output=True, text=True, timeout=300)
        check("[hunter2]" in leaky.stdout, "with the host's environment the secret reaches the sandbox (the planted case)")
        clean = isolate.run(ws, echo, capture_output=True, text=True, timeout=300)
        shown = clean.stdout.strip().split()
        check(shown[:1] == ["[]"] and len(shown) == 2 and int(shown[1]) in isolate.AUTHOR_UIDS,
              f"the author sees no host variable and runs as a fresh uid: {clean.stdout.strip()}")
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
        # Codex's probe: a kept directory with a link inside it to the hidden
        # tests. Copying it through the link would bring them into the sandbox.
        # The planted case is the old copy command, which follows links.
        nest = Path(tempfile.mkdtemp(dir="/root", prefix="s7-keep-"))
        try:
            (nest / "token").write_text("token")
            os.symlink(HERE / "mvp_tasks.py", nest / "tasks")
            read_nest = ["bash", "-c", f"cat {nest}/tasks 2>/dev/null | grep -c allocate-batch"]
            check(refused_exit(lambda: isolate.run(ws, ["true"], keep=(str(nest),))),
                  "--keep refuses a directory with a link inside it")
            check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"], keep=(str(nest),))),
                  "the sandbox refuses to copy a kept directory with a link inside it")
            # The planted case bypasses both checks on kept content.
            real_plain, isolate.plain_tree = isolate.plain_tree, lambda k: None
            real_scan, isolate.hidden_copies = isolate.hidden_copies, lambda sources: []
            try:
                mutant = isolate.sandbox_command(ws, read_nest, keep=(str(nest),), uid=isolate.NOBODY)
            finally:
                isolate.plain_tree = real_plain
                isolate.hidden_copies = real_scan
            # Even past the refusal, the copy keeps the link a link, which
            # dangles inside.
            kept_link = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
            check(kept_link.stdout.strip() in ("", "0"),
                  f"copied without following links, the hidden tests stay out: {kept_link.stdout.strip()!r}")
            i = mutant.index("-c") + 1
            mutant[i] = mutant[i].replace("cp -r --no-dereference", "cp -rL")
            leaked = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
            check(leaked.stdout.strip() not in ("", "0"),
                  f"copied through the link, the hidden tests reach the sandbox (the planted case): {leaked.stdout.strip()!r}")
        finally:
            shutil.rmtree(nest)
        # Codex's next probe: a hard link to the hidden tests inside a kept
        # directory is a regular file, and a plain copy brings its content in.
        # Planted: with the check bypassed, the copy does bring it.
        hard = Path(tempfile.mkdtemp(dir="/root", prefix="s7-keep-"))
        try:
            (hard / "token").write_text("token")
            try:
                os.link(HERE / "mvp_tasks.py", hard / "tasks")
            except OSError as e:
                print(f"skip no hard link to the tests from /root here ({e}), so no hard-link case")
            else:
                check(refused_exit(lambda: isolate.run(ws, ["true"], keep=(str(hard),))),
                      "--keep refuses a directory holding a hard link")
                check(refused_exit(lambda: isolate.run(ws, ["true"], keep=(str(hard / "tasks"),))),
                      "--keep refuses a file with a second hard link")
                read_hard = ["bash", "-c", f"grep -c allocate-batch {hard}/tasks 2>/dev/null"]
                # The planted case bypasses both checks on kept content.
                real_plain, isolate.plain_tree = isolate.plain_tree, lambda k: None
                real_scan, isolate.hidden_copies = isolate.hidden_copies, lambda sources: []
                try:
                    mutant = isolate.sandbox_command(ws, read_hard, keep=(str(hard),), uid=isolate.NOBODY)
                finally:
                    isolate.plain_tree = real_plain
                    isolate.hidden_copies = real_scan
                leaked = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
                check(leaked.stdout.strip() not in ("", "0"),
                      f"without the check, a hard link brings the hidden tests in (the planted case): {leaked.stdout.strip()!r}")
        finally:
            shutil.rmtree(hard)
        # The reviewer's probe: a bind mount of eval/s7 inside a kept directory.
        # To lstat it is a plain directory, and a copy brings the tests in. It
        # runs in its own mount namespace, so the host never sees the mount.
        bind = Path(tempfile.mkdtemp(dir="/root", prefix="s7-keep-"))
        try:
            (bind / "token").write_text("token")
            (bind / "sub").mkdir()
            probe = f"""
import json, subprocess, sys
sys.path.insert(0, {str(HERE)!r})
import isolate
subprocess.run(["mount", "--bind", {str(HERE)!r}, {str(bind / "sub")!r}], check=True)
out = {{}}
try:
    isolate.sandbox_command({str(ws)!r}, ["true"], keep=({str(bind)!r},))
    out["refused"] = False
except SystemExit:
    out["refused"] = True
isolate.plain_tree = lambda k: None
isolate.hidden_copies = lambda sources: []
cmd = isolate.sandbox_command({str(ws)!r}, ["bash", "-c", "grep -c allocate-batch {bind}/sub/mvp_tasks.py"],
                              keep=({str(bind)!r},), uid=isolate.NOBODY)
out["leak"] = subprocess.run(cmd, env=isolate.sandbox_env(), capture_output=True, text=True).stdout.strip()
print(json.dumps(out))
"""
            got = subprocess.run(["unshare", "--mount", "--propagation", "private", sys.executable, "-c", probe],
                                 capture_output=True, text=True, timeout=300)
            res = json.loads(got.stdout or "{}")
            check(res.get("refused") is True, f"the sandbox refuses a kept directory with a mount inside it: {got.stderr.strip()[-200:]}")
            check(res.get("leak") not in (None, "", "0"),
                  f"without the check, the bind mount brings the hidden tests in (the planted case): {res.get('leak')!r}")
        finally:
            shutil.rmtree(bind)
        # A kept file with the content of a hidden file (a copy or a reflink) is
        # refused by its hash. Planted: with the check bypassed it comes in.
        copied = Path(tempfile.mkdtemp(dir="/root", prefix="s7-keep-"))
        try:
            (copied / "token").write_text("token")
            shutil.copyfile(HERE / "reference/mvp/sort.firth", copied / "notes")
            check(refused_exit(lambda: isolate.sandbox_command(ws, ["true"], keep=(str(copied),))),
                  "the sandbox refuses a kept copy of a reference solution")
            # The planted case bypasses both checks on kept content.
            real_plain, isolate.plain_tree = isolate.plain_tree, lambda k: None
            real_scan, isolate.hidden_copies = isolate.hidden_copies, lambda sources: []
            try:
                mutant = isolate.sandbox_command(ws, ["cat", str(copied / "notes")], keep=(str(copied),),
                                                 uid=isolate.NOBODY)
            finally:
                isolate.plain_tree = real_plain
                isolate.hidden_copies = real_scan
            leaked = subprocess.run(mutant, env=isolate.sandbox_env(), capture_output=True, text=True, timeout=300)
            check(leaked.stdout == (HERE / "reference/mvp/sort.firth").read_text(),
                  "without the check, the copy reaches the sandbox (the planted case)")
        finally:
            shutil.rmtree(copied)
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

        # Codex's keyring probe: a key stored in the user keyring by one run is
        # read back by the next. Planted: two runs forced onto one uid share it;
        # two ordinary runs, each with a fresh uid, do not. The probe links the
        # user keyring into a fresh session first: the CI runner's jobs inherit
        # a session keyring, and without the link the key cannot be read back.
        (ws / "kr.py").write_text(KEYRING)
        shared = isolate.fresh_uid()
        put = isolate.run(ws, ["python3", "kr.py", "put"], uid=shared, capture_output=True, text=True, timeout=300)
        got = isolate.run(ws, ["python3", "kr.py", "get"], uid=shared, capture_output=True, text=True, timeout=300)
        check("S7-NOTE" in got.stdout, f"two runs as one uid share its keyring (the planted case): {put.stdout.strip()} {got.stdout.strip()}")
        put = isolate.run(ws, ["python3", "kr.py", "put"], capture_output=True, text=True, timeout=300)
        got = isolate.run(ws, ["python3", "kr.py", "get"], capture_output=True, text=True, timeout=300)
        check(put.stdout.startswith("put") and "S7-NOTE" not in got.stdout,
              f"a key stored by one author run is gone for the next: {put.stdout.strip()} {got.stdout.strip()}")
        (ws / "kr.py").unlink()
        keyed = [harness.run_python(f"import ctypes\n{KEYRING_FN}\ndef main(xs):\n    return [keyring(m) for m in {mode!r}]\n",
                                    ([1],), None, ("Seq Int",), sandboxed=True) for mode in (["put"], ["get"])]
        check(keyed[0].get("stack") == [[1]] and keyed[1].get("stack") == [[0]],
              f"a key stored by one submitted program is gone for the next: {keyed}")
        # The reviewer's IPC probe: a shared-memory segment made by the author
        # must not outlive the run on the host.
        def nobody_segments() -> list[str]:
            """Every shared-memory segment on the host (authors no longer share a uid)."""
            out = subprocess.run(["ipcs", "-m"], capture_output=True, text=True).stdout
            return [l.split()[1] for l in out.splitlines() if l[:2] == "0x"]
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
        layout_checks(ws)
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
