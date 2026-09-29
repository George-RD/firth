#!/usr/bin/env python3
"""Rank run 10's failure causes by how many answers a fix could plausibly recover.

Usage, from eval/s7: python3 runs/2026-09-29-control/causes/rank.py [--self-test]

Reads `units.json` (causes.py), `jev.json` (jev_causes.py) and the hand labels
in `handcheck.md`, and prints:

1. How often feedback cleared each family: for a failing task rewritten in the
   next round, whether the next answer's first error is in the same family.
2. The final answers' causes: the rule family of the first thing shown, split
   by Jev's label for checker failures. A final answer whose independent
   errors are all in one family is "single-family": fixing that family alone
   would leave a program that checks.
3. How often an answer that checks also passes (every written answer in
   every round), which turns "would check" into "would pass" (inferred).
4. Reversed loop guards (`<seq> prim seq-int.len <name> prim <`, where
   `<name> <seq> prim seq-int.len prim <` was meant) among wrong results,
   found by pattern, not by reading.

Counts are measured from the files. The recovery estimate in (3) is inferred:
it assumes an answer whose checker errors were fixed would pass at the rate
answers that checked did, and that fixing one cause does not reveal another.
"""
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import handcheck_sample  # noqa: E402
import jev_causes  # noqa: E402

RUNS_WRONG = ("wrong-result", "runtime-trap")
REVERSED_GUARD = re.compile(r"seq-(?:int|bool)\.len\s+([a-z][\w-]*)\s+prim\s+<(?!=)")


def cause(r, jev):
    """Rule family, refined by Jev's label for a checker failure."""
    if r["seen_family"] in RUNS_WRONG:
        return r["seen_family"]
    return f"{r['seen_family']} / {jev[(r['sample'], r['round'], r['task'])]['label']}"


def persistence(rows):
    by = {(r["sample"], r["round"], r["task"]): r for r in rows}
    out = defaultdict(Counter)
    for r in rows:
        if r["round"] == 3 or r["passed"]:
            continue
        nxt = by[(r["sample"], r["round"] + 1, r["task"])]
        if not nxt["written"]:
            continue
        out[r["seen_family"]]["passed" if nxt["passed"] else
                              "same family" if nxt["seen_family"] == r["seen_family"] else
                              "other family"] += 1
    return out


def single_family(r):
    fams = {e["family"] for e in r["errors"] if not e["dependent"]}
    return len(fams) == 1 and r["seen_family"] in fams


def check_rate(rows):
    written = [r for r in rows if r["written"]]
    passed = sum(r["passed"] for r in written)
    ran = passed + sum(r["seen_family"] in RUNS_WRONG for r in written if not r["passed"])
    return passed, ran


def reversed_guards(src):
    return [m[1] for m in REVERSED_GUARD.finditer(src)]


def report():
    rows = json.loads((HERE / "units.json").read_text())
    jev = {(a["sample"], a["round"], a["task"]): a
           for a in json.loads((HERE / "jev.json").read_text())["answers"]}

    print("== Feedback: a failing task rewritten in the next round, by the family first shown")
    per = persistence(rows)
    for fam in sorted(per, key=lambda f: -sum(per[f].values())):
        c = per[fam]
        t = sum(c.values())
        print(f"  {fam:16s} {t:4d}  same family {c['same family']:4d} ({100 * c['same family'] / t:3.0f}%)"
              f"  other family {c['other family']:4d}  passed {c['passed']:4d} ({100 * c['passed'] / t:3.0f}%)")

    passed, ran = check_rate(rows)
    rate = passed / ran
    print(f"\n== Written answers that checked: {ran}; passed {passed} ({100 * rate:.0f}%)")

    final = [r for r in rows if r["round"] == 3 and not r["passed"]]
    causes = Counter(cause(r, jev) for r in final)
    single = Counter(cause(r, jev) for r in final if single_family(r))
    print(f"\n== Final failing answers ({len(final)}) by cause; single-family ones; "
          f"inferred recoverable = single-family x {rate:.2f}")
    for c, n in causes.most_common():
        s = single[c] if c not in RUNS_WRONG else n
        rec = f"{s * rate:5.1f}" if c not in RUNS_WRONG else "    -"
        print(f"  {c:40s} {n:4d}  single {s:4d}  recoverable {rec}")

    print("\n== Final failing answers by family (single-family; inferred recoverable)")
    fam = Counter(r["seen_family"] for r in final)
    fam_single = Counter(r["seen_family"] for r in final if single_family(r))
    for f, n in fam.most_common():
        if f in RUNS_WRONG:
            print(f"  {f:16s} {n:4d}")
        else:
            print(f"  {f:16s} {n:4d}  single {fam_single[f]:4d}  recoverable {fam_single[f] * rate:5.1f}")

    wrong = [r for r in rows if r["round"] == 3 and r["seen_family"] == "wrong-result"]
    hits = [r for r in wrong if reversed_guards(jev_causes.source(r))]
    print(f"\n== Final wrong results with a reversed loop guard: {len(hits)} of {len(wrong)}")
    for r in hits:
        print(f"  {r['sample']:4s} {r['task']:15s} {', '.join(reversed_guards(jev_causes.source(r)))}")

    print("\n== Hand check agreement by rule family (handcheck.md)")
    hand = handcheck_sample.hand_labels((HERE / "handcheck.md").read_text())
    agree = defaultdict(Counter)
    for i, r in enumerate(handcheck_sample.sample(), 1):
        j = jev[(r["sample"], r["round"], r["task"])]["label"]
        agree[r["seen_family"]]["agree" if j == hand[i][3] else "differ"] += 1
    for f, c in sorted(agree.items()):
        print(f"  {f:16s} agree {c['agree']:2d} of {sum(c.values()):2d}")


def self_test():
    assert reversed_guards("xs prim seq-int.len i prim < [") == ["i"]
    assert reversed_guards("flags prim seq-bool.len j prim <") == ["j"]
    assert reversed_guards("i xs prim seq-int.len prim <") == []
    assert reversed_guards("xs prim seq-int.len 1 prim <") == []
    rows = [
        {"sample": "A1", "round": 1, "task": "t", "passed": False, "written": True,
         "seen_family": "syntax", "errors": []},
        {"sample": "A1", "round": 2, "task": "t", "passed": False, "written": True,
         "seen_family": "syntax", "errors": []},
        {"sample": "A1", "round": 3, "task": "t", "passed": False, "written": True,
         "seen_family": "wrong-result", "errors": []},
    ]
    assert persistence(rows) == {"syntax": Counter({"same family": 1, "other family": 1})}
    assert check_rate(rows) == (0, 1)
    assert single_family({"seen_family": "syntax", "errors": [
        {"family": "syntax", "dependent": False},
        {"family": "input-mismatch", "dependent": True}]})
    assert not single_family({"seen_family": "syntax", "errors": [
        {"family": "syntax", "dependent": False},
        {"family": "input-mismatch", "dependent": False}]})
    print("self-test ok")


if __name__ == "__main__":
    self_test() if "--self-test" in sys.argv else report()
