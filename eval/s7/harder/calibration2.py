"""The second calibration pool of the harder S7 tier (`todo.s7-harder-task-tier`).

The first pool (`calibration.py`) was at the ceiling for Sonnet in Python
(24 of 24 on the first attempt) and near it in Firth, so this pool is
harder in the way that pool was not: each task is a larger program with
many rules that interact, of the kind a careful author still gets wrong
in one corner. Like the first pool it is run for calibration only and never
scored; the scored tier is a different, frozen set.

Every description states every bound an answer depends on: the size of
each input, the range of each value, and so the largest result, which
always fits in a 64-bit `Int`. `test_harder.py` checks that no example,
hidden test or hand value has an integer outside those bounds' results.

Each `ref` is the task's meaning, written in plain Python independently of
any Firth code. Hidden inputs are scored against it and never shown to the
author. `test_harder.py` checks the refs against values worked out by hand.
"""
from __future__ import annotations

import random
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from task import Task, _t  # noqa: E402

I, B, SI, SB = "Int", "Bool", "Seq Int", "Seq Bool"


# --- poker -----------------------------------------------------------------

def _poker_hand(ranks, suits):
    count = Counter(ranks)
    groups = sorted(count.items(), key=lambda kv: (-kv[1], -kv[0]))
    shape = [c for _, c in groups]
    flush = len(set(suits)) == 1
    distinct = sorted(count)
    high = None
    if len(distinct) == 5:
        if distinct[4] - distinct[0] == 4:
            high = distinct[4]
        elif distinct == [2, 3, 4, 5, 14]:
            high = 5
    if high is not None:
        return (8 if flush else 4), [high]
    key = [r for r, _ in groups]
    if shape == [4, 1]:
        return 7, key
    if shape == [3, 2]:
        return 6, key
    if flush:
        return 5, key
    if shape == [3, 1, 1]:
        return 3, key
    if shape == [2, 2, 1]:
        return 2, key
    if shape == [2, 1, 1, 1]:
        return 1, key
    return 0, key


def _poker(ranks1, suits1, ranks2, suits2):
    c1, k1 = _poker_hand(ranks1, suits1)
    c2, k2 = _poker_hand(ranks2, suits2)
    a, b = (c1, k1), (c2, k2)
    return (1 if a > b else 2 if b > a else 0), c1, c2


# --- league-table ----------------------------------------------------------

def _league(n, homes, aways, home_goals, away_goals):
    pts, gf, ga = [0] * n, [0] * n, [0] * n

    def result(h, a, x, y, tally):
        if x > y:
            tally[h] += 3
        elif x < y:
            tally[a] += 3
        else:
            tally[h] += 1
            tally[a] += 1
    for h, a, x, y in zip(homes, aways, home_goals, away_goals):
        result(h, a, x, y, pts)
        gf[h] += x
        ga[h] += y
        gf[a] += y
        ga[a] += x
    key = {t: (pts[t], gf[t] - ga[t], gf[t]) for t in range(n)}
    head = [0] * n
    for k in set(key.values()):
        group = {t for t in range(n) if key[t] == k}
        if len(group) > 1:
            for h, a, x, y in zip(homes, aways, home_goals, away_goals):
                if h in group and a in group:
                    result(h, a, x, y, head)
    order = sorted(range(n), key=lambda t: (-pts[t], -(gf[t] - ga[t]), -gf[t], -head[t], t))
    return order, pts


# --- bank-ledger -----------------------------------------------------------

def _bank(balances, limit, kinds, accts, others, amounts):
    bal = list(balances)
    n = len(bal)
    strikes, frozen, rejected = [0] * n, [False] * n, 0
    for kind, a, b, x in zip(kinds, accts, others, amounts):
        if kind == 4:
            for i in range(n):
                if bal[i] < 0:
                    bal[i] -= (-bal[i] + 9) // 10
                elif bal[i] >= 100:
                    bal[i] += bal[i] // 100
            continue
        ok = not frozen[a] and not (kind == 3 and frozen[b])
        if ok and kind == 3 and a == b:
            ok = False
        if ok and kind in (2, 3) and bal[a] - x < -limit:
            ok = False
        if not ok:
            rejected += 1
            strikes[a] += 1
            if strikes[a] == 3:
                frozen[a] = True
            continue
        if kind == 1:
            bal[a] += x
        else:
            before = bal[a]
            bal[a] -= x
            if before >= 0 > bal[a]:
                bal[a] -= 5
            if kind == 3:
                bal[b] += x
    return bal, rejected, frozen


# --- order-book ------------------------------------------------------------

def _order_book(kinds, sides, prices, qtys):
    m = len(kinds)
    left = [0] * m      # quantity still resting, for limit orders in the book
    filled = [0] * m
    value = trades = 0
    for i in range(m):
        if kinds[i] == 1:
            t = qtys[i]
            if 0 <= t < i and kinds[t] == 0 and left[t] > 0:
                left[t] = 0
            continue
        side, price, want = sides[i], prices[i], qtys[i]
        while want > 0:
            best = None
            for j in range(i):
                if kinds[j] != 0 or left[j] == 0 or sides[j] == side:
                    continue
                if side == 0 and price != 0 and prices[j] > price:
                    continue
                if side == 1 and price != 0 and prices[j] < price:
                    continue
                if best is None or (prices[j] < prices[best] if side == 0 else prices[j] > prices[best]):
                    best = j
            if best is None:
                break
            q = min(want, left[best])
            want -= q
            left[best] -= q
            filled[i] += q
            filled[best] += q
            value += q * prices[best]
            trades += 1
        if price != 0:
            left[i] = want
    return filled, value, trades


# --- spreadsheet -----------------------------------------------------------

def _sheet(kinds, xs, ys):
    n = len(kinds)

    def refs(i):
        k, a, b = kinds[i], xs[i], ys[i]
        if k == 0:
            return []
        if k in (1, 2, 3):
            return [a, b]
        return list(range(a, b + 1))

    def bad(i):
        k, a, b = kinds[i], xs[i], ys[i]
        if k in (1, 2, 3):
            return not (0 <= a < n and 0 <= b < n)
        if k in (4, 5):
            return not (0 <= a <= b < n)
        return False
    edges = [[] if bad(i) else refs(i) for i in range(n)]

    def reach(i):
        seen, todo = set(), list(edges[i])
        while todo:
            j = todo.pop()
            if j not in seen:
                seen.add(j)
                todo += edges[j]
        return seen
    reaches = [reach(i) for i in range(n)]
    on_cycle = [i in reaches[i] for i in range(n)]
    cyclic = [on_cycle[i] or any(on_cycle[j] for j in reaches[i]) for i in range(n)]
    val, err = [0] * n, [False] * n
    done = [False] * n

    def ev(i):
        if done[i]:
            return
        done[i] = True
        k, a, b = kinds[i], xs[i], ys[i]
        if bad(i) or cyclic[i]:
            err[i] = True
            return
        for j in edges[i]:
            ev(j)
        if k == 0:
            val[i] = a
        elif k == 5:
            val[i] = sum(1 for j in edges[i] if not err[j] and val[j] > 0)
        elif any(err[j] for j in edges[i]):
            err[i] = True
        elif k == 1:
            val[i] = val[a] + val[b]
        elif k == 2:
            val[i] = val[a] - val[b]
        elif k == 3:
            if val[b] == 0:
                err[i] = True
            else:
                q = abs(val[a]) // abs(val[b])
                val[i] = q if (val[a] < 0) == (val[b] < 0) else -q
        else:
            val[i] = max(val[j] for j in edges[i])
    for i in range(n):
        ev(i)
    return [0 if err[i] else val[i] for i in range(n)], err


# --- elevator --------------------------------------------------------------

def _elevator(times, floors):
    m = len(times)
    served = [-1] * m
    t = floor = travelled = 0
    d = 1
    while True:
        pending = [i for i in range(m) if served[i] < 0 and times[i] <= t]
        if not pending:
            future = [times[i] for i in range(m) if served[i] < 0]
            if not future:
                return served, t, travelled
            t = min(future)
            continue
        here = [i for i in pending if floors[i] == floor]
        if here:
            for i in here:
                served[i] = t
            t += 2
            continue
        if not any((floors[i] - floor) * d > 0 for i in pending):
            d = -d
        floor += d
        t += 1
        travelled += 1


# --- date-diff -------------------------------------------------------------

def _leap(y):
    return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)


_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


def _day_of_year(y, m, d):
    return sum(_MONTH[:m - 1]) + (1 if m > 2 and _leap(y) else 0) + d


def _ordinal(y, m, d):
    years = sum(366 if _leap(z) else 365 for z in range(1600, y))
    return years + _day_of_year(y, m, d)


def _date_diff(y1, m1, d1, y2, m2, d2):
    a, b = _ordinal(y1, m1, d1), _ordinal(y2, m2, d2)
    # 1 January 2000 was a Saturday (5, counting Monday as 0).
    weekday = (5 + b - _ordinal(2000, 1, 1)) % 7
    return b - a, weekday, _day_of_year(y2, m2, d2)


# --- heap-alloc ------------------------------------------------------------

def _heap(size, kinds, vals):
    used = [False] * size
    live = {}  # op index -> (start, length) of a block not yet freed
    results = []

    def blocks():
        out, i = [], 0
        while i < size:
            if used[i]:
                i += 1
                continue
            j = i
            while j < size and not used[j]:
                j += 1
            out.append((i, j - i))
            i = j
        return out
    for i, (k, v) in enumerate(zip(kinds, vals)):
        if k == 0:
            fit = [(n, s) for s, n in blocks() if n >= v]
            if not fit:
                results.append(-1)
                continue
            _, s = min(fit)
            for c in range(s, s + v):
                used[c] = True
            live[i] = (s, v)
            results.append(s)
        else:
            if v not in live:
                results.append(-1)
                continue
            s, n = live.pop(v)
            for c in range(s, s + n):
                used[c] = False
            results.append(0)
    free = blocks()
    return results, len(free), max((n for _, n in free), default=0)


# --- hidden-test generators (seeded, so the tests are fixed) ---------------

def _random_hands(seed, count):
    rng = random.Random(seed)
    out = []
    for _ in range(count):
        cards = rng.sample([(r, s) for r in range(2, 15) for s in range(4)], 10)
        r1, s1 = [c[0] for c in cards[:5]], [c[1] for c in cards[:5]]
        r2, s2 = [c[0] for c in cards[5:]], [c[1] for c in cards[5:]]
        out.append((r1, s1, r2, s2))
    return out


def _random_league(seed, n, m):
    rng = random.Random(seed)
    homes, aways, hg, ag = [], [], [], []
    for _ in range(m):
        h, a = rng.sample(range(n), 2)
        homes.append(h)
        aways.append(a)
        hg.append(rng.randint(0, 4))
        ag.append(rng.randint(0, 4))
    return n, homes, aways, hg, ag


def _random_bank(seed, n, m):
    rng = random.Random(seed)
    balances = [rng.choice([0, 50, 100, 250, 1000, 12345]) for _ in range(n)]
    kinds, accts, others, amounts = [], [], [], []
    for _ in range(m):
        k = rng.choice([1, 2, 2, 3, 3, 3, 4])
        a = rng.randrange(n)
        b = rng.randrange(n) if k == 3 else 0
        kinds.append(k)
        accts.append(0 if k == 4 else a)
        others.append(b)
        amounts.append(0 if k == 4 else rng.choice([1, 7, 40, 99, 150, 600, 2000]))
    return balances, rng.choice([0, 100, 500]), kinds, accts, others, amounts


def _random_book(seed, m):
    rng = random.Random(seed)
    kinds, sides, prices, qtys = [], [], [], []
    for i in range(m):
        if i > 2 and rng.random() < 0.15:
            kinds.append(1)
            sides.append(0)
            prices.append(0)
            qtys.append(rng.randrange(i))
            continue
        kinds.append(0)
        sides.append(rng.randrange(2))
        prices.append(0 if rng.random() < 0.15 else rng.randint(95, 105))
        qtys.append(rng.randint(1, 30))
    return kinds, sides, prices, qtys


def _random_sheet(seed, n):
    rng = random.Random(seed)
    kinds, xs, ys = [], [], []
    for i in range(n):
        k = rng.choice([0, 0, 0, 1, 2, 3, 4, 5]) if i else 0
        if k == 0:
            a, b = rng.randint(-50, 50), 0
        elif k in (1, 2, 3):
            a, b = rng.randrange(n), rng.randrange(n)
        else:
            a = rng.randrange(n)
            b = min(n - 1, a + rng.randrange(4))
        kinds.append(k)
        xs.append(a)
        ys.append(b)
    return kinds, xs, ys


def _random_lift(seed, m):
    rng = random.Random(seed)
    times = sorted(rng.randint(0, 120) for _ in range(m))
    return times, [rng.randint(0, 20) for _ in range(m)]


def _random_heap(seed, size, m):
    rng = random.Random(seed)
    kinds, vals, allocs = [], [], []
    for i in range(m):
        if allocs and rng.random() < 0.4:
            kinds.append(1)
            vals.append(rng.choice(allocs))
        else:
            kinds.append(0)
            vals.append(rng.randint(1, size // 4))
            allocs.append(i)
    return size, kinds, vals


CALIBRATION2: tuple[Task, ...] = (
    _t("poker",
       "Compare two five-card poker hands. Hand 1 is ranks1 and suits1, hand 2 is ranks2 and "
       "suits2: card i of a hand has rank ranks[i] (2 to 10, then 11 jack, 12 queen, 13 king, "
       "14 ace) and suit suits[i] (0 to 3). Each sequence has exactly five elements, and the "
       "ten cards are all different. Each hand has a category, from best to worst: 8 straight "
       "flush, 7 four of a kind, 6 full house (three of one rank and two of another), 5 flush "
       "(all one suit), 4 straight, 3 three of a kind, 2 two pair, 1 one pair, 0 high card. A "
       "straight is five consecutive ranks, and ace, 2, 3, 4, 5 is also a straight, the lowest "
       "one, whose high card is the 5; a straight does not wrap (queen, king, ace, 2, 3 is not "
       "one). A straight that is also a flush is a straight flush only. The better category "
       "wins. Hands of the same category are compared as follows: two straights or two "
       "straight flushes by their high card; otherwise, group each hand's cards by rank, order "
       "the groups by size, largest first, and groups of the same size by rank, highest first, "
       "and compare the two lists of group ranks from the first element, the first difference "
       "deciding. Suits never break a tie. Return the winner (1 or 2, or 0 when neither hand "
       "is better), then the category of hand 1 and of hand 2.",
       [("ranks1", SI), ("suits1", SI), ("ranks2", SI), ("suits2", SI)],
       [("winner", I), ("category1", I), ("category2", I)], _poker,
       ([10, 11, 12, 13, 14], [2, 2, 2, 2, 2], [9, 9, 9, 9, 3], [0, 1, 2, 3, 0]),
       [([14, 2, 3, 4, 5], [0, 1, 2, 3, 0], [2, 3, 4, 5, 6], [2, 3, 0, 1, 2]),
        ([14, 2, 3, 4, 5], [1, 1, 1, 1, 1], [13, 13, 13, 13, 14], [0, 1, 2, 3, 0]),
        ([5, 4, 3, 2, 14], [0, 0, 1, 2, 3], [9, 10, 11, 12, 13], [1, 2, 3, 0, 1]),
        ([12, 13, 14, 2, 3], [0, 1, 2, 3, 0], [12, 12, 4, 5, 6], [1, 2, 0, 1, 2]),
        ([5, 5, 5, 9, 9], [0, 1, 2, 0, 1], [4, 4, 4, 14, 14], [0, 1, 2, 2, 3]),
        ([8, 8, 3, 3, 14], [0, 1, 0, 1, 2], [8, 8, 3, 3, 13], [2, 3, 2, 3, 3]),
        ([8, 8, 3, 3, 13], [0, 1, 0, 1, 2], [8, 8, 5, 5, 2], [2, 3, 2, 3, 3]),
        ([14, 12, 9, 6, 3], [0, 0, 0, 0, 0], [14, 12, 9, 6, 2], [1, 1, 1, 1, 1]),
        ([14, 12, 9, 6, 3], [0, 1, 0, 0, 0], [14, 12, 9, 6, 3], [1, 2, 1, 1, 1]),
        ([14, 12, 9, 6, 3], [0, 1, 0, 0, 0], [14, 12, 9, 6, 3], [2, 2, 3, 3, 3]),
        ([7, 7, 13, 4, 2], [0, 1, 0, 1, 0], [7, 7, 13, 4, 3], [2, 3, 1, 0, 1]),
        ([5, 6, 7, 8, 9], [3, 3, 3, 3, 3], [10, 10, 10, 10, 2], [0, 1, 2, 3, 0]),
        ([2, 2, 2, 13, 12], [0, 1, 2, 0, 1], [14, 14, 13, 13, 12], [0, 1, 2, 3, 3]),
        ([3, 4, 5, 6, 7], [0, 1, 0, 1, 0], [3, 4, 5, 6, 7], [2, 3, 2, 3, 2]),
        ([11, 11, 11, 2, 2], [0, 1, 2, 0, 1], [11, 9, 10, 8, 7], [3, 3, 3, 3, 3]),
        *_random_hands(2, 8)],
       ["seq", "loop", "rules", "sort"]),
    _t("league-table",
       "A league has n teams, numbered 0 to n - 1. Match k was played at home by team homes[k] "
       "against team aways[k] (a different team) and ended home_goals[k] to away_goals[k]; "
       "the four sequences have the same length, and two teams may meet any number of times. "
       "A win is worth 3 points, a draw 1 point to each team, a loss 0. Rank the teams: more "
       "points first; then greater goal difference (goals scored minus goals conceded); then "
       "more goals scored. Teams still level on all three form a tied group, and within it "
       "the team with more head-to-head points goes first, counting only the matches between "
       "two teams of that same group (this is worked out once per group, from the whole "
       "group; it is not repeated for teams still level). Teams still level after that are "
       "ordered by lower number first. Return the team numbers in ranking order, best first, "
       "and the points of each team, indexed by team number. n is 2 to 10, there are at most "
       "45 matches, and every goal count is 0 to 20.",
       [("n", I), ("homes", SI), ("aways", SI), ("home-goals", SI), ("away-goals", SI)],
       [("order", SI), ("points", SI)], _league,
       (4, [0, 1, 2, 3, 0, 1], [1, 2, 3, 0, 2, 3], [2, 1, 0, 1, 3, 2], [0, 1, 0, 3, 3, 2]),
       [(2, [], [], [], []),
        (3, [0, 1, 2], [1, 2, 0], [1, 1, 1], [0, 0, 0]),
        (3, [0, 1, 2], [1, 2, 0], [2, 1, 1], [0, 0, 0]),
        (3, [2, 1], [0, 0], [0, 3], [0, 0]),
        (3, [0, 2], [1, 1], [3, 0], [0, 3]),
        (4, [0, 2, 0, 1], [1, 3, 3, 2], [1, 1, 0, 0], [0, 0, 1, 1]),
        (4, [0, 1, 2, 3, 0, 1, 2, 3], [1, 0, 3, 2, 2, 3, 0, 1],
         [1, 2, 1, 2, 0, 0, 0, 0], [0, 1, 0, 1, 0, 0, 0, 0]),
        (5, [0, 1, 2, 3, 4, 0], [1, 2, 0, 4, 3, 4], [1, 1, 1, 2, 0, 0], [0, 0, 0, 0, 2, 5]),
        (4, [0, 1, 2, 3, 0, 2], [1, 0, 3, 2, 3, 1], [2, 0, 1, 1, 1, 1], [0, 0, 0, 0, 1, 1]),
        (6, [0, 2, 4, 1, 3, 5, 0, 1], [1, 3, 5, 2, 4, 0, 3, 4],
         [3, 3, 3, 0, 0, 0, 0, 0], [1, 1, 1, 0, 0, 0, 0, 0]),
        (3, [0, 0, 1], [1, 1, 0], [20, 0, 0], [0, 20, 0]),
        (4, [1, 1, 1, 3, 2], [2, 0, 2, 0, 3], [0, 2, 0, 0, 0], [1, 0, 1, 2, 2]),
        (6, [2, 4, 3, 4, 2, 3, 5, 0, 3, 0, 1], [0, 1, 2, 5, 0, 2, 3, 4, 5, 5, 4],
         [1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0], [1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1]),
        _random_league(3, 8, 30), _random_league(4, 10, 45), _random_league(5, 6, 20)],
       ["seq", "nested-loop", "rules", "sort", "heavy"]),
    _t("bank-ledger",
       "Run operations on n bank accounts, numbered 0 to n - 1, whose balances start as "
       "balances (n is the length of balances). Operation k is kinds[k] with account accts[k], "
       "second account others[k] and amount amounts[k] (the four sequences have the same "
       "length). Kinds: 1 deposits the amount into account a = accts[k]; 2 withdraws it from "
       "a; 3 transfers it from a to b = others[k]; 4 is a month end. A deposit, withdrawal or "
       "transfer is rejected, and changes no balance, when a is frozen, when it is a transfer "
       "and b is frozen, when it is a transfer with a equal to b, or when it is a withdrawal "
       "or transfer that would leave a's balance below -limit. Otherwise it is carried out; "
       "if a withdrawal or transfer takes a's balance from 0 or more to below 0, a fee of 5 is "
       "also taken from a (the fee may take the balance below -limit). Each rejection counts "
       "against account a, whatever the reason, and an account becomes frozen once 3 "
       "operations have been rejected against it; it stays frozen. A month end applies to "
       "every account, frozen or not, and is never rejected: a negative balance loses a tenth "
       "of its size, rounded up (-25 becomes -28); a balance of 100 or more gains a hundredth, "
       "rounded down (250 becomes 252); other balances are unchanged. For a month end, "
       "accts[k], others[k] and amounts[k] are 0 and ignored, and for kinds 1 and 2 others[k] "
       "is 0 and ignored. Return the final balances, the number of rejected operations, and "
       "for each account whether it is frozen. n is 1 to 8; the starting balances and limit "
       "are 0 to 1,000,000; there are at most 60 operations; for kinds 1 to 3 the amount is "
       "1 to 1,000,000 and the accounts are 0 to n - 1.",
       [("balances", SI), ("limit", I), ("kinds", SI), ("accts", SI), ("others", SI), ("amounts", SI)],
       [("final", SI), ("rejected", I), ("frozen", SB)], _bank,
       ([100, 20], 10, [2, 3, 4, 1, 2], [0, 1, 0, 1, 1], [0, 0, 0, 0, 0], [30, 25, 0, 40, 50]),
       [([5], 0, [], [], [], []),
        ([5], 0, [2], [0], [0], [6]),
        ([5], 1, [2], [0], [0], [6]),
        ([0], 10, [2], [0], [0], [10]),
        ([0], 10, [2, 2], [0, 0], [0, 0], [3, 3]),
        ([10, 10], 0, [3], [0], [0], [5]),
        ([10, 10], 0, [3, 3, 3, 1, 3], [0, 0, 0, 0, 1], [0, 0, 0, 0, 0], [5, 5, 5, 5, 5]),
        ([10, 0], 0, [2, 2, 2, 1, 4], [1, 1, 1, 0, 0], [0, 0, 0, 0, 0], [1, 1, 1, 1000, 0]),
        ([0, 99, 100, 1000], 50, [2, 4, 4], [0, 0, 0], [0, 0, 0], [25, 0, 0]),
        ([0, 0], 100, [2, 4, 2, 4], [0, 0, 1, 0], [0, 0, 0, 0], [91, 0, 1, 0]),
        ([10, 10, 10], 0, [3, 3, 3, 3, 3, 3, 1], [0, 0, 0, 1, 2, 2, 0], [0, 0, 0, 0, 0, 1, 0],
         [1, 1, 1, 1, 100, 100, 1]),
        ([1000000] * 8, 1000000, [4] * 60, [0] * 60, [0] * 60, [0] * 60),
        ([0], 1000000, [2] + [4] * 59, [0] * 60, [0] * 60, [1000000] + [0] * 59),
        _random_bank(6, 4, 40), _random_bank(7, 8, 60), _random_bank(8, 2, 30)],
       ["seq", "loop", "rules", "state", "bool-seq"]),
    _t("order-book",
       "Run a trading order book. Operation i is kinds[i], sides[i], prices[i] and qtys[i] "
       "(the four sequences have the same length). Kind 0 is an order: side 0 buys and side 1 "
       "sells qtys[i] units; prices[i] is its limit price, or 0 for a market order, which has "
       "no limit. Kind 1 cancels: qtys[i] is the number of an earlier operation, and if that "
       "operation is an order with units still resting in the book, they are removed from it; "
       "otherwise the cancel does nothing (sides[i] and prices[i] are 0 and ignored). An "
       "incoming buy trades with resting sell orders whose price is at most its limit (any "
       "price, for a market buy), lowest price first, and among equal prices the one placed "
       "earliest first; an incoming sell trades with resting buy orders whose price is at "
       "least its limit (any price, for a market sell), highest price first, then earliest. "
       "Each trade is for as many units as both orders still have, at the resting order's "
       "price, and trading goes on until the incoming order is complete or no resting order "
       "can trade with it. What is left of a limit order then rests in the book; what is "
       "left of a market order is dropped. Market orders never rest. Return, for each "
       "operation, the units it filled in all, as the incoming order and later as a resting "
       "order (0 for a cancel), then the total value of all trades (the sum of units times "
       "price), then the number of trades. There are at most 40 operations; limit prices are "
       "1 to 1,000, an order's quantity is 1 to 100, and a cancel's qtys[i] is 0 to 39.",
       [("kinds", SI), ("sides", SI), ("prices", SI), ("qtys", SI)],
       [("filled", SI), ("value", I), ("trades", I)], _order_book,
       ([0, 0, 0, 0], [1, 1, 0, 0], [101, 100, 101, 0], [5, 5, 7, 6]),
       [([], [], [], []),
        ([0, 0], [0, 1], [0, 0], [5, 5]),
        ([0, 0], [0, 1], [100, 101], [5, 5]),
        ([0, 0], [0, 1], [101, 100], [5, 3]),
        ([0, 0, 0], [1, 1, 0], [100, 100, 100], [2, 2, 3]),
        ([0, 0, 0], [0, 0, 1], [99, 100, 98], [4, 4, 6]),
        ([0, 1, 0], [1, 0, 0], [100, 0, 100], [5, 0, 5]),
        ([0, 0, 1, 0], [1, 0, 0, 0], [100, 100, 0, 100], [5, 2, 0, 5]),
        ([0, 1, 1, 0], [1, 0, 0, 0], [100, 0, 0, 0], [5, 0, 0, 5]),
        ([0, 1, 0], [0, 0, 1], [100, 0, 100], [5, 1, 5]),
        ([1, 0, 1, 0], [0, 0, 0, 1], [0, 50, 0, 50], [0, 3, 3, 3]),
        ([0, 0, 0, 0, 0], [0, 0, 0, 1, 1], [0, 101, 102, 0, 101], [9, 4, 4, 3, 8]),
        ([0] * 6, [1, 1, 1, 1, 1, 0], [1000, 999, 1000, 998, 999, 1000], [100] * 6),
        _random_book(9, 25), _random_book(10, 40), _random_book(11, 40)],
       ["seq", "nested-loop", "rules", "state", "heavy"]),
    _t("spreadsheet",
       "A sheet has n cells, numbered 0 to n - 1; cell i is kinds[i] with operands a = xs[i] "
       "and b = ys[i] (the three sequences have the same length n). Kinds: 0 is the number a "
       "(b is 0 and ignored); 1 is cell a plus cell b; 2 is cell a minus cell b; 3 is cell a "
       "divided by cell b, the quotient rounded toward zero (-7 and 2 give -3); 4 is the "
       "largest value of cells a to b, both included; 5 is how many of cells a to b, both "
       "included, have no error and a value greater than 0. A kind 1 to 3 cell refers to cells"
       " a and b, and a kind 4 or 5 cell to cells a to b. A cell has an error when: it refers "
       "to a cell number outside 0 to n - 1, or, for kinds 4 and 5, a is greater than b (such "
       "a cell's references, even those inside 0 to n - 1, are then not followed at all); it "
       "is on a cycle or leads to one: following references from it, one or more steps, "
       "reaches some cell c (it or another) from which following references gets back to c (a "
       "cell referring to itself is on a cycle), where the references followed may be those of"
       " any kind, kind 5 included; it is kind 1 to 4 and a cell it refers to has an error; or"
       " it is kind 3 and cell b's value is 0. Apart from cycles, a kind 5 cell does not get "
       "an error from the cells it counts. Return each cell's value, 0 for a cell with an "
       "error, and whether each cell has an error. n is 1 to 25, every kind 0 number is "
       "-1,000,000 to 1,000,000, and for kinds 1 to 5, a and b are -100 to 100.",
       [("kinds", SI), ("xs", SI), ("ys", SI)], [("values", SI), ("errors", SB)], _sheet,
       ([0, 0, 1, 3, 4, 5, 1], [7, -3, 0, 2, 0, 0, 6], [0, 0, 1, 1, 3, 3, 6]),
       [([0], [5], [0]),
        ([1], [0], [0]),
        ([0, 3], [4, 0], [0, 1]),
        ([0, 0, 3], [-7, 2, 0], [0, 0, 1]),
        ([0, 0, 3], [7, -2, 0], [0, 0, 1]),
        ([0, 0, 3], [-1, 5, 0], [0, 0, 1]),
        ([0, 1, 2], [1, 0, 1], [0, 5, 0]),
        ([0, 4, 4], [1, 0, 2], [0, 0, 1]),
        ([0, 5, 1], [3, 0, 1], [0, 2, 0]),
        ([0, 0, 5, 1, 1], [3, -1, 0, 4, 3], [0, 0, 4, 3, 0]),
        ([0, 0, 2, 4, 5], [-4, -9, 0, 0, 0], [0, 0, 1, 2, 3]),
        ([1, 0, 0, 3, 5], [2, 6, 0, 1, 0], [2, 0, 0, 2, 3]),
        ([0, 2, 1, 1, 1, 1, 1, 1], [1000000, 0, 1, 2, 3, 4, 5, 6], [0, 0, 1, 2, 3, 4, 5, 6]),
        ([0] + [1] * 24, [1000000] + list(range(24)), [0] + list(range(24))),
        ([0, 0, 0, 4, 4, 5], [-5, -2, -9, 0, 0, 0], [0, 0, 0, 2, 2, 4]),
        ([0, 5, 1, 1], [5, 0, 0, 3], [0, 2, 3, 0]),
        ([5, 1], [1, 1], [1, 50]),
        ([0, 0, 3, 1, 0, 5, 4], [4, 0, 0, 0, 9, 0, 0], [0, 0, 1, 9, 0, 4, 4]),
        _random_sheet(12, 12), _random_sheet(13, 20), _random_sheet(14, 25), _random_sheet(15, 25)],
       ["seq", "nested-loop", "rules", "graph", "divmod", "bool-seq", "heavy"]),
    _t("elevator",
       "Simulate one lift. Request k asks for the lift at floor floors[k], from time times[k] "
       "(the two sequences have the same length). At time 0 the lift is at floor 0, heading "
       "up. A request is waiting when its time is at most the current time and it has not been "
       "served. Repeat: if a waiting request is for the current floor, serve every waiting "
       "request for that floor at the current time (that is each one's serve time), and the "
       "stop takes 2 time units. Otherwise, if no request is waiting: stop if every request "
       "has been served, else move the clock forward to the earliest time of a request not yet "
       "served (the lift does not move). Otherwise, if no waiting request is beyond the current "
       "floor in the heading direction, reverse the heading; then move one floor in the "
       "heading direction, which takes 1 time unit. Return each request's serve time, the time "
       "when the simulation stops, and how many floors the lift moved in all. There are at "
       "most 30 requests, floors are 0 to 20, and times are 0 to 1,000, in any order.",
       [("times", SI), ("floors", SI)], [("served", SI), ("end", I), ("moved", I)], _elevator,
       ([0, 0, 3], [3, 1, 2]),
       [([], []),
        ([0], [0]),
        ([5], [0]),
        ([0, 1], [0, 0]),
        ([0, 2], [0, 0]),
        ([0, 0], [4, 2]),
        ([0, 1], [5, 1]),
        ([0, 2, 2], [3, 1, 4]),
        ([10, 0], [2, 3]),
        ([0, 0, 0], [20, 0, 10]),
        ([0, 4, 4, 30], [6, 2, 9, 0]),
        ([7, 7, 7, 7], [5, 5, 4, 6]),
        _random_lift(16, 15), _random_lift(17, 30), _random_lift(18, 30)],
       ["seq", "loop", "rules", "state"]),
    _t("date-diff",
       "Two dates are given as year, month (1 to 12) and day: y1, m1, d1 and y2, m2, d2. Both "
       "are valid dates in the Gregorian calendar, in years 1600 to 2400. A year has 366 days "
       "if it is divisible by 4, except that a year divisible by 100 has 365 unless it is also "
       "divisible by 400; February has 29 days in such a 366-day year and 28 otherwise; April, "
       "June, September and November have 30 days, and the others 31. Return the number of "
       "days from the first date to the second (negative when the second is earlier; 1 when "
       "it is the next day), the weekday of the second date, counting Monday as 0 and Sunday "
       "as 6 (1 January 2000 was a Saturday), and the day of the year of the second date (1 "
       "January is 1).",
       [("y1", I), ("m1", I), ("d1", I), ("y2", I), ("m2", I), ("d2", I)],
       [("days", I), ("weekday", I), ("day-of-year", I)], _date_diff,
       (2000, 1, 1, 2000, 3, 1),
       [(2000, 1, 1, 2000, 1, 1),
        (1999, 12, 31, 2000, 1, 1),
        (2000, 1, 1, 1999, 12, 31),
        (1900, 2, 28, 1900, 3, 1),
        (2000, 2, 28, 2000, 3, 1),
        (2100, 12, 31, 2101, 1, 1),
        (2024, 1, 1, 2024, 12, 31),
        (2023, 1, 1, 2023, 12, 31),
        (1600, 1, 1, 2400, 12, 31),
        (2400, 12, 31, 1600, 1, 1),
        (1969, 7, 20, 2026, 10, 2),
        (1752, 9, 2, 1752, 9, 14),
        (2400, 2, 29, 2399, 3, 1),
        (1700, 3, 1, 1700, 2, 28),
        (2004, 2, 29, 2005, 2, 28)],
       ["arith", "rules", "divmod"]),
    _t("heap-alloc",
       "Simulate a memory of size cells, numbered 0 to size - 1, all free at first. The free "
       "cells form free blocks: runs of free cells next to each other that cannot be made "
       "longer. Operation i is kinds[i] and vals[i] (the two sequences have the same length). "
       "Kind 0 allocates vals[i] cells: choose the free block with the fewest cells among "
       "those with at least vals[i] cells, the lowest-numbered one among equals, and take its "
       "first vals[i] cells; the result is the number of the first cell taken, or -1 if no "
       "free block is big enough. Kind 1 frees: vals[i] is the number of an earlier operation, "
       "and if that operation was an allocation that succeeded and has not been freed yet, its "
       "cells become free again and the result is 0; otherwise nothing changes and the result "
       "is -1. Return each operation's result, then the number of free blocks at the end and "
       "the size of the largest one (0 if there is none). size is 1 to 1,000; there are at "
       "most 40 operations; an allocation asks for 1 to 1,000 cells, and vals[i] of a free "
       "may be any number from -1,000 to 1,000.",
       [("size", I), ("kinds", SI), ("vals", SI)], [("results", SI), ("blocks", I), ("largest", I)], _heap,
       (10, [0, 0, 0, 1, 0], [3, 3, 3, 1, 2]),
       [(5, [], []),
        (5, [0], [5]),
        (5, [0], [6]),
        (5, [0, 0], [5, 1]),
        (10, [0, 0, 1, 1], [4, 4, 0, 0]),
        (10, [0, 1], [4, 1]),
        (10, [0, 1, 1], [4, 5, -1]),
        (10, [0, 0, 1, 0], [4, 4, 1, 2]),
        (12, [0, 0, 0, 0, 1, 1, 0], [2, 3, 2, 5, 0, 2, 2]),
        (12, [0, 0, 0, 0, 1, 1, 0], [2, 3, 2, 5, 0, 2, 3]),
        (12, [0, 0, 0, 1, 1, 0], [4, 4, 4, 0, 1, 8]),
        (20, [0, 0, 0, 0, 0, 1, 1, 0, 0], [3, 4, 3, 4, 3, 1, 3, 4, 1]),
        (9, [0, 0, 0, 1, 1, 1, 0], [3, 3, 3, 1, 0, 2, 9]),
        _random_heap(19, 100, 30), _random_heap(20, 1000, 40), _random_heap(21, 50, 40)],
       ["seq", "nested-loop", "rules", "state", "heavy"]),
)
