#!/usr/bin/env python3
"""Run 10's pre-registered tests (preregistration.md, "Outcomes").

Usage, from eval/s7: python3 runs/2026-09-29-control/analyse.py [--self-test]

A sample counts when its directory has results-1.json and results-3.json and
no void.md. A task passes when every case passes. Both tests are exact and
one-sided (arm B greater than arm A), written out here because the container
has no scipy.
"""
import itertools
import json
import sys
from math import comb
from pathlib import Path

HERE = Path(__file__).resolve().parent
ARMS = {"A": HERE / "4c379e0", "B": HERE / "8ea4a1d"}


def passed(results):
    tasks = json.loads(results.read_text())["tasks"].values()
    return sum(bool(t.get("cases")) and all(c["pass"] for c in t["cases"]) for t in tasks)


def fisher_greater(b_yes, b_n, a_yes, a_n):
    """P(arm B has >= b_yes successes) given the margins (hypergeometric)."""
    k, n = b_yes + a_yes, b_n + a_n
    return sum(comb(k, x) * comb(n - k, b_n - x)
               for x in range(b_yes, min(k, b_n) + 1)) / comb(n, b_n)


def ranks(values):
    order = sorted(range(len(values)), key=values.__getitem__)
    r = [0.0] * len(values)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and values[order[j + 1]] == values[order[i]]:
            j += 1
        for k in range(i, j + 1):
            r[order[k]] = (i + j) / 2 + 1
        i = j + 1
    return r


def mann_whitney_greater(b, a):
    """U for B and the exact permutation p of U_B >= observed (mid-ranks)."""
    pooled = b + a
    r = ranks(pooled)
    def u(idx):
        return sum(r[i] for i in idx) - len(b) * (len(b) + 1) / 2
    obs = u(range(len(b)))
    hits = total = 0
    for idx in itertools.combinations(range(len(pooled)), len(b)):
        total += 1
        hits += u(idx) >= obs - 1e-9
    return obs, hits / total


def self_test():
    # Known values: Fisher one-sided on [[3,1],[1,3]] is 17/70; on [[4,0],[0,4]] 1/70.
    assert abs(fisher_greater(3, 4, 1, 4) - 17 / 70) < 1e-12
    assert abs(fisher_greater(4, 4, 0, 4) - 1 / 70) < 1e-12
    # Complete separation of 3 vs 3: U = 9, p = 1/20; identical samples give p = 1.
    assert mann_whitney_greater([4, 5, 6], [1, 2, 3]) == (9.0, 1 / 20)
    assert mann_whitney_greater([1, 1, 1], [1, 1, 1])[1] == 1.0
    # Planted: reversing the arms must not look significant.
    assert mann_whitney_greater([1, 2, 3], [4, 5, 6])[1] == 1.0
    assert fisher_greater(0, 4, 4, 4) == 1.0
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    rows, first, final = {}, {}, {}
    for arm, root in ARMS.items():
        rows[arm], first[arm], final[arm] = [], [], []
        for d in sorted(root.glob("haiku-firth-*"), key=lambda p: int(p.name.rsplit("-", 1)[1])):
            if not (d / "results-1.json").is_file() and not (d / "void.md").is_file():
                continue
            scores = [passed(d / f"results-{n}.json") if (d / f"results-{n}.json").is_file() else None
                      for n in (1, 2, 3)]
            void = (d / "void.md").is_file()
            rows[arm].append((d.name, scores, void))
            if not void and scores[2] is not None:
                first[arm].append(scores[0])
                final[arm].append(scores[2])
    for arm in ARMS:
        print(f"arm {arm} ({ARMS[arm].name})")
        for name, s, void in rows[arm]:
            print(f"  {name:>15}  {' '.join('-' if x is None else str(x) for x in s):<10}"
                  f"{'  VOID' if void else ''}")
    a, b = final["A"], final["B"]
    print(f"counted: A {len(a)}, B {len(b)}")
    ay, by = sum(x > 0 for x in a), sum(x > 0 for x in b)
    print(f"primary: passing >=1 after round 2: A {ay}/{len(a)}, B {by}/{len(b)}; "
          f"one-sided Fisher p = {fisher_greater(by, len(b), ay, len(a)):.4f}")
    u, p = mann_whitney_greater(b, a)
    print(f"secondary 1: total after round 2: A {sum(a)}, B {sum(b)}; U_B = {u:g}, p = {p:.4f}")
    u, p = mann_whitney_greater(first["B"], first["A"])
    print(f"secondary 2: first answers: A {sum(first['A'])}, B {sum(first['B'])}; U_B = {u:g}, p = {p:.4f}")


if __name__ == "__main__":
    main()
