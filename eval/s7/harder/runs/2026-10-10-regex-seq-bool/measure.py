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

With `--drafted` it runs instead the inputs of `DRAFTED`, which sit within
the bounds first drafted for the task (patterns of up to 30 tokens, 10
strings of up to 20 letters; README, "The scored set") and outside the
bounds it was given, and prints the same columns. A run that ends with the
VM's `fuel-exhausted` trap is shown with that status and no step count:

    measure.py --drafted > drafted.tsv

`test_harder.py` (`regex_drafted_bounds`) checks the record against these
inputs and runs its first out-of-steps input again.
"""
from __future__ import annotations

import concurrent.futures as cf
import json
import os
import random
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HARDER = HERE.parents[1]
ROOT = HARDER.parents[2]
sys.path.insert(0, str(HARDER))

import costliest  # noqa: E402

FIVE = {
    "nest20": [31] * 6 + [26, 27] + [32, 27] * 6,
    "astar10": [0, 27] * 10,
    "dotstar10": [26, 27] * 10,
    "alt20": [31, 26, 30, 26, 26, 30, 0, 32, 27, 31, 26, 30, 1, 32, 27, 26, 27, 26, 27, 28],
    "star20": [31, 0, 27, 1, 27, 30, 2, 27, 26, 32, 27, 31, 26, 27, 32, 27, 26, 27, 0, 28],
}

def _drafted(pattern: list[int], alphabet: str) -> tuple:
    letter = costliest.ALPHABETS[alphabet]
    return pattern, [20] * 10, [letter(i) for i in range(200)]


# Two patterns of 30 tokens against 10 strings of 20 letters: `a*` fifteen
# times, and `(a|b|c)*` three times then `.*` three times (the costliest
# pattern measured at the scored bounds, made longer).
DRAFTED = [
    (f"{name} on {alphabet}", _drafted(pattern, alphabet))
    for name, pattern in (("a*x15", [0, 27] * 15),
                          ("(a|b|c)*x3 .*x3", [31, 0, 30, 1, 30, 2, 32, 27] * 3 + [26, 27] * 3))
    for alphabet in ("a", "abc")
]


def inputs() -> list[tuple[str, tuple]]:
    rng = random.Random(1)
    strings = [[rng.randint(0, 1) for _ in range(12)] for _ in range(8)]
    out = [(name, (pat, [12] * 8, [c for s in strings for c in s])) for name, pat in FIVE.items()]
    return out + costliest.candidates()["regex"]


def outcome(stdout: str, stderr: str, returncode: int) -> tuple[str, str]:
    """The kernel steps and status of one `firth_run.py run`. A run whose VM
    stopped with the `fuel-exhausted` trap after the whole 1,000,000-step
    budget is `fuel-exhausted`; any other failure keeps its exit code."""
    try:
        out = json.loads(stdout)
        return str(out.get("kernel_cost")), str(out.get("status"))
    except json.JSONDecodeError:
        pass
    try:
        error = json.loads(stderr)["error"]
    except (json.JSONDecodeError, KeyError, TypeError):
        return "None", f"exit {returncode}"
    if (error.startswith("application vm-run: status 'trap'") and "'trap': 'fuel-exhausted'" in error
            and re.search(r"'steps': 1000000\b", error)):
        return "None", "fuel-exhausted"
    return "None", f"exit {returncode}"


def run(name: str, args: tuple, source: Path = HERE / "regex-seq-bool.firth") -> tuple[str, str, str, bool]:
    args = json.loads(json.dumps(list(args)))
    try:
        p = subprocess.run([sys.executable, "tools/loop/firth_run.py", "run", str(source),
                            "--entry", "main", "--stack", json.dumps(args), "--fuel", "1000000"],
                           cwd=ROOT, capture_output=True, text=True, timeout=3600)
    except subprocess.TimeoutExpired:
        return name, "None", "timeout", False
    cost, status = outcome(p.stdout, p.stderr, p.returncode)
    agrees = status == "success" and costliest.agrees("regex", args, json.loads(p.stdout))
    return name, cost, status, agrees


def main(argv: list[str]) -> int:
    jobs = DRAFTED if argv == ["--drafted"] else inputs()
    with cf.ThreadPoolExecutor(os.cpu_count() or 4) as ex:
        for name, cost, status, ok in ex.map(lambda j: run(*j), jobs):
            print(f"{name}\t{cost}\t{status}\t{ok}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
