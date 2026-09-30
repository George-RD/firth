#!/usr/bin/env python3
"""Arm B's Bash calls, verbatim, and the shell syntax the audit refused.

Usage, from eval/s7:
  python3 runs/2026-09-30-check-tool/driver/bash_calls.py extract LOGDIR
      writes arm-b/haiku-firth-<n>/bash-calls.json from each author's raw log
      (LOGDIR/<agent id>.output, the ids in driver/ids.txt)
  python3 runs/2026-09-30-check-tool/driver/bash_calls.py
      counts, per sample and in all, the calls that are not the allowed check
      command, and the syntax each one adds

The audit keeps only the first characters of a flagged call in
transcript.json, so the counts come from the full commands kept here.
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
ROOT = "/home/user/firth-r12/eval/s7"
CHECK = re.compile(r"python3 " + re.escape(ROOT) + r"/harness\.py check --lang firth "
                   + re.escape(ROOT) + r"/runs/2026-09-30-check-tool/arm-b/haiku-firth-(\d+)/answer-[123]\.md")
FORMS = [  # (label, pattern), counted independently: one call can add several
    ("`2>&1`", re.compile(r"2>&1")),
    ("`| head`", re.compile(r"\|\s*head\b")),
    ("`| tail`", re.compile(r"\|\s*tail\b")),
    ("`| grep`", re.compile(r"\|\s*grep\b")),
    ("`cd … &&` prefix", re.compile(r"^cd \S+ && ")),
    ("redirect to a file", re.compile(r"(?<![0-9&])>>?\s*/(?!dev/null)")),
    ("`source` of a shell profile", re.compile(r"(^|&& |; )source ")),
]
# `&&`, `||`, `;` or a second line, apart from a leading `cd … &&`.
CHAIN = ("chained with `&&`, `||`, `;` or a second line", re.compile(r"&&|\|\||;|\n"))


def extract(logdir):
    for line in (HERE / "driver" / "ids.txt").read_text().splitlines():
        arm, n, agent = line.split()
        if arm != "B":
            continue
        errored, calls = set(), []
        for raw in (Path(logdir) / f"{agent}.output").read_text().splitlines():
            e = json.loads(raw)
            content = e.get("message", {}).get("content")
            if e.get("type") == "user" and isinstance(content, list):
                errored |= {b["tool_use_id"] for b in content if isinstance(b, dict)
                            and b.get("type") == "tool_result" and b.get("is_error")
                            and b.get("tool_use_id")}
            if e.get("type") == "assistant":
                calls += [{"at": e.get("timestamp"), "id": b["id"], "command": b["input"].get("command"),
                           "background": bool(b["input"].get("run_in_background"))}
                          for b in content if b.get("type") == "tool_use" and b["name"] == "Bash"]
        for c in calls:
            c["errored"] = c.pop("id") in errored
        out = HERE / "arm-b" / f"haiku-firth-{n}" / "bash-calls.json"
        out.write_text(json.dumps({"note": "Every Bash call in the author's raw log, command verbatim "
                                           "(driver/bash_calls.py extract).", "calls": calls}, indent=1) + "\n")


def classify(command, n):
    """None for the allowed call (the check of the sample's own answer, nothing
    else), else the list of forms it adds; `other` when it is not a check."""
    m = CHECK.fullmatch(command)
    if m and m.group(1) == str(n):
        return None
    forms = [label for label, p in FORMS if p.search(command)]
    if CHAIN[1].search(re.sub(r"^cd \S+ && ", "", command)):
        forms.append(CHAIN[0])
    return forms if CHECK.search(command) else forms + ["not a check"]


def self_test():
    ok = f"python3 {ROOT}/harness.py check --lang firth {ROOT}/runs/2026-09-30-check-tool/arm-b/haiku-firth-4/answer-1.md"
    assert classify(ok, 4) is None
    assert classify(ok, 5) == []  # another sample's answer
    assert classify(ok + " 2>&1 | grep -A 5 x", 4) == ["`2>&1`", "`| grep`"]
    assert classify(f"cd /home/user/firth-r12 && {ok} 2>&1 | tail -50", 4) == [
        "`2>&1`", "`| tail`", "`cd … &&` prefix"]
    assert classify(f"{ok} > /tmp/out.txt 2>&1", 4) == ["`2>&1`", "redirect to a file"]
    assert classify("ls ~/.elan 2>/dev/null | head -20", 4) == ["`| head`", "not a check"]
    assert classify(f"source ~/.elan/env && source ~/.cargo/env 2>/dev/null; {ok}", 4) == [
        "`source` of a shell profile", "chained with `&&`, `||`, `;` or a second line"]
    assert classify(f"{ok} > /tmp/o 2>&1 && echo ok || echo no\nhead -200 /tmp/o", 4) == [
        "`2>&1`", "redirect to a file", "chained with `&&`, `||`, `;` or a second line"]
    print("self-test ok")


def main():
    if sys.argv[1:2] == ["extract"]:
        return extract(sys.argv[2])
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    total, flagged_total = {}, 0
    for d in sorted((HERE / "arm-b").glob("haiku-firth-*"), key=lambda p: int(p.name.rsplit("-", 1)[1])):
        n = int(d.name.rsplit("-", 1)[1])
        calls = json.loads((d / "bash-calls.json").read_text())["calls"]
        per = {}
        flagged = 0
        for c in calls:
            forms = classify(c["command"], n)
            if forms is None:
                continue
            flagged += 1
            for f in forms:
                per[f] = per.get(f, 0) + 1
        flagged_total += flagged
        for f, k in per.items():
            total[f] = total.get(f, 0) + k
        shown = ", ".join(f"{f} {k}" for f, k in per.items()) or "none"
        print(f"B{n}: {len(calls)} Bash calls, {len(calls) - flagged} allowed, {flagged} not: {shown}")
    print(f"all: {flagged_total} calls not allowed: " + ", ".join(f"{f} {k}" for f, k in total.items()))


if __name__ == "__main__":
    main()
