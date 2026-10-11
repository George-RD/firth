#!/usr/bin/env python3
"""Check that every sub-agent author had exactly the allowed tools.

From the next tier on, each sub-agent author is started as the agent type
`s7-harder-author` (`.claude/agents/s7-harder-author.md`, `tools: Read,
Write`), and the harness adds the hand-back. This reads each author's raw
session log and refuses the run unless, for every author:

- its `agent-<id>.meta.json` names the agent type `s7-harder-author`;
- its log has at least one `prompt_snapshot` attachment carrying a tool
  list, and every such list is exactly Read, Write and SubagentHandback;
- no `deferred_tools_delta` attachment adds a tool (a deferred tool can be
  loaded and called, so it widens the set);
- every log line was written with the working directory the driver fixed
  before the first author (`--cwd`).

With `--ids`, the list must also name every sub-agent that ran: each
`agent-<id>.meta.json` or `agent-<id>.jsonl` in the log directory must be a
row of `agent-ids.txt` (the probe author is the row named `probe`, listed
once), each row is a name and an agent id, and no name or agent id may be
listed twice. A listed author with no log, or with only half of one, is
refused, and a meta file with no agent type fails the type check. So an author left out of the list, or listed
under another author's id, refuses the run instead of going unchecked.

It prints one line per author with its agent type, model, working directory
and tool list, which the driver commits as the run's record of each author's
tools. A voided author is checked like any other: the claim is that every
author in both arms had the same tools, not only the kept ones, so a
wrong tool list refuses the run even if that sample was voided.

    author_tools.py --logs LOG_DIR --ids RUN/agent-ids.txt --cwd DIR
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


def read_ids(path: Path) -> list[list[str]]:
    return [l.split() for l in path.read_text().splitlines()
            if l.strip() and not l.startswith("#")]


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--logs", type=Path, required=True)
    p.add_argument("--cwd", required=True)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--ids", type=Path)
    g.add_argument("--probe")
    a = p.parse_args(argv)
    if a.probe:
        authors = [("probe", a.probe)]
    else:
        authors = read_ids(a.ids)
        if not authors:
            print(f"refused: {a.ids} names no author")
            return 1
    refused = 0
    if a.ids:
        for row in [r for r in authors if len(r) != 2]:
            print(f"refused: row {' '.join(row)!r} in {a.ids} is not 'name agent-id'")
            refused += 1
        authors = [tuple(r) for r in authors if len(r) == 2]
        if [n for n, _ in authors].count("probe") != 1:
            print(f"refused: {a.ids} must list the probe author once, as the row 'probe <id>'")
            refused += 1
        for col, what in ((0, "name"), (1, "agent id")):
            seen = [row[col] for row in authors]
            for v in sorted({v for v in seen if seen.count(v) > 1}):
                print(f"refused: {what} {v} is listed twice in {a.ids}")
                refused += 1
        listed = {agent for _, agent in authors}
        ran = {f.name[len("agent-"):-len(".meta.json")] for f in a.logs.glob("agent-*.meta.json")}
        ran |= {f.name[len("agent-"):-len(".jsonl")] for f in a.logs.glob("agent-*.jsonl")}
        for agent in sorted(ran):
            if agent not in listed:
                print(f"refused: agent {agent} ran in this session but is not in {a.ids}")
                refused += 1
    for name, agent in authors:
        record, errors = check_log(a.logs, agent, a.cwd)
        print(f"{name} {agent}: type={record['type']} model={record['model']} "
              f"cwd={','.join(map(str, record['cwd']))} tools={','.join(record['tools'])}")
        for e in errors:
            print(f"  refused: {e}")
        refused += bool(errors)
    if refused:
        print(f"refused: {refused} problem(s); not every author is shown to have had "
              f"exactly {', '.join(ALLOWED)}")
        return 1
    print(f"ok: every author had exactly {', '.join(ALLOWED)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
