#!/usr/bin/env python3
"""Excerpt of the output-limit continuation from each author's raw session log
(reviewer's request on #245). context-seen.json records the item only as kind
`other`, 183 characters; this prints, for every author in agent-ids.txt, each
log record whose message text holds "Output token limit hit": its line, type,
timestamp and length, with the stop reason of the last assistant record
before it as logged (a streamed reply may log a record with none), then each
distinct text of the item. The raw logs are this session's sub-agent transcripts, which are not
committed; continuation.txt is this script's output, kept so the per-arm counts
in results.md rest on committed evidence.
  continuation.py LOG_DIR > continuation.txt"""
import json, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MARK = "Output token limit hit"


def texts(o):
    c = (o.get("message") or {}).get("content")
    return [c] if isinstance(c, str) else [x.get("text", "") for x in c or [] if isinstance(x, dict)]


def main():
    logs = Path(sys.argv[1])
    ids = [l.split()[:2] for l in (HERE / "agent-ids.txt").read_text().splitlines() if l.strip() and not l.startswith("#")]
    voids = {l.split()[0] for l in (HERE / "voids.txt").read_text().splitlines() if l.strip() and not l.startswith("#")}
    seen = set()
    for name, agent in sorted(ids):
        lines = (logs / f"agent-{agent}.jsonl").read_text().splitlines()
        hits = []
        for k, line in enumerate(lines):
            o = json.loads(line)
            for t in texts(o):
                if MARK in t:
                    prev = next((json.loads(p) for p in reversed(lines[:k]) if json.loads(p).get("type") == "assistant"), {})
                    hits.append(f"line {k + 1}, {o.get('type')}, {o.get('timestamp')}, {len(t)} characters, "
                                f"after an assistant record with stop_reason {(prev.get('message') or {}).get('stop_reason')}")
                    seen.add(t)
        print(f"{name} ({'void' if name in voids else 'kept'}, agent {agent}): {len(hits)}" + "".join(f"\n  {h}" for h in hits))
    print(f"\nDistinct texts of the item across these logs: {len(seen)}")
    for t in sorted(seen):
        print(t)


if __name__ == "__main__":
    main()
