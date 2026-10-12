#!/usr/bin/env python3
"""Check that the host's cost bound is the cost bound Lean proves.

`examples/inventory/run_cases.py` checks every allocator run against
`cost_bound(n)`. `src/proofs/Inventory/Allocate.lean` proves that
`allocate-batch` runs within `batchCost n`. The two are meant to be the same
function, but until now they agreed only because their text matched, so an
edit to either side alone would leave CI checking runs against a bound nobody
proved.

This script asks Lean for `batchCost n` for every batch size the spec allows
(0 to 64 requests) and every size the corpus runs (its 65-request cases are
checked against the bound too), and requires each to equal
`run_cases.cost_bound(n)`. The Lean contract has no length precondition, so
`batchCost` is the proved bound at every size.
`test_check_cost_bound.py` plants a changed value on each side and requires
the check to fail.

Usage: python3 tools/loop/check_cost_bound.py

Run from the repository root after `lake build`.

Language need (AGENTS.md rule 5): S5's cost bound is only proved if the bound
the runs are checked against is the proved one (rule 8 keeps measured and
proved bounds apart).
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "examples" / "inventory"))
import run_cases as host  # noqa: E402  (the host's cost bound)

# The spec's bound on the batch size. The compared range always reaches at
# least this far, because measure_cost.py evaluates the bound at 64 requests;
# today the corpus's 64- and 65-request cases cover it too, but that would
# stop if those cases changed.
MAX_REQUESTS = 64
CORPUS = ROOT / "specs" / "inventory-allocation-cases.json"


def corpus_sizes() -> set[int]:
    """The request counts of the corpus cases whose requests are a list."""
    cases = json.loads(CORPUS.read_text(encoding="utf-8"))["cases"]
    return {len(case["input"]["requests"]) for case in cases
            if isinstance(case["input"], dict) and isinstance(case["input"].get("requests"), list)}


def sizes() -> list[int]:
    """Every batch size to compare: 0 to the largest the spec allows or the corpus runs."""
    return list(range(max({MAX_REQUESTS, *corpus_sizes()}) + 1))


def program(top: int) -> str:
    return f"""import proofs.Inventory.Allocate
open Firth.Proofs.Inventory.Allocate
#eval (List.range {top + 1}).forM fun n => IO.println s!"{{n}} {{batchCost n}}"
"""


def proved_costs(top: int) -> dict[int, int]:
    """`batchCost n` for n = 0..top, evaluated by Lean."""
    with tempfile.TemporaryDirectory() as scratch:
        path = Path(scratch) / "CostBound.lean"
        path.write_text(program(top), encoding="utf-8")
        result = subprocess.run(["lake", "env", "lean", str(path)], cwd=ROOT,
                                capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"Lean could not evaluate batchCost:\n{result.stdout}{result.stderr}")
    costs: dict[int, int] = {}
    for line in result.stdout.splitlines():
        n, cost = line.split()
        costs[int(n)] = int(cost)
    return costs


def problems(proved: dict[int, int], wanted: list[int]) -> list[str]:
    found = []
    if sorted(proved) != wanted:
        found.append(f"Lean gave batchCost for {sorted(proved)}, expected 0 to {wanted[-1]}")
    for n in wanted:
        if n in proved and proved[n] != host.cost_bound(n):
            found.append(f"n = {n}: batchCost is {proved[n]}, run_cases.cost_bound is "
                         f"{host.cost_bound(n)}")
    return found


def main() -> int:
    wanted = sizes()
    try:
        found = problems(proved_costs(wanted[-1]), wanted)
    except (RuntimeError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1
    if found:
        print("the host's cost bound is not the proved one:", file=sys.stderr)
        for problem in found:
            print(f"  {problem}", file=sys.stderr)
        return 1
    print(f"run_cases.cost_bound equals the proved batchCost for 0 to {wanted[-1]} requests")
    return 0


if __name__ == "__main__":
    sys.exit(main())
