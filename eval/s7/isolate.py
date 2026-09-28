#!/usr/bin/env python3
"""Keep an author away from the hidden tests and reference solutions.

An author attempt runs in a workspace that holds only what the author may see:
the prompt, the files it writes, and a `try` client. The client talks over a
Unix socket to a `try` server run by the harness outside the sandbox, so the
harness, the hidden tests (`mvp_tasks.py`) and the references
(`reference/mvp/`) stay out of the author's reach. The sandbox is a Linux mount
and PID namespace (`unshare`, run as root) whose root is built from an
allowlist: the system directories, the author CLI's install (`--tool`), copies
of its credentials (`--keep`), and a fresh /tmp, /dev and /proc, with the
workspace at /tmp/work. The host's root is dropped with pivot_root, so the
repository, its checkouts and everything else not listed do not exist inside.
The sandbox refuses to start if anything on the list would expose the
repository. All capabilities are dropped before the author's command starts.

    isolate.py workspace --lang firth --tier mvp DIR   # prompt.md + try client
    isolate.py serve DIR                               # the try server, foreground
    isolate.py run DIR [--tool D] [--keep F] -- COMMAND...  # COMMAND inside the sandbox
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
import hashlib
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

# The only host directories an author sees, each read-only at its own path,
# plus what `--tool` and `--keep` add. Everything else (the repository, /home,
# /root, /opt, /mnt, /srv, /var, the host's /tmp) is simply not in the new root.
SYSTEM = ("/usr", "/bin", "/sbin", "/lib", "/lib32", "/lib64", "/libx32", "/etc")
# Files under /etc that a container runtime mounts over: bound in as they are
# seen, so the author resolves the same hosts as the harness.
ETC_MOUNTS = ("/etc/resolv.conf", "/etc/hosts", "/etc/hostname")
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


def within(path: str, top: str) -> bool:
    """PATH is TOP or lies below it (both absolute and resolved)."""
    return os.path.commonpath([path, top]) == top


def git_lines(root: Path, *args: str, none: int | None = None) -> list[str]:
    """`git -C ROOT ARGS` output lines; exit status NONE means no lines. Fails
    closed: a checkout whose layout cannot be read is not run, since we could
    not tell what it would expose."""
    try:
        p = subprocess.run(["git", "-c", "safe.directory=*", "-C", str(root), *args],
                           capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError) as e:
        raise SystemExit(f"cannot read the repository's layout to keep it out of the sandbox: {e}")
    if p.returncode == none:
        return []
    if p.returncode != 0:
        raise SystemExit(f"cannot read the repository's layout to keep it out of the sandbox: "
                         f"git {' '.join(args)}: {p.stderr.strip()}")
    return p.stdout.splitlines()


def git_storage(root: Path) -> list[str]:
    """The git directory, common directory and object alternates behind ROOT."""
    if not (root / ".git").exists():
        return []
    dirs = [os.path.realpath(d) for d in git_lines(
        root, "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir")]
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


def repository_paths(root: Path) -> list[str]:
    """Every path that holds the hidden tests or leads to them: the repository,
    its git storage, its main checkout and other worktrees, remotes that are
    local paths, and any checkout enclosing one of these. Nothing allowed into
    the sandbox may be one of them, lie inside one, or contain one."""
    top = os.path.realpath(root)
    paths = [top, *git_storage(root)]
    if (root / ".git").exists():
        paths += [os.path.realpath(l.split(" ", 1)[1])
                  for l in git_lines(root, "worktree", "list", "--porcelain") if l.startswith("worktree ")]
        # `git config --get-regexp` exits 1 when there is no remote at all.
        for line in git_lines(root, "config", "--get-regexp", r"^remote\..*\.(push)?url$", none=1):
            url = line.split(" ", 1)[1] if " " in line else ""
            local = url[len("file://"):] if url.startswith("file://") else url
            if local.startswith(("/", ".")) or (local and ":" not in local):
                paths.append(os.path.realpath(os.path.join(top, local)))
    for p in list(paths):
        for up in Path(p).parents:
            if (up / ".git").exists():
                paths.append(str(up))
    return sorted(set(paths))


def check_exposure(dir: Path, sources: list[str]) -> None:
    """Refuse to start when anything the sandbox would show (a system directory,
    a tool, a credential, the workspace) is, holds, or lies inside a path of the
    repository. The paths come from the repository the harness runs from."""
    repo = repository_paths(harness.ROOT)
    for s in [os.path.realpath(dir), *sources]:
        for p in repo:
            if within(p, s) or within(s, p):
                raise SystemExit(f"the sandbox would expose {p} through {s}; move one of them")


def allowed_sources(tools: tuple[str, ...]) -> list[tuple[str, str]]:
    """(host path, path in the sandbox) for each system directory and tool, the
    host path resolved so a link cannot redirect it. A system directory that is
    a link on the host (/bin -> usr/bin) is recreated as the same link."""
    out = []
    for t in (*SYSTEM, *tools):
        if t not in SYSTEM and os.path.realpath(t) != os.path.normpath(t):
            raise SystemExit(f"--tool {t}: name the real, absolute path, with no link on it")
        if os.path.lexists(t) and not (t in SYSTEM and os.path.islink(t)):
            out.append((os.path.realpath(t), os.path.normpath(t)))
    return out


def sandbox_command(dir: Path, command: list[str], keep: tuple[str, ...] = (),
                    network: bool = True, uid: int | None = None,
                    tools: tuple[str, ...] = ()) -> list[str]:
    """The command line that runs COMMAND in the sandbox, with the workspace at
    /tmp/work. The sandbox's root is a fresh, read-only tmpfs built from an
    allowlist: the system directories, each `tools` path (the author CLI's
    install), copies of the `keep` files (the author model's credentials, each
    at its own path), a fresh /tmp, /dev and /proc. The host's root is dropped
    with pivot_root, so anything not on the list does not exist inside. It
    refuses to build a root that would expose the repository (check_exposure).
    With `network=False` the command also gets an empty network namespace: that
    is how submitted programs run, while the author keeps its network for the
    model API. With `uid`, the command runs as that user and group instead of
    root; the author and submitted programs both run as `nobody`. Run it with
    `env=sandbox_env()`: the command sees only that environment."""
    if os.geteuid() != 0:
        raise SystemExit("the sandbox needs root (unshare and mount)")
    sources = allowed_sources(tools)
    for k in keep:
        plain_tree(k)
    check_exposure(dir, [s for s, _ in sources] + [os.path.realpath(k) for k in keep])
    stage, new = "/run/s7-stage", "/run/s7-root"
    lines = ["set -e", f"mkdir -p {stage} {new}", f"mount -t tmpfs tmpfs {stage}",
             f"mount -t tmpfs -o mode=755 tmpfs {new}"]
    # Credentials the author needs come in as copies its uid can read, not as
    # the host's files. They are staged outside the new root.
    for i, k in enumerate(keep):
        lines.append(f"cp -r --no-dereference {q(k)} {stage}/k{i}")
        if uid is not None:
            lines.append(f"chown -R {uid}:{uid} {stage}/k{i}")
    for t in SYSTEM:
        if os.path.islink(t):
            lines.append(f"ln -s {q(os.readlink(t))} {new}{q(t)}")
    # Non-recursive binds: a mount below an allowed directory is not carried in.
    for src, at in sources:
        make = "mkdir -p" if os.path.isdir(src) else "mkdir -p " + q(new + str(Path(at).parent)) + " && touch"
        lines += [f"{make} {q(new + at)}", f"mount --bind -o ro {q(src)} {q(new + at)}"]
    for f in ETC_MOUNTS:
        if os.path.isfile(f) and not os.path.islink(f):
            lines.append(f"[ -f {new}{f} ] && mount --bind -o ro {f} {new}{f}")
    # A fresh /dev with only the harmless character devices: no disk, loop or
    # memory device to read the hidden files through.
    lines.append(f"mkdir {new}/dev && mount -t tmpfs -o mode=755 tmpfs {new}/dev")
    for d in DEVICES:
        lines += [f"touch {new}/dev/{d}", f"mount --bind /dev/{d} {new}/dev/{d}"]
    lines += [f"mkdir {new}/dev/shm", f"mount -t tmpfs -o mode=1777 tmpfs {new}/dev/shm",
              f"ln -s /proc/self/fd {new}/dev/fd"]
    lines += [f"ln -s /proc/self/fd/{i} {new}/dev/{n}" for i, n in enumerate(("stdin", "stdout", "stderr"))]
    lines += [f"mkdir {new}/tmp && mount -t tmpfs -o mode=1777 tmpfs {new}/tmp",
              f"mkdir {new}{INSIDE} && mount --bind {q(dir)} {new}{INSIDE}"]
    # The client and its socket stay as the harness wrote them: an author who
    # could replace `try` could run anything through the one allowed command.
    for name in PROTECTED:
        lines.append(f"[ -e {new}{INSIDE}/{name} ] && mount --bind -o ro {new}{INSIDE}/{name} {new}{INSIDE}/{name}")
    for i, k in enumerate(keep):
        at = new + os.path.normpath(os.path.abspath(k))
        make = (f"mkdir -p {q(at)}" if Path(k).is_dir() else
                f"[ -e {q(at)} ] || {{ mkdir -p {q(str(Path(at).parent))} && touch {q(at)}; }}")
        lines += [make, f"mount --bind -o ro {stage}/k{i} {q(at)}"]
    # /proc for the sandbox's own PID namespace, then the root read-only.
    # Both mount points are named, so mount never looks the root up in fstab.
    # Its kernel knobs are read-only, and /sys is not there at all.
    lines += [f"mkdir {new}/proc {new}/.old", f"mount -t proc proc {new}/proc",
              f"mount --bind -o ro {new}/proc/sys {new}/proc/sys",
              f"[ ! -e {new}/proc/sysrq-trigger ] || mount --bind -o ro {new}/proc/sysrq-trigger {new}/proc/sysrq-trigger",
              f"mount -o remount,bind,ro {new} {new}"]
    # Swap roots and detach the host's. /.old exists only in this namespace.
    lines += [f"cd {new}", "pivot_root . .old", "umount -l /.old", f"cd {INSIDE}",
              "exec setpriv --bounding-set=-all --inh-caps=-all --no-new-privs"
              + (f" --reuid={uid} --regid={uid} --clear-groups" if uid is not None else "")
              + ' -- "$@"']
    # --kill-child alone does not stop a runaway: dropping to another uid clears
    # the death signal it sets. `contained` kills the namespace itself.
    # --ipc: System V shared memory and POSIX message queues would otherwise
    # outlive the run on the host, a channel from one attempt to the next.
    return ["unshare", "--mount", "--pid", "--ipc", "--fork", "--kill-child",
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


def mount_points() -> list[str]:
    """Every mount point this process sees, from /proc/self/mountinfo (field 5,
    with its octal escapes undone). A bind mount from the same filesystem looks
    like a plain directory to lstat, os.path.ismount and st_dev alike."""
    out = []
    for line in Path("/proc/self/mountinfo").read_text().splitlines():
        field = line.split(" ")[4]
        out.append(re.sub(r"\\([0-7]{3})", lambda m: chr(int(m.group(1), 8)), field))
    return out


def hidden_hashes() -> set[str]:
    """SHA-256 of the hidden tests and the reference solutions."""
    files = [HERE / "mvp_tasks.py", *sorted((HERE / "reference").rglob("*.firth"))]
    return {hashlib.sha256(f.read_bytes()).hexdigest() for f in files if f.is_file()}


def plain_tree(k: str) -> None:
    """Refuse a kept credential that holds anything but plain files and
    directories, or that could carry a hidden file in. A link nested in a kept
    directory could point at the repository, and copying through it would bring
    the hidden tests in; a file with a second hard link could be a hidden file
    itself (both Codex's findings); a mount at or below the kept path could
    show the repository (the reviewer's); a device or FIFO has no place among
    credentials. A kept file with the same content as a hidden file, a copy or
    a reflink, is refused by its hash. A kept file that holds part of one, or
    an encoding of it, is not caught: kept contents are trusted to be
    credentials."""
    top_path = os.path.realpath(k)
    for m in mount_points():
        if within(m, top_path):
            raise SystemExit(f"--keep {k}: {m} is a mount point at or below it")
    hidden = hidden_hashes()
    for top, dirs, files in os.walk(k, followlinks=False):
        for n in [top] + [os.path.join(top, e) for e in dirs + files]:
            st = os.lstat(n)
            if not (stat.S_ISDIR(st.st_mode) or stat.S_ISREG(st.st_mode) and st.st_nlink == 1):
                raise SystemExit(f"--keep {k}: {n} is not a plain file with one link, or a directory")
    st = os.lstat(k)
    if not (stat.S_ISDIR(st.st_mode) or stat.S_ISREG(st.st_mode) and st.st_nlink == 1):
        raise SystemExit(f"--keep {k}: not a plain file with one link, or a directory")
    kept = [k] if not stat.S_ISDIR(st.st_mode) else [
        os.path.join(t, f) for t, _, fs in os.walk(k, followlinks=False) for f in fs]
    for f in kept:
        if hashlib.sha256(Path(f).read_bytes()).hexdigest() in hidden:
            raise SystemExit(f"--keep {k}: {f} has the content of a hidden file")


def check_keep(keep: tuple[str, ...], dir: Path) -> None:
    """Refuse a credential path an author could have planted or redirected: one
    inside the workspace, one through a link, or one under a directory that
    `nobody` or anyone at all can write (something could be swapped in there)."""
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
        uid: int | None = None, tools: tuple[str, ...] = (), **kw) -> subprocess.CompletedProcess:
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
            return contained(sandbox_command(dir, command, keep, uid=uid, tools=tools), env=sandbox_env(passed), **kw)
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
    r.add_argument("--keep", action="append", default=[],
                   help="a credential file or directory; the author gets a read-only copy at its path")
    r.add_argument("--tool", action="append", default=[],
                   help="a directory the author CLI needs (its install), shown read-only at its path")
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
        return run(a.dir.resolve(), cmd, tuple(a.keep), tuple(a.pass_env), tools=tuple(a.tool)).returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
