#!/usr/bin/env python3
"""Check the `inventoryHost` executable that run_cases.py hands the host encoding to.

`src/proofs/Inventory/Host.lean` proves the encoding injective and the answer
order-preserving; `HostMain.lean` runs those definitions on JSON. The proofs
cover the definitions, not the JSON glue, so this script checks the glue:

* known IDs encode to parts written out by hand (a character's digit is its
  position in A..Z a..z 0..9 _ - plus one, read in base 65);
* a successful stack comes back with the IDs in request order and the reasons
  by name, and an error stack by its error name;
* the executable refuses what the proofs do not cover: IDs outside the spec's
  syntax (in both modes), unknown reason and error codes, error codes with
  anything beside them, and lengths that differ. A refusal counts only when
  it carries the executable's own `inventoryHost: ` message, not a crash.

Usage: python3 examples/inventory/check_host.py
"""
from __future__ import annotations

import sys

import run_cases as host

P7 = 65 ** 7

ENCODED = [
    (["A"], [P7, 0, 0, 0]),
    (["-"], [64 * P7, 0, 0, 0]),
    (["AB", "b"], [P7 + 2 * 65 ** 6, 0, 0, 0, 28 * P7, 0, 0, 0]),
    (["AAAAAAAAB"], [sum(65 ** k for k in range(8)), 2 * P7, 0, 0]),
    ([], []),
]

ANSWERS = [
    ({"ids": ["x", "y"], "stack": [0, 5, [3, 0], [0, 2]]},
     {"status": "ok", "remaining": 5, "allocations": [
         {"id": "x", "quantity": 3, "reason": "fulfilled"},
         {"id": "y", "quantity": 0, "reason": "out-of-stock"}]}),
    ({"ids": ["p", "q"], "stack": [0, 0, [2, 0], [1, 3]]},
     {"status": "ok", "remaining": 0, "allocations": [
         {"id": "p", "quantity": 2, "reason": "partial"},
         {"id": "q", "quantity": 0, "reason": "insufficient-stock"}]}),
    ({"ids": ["x"], "stack": [1, 0, [], []]}, {"status": "error", "code": "invalid-range"}),
    ({"ids": ["x"], "stack": [2, 0, [], []]}, {"status": "error", "code": "duplicate-id"}),
]

REFUSED = [
    ("encode", [""]),
    ("encode", ["a" * 33]),
    ("encode", ["a b"]),
    ("encode", ["é"]),
    ("encode", "A"),
    ("answer", {"ids": ["x"], "stack": [0, 0, [1], [4]]}),
    ("answer", {"ids": ["x"], "stack": [0, 0, [1], [-1]]}),
    ("answer", {"ids": ["x"], "stack": [3, 0, [], []]}),
    ("answer", {"ids": ["x", "y"], "stack": [0, 0, [1], [0]]}),
    ("answer", {"ids": ["x"], "stack": [0, 0, [1]]}),
    ("answer", {"ids": ["x"], "stack": [2, 5, [], []]}),
    ("answer", {"ids": ["x"], "stack": [1, 0, [1], [0]]}),
    ("answer", {"ids": ["a b"], "stack": [0, 0, [1], [0]]}),
]


def problems() -> list[str]:
    found = []
    for ids, expected in ENCODED:
        actual = host.lean_host("encode", ids)
        if actual != expected:
            found.append(f"encode {ids}: {actual}, expected {expected}")
    for payload, expected in ANSWERS:
        actual = host.lean_host("answer", payload)
        if actual != expected:
            found.append(f"answer {payload}: {actual}, expected {expected}")
    for mode, payload in REFUSED:
        try:
            actual = host.lean_host(mode, payload)
        except RuntimeError as refusal:
            # A refusal is the executable's own message; anything else (a
            # crash, a panic) is not a refusal.
            if "failed: inventoryHost: " not in str(refusal):
                found.append(f"{mode} {payload} failed without refusing: {refusal}")
            continue
        found.append(f"{mode} {payload} was accepted as {actual}")
    return found


def main() -> int:
    host.build_toolchain()
    found = problems()
    for problem in found:
        print(problem, file=sys.stderr)
    if found:
        return 1
    print(f"inventoryHost: {len(ENCODED)} encodings, {len(ANSWERS)} answers and "
          f"{len(REFUSED)} refusals as expected")
    return 0


if __name__ == "__main__":
    sys.exit(main())
