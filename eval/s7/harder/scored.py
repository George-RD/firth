"""The scored set of the harder S7 tier (`todo.s7-harder-task-tier`).

This is the scored set: six tasks written after the three calibration pools
and frozen before any scored trial. None of them was run in calibration, and
none is swapped out after a result (README, "The scored tier"). Each is a
whole simulation with many interacting rules: a warehouse puzzle with undo
(`sokoban`), draughts played by a fixed rule (`checkers`), a regular
expression matcher with its own grammar (`regex`), a Swiss-system
tournament (`swiss`), a warehouse with expiring lots, backorders and
reordering (`warehouse`) and a two-level write-back cache (`cache-sim`).

Reference sizes, measured with `wc -l`: the Python references are 47 to 116
lines (466 in all) and the Firth ones 139 to 454 (1,859). A Sonnet worker
wrote each Python reference from the description alone, and they agree
with the meanings below on 3,000 seeded random inputs per task; the Firth
references were written by Sonnet workers from the descriptions too.

Every description states every bound an answer depends on: the size of
each input and the range of each value, so every result fits in a 64-bit
`Int`. `test_harder.py` checks that no example, hidden test or hand value
breaks those bounds, including the structural ones (the walls around a
sokoban floor, the pieces on a draughts board, string lengths that add up
to the letters given, a result for every game, events in day order).

Each `ref` is the task's meaning, written in plain Python independently of
any Firth code. Hidden inputs are scored against it and never shown to the
author. `test_harder.py` checks the refs against values worked out by hand.
"""
from __future__ import annotations

import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from task import Task, _t  # noqa: E402

I, B, SI, SB = "Int", "Bool", "Seq Int", "Seq Bool"


# --- sokoban ---------------------------------------------------------------------

_DELTA = {0: lambda w: -w, 1: lambda w: 1, 2: lambda w: w, 3: lambda w: -1}


def _sokoban(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    history = []  # (direction, pushed box index or -1)
    used = pushes = blocked = undos = dead = 0

    def solved():
        return all(cells[b] == 2 for b in boxes)

    def wall(i):
        return cells[i] == 1

    def corner(i):
        up, down, left, right = wall(i - width), wall(i + width), wall(i - 1), wall(i + 1)
        return (up or down) and (left or right)

    for m in moves:
        if solved():
            break
        used += 1
        if m == 4:
            if history:
                d, k = history.pop()
                delta = _DELTA[d](width)
                if k >= 0:
                    boxes[k] -= delta
                player -= delta
                undos += 1
            continue
        delta = _DELTA[m](width)
        t = player + delta
        if wall(t):
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + delta
            if wall(u) or u in boxes:
                blocked += 1
                continue
            boxes[k] = u
            player = t
            pushes += 1
            if cells[u] != 2 and corner(u):
                dead += 1
            history.append((m, k))
        else:
            player = t
            history.append((m, -1))
    return player, boxes, used, len(history), pushes, blocked, undos, dead, solved()


# --- checkers --------------------------------------------------------------------

def _rc(i):
    r = i // 4
    return r, 2 * (i % 4) + (1 if r % 2 == 0 else 0)


def _sq(r, c):
    if 0 <= r < 8 and 0 <= c < 8 and (r + c) % 2 == 1:
        return r * 4 + c // 2
    return -1


def _owner(v):
    return 0 if v == 0 else (1 if v in (1, 2) else 2)  # 1 white, 2 black


def _dirs(v):
    if v in (2, 4):
        return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    return [(-1, -1), (-1, 1)] if v == 1 else [(1, -1), (1, 1)]


def _crowns(v, r):
    return (v == 1 and r == 0) or (v == 3 and r == 7)


def _jumps(board, i, v):
    """Every complete capture sequence of the piece v standing on i: a list of
    (landing squares, captured squares). A man that reaches its far row is
    crowned and its move ends there."""
    out = []
    r, c = _rc(i)
    for dr, dc in _dirs(v):
        over, land = _sq(r + dr, c + dc), _sq(r + 2 * dr, c + 2 * dc)
        if over < 0 or land < 0 or board[land] != 0 or _owner(board[over]) not in (1, 2) \
                or _owner(board[over]) == _owner(v):
            continue
        b = list(board)
        b[i], b[over], b[land] = 0, 0, v
        lr, _ = _rc(land)
        if _crowns(v, lr):
            out.append(([land], [over]))
            continue
        more = _jumps(b, land, v)
        if more:
            out += [([land] + ls, [over] + cs) for ls, cs in more]
        else:
            out.append(([land], [over]))
    return out


def _legal(board, side):
    """The side's moves as (start, landings, captured), captures only if any."""
    caps, steps = [], []
    for i in range(32):
        v = board[i]
        if _owner(v) != side:
            continue
        for ls, cs in _jumps(board, i, v):
            caps.append((i, ls, cs))
        r, c = _rc(i)
        for dr, dc in _dirs(v):
            t = _sq(r + dr, c + dc)
            if t >= 0 and board[t] == 0:
                steps.append((i, [t], []))
    return caps if caps else steps


def _choose(moves):
    most = max(len(cs) for _, _, cs in moves)
    return min((m for m in moves if len(m[2]) == most), key=lambda m: (m[0], m[1]))


def _checkers(board, turn, plies):
    board = list(board)
    side = 1 if turn == 0 else 2
    played, taken, crowned, result = 0, [0, 0], 0, 0
    while True:
        moves = _legal(board, side)
        if not moves:
            result = 2 if side == 1 else 1  # the side to move has lost
            break
        if played == plies:
            break
        start, ls, cs = _choose(moves)
        v = board[start]
        board[start] = 0
        for s in cs:
            board[s] = 0
        end = ls[-1]
        if _crowns(v, _rc(end)[0]):
            v += 1
            crowned += 1
        board[end] = v
        taken[side - 1] += len(cs)
        played += 1
        side = 3 - side
    return board, played, taken[0], taken[1], crowned, result


# --- regex -----------------------------------------------------------------------

class _Bad(Exception):
    pass


def _parse_regex(toks):
    pos = 0

    def peek():
        return toks[pos] if pos < len(toks) else None

    def alt():
        nonlocal pos
        branches = [concat()]
        while peek() == 30:
            pos += 1
            branches.append(concat())
        return ("alt", branches)

    def concat():
        items = []
        while peek() is not None and peek() not in (30, 32):
            items.append(repeat())
        return ("cat", items)

    def repeat():
        nonlocal pos
        node = atom()
        while peek() in (27, 28, 29):
            node = ({27: "star", 28: "plus", 29: "opt"}[peek()], node)
            pos += 1
        return node

    def atom():
        nonlocal pos
        t = peek()
        if t is None or t in (27, 28, 29, 30, 32):
            raise _Bad
        pos += 1
        if t <= 25:
            return ("lit", t)
        if t == 26:
            return ("any",)
        inner = alt()  # t == 31
        if peek() != 32:
            raise _Bad
        pos += 1
        return inner

    tree = alt()
    if pos != len(toks):
        raise _Bad  # a ')' with no '(' open
    return tree


def _ends(node, s, starts):
    """The positions at which a match of node can end, starting from any of starts."""
    kind = node[0]
    if kind == "lit":
        return {i + 1 for i in starts if i < len(s) and s[i] == node[1]}
    if kind == "any":
        return {i + 1 for i in starts if i < len(s)}
    if kind == "cat":
        cur = set(starts)
        for item in node[1]:
            cur = _ends(item, s, cur)
        return cur
    if kind == "alt":
        out = set()
        for b in node[1]:
            out |= _ends(b, s, starts)
        return out
    if kind == "opt":
        return set(starts) | _ends(node[1], s, starts)
    reach, frontier = set(starts) if kind == "star" else set(), set(starts)
    while frontier:
        nxt = _ends(node[1], s, frontier) - reach
        reach |= nxt
        frontier = nxt
    return reach


def _regex(pattern, lens, chars):
    strings, k = [], 0
    for n in lens:
        strings.append(list(chars[k:k + n]))
        k += n
    try:
        tree = _parse_regex(list(pattern))
    except _Bad:
        return [False] * len(lens), [-1] * len(lens), 0, False
    full, longest = [], []
    for s in strings:
        e = _ends(tree, s, {0})
        full.append(len(s) in e)
        longest.append(max(e) if e else -1)
    return full, longest, sum(full), True


# --- swiss -----------------------------------------------------------------------

def _swiss(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    met = [set() for _ in range(n)]
    opponents = [[] for _ in range(n)]
    whites = [0] * n
    last = [None] * n  # 'w' or 'b' of the last game played (not a bye)
    had_bye = [False] * n
    rematches, r_i = 0, 0
    for _ in range(rounds):
        order = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        unpaired = list(order)
        if n % 2 == 1:
            bye = next(p for p in reversed(order) if not had_bye[p])
            unpaired.remove(bye)
            had_bye[bye] = True
            score[bye] += 2
        games = []
        while unpaired:
            a = unpaired.pop(0)
            b = next((p for p in unpaired if p not in met[a]), unpaired[0])
            unpaired.remove(b)
            games.append((a, b))
        for a, b in games:
            if whites[a] != whites[b]:
                w = a if whites[a] < whites[b] else b
            elif (last[a] == "b") != (last[b] == "b"):
                w = a if last[a] == "b" else b
            else:
                w = a
            bl = b if w == a else a
            if bl in met[w]:
                rematches += 1
            res = results[r_i]
            r_i += 1
            score[w] += {0: 2, 1: 1, 2: 0}[res]
            score[bl] += {0: 0, 1: 1, 2: 2}[res]
            whites[w] += 1
            last[w], last[bl] = "w", "b"
            met[w].add(bl)
            met[bl].add(w)
            opponents[w].append(bl)
            opponents[bl].append(w)
    buchholz = [sum(score[o] for o in opponents[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-score[p], -buchholz[p], -ratings[p], p))
    return score, buchholz, ranking, whites, rematches


# --- warehouse -------------------------------------------------------------------

def _warehouse(days, price, rp, rq, lead, shelf,
               ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]  # [qty, expiry, arrival serial]
    back = [[] for _ in range(P)]  # [qty, day placed]
    supply = [None] * P  # day the pending supply arrives
    serial = 0
    revenue = shipped = discarded = cancelled = reorders = 0

    def add_lot(p, qty, expiry):
        nonlocal serial, revenue, shipped
        lots[p].append([qty, expiry, serial])
        serial += 1
        while back[p] and stock(p):
            want = back[p][0][0]
            got = take(p, want)
            revenue += got * price[p]
            shipped += got
            back[p][0][0] -= got
            if back[p][0][0] == 0:
                back[p].pop(0)

    def stock(p):
        return sum(q for q, _, _ in lots[p])

    def take(p, want):
        got = 0
        lots[p].sort(key=lambda lot: (lot[1], lot[2]))
        for lot in lots[p]:
            if got == want:
                break
            k = min(lot[0], want - got)
            lot[0] -= k
            got += k
        lots[p] = [lot for lot in lots[p] if lot[0] > 0]
        return got

    e = 0
    for d in range(days):
        for p in range(P):
            gone = [lot for lot in lots[p] if lot[1] < d]
            discarded += sum(q for q, _, _ in gone)
            lots[p] = [lot for lot in lots[p] if lot[1] >= d]
        for p in range(P):
            if supply[p] == d:
                supply[p] = None
                add_lot(p, rq[p], d + shelf[p])
        while e < len(ev_day) and ev_day[e] == d:
            p, q = ev_prod[e], ev_qty[e]
            if ev_kind[e] == 1:
                add_lot(p, q, ev_expiry[e])
            else:
                got = take(p, q) if not back[p] else 0
                revenue += got * price[p]
                shipped += got
                if got < q:
                    back[p].append([q - got, d])
            e += 1
        for p in range(P):
            keep = [b for b in back[p] if d - b[1] < 7]
            cancelled += sum(b[0] for b in back[p] if d - b[1] >= 7)
            back[p] = keep
        for p in range(P):
            if supply[p] is None and stock(p) <= rp[p]:
                supply[p] = d + lead[p]
                reorders += 1
    return ([stock(p) for p in range(P)], revenue, shipped, discarded, cancelled, reorders,
            sum(b[0] for p in range(P) for b in back[p]))


# --- cache-sim -------------------------------------------------------------------

def _cache_sim(s1, w1, s2, w2, addrs, writes):
    l1 = [[] for _ in range(s1)]  # most recently used last: [block, dirty]
    l2 = [[] for _ in range(s2)]
    c = dict(h1=0, m1=0, h2=0, m2=0, mr=0, mw=0)

    def find(level, sets, a):
        for e in sets[a % len(sets)]:
            if e[0] == a:
                return e
        return None

    def touch(sets, e, a):
        s = sets[a % len(sets)]
        s.remove(e)
        s.append(e)

    def insert(sets, ways, a, dirty):
        """Insert block a; return the evicted entry, or None."""
        s = sets[a % len(sets)]
        victim = s.pop(0) if len(s) == ways else None
        s.append([a, dirty])
        return victim

    def l2_write(a):
        e = find(2, l2, a)
        if e:
            e[1] = True
            touch(l2, e, a)
            return
        v = insert(l2, w2, a, True)
        if v and v[1]:
            c["mw"] += 1

    for a, w in zip(addrs, writes):
        e = find(1, l1, a)
        if e:
            c["h1"] += 1
            if w:
                e[1] = True
            touch(l1, e, a)
            continue
        c["m1"] += 1
        e2 = find(2, l2, a)
        if e2:
            c["h2"] += 1
            touch(l2, e2, a)
        else:
            c["m2"] += 1
            c["mr"] += 1
            v = insert(l2, w2, a, False)
            if v and v[1]:
                c["mw"] += 1
        v = insert(l1, w1, a, bool(w))
        if v and v[1]:
            l2_write(v[0])
    dirty = sum(e[1] for s in l1 for e in s) + sum(e[1] for s in l2 for e in s)
    final_l1 = [e[0] for s in l1 for e in s]
    return (c["h1"], c["m1"], c["h2"], c["m2"], c["mr"], c["mw"], dirty, final_l1)


# --- random inputs --------------------------------------------------------------

# sokoban

def _room(rng, w, h, wall_p=0.15, goals=0):
    cells = []
    for r in range(h):
        for c in range(w):
            edge = r in (0, h - 1) or c in (0, w - 1)
            cells.append(1 if edge or rng.random() < wall_p else 0)
    free = [i for i, v in enumerate(cells) if v == 0]
    for i in rng.sample(free, min(goals, len(free))):
        cells[i] = 2
    return cells


def _random_sokoban(seed, w=None, h=None, nbox=None, nmoves=None, solve_at=None):
    rng = random.Random(seed)
    w = w or rng.randint(5, 12)
    h = h or rng.randint(5, 12)
    nbox = nbox or rng.randint(1, 6)
    for _ in range(1000):
        cells = _room(rng, w, h, goals=rng.randint(nbox, nbox + 2))
        free = [i for i, v in enumerate(cells) if v != 1]
        if len(free) >= nbox + 2:
            break
    picks = rng.sample(free, nbox + 1)
    player, boxes = picks[0], picks[1:]
    n = nmoves if nmoves is not None else rng.randint(0, 200)
    moves = [4 if rng.random() < 0.08 else rng.randint(0, 3) for _ in range(n)]
    if solve_at is not None:
        # Make the boxes' cells after solve_at moves the only goals, so the
        # puzzle is solved there (if no box is on a goal earlier).
        _, after, *_ = _sokoban(w, h, [1 if v == 1 else 0 for v in cells], player, boxes,
                                  moves[:solve_at])
        cells = [1 if v == 1 else 0 for v in cells]
        for b in after:
            cells[b] = 2
    return w, h, cells, player, boxes, moves


# checkers

_OPENING = [3] * 12 + [0] * 8 + [1] * 12


def _random_board(rng, white, black, kings=0.3):
    board = [0] * 32
    squares = rng.sample(range(32), white + black)
    for k, i in enumerate(squares):
        r = i // 4
        if k < white:
            board[i] = 2 if r == 0 or rng.random() < kings else 1
        else:
            board[i] = 4 if r == 7 or rng.random() < kings else 3
    return board


def _largest_checkers(seed):
    """A checkers input at the largest sizes: 12 pieces a side and 40 plies."""
    rng = random.Random(seed)
    return _random_board(rng, 12, 12, kings=rng.choice([0.0, 0.3, 0.7, 1.0])), rng.randint(0, 1), 40


def _random_checkers(seed, plies=None):
    rng = random.Random(seed)
    if rng.random() < 0.3:
        board = list(_OPENING)
    else:
        board = _random_board(rng, rng.randint(1, 12), rng.randint(1, 12))
    return board, rng.randint(0, 1), plies or rng.randint(1, 40)


# regex

def _rx_item(rng, depth, budget):
    r = rng.random()
    if depth < 2 and budget >= 4 and r < 0.25:
        inner = _rx_alt(rng, depth + 1, budget - 2)
        atom = [31] + inner + [32]
    elif r < 0.35:
        atom = [26]
    else:
        atom = [rng.randint(0, 2)]
    while rng.random() < 0.3 and len(atom) < budget:
        atom = atom + [rng.choice([27, 28, 29])]
    return atom


def _rx_seq(rng, depth, budget):
    out = []
    while len(out) < budget and rng.random() < 0.75:
        item = _rx_item(rng, depth, budget - len(out))
        if len(out) + len(item) > budget:
            break
        out += item
    return out


def _rx_alt(rng, depth, budget):
    out = _rx_seq(rng, depth, budget)
    while len(out) + 1 < budget and rng.random() < 0.3:
        more = _rx_seq(rng, depth, budget - len(out) - 1)
        out += [30] + more
    return out


def _random_regex(seed, broken=None):
    rng = random.Random(seed)
    pattern = _rx_alt(rng, 0, rng.randint(1, 20))
    if broken if broken is not None else rng.random() < 0.15:
        k = rng.randint(0, len(pattern))
        pattern = (pattern[:k] + [rng.choice([27, 28, 29, 31, 32])] + pattern[k:])[:20]
    strings = []
    try:
        tree = _parse_regex(pattern)
    except _Bad:
        tree = None
    for _ in range(rng.randint(1, 8)):
        s = _rx_sample(rng, tree) if tree and rng.random() < 0.6 else None
        if s is None or len(s) > 12:
            s = [rng.randint(0, 2) for _ in range(rng.randint(0, 12 if rng.random() < 0.3 else 6))]
        elif rng.random() < 0.3 and s:
            s = s[:]
            s[rng.randrange(len(s))] = rng.randint(0, 2)  # one letter changed
        strings.append(s)
    return pattern, [len(s) for s in strings], [c for s in strings for c in s]


def _rx_sample(rng, node, depth=0):
    """A random string the node matches, or None if it grew too long."""
    if depth > 40:
        return None
    kind = node[0]
    if kind == "lit":
        return [node[1]]
    if kind == "any":
        return [rng.randint(0, 2)]
    if kind in ("cat", "alt"):
        parts = node[1] if kind == "cat" else [rng.choice(node[1])]
        out = []
        for part in parts:
            got = _rx_sample(rng, part, depth + 1)
            if got is None:
                return None
            out += got
        return out
    lo = 1 if kind == "plus" else 0
    hi = 1 if kind == "opt" else 3
    out = []
    for _ in range(rng.randint(lo, hi)):
        got = _rx_sample(rng, node[1], depth + 1)
        if got is None:
            return None
        out += got
    return out


# swiss

def _random_swiss(seed, n=None, rounds=None):
    rng = random.Random(seed)
    n = n or rng.randint(2, 12)
    rounds = rounds or rng.randint(1, min(7, n - 1))
    ratings = [rng.choice([rng.randint(1000, 3000), 1500, 2000]) for _ in range(n)]
    results = [rng.choice([0, 0, 1, 2, 2]) for _ in range(rounds * (n // 2))]
    return ratings, rounds, results


# warehouse

def _random_warehouse(seed, P=None, days=None, events=None):
    rng = random.Random(seed)
    P = P or rng.randint(1, 5)
    days = days or rng.randint(1, 60)
    price = [rng.randint(1, 1000) for _ in range(P)]
    rp = [rng.randint(0, 30) for _ in range(P)]
    rq = [rng.randint(1, 60) for _ in range(P)]
    lead = [rng.randint(1, 10) for _ in range(P)]
    shelf = [rng.randint(1, 30) for _ in range(P)]
    m = events if events is not None else rng.randint(0, 80)
    ev_day = sorted(rng.randint(0, days - 1) for _ in range(m))
    ev_kind = [rng.choice([1, 2, 2]) for _ in range(m)]
    ev_prod = [rng.randint(0, P - 1) for _ in range(m)]
    ev_qty = [rng.randint(1, 40 if rng.random() < 0.8 else 200) for _ in range(m)]
    ev_expiry = [d + rng.randint(0, 60) if k == 1 else 0 for d, k in zip(ev_day, ev_kind)]
    return days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry


# cache-sim

def _random_cache(seed, n=None):
    rng = random.Random(seed)
    s1, w1 = rng.randint(1, 4), rng.randint(1, 4)
    s2, w2 = rng.randint(1, 8), rng.randint(1, 8)
    n = n if n is not None else rng.randint(0, 200)
    span = rng.choice([8, 16, 32, 256])
    base = rng.randint(0, 256 - span)
    addrs = [base + rng.randint(0, span - 1) for _ in range(n)]
    writes = [rng.random() < 0.35 for _ in range(n)]
    return s1, w1, s2, w2, addrs, writes


def _largest_cache(seed):
    """A cache-sim input at the largest sizes: 4 by 4 and 8 by 8 places, 200 accesses."""
    return (4, 4, 8, 8, *_random_cache(seed, 200)[4:])


# --- hand-written inputs ------------------------------------------------------

def _soko(rows, moves, reverse=False):
    """sokoban inputs from a picture: '#' wall, ' ' floor, '.' goal, '@' the worker,
    '+' the worker on a goal, '$' a box, '*' a box on a goal. Boxes are listed in
    reading order, or the reverse."""
    width, height = len(rows[0]), len(rows)
    cells, player, boxes = [], None, []
    for r, row in enumerate(rows):
        assert len(row) == width
        for c, ch in enumerate(row):
            i = r * width + c
            cells.append(1 if ch == "#" else 2 if ch in ".*+" else 0)
            if ch in "@+":
                player = i
            if ch in "$*":
                boxes.append(i)
    return width, height, cells, player, boxes[::-1] if reverse else boxes, list(moves)


_U, _R, _D, _L, _Z = 0, 1, 2, 3, 4   # sokoban moves; _Z is undo


def _sokoban_cases():
    return [
        # Undo with an empty history, blocked by walls, a step taken back, then a push.
        _soko(["#######",
               "#@ $ .#",
               "#######"], [_Z, _U, _L, _R, _Z, _Z, _R, _R]),
        # Blocked by two boxes in a row, and by a box against a wall.
        _soko(["#######",
               "#@$$ .#",
               "#  . ##",
               "#######"], [_R, _D, _R, _R, _U, _R, _Z]),
        # Two pushes, the second into a corner (dead), both undone.
        _soko(["######",
               "#@$  #",
               "#   .#",
               "######"], [_R, _R, _Z, _Z, _Z, _D]),
        # Pushed along a corridor with walls above and below only: never dead. Solved at the
        # third push, so the last three moves are not read.
        _soko(["#######",
               "#@$  .#",
               "#######"], [_R, _R, _R, _L, _L, _Z]),
        # Solved before the first move.
        _soko(["#####",
               "#@* #",
               "#####"], [_R, _L, _Z]),
        # No moves: one box of two on a goal.
        _soko(["#####",
               "#@*.#",
               "#$  #",
               "#####"], []),
        # A box pushed onto a goal in a corner is not dead, nor one pushed against the bottom
        # wall only; one pushed into a corner that is not a goal is.
        _soko(["#######",
               "#.$ $ #",
               "# $@  #",
               "#     #",
               "#######"], [_U, _L, _D, _U, _R, _R]),
        # Pushes down and up, which move by width, and a push undone; boxes listed in
        # reverse order.
        _soko(["#####",
               "# @ #",
               "# $ #",
               "#$  #",
               "# . #",
               "#####"], [_D, _D, _Z, _R, _D, _D, _L, _U, _U], reverse=True),
        # An undo after a blocked move takes back the move before it.
        _soko(["#####",
               "#@ .#",
               "# $ #",
               "#####"], [_R, _R, _Z, _D, _Z, _Z, _Z]),
        # Solved midway, after a step taken back, a push onto a goal in a corner and a push
        # blocked by a wall; the last three moves are not read.
        _soko(["######",
               "#.$@ #",
               "#  $.#",
               "#    #",
               "######"], [_R, _Z, _L, _L, _D, _R, _U, _U, _L]),
    ]


def _cb(pieces):
    """A checkers board from {square: piece}."""
    board = [0] * 32
    for sq, v in pieces.items():
        board[sq] = v
    return board


_WM, _WK, _BM, _BK = 1, 2, 3, 4


def _checkers_cases():
    return [
        # Capture forced: 21 could step, 25 must take 22. Black keeps a man on 0.
        (_cb({21: _WM, 25: _WM, 22: _BM, 0: _BM}), 0, 1),
        # The same with black's last piece taken: black then has no move at the ply limit, so
        # white has won.
        (_cb({21: _WM, 25: _WM, 22: _BM}), 0, 1),
        # A double jump by the man on 29 beats a single one from a lower square.
        (_cb({21: _WM, 17: _BM, 29: _WM, 25: _BM, 18: _BM, 0: _BM}), 0, 1),
        # A man that lands on row 0 is crowned and its capture ends, though a king could jump on.
        (_cb({8: _WM, 5: _BM, 6: _BM, 31: _BK}), 0, 2),
        # Two men can take the man on 17: 21 (landing on 14) starts lower than 22 (landing on 13).
        (_cb({21: _WM, 22: _WM, 17: _BM, 3: _BM}), 0, 1),
        # One man, two double jumps: landings 18 then 9, or 18 then 11.
        (_cb({25: _WM, 22: _BM, 14: _BM, 15: _BM, 3: _BM}), 0, 1),
        # A king takes four in a ring and lands on the square it started from; two ways
        # round, landings 8, 1, 10, 17 or 10, 1, 8, 17.
        (_cb({17: _WK, 13: _BM, 5: _BM, 6: _BM, 14: _BM, 20: _BM}), 0, 3),
        # A king on 22 can take five pieces three ways; the one landing on 13, 20, 29, 22 and
        # 31 is first at its first landing, though another ends on a lower square (15).
        ([0] * 9 + [4, 4] + [0] * 5 + [3, 4] + [0] * 4 + [2, 1, 4, 4, 4, 4] + [0] * 4, 0, 3),
        # White's only man is blocked: white has no move and black has won at once.
        (_cb({4: _WM, 0: _BM}), 0, 5),
        # White has no pieces, black to move: black steps once, then white has lost.
        (_cb({9: _BM}), 1, 5),
        # A man that steps onto row 0 is crowned; the king then steps back down.
        (_cb({5: _WM, 31: _BK}), 0, 4),
        # Black moves first; its men move down and capture.
        (_cb({9: _BM, 13: _WM, 30: _WM, 1: _BK}), 1, 6),
        # The opening, played to the ply limit.
        ([3] * 12 + [0] * 8 + [1] * 12, 0, 40),
    ]


_A, _Bt, _C, _DOT, _STAR, _PLUS, _OPT, _BAR, _OPEN, _CLOSE = 0, 1, 2, 26, 27, 28, 29, 30, 31, 32


def _rx(pattern, *strings):
    return list(pattern), [len(s) for s in strings], [c for s in strings for c in s]


def _regex_cases():
    a, b, c = _A, _Bt, _C
    return [
        _rx([_STAR, a], [], [a]),                          # an operator where an atom should start
        _rx([_OPEN, a], [a], []),                          # a '(' never closed
        _rx([a, _CLOSE], [a], []),                         # a ')' with no '(' open
        _rx([_OPEN, a, _CLOSE, _CLOSE, _STAR], [a]),
        _rx([a, _BAR, _PLUS], [a]),
        _rx([_OPEN, _STAR, _CLOSE], []),
        _rx([_OPT], [], [b]),
        _rx([], [], [a], []),                              # the empty pattern
        _rx([_OPEN, _CLOSE, _STAR], [], [a, a]),           # an empty group, repeated
        _rx([a, _BAR], [], [a], [a, a], [b]),              # an empty second branch
        _rx([_BAR, _BAR, b], [], [b], [a]),
        _rx([a, _STAR, _STAR], [], [a, a, a], [b]),        # nested operators
        _rx([_OPEN, a, _STAR, _CLOSE, _PLUS, b, _PLUS, _OPT], [], [a, a], [b, b], [a, b, a]),
        _rx([a, b, _STAR], [a, b, b], [a, b, a, b], [a], [b]),  # '*' takes only the b
        _rx([_OPEN, a, b, _CLOSE, _STAR], [a, b, a, b], [a, b, a], [], [b, a]),
        _rx([_DOT, _DOT, _OPT, c], [a, c], [b, b, c], [c], [a, b, c, c]),
        _rx([_OPEN, a, _BAR, b, _CLOSE, _STAR, c], [a, b, b, a, c], [a, b, b], [c, c], [c]),
        _rx([_OPEN, _OPEN, a, _BAR, _OPEN, b, _BAR, c, _CLOSE, _PLUS, _CLOSE, _CLOSE, _OPT, a],
            [a], [a, a], [b, c, a], [b, c], [c, a, a]),
        _rx([b], [a], [b, b], [], [25] * 12),
        _rx([25, _DOT, _STAR, 25], [25, 25], [25, 0, 25, 3, 25], [25, 0], [25] * 12),
    ]


def _swiss_cases():
    return [
        ([2000, 1900, 1800], 2, [0, 0]),                    # three players: a bye each round
        ([1500, 1500, 1500], 2, [1, 2]),
        ([2400, 2300, 2200, 2100, 2000], 4, [0, 0, 0, 0, 0, 0, 0, 0]),  # five players, four byes
        ([1800, 1700, 1600, 1500, 1400], 4, [2, 2, 2, 2, 2, 2, 2, 2]),
        ([2000, 1000], 1, [2]),
        ([2000, 1900, 1800, 1700], 3, [0, 0, 0, 0, 1, 1]),
        ([1500, 1600, 1700, 1800, 1900], 3, [0, 0, 0, 0, 0, 0]),  # a forced rematch in round 3
        ([2000, 1900, 1800, 1700], 3, [2, 2, 1, 1, 0, 2]),
        ([1600, 1600, 1600, 1600, 1600, 1600], 5, [1] * 15),  # every game drawn: ties go by number
        ([2000, 2000, 1000, 1000, 3000, 3000], 3, [0, 2, 1, 2, 0, 1, 1, 1, 0]),
        ([1500, 2500, 2000, 1000, 3000, 1200, 2800], 6, [0, 2, 1] * 6),
    ]


def _wh(days, products, events):
    """warehouse inputs: products as (price, rp, rq, lead, shelf), events as
    (day, kind, product, qty, expiry)."""
    cols = list(zip(*products))
    ev = list(zip(*events)) if events else [()] * 5
    return (days, *(list(c) for c in cols), *(list(e) for e in ev))


def _warehouse_cases():
    return [
        # A lot expiring on day 1 can still be sold on day 1 and is thrown away on day 2.
        _wh(4, [(10, 0, 1, 10, 1)], [(0, 1, 0, 5, 1), (1, 2, 0, 2, 0), (2, 2, 0, 1, 0)]),
        # The lot that expires first is sold first, though it arrived second.
        _wh(8, [(5, 0, 1, 10, 1)], [(0, 1, 0, 4, 9), (0, 1, 0, 4, 5), (1, 2, 0, 3, 0)]),
        # A backorder filled by later deliveries, oldest first, the second order joining the
        # queue behind the first.
        _wh(5, [(2, 0, 1, 10, 1)], [(0, 2, 0, 5, 0), (1, 2, 0, 2, 0), (2, 1, 0, 3, 20),
                                    (3, 1, 0, 6, 20)]),
        # Placed on day 0: still owed on day 6, so a delivery on day 7 fills it before the
        # cancellations.
        _wh(9, [(3, 0, 1, 10, 1)], [(0, 2, 0, 4, 0), (7, 1, 0, 10, 30)]),
        # The same delivery a day later finds the backorder cancelled on day 7.
        _wh(9, [(3, 0, 1, 10, 1)], [(0, 2, 0, 4, 0), (8, 1, 0, 10, 30)]),
        # A partly filled backorder is cancelled for the units still owed.
        _wh(10, [(3, 0, 1, 10, 1)], [(0, 2, 0, 9, 0), (3, 1, 0, 4, 30), (8, 1, 0, 2, 30)]),
        # Reordering: stock at or below rp orders rq, due lead days later; on the day it
        # arrives it is no longer on the way, so another can be ordered that day.
        _wh(12, [(7, 5, 4, 3, 30)], [(1, 2, 0, 2, 0), (4, 2, 0, 6, 0)]),
        # A supply arriving fills a backorder before the day's events.
        _wh(6, [(4, 0, 10, 2, 10)], [(0, 2, 0, 3, 0), (2, 2, 0, 9, 0)]),
        # Two products, each with its own lots, backorders and supplies.
        _wh(15, [(10, 2, 5, 2, 3), (20, 0, 3, 4, 5)],
            [(0, 1, 1, 2, 0), (0, 2, 0, 1, 0), (1, 2, 1, 4, 0), (3, 1, 0, 6, 4), (6, 2, 0, 3, 0),
             (6, 2, 1, 1, 0), (9, 1, 1, 5, 60)]),
        # No events: only the supplies run.
        _wh(20, [(1, 0, 2, 3, 2)], []),
    ]


def _cache_cases():
    F, T = False, True
    return [
        ([1, 1, 1, 2, [1, 2], [T, F]]),                    # dirty L1 eviction, block still in L2
        ([1, 1, 1, 1, [1, 2, 3], [T, F, F]]),              # dirty L1 eviction after L2 lost it
        ([1, 1, 1, 2, [1, 2, 1, 1], [T, F, F, T]]),         # dirty in both levels
        ([1, 2, 1, 2, [1, 2, 3, 4, 5], [T, T, T, T, T]]),
        ([2, 2, 1, 2, [0, 1, 2, 3, 4, 5, 0, 1], [T, F, T, F, T, F, F, F]]),
        ([1, 4, 1, 1, [7, 7, 8, 7], [F, T, F, F]]),
        ([4, 1, 8, 1, [0, 4, 8, 0, 16, 4], [T, T, F, F, T, T]]),
        ([1, 1, 2, 1, [0, 1, 2, 3, 0, 1, 2, 3], [T] * 8]),
        ([2, 1, 1, 8, [], []]),
        ([1, 2, 2, 2, [5, 5, 5, 6, 7, 6, 5, 8], [F, T, T, F, T, F, F, F]]),
    ]


# --- descriptions ---------------------------------------------------------------

_SOKOBAN = (
    "Play moves in a warehouse puzzle and report what happened. The floor is a grid of "
    "width columns and height rows; cell (row r, column c) is number r times width plus c, "
    "and cells[i] is 0 for floor, 1 for wall and 2 for a goal (a goal is also floor). The "
    "worker stands on cell player, and boxes lists the cells holding boxes: box k starts on "
    "boxes[k]. Each move is 0 up (to the cell width lower in number), 1 right (one "
    "higher), 2 down (width higher), 3 left (one lower) or 4 undo. Read the moves in "
    "order. Before reading each move, the first one included, if every box is on a goal, stop: "
    "the puzzle is solved and the moves not yet read are not used. A move in a direction looks at the "
    "next cell t that way from the worker. If t is a wall, the move is blocked and nothing "
    "changes. If t holds a box, look at the cell u beyond it in the same direction: if u is "
    "a wall or holds a box, the move is blocked; otherwise the box moves to u and the "
    "worker to t, which is a push. Otherwise the worker moves to t, which is a step. A "
    "push or a step is recorded in the history, the latest last; a blocked move is not. "
    "A pushed box is dead if, after the push, it is not on a goal, has a wall above or below it, and also has a wall to "
    "its left or right. An undo takes back "
    "the latest move in the history and removes it from the history: the worker moves "
    "back the way it came, and if that move was a push, its box moves back too. An undo "
    "with an empty history does nothing. Return the worker's final cell, the final cell "
    "of each box (in the order of boxes), the number of moves read, the number of moves "
    "left in the history, the number of pushes made (an undone push still counts), the "
    "number of blocked moves, the number of undos that took a move back, the number of "
    "pushes that left a box dead (again counting undone ones), and whether every box is "
    "on a goal at the end. width and height are 3 to 12; cells has width times height "
    "values, each 0 to 2, and every cell in the first or last row or column is a wall; "
    "player and every value of boxes are cells that are not walls, boxes has 1 to 6 "
    "values, and no two of player and the boxes are the same cell; moves has at most 200 "
    "values, each 0 to 4."
)

_CHECKERS = (
    "Play draughts on an 8 by 8 board, both sides moving by a fixed rule, and report the "
    "result. Only the 32 dark squares are used, numbered 0 to 31: square i is in row r = "
    "i divided by 4, rounded down (row 0 at the top), and in column 2 times (i mod 4), plus "
    "1 when r is even. board[i] is 0 for empty, 1 for a white man, 2 for a white king, 3 "
    "for a black man and 4 for a black king. White men move up (towards row 0) and black "
    "men down; kings move both ways. A step moves a piece to an empty square diagonally "
    "next to it, in a direction it may move. A jump moves a piece over a diagonally next "
    "square holding a piece of the other side, in a direction it may move, to the empty "
    "square just beyond; the piece jumped over is taken off the board at once, and the square "
    "the capturing piece started from counts as empty during the capture, so it may land there. A capture "
    "is a sequence of jumps by one piece: after each jump, if that piece can jump again "
    "from where it landed, it must, and a capture is complete only when it cannot, "
    "except that a man that lands on the far row (row 0 for white, row 7 for black) is "
    "crowned king and its capture ends there. A man that steps onto its far row is "
    "crowned too. The side to move must capture if any of its pieces can; then it plays "
    "the complete capture that takes the most pieces, choosing among equals the one whose "
    "piece starts on the lowest-numbered square, then the one whose list of landing squares, read in order, is lower at the first "
    "place the lists differ, whatever its last landing. If it cannot capture it "
    "makes the step whose piece starts on the lowest-numbered square, and among those the "
    "step to the lowest-numbered square. White moves first if turn is 0 and black if turn "
    "is 1, then the sides alternate. Before each move, if the side to move has no capture "
    "or step, it has lost and play stops; otherwise, if plies moves have been played, play stops; otherwise it moves. "
    "So a side with no move when the limit is reached has still lost. Return the final board, the number of moves played, the "
    "number of pieces white took, the number black took, the number of men crowned (by a step or at the end of a capture, on "
    "either side), and "
    "the result: 1 if white won, 2 if black won, 0 if play stopped at the move limit. "
    "board has 32 values, each 0 to 4, with at most 12 pieces of each side, no white man on "
    "row 0 and no black man on row 7; turn is 0 or 1; plies is 1 to 40."
)

_REGEX = (
    "Match strings against a regular expression given as tokens. Token 0 to 25 is that "
    "letter; 26 is '.', matching any one letter; 27 '*', 28 '+' and 29 '?' are postfix "
    "operators; 30 is '|'; 31 '(' and 32 ')'. The pattern's grammar: an alternation is one "
    "or more sequences separated by '|'; a sequence is zero or more items, one after "
    "another; an item is an atom followed by zero or more postfix operators; an atom is a "
    "letter, '.', or '(' alternation ')'. The whole pattern is one alternation. A postfix operator applies to its item's atom together with any operators "
    "already after it, so ab* repeats only the b and (a*)? is a*?: '*' matches zero "
    "or more repeats, '+' one or more, '?' zero or one. A sequence matches its items one "
    "after another (an empty sequence matches the empty string), and an alternation "
    "matches if any of its sequences does. A pattern that does not fit the grammar, such "
    "as one with an operator where an atom should start, a '(' never closed or a ')' with "
    "no '(' open, is invalid. The strings are given together: string j has lens[j] letters, "
    "and chars holds every string's letters, string 0 first. For each string, return "
    "whether the whole string matches the pattern, and the length of the longest start "
    "of it (from no letters up to all of them) that matches, or -1 if none does. Also "
    "return how many strings match whole and whether the pattern is valid; for an invalid "
    "pattern every string gives false and -1, the count is 0 and validity is false. "
    "pattern has at most 20 tokens, each 0 to 32; lens has 1 to 8 values, each 0 to 12, "
    "adding up to the length of chars; every value of chars is 0 to 25."
)

_SWISS = (
    "Run a Swiss-system chess tournament and report the standings. Player p has rating "
    "ratings[p]. Scores count half points: a win is 2, a draw 1, a loss 0. Play rounds "
    "rounds. At the start of each round, rank the players by score, highest first, then "
    "by rating, highest first, then by player number, lowest first. If the number of "
    "players is odd, the lowest-ranked player who has not yet had a bye gets one: they score 2 and do not play this round. This is done before pairing, "
    "and that player is left out of it. Then pair the others: repeatedly take the "
    "highest-ranked player not yet paired this round, and pair them with the "
    "highest-ranked unpaired player they have not played before in this tournament; if "
    "they have played every unpaired player, pair them with the highest-ranked unpaired "
    "player anyway, which is a rematch. In each pair, white goes to the player who has "
    "had white fewer times so far; if equal, to the player whose last game was played "
    "as black, if exactly one of them (a player who has played no game has no last "
    "game); otherwise to the player taken first. A bye is not a "
    "game and does not count as a last game. The games of a round are played in the order "
    "they were paired, and their results are read from results in that order, round "
    "after round: 0 means white won, 1 a draw, 2 black won. Return each player's final "
    "score; each player's Buchholz score, the sum of the final scores of the opponents "
    "of every game they played (an opponent met twice counts twice; a bye adds nothing); "
    "the player numbers ranked by final score, then Buchholz score, then rating, each "
    "highest first, then player number, lowest first; the number of times each player "
    "had white; and the number of rematches. ratings has 2 to 12 values, each 1,000 to "
    "3,000; rounds is 1 to 7 and below the number of players; results has rounds times "
    "(the number of players divided by 2, rounded down) values, each 0 to 2."
)

_WAREHOUSE = (
    "Run a warehouse for days days, numbered from 0, and report the totals. There are "
    "products 0 to P - 1, where P is the length of price; product p sells for price[p] a "
    "unit. Stock is held in lots, each with a quantity, an expiry day and the order in "
    "which it arrived. A pending order for a product waits in that product's backorder "
    "queue with the quantity still owed and the day it was placed. Taking q units of a "
    "product means taking them from its lots with the earliest expiry first, and among "
    "equal expiries the lot that arrived first; a lot that reaches 0 is gone. When a "
    "lot of a product arrives, it is added, and then while that product has a backorder "
    "and units in stock, the oldest backorder is filled as far as the stock allows: the "
    "units taken are shipped, and the backorder is gone once nothing is owed. On each day "
    "d, in this order: first, every lot whose expiry day is before d is thrown away. "
    "Second, for each product in order, a supply ordered earlier that is due on day d "
    "arrives as a lot of rq[p] units expiring on day d + shelf[p]. Third, the events of "
    "day d happen in the order listed: event e is on day ev_day[e], for product "
    "ev_prod[e], with quantity ev_qty[e]. Kind 1 is a delivery: a lot of that quantity "
    "arrives, expiring on day ev_expiry[e]. Kind 2 is a customer order: if the product "
    "has any backorder, the whole order joins the end of its backorder queue; otherwise "
    "as many units as are in stock, up to the quantity, are taken and shipped, and any "
    "units not shipped join the end of the queue as a backorder placed on day d. Fourth, "
    "every backorder placed on day d - 7 or earlier is cancelled, and the units "
    "it still owes (even if it was partly filled) count as cancelled. Fifth, for each "
    "product in order, if it has no supply on the way and its units in stock are at "
    "most rp[p], a supply is ordered, due on day d + lead[p]; a supply stops being on the "
    "way when it arrives in the second step, so another can be ordered that same day. Every unit shipped earns its "
    "product's price. Return the units in stock of each product at the end, the total "
    "earned, the units shipped, the units thrown away, the units cancelled, the number of "
    "supplies ordered, and the units still owed on backorder at the end. price, rp, rq, "
    "lead and shelf have the same length P, 1 to 5; each price is 1 to 1,000, each rp 0 to "
    "100, each rq 1 to 200, each lead 1 to 10 and each shelf 1 to 30; days is 1 to 60. The "
    "five event sequences have the same length, at most 80; ev_day is 0 to days - 1 and "
    "never decreases from one event to the next; ev_kind is 1 or 2; ev_prod is 0 to P - 1; "
    "ev_qty is 1 to 200; ev_expiry is ev_day to ev_day + 60 for a delivery and 0 for an "
    "order."
)

_CACHE = (
    "Simulate a two-level cache and report its counters. Memory is made of blocks "
    "numbered 0 to 255. The first level has s1 sets of w1 places and the second level s2 "
    "sets of w2 places; block a belongs to set a mod s1 in the first level and a mod s2 "
    "in the second. Each place holds a block and a dirty mark. Each set keeps its blocks "
    "in order of use, least recently used first; using a block moves it to the most "
    "recent end, and putting a block into a set adds it at the most recent end after "
    "removing the least recently used block if the set is full (that block is evicted). "
    "Access i is to block addrs[i], a write if writes[i] is true and a read otherwise. If "
    "the block is in the first level, that is a first-level hit: it is used, and marked "
    "dirty if the access is a write. Otherwise it is a first-level miss, and: if the block "
    "is in the second level, that is a second-level hit and it is used there; otherwise it "
    "is a second-level miss, the block is read from memory and put into the second level "
    "unmarked, and if that evicts a dirty block, that block is written to memory. Then the "
    "block is put into the first level, marked dirty if the access is a write. If that "
    "evicts a dirty block b from the first level, b is written to the second level: if b "
    "is there it is used and marked dirty; otherwise it is put into the second level "
    "marked dirty, and if that evicts a dirty block, that block is written to memory. A "
    "clean evicted block is simply dropped. Return the number of first-level hits, "
    "first-level misses, second-level hits, second-level misses, memory reads and memory "
    "writes, the number of places in either level holding a dirty block at the end (a "
    "block dirty in both levels counts twice), and the blocks left "
    "in the first level, set 0 first, each set least recently used first. s1, w1 are 1 to "
    "4 and s2, w2 are 1 to 8; addrs and writes have the same length, at most 200; every "
    "value of addrs is 0 to 255."
)


# --- examples -------------------------------------------------------------------

_SOKOBAN_EX = (6, 5, [1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1],
               9, [15], [2, 1, 2, 3, 3, 4, 4, 0, 3, 3, 4, 1, 1])
_CHECKERS_EX = ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 1, 0, 0, 0],
                0, 2)
_REGEX_EX = ([0, 27, 1, 30, 31, 2, 3, 32, 28], [3, 2, 4, 0, 3, 1, 3],
             [0, 0, 1, 2, 3, 2, 3, 2, 3, 2, 3, 2, 1, 0, 1, 1])
_SWISS_EX = ([1500, 1600, 1400, 1700], 2, [0, 1, 2, 0])
_WAREHOUSE_EX = (12, [3], [0], [1], [10], [1], [0, 0, 3, 4], [1, 2, 2, 2], [0, 0, 0, 0], [5, 2, 4, 1], [1, 0, 0, 0])
_CACHE_EX = (1, 2, 1, 2, [1, 2, 1, 3, 2, 4, 5], [False, True, False, False, False, True, False])

# The costliest input for each Firth reference, of at least 40 at the largest sizes
# allowed: kernel steps 144,953 (40 random sokoban inputs, 12 by 12, 6 boxes, 200 moves),
# 209,279 (40 random checkers boards of 12 pieces a side and the opening with each side
# first, 40 plies), 98,097 (108 regex inputs: 36 patterns of up to 20 tokens built to be slow,
# each against 8 strings of 12 letters from three alphabets), 108,057 (40 swiss
# inputs of 12 players and 10 of 11, 7 rounds), 179,655 (40 random warehouse inputs, 5
# products, 60 days, 80 events) and 161,365 (50 random cache-sim inputs of 200 accesses).
_SOKOBAN_MAX = _random_sokoban(112, 12, 12, 6, 200)
_CHECKERS_MAX = _largest_checkers(110)
_REGEX_MAX = ([0, 27] * 10, [12] * 8, [0] * 96)
_SWISS_MAX = _random_swiss(101, 12, 7)
_WAREHOUSE_MAX = _random_warehouse(136, 5, 60, 80)
_CACHE_MAX = _largest_cache(117)

# The last hidden test of each task is the costliest, for its Firth reference, of at
# least 40 inputs at the largest sizes the description allows (README, "The scored tier").
SCORED: tuple[Task, ...] = (
    _t("sokoban", _SOKOBAN,
       [("width", I), ("height", I), ("cells", SI), ("player", I), ("boxes", SI), ("moves", SI)],
       [("player", I), ("boxes", SI), ("read", I), ("history", I), ("pushes", I), ("blocked", I),
        ("undos", I), ("dead", I), ("solved", B)], _sokoban, _SOKOBAN_EX,
       [*_sokoban_cases(), _random_sokoban(1), _random_sokoban(2), _random_sokoban(3, solve_at=17),
        _random_sokoban(4, solve_at=40), _SOKOBAN_MAX],
       ["seq", "loop", "rules", "state", "heavy"]),
    _t("checkers", _CHECKERS,
       [("board", SI), ("turn", I), ("plies", I)],
       [("board", SI), ("played", I), ("white_took", I), ("black_took", I), ("crowned", I), ("result", I)],
       _checkers, _CHECKERS_EX,
       [*_checkers_cases(), *(_random_checkers(s) for s in (5, 6, 7, 8)), _CHECKERS_MAX],
       ["seq", "nested-loop", "rules", "state", "heavy"]),
    _t("regex", _REGEX,
       [("pattern", SI), ("lens", SI), ("chars", SI)],
       [("full", SB), ("longest", SI), ("count", I), ("valid", B)], _regex, _REGEX_EX,
       [*_regex_cases(), *(_random_regex(s) for s in (1, 2, 3)), _random_regex(4, broken=True), _REGEX_MAX],
       ["seq", "nested-loop", "rules", "parse", "bool-seq", "heavy"]),
    _t("swiss", _SWISS,
       [("ratings", SI), ("rounds", I), ("results", SI)],
       [("scores", SI), ("buchholz", SI), ("ranking", SI), ("whites", SI), ("rematches", I)],
       _swiss, _SWISS_EX,
       [*_swiss_cases(), *(_random_swiss(s) for s in (1, 2, 3, 4)), _SWISS_MAX],
       ["seq", "nested-loop", "rules", "state", "sort", "heavy"]),
    _t("warehouse", _WAREHOUSE,
       [("days", I), ("price", SI), ("rp", SI), ("rq", SI), ("lead", SI), ("shelf", SI), ("ev_day", SI),
        ("ev_kind", SI), ("ev_prod", SI), ("ev_qty", SI), ("ev_expiry", SI)],
       [("stock", SI), ("earned", I), ("shipped", I), ("discarded", I), ("cancelled", I), ("supplies", I),
        ("owed", I)], _warehouse, _WAREHOUSE_EX,
       [*_warehouse_cases(), *(_random_warehouse(s) for s in (1, 2, 3, 4)), _WAREHOUSE_MAX],
       ["seq", "loop", "rules", "state", "heavy"]),
    _t("cache-sim", _CACHE,
       [("s1", I), ("w1", I), ("s2", I), ("w2", I), ("addrs", SI), ("writes", SB)],
       [("l1_hits", I), ("l1_misses", I), ("l2_hits", I), ("l2_misses", I), ("mem_reads", I),
        ("mem_writes", I), ("dirty", I), ("l1_blocks", SI)], _cache_sim, _CACHE_EX,
       [*_cache_cases(), *(_random_cache(s) for s in (1, 2, 3, 4)), _CACHE_MAX],
       ["seq", "nested-loop", "rules", "state", "divmod", "bool-seq", "heavy"]),
)
