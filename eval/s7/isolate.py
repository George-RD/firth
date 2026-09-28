#!/usr/bin/env python3
"""Keep an author away from the hidden tests and reference solutions.

An author attempt runs in a workspace that holds only what the author may see:
the prompt, the files it writes, and a `try` client. The client talks over a
Unix socket to a `try` server run by the harness outside the sandbox, so the
harness, the hidden tests (`mvp_tasks.py`) and the references
(`reference/mvp/`) stay out of the author's reach. The sandbox is a Linux mount
and PID namespace (`unshare`, run as root) in which the repository, /home,
/root, /tmp, /var/tmp, /mnt and /srv are replaced by empty directories; the
workspace appears at /tmp/work, and all capabilities are dropped before the
author's command starts, so it cannot unmount them or see outside processes.

    isolate.py workspace --lang firth --tier mvp DIR   # prompt.md + try client
    isolate.py serve DIR                               # the try server, foreground
    isolate.py run DIR -- COMMAND...                   # COMMAND inside the sandbox
    isolate.py audit transcript.jsonl                  # tool calls beyond try, if any

`run` starts the server itself. `test_isolation.py` checks that a command in
the sandbox can use `try` and cannot read the hidden tests by any path we know
of. The network is not cut off (the author model needs its API); the author's
tool permissions cover that, and `audit` checks each retained transcript for any
tool call other than `try` and workspace files, as a second line of defence.
"""
from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import signal
import socket
import stat
import subprocess
import sys
import threading
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import harness  # noqa: E402
from tasks import BY_ID  # noqa: E402

HIDDEN = ("/home", "/root", "/tmp", "/var/tmp", "/mnt", "/srv")
SOCKET = "try.sock"
INSIDE = "/tmp/work"
PROTECTED = ("try", "workspace.json")
LOCK = "/run/s7-author.lock"  # root-only directory, so no author can plant it
DEVICES = ("null", "zero", "full", "random", "urandom", "tty")
NOBODY = 65534

# `-I` keeps the workspace off the import path, so a file the author writes
# (a `json.py`, say) cannot take over the client.
CLIENT = r'''#!/usr/bin/python3 -I
"""Check and run a program on a task's visible example, or on your own inputs.

    ./try --task TASK_ID FILE [--stack JSON]
"""
import argparse, json, os, socket, stat, sys
from pathlib import Path
HERE = Path(__file__).resolve().parent


def read_here(name):
    """FILE must be a plain file in this workspace, reached without links."""
    rel = Path(os.path.relpath(os.path.normpath(os.path.abspath(name)), HERE))
    if rel.parts[:1] == ("..",) or not rel.parts:
        sys.exit(f"try: {name} is not a file in the workspace")
    fd = os.open(HERE, os.O_RDONLY | os.O_DIRECTORY)
    for i, part in enumerate(rel.parts):
        last = i == len(rel.parts) - 1
        flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | (0 if last else os.O_DIRECTORY)
        try:
            nfd = os.open(part, flags, dir_fd=fd)
        except OSError:
            sys.exit(f"try: {name} is not a plain file in the workspace")
        os.close(fd)
        fd = nfd
    st = os.fstat(fd)
    if not stat.S_ISREG(st.st_mode) or st.st_nlink != 1:
        sys.exit(f"try: {name} is not a plain file in the workspace")
    with os.fdopen(fd, encoding="utf-8") as f:
        return f.read()


cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
cli.add_argument("--task", required=True)
cli.add_argument("file")
cli.add_argument("--stack")
a = cli.parse_args()
req = {"task": a.task, "source": read_here(a.file),
       "stack": None if a.stack is None else json.loads(a.stack)}
s = socket.socket(socket.AF_UNIX)
s.connect(str(HERE / "try.sock"))
s.sendall(json.dumps(req).encode() + b"\n")
s.shutdown(socket.SHUT_WR)
print(b"".join(iter(lambda: s.recv(65536), b"")).decode())
'''


def workspace(dir: Path, lang: str, tier: str) -> None:
    dir.mkdir(parents=True, exist_ok=False)
    tasks = harness.select(tier)
    text = harness.prompt(tasks, lang, mvp=True).replace(
        harness.TRY.format(lang=lang), "./try --task <task id> <file>")
    (dir / "prompt.md").write_text(text + "\n")
    (dir / "try").write_text(CLIENT)
    (dir / "try").chmod(0o755)
    (dir / "workspace.json").write_text(json.dumps(
        {"lang": lang, "tasks": [t.id for t in tasks]}, indent=2) + "\n")


def answer(req: dict, lang: str, allowed: set[str]) -> str:
    tid = req.get("task")
    if tid not in allowed:
        return f"unknown task {tid!r}; the tasks are: {', '.join(sorted(allowed))}"
    stack = req.get("stack")
    if stack is not None and not isinstance(stack, list):
        return "--stack must be a JSON array"
    return harness.try_run(str(req.get("source", "")), lang, BY_ID[tid], stack, sandboxed=True)


def serve(dir: Path, stop: threading.Event | None = None) -> socket.socket:
    """Listen on DIR/try.sock and answer `try` requests until `stop` is set."""
    meta = json.loads((dir / "workspace.json").read_text())
    lang, allowed = meta["lang"], set(meta["tasks"])
    path = dir / SOCKET
    path.unlink(missing_ok=True)
    srv = socket.socket(socket.AF_UNIX)
    srv.bind(str(path))
    path.chmod(0o777)
    srv.listen()
    srv.settimeout(0.5)

    def handle(conn: socket.socket) -> None:
        with conn:
            data = b"".join(iter(lambda: conn.recv(65536), b""))
            try:
                out = answer(json.loads(data), lang, allowed)
            except Exception as e:  # a malformed request is the author's problem, not ours
                out = f"bad request: {e}"
            conn.sendall(out.encode())

    def loop() -> None:
        while not (stop and stop.is_set()):
            try:
                conn, _ = srv.accept()
            except socket.timeout:
                continue
            threading.Thread(target=handle, args=(conn,), daemon=True).start()
        srv.close()

    threading.Thread(target=loop, daemon=True).start()
    return srv


def hidden_paths() -> list[str]:
    """Everything to cover: the fixed list, the repository wherever it is, and
    its git storage. A worktree's git directory, the shared common directory
    and any object alternates can lie outside the repository, and `git show`
    reads the hidden tests from any of them."""
    paths = list(HIDDEN)
    for extra in (str(harness.ROOT), *git_storage(harness.ROOT)):
        if not any(extra == p or extra.startswith(p + "/") for p in paths):
            paths.append(extra)
    return paths


def git_storage(root: Path) -> list[str]:
    """The git directory, common directory and object alternates behind ROOT.
    Fails closed: a checkout whose storage cannot be resolved is not run."""
    if not (root / ".git").exists():
        return []
    try:
        out = subprocess.run(["git", "-C", str(root), "rev-parse", "--path-format=absolute",
                              "--git-dir", "--git-common-dir"],
                             capture_output=True, text=True, check=True, timeout=30).stdout
    except (OSError, subprocess.SubprocessError) as e:
        raise SystemExit(f"cannot find the repository's git storage to hide it: {e}")
    dirs = [os.path.realpath(d) for d in out.split()]
    pending = [Path(dirs[-1]) / "objects"]
    while pending:  # alternates may chain
        alt = pending.pop() / "info" / "alternates"
        if alt.is_file():
            for line in alt.read_text().splitlines():
                if line.strip() and not line.startswith("#"):
                    obj = Path(os.path.realpath(alt.parent.parent / line.strip()))
                    if str(obj) not in dirs:
                        dirs.append(str(obj))
                        pending.append(obj)
    return dirs


def sandbox_command(dir: Path, command: list[str], keep: tuple[str, ...] = (),
                    network: bool = True, uid: int | None = None) -> list[str]:
    """The command line that runs COMMAND in the sandbox, with the workspace at
    /tmp/work. `keep` lists files or directories to bind back in read-only (for
    example the author model's credentials), each at its own path. With
    `network=False` the command also gets an empty network namespace: that is how
    submitted programs run, while the author process keeps its network for the
    model API. With `uid`, the command runs as that user and group instead of
    root, so root-only files the mounts do not cover stay unreadable; the author
    and submitted programs both run as `nobody`. Run it with `env=sandbox_env()`:
    the command sees only that environment."""
    if os.geteuid() != 0:
        raise SystemExit("the sandbox needs root (unshare and mount)")
    stage = "/run/s7-stage"
    lines = ["set -e", f"mkdir -p {stage}", f"mount -t tmpfs tmpfs {stage}",
             f"mkdir {stage}/work", f"mount --bind {q(dir)} {stage}/work"]
    # Credentials the author needs come in as copies its uid can read, not as
    # the host's files.
    for i, k in enumerate(keep):
        lines.append(f"cp -rL {q(k)} {stage}/k{i}")
        if uid is not None:
            lines.append(f"chown -R {uid}:{uid} {stage}/k{i}")
    # A fresh /dev with only the harmless character devices: no disk, loop or
    # memory device to read the hidden files through, below every path mount.
    lines.append(f"mkdir {stage}/dev")
    for d in DEVICES:
        lines += [f"touch {stage}/dev/{d}", f"mount --bind /dev/{d} {stage}/dev/{d}"]
    lines.append("mount -t tmpfs -o mode=755 tmpfs /dev")
    for d in DEVICES:
        lines += [f"touch /dev/{d}", f"mount --bind {stage}/dev/{d} /dev/{d}"]
    lines += ["mkdir -p /dev/shm", "mount -t tmpfs -o mode=1777 tmpfs /dev/shm",
              "ln -sfn /proc/self/fd /dev/fd"]
    lines += [f"ln -sfn /proc/self/fd/{i} /dev/{n}" for i, n in enumerate(("stdin", "stdout", "stderr"))]
    for p in hidden_paths():
        lines.append(f"[ -d {q(p)} ] && mount -t tmpfs -o mode=755 tmpfs {q(p)}")
    lines += [f"mkdir -p {INSIDE}", f"mount --bind {stage}/work {INSIDE}"]
    # The client and its socket stay as the harness wrote them: an author who
    # could replace `try` could run anything through the one allowed command.
    for name in PROTECTED:
        lines.append(f"[ -e {INSIDE}/{name} ] && mount --bind -o ro {INSIDE}/{name} {INSIDE}/{name}")
    for i, k in enumerate(keep):
        make = (f"mkdir -p {q(k)}" if Path(k).is_dir() else
                f"[ -e {q(k)} ] || {{ mkdir -p {q(str(Path(k).parent))} && touch {q(k)}; }}")
        lines += [make, f"mount --bind -o ro {stage}/k{i} {q(k)}"]
    # Everything else read-only: remount every mount point except the workspace,
    # the fresh /tmp and /dev/shm, and /proc. Listing world-writable directories
    # instead would miss some, and one attempt could leave notes for the next.
    # A remount that fails stops the sandbox (set -e with pipefail).
    # /run holds the host's sockets (a read-only mount still lets a socket be
    # connected), so it is replaced by an empty directory, once staging is done.
    lines += [f"umount -l {stage}", "mount -t tmpfs -o mode=755 tmpfs /run"]
    lines += ["set -o pipefail",
              "awk '{print $5}' /proc/self/mountinfo | sort -u | while read -r m; do",
              '  m=$(printf "%b" "$m")',
              f'  case "$m" in /tmp|{INSIDE}|{INSIDE}/*|/dev/shm|/proc|/proc/*) continue;; esac',
              '  [ -e "$m" ] || continue  # covered by a mount above: unreachable',
              '  mount -o remount,bind,ro "$m" "$m"  # both named: no fstab lookup',
              "done"]
    lines += [f"cd {INSIDE}",
              "exec setpriv --bounding-set=-all --inh-caps=-all --no-new-privs"
              + (f" --reuid={uid} --regid={uid} --clear-groups" if uid is not None else "")
              + ' -- "$@"']
    # --kill-child alone does not stop a runaway: dropping to another uid clears
    # the death signal it sets. `contained` kills the namespace itself.
    # --ipc: System V shared memory and POSIX message queues would otherwise
    # outlive the run on the host, a channel from one attempt to the next.
    return ["unshare", "--mount", "--pid", "--ipc", "--fork", "--kill-child", "--mount-proc",
            "--propagation", "private",
            *([] if network else ["--net"]),
            "bash", "-c", "\n".join(lines), "sandbox", *command]


def sandbox_env(passed: tuple[str, ...] = ()) -> dict[str, str]:
    """The whole environment a sandboxed command gets: PATH, a UTF-8 locale, HOME
    at the workspace, and the host variables named in `passed` (the author
    model's API key, say). Nothing else from the host, so no stray token leaks."""
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "LANG": "C.UTF-8", "HOME": INSIDE}
    env.update({n: os.environ[n] for n in passed if n in os.environ})
    return env


def hand_over(dir: Path, uid: int) -> None:
    """Give the workspace to the author's uid, except the files it must not change
    (they are also mounted read-only). Links are changed, never followed."""
    for top, dirs, files in os.walk(dir, followlinks=False):
        os.lchown(top, uid, uid)
        for n in files + [d for d in dirs if os.path.islink(os.path.join(top, d))]:
            path = os.path.join(top, n)
            if top == str(dir) and n in (*PROTECTED, SOCKET):
                continue
            os.lchown(path, uid, uid)


def check_keep(keep: tuple[str, ...], dir: Path) -> None:
    """Refuse a credential path an author could have planted or redirected: one
    inside the workspace, one through a link, or one under a directory that
    `nobody` or anyone at all can write (`cp -rL` would follow what it found)."""
    work = os.path.realpath(dir)
    for k in keep:
        path = os.path.abspath(k)
        if os.path.realpath(path) != path:
            raise SystemExit(f"--keep {k}: a link on its path; name the real file")
        if path == work or path.startswith(work + "/"):
            raise SystemExit(f"--keep {k}: inside the workspace")
        p = Path(path)
        for d in [p, *p.parents]:
            st = os.lstat(d)
            if st.st_uid == NOBODY or st.st_mode & 0o002:
                raise SystemExit(f"--keep {k}: {d} is writable by the author")


def contained(command: list[str], timeout: float | None = None, input: str | None = None,
              **kw) -> subprocess.CompletedProcess:
    """subprocess.run for a sandbox command line. On a timeout it kills the
    namespace's first process, which takes every process in the PID namespace
    with it (however it forked or set its session), then raises TimeoutExpired."""
    if kw.pop("capture_output", False):
        kw["stdout"] = kw["stderr"] = subprocess.PIPE
    with subprocess.Popen(command, stdin=subprocess.PIPE if input is not None else None, **kw) as p:
        try:
            out, err = p.communicate(input, timeout=timeout)
        except subprocess.TimeoutExpired:
            for child in children(p.pid):
                os.kill(child, signal.SIGKILL)
            p.kill()
            p.communicate()
            raise
        return subprocess.CompletedProcess(p.args, p.returncode, out, err)


def children(pid: int) -> list[int]:
    return [int(d) for d in os.listdir("/proc") if d.isdigit() and ppid(int(d)) == pid]


def ppid(pid: int) -> int | None:
    try:
        return int(Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[1])
    except (OSError, IndexError, ValueError):
        return None


def q(s: str | Path) -> str:
    return "'" + str(s).replace("'", "'\\''") + "'"


def run(dir: Path, command: list[str], keep: tuple[str, ...] = (), passed: tuple[str, ...] = (),
        uid: int | None = None, **kw) -> subprocess.CompletedProcess:
    """COMMAND as the author: in the sandbox, as `nobody`, with `sandbox_env(passed)`.
    `uid` exists only so the isolation test can plant a root author."""
    uid = NOBODY if uid is None else uid
    check_keep(keep, dir)
    # One author at a time: the author shares the host's network (it needs its
    # API), so two at once could talk over loopback or an abstract socket.
    lock = os.open(LOCK, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    try:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("another author run holds the lock; attempts run one at a time") from None
        stop = threading.Event()
        serve(dir, stop)
        hand_over(dir, uid)
        try:
            return contained(sandbox_command(dir, command, keep, uid=uid), env=sandbox_env(passed), **kw)
        finally:
            stop.set()
    finally:
        os.close(lock)


# One command on one line: spaces and tabs only, no newline, no shell operators.
TRY_CALL = re.compile(r"\./try(?:[ \t][^;&|`$<>()\\\r\n]*)?")


def audit(events: list[dict]) -> list[str]:
    """Every tool call in an author transcript that goes beyond the workspace and
    `try`. The transcript is the author CLI's stream-json output, one event per
    line; tool calls are `tool_use` blocks in assistant messages. Allowed: `./try`
    with plain arguments, reading files inside the workspace, and writing them,
    except the `try` client, its socket and `workspace.json`."""
    bad = []
    for ev in events:
        content = (ev.get("message") or {}).get("content") if ev.get("type") == "assistant" else None
        for block in content if isinstance(content, list) else []:
            if block.get("type") != "tool_use":
                continue
            name, inp = block.get("name"), block.get("input") or {}
            if name == "Bash" and TRY_CALL.fullmatch(str(inp.get("command", "")).strip(" \t")):
                continue
            path = str(inp.get("file_path", ""))
            if name == "Read" and in_workspace(path):
                continue
            if name in ("Write", "Edit") and in_workspace(path) and not protected(path):
                continue
            bad.append(f"{name}: {json.dumps(inp)[:200]}")
    return bad


def in_workspace(path: str) -> bool:
    return normal(path).startswith(INSIDE + "/")


def protected(path: str) -> bool:
    """The files an author may read but never change: the client and its socket."""
    return normal(path) in {f"{INSIDE}/{n}" for n in (*PROTECTED, SOCKET)}


def normal(path: str) -> str:
    p = Path(INSIDE) / path if not path.startswith("/") else Path(path)
    parts = []
    for part in p.parts:
        if part == "..":
            if parts:
                parts.pop()
        elif part not in ("", "."):
            parts.append(part)
    return str(Path("/", *parts))


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = cli.add_subparsers(dest="cmd", required=True)
    w = sub.add_parser("workspace"); w.add_argument("dir", type=Path)
    w.add_argument("--lang", required=True, choices=["firth", "python"])
    w.add_argument("--tier", default="mvp")
    s = sub.add_parser("serve"); s.add_argument("dir", type=Path)
    au = sub.add_parser("audit"); au.add_argument("transcript", type=Path)
    au.add_argument("--workspace", type=Path, help="the author's workspace, when the transcript is in it")
    r = sub.add_parser("run"); r.add_argument("dir", type=Path)
    r.add_argument("--keep", action="append", default=[])
    r.add_argument("--pass-env", action="append", default=[],
                   help="a host variable the author needs (its API key); nothing else is passed")
    r.add_argument("command", nargs=argparse.REMAINDER)
    a = cli.parse_args()
    if a.cmd == "workspace":
        workspace(a.dir.resolve(), a.lang, a.tier)
    elif a.cmd == "serve":
        stop = threading.Event()
        serve(a.dir.resolve(), stop)
        try:
            threading.Event().wait()
        except KeyboardInterrupt:
            stop.set()
    elif a.cmd == "audit":
        events = [json.loads(l) for l in harness.read_regular(a.transcript, a.workspace or harness.plain_parent(a.transcript)).splitlines() if l.strip()]
        bad = audit(events)
        print("\n".join(bad) if bad else "clean: only try and workspace files")
        return 1 if bad else 0
    elif a.cmd == "run":
        cmd = a.command[1:] if a.command[:1] == ["--"] else a.command
        return run(a.dir.resolve(), cmd, tuple(a.keep), tuple(a.pass_env)).returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
