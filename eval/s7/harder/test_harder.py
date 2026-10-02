#!/usr/bin/env python3
"""Checks for the harder S7 tier, run before any model sees a task.

1. Each task's Python `ref` agrees with values worked out by hand from the
   description, written here without running the refs. Every input of the
   second pool keeps to its description's stated bounds, and every input
   and expected integer fits in an `Int`.
2. Each task's Python reference solution (`reference/<set>/python/<id>.py`, written
   separately from the ref) passes its example and hidden tests.
3. Each task's Firth reference solution (`reference/<set>/firth/<id>.firth`)
   passes its example and hidden tests on both hosts, using at most a
   quarter of the step budget on every case, so an author's slower but
   reasonable program still fits. It also gives the hand values of 1,
   which include edge cases the hidden tests lack.
4. The hidden tests catch the mistakes a careful author is likely to make:
   for every task, a planted Python mutant with one such mistake fails, and
   in each pool a planted mutant of a Firth reference fails.
5. The prompt carries no hidden input and repair shows only the example.
6. The audit refuses options that widen an author's tools, scoring refuses
   a link named as the answer directory, and the scan run before scoring
   Python finds planted copies of this tier's hidden files.

    python3 eval/s7/harder/test_harder.py            # everything (needs the toolchain)
    python3 eval/s7/harder/test_harder.py --no-firth # 1, 2, the Python part of 4, 5 and 6
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import tier  # noqa: E402
from tier import BY_ID, SETS, harness  # noqa: E402

FAILED = []


def check(ok: bool, what: str) -> None:
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        FAILED.append(what)


MAX = 2**63 - 1  # the largest Int

# (task id, inputs, outputs), worked out by hand from the descriptions.
HAND = [
    # X=20, 7/3+9=39, 9-0=48, X+0+8=66, 0-8=74, 8/2+0=84, 0-6=90, X+X+X=120, X+X+8=148, X81=167.
    ("bowling", ([10, 7, 3, 9, 0, 10, 0, 8, 8, 2, 0, 6, 10, 10, 10, 8, 1],),
     ([20, 39, 48, 66, 74, 84, 90, 120, 148, 167],)),
    ("bowling", ([10] * 12,), ([30, 60, 90, 120, 150, 180, 210, 240, 270, 300],)),
    # Tenth frame 7/3 then 10: 63 + 20.
    ("bowling", ([3, 4] * 9 + [7, 3, 10],), ([7, 14, 21, 28, 35, 42, 49, 56, 63, 83],)),
    # Strike then two gutters: 10, then 0, then 2 a frame.
    ("bowling", ([10, 0, 0] + [1, 1] * 8,), ([10, 10, 12, 14, 16, 18, 20, 22, 24, 26],)),
    # 1 2 miss, 1 hit, 3 miss evicts 2, 2 miss evicts 1.
    ("lru", (2, [1, 2, 1, 3, 2]), (4, [3, 2])),
    ("lru", (1, [5, 5, 5]), (1, [5])),
    ("lru", (1, []), (0, [])),
    ("rpn", ([0, 0, 0, 3, 1], [2, 3, 4, 0, 0]), (14, 0)),
    ("rpn", ([0, 0, 4], [-7, 2, 0]), (-3, 0)),
    ("rpn", ([0, 0, 4], [-1, 5, 0]), (0, 0)),
    ("rpn", ([0, 0, 4, 0, 1], [5, 0, 0, 1, 0]), (0, 2)),
    ("rpn", ([5, 0], [0, 1]), (0, 1)),
    ("rpn", ([], []), (0, 3)),
    ("rpn", ([0, 0, 0, 1], [1, 2, 3, 0]), (0, 3)),
    # 3*3=9, 9*9=81, 81-80=1.
    ("rpn", ([0, 5, 3, 5, 3, 0, 2], [3, 0, 0, 0, 0, 80, 0]), (1, 0)),
    # Delete 2, insert 4.
    ("edit-cost", ([1, 2, 3], [1, 3, 4], 1, 1, 1), (2,)),
    ("edit-cost", ([], [1, 2, 3], 2, 7, 1), (6,)),
    ("edit-cost", ([4, 4], [], 2, 7, 1), (14,)),
    # Replacing costs 5, deleting and inserting 2.
    ("edit-cost", ([1, 2, 3], [1, 9, 3], 1, 1, 5), (2,)),
    ("edit-cost", ([1, 2, 3], [1, 9, 3], 3, 3, 5), (5,)),
    # 0->1->3 costs 2 with 2 hops; 0->2 costs 4.
    ("shortest-hops", (4, [0, 0, 1, 2], [1, 2, 3, 3], [1, 4, 1, 1], 0), ([0, 1, 4, 2], [0, 1, 1, 2])),
    # Zero weights: 2 is reached at 0 by the direct edge, 1 hop.
    ("shortest-hops", (3, [0, 1, 0], [1, 2, 2], [0, 0, 0], 0), ([0, 0, 0], [0, 1, 1])),
    # 0->3 directly costs 3, the same as 0->1->2->3, so 1 hop.
    ("shortest-hops", (4, [0, 1, 2, 0], [1, 2, 3, 3], [1, 1, 1, 3], 0), ([0, 1, 2, 3], [0, 1, 2, 1])),
    ("shortest-hops", (3, [], [], [], 1), ([-1, 0, -1], [-1, 0, -1])),
    ("merge-ranges", ([8, 1, 4, 15], [10, 3, 6, 15]), ([1, 8, 15], [6, 10, 15], 10)),
    ("merge-ranges", ([1, 4], [2, 5]), ([1, 4], [2, 5], 4)),
    ("merge-ranges", ([1, 3], [2, 4]), ([1], [4], 4)),
    ("merge-ranges", ([1, 1], [10, 3]), ([1], [10], 10)),
    ("merge-ranges", ([], []), ([], [], 0)),
    # At the largest Int: a range ending there absorbs the next, touching
    # ranges merge, and ranges a gap apart do not.
    ("merge-ranges", ([1, 5], [MAX, 7]), ([1], [MAX], MAX)),
    ("merge-ranges", ([MAX - 1, MAX], [MAX - 1, MAX]), ([MAX - 1], [MAX], 2)),
    ("merge-ranges", ([MAX, MAX - 3], [MAX, MAX - 2]), ([MAX - 3, MAX], [MAX - 2, MAX], 3)),
    # r0=5, r1=1, r2=1; loop r1*=r0, r0-=r2 five times; halt: 3 + 15 + 1.
    ("tiny-vm", ([1, 0, 5, 1, 1, 1, 1, 2, 1, 4, 1, 0, 3, 0, 2, 6, 0, 3, 0, 0, 0], [0, 0, 0, 0], 100),
     ([0, 120, 1, 0], 19, 0)),
    ("tiny-vm", ([], [1, 2, 3, 4], 10), ([1, 2, 3, 4], 0, 1)),
    ("tiny-vm", ([0, 0, 0], [1, 2, 3, 4], 1), ([1, 2, 3, 4], 1, 0)),
    ("tiny-vm", ([0, 0, 0], [1, 2, 3, 4], 0), ([1, 2, 3, 4], 0, 2)),
    # r1=1, then r0+=r1 and a jump back, forever: 7 executed, r0 = 3.
    ("tiny-vm", ([1, 1, 1, 2, 0, 1, 6, 0, 1], [0, 0, 0, 0], 7), ([3, 1, 0, 0], 7, 2)),
    # Jump to -1 is out of range after one instruction.
    ("tiny-vm", ([6, 0, -1, 0, 0, 0], [1, 0, 0, 0], 10), ([1, 0, 0, 0], 1, 1)),
    # r0 = 6 counts down by 2 until negative: 2 + 3*4 + 2 + 2.
    ("tiny-vm", ([1, 0, 6, 1, 1, 2, 3, 0, 1, 7, 0, 6, 2, 2, 1, 6, 1, 2, 1, 3, 77, 0, 0, 0],
                 [5, 5, 5, 5], 300), ([-2, 2, 11, 77], 18, 0)),
    ("lis-smallest", ([5, 1, 6, 2, 7, 3],), ([1, 2, 3],)),
    ("lis-smallest", ([],), ([],)),
    ("lis-smallest", ([3, 3, 3],), ([3],)),
    ("lis-smallest", ([5, 4, 3, 2, 1],), ([1],)),
    # 1 2 5 6 and 1 2 4 6 are both longest; 4 < 5.
    ("lis-smallest", ([3, 1, 2, 0, 5, 4, 6],), ([1, 2, 4, 6],)),
    ("lis-smallest", ([2, 9, 3, 8, 4],), ([2, 3, 4],)),
]

# The second pool's, worked out the same way.
F, T = False, True
HAND += [
    # Straights: the ace-low one's high card is 5, so 6-high wins.
    ("poker", ([14, 2, 3, 4, 5], [0, 1, 2, 3, 0], [2, 3, 4, 5, 6], [2, 3, 0, 1, 2]), (2, 4, 4)),
    # Ace-low straight flush beats four kings.
    ("poker", ([14, 2, 3, 4, 5], [1] * 5, [13, 13, 13, 13, 12], [0, 1, 2, 3, 0]), (1, 8, 7)),
    # Queen, king, ace, 2, 3 does not wrap: high card loses to a pair.
    ("poker", ([12, 13, 14, 2, 3], [0, 1, 2, 3, 0], [12, 12, 4, 5, 6], [1, 2, 0, 1, 2]), (2, 0, 1)),
    # Two pair, eights and threes, decided by the kicker.
    ("poker", ([8, 8, 3, 3, 14], [0, 1, 0, 1, 2], [8, 8, 3, 3, 13], [2, 3, 2, 3, 3]), (1, 2, 2)),
    ("poker", ([2, 5, 7, 9, 11], [0] * 5, [4, 5, 6, 7, 8], [0, 1, 2, 3, 0]), (1, 5, 4)),
    ("poker", ([3, 3, 3, 2, 2], [0, 1, 2, 0, 1], [14, 13, 12, 11, 9], [3] * 5), (1, 6, 5)),
    # Same ranks, suits do not break the tie.
    ("poker", ([13, 10, 8, 6, 2], [0, 1, 0, 1, 0], [13, 10, 8, 6, 2], [2, 3, 2, 3, 2]), (0, 0, 0)),
    # Pairs of sevens, king and 4 kickers; the last kicker decides.
    ("poker", ([7, 7, 13, 4, 2], [0, 1, 0, 1, 0], [7, 7, 13, 4, 3], [2, 3, 1, 0, 1]), (2, 1, 1)),
    ("poker", ([9, 9, 9, 2, 5], [0, 1, 2, 0, 1], [14, 14, 13, 13, 12], [0, 1, 2, 3, 3]), (1, 3, 2)),
    # 0 draws 1 1-1, 1 beats 2 2-0, 0 wins 3-0 at 2: 0 and 1 on 4 points, 0 by goal difference.
    ("league-table", (3, [0, 1, 2], [1, 2, 0], [1, 2, 0], [1, 0, 3]), ([0, 1, 2], [4, 4, 0])),
    # 2 draws 0 0-0, 1 beats 0 3-0: 2 (0 goal difference) above 0 (-3).
    ("league-table", (3, [2, 1], [0, 0], [0, 3], [0, 0]), ([1, 2, 0], [1, 3, 1])),
    # 3 beat 1: 3 on 3 points, +1. 0 and 1 level (3 points, 0, 2 scored); 1 beat 0.
    ("league-table", (4, [1, 0, 3], [0, 2, 1], [2, 1, 1], [1, 0, 0]), ([3, 1, 0, 2], [3, 3, 0, 3])),
    # 2 on 6. 0, 1 and 3 level (3 points, 0, 2 scored); in that group 1 beat 0 and 0
    # beat 3, so 0 and 1 have 3 head-to-head points each and stay in number order,
    # though 1 beat 0: head-to-head is not worked out again for the two.
    ("league-table", (4, [1, 1, 1, 3, 2], [2, 0, 2, 0, 3], [0, 2, 0, 0, 0], [1, 0, 1, 2, 2]),
     ([2, 0, 1, 3], [3, 3, 6, 3])),
    ("league-table", (2, [], [], [], []), ([0, 1], [0, 0])),
    # 100-30=70; 20-25=-5 is allowed (limit 10) and crosses 0, so -10; month end
    # -10 loses 1, 95 stays; 29 after the deposit; 29-50 < -10 is rejected.
    ("bank-ledger", ([100, 20], 10, [2, 3, 4, 1, 2], [0, 1, 0, 1, 1], [0] * 5, [30, 25, 0, 40, 50]),
     ([95, 29], 1, [F, F])),
    # 0-3 crosses 0: -8; -8-3 = -11 is past the limit.
    ("bank-ledger", ([0], 10, [2, 2], [0, 0], [0, 0], [3, 3]), ([-8], 1, [F])),
    # Three self-transfers freeze 0; then a deposit to 0 and a transfer to 0 are
    # rejected, the last counting against 1.
    ("bank-ledger", ([10, 10], 0, [3, 3, 3, 1, 3], [0, 0, 0, 0, 1], [0] * 5, [5] * 5), ([10, 10], 5, [T, F])),
    # -30, then month ends: -33, -37; 99 stays; 100, 101, 102; 1000, 1010, 1020.
    ("bank-ledger", ([0, 99, 100, 1000], 50, [2, 4, 4], [0, 0, 0], [0, 0, 0], [25, 0, 0]),
     ([-37, 99, 102, 1020], 0, [F, F, F, F])),
    # The fee may pass the limit.
    ("bank-ledger", ([5], 1, [2], [0], [0], [6]), ([-6], 0, [F])),
    # 5 at 100 from the 100 sell, then 2 at 101; the market buy takes 3 left at 101.
    ("order-book", ([0, 0, 0, 0], [1, 1, 0, 0], [101, 100, 101, 0], [5, 5, 7, 6]), ([5, 5, 7, 3], 1005, 3)),
    ("order-book", ([0, 0], [0, 1], [0, 0], [5, 5]), ([0, 0], 0, 0)),
    # Equal prices: the earlier sell first.
    ("order-book", ([0, 0, 0], [1, 1, 0], [100, 100, 100], [2, 2, 3]), ([2, 1, 3], 300, 2)),
    ("order-book", ([0, 1, 0], [1, 0, 0], [100, 0, 100], [5, 0, 5]), ([0, 0, 0], 0, 0)),
    # The cancel removes the 3 units left; the second buy rests.
    ("order-book", ([0, 0, 1, 0], [1, 0, 0, 0], [100, 100, 0, 100], [5, 2, 0, 5]), ([2, 2, 0, 0], 200, 1)),
    # Cancels of itself and of a later operation do nothing.
    ("order-book", ([1, 0, 1, 0], [0, 0, 0, 1], [0, 50, 0, 50], [0, 3, 3, 3]), ([0, 3, 0, 3], 150, 1)),
    # 7 + -3 = 4; 4 / -3 = -1; max 7; two of 7, -3, 4, -1 above 0; 6 refers to itself.
    ("spreadsheet", ([0, 0, 1, 3, 4, 5, 1], [7, -3, 0, 2, 0, 0, 6], [0, 0, 1, 1, 3, 3, 6]),
     ([7, -3, 4, -1, 7, 2, 0], [F, F, F, F, F, F, T])),
    ("spreadsheet", ([0, 0, 3], [-7, 2, 0], [0, 0, 1]), ([-7, 2, -3], [F, F, F])),
    # 3 divides by 0; the count in 4 skips it and counts only the 6.
    ("spreadsheet", ([1, 0, 0, 3, 5], [2, 6, 0, 1, 0], [2, 0, 0, 2, 3]), ([0, 6, 0, 0, 1], [F, F, F, T, F])),
    ("spreadsheet", ([0, 4, 4], [1, 0, 2], [0, 0, 1]), ([1, 1, 0], [F, F, T])),
    # 3 refers to itself, 4 to 3, and the count in 2 covers itself.
    ("spreadsheet", ([0, 0, 5, 1, 1], [3, -1, 0, 4, 3], [0, 0, 4, 3, 0]), ([3, -1, 0, 0, 0], [F, F, T, T, T])),
    ("spreadsheet", ([1], [0], [1]), ([0], [T])),
    # 3 refers to itself; 2 leads to it, not on the cycle; the count in 1 covers 2.
    ("spreadsheet", ([0, 5, 1, 1], [5, 0, 0, 3], [0, 2, 3, 0]), ([5, 0, 0, 0], [F, T, T, T])),
    # 1 refers outside the sheet, so its reference to itself is not followed: no cycle.
    ("spreadsheet", ([5, 1], [1, 1], [1, 50]), ([0, 0], [F, T])),
    ("spreadsheet", ([0, 0, 3, 2], [5, 0, 0, 2], [0, 0, 1, 0]), ([5, 0, 0, 0], [F, F, T, T])),
    # Floor 1 at 1 (stop to 3), 2 at 4 (to 6), 3 at 7 (to 9).
    ("elevator", ([0, 0, 3], [3, 1, 2]), ([7, 1, 4], 9, 3)),
    # The second request comes during the first stop: a second stop.
    ("elevator", ([0, 1], [0, 0]), ([0, 2], 4, 0)),
    ("elevator", ([0, 0], [4, 2]), ([6, 2], 8, 4)),
    ("elevator", ([0, 1], [5, 1]), ([7, 1], 9, 5)),
    # Up to 3 and 4, then back down to 1.
    ("elevator", ([0, 2, 2], [3, 1, 4]), ([3, 11, 6], 13, 7)),
    # Idle at 3 until 10, then down one.
    ("elevator", ([10, 0], [2, 3]), ([11, 3], 13, 4)),
    ("elevator", ([], []), ([], 0, 0)),
    # 31 + 29 days; 1 March 2000 was a Wednesday.
    ("date-diff", (2000, 1, 1, 2000, 3, 1), (60, 2, 61)),
    # 1900 has no 29 February; 1 January 1900 was a Monday, and 1 March 59 days later.
    ("date-diff", (1900, 2, 28, 1900, 3, 1), (1, 3, 60)),
    ("date-diff", (2000, 1, 1, 1999, 12, 31), (-1, 4, 365)),
    ("date-diff", (2024, 1, 1, 2024, 12, 31), (365, 1, 366)),
    # 101 years, 25 of 366 days (2100 is not one): 36,890 days, a whole number of weeks.
    ("date-diff", (2100, 12, 31, 2101, 1, 1), (1, 5, 1)),
    # 0, 3 and 6 taken; freeing 3 leaves blocks of 3 at 3 and 1 at 9; 2 cells fit best at 3.
    ("heap-alloc", (10, [0, 0, 0, 1, 0], [3, 3, 3, 1, 2]), ([0, 3, 6, 0, 3], 2, 1)),
    ("heap-alloc", (10, [0, 1, 1], [4, 5, -1]), ([0, -1, -1], 1, 6)),
    ("heap-alloc", (10, [0, 1, 1], [4, 0, 0]), ([0, 0, -1], 1, 10)),
    ("heap-alloc", (5, [0, 1], [6, 0]), ([-1, -1], 1, 5)),
    # Blocks of 4 at 3 and 10 and of 3 at 17: 4 cells go to 3, then 1 cell to 17.
    ("heap-alloc", (20, [0, 0, 0, 0, 0, 1, 1, 0, 0], [3, 4, 3, 4, 3, 1, 3, 4, 1]),
     ([0, 3, 7, 10, 14, 0, 0, 3, 17], 2, 4)),
    # Freeing two neighbours makes one block of 8.
    ("heap-alloc", (12, [0, 0, 0, 1, 1, 0], [4, 4, 4, 0, 1, 8]), ([0, 4, 8, 0, 0, 0], 0, 0)),
]


def hand_values() -> None:
    for tid, args, want in HAND:
        check(tuple(BY_ID[tid].ref(*args)) == want, f"hand value: {tid}{args} = {want}")
    covered = {tid for tid, _, _ in HAND}
    check(covered == set(BY_ID), f"every task has hand values (missing: {sorted(set(BY_ID) - covered)})")



def _same_len(*seqs):
    return len({len(q) for q in seqs}) == 1


def _in(x, lo, hi):
    return lo <= x <= hi


def _all_in(xs, lo, hi):
    return all(lo <= x <= hi for x in xs)


def _date_ok(y, m, d):
    days = [31, 29 if y % 4 == 0 and (y % 100 or y % 400 == 0) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return _in(y, 1600, 2400) and _in(m, 1, 12) and _in(d, 1, days[m - 1])


def _bank_ok(balances, limit, kinds, accts, others, amounts):
    n = len(balances)
    ops = list(zip(kinds, accts, others, amounts))
    return (_in(n, 1, 8) and _all_in(balances, 0, 10**6) and _in(limit, 0, 10**6) and len(kinds) <= 60
            and _same_len(kinds, accts, others, amounts)
            and all((a, b, x) == (0, 0, 0) if k == 4 else
                    k in (1, 2, 3) and _in(a, 0, n - 1) and _in(x, 1, 10**6)
                    and (_in(b, 0, n - 1) if k == 3 else b == 0) for k, a, b, x in ops))


def _book_ok(kinds, sides, prices, qtys):
    return (len(kinds) <= 40 and _same_len(kinds, sides, prices, qtys)
            and all((s, p) == (0, 0) and _in(q, 0, 39) if k == 1 else
                    k == 0 and s in (0, 1) and (p == 0 or _in(p, 1, 1000)) and _in(q, 1, 100)
                    for k, s, p, q in zip(kinds, sides, prices, qtys)))


def _sheet_ok(kinds, xs, ys):
    return (_in(len(kinds), 1, 25) and _same_len(kinds, xs, ys)
            and all(k in range(6) and (_in(a, -10**6, 10**6) and b == 0 if k == 0 else
                                       _in(a, -100, 100) and _in(b, -100, 100))
                    for k, a, b in zip(kinds, xs, ys)))


# Each pool-2 task's stated input bounds, as a check on its own inputs.
BOUNDS = {
    "poker": lambda r1, s1, r2, s2: (all(len(q) == 5 for q in (r1, s1, r2, s2))
                                     and _all_in(r1 + r2, 2, 14) and _all_in(s1 + s2, 0, 3)
                                     and len(set(zip(r1 + r2, s1 + s2))) == 10),
    "league-table": lambda n, h, a, hg, ag: (_in(n, 2, 10) and len(h) <= 45 and _same_len(h, a, hg, ag)
                                             and _all_in(h + a, 0, n - 1) and all(x != y for x, y in zip(h, a))
                                             and _all_in(hg + ag, 0, 20)),
    "bank-ledger": _bank_ok,
    "order-book": _book_ok,
    "spreadsheet": _sheet_ok,
    "elevator": lambda ts, fs: (len(ts) <= 30 and _same_len(ts, fs) and _all_in(ts, 0, 1000)
                                and _all_in(fs, 0, 20)),
    "date-diff": lambda y1, m1, d1, y2, m2, d2: _date_ok(y1, m1, d1) and _date_ok(y2, m2, d2),
    "heap-alloc": lambda size, kinds, vals: (_in(size, 1, 1000) and len(kinds) <= 40 and _same_len(kinds, vals)
                                             and all(k == 0 and _in(v, 1, 1000) or k == 1 and _in(v, -1000, 1000)
                                                     for k, v in zip(kinds, vals))),
}


def ints(v):
    if isinstance(v, bool):
        return []
    if isinstance(v, int):
        return [v]
    return [i for x in v for i in ints(x)]


def bounds() -> None:
    """Every pool-2 input keeps to its description's stated bounds, and every
    input and expected integer of every task fits in an `Int`."""
    check(set(BOUNDS) == {t.id for t in SETS["calibration2"]}, "every pool-2 task has its bounds")
    for tid, check_args in BOUNDS.items():
        t = BY_ID[tid]
        every = [*cases(t), *(a for i, a, _ in HAND if i == tid)]
        bad = [a for a in every if not check_args(*a)]
        check(not bad, f"{tid}: all {len(every)} inputs keep to the stated bounds (outside: {bad[:1]})")
    check(not BOUNDS["poker"]([2, 3, 4, 5, 6], [0] * 5, [2, 7, 8, 9, 10], [0, 1, 1, 1, 1]),
          "the bounds check refuses a card dealt twice")
    check(not BOUNDS["bank-ledger"]([5], 0, [3], [0], [1], [5]),
          "the bounds check refuses an account number outside the ledger")
    for name, tasks in SETS.items():
        big = [(t.id, a) for t in tasks for a in cases(t)
               if any(not -2**63 <= i < 2**63 for i in ints([a, t.expected(a)]))]
        check(not big, f"{name}: every input and expected integer fits in an Int (outside: {big[:1]})")
    check(not all(-2**63 <= i < 2**63 for i in ints([[1, 2**63]])), "the Int check refuses 2^63")


def cases(t):
    return (t.example, *t.hidden)


def python_references() -> None:
    """In-process: these are our own files, not an author's answer."""
    for name, tasks in SETS.items():
        for t in tasks:
            ns: dict = {}
            exec(compile((HERE / "reference" / name / "python" / f"{t.id}.py").read_text(), f"{t.id}.py", "exec"), ns)
            bad = [args for args in cases(t)
                   if not harness.same(json.loads(json.dumps(as_list(ns["main"](*args), t))), t.expected(args))]
            check(not bad, f"Python reference {name}/{t.id} passes {len(cases(t))} cases (failing: {bad[:1]})")


def as_list(r, t):
    return list(r) if len(t.outputs) > 1 else [r]


def firth_references() -> None:
    for name, tasks in SETS.items():
        sols = {t.id: (HERE / "reference" / name / "firth" / f"{t.id}.firth").read_text() for t in tasks}
        res = tier.score(sols, "firth", list(tasks))
        for t in tasks:
            r = res["tasks"][t.id]
            vis = r["cases"][0]["pass"]
            check(r["pass"] and vis, f"Firth reference {name}/{t.id}: example {'passes' if vis else 'FAILS'}, "
                  f"hidden {r['hidden_passed']}/{r['hidden_total']}")
            most = max((c.get("kernel_cost") or 0) for c in r["cases"])
            check(0 < most <= tier.FUEL // 4,
                  f"Firth reference {name}/{t.id}: most kernel steps on a case {most:,} (budget {tier.FUEL:,})")
    firth_hand_values()


def firth_hand_values() -> None:
    """The Firth references on the hand values, which include cases the hidden
    tests lack (ranges at the largest Int, in the first pool). The merge-ranges reference with
    the gap test written as `last + 1 < s`, which overflows there, fails them."""
    for tid, args, want in HAND:
        src = (HERE / "reference" / tier.SET_OF[tid] / "firth" / f"{tid}.firth").read_text()
        got = tier.run_firth(src, args)
        check(got["ok"] and harness.same(got["stack"], list(want)), f"Firth hand value: {tid}{args} = {want}")
    src = (HERE / "reference/calibration/firth/merge-ranges.firth").read_text()
    gap = "{ s last prim > [ s 1 prim - last prim > ] [ false ] if }"
    check(gap in src, "the merge-ranges reference has the overflow-free gap test")
    bad = src.replace(gap, "{ last 1 prim + s prim < }")
    edge = [(a, w) for tid, a, w in HAND if tid == "merge-ranges" and MAX in a[1]]
    failed = [a for a, w in edge
              if not ((g := tier.run_firth(bad, a))["ok"] and harness.same(g["stack"], list(w)))]
    check(bool(failed), f"the merge-ranges reference with an overflowing gap test fails {len(failed)} hand value(s)")


# One plausible mistake per task, each a whole Python answer. Every one must
# fail at least one hidden test, which shows the hidden tests can fail an answer
# that passes the visible example.
PY_MUTANTS = {
    # The tenth frame's extra rolls scored as frames of their own: frames 1-10 all
    # take a strike bonus, but the walk is right, so this one double-counts only
    # when frame 10 is a spare scored without its bonus.
    "bowling": ("a spare in the tenth frame scored without its bonus roll",
                (HERE / "reference/calibration/python/bowling.py").read_text().replace(
                    "bonus = rolls[pos + 2] if first + second == 10 else 0",
                    "bonus = rolls[pos + 2] if first + second == 10 and frame < 9 else 0")),
    "lru": ("a hit refreshes the key only when the cache is full",
            (HERE / "reference/calibration/python/lru.py").read_text().replace(
                "cache.move_to_end(k)\n", "if len(cache) >= cap:\n                cache.move_to_end(k)\n")),
    "rpn": ("division floors instead of truncating",
            (HERE / "reference/calibration/python/rpn.py").read_text().replace(
                "if q < 0 and q * b != a:", "if False:")),
    "edit-cost": ("the insert and delete costs swapped",
                  (HERE / "reference/calibration/python/edit-cost.py").read_text()
                  .replace("def main(xs, ys, insert, delete, replace):",
                           "def main(xs, ys, delete, insert, replace):")),
    "shortest-hops": ("hops is the fewest edges overall, not among the shortest paths",
                      (HERE / "reference/calibration/python/shortest-hops.py").read_text().replace(
                          "    return [-1 if b is None else b[0] for b in best], "
                          "[-1 if b is None else b[1] for b in best]\n",
                          "    hops = [-1] * n\n    hops[source] = 0\n    frontier = [source]\n"
                          "    while frontier:\n        nxt = []\n        for v in frontier:\n"
                          "            for b, _ in adj[v]:\n                if hops[b] < 0:\n"
                          "                    hops[b] = hops[v] + 1\n                    nxt.append(b)\n"
                          "        frontier = nxt\n"
                          "    return [-1 if b is None else b[0] for b in best], hops\n")),
    "merge-ranges": ("covered counted from the input ranges, so overlaps count twice",
                     (HERE / "reference/calibration/python/merge-ranges.py").read_text().replace(
                         "sum(b - a + 1 for a, b in zip(ms, me))",
                         "sum(b - a + 1 for a, b in zip(starts, ends))")),
    "tiny-vm": ("a halt runs even when the limit is used up",
                (HERE / "reference/calibration/python/tiny-vm.py").read_text().replace(
                    "if executed >= limit:", "if executed >= limit and code[3 * pc] != 0:")),
    "lis-smallest": ("the smallest tail of each length, which need not be a subsequence",
                     "from bisect import bisect_left\n"
                     "def main(xs):\n"
                     "    tails = []\n"
                     "    for x in xs:\n"
                     "        i = bisect_left(tails, x)\n"
                     "        tails[i:i + 1] = [x]\n"
                     "    return tails\n"),
}



def meaning_mutant(name: str, old: str, new: str) -> str:
    """A whole Python answer: the second pool's meaning of a task with one
    plausible mistake planted (OLD replaced by NEW), answering through NAME."""
    src = (HERE / "calibration2.py").read_text()
    assert src.count(old) == 1, f"the mutant's text is not in calibration2.py once: {old!r}"
    future = "from __future__ import annotations\n"
    src = src.replace(future, future + f"__file__ = {str(HERE / 'calibration2.py')!r}\n", 1)
    return src.replace(old, new) + f"\n\ndef main(*args):\n    return {name}(*args)\n"


PY_MUTANTS |= {
    "poker": ("the ace-low straight given the ace as its high card",
              meaning_mutant("_poker", "high = 5", "high = 14")),
    "league-table": ("head-to-head worked out again for teams still level after it",
                     "def main(n, H, A, X, Y):\n"
                     "    pts, gf, ga = [0] * n, [0] * n, [0] * n\n"
                     "    def res(h, a, x, y, t):\n"
                     "        if x > y: t[h] += 3\n"
                     "        elif x < y: t[a] += 3\n"
                     "        else: t[h] += 1; t[a] += 1\n"
                     "    for h, a, x, y in zip(H, A, X, Y):\n"
                     "        res(h, a, x, y, pts); gf[h] += x; ga[h] += y; gf[a] += y; ga[a] += x\n"
                     "    def order(group):\n"
                     "        hp = {t: 0 for t in group}\n"
                     "        for h, a, x, y in zip(H, A, X, Y):\n"
                     "            if h in group and a in group: res(h, a, x, y, hp)\n"
                     "        vals = sorted(set(hp.values()), reverse=True)\n"
                     "        if len(vals) == 1: return sorted(group)\n"
                     "        return [t for v in vals for t in order({u for u in group if hp[u] == v})]\n"
                     "    key = lambda t: (pts[t], gf[t] - ga[t], gf[t])\n"
                     "    out = []\n"
                     "    for k in sorted({key(t) for t in range(n)}, reverse=True):\n"
                     "        out += order({t for t in range(n) if key(t) == k})\n"
                     "    return out, pts\n"),
    "bank-ledger": ("month-end charges on a negative balance rounded toward zero",
                    meaning_mutant("_bank", "(-bal[i] + 9) // 10", "-bal[i] // 10")),
    "order-book": ("what is left of a market order rests in the book",
                   meaning_mutant("_order_book", "        if price != 0:\n            left[i] = want",
                                  "        left[i] = want")),
    "spreadsheet": ("a count takes an error from a cell it counts",
                    meaning_mutant("_sheet", "            val[i] = a\n        elif k == 5:",
                                   "            val[i] = a\n        elif k == 5 and any(err[j] for j in edges[i]):\n"
                                   "            err[i] = True\n        elif k == 5:")),
    "elevator": ("requests that come during a stop served in that stop",
                 meaning_mutant("_elevator", "here = [i for i in pending if floors[i] == floor]",
                                "here = [i for i in range(m) if served[i] < 0 and times[i] <= t + 2 "
                                "and floors[i] == floor] if any(floors[i] == floor for i in pending) else []")),
    "date-diff": ("every fourth year a leap year",
                  meaning_mutant("_date_diff", "return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)",
                                 "return y % 4 == 0")),
    "heap-alloc": ("the first free block that fits, not the smallest",
                   meaning_mutant("_heap", "_, s = min(fit)", "_, s = min(fit, key=lambda f: f[1])")),
}

def python_mutants() -> None:
    check(set(PY_MUTANTS) == set(BY_ID), "every task has a Python mutant")
    for tid, (what, src) in PY_MUTANTS.items():
        t = BY_ID[tid]
        ns: dict = {}
        exec(compile(src, f"{tid}-mutant.py", "exec"), ns)
        caught = [args for args in t.hidden
                  if not harness.same(json.loads(json.dumps(as_list(ns["main"](*args), t))), t.expected(args))]
        example = harness.same(json.loads(json.dumps(as_list(ns["main"](*t.example), t))),
                               t.expected(t.example))
        check(example and bool(caught), f"Python mutant of {tid} ({what}) passes the example and fails "
              f"{len(caught)} hidden test(s)")


def firth_mutant() -> None:
    """A planted bug in a Firth reference of each pool: the scorer must fail it."""
    src = (HERE / "reference/calibration/firth/lru.firth").read_text()
    t = BY_ID["lru"]
    mutant = src.replace("c prim seq-int.len cap prim <", "c prim seq-int.len cap 1 prim + prim <", 1)
    check(mutant != src, "the lru mutant changes the reference")
    res = tier.score({"lru": mutant}, "firth", [t])["tasks"]["lru"]
    check(all(c["ok"] for c in res["cases"]), "the lru mutant checks and runs on every case")
    check(not res["pass"], "a Firth lru reference that holds cap + 1 keys fails the hidden tests "
          f"({res['hidden_passed']}/{res['hidden_total']})")

    # The second pool: month-end charges on a negative balance rounded toward zero.
    src = (HERE / "reference/calibration2/firth/bank-ledger.firth").read_text()
    t = BY_ID["bank-ledger"]
    up = "[ b 0 b prim - 9 prim + 10 prim div prim - ]"
    mutant = src.replace(up, "[ b 0 b prim - 10 prim div prim - ]", 1)
    check(up in src and mutant != src, "the bank-ledger mutant changes the reference")
    res = tier.score({"bank-ledger": mutant}, "firth", [t])["tasks"]["bank-ledger"]
    check(all(c["ok"] for c in res["cases"]), "the bank-ledger mutant checks and runs on every case")
    check(res["cases"][0]["pass"] and not res["pass"],
          "a Firth bank-ledger reference that rounds month-end charges toward zero passes the example "
          f"and fails the hidden tests ({res['hidden_passed']}/{res['hidden_total']})")

def prompt_and_repair() -> None:
    for name, tasks in SETS.items():
        for lang in ("firth", "python"):
            text = tier.prompt(list(tasks), lang)
            check(all(f"## {t.id}\n" in text for t in tasks), f"{name} {lang} prompt lists every task")
            leaked = [t.id for t in tasks for h in t.hidden
                      if len(json.dumps(list(h))) > 12 and
                      ", ".join(harness.lit(v, lang) for v in h) in text]
            check(not leaked, f"{name} {lang} prompt shows no hidden input (leaked: {leaked})")
    t = BY_ID["rpn"]
    results = {"tasks": {"rpn": {"submitted": True, "cases": [
        {"visible": True, "ok": True, "stack": [0, 0], "expected": [14, 0], "pass": False},
        {"visible": False, "ok": True, "stack": [9, 9], "expected": [42, 0], "pass": False}]}}}
    text = tier.repair({"rpn": "def main(k, v): return 0, 0\n"}, results, "python", [t])
    check("[14, 0]" in text and "[42, 0]" not in text and "[9, 9]" not in text,
          "repair shows the example's outcome and nothing from a hidden test")
    results["tasks"]["rpn"]["cases"][0].update(stack=[14, 0], ok=True, **{"pass": True})
    check(tier.repair({"rpn": ""}, results, "python", [t]) == "",
          "repair is empty, so no round runs, when every answer passed its example")


def refusals() -> None:
    """The audit refuses any option that could widen what an author may do,
    however it is spelt, and scoring refuses a link named as answer directory."""
    import subprocess, tempfile
    for opt in ("--check-cmd=/x", "--check-c=/x", "--shell-forms", "--hook=/x"):
        p = subprocess.run([sys.executable, str(HERE / "audit.py"), "/dev/null", "--set", "calibration",
                            "--prompt", "p", "--dir", "d", "--rounds", "1", "--lang", "firth", opt],
                           capture_output=True, text=True)
        check(p.returncode != 0 and "takes only" in p.stderr, f"audit refuses {opt}")
    with tempfile.TemporaryDirectory() as d:
        link = Path(d) / "answers"
        link.symlink_to(HERE / "reference/calibration/firth")
        try:
            tier.load(link, "firth")
            refused = False
        except (OSError, ValueError):
            refused = True
        check(refused, "scoring refuses a link named as the answer directory")
        real = Path(d) / "real"
        real.mkdir()
        (real / "lru.firth").write_text("x")
        (real / "lru.py").write_text("y")
        check(tier.load(real, "firth") == {"lru": "x"} and tier.load(real, "python") == {"lru": "y"},
              "a directory's answers are read in the language scored only")
    sandbox_scan()


def sandbox_scan() -> None:
    """The scan run before scoring Python finds a copy of this tier's hidden
    files where the sandbox would show it, and passes a directory without one."""
    import shutil, subprocess, tempfile
    git = ["git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "init.defaultBranch=main"]
    with tempfile.TemporaryDirectory() as d:
        clean = Path(d) / "clean"
        (clean / "lib").mkdir(parents=True)
        (clean / "lib" / "lru.py").write_text("def main(c, ops):\n    return []\n")
        subprocess.run(git + ["init", "-q", str(clean / "repo")], check=True)
        check(tier.tier_copies((str(clean),)) == [], "the sandbox scan passes a directory with no copy")
        def copy(p: Path) -> None:  # a reference under another name
            (p / "x").mkdir()
            shutil.copy(HERE / "reference/calibration/python/lru.py", p / "x" / "cache.py")

        def named(p: Path) -> None:  # an older revision's directory, content unknown
            (p / "old/eval/s7/harder").mkdir(parents=True)

        def history(p: Path) -> None:  # the tasks in a commit, gone from the checkout
            subprocess.run(git + ["init", "-q", str(p / "r")], check=True)
            shutil.copy(HERE / "calibration.py", p / "r" / "tasks.py")
            subprocess.run(git + ["-C", str(p / "r"), "add", "."], check=True)
            subprocess.run(git + ["-C", str(p / "r"), "commit", "-qm", "x"], check=True)
            (p / "r" / "tasks.py").unlink()
        def results(p: Path) -> None:  # a scored run's results, which hold the hidden tests
            found = sorted((HERE / "runs").rglob("results-1.json"))
            check(bool(found), "a committed run's results-1.json exists to plant")
            if found:
                shutil.copy(found[0], p / "r.json")

        def tests(p: Path) -> None:  # this file, whose hand values are hidden cases
            shutil.copy(Path(__file__), p / "checks.py")
        planted = {"copy": copy, "named": named, "git": history, "results": results, "tests": tests}
        for what, plant in planted.items():
            p = Path(d) / what
            p.mkdir()
            plant(p)
            check(bool(tier.tier_copies((str(p),))), f"the sandbox scan finds a planted copy ({what})")

    # The scan is wired in: scoring Python calls it before running any answer
    # (the planted copies above test the scan itself, not that score uses it).
    class Scanned(Exception):
        pass

    def scanned() -> None:
        raise Scanned
    saved = (os.geteuid, harness.sandbox_preflight, tier.check_sandbox_sources)
    os.geteuid, harness.sandbox_preflight, tier.check_sandbox_sources = (lambda: 0), (lambda: None), scanned
    try:
        tier.score({}, "python", [])
        wired = False
    except Scanned:
        wired = True
    finally:
        os.geteuid, harness.sandbox_preflight, tier.check_sandbox_sources = saved
    check(wired, "scoring Python runs the sandbox scan before any answer")


def main() -> int:
    hand_values()
    bounds()
    refusals()
    python_references()
    python_mutants()
    prompt_and_repair()
    if "--no-firth" not in sys.argv:
        firth_references()
        firth_mutant()
    print(f"\n{len(FAILED)} failed" if FAILED else "\nall passed")
    return 1 if FAILED else 0


if __name__ == "__main__":
    raise SystemExit(main())
