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
    costliest.py --candidates [TASK ...] > costliest-candidates.tsv

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

import candidates as cand  # noqa: E402
import scored  # noqa: E402
from tier import BY_ID, SET_OF, harness  # noqa: E402

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


def candidate_inputs() -> dict[str, list[tuple[str, tuple]]]:
    """The same search for the candidate set (`candidates.py`): seeded random
    inputs at the largest sizes each description allows, and a few built to be
    slow for a straightforward program."""
    sweep = cand._ob(*([(0, 1, 500 + i, 1, i % 10, 0) for i in range(29)] + [(1, 0, 1, 1000, 9, 0)]))
    fok = cand._ob(*([(0, 1, 100 + i % 3, 2, i % 10, 0) for i in range(22)]
                     + [(0, 0, 200, 40, i % 10, 2) for i in range(8)]))
    j_max = ([10 ** 12] * 3, [12, 11, 10], [200] * 3)
    j_twelve = ([10 ** 12, 10 ** 12 - 1, 999_999_999_989], [12] * 3, [200] * 3)
    two_each = list(range(10)) * 2
    deep = cand._ex(" ".join(["("] * 29 + ["2"] + [")"] * 29))
    powers = cand._ex(" ; ".join(["2 ^ 39"] * 10) + " ; 9999 ^ 3 ^ 9")
    return {
        "order-match": [(f"_random_order_book({s}, 30)", cand._random_order_book(s, 30)) for s in range(100, 130)]
        + [("a market buy sweeping 29 sells", sweep), ("fill or kill buys against 22 sells", fok)],
        "go-game": [(f"_random_go({s}, 7, 60)", cand._random_go(s, 7, 60)) for s in range(100, 130)]
        + [(f"_random_go({s}, 6, 60)", cand._random_go(s, 6, 60)) for s in range(100, 105)],
        "stack-vm": [(f"_random_stack_vm({s}, 60, 800)", cand._random_stack_vm(s, 60, 800))
                     for s in range(100, 140)]
        + [("an 800-step loop", cand._vm((0, 30), (6,), (10, 7), (0, 1), (2,), (6,), (9, 1), (8,), limit=800))],
        "josephus": [(f"_random_josephus({s}, 3)", cand._random_josephus(s, 3)) for s in range(100, 120)]
        + [("1e12 counting by 12 to 10", j_max), ("near 1e12 counting by 12", j_twelve)],
        "perm-rank": [(f"_random_perm_rank({s})", cand._random_perm_rank(s)) for s in range(100, 120)]
        + [("two of each digit, largest first, last k", (two_each, sorted(two_each, reverse=True),
                                                         2_375_880_867_359_999)),
           ("two of each digit, smallest first, k 1e15", (two_each, sorted(two_each), 10 ** 15))],
        "wire-decode": [(f"_random_wire({s}, 200)", cand._random_wire(s, 200)) for s in range(100, 130)]
        + [("100 two-byte records", ([8, 1] * 100,)), ("22 nine-byte records", (([8] + [255] * 7 + [127]) * 22,))],
        "tennis": [(f"_random_tennis({s}, 400)", cand._random_tennis(s, 400)) for s in range(100, 130)]
        + [("400 alternating points", ([0, 1] * 200, 5, 2, False, 0))],
        "timetable": [(f"_random_timetable({s}, 60)", cand._random_timetable(s, 60)) for s in range(100, 140)],
        "expr-eval": [(f"_random_expr({s}, 60)", cand._random_expr(s, 60)) for s in range(100, 130)]
        + [("29 nested parentheses", deep), ("powers near the bound", powers)],
    }


def agrees(tid: str, args, out: dict) -> bool:
    """Whether a `firth_run.py run` result OUT on ARGS ran to the end and left
    what the meaning says (`test_harder.py`, `scored_costliest`, plants a
    wrong stack and a run that did not finish)."""
    t = BY_ID[tid]
    return out.get("status") == "success" and harness.same(out.get("stack"), t.expected(args))


def run(tid: str, name: str, args: tuple) -> tuple[str, str, int | None, bool]:
    args = json.loads(json.dumps(list(args)))
    try:
        p = subprocess.run([sys.executable, "tools/loop/firth_run.py", "run",
                            str(HERE / "reference" / SET_OF[tid] / "firth" / f"{tid}.firth"), "--entry", "main",
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
    if argv[:1] == ["--candidates"]:
        every, argv = candidate_inputs(), argv[1:]
    tasks = argv or list(every)
    jobs = [(tid, name, args) for tid in tasks for name, args in every[tid]]
    with cf.ThreadPoolExecutor(os.cpu_count() or 4) as ex:
        for tid, name, cost, ok in ex.map(lambda j: run(*j), jobs):
            print(f"{tid}\t{name}\t{cost}\t{ok}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
