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
import json
import os
import re
import socket
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

CLIENT = r'''#!/usr/bin/env python3
"""Check and run a program on a task's visible example, or on your own inputs.

    ./try --task TASK_ID FILE [--stack JSON]
"""
import argparse, json, socket, sys
from pathlib import Path
cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
cli.add_argument("--task", required=True)
cli.add_argument("file", type=Path)
cli.add_argument("--stack")
a = cli.parse_args()
req = {"task": a.task, "source": a.file.read_text(),
       "stack": None if a.stack is None else json.loads(a.stack)}
s = socket.socket(socket.AF_UNIX)
s.connect(str(Path(__file__).resolve().parent / "try.sock"))
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
    return harness.try_run(str(req.get("source", "")), lang, BY_ID[tid], stack)


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
    """Everything to cover: the fixed list plus the repository, wherever it is."""
    paths = list(HIDDEN)
    root = str(harness.ROOT)
    if not any(root == p or root.startswith(p + "/") for p in paths):
        paths.append(root)
    return paths


def sandbox_command(dir: Path, command: list[str], keep: tuple[str, ...] = ()) -> list[str]:
    """The command line that runs COMMAND in the sandbox, with the workspace at
    /tmp/work. `keep` lists files or directories to bind back in read-only (for
    example the author model's credentials), each at its own path."""
    if os.geteuid() != 0:
        raise SystemExit("the sandbox needs root (unshare and mount)")
    stage = "/run/s7-stage"
    lines = ["set -e", f"mkdir -p {stage}", f"mount -t tmpfs tmpfs {stage}",
             f"mkdir {stage}/work", f"mount --bind {q(dir)} {stage}/work"]
    for i, k in enumerate(keep):
        kind = "-d" if Path(k).is_dir() else "-f"
        lines += [f"mkdir {stage}/k{i}" if kind == "-d" else f"touch {stage}/k{i}",
                  f"mount --bind {q(k)} {stage}/k{i}"]
    for p in hidden_paths():
        lines.append(f"[ -d {q(p)} ] && mount -t tmpfs -o mode=755 tmpfs {q(p)}")
    lines += [f"mkdir -p {INSIDE}", f"mount --bind {stage}/work {INSIDE}"]
    for i, k in enumerate(keep):
        make = (f"mkdir -p {q(k)}" if Path(k).is_dir() else
                f"[ -e {q(k)} ] || {{ mkdir -p {q(str(Path(k).parent))} && touch {q(k)}; }}")
        lines += [make, f"mount --bind -o ro {stage}/k{i} {q(k)}"]
    lines += [f"umount -l {stage}", f"cd {INSIDE}",
              'exec setpriv --bounding-set=-all --inh-caps=-all --no-new-privs -- "$@"']
    return ["unshare", "--mount", "--pid", "--fork", "--mount-proc", "--propagation", "private",
            "bash", "-c", "\n".join(lines), "sandbox", *command]


def q(s: str | Path) -> str:
    return "'" + str(s).replace("'", "'\\''") + "'"


def run(dir: Path, command: list[str], keep: tuple[str, ...] = (), **kw) -> subprocess.CompletedProcess:
    stop = threading.Event()
    serve(dir, stop)
    try:
        return subprocess.run(sandbox_command(dir, command, keep), **kw)
    finally:
        stop.set()


TRY_CALL = re.compile(r"^\./try(\s[^;&|`$<>]*)?$")


def audit(events: list[dict]) -> list[str]:
    """Every tool call in an author transcript that goes beyond the workspace and
    `try`. The transcript is the author CLI's stream-json output, one event per
    line; tool calls are `tool_use` blocks in assistant messages. Allowed: `./try`
    with plain arguments, and reading or writing files inside the workspace."""
    bad = []
    for ev in events:
        content = (ev.get("message") or {}).get("content") if ev.get("type") == "assistant" else None
        for block in content if isinstance(content, list) else []:
            if block.get("type") != "tool_use":
                continue
            name, inp = block.get("name"), block.get("input") or {}
            if name == "Bash" and TRY_CALL.match(str(inp.get("command", "")).strip()):
                continue
            if name in ("Read", "Write", "Edit") and in_workspace(str(inp.get("file_path", ""))):
                continue
            bad.append(f"{name}: {json.dumps(inp)[:200]}")
    return bad


def in_workspace(path: str) -> bool:
    p = Path(INSIDE) / path if not path.startswith("/") else Path(path)
    parts = []
    for part in p.parts:
        if part == "..":
            if parts:
                parts.pop()
        elif part not in ("", "."):
            parts.append(part)
    return str(Path("/", *parts)).startswith(INSIDE + "/")


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = cli.add_subparsers(dest="cmd", required=True)
    w = sub.add_parser("workspace"); w.add_argument("dir", type=Path)
    w.add_argument("--lang", required=True, choices=["firth", "python"])
    w.add_argument("--tier", default="mvp")
    s = sub.add_parser("serve"); s.add_argument("dir", type=Path)
    au = sub.add_parser("audit"); au.add_argument("transcript", type=Path)
    r = sub.add_parser("run"); r.add_argument("dir", type=Path)
    r.add_argument("--keep", action="append", default=[])
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
        events = [json.loads(l) for l in a.transcript.read_text().splitlines() if l.strip()]
        bad = audit(events)
        print("\n".join(bad) if bad else "clean: only try and workspace files")
        return 1 if bad else 0
    elif a.cmd == "run":
        cmd = a.command[1:] if a.command[:1] == ["--"] else a.command
        return run(a.dir.resolve(), cmd, tuple(a.keep)).returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
