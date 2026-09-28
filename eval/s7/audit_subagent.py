#!/usr/bin/env python3
"""Audit a sub-agent author's transcript and write the trimmed log kept with a run.

A sub-agent author (runs 4 and 5) is not sandboxed: it shares the eval
session's shell and files, so nothing but its own choice keeps it from reading
`mvp_tasks.py` or the references. This audit is what checks that choice. The
transcript is the sub-agent's JSONL log; tool calls are `tool_use` blocks in
assistant messages. Allowed, and nothing else:

- Read of the prompt file, or of `repair-<n>.md` in the author's directory;
- Write of `answer-<n>.md` in the author's directory, whose content must be
  the file that was scored (its SHA-256 is compared with the kept copy);
- the hand-back at the end.

Each kept `solutions-<n>.json`, which is what `score` read, must also be the
previous round's solutions updated with the tasks `extract` finds in
`answer-<n>.md`, so a merge between rounds cannot change what was scored.

    audit_subagent.py LOG.jsonl --prompt P --dir D [--kept K] > transcript.json

`--dir` is where the author wrote (as its log records it); `--kept` is where
the answers are kept now, when they were moved. Exits 1 if any call is flagged.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness import extract  # noqa: E402


def audit(events: list[dict], prompt: Path, run_dir: Path, kept: Path) -> tuple[dict, list[str]]:
    reads = {str(prompt)}
    answer = re.compile(re.escape(str(run_dir)) + r"/answer-[1-9]\.md")
    repair = re.compile(re.escape(str(run_dir)) + r"/repair-[1-9]\.md")
    calls, models, times, bad = [], set(), [], []
    for ev in events:
        if ev.get("timestamp"):
            times.append(ev["timestamp"])
        msg = ev.get("message") or {}
        if ev.get("type") != "assistant":
            continue
        if msg.get("model"):
            models.add(msg["model"])
        for b in msg.get("content") or []:
            if not isinstance(b, dict) or b.get("type") != "tool_use":
                continue
            name, inp = b.get("name"), b.get("input") or {}
            path = str(inp.get("file_path", ""))
            rec = {"at": ev.get("timestamp"), "tool": name}
            if name == "Read" and (path in reads or repair.fullmatch(path)):
                rec["path"] = Path(path).name
            elif name == "Write" and answer.fullmatch(path):
                content = str(inp.get("content", ""))
                rec.update(path=Path(path).name, content_chars=len(content),
                           content_sha256=hashlib.sha256(content.encode()).hexdigest())
                copy = kept / Path(path).name
                if not copy.is_file() or hashlib.sha256(copy.read_bytes()).hexdigest() != rec["content_sha256"]:
                    bad.append(f"{copy}: not what the author wrote")
            elif name == "SubagentHandback":
                rec["input"] = {"message": str(inp.get("message", ""))[:200]}
            else:
                rec["input"] = inp
                bad.append(f"{name}: {json.dumps(inp)[:200]}")
            calls.append(rec)
    bad += solutions_mismatch(kept)
    log = {"note": "Trimmed log of the author sub-agent: every tool call it made, with written "
                   "content reduced to a hash. The full answers are the answer-*.md files next to this one.",
           "models": sorted(models), "started": min(times, default=None),
           "finished": max(times, default=None), "tool_calls": calls, "flagged": bad}
    return log, bad


def solutions_mismatch(kept: Path) -> list[str]:
    """Each kept solutions-N.json that is not solutions-(N-1) updated with the
    tasks extracted from answer-N.md (Codex, on #147)."""
    bad, prev, n = [], {}, 1
    while (kept / f"answer-{n}.md").is_file():
        want = {**prev, **extract((kept / f"answer-{n}.md").read_text())}
        sol = kept / f"solutions-{n}.json"
        if sol.is_file():
            got = json.loads(sol.read_text())
            if got != want:
                diff = sorted(k for k in set(got) | set(want) if got.get(k) != want.get(k))
                bad.append(f"{sol}: not the answers as written (tasks {', '.join(diff)[:200]})")
            prev = got
        else:
            prev = want
        n += 1
    return bad


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    cli.add_argument("log", type=Path)
    cli.add_argument("--prompt", type=Path, required=True)
    cli.add_argument("--dir", type=Path, required=True)
    cli.add_argument("--kept", type=Path)
    a = cli.parse_args()
    events = [json.loads(l) for l in a.log.read_text().splitlines() if l.strip()]
    log, bad = audit(events, a.prompt, a.dir, a.kept or a.dir)
    print(json.dumps(log, indent=2))
    for b in bad:
        print("FLAGGED", b, file=sys.stderr)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
