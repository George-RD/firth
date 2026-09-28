#!/usr/bin/env python3
"""Tag why each failed task failed, using TypeSafe's Jev classifier.

Pass/fail always comes from the hidden tests in harness.py. This only labels the
failures, so a report can say "mostly stack-order mistakes" without an LLM
reading every attempt. Jev returns a label and a confidence; labels under 0.7
are marked for a human to check.

    classify.py solutions.json results.json [--available add,sub,cmp] > modes.json

A task whose capabilities are not all in --available is labelled
missing_primitive by rule, without asking Jev: in the first run Jev labelled
those confidently as stack_effect because the checker's diagnostic dominated.
--available defaults to every capability a task names, which the language
now has; pass a narrower list only to score a build that lacks some (the
plus-only runs used --available add).
A failure whose error mentions fuel, resource-fault or overflow is labelled
resource_limit by rule, so runtime limits are counted apart from mistakes.

Auth: TYPESAFE_API_KEY if set; in the cloud environment the proxy injects it.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tasks import BY_ID  # noqa: E402

MODEL = "jev-1.13.0"  # pinned so a model update cannot move the labels silently
REVIEW_BELOW = 0.7
MODES = {
    "missing_primitive": "The task needs an operation the language or runner does not provide "
                         "(for example subtraction, comparison or multiplication), and the author "
                         "invented it, left a stub, or said it cannot be done.",
    "invented_syntax": "The author used a word, keyword or syntax form that is not in the documented "
                       "language, although the task could be written with what exists.",
    "stack_effect": "The declared stack effect (signature) is wrong, inconsistent with the body, "
                    "or rejected by the type checker.",
    "stack_order": "The program runs but leaves values in the wrong order or consumes the wrong "
                   "stack item, e.g. a missing or extra swap.",
    "logic": "The program runs but the algorithm itself is wrong for some inputs.",
    "toolchain": "The source looks valid per the documentation but the checker, compiler or VM "
                 "rejects it or disagrees (an implementation bug or undocumented limit).",
    "resource_limit": "Fuel, recursion depth or overflow limits stop an otherwise plausible program.",
}


def ask(state: str) -> dict:
    body = json.dumps({"model": MODEL, "state": state, "questions": {"mode": {
        "type": "choice",
        "instructions": "This is a failed attempt by a programmer to solve a small task. "
                        "What is the main reason it failed?",
        "criteria": MODES}}}).encode()
    headers = {"Content-Type": "application/json"}
    if os.environ.get("TYPESAFE_API_KEY"):
        headers["Authorization"] = f"Bearer {os.environ['TYPESAFE_API_KEY']}"
    req = urllib.request.Request("https://api.typesafe.ai/v1/systemone", body, headers)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)["answers"]["mode"]


def describe(tid: str, source: str, r: dict) -> str:
    t = BY_ID[tid]
    bad = next((c for c in r["cases"] if not c["pass"]), None)
    if bad is None:
        outcome = "No answer was submitted."
    elif not bad["ok"]:
        code = re.search(r"'code': '([^']+)'|^code: (\S+)", bad["error"], re.M)
        outcome = (f"Running it failed with diagnostic {(code.group(1) or code.group(2)) if code else 'unknown'}: "
                   f"{bad['error'][:800]}")
    else:
        outcome = f"On input {bad['input']} it returned {bad['stack']}; expected {bad['expected']}."
    return (f"Task: {t.description}\nCapabilities the task needs: {', '.join(sorted(t.needs))}.\n"
            f"Submitted program:\n{source[:3000]}\n\n{outcome}")


# Every capability some task needs. The language provides all of them since
# Gamma 0.6 (div/mod), so this is the default rather than the plus-only "add".
ALL = frozenset().union(*(t.needs for t in BY_ID.values()))


def by_rule(tid: str, r: dict, available: set[str]) -> str | None:
    """The mode a failure gets without asking Jev, or None to ask it."""
    if not BY_ID[tid].needs <= available:
        return "missing_primitive"
    errors = " ".join(c.get("error", "") for c in r["cases"] if not c["pass"])
    if re.search(r"fuel|resource-fault|overflow", errors):
        # The step budget or a VM limit stopped the run: a harness/runtime limit,
        # counted apart from authoring mistakes.
        return "resource_limit"
    return None


def main() -> int:
    cli = argparse.ArgumentParser()
    cli.add_argument("solutions", type=Path)
    cli.add_argument("results", type=Path)
    cli.add_argument("--available", default=",".join(sorted(ALL)))
    a = cli.parse_args()
    available = set(a.available.split(","))
    solutions = json.loads(a.solutions.read_text())
    results = json.loads(a.results.read_text())
    out = {}
    for tid, r in results["tasks"].items():
        if r["pass"]:
            continue
        mode = by_rule(tid, r, available)
        if mode:
            out[tid] = {"mode": mode, "by": "rule"}
            continue
        ans = ask(describe(tid, solutions.get(tid, ""), r))
        out[tid] = {"mode": ans["choice"], "by": "jev", "confidence": round(ans["confidence"], 3),
                    "review": ans["confidence"] < REVIEW_BELOW}
    counts = Counter(v["mode"] for v in out.values())
    print(json.dumps({"model": MODEL, "counts": dict(counts.most_common()), "tasks": out}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
