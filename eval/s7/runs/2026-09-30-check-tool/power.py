#!/usr/bin/env python3
"""Power of run 12's primary test (preregistration.md, "Power"). A few minutes.

Usage, from eval/s7: python3 runs/2026-09-30-check-tool/power.py

A sample's final passes are drawn from run 11's 20 counted arm A samples, whose
prompt is byte-identical to run 12's arm A prompt (run 11's analysis.txt); an
arm B sample then passes each task it failed with probability q,
independently. The q that matters is unknown: run 11's refused final answers
(195 of arm A's 246 failures, causes/rank.txt) are what the checker could show
an author before hand-in, but most that check still fail on their results
(causes/recover.py: 37 answers made to check, 15 of them pass).
"""
import importlib.util
import random
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("analyse", HERE / "analyse.py")
analyse = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(analyse)
# Run 11 arm A final passes (analysis.txt), counted samples in start order.
pool = [12, 0, 8, 7, 15, 7, 9, 9, 11, 12, 9, 1, 13, 11, 15, 4, 10, 0, 1, 0]
rng = random.Random(20260930)
N = 2000


def draw(q):
    x = rng.choice(pool)
    return x + sum(rng.random() < q for _ in range(20 - x))


for q in (0.0, 0.05, 0.10, 0.15, 0.20):
    gain = sum(draw(q) for _ in range(20000)) / 20000 - sum(pool) / 20
    hits = 0
    for _ in range(N):
        a = [draw(0) for _ in range(20)]
        b = [draw(q) for _ in range(20)]
        hits += analyse.mann_whitney_greater(b, a)[1] < 0.05
    print(f"| {q:.2f} | {gain:+.1f} | {hits / N:.2f} |")
