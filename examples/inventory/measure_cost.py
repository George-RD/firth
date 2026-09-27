#!/usr/bin/env python3
"""Measure the allocator's kernel cost against batch size, for the S5 bound.

Every input here is valid and has no repeated ID, so validation scans every
quantity and the repeated-ID scan visits every pair. All IDs share their first
24 characters, so every pair takes the slow path in `same-id`. Four request
patterns cover the four allocation branches. Each run executes on the VM and
the reference interpreter (`mvp_agent_gate.rebuild`), which must agree.

For n >= 2 each pattern's cost is exactly a + b*n + c*n*(n-1)/2: a fixed
entry cost, a per-request cost that depends on the reason branch, and a
per-pair cost for the repeated-ID scan. The script fits a, b and c from
n = 2, 3 and 8, fails unless the fit is exact at every other measured size,
and fails unless every measurement is within `run_cases.cost_bound`.
"""
from __future__ import annotations

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


def measure(pattern: str, n: int) -> int:
    available, policy, quantity = PATTERNS[pattern]
    requests = [{"id": "x" * 24 + f"{k:08d}", "quantity": quantity} for k in range(n)]
    stack = host.host_decode({"available": available(n), "policy": policy, "requests": requests})
    with tempfile.TemporaryDirectory(prefix="firth-inventory-cost-") as directory:
        observation = host.gate.rebuild(
            {"name": f"{pattern}-{n}", "entry": host.ENTRY, "source": str(host.SOURCE),
             "source_path": host.SOURCE.name},
            Path(directory), stack=stack, fuel=host.FUEL)
    return observation["kernel_cost"]


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
        costs = dict(zip(jobs, pool.map(lambda job: measure(*job), jobs)))
    report, ok = {}, True
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
