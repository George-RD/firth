#!/usr/bin/env python3
"""Find the costliest input for each scored-set Firth reference
(`todo.s7-harder-task-tier`; README, "The scored set").

The last hidden test of each scored task is meant to be the costliest input,
for its Firth reference, among a fixed list of candidates at the largest sizes
its description allows. This script is that search: it runs every candidate
through the reference (`firth_run.py run`, fuel 1,000,000), keeps each kernel
step count and checks the output against the meaning, and prints one line
per candidate:

    task <TAB> candidate <TAB> kernel steps <TAB> agrees with the meaning

    costliest.py [TASK ...] > costliest.tsv

It takes about 15 seconds a candidate, so it is not run in CI. Its recorded
output (`costliest.tsv`) is what `test_harder.py` (`scored_costliest`) checks
the hidden tests against: each task's last hidden test must be the candidate
the record shows as costliest, and every candidate must have agreed.
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
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE))

import scored  # noqa: E402
from tier import harness  # noqa: E402

ALPHABETS = {"a": lambda i: 0, "ab": lambda i: i % 2, "abc": lambda i: random.Random(i).randint(0, 2)}

# Patterns of 20 tokens or fewer whose matching is slow: nested and stacked
# repeats that reach many positions, each tried against 8 strings of 12 letters.
SLOW_PATTERNS = {
    "a*x10": [0, 27] * 10,
    ".*x10": [26, 27] * 10,
    "(a*)*x4": [31, 0, 27, 32, 27] * 4,
    "(a|b)*x5": [31, 0, 30, 1, 32, 27] * 3 + [0, 27],
    "(.*)+x4": [31, 26, 27, 32, 28] * 4,
    "a?x10": [0, 29] * 10,
    "(a*b*)*": [31, 31, 0, 27, 1, 27, 32, 27, 32, 27, 31, 0, 27, 30, 1, 27, 32, 27, 0, 27],
    "a+x10": [0, 28] * 10,
    "(a|.)*x3": [31, 0, 30, 26, 32, 27] * 3 + [26, 27],
    "((a*)*)*": [31, 31, 31, 0, 27, 32, 27, 32, 27, 32, 27, 26, 27, 26, 27, 26, 27, 26, 27, 0],
    "(.?)*x4": [31, 26, 29, 32, 27] * 4,
    "(a|b|c)*": [31, 0, 30, 1, 30, 2, 32, 27] * 2 + [26, 27, 26, 27],
}


def _regex_candidate(name: str, alphabet: str):
    letter = ALPHABETS[alphabet]
    chars = [letter(i) for i in range(96)]
    return SLOW_PATTERNS[name], [12] * 8, chars


def candidates() -> dict[str, list[tuple[str, tuple]]]:
    """Every candidate input, by task, with a name that says how it was made."""
    return {
        "sokoban": [(f"_random_sokoban({s}, 12, 12, 6, 200)", scored._random_sokoban(s, 12, 12, 6, 200))
                    for s in range(100, 140)],
        "checkers": [(f"_largest_checkers({s})", scored._largest_checkers(s)) for s in range(100, 140)]
        + [(f"opening, turn {t}, 40 plies", (list(scored._OPENING), t, 40)) for t in (0, 1)],
        "regex": [(f"{p} on {a}", _regex_candidate(p, a)) for p in SLOW_PATTERNS for a in ALPHABETS],
        "swiss": [(f"_random_swiss({s}, 12, 7)", scored._random_swiss(s, 12, 7)) for s in range(100, 140)]
        + [(f"_random_swiss({s}, 11, 7)", scored._random_swiss(s, 11, 7)) for s in range(100, 110)],
        "warehouse": [(f"_random_warehouse({s}, 5, 60, 80)", scored._random_warehouse(s, 5, 60, 80))
                      for s in range(100, 140)],
        "cache-sim": [(f"_largest_cache({s})", scored._largest_cache(s)) for s in range(100, 150)],
    }


def agrees(tid: str, args, out: dict) -> bool:
    """Whether a `firth_run.py run` result OUT on ARGS ran to the end and left
    what the meaning says (`test_harder.py`, `scored_costliest`, plants a
    wrong stack and a run that did not finish)."""
    t = {t.id: t for t in scored.SCORED}[tid]
    return out.get("status") == "success" and harness.same(out.get("stack"), t.expected(args))


def run(tid: str, name: str, args: tuple) -> tuple[str, str, int | None, bool]:
    args = json.loads(json.dumps(list(args)))
    try:
        p = subprocess.run([sys.executable, "tools/loop/firth_run.py", "run",
                            str(HERE / "reference/scored/firth" / f"{tid}.firth"), "--entry", "main",
                            "--stack", json.dumps(args), "--fuel", "1000000"],
                           cwd=ROOT, capture_output=True, text=True, timeout=1800)
        out = json.loads(p.stdout)
    except (subprocess.TimeoutExpired, json.JSONDecodeError) as e:
        # One failed candidate is recorded as a failure row, never stops the search.
        detail = e if isinstance(e, subprocess.TimeoutExpired) else (p.stderr or p.stdout)[-300:]
        print(f"{tid} {name}: {detail}", file=sys.stderr)
        return tid, name, None, False
    return tid, name, out.get("kernel_cost"), agrees(tid, args, out)


def main(argv: list[str]) -> int:
    every = candidates()
    tasks = argv or list(every)
    jobs = [(tid, name, args) for tid in tasks for name, args in every[tid]]
    with cf.ThreadPoolExecutor(os.cpu_count() or 4) as ex:
        for tid, name, cost, ok in ex.map(lambda j: run(*j), jobs):
            print(f"{tid}\t{name}\t{cost}\t{ok}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
