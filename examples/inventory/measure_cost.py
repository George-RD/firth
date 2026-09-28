#!/usr/bin/env python3
"""Measure the allocator's kernel cost against batch size, for the S5 bound.

Every input here is valid and has no repeated ID, so validation scans every
quantity and the repeated-ID scan visits every pair. What a pair costs depends
only on how the two IDs' four parts compare: `same-id` takes its slow path when
part 0 is equal, and `distance` takes its costlier negating branch
(`0 swap prim -`) when the earlier ID's part is the smaller. So each part of a
pair p < q is equal, ascending or descending, and there are 80 shapes (all four
equal would be a repeat). The script measures every shape at n = 2 and 3 and
fails unless `WORST` is the single costliest. `WORST` shares part 0 and has
parts 1 to 3 ascending, so it takes the slow path and three negations. Each
shape holds for every pair at once, so the cost sweep below uses it for all
requests. The earlier IDs shared parts 0 to 2, took one negation per pair and
understated the per-pair cost. Four request
patterns cover the four allocation branches. Each run executes on the VM and
the reference interpreter (`mvp_agent_gate.rebuild`), which must agree.

For n >= 2 each pattern's cost is exactly a + b*n + c*n*(n-1)/2: a fixed
entry cost, a per-request cost that depends on the reason branch, and a
per-pair cost for the repeated-ID scan. The script fits a, b and c from
n = 2, 3 and 8, fails unless the fit is exact at every other measured size,
and fails unless every measurement is within `run_cases.cost_bound`. That bound
is measured, not proved (`language-06c`).
"""
from __future__ import annotations

import itertools
import json
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from fractions import Fraction
from pathlib import Path

import run_cases as host

PATTERNS = {
    # name: (available, policy, quantity) for every request
    "fulfilled": (lambda n: n, "partial", 1),
    "out-of-stock": (lambda n: 0, "partial", 1),
    "insufficient-stock": (lambda n: 1, "all-or-nothing", 2),
    "partial-then-out": (lambda n: 1, "partial", 2),
}
SIZES = [0, 1, 2, 3, 8, 16, 32, 48, 64]


RELATIONS = ("equal", "ascending", "descending")
SHAPES = [shape for shape in itertools.product(RELATIONS, repeat=4) if shape != ("equal",) * 4]
WORST = ("equal", "ascending", "ascending", "ascending")


def make_id(shape: tuple[str, ...], k: int) -> str:
    """Request k's ID: each 8-character part is fixed, or ends in a character
    that rises or falls with k."""
    last = {"ascending": host.ALPHABET[k], "descending": host.ALPHABET[63 - k]}
    return "".join(fill * 7 + last.get(relation, fill) for relation, fill in zip(shape, "xyzw"))


def run(requests: list[dict], available: int, policy: str, name: str) -> int:
    stack = host.host_decode({"available": available, "policy": policy, "requests": requests})
    with tempfile.TemporaryDirectory(prefix="firth-inventory-cost-") as directory:
        observation = host.gate.rebuild(
            {"name": name, "entry": host.ENTRY, "source": str(host.SOURCE),
             "source_path": host.SOURCE.name},
            Path(directory), stack=stack, fuel=host.FUEL)
    return observation["kernel_cost"]


def shape_cost(shape: tuple[str, ...]) -> int:
    """cost(3) - cost(2) = b + 2c; b does not depend on the IDs, so this ranks
    shapes by their per-pair cost c."""
    two, three = (run([{"id": make_id(shape, k), "quantity": 1} for k in range(n)],
                      n, "partial", "-".join(shape)) for n in (2, 3))
    return three - two


def measure(pattern: str, n: int) -> int:
    available, policy, quantity = PATTERNS[pattern]
    requests = [{"id": make_id(WORST, k), "quantity": quantity} for k in range(n)]
    return run(requests, available(n), policy, f"{pattern}-{n}")


def fit(points: dict[int, int]) -> tuple[Fraction, Fraction, Fraction]:
    y2, y3, y8 = (Fraction(points[n]) for n in (2, 3, 8))
    c = ((y8 - y3) / 5 - (y3 - y2)) / 3
    b = y3 - y2 - 2 * c
    a = y2 - 2 * b - c
    return a, b, c


def main() -> int:
    host.gate.build_toolchain()
    jobs = [(p, n) for p in PATTERNS for n in SIZES]
    with ThreadPoolExecutor(max_workers=6) as pool:
        shapes = dict(zip(SHAPES, pool.map(shape_cost, SHAPES)))
        costs = dict(zip(jobs, pool.map(lambda job: measure(*job), jobs)))
    worst = max(shapes.values())
    costliest = [shape for shape, cost in shapes.items() if cost == worst]
    ok = costliest == [WORST]
    print(f"costliest pair shape of {len(SHAPES)}: {costliest} (cost(3) - cost(2) = {worst})"
          f"{'' if ok else f'  NOT {WORST}'}")
    report = {"shapes": {"-".join(shape): cost for shape, cost in shapes.items()}}
    for pattern in PATTERNS:
        points = {n: costs[(pattern, n)] for n in SIZES}
        a, b, c = fit(points)
        exact = all(a + b * n + c * n * (n - 1) / 2 == points[n] for n in SIZES if n >= 2)
        within = all(cost <= host.cost_bound(n) for n, cost in points.items())
        ok &= exact and within
        report[pattern] = {"a": str(a), "b": str(b), "c": str(c), "costs": points,
                           "exact_for_n_at_least_2": exact, "within_bound": within}
        print(f"{pattern:20} cost(n) = {a} + {b}*n + {c}*n(n-1)/2 for n >= 2;"
              f" n=64: {points[64]} (bound {host.cost_bound(64)})"
              f"{'' if exact else '  NOT EXACT'}{'' if within else '  OVER BOUND'}")
    print(json.dumps(report, indent=1))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
