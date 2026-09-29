#!/usr/bin/env python3
"""Power of run 11's tests (preregistration.md, "Power"). About 8 minutes.

Usage, from eval/s7: python3 runs/2026-09-29-locals-guide/power.py

A sample's final passes are drawn from run 10's 20 counted samples (whose
arm B prompt is byte-identical to run 11's arm A prompt); an arm B sample then
passes each task it failed with probability q, independently. q = 0.14 is
about +2 tasks per sample, what run 10's association (41% vs 10%) would
give if it were causal and arm B cut answers with shuffle words from 43% to 10%.
"""
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from analyse import fisher_greater, mann_whitney_greater  # noqa: E402
# Run 10 final passes (analysis.txt), arm A then arm B.
pool = [3, 9, 10, 1, 10, 3, 12, 6, 0, 8, 8, 0, 9, 0, 13, 7, 2, 2, 8, 0]
rng = random.Random(20260929)
N = 2000


def draw(q):
    x = rng.choice(pool)
    return x + sum(rng.random() < q for _ in range(20 - x))


for q in (0.0,0.07,0.14,0.21,0.28):
    g=sum(draw(q) for _ in range(20000))/20000-sum(pool)/20; row=[]
    for n in (10,20):
        h=f=0
        for _ in range(N):
            a=[draw(0) for _ in range(n)]; b=[draw(q) for _ in range(n)]
            h+=mann_whitney_greater(b,a)[1]<0.05
            f+=fisher_greater(sum(v>0 for v in b),n,sum(v>0 for v in a),n)<0.05
        row.append(f"n={n}: MWU {h/N:.2f} Fisher(>=1) {f/N:.2f}")
    print(f"q={q:.2f} gain {g:+.1f} | "+" | ".join(row))
