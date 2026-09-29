#!/usr/bin/env python3
"""List everything put into an author's context that the author did not fetch.

`audit_subagent.py` checks what an author *called*. That is not the whole of
what it saw: run 10's sample B8 was handed another author's name and the path
of that author's output log by a `task_status` attachment the harness injected,
without making any call (`runs/2026-09-29-control/8ea4a1d/haiku-firth-8/`).
Sample independence therefore rests on what each author was shown, not only on
what it read, so this script scans a raw author log and lists every item that
is neither

- the author's own turn (an assistant message), nor
- a result of one of the author's own tool calls, nor
- a message from the eval session that dispatched it (the run's own
  instructions, which `runs/2026-09-29-control/instructions.py` compares
  between arms).

Everything else is injected: harness reminders and nudges, environment and
model notices, context compactions, and attachments about other tasks. Each is
kept with its kind, its time and, when it names one, the other sample or task
it mentions. An item that names another sample or points at another author's
files is reported as `cross_sample`, and the exit status is 1.

    context_seen.py LOG.jsonl --sample haiku-firth-8 --label B8 > context-seen.json
    context_seen.py --self-test

The run's own instructions are recognised by their opening words, so a message
the eval session did not send cannot be mistaken for one.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# The two messages the eval session sends an author; anything else in a user
# turn was put there by the harness.
OURS = ("You are the author in a programming evaluation.",
        "The coordinator sent a message while you were working:\nFeedback round ")
SAMPLE = re.compile(r"haiku-(?:firth|python)-([0-9]+)")
TASKS = re.compile(r"/tasks/([0-9a-f]{8,})")
# How the eval session labels its authors when it starts them ("Control author
# B10"); the harness can repeat another task's label with no path (Codex, on #181).
LABEL = re.compile(r"\bauthor ([AB][0-9]+)\b")


def texts(msg: dict) -> list[str]:
    c = msg.get("content")
    if isinstance(c, str):
        return [c]
    return [b["text"] for b in c or [] if isinstance(b, dict) and b.get("type") == "text"]


def own_result(msg: dict, mine: set[str]) -> bool:
    """A tool_result for one of this author's own tool calls."""
    c = msg.get("content")
    blocks = [b for b in c or [] if isinstance(b, dict)] if isinstance(c, list) else []
    return bool(blocks) and all(b.get("type") == "tool_result" and b.get("tool_use_id") in mine
                                for b in blocks)


def kind(ev: dict, text: str) -> str:
    if ev.get("type") == "attachment":
        return "attachment:" + str((ev.get("attachment") or {}).get("type"))
    if text.startswith("[handback-send-enforce]"):
        return "handback-enforce"
    if text.startswith("[Your previous response"):
        return "nudge"
    if text.startswith("<system-reminder>"):
        return "system-reminder"
    if text.startswith("This session is being continued"):
        return "compaction"
    return "other"


def scan(events: list[dict], sample: str | None, label: str | None = None) -> dict:
    mine: set[str] = set()
    items, cross = [], []
    for line_no, ev in enumerate(events, 1):
        msg = ev.get("message") or {}
        if ev.get("type") == "assistant":
            for b in msg.get("content") or []:
                if isinstance(b, dict) and b.get("type") == "tool_use":
                    mine.add(b.get("id"))
            continue
        if msg.get("role") == "user":
            if own_result(msg, mine):
                continue
            body = "\n".join(texts(msg)) or json.dumps(msg.get("content"))
            if body.startswith(OURS):
                continue
        else:
            body = json.dumps(ev.get("attachment") or ev.get("content") or {})
        if not body:
            continue
        others = {s for s in SAMPLE.findall(body)
                  if sample is None or s != SAMPLE.search(sample)[1]}
        item = {"line": line_no, "at": ev.get("timestamp"), "kind": kind(ev, body),
                "chars": len(body)}
        labels = {l for l in LABEL.findall(body) if l != label}
        if others or labels or TASKS.search(body):
            item["cross_sample"] = True
            item["names"] = sorted(others)
            item["labels"] = sorted(labels)
            item["task_paths"] = sorted(set(TASKS.findall(body)))
            item["excerpt"] = body[:600]
            cross.append(item)
        items.append(item)
    return {"note": "Everything put into this author's context that it did not fetch itself: "
                    "the eval session's own instructions and the author's own tool results are "
                    "left out. cross_sample marks an item naming another sample or another "
                    "task's files.",
            "sample": sample, "injected": items, "cross_sample": cross}


def self_test() -> None:
    def log(*evs):
        return list(evs)

    base = log(
        {"type": "user", "timestamp": "t0",
         "message": {"role": "user", "content": OURS[0] + " write your answer"}},
        {"type": "assistant", "timestamp": "t1",
         "message": {"role": "assistant",
                     "content": [{"type": "tool_use", "id": "x1", "name": "Read", "input": {}}]}},
        {"type": "user", "timestamp": "t2",
         "message": {"role": "user", "content": [{"type": "tool_result", "tool_use_id": "x1"}]}},
    )
    clean = scan(base, "haiku-firth-3")
    assert clean["injected"] == [] and clean["cross_sample"] == [], clean
    # Planted: the harness hands this author another sample's task, as it did
    # to B8. The scan must report it even though the author called nothing.
    planted = base + log({"type": "attachment", "timestamp": "t3", "attachment": {
        "type": "task_status", "description": "Control author B10",
        "outputFilePath": "/tmp/x/tasks/a06fe49c204b15e18.output"}})
    got = scan(planted, "haiku-firth-3")
    assert len(got["cross_sample"]) == 1, got
    assert got["cross_sample"][0]["task_paths"] == ["a06fe49c204b15e18"], got
    # Planted: a nudge naming another sample's directory.
    planted = base + log({"type": "user", "timestamp": "t3", "message": {
        "role": "user", "content": "[Your previous response] see haiku-firth-9/answer-1.md"}})
    got = scan(planted, "haiku-firth-3")
    assert [i["names"] for i in got["cross_sample"]] == [["9"]], got
    # Planted: another author's label alone, with no path or directory.
    planted = base + log({"type": "attachment", "timestamp": "t3", "attachment": {
        "type": "task_status", "description": "Control author B10", "status": "running"}})
    got = scan(planted, "haiku-firth-3", "A3")
    assert [i["labels"] for i in got["cross_sample"]] == [["B10"]], got
    # This author's own label is not another sample.
    planted = base + log({"type": "attachment", "timestamp": "t3", "attachment": {
        "type": "task_status", "description": "Control author A3", "status": "running"}})
    assert scan(planted, "haiku-firth-3", "A3")["cross_sample"] == []
    # A tool result for a call this author never made is not its own.
    planted = base + log({"type": "user", "timestamp": "t3", "message": {
        "role": "user", "content": [{"type": "tool_result", "tool_use_id": "other"}]}})
    assert len(scan(planted, "haiku-firth-3")["injected"]) == 1
    # The author's own instructions and results stay out of the list.
    assert scan(base + base, "haiku-firth-3")["injected"] == []
    print("self-test ok")


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    cli.add_argument("log", type=Path, nargs="?")
    cli.add_argument("--sample", help="this author's sample directory name, e.g. haiku-firth-8")
    cli.add_argument("--label", help="this author's own label, e.g. B8 (from 'Control author B8')")
    cli.add_argument("--self-test", action="store_true")
    a = cli.parse_args()
    if a.self_test:
        self_test()
        return 0
    events = [json.loads(l) for l in a.log.read_text().splitlines() if l.strip()]
    out = scan(events, a.sample, a.label)
    print(json.dumps(out, indent=1, ensure_ascii=False))
    for item in out["cross_sample"]:
        print(f"CROSS-SAMPLE line {item['line']} {item['kind']} {item['at']}", file=sys.stderr)
    return 1 if out["cross_sample"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
