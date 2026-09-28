"""S7 authoring tasks: small stack-in, stack-out problems with hidden tests.

Every task is a word `main` that takes its inputs on the stack (listed bottom
to top) and leaves its outputs on the stack (bottom to top). Values are
non-negative integers and Booleans only, because that is all the portable
runner can pass in or read back.

`needs` records which language capabilities a reasonable solution requires.
`add` means only `prim +`, stack atoms, quotations and `if`; anything else
(`sub`, `cmp`, `mul`, `loop`) depends on primitives the executable profile does
not have yet. The prompt shows the description and one visible example; the
`hidden` inputs are scored against `ref` and never shown to the author.
"""
from __future__ import annotations

from math import gcd

from task import Task, _t  # noqa: F401  (Task is re-exported)


I, B = "Int", "Bool"


def _fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a


def _fact(n):
    r = 1
    for k in range(2, n + 1):
        r *= k
    return r


def _collatz(n):
    steps = 0
    while n != 1:
        n = n // 2 if n % 2 == 0 else 3 * n + 1
        steps += 1
    return steps


TASKS: tuple[Task, ...] = (
    # --- expressible with `prim +` and structural words -----------------------
    _t("triple", "Return three times n.",
       [("n", I)], [("r", I)], lambda n: (3 * n,),
       (4,), [(0,), (1,), (7,), (1000,), (123456,)]),
    _t("sum3", "Return a + b + c.",
       [("a", I), ("b", I), ("c", I)], [("r", I)], lambda a, b, c: (a + b + c,),
       (1, 2, 3), [(0, 0, 0), (5, 0, 9), (10, 20, 30), (1, 1, 999)]),
    _t("times10", "Return ten times n.",
       [("n", I)], [("r", I)], lambda n: (10 * n,),
       (3,), [(0,), (1,), (42,), (999,)]),
    _t("affine", "Return 4*x + 7.",
       [("x", I)], [("r", I)], lambda x: (4 * x + 7,),
       (1,), [(0,), (2,), (10,), (250,)]),
    _t("pair-sum", "Leave b and then a + b on the stack (a + b on top).",
       [("a", I), ("b", I)], [("b", I), ("s", I)], lambda a, b: (b, a + b),
       (2, 5), [(0, 0), (1, 0), (0, 1), (13, 29)]),
    _t("select", "If flag is true return a, otherwise return b.",
       [("a", I), ("b", I), ("flag", B)], [("r", I)], lambda a, b, f: (a if f else b,),
       (7, 9, True), [(7, 9, False), (0, 5, True), (0, 5, False), (3, 3, True)]),
    _t("not", "Return the Boolean negation of p.",
       [("p", B)], [("r", B)], lambda p: (not p,),
       (True,), [(False,), (True,)]),
    _t("and", "Return p AND q.",
       [("p", B), ("q", B)], [("r", B)], lambda p, q: (p and q,),
       (True, False), [(True, True), (False, True), (False, False), (True, False)]),
    _t("xor", "Return p XOR q (true when exactly one is true).",
       [("p", B), ("q", B)], [("r", B)], lambda p, q: (p != q,),
       (True, False), [(True, True), (False, True), (False, False), (True, False)]),
    _t("majority", "Return true when at least two of p, q, r are true.",
       [("p", B), ("q", B), ("r", B)], [("m", B)],
       lambda p, q, r: (p + q + r >= 2,),
       (True, False, True),
       [(False, False, False), (True, True, False), (False, True, False),
        (True, True, True), (False, False, True), (False, True, True)]),
    _t("count-true", "Return how many of p, q, r are true, as an Int.",
       [("p", B), ("q", B), ("r", B)], [("n", I)],
       lambda p, q, r: (int(p) + int(q) + int(r),),
       (True, False, True),
       [(False, False, False), (True, True, True), (False, True, False), (True, True, False)]),
    # --- need subtraction, comparison, multiplication or loops ----------------
    _t("max", "Return the larger of a and b.",
       [("a", I), ("b", I)], [("r", I)], lambda a, b: (max(a, b),),
       (3, 8), [(8, 3), (0, 0), (5, 5), (100, 99), (0, 7)], ["cmp"]),
    _t("min3", "Return the smallest of a, b and c.",
       [("a", I), ("b", I), ("c", I)], [("r", I)], lambda a, b, c: (min(a, b, c),),
       (4, 2, 9), [(1, 2, 3), (3, 2, 1), (2, 3, 1), (5, 5, 5), (0, 9, 9)], ["cmp"]),
    _t("abs-diff", "Return |a - b|.",
       [("a", I), ("b", I)], [("r", I)], lambda a, b: (abs(a - b),),
       (3, 10), [(10, 3), (0, 0), (7, 7), (0, 1000)], ["sub", "cmp"]),
    _t("clamp", "Return x limited to the range lo..hi (lo <= hi is guaranteed).",
       [("x", I), ("lo", I), ("hi", I)], [("r", I)], lambda x, lo, hi: (min(max(x, lo), hi),),
       (15, 0, 10), [(5, 0, 10), (0, 3, 10), (10, 10, 10), (11, 2, 11), (99, 5, 7)], ["cmp"]),
    _t("is-even", "Return true when n is even.",
       [("n", I)], [("r", B)], lambda n: (n % 2 == 0,),
       (6,), [(0,), (1,), (7,), (40,), (41,)], ["sub", "cmp", "loop"]),
    _t("sum-to", "Return 0 + 1 + ... + n.",
       [("n", I)], [("r", I)], lambda n: (n * (n + 1) // 2,),
       (4,), [(0,), (1,), (10,), (30,)], ["sub", "cmp", "loop"]),
    _t("factorial", "Return n! (0! = 1).",
       [("n", I)], [("r", I)], lambda n: (_fact(n),),
       (4,), [(0,), (1,), (5,), (7,)], ["sub", "cmp", "mul", "loop"]),
    _t("fib", "Return the n-th Fibonacci number, with fib(0) = 0 and fib(1) = 1.",
       [("n", I)], [("r", I)], lambda n: (_fib(n),),
       (6,), [(0,), (1,), (2,), (10,), (20,)], ["sub", "cmp", "loop"]),
    _t("gcd", "Return the greatest common divisor of a and b (both at least 1).",
       [("a", I), ("b", I)], [("r", I)], lambda a, b: (gcd(a, b),),
       (12, 18), [(7, 5), (9, 3), (1, 1), (48, 36), (17, 51)], ["sub", "cmp", "loop"]),
    _t("power", "Return base raised to exp (0^0 = 1).",
       [("base", I), ("exp", I)], [("r", I)], lambda b, e: (b ** e,),
       (3, 4), [(2, 0), (0, 0), (0, 3), (2, 10), (5, 3)], ["sub", "cmp", "mul", "loop"]),
    _t("collatz-steps",
       "Return how many Collatz steps it takes n (n >= 1) to reach 1: halve even "
       "numbers, map odd n to 3n + 1.",
       [("n", I)], [("r", I)], lambda n: (_collatz(n),),
       (6,), [(1,), (2,), (3,), (7,), (12,)], ["sub", "cmp", "mul", "loop"]),
)



def _isqrt(n):
    r = 0
    while (r + 1) * (r + 1) <= n:
        r += 1
    return r


def _divisors(n):
    return sum(1 for d in range(1, n + 1) if n % d == 0)


def _prime(n):
    return n >= 2 and all(n % d for d in range(2, n))


def _triangle(a, b, c):
    x, y, z = sorted((a, b, c))
    if x == 0 or x + y <= z:
        return 0
    if x == z:
        return 1
    if x == y or y == z:
        return 2
    return 3


def _allocate(remaining, requested, whole):
    """One step of specs/inventory-allocation.md: (left, allocated, reason)."""
    if requested <= remaining:
        return (remaining - requested, requested, 0)
    if remaining == 0:
        return (0, 0, 2)
    if whole:
        return (remaining, 0, 3)
    return (0, remaining, 1)


# Harder tasks: several cooperating words, more stack juggling, and loops whose
# inputs stay small enough for the 4096-step budget with a plain solution. In
# the PR #113 build one loop iteration over three locals costs about 120 steps,
# so a loop gets roughly 30 iterations; the inputs below are sized for that.
HARD: tuple[Task, ...] = (
    _t("sort3", "Leave a, b and c sorted so the smallest is at the bottom and the largest on top.",
       [("a", I), ("b", I), ("c", I)], [("lo", I), ("mid", I), ("hi", I)],
       lambda a, b, c: tuple(sorted((a, b, c))),
       (3, 1, 2), [(1, 2, 3), (3, 2, 1), (2, 3, 1), (5, 5, 1), (0, 9, 0), (7, 7, 7)], ["cmp"]),
    _t("median3", "Return the middle value of a, b and c.",
       [("a", I), ("b", I), ("c", I)], [("m", I)], lambda a, b, c: (sorted((a, b, c))[1],),
       (9, 1, 5), [(1, 2, 3), (3, 1, 2), (2, 3, 1), (4, 4, 1), (0, 0, 0)], ["cmp"]),
    _t("triangle-kind",
       "Classify side lengths a, b, c: return 0 if they cannot form a triangle with positive "
       "area (a zero side, or the two shorter sides sum to no more than the longest), 1 if "
       "equilateral, 2 if isosceles, 3 if scalene.",
       [("a", I), ("b", I), ("c", I)], [("kind", I)], lambda a, b, c: (_triangle(a, b, c),),
       (3, 4, 5), [(2, 2, 2), (2, 2, 3), (3, 2, 2), (1, 2, 3), (0, 1, 1), (5, 3, 4), (10, 1, 1), (2, 3, 2)],
       ["cmp", "sub"]),
    _t("divmod", "Return the quotient and then the remainder of a divided by b (b is at least 1).",
       [("a", I), ("b", I)], [("q", I), ("r", I)], lambda a, b: (a // b, a % b),
       (17, 5), [(0, 3), (3, 3), (2, 7), (40, 9), (12, 1)], ["cmp", "sub", "loop"]),
    _t("isqrt", "Return the largest r with r * r <= n.",
       [("n", I)], [("r", I)], lambda n: (_isqrt(n),),
       (10,), [(0,), (1,), (3,), (4,), (99,), (100,), (200,)], ["cmp", "mul", "loop"]),
    _t("is-prime", "Return true when n is a prime number.",
       [("n", I)], [("r", B)], lambda n: (_prime(n),),
       (7,), [(0,), (1,), (2,), (9,), (13,), (15,), (11,)], ["cmp", "sub", "loop"]),
    _t("digit-sum", "Return the sum of the decimal digits of n.",
       [("n", I)], [("r", I)], lambda n: (sum(map(int, str(n))),),
       (42,), [(0,), (7,), (10,), (31,), (57,)], ["cmp", "sub", "loop"]),
    _t("lcm", "Return the least common multiple of a and b (both at least 1).",
       [("a", I), ("b", I)], [("r", I)], lambda a, b: (a * b // gcd(a, b),),
       (4, 6), [(1, 1), (3, 5), (6, 3), (6, 9), (7, 7)], ["cmp", "sub", "mul", "loop"]),
    _t("allocate",
       "Allocate stock for one order. If requested <= remaining, allocate all of it (reason 0). "
       "Otherwise, if remaining is 0, allocate nothing (reason 2). Otherwise, if whole is true "
       "the order must be filled completely, so allocate nothing (reason 3); if whole is false "
       "allocate everything that remains (reason 1). Return the stock left, the quantity "
       "allocated and the reason code.",
       [("remaining", I), ("requested", I), ("whole", B)],
       [("left", I), ("allocated", I), ("reason", I)], _allocate,
       (10, 4, False),
       [(10, 10, True), (5, 8, False), (5, 8, True), (0, 3, False), (0, 3, True), (7, 0, True), (0, 0, False)],
       ["cmp", "sub"]),
)

from mvp_tasks import MVP  # noqa: E402  (defined in its own file, frozen separately)
BY_ID = {t.id: t for t in TASKS + HARD + MVP}
assert len(BY_ID) == len(TASKS) + len(HARD) + len(MVP)
