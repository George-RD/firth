#!/usr/bin/env python3
"""Check that the host's cost bound is the cost bound Lean proves.

`examples/inventory/run_cases.py` checks every allocator run against
`cost_bound(n)`. `src/proofs/Inventory/Allocate.lean` proves that
`allocate-batch` runs within `batchCost n`. The two are meant to be the same
function, but until now they agreed only because their text matched, so an
edit to either side alone would leave CI checking runs against a bound nobody
proved.

This script asks Lean for `batchCost n` for every batch size the spec allows
(0 to 64 requests) and requires each to equal `run_cases.cost_bound(n)`.
`test_check_cost_bound.py` plants a changed value on each side and requires
the check to fail.

Usage: python3 tools/loop/check_cost_bound.py

Run from the repository root after `lake build`.

Language need (AGENTS.md rule 5): S5's cost bound is only proved if the bound
the runs are checked against is the proved one (rule 8 keeps measured and
proved bounds apart).
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "examples" / "inventory"))
import run_cases as host  # noqa: E402  (the host's cost bound)

MAX_REQUESTS = 64  # the spec's bound on the batch size
PROGRAM = f"""import proofs.Inventory.Allocate
open Firth.Proofs.Inventory.Allocate
#eval (List.range {MAX_REQUESTS + 1}).forM fun n => IO.println s!"{{n}} {{batchCost n}}"
"""


def proved_costs() -> dict[int, int]:
    """`batchCost n` for n = 0..MAX_REQUESTS, evaluated by Lean."""
    with tempfile.TemporaryDirectory() as scratch:
        path = Path(scratch) / "CostBound.lean"
        path.write_text(PROGRAM, encoding="utf-8")
        result = subprocess.run(["lake", "env", "lean", str(path)], cwd=ROOT,
                                capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"Lean could not evaluate batchCost:\n{result.stdout}{result.stderr}")
    costs: dict[int, int] = {}
    for line in result.stdout.splitlines():
        n, cost = line.split()
        costs[int(n)] = int(cost)
    return costs


def problems(proved: dict[int, int]) -> list[str]:
    found = []
    if sorted(proved) != list(range(MAX_REQUESTS + 1)):
        found.append(f"Lean gave batchCost for {sorted(proved)}, expected 0 to {MAX_REQUESTS}")
    for n in range(MAX_REQUESTS + 1):
        if n in proved and proved[n] != host.cost_bound(n):
            found.append(f"n = {n}: batchCost is {proved[n]}, run_cases.cost_bound is "
                         f"{host.cost_bound(n)}")
    return found


def main() -> int:
    try:
        found = problems(proved_costs())
    except (RuntimeError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1
    if found:
        print("the host's cost bound is not the proved one:", file=sys.stderr)
        for problem in found:
            print(f"  {problem}", file=sys.stderr)
        return 1
    print(f"run_cases.cost_bound equals the proved batchCost for 0 to {MAX_REQUESTS} requests")
    return 0


if __name__ == "__main__":
    sys.exit(main())
