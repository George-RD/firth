#!/usr/bin/env python3
"""Check that every kept sub-agent author had exactly the allowed tools.

From the next tier on, each sub-agent author is started as the agent type
`s7-harder-author` (`.claude/agents/s7-harder-author.md`, `tools: Read,
Write`), and the harness adds the hand-back. This reads each kept author's
raw session log and refuses the run unless, for every kept author:

- its `agent-<id>.meta.json` names the agent type `s7-harder-author`;
- its log has at least one `prompt_snapshot` attachment carrying a tool
  list, and every such list is exactly Read, Write and SubagentHandback;
- no `deferred_tools_delta` attachment adds a tool (a deferred tool can be
  loaded and called, so it widens the set);
- every log line was written with the working directory the driver fixed
  before the first author (`--cwd`).

It prints one line per author with its agent type, model, working directory
and tool list, which the driver commits as the run's record of each author's
tools. Voided authors (`voids.txt`) are listed but not checked.

    author_tools.py --logs LOG_DIR --ids RUN/agent-ids.txt [--voids RUN/voids.txt] --cwd DIR
    author_tools.py --logs LOG_DIR --probe AGENT_ID --cwd DIR

`--probe` checks one log that is not a sample (the non-sample author the
driver starts first).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

AGENT_TYPE = "s7-harder-author"
ALLOWED = ("Read", "SubagentHandback", "Write")


def check_log(logs: Path, agent: str, cwd: str) -> tuple[dict, list[str]]:
    """The record of one author's tools, and why it is refused (empty if not)."""
    errors: list[str] = []
    meta_path = logs / f"agent-{agent}.meta.json"
    log_path = logs / f"agent-{agent}.jsonl"
    record = {"agent": agent, "type": None, "model": None, "cwd": [], "tools": []}
    if not meta_path.is_file() or not log_path.is_file():
        return record, [f"no log for agent {agent} in {logs}"]
    meta = json.loads(meta_path.read_text())
    record["type"] = meta.get("agentType")
    record["model"] = meta.get("model")
    if record["type"] != AGENT_TYPE:
        errors.append(f"agent type is {record['type']!r}, not {AGENT_TYPE!r}")
    lists, cwds = [], []
    for n, line in enumerate(log_path.read_text().splitlines(), 1):
        if not line.strip():
            continue
        o = json.loads(line)
        if "cwd" in o and o["cwd"] not in cwds:
            cwds.append(o.get("cwd"))
        a = o.get("attachment") or {}
        if o.get("type") != "attachment":
            continue
        if a.get("type") == "prompt_snapshot" and "tools" in a:
            names = [t.get("name") for t in a["tools"]]
            lists.append(names)
            if sorted(names) != sorted(ALLOWED):
                errors.append(f"line {n}: tool list is {sorted(names)}, not {list(ALLOWED)}")
        elif a.get("type") == "deferred_tools_delta":
            added = list(a.get("addedNames") or []) + list(a.get("readdedNames") or [])
            if added:
                errors.append(f"line {n}: deferred tools added: {sorted(added)}")
    if not lists:
        errors.append("no tool list in the log")
    record["tools"] = sorted({t for names in lists for t in names})
    record["cwd"] = cwds
    if cwds != [cwd]:
        errors.append(f"working directory {cwds}, not [{cwd!r}]")
    return record, errors


def read_ids(path: Path) -> list[tuple[str, str]]:
    return [tuple(l.split()[:2]) for l in path.read_text().splitlines()
            if l.strip() and not l.startswith("#")]


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--logs", type=Path, required=True)
    p.add_argument("--cwd", required=True)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--ids", type=Path)
    g.add_argument("--probe")
    p.add_argument("--voids", type=Path)
    a = p.parse_args(argv)
    if a.probe:
        authors = [("probe", a.probe)]
    else:
        authors = read_ids(a.ids)
        if not authors:
            print(f"refused: {a.ids} names no author")
            return 1
    voids = set()
    if a.voids and a.voids.is_file():
        voids = {l.split()[0] for l in a.voids.read_text().splitlines()
                 if l.strip() and not l.startswith("#")}
    refused = 0
    for name, agent in authors:
        if name in voids:
            print(f"{name} {agent}: void, not checked")
            continue
        record, errors = check_log(a.logs, agent, a.cwd)
        print(f"{name} {agent}: type={record['type']} model={record['model']} "
              f"cwd={','.join(map(str, record['cwd']))} tools={','.join(record['tools'])}")
        for e in errors:
            print(f"  refused: {e}")
        refused += bool(errors)
    if refused:
        print(f"refused: {refused} author(s) did not have exactly {', '.join(ALLOWED)}")
        return 1
    print(f"ok: every kept author had exactly {', '.join(ALLOWED)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
