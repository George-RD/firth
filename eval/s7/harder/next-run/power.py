"""Power of the next scored run's pre-registered decision rule, by simulation
(`scored.md`), for its sample sizes: 12 authors per arm for Sonnet and 8
for DeepSeek. The rule and the simulation are those of
`scored-run/power.py`.

Each simulated author answers 6 tasks, each passed independently with the
arm's rate (binomial). A replicate counts as a material Python-higher or
Firth-higher result exactly as `scored.md` defines it: an observed
difference of at least 1 task, a two-sided exact permutation p below 0.05,
and a 95% percentile bootstrap interval excluding 0. The bootstrap here
uses 2,000 resamples for speed (the analysis uses 10,000).

    python3 eval/s7/harder/next-run/power.py

prints the table recorded in `power-output.txt`. Standard library only. It
first checks its exact permutation p against enumeration, and checks that
the same comparison rejects a planted one-sided p.
"""

from __future__ import annotations

import itertools
import random
from math import comb

TASKS = 6
REPLICATES = 2000
BOOT = 2000
SEED = 0


def perm_p(a: list[int], b: list[int]) -> float:
    """Exact two-sided permutation p for the difference in means.

    Counts every split of the pooled scores into groups of len(a) and
    len(b) by the sum of the first group (scores are small integers), so
    it equals enumerating all comb(N, len(a)) splits.
    """
    pooled = a + b
    n, m = len(a), len(b)
    total = sum(pooled)
    # ways[k][s]: number of k-subsets of the pooled scores with sum s.
    ways = [[0] * (total + 1) for _ in range(n + 1)]
    ways[0][0] = 1
    for x in pooled:
        for k in range(n, 0, -1):
            row, prev = ways[k], ways[k - 1]
            for s in range(total, x - 1, -1):
                row[s] += prev[s - x]
    obs = abs(sum(a) / n - sum(b) / m)
    hits = sum(
        ways[n][s]
        for s in range(total + 1)
        if abs(s / n - (total - s) / m) >= obs - 1e-12
    )
    return hits / comb(n + m, n)


def perm_p_brute(a: list[int], b: list[int]) -> float:
    pooled = a + b
    n, m = len(a), len(b)
    total = sum(pooled)
    obs = abs(sum(a) / n - sum(b) / m)
    splits = list(itertools.combinations(range(n + m), n))
    hits = 0
    for c in splits:
        s = sum(pooled[i] for i in c)
        if abs(s / n - (total - s) / m) >= obs - 1e-12:
            hits += 1
    return hits / len(splits)


def boot_interval(hi: list[int], lo: list[int], rng: random.Random) -> tuple[float, float]:
    diffs = sorted(
        sum(rng.choices(hi, k=len(hi))) / len(hi)
        - sum(rng.choices(lo, k=len(lo))) / len(lo)
        for _ in range(BOOT)
    )
    return diffs[int(0.025 * BOOT)], diffs[int(0.975 * BOOT) - 1]


def material(hi: list[int], lo: list[int], rng: random.Random) -> bool:
    if sum(hi) / len(hi) - sum(lo) / len(lo) < 1:
        return False
    if perm_p(hi, lo) >= 0.05:
        return False
    return boot_interval(hi, lo, rng)[0] > 0


def power(n: int, mean_hi: float, mean_lo: float, rng: random.Random) -> float:
    p_hi, p_lo = mean_hi / TASKS, mean_lo / TASKS
    hits = 0
    for _ in range(REPLICATES):
        hi = [sum(rng.random() < p_hi for _ in range(TASKS)) for _ in range(n)]
        lo = [sum(rng.random() < p_lo for _ in range(TASKS)) for _ in range(n)]
        hits += material(hi, lo, rng)
    return hits / REPLICATES


def self_check(perm=perm_p) -> list[str]:
    """Problems found comparing PERM against brute-force enumeration and
    the known 2/252 minimum; empty when it agrees."""
    problems = []
    rng = random.Random(1)
    for n in (3, 5):
        for _ in range(50):
            a = [rng.randint(0, TASKS) for _ in range(n)]
            b = [rng.randint(0, TASKS) for _ in range(n)]
            if abs(perm(a, b) - perm_p_brute(a, b)) > 1e-12:
                problems.append(f"differs from enumeration on {a} {b}")
    # The smallest two-sided p for 5 against 5 is 2/252.
    if abs(perm([6] * 5, [0] * 5) - 2 / 252) > 1e-12:
        problems.append("smallest p is not 2/252")
    return problems


def planted_one_sided(a: list[int], b: list[int]) -> float:
    """A planted bug: `perm_p` without the absolute value, a one-sided p.
    `self_check` must reject it."""
    pooled = a + b
    n, m = len(a), len(b)
    total = sum(pooled)
    obs = sum(a) / n - sum(b) / m
    splits = list(itertools.combinations(range(n + m), n))
    hits = sum(
        1 for c in splits
        if (s := sum(pooled[i] for i in c)) / n - (total - s) / m >= obs - 1e-12)
    return hits / len(splits)


def main() -> None:
    problems = self_check()
    assert not problems, problems
    assert self_check(planted_one_sided), "self_check accepted the planted one-sided p"
    print(f"replicates {REPLICATES}, bootstrap {BOOT}, seed {SEED}")
    print("true means (higher arm vs lower arm) | n per arm | power")
    for n in (8, 12):
        # The last pair is the 11 October run's Sonnet round-1 means (Python
        # 5.75, Firth 4.38), the gap this run is powered for.
        for mean_lo, mean_hi in ((4.5, 5.5), (4.0, 5.5), (3.5, 5.5), (4.38, 5.75)):
            # Each cell has its own stream, seeded from the seed and the cell
            # (a str seed is hashed the same way in every run), so adding a
            # row cannot move a number already cited.
            rng = random.Random(f"{SEED} {n} {mean_hi} {mean_lo}")
            p = power(n, mean_hi, mean_lo, rng)
            print(f"{mean_hi} vs {mean_lo} | {n} | {p:.2f}")


if __name__ == "__main__":
    main()
