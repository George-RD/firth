#!/usr/bin/env python3
"""Measure the first `regex` Firth reference, which held position sets as
`Seq Bool` and was replaced by the bitset reference (README, "The scored
set"), at the scored bounds.

It runs `regex-seq-bool.firth` on five patterns built to be slow (each
against 8 strings of 12 letters drawn from a and b with a fixed seed) and on
every `regex` candidate of `costliest.py`, checks each result against the
meaning, and prints one line per input:

    input <TAB> kernel steps <TAB> run status <TAB> agrees with the meaning

    measure.py > output.tsv
"""
from __future__ import annotations

import concurrent.futures as cf
import json
import os
import random
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HARDER = HERE.parents[1]
ROOT = HARDER.parents[2]
sys.path.insert(0, str(HARDER))

import costliest  # noqa: E402
import scored  # noqa: E402
from tier import harness  # noqa: E402

FIVE = {
    "nest20": [31] * 6 + [26, 27] + [32, 27] * 6,
    "astar10": [0, 27] * 10,
    "dotstar10": [26, 27] * 10,
    "alt20": [31, 26, 30, 26, 26, 30, 0, 32, 27, 31, 26, 30, 1, 32, 27, 26, 27, 26, 27, 28],
    "star20": [31, 0, 27, 1, 27, 30, 2, 27, 26, 32, 27, 31, 26, 27, 32, 27, 26, 27, 0, 28],
}


def inputs() -> list[tuple[str, tuple]]:
    rng = random.Random(1)
    strings = [[rng.randint(0, 1) for _ in range(12)] for _ in range(8)]
    out = [(name, (pat, [12] * 8, [c for s in strings for c in s])) for name, pat in FIVE.items()]
    return out + costliest.candidates()["regex"]


def run(name: str, args: tuple) -> tuple[str, str, str, bool]:
    t = {t.id: t for t in scored.SCORED}["regex"]
    args = json.loads(json.dumps(list(args)))
    p = subprocess.run([sys.executable, "tools/loop/firth_run.py", "run", str(HERE / "regex-seq-bool.firth"),
                        "--entry", "main", "--stack", json.dumps(args), "--fuel", "1000000"],
                       cwd=ROOT, capture_output=True, text=True, timeout=3600)
    try:
        out = json.loads(p.stdout)
    except json.JSONDecodeError:
        return name, "None", f"exit {p.returncode}", False
    ok = out.get("status") == "success" and harness.same(out["stack"], t.expected(args))
    return name, str(out.get("kernel_cost")), str(out.get("status")), ok


def main() -> int:
    with cf.ThreadPoolExecutor(os.cpu_count() or 4) as ex:
        for name, cost, status, ok in ex.map(lambda j: run(*j), inputs()):
            print(f"{name}\t{cost}\t{status}\t{ok}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
