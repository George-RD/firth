#!/usr/bin/env python3
"""Checks for the harder S7 tier, run before any model sees a task.

1. Each task's Python `ref` agrees with values worked out by hand from the
   description, written here without running the refs. Every input of the
   second and third pools and of the scored set keeps to its description's
   stated bounds, and every input and expected integer fits in an `Int`.
2. Each task's Python reference solution (`reference/<set>/python/<id>.py`, written
   separately from the ref) passes its example and hidden tests, and the scored
   set's agree with the meanings on 3,000 seeded random inputs per task.
3. Each task's Firth reference solution (`reference/<set>/firth/<id>.firth`)
   passes its example and hidden tests on both hosts, using at most a
   quarter of the step budget on every case, so an author's slower but
   reasonable program still fits. It also gives the hand values of 1,
   which include edge cases the hidden tests lack.
4. The hidden tests catch the mistakes a careful author is likely to make:
   for every task, a planted Python mutant with one such mistake fails, and
   in each pool and the scored set a planted mutant of a Firth reference fails.
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
    # One day across 2100, which is not a leap year. The weekday: 1 January 2101 is 101 years
    # after 1 January 2000, 25 of them of 366 days, so 36,890 days, a whole number of weeks.
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
    # The third pool. Recursive factorial of 8: main runs in, load, call (3), then out and
    # halt (2); fact(n) for n > 1 runs compare, jump, push, subtract, call, pop, multiply,
    # return (8) around fact(n - 1), and fact(1) runs compare, jump, load, return (4), so
    # 3 + 7 * 8 + 4 + 2 = 65. The multiply last set the flags, from 40,320.
    ("mini-cpu", ([23, 1, 21, 24, 0, 11, 17, 1, 22, 19, 4, 21, 20, 5, 22],
                  [0, 1, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0],
                  [0, 1, 5, 0, 0, 1, 9, 1, 0, 0, 0, 5, 0, 2, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], [0] * 8, [0] * 64, [8]),
     ([40320], 0, 65, 4, [8, 1, 40320, 0, 0, 0, 0, 0], [0] * 64, [False, False, False])),
    # Counting 149 down by 1 takes the load, 149 subtract-and-jumps and the halt: 300, the
    # limit, so the halt runs. From 150 the 300th is the last subtract, and pc is the jump.
    ("mini-cpu", ([1, 4, 16, 0], [1, 0, 0, 0], [1, 0, 1, 0], [0, 1, 0, 0], [149] + [0] * 7, [0] * 64, []),
     ([], 0, 300, 3, [0, 1, 0, 0, 0, 0, 0, 0], [0] * 64, [True, False, False])),
    ("mini-cpu", ([1, 4, 16, 0], [1, 0, 0, 0], [1, 0, 1, 0], [0, 1, 0, 0], [150] + [0] * 7, [0] * 64, []),
     ([], 1, 300, 2, [0, 1, 0, 0, 0, 0, 0, 0], [0] * 64, [True, False, False])),
    # -2^31 - 1 = -2,147,483,649 wraps to 2,147,483,647: N false, V true, so less is taken.
    ("mini-cpu", ([11, 17, 24, 0, 24, 0], [0, 0, 2, 0, 3, 0], [0, 4, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0],
                  [-2**31, 1, 0, 1, 0, 0, 0, 0], [0] * 64, []),
     ([1], 0, 4, 5, [-2**31, 1, 0, 1, 0, 0, 0, 0], [0] * 64, [False, False, True])),
    # Twelve flat I pieces on a well 4 wide each clear a row, in a run: combos 0 to 9 at
    # level 1 make 10 * 100 + 50 * 45 = 3,250; then level 2: (100 + 500) * 2 + (100 + 550) * 2.
    ("stacker", (4, 8, [0] * 12, [0] * 12), ([0, 0, 0, 0], 5750, 12, 12, 0, -1)),
    # Sixteen upright I pieces, four to a column set, clear four rows every fourth lock; the
    # three locks between break the combo. 800, then back-to-back 1,200 twice, then 1,200 at
    # level 2 (12 rows removed before it).
    ("stacker", (4, 8, [0] * 16, [3, 1, 1, 0, 3, 1, 0, 3, 0, 3, 2, 0] * 4), ([0, 0, 0, 0], 5600, 16, 16, 0, -1)),
    # Holding the only piece leaves the queue empty.
    ("stacker", (6, 8, [2], [6]), ([0, 0, 0, 0, 0, 0], 0, 0, 0, 0, 2)),
    # 999,999 overdrawn for one day at 1,000 ppm accrues -999,999,000: 999 taken at the
    # month end (31 May), then the fee.
    ("bank-days", (2023, 5, 31, 1, [0], [1_000_000], 0, 1000, [0], [2], [0], [0], [999_999], [], [], [], []),
     ([-1_001_998], 0, [], 0, 999, 1000)),
    # 1900 is not a leap year: February has 28 days, so both orders pay on the 28th, and
    # 27 days at 1,000,000 plus one at 999,997, at 1,000 ppm, post 27,999 (the 3 in
    # account 1 accrues 3,000, which posts 0). 1 March accrues but posts nothing.
    ("bank-days", (1900, 2, 1, 29, [1_000_000, 0], [0, 0], 1000, 0, [], [], [], [], [], [30, 29], [0, 0], [1, 1], [1, 2]),
     ([1_027_996, 3], 0, [False, False], 27_999, 0, 0)),
    # 2000 is: a 29th day at 1,000,000, so 28,999.
    ("bank-days", (2000, 2, 1, 29, [1_000_000, 0], [0, 0], 1000, 0, [], [], [], [], [], [30, 29], [0, 0], [1, 1], [1, 2]),
     ([1_028_996, 3], 0, [False, False], 28_999, 0, 0)),
    # From 1 April for 61 days: the 31st and 30th orders both pay on 30 April, then on
    # 31 and 30 May; the 29th on 29 April and 29 May.
    ("bank-days", (2023, 4, 1, 61, [10_000, 0, 0], [0, 0, 0], 0, 0, [], [], [], [], [], [31, 30, 29], [0, 0, 0],
                   [1, 2, 1], [10, 20, 40]), ([9860, 100, 40], 0, [False, False, False], 0, 0, 0)),
    # Cells 4, 1 (refers to itself), count of 0..0 = 1, count of 0..1 (reaches the cycle),
    # and an if whose untaken branch still refers to the cycle.
    ("formula-sheet", ([1, 1, 1, 1, 4], [0, 1, 3, 3, 0, 0, 1, 2], [4, 1, 4, 4, 1, 2, 1, 7], [0, 0, 0, 0, 0, 0, 0, 0],
                       [0, 0, 0, 1, 0, 0, 0, 0], [], [], [], [], [], []),
     ([4, 0, 1, 0, 0], [False, True, False, True, True], [])),
    # -7 / 2, 7 / -2 and -7 / -2 round toward zero; 5 / 0 is an error; 0 / 5 is 0.
    ("formula-sheet", ([3] * 5, [0, 0, 2] * 5, [-7, 2, 4, 7, -2, 4, -7, -2, 4, 5, 0, 4, 0, 5, 4], [0] * 15, [0] * 15,
                       [], [], [], [], [], []),
     ([-3, -3, 3, 0, 0], [False, False, False, True, False], [])),
    # Cells 1, 0 + 1, 1 * 0, sum of 0..2 (1, 2, 2, 5). Cell 0 := 2 changes all four (2, 3,
    # 6, 11); again, none; := cell 3 makes the cycle 0, 3, 1 or 2, so all four are errors;
    # := 5 breaks it: 5, 6, 30, 41, all four again.
    ("formula-sheet", ([1, 3, 3, 1], [0, 1, 0, 2, 1, 1, 2, 3], [1, 0, 1, 1, 1, 0, 3, 1], [0] * 8,
                       [0] * 7 + [2], [0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 1, 0], [2, 2, 3, 5],
                       [0, 0, 0, 0], [0, 0, 0, 0]),
     ([5, 6, 30, 41], [False, False, False, False], [4, 0, 4, 4])),
    # Eights against a 6, dealer 16: split; the hands get 3 and 10. 8 + 3 = 11 doubles
    # (100 covers 30) and gets 2: 13 for 20. 18 stands. The dealer draws 5: 21. Both lose.
    ("blackjack", ([8, 6, 8, 10, 3, 10, 2, 5, 9, 10], [100], [10], 1), ([70], 1, 0, 0)),
    # With 20 the split is covered but not the double: 8 + 3 hits to 13 and stands on it.
    ("blackjack", ([8, 6, 8, 10, 3, 10, 2, 5, 9, 10], [20], [10], 1), ([0], 1, 0, 0)),
    # Aces split against a 6: 21 (not a natural) and 20; the dealer's 16 draws 10. Both win.
    ("blackjack", ([1, 6, 1, 10, 12, 9, 10], [100], [10], 1), ([120], 1, 1, 0)),
    # A king up and an ace in the hole: player 1's natural keeps its bet, player 0's 17 loses.
    ("blackjack", ([10, 1, 13, 7, 10, 1], [100, 100], [10, 10], 1), ([90, 100], 1, 0, 1)),
    # Round 2 deals player 0 a natural, then player 1's 12 against a 7 needs a card the
    # shoe lacks: the round, natural included, counts for nothing.
    ("blackjack", ([10, 10, 9, 10, 9, 8, 1, 10, 7, 10, 2, 10], [100, 100], [10, 10], 2), ([110, 110], 1, 0, 0)),
]


# The scored set, worked out the same way: by hand from the descriptions, before the
# meanings were run on these inputs.
HAND += [
    # One push puts the box on the goal; the puzzle is then solved before the second move.
    ("sokoban", (5, 3, [1, 1, 1, 1, 1, 1, 0, 0, 2, 1, 1, 1, 1, 1, 1], 6, [7], [1, 1]),
     (7, [8], 1, 1, 1, 0, 0, 0, True)),
    # Push right to 8: not a goal, wall above and to the right, so dead. Right again is
    # blocked by the wall at 9. Undo takes the push back (worker 6, box 7); two undos with
    # an empty history do nothing; left is blocked by the wall at 5.
    ("sokoban", (5, 4, [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 2, 1, 1, 1, 1, 1, 1], 6, [7], [1, 1, 4, 4, 4, 3]),
     (6, [7], 6, 0, 1, 2, 1, 1, False)),
    # Down is blocked by two boxes (9, then 13). Right to 6, down to 10 and 14; left from 14
    # would push the box on 13 into the wall at 12, so it is blocked.
    ("sokoban", (4, 5, [1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 2, 1, 1, 1, 1, 1], 5, [9, 13], [2, 1, 2, 2, 3]),
     (14, [9, 13], 5, 3, 0, 2, 0, 0, False)),
    # The only box starts on a goal: solved before the first move, so none is read.
    ("sokoban", (4, 3, [1, 1, 1, 1, 1, 0, 2, 1, 1, 1, 1, 1], 5, [6], [3, 4]), (5, [6], 0, 0, 0, 0, 0, 0, True)),
    # The man on 22 must take 17, landing on 13 with no further jump; black then has no
    # piece, so no move, and white has won.
    ("checkers", ([0] * 17 + [3] + [0] * 4 + [1] + [0] * 9, 0, 1),
     ([0] * 13 + [1] + [0] * 18, 1, 1, 0, 0, 1)),
    # No capture: white's lowest piece, 20, steps to 16; black's man on 0 steps to 4; then
    # the two plies are played.
    ("checkers", ([3] + [0] * 19 + [1, 1] + [0] * 10, 0, 2),
     ([0] * 4 + [3] + [0] * 11 + [1] + [0] * 4 + [1] + [0] * 10, 2, 0, 0, 0, 0)),
    # 5 steps to 0 and is crowned; black's 27 steps to 31 and is crowned; the white king on
    # 0 steps to 4. Three plies played, black still has a move.
    ("checkers", ([0] * 5 + [1] + [0] * 21 + [3] + [0] * 4, 0, 3),
     ([0] * 4 + [2] + [0] * 26 + [4], 3, 0, 0, 2, 0)),
    # Black first: 9 takes 13 (landing on 16) and then 21 (landing on 25). White's man on 31
    # steps to 26; two plies.
    ("checkers", ([0] * 9 + [3] + [0] * 3 + [1] + [0] * 7 + [1] + [0] * 9 + [1], 1, 2),
     ([0] * 25 + [3, 1] + [0] * 5, 2, 0, 2, 0, 0)),
    # 21 and 22 can each take 17 (landing on 14 and 13); 21 starts lower.
    ("checkers", ([0] * 17 + [3] + [0] * 3 + [1, 1] + [0] * 9, 0, 1),
     ([0] * 14 + [1] + [0] * 7 + [1] + [0] * 9, 1, 1, 0, 0, 1)),
    # a*b: aab and b match whole; aa and the empty string have no matching start.
    ("regex", ([0, 27, 1], [3, 1, 2, 0], [0, 0, 1, 1, 0, 0]), ([T, T, F, F], [3, 1, -1, -1], 2, T)),
    # (a)+ then a ')' with no '(' open: invalid.
    ("regex", ([31, 0, 32, 28, 32], [2], [0, 0]), ([F], [-1], 0, F)),
    # (a|b)+c?: abc and ba whole; c has no start with an a or b; abcc's longest is abc.
    ("regex", ([31, 0, 30, 1, 32, 28, 2, 29], [3, 2, 1, 4], [0, 1, 2, 1, 0, 2, 0, 1, 2, 2]),
     ([T, T, F, F], [3, 2, -1, 3], 2, T)),
    # a|: the empty branch matches the empty string, and the empty start of b.
    ("regex", ([0, 30], [0, 1, 1], [0, 1]), ([T, T, F], [0, 1, 0], 2, T)),
    # ab*: the star takes only the b, so abab is not whole; its longest start is ab.
    ("regex", ([0, 1, 27], [4, 1], [0, 1, 0, 1, 0]), ([F, T], [2, 1], 1, T)),
    # Round 1: 1, 2, 0 by rating; 0 has the bye; 1 (white, taken first) loses to 2. Round 2:
    # 2 and 0 on 2, then 1, who has the bye. 2 and 0 have had white 0 times; 2's last game
    # was as black and 0 has played none, so 2 has white; a draw. Scores 3, 2, 3;
    # Buchholz 3 (2), 3 (2), 2 + 3.
    ("swiss", ([1500, 2500, 2000], 2, [2, 1]), ([3, 2, 3], [3, 3, 5], [2, 0, 1], [0, 1, 1], 0)),
    # One drawn game; ties broken by rating.
    ("swiss", ([1200, 1300], 1, [1]), ([1, 1], [1, 1], [1, 0], [0, 1], 0)),
    # Round 1: 0 (white) beats 1, 3 (black) beats 2. Round 2 ranks 0, 3, 1, 2: 3 has had
    # white fewer times than 0, so has white, and draws; 1 has white over 2 and wins.
    ("swiss", ([2000, 1900, 1800, 1700], 2, [0, 2, 1, 0]), ([3, 2, 0, 3], [5, 3, 5, 3], [0, 3, 1, 2], [1, 1, 1, 1], 0)),
    # Day 0: 3 ordered, none in stock, all owed; a supply due day 1. Day 1: its 2 units go
    # to the backorder; another supply, due day 2, whose 2 units pay the last 1, leaving 1.
    ("warehouse", (3, [5], [0], [2], [1], [1], [0], [2], [0], [3], [0]), ([1], 15, 3, 0, 0, 2, 0)),
    # The 4 expiring on day 1 are sold first on day 1, then 1 of the 3 expiring on day 2;
    # the other 2 are thrown away on day 3, where the order of 1 is owed and a supply ordered.
    ("warehouse", (4, [2], [0], [1], [10], [1], [0, 0, 1, 3], [1, 1, 2, 2], [0, 0, 0, 0], [3, 4, 5, 1], [2, 1, 0, 0]),
     ([0], 10, 5, 2, 0, 1, 1)),
    # 2 owed from day 0, 1 paid on day 1; the other is cancelled on day 7.
    ("warehouse", (9, [1], [0], [1], [10], [1], [0, 1], [2, 1], [0, 0], [2, 1], [0, 5]), ([0], 1, 1, 0, 1, 1, 0)),
    # Read 3 (miss, miss), write 3 (hit), read 4 (miss, miss): 3 leaves L2 clean, then
    # leaves L1 dirty and goes back into L2 dirty, pushing out the clean 4.
    ("cache-sim", (1, 1, 1, 1, [3, 3, 4], [F, T, F]), (1, 2, 0, 2, 2, 0, 1, [4])),
    # 2 shares L1 set 0 with the dirty 0, which goes back into L2 dirty in place of the clean
    # 1; reading 0 again hits in L2.
    ("cache-sim", (2, 1, 1, 2, [0, 1, 2, 0], [T, F, F, F]), (0, 4, 1, 3, 3, 0, 1, [0, 1])),
    # Reading 7 pushes the dirty 5 out of L2 to memory; the dirty 6 from L1 takes its place.
    ("cache-sim", (1, 1, 1, 1, [5, 6, 7], [T, T, F]), (0, 3, 0, 3, 3, 1, 1, [7])),
]

SCORED_EX = {t.id: t.example for t in SETS["scored"]}

# The scored set's six examples, which an author is shown, also worked out by hand so
# that the shown result does not rest on the meaning alone (Codex, #229).
HAND += [
    # Push down (box 15 to 21: wall below, but no wall left or right, so not dead); step
    # right to 16 and down to 22; push left twice (box to 20, then 19: wall below and to
    # the left, so dead); two undos (box back to 21, worker 22); up to 16, left to 15 and
    # 14; undo (back to 15); right to 16; right into the wall at 17 is blocked.
    ("sokoban", SCORED_EX["sokoban"], (16, [21], 13, 6, 3, 1, 3, 1, F)),
    # White's man on 28 must capture. Over 24 it lands on 21; from there over 16 (to 12,
    # where it stops) takes two, over 17 (to 14), then over 10 (to 7, row 1, where it
    # stops) takes three, so it plays the three. Black's last man, on 16, steps to the
    # lower of 20 and 21. Two plies played; white still has a move.
    ("checkers", SCORED_EX["checkers"],
     ([0] * 7 + [1] + [0] * 12 + [3] + [0] * 11, 2, 3, 0, 0, 0)),
    ("regex", SCORED_EX["regex"], ([T, T, T, F, F, T, F], [3, 2, 4, -1, 2, 1, 2], 4, T)),
    # Round 1: 3 (white) beats 1, 0 (white) draws with 2. Round 2 ranks 3, 0, 2, 1: 3 and 0
    # have each had white once and last played white, so 3 (taken first) has white and
    # loses; 2 and 1 last played black, so 2 has white and wins.
    ("swiss", SCORED_EX["swiss"], ([3, 0, 3, 2], [5, 5, 3, 3], [0, 2, 3, 1], [1, 0, 1, 2], 0)),
    # Day 0: 5 arrive (expiring day 1), 2 shipped. Day 2: the other 3 are thrown away and a
    # supply is ordered, due day 12, after the last day. The orders of 4 (day 3) and 1
    # (day 4) are owed and cancelled on days 10 and 11.
    ("warehouse", SCORED_EX["warehouse"], ([0], 6, 2, 3, 5, 1, 0)),
    # L1 one set of two, L2 one set of two: 1 and 2 miss both; 1 hits L1; 3 misses both,
    # pushing clean 1 out of L2 and dirty 2 out of L1 into L2 (there, so used, dirty);
    # 2 hits L2; 4 misses both (clean 3 leaves each level); 5 misses both, pushing dirty 2
    # out of L2 to memory. Hits 1, 6, 1, 5; 5 reads, 1 write; dirty 4 in L1; L1 holds 4, 5.
    ("cache-sim", SCORED_EX["cache-sim"], (1, 6, 1, 5, 5, 1, 1, [4, 5])),
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


_W32 = (-2**31, 2**31 - 1)
_CPU_A = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 19, 20, 23, 24}   # opcodes whose a is a register


def _cpu_field_ok(op, a, b, c):
    """Each field as the mini-cpu description bounds it for its opcode; unused ones are 0."""
    a_ok = _in(a, 0, 7) if op in _CPU_A else a == 0
    if op == 1:
        b_ok = _in(b, *_W32)
    elif 2 <= op <= 13:
        b_ok = _in(b, 0, 7)
    elif op in (14, 15, 16, 17, 18, 21):
        b_ok = _in(b, -2, 66)
    else:
        b_ok = b == 0
    if op in (3, 4, 5, 6, 7, 11):
        c_ok = _in(c, 0, 7)
    elif op in (9, 10):
        c_ok = _in(c, 0, 31)
    elif op in (12, 13):
        c_ok = _in(c, -64, 64)
    else:
        c_ok = c == 0
    return _in(op, 0, 24) and a_ok and b_ok and c_ok


def _cpu_ok(ops, fa, fb, fc, regs, memory, inputs):
    return (_in(len(ops), 1, 64) and _same_len(ops, fa, fb, fc) and len(regs) == 8 and len(memory) == 64
            and len(inputs) <= 40 and _all_in(regs + memory + inputs, *_W32)
            and all(_cpu_field_ok(*f) for f in zip(ops, fa, fb, fc)))


def _bank3_ok(year, month, day, days, balances, limits, credit, debit,
              tx_day, tx_kind, tx_acct, tx_other, tx_amount, so_dom, so_from, so_to, so_amount):
    n = len(balances)
    return (_in(n, 1, 6) and _same_len(balances, limits) and _all_in(balances + limits, 0, 10**6)
            and _in(year, 1900, 2100) and _date_ok(year, month, day) and _in(days, 1, 120)
            and _in(credit, 0, 1000) and _in(debit, 0, 1000)
            and len(tx_day) <= 60 and _same_len(tx_day, tx_kind, tx_acct, tx_other, tx_amount)
            and all(_in(d, 0, days - 1) and k in (1, 2, 3) and _in(a, 0, n - 1)
                    and (_in(b, 0, n - 1) if k == 3 else b == 0) and _in(x, 1, 10**6)
                    for d, k, a, b, x in zip(tx_day, tx_kind, tx_acct, tx_other, tx_amount))
            and len(so_dom) <= 6 and _same_len(so_dom, so_from, so_to, so_amount)
            and _all_in(so_dom, 1, 31) and _all_in(so_from + so_to, 0, n - 1) and _all_in(so_amount, 1, 10**6))


def _tokens_ok(lens, kinds, xs, ys, zs):
    """formula-sheet tokens: lengths 0 to 8 that add up to the token count, and each
    token's fields as its kind bounds them."""
    return (_all_in(lens, 0, 8) and sum(lens) == len(kinds) and _same_len(kinds, xs, ys, zs)
            and all(k == 0 and _in(x, -10**6, 10**6) and y == z == 0
                    or k == 1 and _in(x, -5, 35) and y == z == 0
                    or k == 2 and _in(x, 1, 8) and y == z == 0
                    or k == 3 and _in(x, 1, 4) and _in(y, -5, 35) and _in(z, -5, 35)
                    for k, x, y, z in zip(kinds, xs, ys, zs)))


def _sheet3_ok(lens, kinds, xs, ys, zs, cells, elens, ekinds, exs, eys, ezs):
    return (_in(len(lens), 1, 20) and _tokens_ok(lens, kinds, xs, ys, zs)
            and len(cells) <= 4 and _same_len(cells, elens) and _all_in(cells, 0, len(lens) - 1)
            and _tokens_ok(elens, ekinds, exs, eys, ezs))


def _soko_ok(width, height, cells, player, boxes, moves):
    """sokoban: the walls all round, and the worker and boxes on distinct cells that are not walls."""
    n = width * height
    if not (_in(width, 3, 12) and _in(height, 3, 12) and len(cells) == n and _all_in(cells, 0, 2)):
        return False
    edge = [r * width + c for r in range(height) for c in range(width)
            if r in (0, height - 1) or c in (0, width - 1)]
    places = [player, *boxes]
    return (all(cells[i] == 1 for i in edge) and _in(len(boxes), 1, 6)
            and all(_in(x, 0, n - 1) and cells[x] != 1 for x in places) and len(set(places)) == len(places)
            and len(moves) <= 200 and _all_in(moves, 0, 4))


def _checkers_ok(board, turn, plies):
    return (len(board) == 32 and _all_in(board, 0, 4)
            and sum(v in (1, 2) for v in board) <= 12 and sum(v in (3, 4) for v in board) <= 12
            and 1 not in board[:4] and 3 not in board[28:] and turn in (0, 1) and _in(plies, 1, 40))


def _warehouse_ok(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    """warehouse: events in day order within the days run, and each expiry as its kind bounds it."""
    p = len(price)
    return (_in(p, 1, 5) and _same_len(price, rp, rq, lead, shelf) and _all_in(price, 1, 1000)
            and _all_in(rp, 0, 100) and _all_in(rq, 1, 200) and _all_in(lead, 1, 10) and _all_in(shelf, 1, 30)
            and _in(days, 1, 60) and len(ev_day) <= 80 and _same_len(ev_day, ev_kind, ev_prod, ev_qty, ev_expiry)
            and all(a <= b for a, b in zip(ev_day, ev_day[1:]))
            and all(_in(d, 0, days - 1) and k in (1, 2) and _in(q, 0, p - 1) and _in(n, 1, 200)
                    and (_in(x, d, d + 60) if k == 1 else x == 0)
                    for d, k, q, n, x in zip(ev_day, ev_kind, ev_prod, ev_qty, ev_expiry)))


# Each pool-2, pool-3 and scored task's stated input bounds, as a check on its own inputs.
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
    # The third pool.
    "mini-cpu": _cpu_ok,
    "stacker": lambda w, h, queue, moves: (_in(w, 4, 10) and _in(h, 4, 10) and len(queue) <= 30
                                           and _all_in(queue, 0, 6) and len(moves) <= 100 and _all_in(moves, 0, 6)),
    "bank-days": _bank3_ok,
    "formula-sheet": _sheet3_ok,
    "blackjack": lambda shoe, banks, bets, rounds: (_in(len(banks), 1, 5) and _same_len(banks, bets)
                                                    and _all_in(banks, 0, 10**5) and _all_in(bets, 1, 1000)
                                                    and _in(rounds, 1, 20) and len(shoe) <= 120
                                                    and _all_in(shoe, 1, 13)),
    # The scored set.
    "sokoban": _soko_ok,
    "checkers": _checkers_ok,
    "regex": lambda pattern, lens, chars: (len(pattern) <= 20 and _all_in(pattern, 0, 32) and _in(len(lens), 1, 8)
                                           and _all_in(lens, 0, 12) and sum(lens) == len(chars)
                                           and _all_in(chars, 0, 25)),
    "swiss": lambda ratings, rounds, results: (_in(len(ratings), 2, 12) and _all_in(ratings, 1000, 3000)
                                               and _in(rounds, 1, 7) and rounds < len(ratings)
                                               and len(results) == rounds * (len(ratings) // 2)
                                               and _all_in(results, 0, 2)),
    "warehouse": _warehouse_ok,
    "cache-sim": lambda s1, w1, s2, w2, addrs, writes: (_in(s1, 1, 4) and _in(w1, 1, 4) and _in(s2, 1, 8)
                                                        and _in(w2, 1, 8) and len(addrs) <= 200
                                                        and _same_len(addrs, writes) and _all_in(addrs, 0, 255)
                                                        and all(isinstance(w, bool) for w in writes)),
}


def ints(v):
    if isinstance(v, bool):
        return []
    if isinstance(v, int):
        return [v]
    return [i for x in v for i in ints(x)]


def bounds() -> None:
    """Every pool-2, pool-3 and scored input keeps to its description's stated
    bounds, and every input and expected integer of every task fits in an `Int`."""
    check(set(BOUNDS) == {t.id for t in SETS["calibration2"] + SETS["calibration3"] + SETS["scored"]},
          "every pool-2, pool-3 and scored task has its bounds")
    for tid, check_args in BOUNDS.items():
        t = BY_ID[tid]
        every = [*cases(t), *(a for i, a, _ in HAND if i == tid)]
        bad = [a for a in every if not check_args(*a)]
        check(not bad, f"{tid}: all {len(every)} inputs keep to the stated bounds (outside: {bad[:1]})")
    check(not BOUNDS["poker"]([2, 3, 4, 5, 6], [0] * 5, [2, 7, 8, 9, 10], [0, 1, 1, 1, 1]),
          "the bounds check refuses a card dealt twice")
    check(not BOUNDS["bank-ledger"]([5], 0, [3], [0], [1], [5]),
          "the bounds check refuses an account number outside the ledger")
    ok_cpu = ([9, 0], [1, 0], [2, 0], [31, 0], [0] * 8, [0] * 64, [])
    check(BOUNDS["mini-cpu"](*ok_cpu) and not BOUNDS["mini-cpu"]([9, 0], [1, 0], [2, 0], [32, 0], [0] * 8, [0] * 64, [])
          and not BOUNDS["mini-cpu"]([24, 0], [1, 0], [0, 0], [3, 0], [0] * 8, [0] * 64, []),
          "the bounds check refuses a shift by 32 and a field an opcode does not use")
    ok_bank = (2023, 2, 28, 3, [5], [0], 0, 0, [2], [1], [0], [0], [1], [], [], [], [])
    check(BOUNDS["bank-days"](*ok_bank)
          and not BOUNDS["bank-days"](*ok_bank[:8], [3], *ok_bank[9:])
          and not BOUNDS["bank-days"](2023, 2, 29, *ok_bank[3:]),
          "the bounds check refuses a transaction after the last day and 29 February 2023")
    ok_sheet = ([1, 0], [1], [1], [0], [0], [1], [1], [0], [7], [0], [0])
    check(BOUNDS["formula-sheet"](*ok_sheet) and not BOUNDS["formula-sheet"]([2, 0], *ok_sheet[1:])
          and not BOUNDS["formula-sheet"](*ok_sheet[:5], [2], *ok_sheet[6:]),
          "the bounds check refuses lengths that do not match the tokens and an edit outside the sheet")
    five = ([1], [0], [1], [0], [0], [0] * 5, [1] * 5, [0] * 5, [1] * 5, [0] * 5, [0] * 5)
    check(BOUNDS["formula-sheet"](*five[:5], [0] * 4, [1] * 4, [0] * 4, [1] * 4, [0] * 4, [0] * 4)
          and not BOUNDS["formula-sheet"](*five), "the bounds check refuses a fifth edit")
    check(BOUNDS["stacker"](4, 10, [0], [0] * 100) and not BOUNDS["stacker"](4, 10, [0], [0] * 101)
          and not BOUNDS["stacker"](4, 11, [0], [0]), "the bounds check refuses 101 moves and an 11-row well")
    bj = BOUNDS["blackjack"]
    check(bj([1] * 120, [0], [1], 20) and not bj([1] * 121, [0], [1], 20) and not bj([1] * 120, [0], [1], 21)
          and not bj([14], [0], [1], 1) and not bj([1], [0], [0], 1),
          "the bounds check refuses a 121-card shoe, a 21st round, a card of 14 and a bet of 0")
    scored_planted()
    for name, tasks in SETS.items():
        big = [(t.id, a) for t in tasks for a in (*cases(t), *(a for i, a, _ in HAND if i == t.id))
               if any(not -2**63 <= i < 2**63 for i in ints([a, t.expected(a)]))]
        check(not big, f"{name}: every input and expected integer fits in an Int (outside: {big[:1]})")
    check(not all(-2**63 <= i < 2**63 for i in ints([[1, 2**63]])), "the Int check refuses 2^63")


def scored_planted() -> None:
    """Each kind of scored-set constraint, shown to refuse a known-bad input: a good
    input passes, and each planted change of it fails."""
    def refuses(tid, good, bad, what):
        check(BOUNDS[tid](*good) and not any(BOUNDS[tid](*b) for b in bad), f"the bounds check refuses {what}")
    room = [1, 1, 1, 1, 1, 1, 0, 0, 2, 1, 1, 1, 1, 1, 1]          # 5 by 3, floor at 6 and 7, a goal at 8
    soko = (5, 3, room, 6, [7], [1])
    refuses("sokoban", soko, [(5, 3, room[:-1], 6, [7], [1]), (5, 3, room[:5] + [0] + room[6:], 6, [7], [1]),
                              (5, 3, room, 5, [7], [1]), (5, 3, room, 7, [7], [1]), (5, 3, room, 6, [], [1]),
                              (5, 3, room, 6, [7], [5])],
            "a sokoban floor of the wrong size, an edge cell that is not a wall, the worker on a wall, "
            "the worker on a box, no box and a move of 5")
    big = [1] * 8 + [1, 0, 0, 0, 0, 0, 0, 1] * 6 + [1] * 8          # 8 by 8, 36 floor cells
    refuses("sokoban", (8, 8, big, 9, [10, 11, 12, 13, 14, 17], [0] * 200),
            [(8, 8, big, 9, [10, 11, 12, 13, 14, 17, 18], [0] * 200), (8, 8, big, 9, [10, 10], [0]),
             (8, 8, big, 9, [10], [0] * 201)],
            "a seventh box, two boxes on one cell and a 201st move")
    board = [3] * 12 + [0] * 8 + [1] * 12
    refuses("checkers", (board, 0, 40),
            [(board[:31], 0, 40), (board[:12] + [1] + board[13:], 0, 40), ([1] + [0] * 31, 0, 1),
             ([0] * 31 + [3], 0, 1), (board, 2, 1), (board, 0, 41)],
            "a board of 31 squares, 13 white pieces, a white man on row 0, a black man on row 7, "
            "a turn of 2 and 41 plies")
    check(BOUNDS["checkers"]([2] + [0] * 30 + [4], 0, 1), "the bounds check takes kings on the far rows")
    refuses("regex", ([0, 27], [1, 2], [0, 0, 1]),
            [([0, 27], [1, 2], [0, 0]), ([0, 27], [1, 2], [0, 0, 1, 1]), ([0] * 21, [0], []),
             ([0], [0] * 9, []), ([0], [13], [0] * 13), ([33], [0], [])],
            "string lengths that do not add up to the letters, 21 tokens, 9 strings, a 13-letter string "
            "and a token of 33")
    refuses("swiss", ([1500, 1600, 1700], 2, [0, 1]),
            [([1500, 1600, 1700], 2, [0]), ([1500, 1600, 1700], 2, [0, 1, 2]), ([1500, 1600, 1700], 3, [0, 1, 2]),
             ([1500, 999], 1, [0])],
            "too few or too many results, as many rounds as players and a rating of 999")
    wh = (10, [5], [0], [1], [2], [3], [0, 2, 2], [1, 2, 1], [0, 0, 0], [4, 1, 2], [60, 0, 2])
    def ev(*cols):
        return (*wh[:6], *cols)
    refuses("warehouse", wh,
            [ev([0, 2], [1, 2, 1], [0, 0, 0], [4, 1, 2], [60, 0, 2]), ev([0, 3, 2], [1, 2, 1], [0, 0, 0], [4, 1, 2],
                                                                        [60, 0, 3]),
             ev([0, 2, 10], [1, 2, 1], [0, 0, 0], [4, 1, 2], [60, 0, 10]),
             ev([0, 2, 2], [1, 2, 1], [0, 0, 0], [4, 1, 2], [61, 0, 2]),
             ev([0, 2, 2], [1, 2, 1], [0, 0, 0], [4, 1, 2], [60, 0, 1]),
             ev([0, 2, 2], [1, 2, 1], [0, 0, 0], [4, 1, 2], [60, 3, 2]),
             ev([0, 2, 2], [1, 2, 1], [0, 1, 0], [4, 1, 2], [60, 0, 2]),
             (10, [5, 6], [0], [1], [2], [3], *wh[6:])],
            "event sequences of unequal length, days that go back, an event on the day after the last, "
            "a delivery expiring 61 days after its day, one expiring the day before its day, an order "
            "with an expiry, a product outside the list and product sequences of unequal length")
    refuses("cache-sim", (4, 4, 8, 8, [0, 255], [True, False]),
            [(4, 4, 8, 8, [0, 255], [True]), (4, 4, 8, 8, [256], [True]), (5, 4, 8, 8, [], []),
             (4, 4, 8, 9, [], [])],
            "addresses and writes of unequal length, block 256, 5 first-level sets and 9 second-level places")


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


def scored_random_agreement(n: int = 3000) -> None:
    """The scored set's Python references, written from the descriptions alone, agree
    with the meanings on n seeded random inputs per task, beyond the hidden tests."""
    import scored
    gens = {"sokoban": lambda s: scored._random_sokoban(s, solve_at=s % 50) if s % 3 == 0
            else scored._random_sokoban(s),
            "checkers": scored._random_checkers, "regex": scored._random_regex,
            "swiss": scored._random_swiss, "warehouse": scored._random_warehouse,
            "cache-sim": scored._random_cache}
    check(set(gens) == {t.id for t in SETS["scored"]}, "every scored task has a generator")

    def disagree(src: str, tid: str) -> int:
        ns: dict = {}
        exec(compile(src, f"{tid}.py", "exec"), ns)
        t = BY_ID[tid]
        return sum(not harness.same(json.loads(json.dumps(as_list(ns["main"](*a), t))), t.expected(a))
                   for a in map(gens[tid], range(n)))
    for tid in gens:
        src = (HERE / "reference" / "scored" / "python" / f"{tid}.py").read_text()
        check(disagree(src, tid) == 0, f"Python reference scored/{tid} agrees with the meaning on {n} seeded inputs")
    # Planted: a reference that cancels a backorder a day late disagrees.
    src = (HERE / "reference" / "scored" / "python" / "warehouse.py").read_text()
    assert src.count("d - 7") == 1
    check(disagree(src.replace("d - 7", "d - 8"), "warehouse") > 0,
          "the seeded comparison catches a warehouse reference that cancels a day late")


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



def meaning_mutant(name: str, old: str, new: str, pool: str = "calibration2.py") -> str:
    """A whole Python answer: a pool's meaning of a task with one plausible
    mistake planted (OLD replaced by NEW), answering through NAME."""
    src = (HERE / pool).read_text()
    assert src.count(old) == 1, f"the mutant's text is not in {pool} once: {old!r}"
    future = "from __future__ import annotations\n"
    src = src.replace(future, future + f"__file__ = {str(HERE / pool)!r}\n", 1)
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

PY_MUTANTS |= {
    "mini-cpu": ("jump if less reads N alone, missing signed overflow",
                 meaning_mutant("_cpu", "17: neg != v", "17: neg", "calibration3.py")),
    "stacker": ("no back-to-back bonus for a second four-row clear",
                meaning_mutant("_stacker", "if len(full) == 4 and last_clear_tetris:", "if False:",
                               "calibration3.py")),
    "bank-days": ("a standing order cancelled after two rejections, in a row or not",
                  meaning_mutant("_bank_days", "so_fails[k] = 0", "pass", "calibration3.py")),
    "formula-sheet": ("only cells on a cycle are errors, not cells that lead to one",
                      meaning_mutant("_formula_sheet",
                                     "cyclic = [any(j in reaches[j] for j in reaches[i]) for i in range(n)]",
                                     "cyclic = [i in reaches[i] for i in range(n)]", "calibration3.py")),
    "blackjack": ("a player stands on a soft 17",
                  meaning_mutant("_blackjack_table", "    if soft:\n        return t <= 17",
                                 "    if soft:\n        return t <= 16", "calibration3.py")),
}

PY_MUTANTS |= {
    "sokoban": ("a pushed box dead whenever two of its sides are walls",
                meaning_mutant("_sokoban", "return (up or down) and (left or right)",
                               "return up + down + left + right >= 2", "scored.py")),
    "checkers": ("a man crowned during a capture jumps on as a king",
                 meaning_mutant("_checkers", "        if _crowns(v, lr):\n            out.append(([land], [over]))\n"
                                "            continue\n        more = _jumps(b, land, v)",
                                "        more = _jumps(b, land, v + 1 if _crowns(v, lr) else v)", "scored.py")),
    "regex": ("a ')' with no '(' open ends the pattern instead of making it invalid",
              meaning_mutant("_regex", "    if pos != len(toks):\n        raise _Bad", "    pass", "scored.py")),
    "swiss": ("with equal whites, white always to the player taken first",
              meaning_mutant("_swiss", 'elif (last[a] == "b") != (last[b] == "b"):', "elif False:", "scored.py")),
    "warehouse": ("stock taken from the lot that arrived first, not the one expiring first",
                  meaning_mutant("_warehouse", "lots[p].sort(key=lambda lot: (lot[1], lot[2]))",
                                 "lots[p].sort(key=lambda lot: lot[2])", "scored.py")),
    "cache-sim": ("a dirty block evicted from the first level written straight to memory",
                  meaning_mutant("_cache_sim", "            l2_write(v[0])", '            c["mw"] += 1', "scored.py")),
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


def reading(name: str, *edits: tuple[str, str]) -> str:
    """The scored meaning of a task as another reading of its description
    would have it: each OLD replaced by NEW, answering through NAME."""
    src = (HERE / "scored.py").read_text()
    for old, new in edits:
        assert src.count(old) == 1, f"the reading's text is not in scored.py once: {old!r}"
        src = src.replace(old, new)
    future = "from __future__ import annotations\n"
    src = src.replace(future, future + f"__file__ = {str(HERE / 'scored.py')!r}\n", 1)
    return src + f"\n\ndef main(*args):\n    return {name}(*args)\n"


# The twelve sentences made explicit before the scored set was frozen (README,
# "The scored set"): each other reading, which the hidden tests must tell apart.
READINGS = [
    ("sokoban", "the solved check made only after a move, never before the first",
     reading("_sokoban", ("    for m in moves:\n        if solved():",
                          "    for i, m in enumerate(moves):\n        if i and solved():"))),
    ("sokoban", "a pushed box dead whenever any two of its sides are walls",
     reading("_sokoban", ("return (up or down) and (left or right)", "return up + down + left + right >= 2"))),
    ("checkers", "captures of equal length broken by their last landing square",
     reading("_checkers", ("key=lambda m: (m[0], m[1]))", "key=lambda m: (m[0], m[1][-1]))"))),
    ("checkers", "the capturing piece's starting square still occupied during the capture",
     reading("_checkers",
             ("        for ls, cs in _jumps(board, i, v):",
              "        global _START\n        _START = i\n        for ls, cs in _jumps(board, i, v):"),
             ("if over < 0 or land < 0 or board[land] != 0 ",
              "if over < 0 or land < 0 or board[land] != 0 or land == _START "))),
    ("checkers", "no loss for a side with no move once the ply limit is reached",
     reading("_checkers",
             ("        moves = _legal(board, side)\n        if not moves:\n"
              "            result = 2 if side == 1 else 1  # the side to move has lost\n            break\n"
              "        if played == plies:\n            break\n",
              "        if played == plies:\n            break\n        moves = _legal(board, side)\n"
              "        if not moves:\n            result = 2 if side == 1 else 1\n            break\n"))),
    ("checkers", "only men crowned by a step counted as crowned",
     reading("_checkers", ("            crowned += 1", "            crowned += 0 if cs else 1"))),
    ("regex", "each postfix operator applied to the bare atom, so a*? is a?",
     reading("_regex", ("        node = atom()\n", "        node = base = atom()\n"),
             ('[peek()], node)', '[peek()], base)'))),
    ("swiss", "a player who has played no game taken to have had black last",
     reading("_swiss", ("last = [None] * n", 'last = ["b"] * n'))),
    ("swiss", "the bye given after pairing, to the player left over",
     reading("_swiss",
             ("        if n % 2 == 1:\n            bye = next(p for p in reversed(order) if not had_bye[p])\n"
              "            unpaired.remove(bye)\n            had_bye[bye] = True\n            score[bye] += 2\n",
              ""),
             ("        while unpaired:\n            a = unpaired.pop(0)",
              "        while len(unpaired) > 1:\n            a = unpaired.pop(0)"),
             ("            games.append((a, b))\n",
              "            games.append((a, b))\n        if unpaired:\n            score[unpaired[0]] += 2\n"))),
    ("warehouse", "a cancelled order counting all the units it asked for",
     reading("_warehouse", ("back[p].append([q - got, d])", "back[p].append([q - got, d, q])"),
             ("cancelled += sum(b[0] for b in back[p] if d - b[1] >= 7)",
              "cancelled += sum(b[2] for b in back[p] if d - b[1] >= 7)"))),
    ("warehouse", "no reorder on the day a supply arrives",
     reading("_warehouse", ("                supply[p] = None\n", "                supply[p] = -1\n"),
             ("            if supply[p] is None and stock(p) <= rp[p]:",
              "            if supply[p] == -1:\n                supply[p] = None\n                continue\n"
              "            if supply[p] is None and stock(p) <= rp[p]:"))),
    ("cache-sim", "a block dirty in both levels counted once",
     reading("_cache_sim", ("dirty = sum(e[1] for s in l1 for e in s) + sum(e[1] for s in l2 for e in s)",
                            "dirty = len({e[0] for s in l1 for e in s if e[1]} | "
                            "{e[0] for s in l2 for e in s if e[1]})"))),
]


def told_apart(tid: str, src: str) -> int:
    """How many of TID's hidden tests the reading SRC answers differently."""
    t = BY_ID[tid]
    ns: dict = {}
    exec(compile(src, f"{tid}-reading.py", "exec"), ns)
    return sum(not harness.same(json.loads(json.dumps(as_list(ns["main"](*args), t))), t.expected(args))
               for args in t.hidden)


def scored_readings() -> None:
    check(len(READINGS) == 12, "the scored set keeps all twelve other readings")
    # Planted: the meaning itself, unchanged, is told apart by no hidden test.
    check(told_apart("warehouse", reading("_warehouse")) == 0,
          "a reading that is the meaning itself is told apart by no hidden test")
    for tid, what, src in READINGS:
        n = told_apart(tid, src)
        check(n > 0, f"{tid}, {what}: told apart by {n} hidden test(s)")


def costliest_problems(record: str) -> list[str]:
    """What is wrong with the scored set's last hidden tests, given a recorded
    output of `costliest.py`: each must be the costliest candidate it ran."""
    import costliest
    every = costliest.candidates()
    rows: dict[str, dict[str, tuple[int | None, bool]]] = {}
    for line in record.splitlines():
        tid, name, cost, ok = line.split("\t")
        rows.setdefault(tid, {})[name] = (None if cost == "None" else int(cost), ok == "True")
    problems = []
    for t in SETS["scored"]:
        got = rows.get(t.id, {})
        if set(got) != {name for name, _ in every[t.id]}:
            problems.append(f"{t.id}: the record does not cover exactly the candidates")
            continue
        bad = [name for name, (cost, ok) in got.items() if cost is None or not ok]
        if bad:
            problems.append(f"{t.id}: the reference failed or disagreed on {bad}")
            continue
        top = max(got, key=lambda name: got[name][0])
        args = dict(every[t.id])[top]
        if json.dumps(list(t.hidden[-1])) != json.dumps(list(args)):
            problems.append(f"{t.id}: the last hidden test is not the costliest candidate, {top}")
    return problems


def scored_costliest() -> None:
    record = (HERE / "costliest.tsv").read_text()
    check(costliest_problems(record) == [], "each scored task's last hidden test is the costliest candidate "
          "in the recorded search (costliest.tsv)")
    # Planted: another candidate recorded as costlier than the one kept.
    lines = record.splitlines()
    k = next(i for i, line in enumerate(lines) if line.startswith("warehouse\t")
             and json.dumps(list(dict(__import__("costliest").candidates()["warehouse"])[line.split("\t")[1]]))
             != json.dumps(list(BY_ID["warehouse"].hidden[-1])))
    tid, name, _, ok = lines[k].split("\t")
    lines[k] = f"{tid}\t{name}\t999999\t{ok}"
    check(any(p.startswith("warehouse: the last hidden test is not") for p in costliest_problems("\n".join(lines))),
          "a record with a costlier warehouse candidate than the last hidden test is refused")
    # The agreement column of costliest.tsv and of the kept Seq Bool regex
    # measurement comes from costliest.agrees: a run that left the hand-worked
    # result agrees; a wrong stack, or a run that did not finish, does not.
    import costliest
    ex = SCORED_EX["regex"]
    good = [[True, True, True, False, False, True, False], [3, 2, 4, -1, 2, 1, 2], 4, True]
    check(costliest.agrees("regex", ex, {"status": "success", "stack": good}),
          "a regex run that leaves the hand-worked example result agrees")
    check(not costliest.agrees("regex", ex, {"status": "success", "stack": good[:2] + [3, True]}),
          "a regex run that counts one whole match too few does not agree")
    check(not costliest.agrees("regex", ex, {"status": "out-of-fuel", "stack": good}),
          "a run that did not finish does not agree, whatever it left")


SEQ_BOOL_RUN = HERE / "runs/2026-10-10-regex-seq-bool"


def _seq_bool_measure():
    sys.path.insert(0, str(SEQ_BOOL_RUN))
    import measure
    return measure


def drafted_problems(record: str, drafted: list[tuple[str, tuple]]) -> list[str]:
    """What is wrong with the README's claim that the `Seq Bool` regex
    reference ran out of steps at the drafted bounds, given a recorded output
    of `measure.py --drafted` (RECORD) and its inputs (DRAFTED): each input
    must be a valid pattern within the drafted bounds and outside the scored
    ones, the record must cover exactly those inputs, every run that finished
    must agree with the meaning, and at least one must have run out of steps."""
    b = _seq_bool_measure().DRAFTED_BOUNDS
    t = BY_ID["regex"]
    problems = []
    for name, (pattern, lens, chars) in drafted:
        if not (len(pattern) <= b["tokens"] and _all_in(pattern, 0, 32) and _in(len(lens), 1, b["strings"])
                and _all_in(lens, 0, b["letters"]) and sum(lens) == len(chars) and _all_in(chars, 0, 25)):
            problems.append(f"{name}: not within the drafted bounds")
        elif BOUNDS["regex"](pattern, lens, chars):
            problems.append(f"{name}: within the scored bounds, so it says nothing about the drafted ones")
        elif not t.expected((pattern, lens, chars))[3]:
            problems.append(f"{name}: not a valid pattern")
    rows = {}
    for line in record.splitlines():
        name, cost, status, ok = line.split("\t")
        rows[name] = (status, ok == "True")
    if set(rows) != {name for name, _ in drafted}:
        return problems + ["the record does not cover exactly the drafted inputs"]
    problems += [f"{name}: finished but disagreed" for name, (status, ok) in rows.items()
                 if status == "success" and not ok]
    problems += [f"{name}: neither finished nor ran out of steps ({status})" for name, (status, _) in rows.items()
                 if status not in ("success", "fuel-exhausted")]
    if not any(status == "fuel-exhausted" for status, _ in rows.values()):
        problems.append("no drafted input ran out of steps")
    return problems


def regex_drafted_bounds() -> None:
    measure = _seq_bool_measure()
    record = (SEQ_BOOL_RUN / "drafted.tsv").read_text()
    check(drafted_problems(record, measure.DRAFTED) == [],
          "the Seq Bool regex reference ran out of steps on an input within the drafted bounds (drafted.tsv)")
    # Planted: the same record with every run finished, an input over the
    # drafted bounds, an input the scored bounds already allow, and a broken
    # pattern.
    finished = record.replace("None\tfuel-exhausted\tFalse", "900000\tsuccess\tTrue")
    check(finished != record and "no drafted input ran out of steps" in drafted_problems(finished, measure.DRAFTED),
          "a drafted record where every run finished is refused")
    (name, (pattern, lens, chars)), *rest = measure.DRAFTED
    for bad, why in (([*pattern, 0], "not within the drafted bounds"),
                     ([0, 27], "within the scored bounds"),
                     ([32, *pattern[1:]], "not a valid pattern")):
        args = (bad, lens, chars) if why != "within the scored bounds" else (bad, [12] * 8, chars[:96])
        check(any(why in q for q in drafted_problems(record, [(name, args), *rest])),
              f"a drafted input that is {why} is refused")
    # The run's outcome is read from firth_run.py's error report: only the
    # fuel-exhausted trap after the whole budget counts as running out.
    trap = "application vm-run: status 'trap', expected 'success': {{'trap': '{}', 'steps': {}}}"
    for kind, steps, want in (("fuel-exhausted", 1000000, "fuel-exhausted"),
                              ("stack-underflow", 1000000, "exit 1"), ("fuel-exhausted", 999999, "exit 1")):
        got = measure.outcome("", json.dumps({"status": "error", "error": trap.format(kind, steps)}), 1)[1]
        check(got == want, f"a {kind} trap after {steps:,} steps reads as {want}")


def regex_drafted_rerun() -> None:
    """Runs the first out-of-steps drafted input again on the toolchain, and
    the hand-worked example, which finishes."""
    measure = _seq_bool_measure()
    statuses = dict(line.split("\t")[::2] for line in (SEQ_BOOL_RUN / "drafted.tsv").read_text().splitlines())
    name, args = next((n, a) for n, a in measure.DRAFTED if statuses.get(n) == "fuel-exhausted")
    got = measure.run(name, args)
    check(got[2] == "fuel-exhausted", f"the Seq Bool regex reference runs out of steps on {name} again ({got[2]})")
    got = measure.run("example", SCORED_EX["regex"])
    check(got[2:] == ("success", True), f"the Seq Bool regex reference finishes the regex example and agrees ({got})")


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

    # The third pool: no back-to-back bonus for a second four-row clear.
    src = (HERE / "reference/calibration3/firth/stacker.firth").read_text()
    t = BY_ID["stacker"]
    b2b = "[ 1200 ] [ { 0 100 300 500 800 } k prim seq-int.at ] if"
    mutant = src.replace(b2b, "[ 800 ] [ { 0 100 300 500 800 } k prim seq-int.at ] if", 1)
    check(b2b in src and mutant != src, "the stacker mutant changes the reference")
    res = tier.score({"stacker": mutant}, "firth", [t])["tasks"]["stacker"]
    check(all(c["ok"] for c in res["cases"]), "the stacker mutant checks and runs on every case")
    check(res["cases"][0]["pass"] and not res["pass"],
          "a Firth stacker reference with no back-to-back bonus passes the example "
          f"and fails the hidden tests ({res['hidden_passed']}/{res['hidden_total']})")

    # The scored set: a box pushed into a corner counted as dead even on a goal.
    src = (HERE / "reference/scored/firth/sokoban.firth").read_text()
    t = BY_ID["sokoban"]
    goal = "cells u prim seq-int.at 2 prim = prim not"
    mutant = src.replace(goal, "true", 1)
    check(src.count(goal) == 1 and mutant != src, "the sokoban mutant changes the reference")
    res = tier.score({"sokoban": mutant}, "firth", [t])["tasks"]["sokoban"]
    check(all(c["ok"] for c in res["cases"]), "the sokoban mutant checks and runs on every case")
    check(res["cases"][0]["pass"] and not res["pass"],
          "a Firth sokoban reference that counts a box in a corner on a goal as dead passes the example "
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
    scored_random_agreement()
    python_mutants()
    scored_readings()
    scored_costliest()
    regex_drafted_bounds()
    prompt_and_repair()
    if "--no-firth" not in sys.argv:
        firth_references()
        firth_mutant()
        regex_drafted_rerun()
    print(f"\n{len(FAILED)} failed" if FAILED else "\nall passed")
    return 1 if FAILED else 0


if __name__ == "__main__":
    raise SystemExit(main())
