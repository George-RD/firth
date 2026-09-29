#!/usr/bin/env python3
"""Rank run 11's final-answer failure causes, by arm, by answers recoverable.

Usage, from eval/s7: python3 runs/2026-09-29-locals-guide/causes/rank.py [--self-test]

Reads `units.json` (causes.py), `rechecked.json` (recheck.py), the edit
recoveries `recovered-5d09e25.json` and `recovered-a3fb621.json` (recover.py),
`locals-body.json` (locals_body.py) and `../closed-effect.txt`
(closed_effect.py), and prints `rank.txt`:

1. Final failing answers by family and by the checker's own diagnosis (the
   shape of its hint), per arm, with single-family counts and an inferred
   recoverable count (single-family x the rate at which written answers that
   checked passed, per arm). The inferred count assumes a fixed answer passes
   at that rate and reveals no other error.
2. Measured recoveries: answers that pass after applying the checker's own
   edits (pinned 5d09e25 and main a3fb621), after bracing unbraced `locals`
   bodies, and after opening closed effects. These are counterfactuals, not
   scored, but measured on the answers themselves.
3. Wrong results and runtime traps (checks and runs, but wrong), classified
   by the failing case's outcome with fixed rules, not by reading programs.
4. Tasks and families that fail in both arms.
5. Feedback: a failing task rewritten in the next round, by family and arm.
6. The void samples' last kept answers, to see whether leaving them out
   changes the ranking.
"""
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
RUN = HERE.parent
sys.path.insert(0, str(HERE))
from causes import family, passed as task_passed, seen  # noqa: E402

sys.path.insert(0, str(RUN))
from analyse import ARMS  # noqa: E402

RUNS_WRONG = ("wrong-result", "runtime-trap")


def source(r):
    d = ARMS[r["arm"]] / f"haiku-firth-{r['sample'][1:]}"
    return json.loads((d / f"solutions-{r['round']}.json").read_text())[r["task"]]


def diagnosis(d):
    """The checker's own diagnosis of a first diagnostic, from its hint's shape."""
    if d is None:
        return "-"
    h, code = d.get("hint") or "", d["code"] or ""
    m = d.get("message") or ""
    if "in another order" in h:
        if re.search(r"write `[^`]+` in place of `[^`]+`", h + m):
            return "argument order, edit given"
        return "argument order, left to the author"
    if "Make the branch push, just before" in h:
        return "call in a branch given the wrong values"
    if re.search(r"branch leaves \d+ values? more", h):
        return "one branch leaves extra values"
    if code == "firth.type.branch-mismatch":
        return "other branch mismatch"
    if re.search(r"takes \d+ values but only \d+", h):
        return "too few values for a call"
    if "is not what" in h:
        return "wrong type at a position"
    if code == "firth.type.stack-underflow":
        return "stack underflow"
    if re.search(r"Unexpected `[^`]+`, expected `\{`", m):
        return "`locals` block without a braced body"
    if code == "firth.syntax.invalid-token":
        return "invalid token"
    if "cannot start an item" in m:
        return "operator that does not exist (`<=`, `>`)"
    return code.rsplit(".", 1)[-1]


def outcome(case, task):
    """A wrong result's kind, by fixed rules on the failing case's outcome."""
    if case.get("error") and "trap" in case["error"]:
        return "trap: " + case["error"].split("\n")[0].replace("trap ", "")
    got, exp, inp = case.get("stack"), case["expected"], case["input"]
    if task == "is-sorted" and exp == [True] and got == [False] and any(
            a == b for a, b in zip(inp[0], inp[0][1:])):
        return "equality boundary"
    if task == "keep-positive" and got and 0 in got[0] and 0 not in exp[0]:
        return "equality boundary"
    if task == "primes-up-to" and got and set(got[0]) - set(exp[0]) and all(
            round(x ** 0.5) ** 2 == x for x in set(got[0]) - set(exp[0])):
        return "equality boundary"
    if task == "digits" and got and got[0] == list(reversed(exp[0])):
        return "digits in reverse order"
    def empty(v):  # [] or the integer 0; False == 0 in Python, so test the type
        return v == [] or (type(v) is int and v == 0)
    if got and empty(got[0]) and not empty(exp[0]):
        return "empty or zero result (loop body never ran)"
    return "other wrong value"


def failing_case(r):
    d = ARMS[r["arm"]] / f"haiku-firth-{r['sample'][1:]}"
    t = json.loads((d / f"results-{r['round']}.json").read_text())["tasks"][r["task"]]
    return next(c for c in t["cases"] if not c["pass"])


def single_family(r):
    fams = {e["family"] for e in r["errors"] if not e["dependent"]}
    return len(fams) == 1 and r["seen_family"] in fams


def check_rate(rows):
    written = [r for r in rows if r["written"]]
    ok = sum(r["passed"] for r in written)
    ran = ok + sum(r["seen_family"] in RUNS_WRONG for r in written if not r["passed"])
    return ok, ran


def report():
    rows = json.loads((HERE / "units.json").read_text())
    rc = json.loads((HERE / "rechecked.json").read_text())["answers"]
    first_diag = {}
    for r in rows:
        ds = rc[hashlib.sha256(source(r).encode()).hexdigest()]
        first_diag[(r["sample"], r["round"], r["task"])] = ds[0] if ds else None
    final = [r for r in rows if r["round"] == 3 and not r["passed"]]

    print("== 1. Final failing answers, by family and the checker's diagnosis (first error shown)")
    for arm in ARMS:
        ok, ran = check_rate([r for r in rows if r["arm"] == arm])
        rate = ok / ran
        fa = [r for r in final if r["arm"] == arm]
        print(f"\narm {arm}: {len(fa)} failing final answers; written answers that checked and "
              f"ran: {ran}, passed {ok} ({100 * rate:.0f}%)")
        fam = Counter(r["seen_family"] for r in fa)
        for f, n in fam.most_common():
            if f in RUNS_WRONG:
                print(f"  {f:18s} {n:4d}")
                continue
            s = sum(single_family(r) for r in fa if r["seen_family"] == f)
            print(f"  {f:18s} {n:4d}  single {s:4d}  recoverable (inferred) {s * rate:5.1f}")
            sub = Counter(diagnosis(first_diag[(r["sample"], 3, r["task"])])
                          for r in fa if r["seen_family"] == f)
            for k, v in sub.most_common():
                samples = Counter(r["sample"] for r in fa if r["seen_family"] == f and
                                  diagnosis(first_diag[(r["sample"], 3, r["task"])]) == k)
                top = ", ".join(f"{s} {c}" for s, c in samples.most_common(2))
                print(f"      {v:4d}  {k}  ({len(samples)} samples; most: {top})")

    print("\n== 2. Measured recoveries of failing final answers (counterfactual, not scored)")
    for name in ("recovered-5d09e25.json", "recovered-a3fb621.json"):
        doc = json.loads((HERE / name).read_text())
        for arm in ARMS:
            a = [x for x in doc["answers"] if x["arm"] == arm and x["refused"]]
            off = [x for x in a if x["edits_offered"]]
            chk = [x for x in a if x["edits_applied"] and x["checks_after"]]
            ps = [x for x in chk if x.get("passes_after")]
            byf = Counter(family(x["first_code"]) for x in ps)
            print(f"  checker {doc['checker']} edits, arm {arm}: refused {len(a)}, an edit offered "
                  f"{len(off)}, checks after the edits {len(chk)}, passes {len(ps)} "
                  f"({', '.join(f'{k} {v}' for k, v in byf.most_common()) or 'none'})")
    lb = json.loads((HERE / "locals-body.json").read_text())["answers"]
    for arm in ARMS:
        a = [x for x in lb if x["arm"] == arm]
        print(f"  unbraced `locals` bodies braced, arm {arm}: {len(a)} answers, checks after "
              f"{sum(x['checks_after'] for x in a)}, passes {sum(x.get('passes_after', False) for x in a)}")
    ce = (RUN / "closed-effect.txt").read_text()
    print("  closed effects opened (closed-effect.txt): " + "; ".join(
        ln for ln in ce.splitlines() if ln.startswith("arm ") and "answer-3" in ln))

    print("\n== 3. Wrong results and traps (checks, runs, wrong), by outcome rule")
    for arm in ARMS:
        w = [r for r in final if r["arm"] == arm and r["seen_family"] in RUNS_WRONG]
        kinds = Counter(outcome(failing_case(r), r["task"]) for r in w)
        print(f"  arm {arm}: {len(w)}")
        for k, v in kinds.most_common():
            print(f"      {v:4d}  {k}")

    print("\n== 4. Tasks: failing final answers per arm, and the commonest family in both")
    per = defaultdict(Counter)
    for r in final:
        per[r["task"]][r["arm"]] += 1
    for task in sorted(per, key=lambda t: -sum(per[t].values())):
        fams = Counter(r["seen_family"] for r in final if r["task"] == task)
        print(f"  {task:15s} A {per[task]['A']:2d}  B {per[task]['B']:2d}  "
              + ", ".join(f"{k} {v}" for k, v in fams.most_common(3)))

    print("\n== 5. Feedback: failing tasks rewritten in the next round, by family first shown")
    by = {(r["sample"], r["round"], r["task"]): r for r in rows}
    for arm in ARMS:
        out = defaultdict(Counter)
        for r in rows:
            if r["arm"] != arm or r["round"] == 3 or r["passed"]:
                continue
            nxt = by.get((r["sample"], r["round"] + 1, r["task"]))
            if not nxt or not nxt["written"]:
                continue
            out[r["seen_family"]]["passed" if nxt["passed"] else "same family"
                                  if nxt["seen_family"] == r["seen_family"] else "other"] += 1
        print(f"  arm {arm}")
        for f in sorted(out, key=lambda f: -sum(out[f].values())):
            c = out[f]
            t = sum(c.values())
            print(f"    {f:18s} {t:4d}  same family {100 * c['same family'] / t:3.0f}%  "
                  f"passed {100 * c['passed'] / t:3.0f}%")

    print("\n== 6. Void samples' last kept answers: passed, and failures by family first shown")
    for arm, path in ARMS.items():
        for d in sorted(path.glob("haiku-firth-*"), key=lambda p: int(p.name.rsplit("-", 1)[1])):
            kept = sorted(d.glob("results-*.json"))
            if not (d / "void.md").exists() or not kept:
                continue
            tasks = json.loads(kept[-1].read_text())["tasks"].values()
            fams = Counter(seen(t)[0] for t in tasks if not task_passed(t))
            print(f"  {arm}{d.name.rsplit('-', 1)[1]:3s} {kept[-1].name}  passed "
                  f"{sum(map(task_passed, tasks)):2d}  "
                  + ", ".join(f"{k} {v}" for k, v in fams.most_common()))


def self_test():
    assert diagnosis({"code": "firth.type.primitive-input-mismatch",
                      "hint": "These are the values `prim +` takes, in another order."}
                     ) == "argument order, left to the author"
    assert diagnosis({"code": "firth.type.primitive-input-mismatch",
                      "hint": "These are the values `prim +` takes, in another order. To push "
                              "them in its order, write `a b` in place of `b a`."}
                     ) == "argument order, edit given"
    assert diagnosis({"code": "firth.syntax.unexpected-token", "hint": "A definition looks like",
                      "message": "Unexpected `i`, expected `{`."}).startswith("`locals` block")
    assert diagnosis(None) == "-"
    eq = {"stack": [False], "expected": [True], "input": [[1, 2, 2, 5]]}
    assert outcome(eq, "is-sorted").startswith("equality boundary")
    # Planted: is-sorted wrong on an input with no equal neighbours is not an equality slip.
    assert outcome({"stack": [False], "expected": [True], "input": [[1, 2, 5]]},
                   "is-sorted") == "other wrong value"
    assert outcome({"stack": [[2, 3, 4, 5, 7, 9]], "expected": [[2, 3, 5, 7]], "input": [10]},
                   "primes-up-to").startswith("equality boundary")
    # Planted: a composite that is not a square (6) is not the square-bound slip.
    assert outcome({"stack": [[2, 3, 5, 6, 7]], "expected": [[2, 3, 5, 7]], "input": [10]},
                   "primes-up-to") == "other wrong value"
    assert outcome({"stack": [[5, 0, 3]], "expected": [[3, 0, 5]], "input": [305]},
                   "digits") == "digits in reverse order"
    assert outcome({"stack": [[]], "expected": [[3, 2, 1]], "input": [[1, 2, 3]]},
                   "reverse").startswith("empty")
    assert outcome({"error": "trap primitive-fault\n{...}", "expected": [1], "input": []},
                   "sort") == "trap: primitive-fault"
    rows = [{"written": True, "passed": True, "seen_family": None},
            {"written": True, "passed": False, "seen_family": "wrong-result"},
            {"written": False, "passed": False, "seen_family": "wrong-result"}]
    assert check_rate(rows) == (1, 2)
    print("self-test ok")


if __name__ == "__main__":
    self_test() if "--self-test" in sys.argv else report()
