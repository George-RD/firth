#!/usr/bin/env python3
"""Ask Jev what mistake each failing run 10 answer shows, in finer labels than
the checker's codes.

Usage, from eval/s7: python3 runs/2026-09-29-control/causes/jev_causes.py > jev.json

Reads `units.json` (from causes.py) and asks Jev (`classify.py`'s endpoint and
pinned model) about every failing first answer (round 1) and final answer
(round 3). Jev sees the task, the source and the first thing the author was
shown: the first diagnostic, or the failing case's input, result and expected
output. Pass/fail never comes from Jev. A label under 0.7 confidence is
marked for review. `handcheck.md` compares these labels with labels written
by hand, without looking at Jev's, on a random sample.
"""
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
RUN = HERE.parent
sys.path.insert(0, str(RUN.parents[1]))
from classify import MODEL, REVIEW_BELOW  # noqa: E402
import classify  # noqa: E402
from tasks import BY_ID  # noqa: E402

ARMS = {"A": "4c379e0", "B": "8ea4a1d"}
LABELS = {
    "stale-local-state": "In a loop or recursive word, a new value (an updated accumulator, index "
                         "or sequence) is computed, but the recursive call or the next step is then "
                         "given the old local names, as if a local were a variable the computation "
                         "updated. So a computed value is left over, or the call gets too few "
                         "arguments.",
    "argument-order": "The right number of values reach a primitive or word, but in the wrong "
                      "order (for example the index before the sequence, or the value before the "
                      "index in seq-int.set).",
    "quoted-condition": "The condition of an `if` is written as a quotation `[ condition ]`, as in "
                        "Joy or Factor, instead of a Bool computed before the two branches.",
    "locals-form": "A `locals` block is written in a form the language does not accept: no braces "
                   "around its body, names used in a word that never binds them, or names bound "
                   "in the wrong order.",
    "other-syntax": "Parentheses, comments, `;`, brackets or literals are written in a form the "
                    "parser rejects.",
    "unknown-word": "The program calls a word or primitive that is not defined: a Forth word such "
                    "as over or rot, a made-up primitive, or a helper that was never written.",
    "stack-juggling": "Another stack-shape mistake: dup, swap, drop, dip or a branch leaves too "
                      "many, too few or the wrong values, not because of old local names.",
    "wrong-algorithm": "The program checks and runs but its algorithm gives the wrong result for "
                       "some input.",
    "other": "None of the above.",
}


def shown(r: dict) -> str:
    d = RUN / ARMS[r["arm"]] / f"haiku-firth-{r['sample'][1:]}"
    t = json.loads((d / f"results-{r['round']}.json").read_text())["tasks"][r["task"]]
    c = next(x for x in t["cases"] if not x["pass"])
    if c.get("error"):
        return "The checker or runner reported:\n" + c["error"][:1200]
    return (f"It ran, but on input {c['input']} it returned {c.get('stack')}; "
            f"expected {c['expected']}.")


def source(r: dict) -> str:
    d = RUN / ARMS[r["arm"]] / f"haiku-firth-{r['sample'][1:]}"
    return json.loads((d / f"solutions-{r['round']}.json").read_text())[r["task"]]


def state(r: dict) -> str:
    t = BY_ID[r["task"]]
    return (f"Task: {t.description}\nThe answer is a Firth program (a concatenative, Forth-like "
            f"language with typed stack effects, `locals {{ a b }} {{ body }}` blocks and "
            f"`condition [ then ] [ else ] if`).\nSubmitted program:\n{source(r)[:3000]}\n\n"
            f"{shown(r)}")


def ask(text: str) -> dict:
    body = json.dumps({"model": MODEL, "state": text, "questions": {"cause": {
        "type": "choice",
        "instructions": "This Firth program failed a small task. What mistake caused the first "
                        "reported failure?",
        "criteria": LABELS}}}).encode()
    headers = {"Content-Type": "application/json"}
    req = classify.urllib.request.Request("https://api.typesafe.ai/v1/systemone", body, headers)
    with classify.urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)["answers"]["cause"]


def main():
    rows = [r for r in json.loads((HERE / "units.json").read_text())
            if r["round"] in (1, 3) and not r["passed"]]

    def one(r):
        a = ask(state(r))
        return {"arm": r["arm"], "sample": r["sample"], "round": r["round"], "task": r["task"],
                "label": a["choice"], "confidence": round(a["confidence"], 3),
                "review": a["confidence"] < REVIEW_BELOW}

    with ThreadPoolExecutor(8) as pool:
        out = list(pool.map(one, rows))
    json.dump({"model": MODEL, "labels": LABELS, "answers": out}, sys.stdout, indent=1)
    print()


if __name__ == "__main__":
    main()
