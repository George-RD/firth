#!/usr/bin/env python3
"""Power of run 12's primary test (preregistration.md, "Power").

Usage, from eval/s7: python3 runs/2026-09-30-check-tool/power.py [--n 40] [--runs 1000]

Each row runs in its own process with its own fixed seed; at 40 per arm and
1,000 runs a row, the table takes about half an hour on four cores.

A sample's final passes are drawn from run 11's 20 counted arm A samples, whose
prompt is byte-identical to run 12's arm A prompt (run 11's analysis.txt); an
arm B sample then passes each task it failed with probability q,
independently. The q that matters is unknown: run 11's refused final answers
(195 of arm A's 246 failures, causes/rank.txt) are what the checker could show
an author before hand-in, but most that check still fail on their results
(causes/recover.py: 37 answers made to check, 15 of them pass).
"""
import argparse
import importlib.util
import random
from multiprocessing import Pool
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("analyse", HERE / "analyse.py")
analyse = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(analyse)
# Run 11 arm A final passes (analysis.txt), counted samples in start order.
pool = [12, 0, 8, 7, 15, 7, 9, 9, 11, 12, 9, 1, 13, 11, 15, 4, 10, 0, 1, 0]
QS = (0.0, 0.05, 0.10, 0.15, 0.20)


def draw(rng, q):
    x = rng.choice(pool)
    return x + sum(rng.random() < q for _ in range(20 - x))


def row(job):
    n, runs, q = job
    rng = random.Random(f"20260930-{n}-{q}")
    gain = sum(draw(rng, q) for _ in range(20000)) / 20000 - sum(pool) / len(pool)
    hits = 0
    for _ in range(runs):
        a = [draw(rng, 0) for _ in range(n)]
        b = [draw(rng, q) for _ in range(n)]
        hits += analyse.mann_whitney_greater(b, a)[1] < 0.05
    return f"| {q:.2f} | {gain:+.1f} | {hits / runs:.2f} |"


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=analyse.N_PER_ARM)
    ap.add_argument("--runs", type=int, default=1000)
    a = ap.parse_args()
    print(f"| q | mean gain per sample | power, one-sided MWU, {a.n} per arm |")
    print("| --- | --- | --- |")
    with Pool(4) as p:
        for line in p.map(row, [(a.n, a.runs, q) for q in QS]):
            print(line)
