"""The fixed MVP-authoring task set (roadmap "MVP agent authoring").

Twenty tasks, frozen before any model attempts them. They use sequences,
loops, locals and multi-word programs; five (`merge-sorted`, `histogram`,
`sort`, `ledger`, `allocate-batch`) are at allocator weight: several
cooperating words, nested loops or rebuilding a sequence, and more than one
output. `digits` and `primes-up-to` need division, which Firth does not
have, so the author has to build it from subtraction and comparison.

Each `ref` is the task's meaning, written in plain Python independently of
any Firth code; hidden inputs are scored against it and never shown to the
author. `test_mvp.py` checks the refs against hand-worked expected values.
`needs` tags are for grouping failures, not for scoring.
"""
from __future__ import annotations

from task import Task, _t

I, B, SI, SB = "Int", "Bool", "Seq Int", "Seq Bool"


def _longest_run(xs):
    best = run = 0
    for i, x in enumerate(xs):
        run = run + 1 if i and xs[i - 1] == x else 1
        best = max(best, run)
    return (best,)


def _has_pair(xs, target):
    return (any(xs[i] + xs[j] == target for i in range(len(xs)) for j in range(i + 1, len(xs))),)


def _merge(xs, ys):
    return (sorted(xs + ys),)


def _digits(n):
    return ([int(c) for c in str(n)],)


def _primes(n):
    return ([k for k in range(2, n + 1) if all(k % d for d in range(2, k))],)


def _histogram(xs, k):
    return ([xs.count(v) for v in range(k)],)


def _ledger(start, txs):
    balance, rejected = start, 0
    for tx in txs:
        if balance + tx < 0:
            rejected += 1
        else:
            balance += tx
    return balance, rejected


def _allocate_batch(stock, items, qtys, whole):
    stock = list(stock)
    allocated, reasons = [], []
    for item, qty, w in zip(items, qtys, whole):
        remaining = stock[item]
        if qty <= remaining:
            give, reason = qty, 0
        elif remaining == 0:
            give, reason = 0, 2
        elif w:
            give, reason = 0, 3
        else:
            give, reason = remaining, 1
        stock[item] = remaining - give
        allocated.append(give)
        reasons.append(reason)
    return stock, allocated, reasons


MVP: tuple[Task, ...] = (
    _t("seq-sum", "Return the sum of the numbers in the sequence (0 when it is empty).",
       [("xs", SI)], [("total", I)], lambda xs: (sum(xs),),
       ([4, 5, 6],),
       [([],), ([7],), ([-3, 3, 10],), ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10],), ([-5, -6],)],
       ["seq", "loop"]),
    _t("seq-max", "Return the largest number in the sequence. The sequence is never empty.",
       [("xs", SI)], [("largest", I)], lambda xs: (max(xs),),
       ([3, 9, 2],),
       [([5],), ([-4, -2, -9],), ([1, 1, 1],), ([0, -1, 8, 8, 3],), ([10, 9, 8, 7, 6, 5, 4, 3, 2, 1],)],
       ["seq", "loop", "cmp"]),
    _t("count-below", "Count the numbers in the sequence that are strictly less than k.",
       [("xs", SI), ("k", I)], [("count", I)], lambda xs, k: (sum(x < k for x in xs),),
       ([1, 5, 2, 8], 4),
       [([], 3), ([4, 4], 4), ([-1, 0, 1], 0), ([9, 1, 9, 1, 9], 10), ([2, 3], -5)],
       ["seq", "loop", "cmp"]),
    _t("index-of", "Return the index (from 0) of the first element equal to x, or -1 if there is none.",
       [("xs", SI), ("x", I)], [("index", I)],
       lambda xs, x: (xs.index(x) if x in xs else -1,),
       ([7, 3, 9, 3], 3),
       [([], 1), ([5], 5), ([1, 2, 3], 4), ([2, 2, 2], 2), ([0, -1, -2, -3], -3)],
       ["seq", "loop", "cmp"]),
    _t("reverse", "Return the sequence in reverse order.",
       [("xs", SI)], [("reversed", SI)], lambda xs: (xs[::-1],),
       ([1, 2, 3],),
       [([],), ([5],), ([4, -4, 4, -4, 0],), ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0],)],
       ["seq", "loop"]),
    _t("prefix-sums",
       "Return the running totals: element i of the result is the sum of elements 0 to i of the input.",
       [("xs", SI)], [("sums", SI)],
       lambda xs: ([sum(xs[:i + 1]) for i in range(len(xs))],),
       ([1, 2, 3],),
       [([],), ([5],), ([3, -3, 3, -3],), ([10, 20, 30, 40, 50, 60],)],
       ["seq", "loop"]),
    _t("keep-positive", "Return the elements that are greater than 0, in their original order.",
       [("xs", SI)], [("positives", SI)], lambda xs: ([x for x in xs if x > 0],),
       ([3, -1, 0, 4],),
       [([],), ([-1, -2],), ([1, 2, 3],), ([0, 0, 5, 0],), ([-7, 7, -7, 7, 1],)],
       ["seq", "loop", "cmp"]),
    _t("is-sorted",
       "Return true if every element is less than or equal to the next one (an empty or "
       "one-element sequence is sorted).",
       [("xs", SI)], [("sorted", B)],
       lambda xs: (all(xs[i] <= xs[i + 1] for i in range(len(xs) - 1)),),
       ([1, 2, 2, 5],),
       [([],), ([3],), ([2, 1],), ([1, 2, 3, 2],), ([-5, -5, 0, 7],), ([1, 3, 2],)],
       ["seq", "loop", "cmp"]),
    _t("dot", "Both sequences have the same length. Return the sum of xs[i] * ys[i].",
       [("xs", SI), ("ys", SI)], [("product", I)],
       lambda xs, ys: (sum(a * b for a, b in zip(xs, ys)),),
       ([1, 2, 3], [4, 5, 6]),
       [([], []), ([2], [-3]), ([1, 0, -1], [5, 5, 5]), ([3, 3, 3, 3], [1, 2, 3, 4])],
       ["seq", "loop", "mul"]),
    _t("all-true", "Return true if every Boolean in the sequence is true (true for an empty sequence).",
       [("flags", SB)], [("all", B)], lambda bs: (all(bs),),
       ([True, True, False],),
       [([],), ([True],), ([False],), ([True] * 6,), ([True, False, True],)],
       ["seq", "loop"]),
    _t("longest-run",
       "Return the length of the longest run of equal adjacent elements (0 for an empty sequence).",
       [("xs", SI)], [("length", I)], _longest_run,
       ([1, 1, 2, 2, 2, 1],),
       [([],), ([4],), ([1, 2, 3],), ([5, 5, 5, 5],), ([1, 2, 2, 1, 1, 1, 1, 3],)],
       ["seq", "loop", "cmp"]),
    _t("has-pair-sum",
       "Return true if two elements at different positions add up to target.",
       [("xs", SI), ("target", I)], [("found", B)], _has_pair,
       ([1, 4, 6, 2], 8),
       [([], 0), ([4], 8), ([4, 4], 8), ([1, 2, 3], 7), ([5, -2, 9, 0], -2), ([3, 1, 3], 2)],
       ["seq", "nested-loop", "cmp"]),
    _t("count-distinct", "Return how many different values the sequence contains.",
       [("xs", SI)], [("count", I)], lambda xs: (len(set(xs)),),
       ([3, 1, 3, 2, 1],),
       [([],), ([7],), ([2, 2, 2],), ([1, 2, 3, 4, 5],), ([-1, 1, -1, 1, 0],)],
       ["seq", "nested-loop", "cmp"]),
    _t("merge-sorted",
       "Both sequences are sorted in non-decreasing order. Return one sequence with all "
       "their elements, sorted in non-decreasing order.",
       [("xs", SI), ("ys", SI)], [("merged", SI)], _merge,
       ([1, 4, 9], [2, 3, 10]),
       [([], []), ([], [1, 2]), ([5], []), ([1, 1], [1]), ([-3, 0, 8], [-4, 8, 9, 9])],
       ["seq", "loop", "cmp", "heavy"]),
    _t("digits",
       "n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).",
       [("n", I)], [("digits", SI)], _digits,
       (305,),
       [(0,), (7,), (10,), (99,), (420,), (987,), (1005,), (40213,)],
       ["seq", "loop", "cmp", "divmod"]),
    _t("primes-up-to", "Return the prime numbers less than or equal to n, in increasing order.",
       [("n", I)], [("primes", SI)], _primes,
       (10,),
       [(0,), (1,), (2,), (13,), (30,)],
       ["seq", "nested-loop", "cmp", "divmod"]),
    _t("histogram",
       "Every element of xs is between 0 and k - 1. Return a sequence of length k whose "
       "element v is the number of times v occurs in xs.",
       [("xs", SI), ("k", I)], [("counts", SI)], _histogram,
       ([0, 2, 2, 1, 2], 3),
       [([], 2), ([0], 1), ([1, 1, 1], 2), ([3, 0, 3, 1, 0, 3], 4), ([1, 0, 1], 4)],
       ["seq", "nested-loop", "cmp", "heavy"]),
    _t("sort", "Return the elements sorted in non-decreasing order.",
       [("xs", SI)], [("sorted", SI)], lambda xs: (sorted(xs),),
       ([3, 1, 2],),
       [([],), ([5],), ([2, 2, 1],), ([9, -1, 4, -1, 0, 7, 3],), ([6, 5, 4, 3, 2, 1],)],
       ["seq", "nested-loop", "cmp", "heavy"]),
    _t("ledger",
       "Start with balance start. Apply each transaction in txs in order by adding it to the "
       "balance, except that a transaction that would make the balance negative is rejected "
       "and skipped. Return the final balance and the number of rejected transactions.",
       [("start", I), ("txs", SI)], [("balance", I), ("rejected", I)], _ledger,
       (10, [5, -20, -15, 4]),
       [(0, []), (0, [-1]), (5, [-5, -1, 3, -3]), (100, [-50, -60, 20, -70]), (3, [-1, -1, -1, -1, -1])],
       ["seq", "loop", "cmp", "heavy"]),
    _t("allocate-batch",
       "Allocate stock to a batch of orders, one order at a time in order. stock[i] is the "
       "stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says "
       "whether it must be filled completely. For each order, with r the item's current "
       "stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate "
       "nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if "
       "it is false, allocate all r (reason 1). Take what is allocated off that item's stock "
       "before the next order. Return the final stock, the quantity allocated to each order "
       "and each order's reason code.",
       [("stock", SI), ("items", SI), ("qtys", SI), ("whole", SB)],
       [("stock-left", SI), ("allocated", SI), ("reasons", SI)], _allocate_batch,
       ([10, 3], [0, 1, 0, 1], [4, 5, 7, 1], [False, True, False, False]),
       [([5], [], [], []),
        ([0], [0], [3], [False]),
        ([2, 2, 2], [2, 2, 2], [1, 1, 1], [True, True, True]),
        ([4, 9], [1, 0, 1, 0], [9, 5, 1, 0], [True, True, False, False]),
        ([1, 1], [0, 1, 0, 1], [2, 2, 1, 1], [False, False, True, True])],
       ["seq", "loop", "cmp", "heavy"]),
)
