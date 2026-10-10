"""The third calibration pool of the harder S7 tier (`todo.s7-harder-task-tier`).

The second pool's Python references are 31 to 77 lines and its Firth ones
41 to 194. This pool is five much larger programs, each a whole simulation
with many interacting rules and no Python library shortcut: its Python
references are 94 to 144 lines and its Firth ones 320 to 348, each written
by a Sonnet worker from the description alone. Like the first two pools it is run for
calibration only and never scored; the scored tier is a different, frozen
set.

Every description states every bound an answer depends on: the size of
each input, the range of each value, which fields are 0, and so the largest
result, which always fits in a 64-bit `Int`. `test_harder.py` checks that
no example, hidden test or hand value breaks those bounds, including the
structural ones (which fields an opcode uses, the token counts matching the
formula lengths, transaction days within the days simulated).

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



# --- mini-cpu -------------------------------------------------------------------

_W = 2 ** 32
_LIMIT = 300
_MEM = 64
_DSTACK = 16
_CSTACK = 8


def _wrap(x):
    return (x + 2 ** 31) % _W - 2 ** 31


def _cpu(ops, fa, fb, fc, regs, memory, inputs):
    n = len(ops)
    r = list(regs)
    mem = list(memory)
    z = neg = v = False
    data, calls, out = [], [], []
    inp = 0
    pc = steps = 0

    def done(status):
        return out, status, steps, pc, r, mem, [z, neg, v]

    while True:
        if steps == _LIMIT:
            return done(1)
        if not 0 <= pc < n:
            return done(2)
        op, a, b, c = ops[pc], fa[pc], fb[pc], fc[pc]
        nxt = pc + 1
        result = None            # (register, true value) for flag-setting arithmetic
        if op == 0:
            steps += 1
            return done(0)
        elif op == 1:
            r[a] = b
        elif op == 2:
            r[a] = r[b]
        elif op in (3, 4, 5):
            x, y = r[b], r[c]
            result = (a, x + y if op == 3 else x - y if op == 4 else x * y)
        elif op in (6, 7):
            x, y = r[b], r[c]
            if y == 0:
                return done(3)
            q = abs(x) // abs(y)
            if (x < 0) != (y < 0):
                q = -q
            result = (a, q if op == 6 else x - q * y)
        elif op == 8:
            result = (a, -r[b])
        elif op == 9:
            result = (a, r[b] * 2 ** c)
        elif op == 10:
            result = (a, r[b] // 2 ** c)
        elif op == 11:
            result = (None, r[b] - r[c])
        elif op in (12, 13):
            addr = r[b] + c
            if not 0 <= addr < _MEM:
                return done(6)
            if op == 12:
                r[a] = mem[addr]
            else:
                mem[addr] = r[a]
        elif op == 14:
            nxt = b
        elif op in (15, 16, 17, 18):
            take = {15: z, 16: not z, 17: neg != v, 18: neg == v}[op]
            if take:
                nxt = b
        elif op == 19:
            if len(data) == _DSTACK:
                return done(4)
            data.append(r[a])
        elif op == 20:
            if not data:
                return done(5)
            r[a] = data.pop()
        elif op == 21:
            if len(calls) == _CSTACK:
                return done(4)
            calls.append(pc + 1)
            nxt = b
        elif op == 22:
            if not calls:
                return done(5)
            nxt = calls.pop()
        elif op == 23:
            if inp == len(inputs):
                return done(7)
            r[a] = inputs[inp]
            inp += 1
        elif op == 24:
            out.append(r[a])
        if result is not None:
            reg, true = result
            val = _wrap(true)
            z, neg, v = val == 0, val < 0, val != true
            if reg is not None:
                r[reg] = val
        steps += 1
        pc = nxt

# --- stacker --------------------------------------------------------------------

# _PIECES[kind][rotation] = four (column, row) cells inside a 4 by 4 box,
# column 0 at the left and row 0 at the bottom of the box.
_PIECES = [
    [[(0, 2), (1, 2), (2, 2), (3, 2)], [(2, 0), (2, 1), (2, 2), (2, 3)],
     [(0, 1), (1, 1), (2, 1), (3, 1)], [(1, 0), (1, 1), (1, 2), (1, 3)]],          # 0 I
    [[(1, 1), (2, 1), (1, 2), (2, 2)]] * 4,                                         # 1 O
    [[(0, 2), (1, 2), (2, 2), (1, 3)], [(1, 1), (1, 2), (1, 3), (2, 2)],
     [(0, 2), (1, 2), (2, 2), (1, 1)], [(1, 1), (1, 2), (1, 3), (0, 2)]],          # 2 T
    [[(0, 2), (1, 2), (1, 3), (2, 3)], [(1, 3), (1, 2), (2, 2), (2, 1)],
     [(0, 1), (1, 1), (1, 2), (2, 2)], [(0, 3), (0, 2), (1, 2), (1, 1)]],          # 3 S
    [[(0, 3), (1, 3), (1, 2), (2, 2)], [(2, 3), (2, 2), (1, 2), (1, 1)],
     [(0, 2), (1, 2), (1, 1), (2, 1)], [(1, 3), (1, 2), (0, 2), (0, 1)]],          # 4 Z
    [[(0, 2), (1, 2), (2, 2), (2, 3)], [(1, 3), (1, 2), (1, 1), (2, 1)],
     [(0, 1), (0, 2), (1, 2), (2, 2)], [(0, 3), (1, 3), (1, 2), (1, 1)]],          # 5 L
    [[(0, 3), (0, 2), (1, 2), (2, 2)], [(1, 1), (1, 2), (1, 3), (2, 3)],
     [(0, 2), (1, 2), (2, 2), (2, 1)], [(0, 1), (1, 1), (1, 2), (1, 3)]],          # 6 J
]
_KICKS = [(0, 0), (-1, 0), (1, 0), (0, 1), (-2, 0), (2, 0)]
_CLEAR = [0, 100, 300, 500, 800]


def _stacker(width, height, queue, moves):
    grid = [[False] * width for _ in range(height)]       # grid[row][column]
    score = lines = locked = 0
    combo = -1                 # clearing locks in a row, minus one; -1 after a lock that clears nothing
    last_clear_tetris = False  # whether the last lock that cleared any row cleared four
    held = -1
    qi = mi = 0

    def fits(kind, rot, x, y):
        for cx, cy in _PIECES[kind][rot]:
            col, row = x + cx, y + cy
            if not (0 <= col < width and 0 <= row < height) or grid[row][col]:
                return False
        return True

    def heights():
        return [max([row + 1 for row in range(height) if grid[row][col]], default=0)
                for col in range(width)]

    def finish(status):
        return heights(), score, lines, locked, status, held

    spawn_x, spawn_y = (width - 4) // 2, height - 4
    current = None
    while True:
        if current is None:
            if qi == len(queue):
                return finish(0)
            current = queue[qi]
            qi += 1
            x, y, rot, used_hold = spawn_x, spawn_y, 0, False
            if not fits(current, rot, x, y):
                return finish(2)
        if mi == len(moves):
            return finish(1)
        m = moves[mi]
        mi += 1
        if m in (1, 2):
            dx = -1 if m == 1 else 1
            if fits(current, rot, x + dx, y):
                x += dx
        elif m in (3, 4):
            new = (rot + (1 if m == 3 else 3)) % 4
            for kx, ky in _KICKS:
                if fits(current, new, x + kx, y + ky):
                    x, y, rot = x + kx, y + ky, new
                    break
        elif m == 5:
            if fits(current, rot, x, y - 1):
                y -= 1
        elif m == 6:
            if used_hold:
                continue
            if held == -1:
                held, current = current, None
                if qi == len(queue):
                    return finish(0)
                current = queue[qi]
                qi += 1
            else:
                held, current = current, held
            x, y, rot, used_hold = spawn_x, spawn_y, 0, True
            if not fits(current, rot, x, y):
                return finish(2)
        elif m == 0:
            while fits(current, rot, x, y - 1):
                y -= 1
            for cx, cy in _PIECES[current][rot]:
                grid[y + cy][x + cx] = True
            locked += 1
            full = [row for row in range(height) if all(grid[row])]
            if full:
                level = 1 + lines // 10
                base = _CLEAR[len(full)]
                if len(full) == 4 and last_clear_tetris:
                    base = 1200
                combo += 1
                score += (base + 50 * combo) * level
                lines += len(full)
                last_clear_tetris = len(full) == 4
                grid = [g for row, g in enumerate(grid) if row not in full]
                grid += [[False] * width for _ in full]
            else:
                combo = -1
            current = None

# --- bank-days ------------------------------------------------------------------

_FEE = 1000


def _leap(y):
    return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)


def _month_days(y, m):
    return [31, 29 if _leap(y) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]


def _bank_days(year, month, day, days, balances, limits, credit_ppm, debit_ppm,
               tx_day, tx_kind, tx_acct, tx_other, tx_amount,
               so_dom, so_from, so_to, so_amount):
    n = len(balances)
    bal = list(balances)
    acc = [0] * n
    went_negative = [False] * n
    so_fails = [0] * len(so_dom)
    cancelled = [False] * len(so_dom)
    rejected = paid = charged = fees = 0
    y, m, d = year, month, day

    def move(kind, a, b, amount):
        """Carry out a deposit (1), withdrawal (2) or transfer (3); False if rejected."""
        if kind == 1:
            bal[a] += amount
            return True
        if kind == 3 and a == b:
            return False
        if bal[a] - amount < -limits[a]:
            return False
        bal[a] -= amount
        if kind == 3:
            bal[b] += amount
        return True

    for t in range(days):
        last = d == _month_days(y, m)
        for k in range(len(tx_day)):
            if tx_day[k] == t and not move(tx_kind[k], tx_acct[k], tx_other[k], tx_amount[k]):
                rejected += 1
        for k in range(len(so_dom)):
            if cancelled[k]:
                continue
            if so_dom[k] == d or (last and so_dom[k] > d):
                if move(3, so_from[k], so_to[k], so_amount[k]):
                    so_fails[k] = 0
                else:
                    rejected += 1
                    so_fails[k] += 1
                    if so_fails[k] == 2:
                        cancelled[k] = True
        for i in range(n):
            if bal[i] > 0:
                acc[i] += bal[i] * credit_ppm
            elif bal[i] < 0:
                acc[i] += bal[i] * debit_ppm
                went_negative[i] = True
        if last:
            for i in range(n):
                post = abs(acc[i]) // 1_000_000
                if acc[i] >= 0:
                    bal[i] += post
                    paid += post
                else:
                    bal[i] -= post
                    charged += post
                acc[i] = 0
                if went_negative[i]:
                    bal[i] -= _FEE
                    fees += _FEE
                went_negative[i] = False
        d += 1
        if d > _month_days(y, m):
            d, m = 1, m + 1
            if m == 13:
                m, y = 1, y + 1
    return bal, rejected, cancelled, paid, charged, fees

# --- formula-sheet --------------------------------------------------------------

_BIG = 10 ** 9
_ERR = None


def _parse(lens, kinds, xs, ys, zs):
    """Split the flat token sequences into one list of (kind, x, y, z) per formula."""
    out, pos = [], 0
    for n in lens:
        out.append(list(zip(kinds[pos:pos + n], xs[pos:pos + n], ys[pos:pos + n], zs[pos:pos + n])))
        pos += n
    return out


def _deps(formula, n):
    """Cells a formula refers to: references inside the sheet, and the cells of ranges
    whose two ends are inside the sheet with the first not after the second."""
    out = set()
    for k, x, y, z in formula:
        if k == 1 and 0 <= x < n:
            out.add(x)
        elif k == 3 and 0 <= y <= z < n:
            out.update(range(y, z + 1))
    return out


def _evaluate(formulas):
    n = len(formulas)
    deps = [_deps(f, n) for f in formulas]

    def reach(i):
        seen, todo = set(), list(deps[i])
        while todo:
            j = todo.pop()
            if j not in seen:
                seen.add(j)
                todo.extend(deps[j])
        return seen

    reaches = [reach(i) for i in range(n)]
    cyclic = [any(j in reaches[j] for j in reaches[i]) for i in range(n)]
    value = [_ERR] * n
    done = [False] * n

    def get(i):
        if not done[i]:
            done[i] = True
            value[i] = _ERR if cyclic[i] else _run(formulas[i], get, n)
        return value[i]

    return [get(i) for i in range(n)]


def _checked(v):
    return _ERR if v is _ERR or abs(v) > _BIG else v


def _run(formula, get, n):
    stack = []
    for k, x, y, z in formula:
        if k == 0:
            stack.append(x)
        elif k == 1:
            stack.append(get(x) if 0 <= x < n else _ERR)
        elif k == 2:
            need = 1 if x == 8 else 3 if x == 7 else 2
            if len(stack) < need:
                return _ERR
            args = stack[-need:]
            del stack[-need:]
            stack.append(_op(x, args))
        elif k == 3:
            if not 0 <= y <= z < n:
                stack.append(_ERR)
                continue
            vals = [get(j) for j in range(y, z + 1)]
            if x == 4:
                stack.append(sum(v is not _ERR for v in vals))
            elif any(v is _ERR for v in vals):
                stack.append(_ERR)
            else:
                stack.append(_checked(sum(vals) if x == 1 else min(vals) if x == 2 else max(vals)))
    return stack[0] if len(stack) == 1 else _ERR


def _op(x, args):
    if x == 7:
        c, a, b = args
        if c is _ERR:
            return _ERR
        return a if c != 0 else b
    if any(v is _ERR for v in args):
        return _ERR
    if x == 8:
        return -args[0]
    a, b = args
    if x == 1:
        return _checked(a + b)
    if x == 2:
        return _checked(a - b)
    if x == 3:
        return _checked(a * b)
    if x == 4:
        if b == 0:
            return _ERR
        q = abs(a) // abs(b)
        return q if (a < 0) == (b < 0) else -q
    if x == 5:
        return 1 if a < b else 0
    return 1 if a == b else 0


def _formula_sheet(lens, kinds, xs, ys, zs, edit_cells, edit_lens, e_kinds, e_xs, e_ys, e_zs):
    formulas = _parse(lens, kinds, xs, ys, zs)
    edits = _parse(edit_lens, e_kinds, e_xs, e_ys, e_zs)
    vals = _evaluate(formulas)
    changed = []
    for cell, f in zip(edit_cells, edits):
        formulas[cell] = f
        new = _evaluate(formulas)
        changed.append(sum(a != b for a, b in zip(vals, new)))
        vals = new
    return [0 if v is _ERR else v for v in vals], [v is _ERR for v in vals], changed

# --- blackjack ------------------------------------------------------------------

class _OutOfCards(Exception):
    pass


def _value(rank):
    return 10 if rank >= 10 else rank       # an ace counts 1 here


def _total(cards):
    """(best total, soft): an ace counts 11 when that keeps the total at 21 or less."""
    t = sum(_value(c) for c in cards)
    if 1 in cards and t + 10 <= 21:
        return t + 10, True
    return t, False


def _wants_hit(cards, up):
    t, soft = _total(cards)
    if soft:
        return t <= 17
    if t <= 11:
        return True
    if t <= 16:
        return up == 1 or up >= 7
    return False


def _blackjack_table(shoe, bankrolls, bets, rounds):
    bank = list(bankrolls)
    pos = 0
    played = dealer_busts = naturals = 0

    def draw():
        nonlocal pos
        if pos == len(shoe):
            raise _OutOfCards
        pos += 1
        return shoe[pos - 1]

    try:
        for _ in range(rounds):
            seated = [i for i in range(len(bank)) if bank[i] >= bets[i]]
            if not seated:
                break
            hands = {i: [draw()] for i in seated}
            up = draw()
            for i in seated:
                hands[i].append(draw())
            hole = draw()
            dealer = [up, hole]
            delta = {i: 0 for i in seated}
            nat = busts = 0                    # this round's counts, kept only if it completes
            if _value(up) in (1, 10) and _total(dealer)[0] == 21:
                for i in seated:
                    if _total(hands[i])[0] != 21:
                        delta[i] -= bets[i]
                    else:
                        nat += 1
            else:
                live = []                      # (player, cards, stake)
                for i in seated:
                    cards = hands[i]
                    if _total(cards)[0] == 21:
                        nat += 1
                        delta[i] += bets[i] * 3 // 2
                        continue
                    committed = bets[i]
                    if cards[0] == cards[1] and cards[0] in (1, 8) and bank[i] >= committed + bets[i]:
                        committed += bets[i]
                        split = [[cards[0], draw()], [cards[1], draw()]]
                        for h in split:
                            if cards[0] == 1:
                                live.append((i, h, bets[i]))
                                continue
                            stake, committed = _play(h, up, bets[i], bank[i], committed, draw)
                            live.append((i, h, stake))
                        continue
                    stake, committed = _play(cards, up, bets[i], bank[i], committed, draw)
                    live.append((i, cards, stake))
                standing = [x for x in live if _total(x[1])[0] <= 21]
                if standing:
                    while _total(dealer)[0] < 17:
                        dealer.append(draw())
                d = _total(dealer)[0]
                if standing and d > 21:
                    busts = 1
                else:
                    busts = 0
                for i, cards, stake in live:
                    t = _total(cards)[0]
                    if t > 21:
                        delta[i] -= stake
                    elif d > 21 or t > d:
                        delta[i] += stake
                    elif t < d:
                        delta[i] -= stake
            for i in seated:
                bank[i] += delta[i]
            played += 1
            naturals += nat
            dealer_busts += busts
    except _OutOfCards:
        pass
    return bank, played, dealer_busts, naturals


def _play(cards, up, bet, bankroll, committed, draw):
    """Play one hand; returns its stake and the player's new committed total."""
    t, soft = _total(cards)
    if (len(cards) == 2 and not soft and t in (10, 11) and 2 <= up <= 9
            and bankroll >= committed + bet):
        cards.append(draw())
        return 2 * bet, committed + bet
    while _total(cards)[0] <= 21 and _wants_hit(cards, up):
        cards.append(draw())
    return bet, committed

# --- random inputs --------------------------------------------------------------


_M32 = 2 ** 31
_REG_A = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 19, 20, 23, 24}
_REG_B = set(range(2, 14))
_REG_C = {3, 4, 5, 6, 7, 11}
_JUMPS = {14, 15, 16, 17, 18, 21}


def _small(rng):
    return rng.choice([rng.randint(-20, 20), rng.randint(-_M32, _M32 - 1),
                       rng.choice([-_M32, _M32 - 1, 0, 1, -1, 65536, 46341])])


def _random_cpu(seed, n=None):
    rng = random.Random(seed)
    n = n or rng.randint(8, 64)
    weights = {0: 1, 1: 6, 2: 3, 3: 4, 4: 4, 5: 3, 6: 2, 7: 2, 8: 1, 9: 2, 10: 2, 11: 4,
               12: 3, 13: 3, 14: 2, 15: 3, 16: 3, 17: 3, 18: 3, 19: 3, 20: 3, 21: 2, 22: 2,
               23: 3, 24: 4}
    ops, fa, fb, fc = [], [], [], []
    for _ in range(n):
        op = rng.choices(list(weights), list(weights.values()))[0]
        a = rng.randint(0, 7) if op in _REG_A else 0
        if op == 1:
            b = _small(rng)
        elif op in _REG_B:
            b = rng.randint(0, 7)
        elif op in _JUMPS:
            b = rng.randint(0, n - 1) if rng.random() < 0.95 else rng.choice([-2, -1, n, 66])
        else:
            b = 0
        if op in _REG_C:
            c = rng.randint(0, 7)
        elif op in (9, 10):
            c = rng.randint(0, 31)
        elif op in (12, 13):
            c = rng.randint(-8, 64) if rng.random() < 0.9 else rng.choice([-64, 64])
        else:
            c = 0
        ops.append(op), fa.append(a), fb.append(b), fc.append(c)
    regs = [rng.randint(0, 63) if rng.random() < 0.8 else _small(rng) for _ in range(8)]
    memory = [_small(rng) for _ in range(64)]
    inputs = [_small(rng) for _ in range(rng.randint(0, 40))]
    return ops, fa, fb, fc, regs, memory, inputs


def _random_stacker(seed, width=None, height=None, pieces=None):
    rng = random.Random(seed)
    width = width or rng.randint(4, 10)
    height = height or rng.randint(6, 10)
    pieces = pieces or rng.randint(5, 30)
    queue = [rng.randint(0, 6) for _ in range(pieces)]
    moves = []
    while len(moves) < 100:
        plan = []
        if rng.random() < 0.08:
            plan.append(6)
        plan += [rng.choice([3, 4])] * rng.choice([0, 0, 1, 1, 2, 3])
        shift = rng.randint(-(width // 2) - 1, width // 2 + 1)
        plan += [1 if shift < 0 else 2] * abs(shift)
        if rng.random() < 0.2:
            plan += [5] * rng.randint(1, 4) + [rng.choice([1, 2, 3, 4])]
        plan.append(0)
        if len(moves) + len(plan) > 100:
            break
        moves += plan
    if rng.random() < 0.3:
        moves = moves[:rng.randint(0, len(moves))]
    return width, height, queue, moves


def _random_bank(seed):
    rng = random.Random(seed)
    n = rng.randint(1, 6)
    year = rng.choice([1900, 2000, 2023, 2024, 2100, rng.randint(1900, 2100)])
    month = rng.randint(1, 12)
    mdays = [31, 29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28,
             31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
    day = rng.choice([1, mdays, rng.randint(1, mdays)])
    days = rng.randint(1, 120)
    big = rng.random() < 0.5
    balances = [rng.randint(0, 1_000_000 if big else 5000) for _ in range(n)]
    limits = [rng.choice([0, rng.randint(0, 1_000_000 if big else 5000)]) for _ in range(n)]
    credit, debit = rng.randint(0, 1000), rng.randint(0, 1000)
    t = rng.randint(0, 60)
    tx_day = sorted(rng.randint(0, days - 1) for _ in range(t)) if rng.random() < 0.5 \
        else [rng.randint(0, days - 1) for _ in range(t)]
    tx_kind = [rng.randint(1, 3) for _ in range(t)]
    tx_acct = [rng.randint(0, n - 1) for _ in range(t)]
    tx_other = [rng.randint(0, n - 1) if k == 3 else 0 for k in tx_kind]
    tx_amount = [rng.randint(1, 1_000_000 if big else 5000) for _ in range(t)]
    s = rng.randint(0, 6)
    so_dom = [rng.choice([1, 15, 28, 29, 30, 31, rng.randint(1, 31)]) for _ in range(s)]
    so_from = [rng.randint(0, n - 1) for _ in range(s)]
    so_to = [rng.randint(0, n - 1) for _ in range(s)]
    so_amount = [rng.randint(1, max(1, sum(balances) // (2 * n) + 1)) for _ in range(s)]
    return (year, month, day, days, balances, limits, credit, debit,
            tx_day, tx_kind, tx_acct, tx_other, tx_amount, so_dom, so_from, so_to, so_amount)


def _expr(rng, n, before, budget):
    """A well-formed RPN expression of at most budget tokens; refers mostly to earlier cells."""
    def leaf():
        r = rng.random()
        if r < 0.35 or (not before and rng.random() < 0.95):
            return [(0, rng.randint(-10 ** 6, 10 ** 6) if rng.random() < 0.08 else rng.randint(-20, 20), 0, 0)]
        if r < 0.75:
            if before and rng.random() < 0.985:
                x = rng.randint(0, before - 1)
            else:
                x = rng.randint(-5, 35) if rng.random() < 0.15 else rng.randint(0, n - 1)
            return [(1, x, 0, 0)]
        hi = before - 1 if before and rng.random() < 0.985 else n - 1
        y = rng.randint(0, hi)
        z = rng.randint(y, min(hi, y + 6))
        if rng.random() < 0.04:
            y, z = rng.randint(-5, 35), rng.randint(-5, 35)
        return [(3, rng.randint(1, 4), y, z)]

    def build(budget):
        if budget < 3 or rng.random() < 0.3:
            if budget >= 2 and rng.random() < 0.2:
                return leaf() + [(2, 8, 0, 0)]
            return leaf()
        if budget >= 7 and rng.random() < 0.2:
            c = build(2); a = build((budget - 3) // 2); b = build(budget - 1 - len(c) - len(a))
            return c + a + b + [(2, 7, 0, 0)]
        a = build((budget - 1) // 2)
        b = build(budget - 1 - len(a))
        return a + b + [(2, rng.choice([1, 1, 2, 2, 3, 3, 4, 5, 6]), 0, 0)]

    return build(budget)


def _formula(rng, n, before):
    toks = _expr(rng, n, before, rng.randint(1, 8))
    r = rng.random()
    if r < 0.04:
        toks = toks[:-1]
    elif r < 0.07:
        toks = toks + [(0, 1, 0, 0)]
    elif r < 0.09:
        toks = []
    return toks[:8]


def _random_sheet(seed, n=None, edits=None):
    rng = random.Random(seed)
    n = n or rng.randint(1, 20)
    forms = [_formula(rng, n, i) for i in range(n)]
    lens = [len(f) for f in forms]
    flat = [t for f in forms for t in f]
    ne = rng.randint(0, 4) if edits is None else edits
    ecells, eforms = [], []
    for _ in range(ne):
        c = rng.randint(0, n - 1)
        ecells.append(c)
        eforms.append(_formula(rng, n, n if rng.random() < 0.15 else c))
    elens = [len(f) for f in eforms]
    eflat = [t for f in eforms for t in f]
    col = lambda ts, k: [t[k] for t in ts]
    return (lens, col(flat, 0), col(flat, 1), col(flat, 2), col(flat, 3), ecells, elens,
            col(eflat, 0), col(eflat, 1), col(eflat, 2), col(eflat, 3))


def _largest_bank(seed):
    """A bank-days input with the largest number of days."""
    a = list(_random_bank(seed))
    rng = random.Random(seed)
    a[3] = 120
    a[8] = [rng.randint(0, 119) for _ in a[8]]
    return tuple(a)


def _largest_blackjack(seed):
    """A blackjack input with the largest shoe, players and rounds."""
    rng = random.Random(seed)
    return [rng.randint(1, 13) for _ in range(120)], [100_000] * 5, [rng.randint(1, 50) for _ in range(5)], 20


def _random_blackjack(seed):
    rng = random.Random(seed)
    p = rng.randint(1, 5)
    shoe = [rng.randint(1, 13) for _ in range(rng.choice([rng.randint(4, 40), rng.randint(40, 120), 120]))]
    bets = [rng.choice([1, 2, 5, 10, 25, 100, rng.randint(1, 1000)]) for _ in range(p)]
    bankrolls = [rng.choice([0, b, 2 * b, 3 * b, rng.randint(0, 100_000)]) for b in bets]
    rounds = rng.randint(1, 20)
    return shoe, bankrolls, bets, rounds


def _greedy_stacker(seed, width=None, height=None, pieces=None, noise=0.15):
    """Inputs whose moves place each piece well, so rows are cleared; the moves are
    chosen by trying every rotation and shift on a copy of the game (via the meaning)."""
    rng = random.Random(seed)
    width = width or rng.randint(4, 10)
    height = height or rng.randint(6, 10)
    pieces = pieces or rng.randint(10, 30)
    queue = [rng.randint(0, 6) for _ in range(pieces)]
    moves = []
    for k in range(pieces):
        best = None
        options = []
        for turns in range(4):
            for shift in range(-width, width + 1):
                plan = [3] * turns + ([1] if shift < 0 else [2]) * abs(shift) + [0]
                options.append(plan)
        rng.shuffle(options)
        for plan in options:
            if len(moves) + len(plan) > 100:
                continue
            h, score, lines, locked, status, _ = _stacker(width, height, queue[:k + 1], moves + plan)
            if locked != k + 1:
                continue
            key = (-lines, max(h), sum(h))
            if best is None or key < best[0]:
                best = (key, plan)
        if best is None:
            break
        plan = best[1]
        if rng.random() < noise:
            plan = rng.choice(options)
            if len(moves) + len(plan) > 100:
                break
        moves += plan
    return width, height, queue, moves
# --- hand-written inputs ------------------------------------------------------

def _prog(code, regs=None, memory=None, inputs=()):
    """mini-cpu inputs from a list of (op, a, b, c) instructions."""
    return ([i[0] for i in code], [i[1] for i in code], [i[2] for i in code], [i[3] for i in code],
            list(regs or [0] * 8), list(memory or [0] * 64), list(inputs))


_MIN, _MAX = -2 ** 31, 2 ** 31 - 1

# Count r0 down to 0 by r1 = 1, then halt: 1 + 2 * r0 + 1 instructions.
_COUNTDOWN = [(1, 1, 1, 0), (4, 0, 0, 1), (16, 0, 1, 0), (0, 0, 0, 0)]

# Read a count, then that many values into memory 0 onward; bubble-sort them; output them.
_SORT = [(23, 7, 0, 0), (1, 0, 0, 0), (1, 6, 1, 0), (11, 0, 0, 7), (18, 0, 9, 0), (23, 1, 0, 0),
         (13, 1, 0, 0), (3, 0, 0, 6), (14, 0, 3, 0),
         (1, 5, 0, 0), (1, 0, 0, 0), (4, 4, 7, 6), (11, 0, 0, 4), (18, 0, 23, 0), (12, 1, 0, 0),
         (12, 2, 0, 1), (11, 0, 2, 1), (18, 0, 21, 0), (13, 2, 0, 0), (13, 1, 0, 1), (1, 5, 1, 0),
         (3, 0, 0, 6), (14, 0, 12, 0), (11, 0, 5, 3), (16, 0, 9, 0),
         (1, 0, 0, 0), (11, 0, 0, 7), (18, 0, 32, 0), (12, 1, 0, 0), (24, 1, 0, 0), (3, 0, 0, 6),
         (14, 0, 26, 0), (0, 0, 0, 0)]

# Recursive factorial of an input, saving n on the data stack around each call.
_FACT = [(23, 0, 0, 0), (1, 1, 1, 0), (21, 0, 5, 0), (24, 2, 0, 0), (0, 0, 0, 0),
         (11, 0, 1, 0), (17, 0, 9, 0), (1, 2, 1, 0), (22, 0, 0, 0),
         (19, 0, 0, 0), (4, 0, 0, 1), (21, 0, 5, 0), (20, 0, 0, 0), (5, 2, 2, 0), (22, 0, 0, 0)]

# Output the first r3 Fibonacci numbers: 4 + 8 * r3 + 2 instructions, so 35 fit and 50 do not.
_FIB = [(1, 0, 0, 0), (1, 1, 1, 0), (1, 4, 1, 0), (1, 5, 0, 0), (11, 0, 3, 5), (15, 0, 12, 0),
        (24, 0, 0, 0), (3, 2, 0, 1), (2, 0, 1, 0), (2, 1, 2, 0), (4, 3, 3, 4), (14, 0, 4, 0),
        (0, 0, 0, 0)]

# Signed-less-than through the flags: r0 < r1 outputs 1, else 0.
_LESS = [(11, 0, 0, 1), (17, 0, 4, 0), (24, 2, 0, 0), (0, 0, 0, 0), (24, 3, 0, 0), (0, 0, 0, 0)]


def _cpu_cases():
    regs = lambda *rs: list(rs) + [0] * (8 - len(rs))
    return [
        _prog([(0, 0, 0, 0)]),
        _prog([(1, 0, 5, 0)]),
        _prog([(14, 0, 0, 0)]),
        _prog(_COUNTDOWN, regs(149)),
        _prog(_COUNTDOWN, regs(150)),
        _prog([(3, 2, 0, 1), (5, 3, 0, 0), (9, 4, 0, 3), (10, 5, 6, 2), (24, 2, 0, 0), (24, 3, 0, 0),
               (24, 4, 0, 0), (24, 5, 0, 0), (0, 0, 0, 0)], regs(_MAX, 1, 0, 0, 0, 0, -7)),
        _prog([(6, 2, 0, 1), (7, 3, 0, 1), (24, 2, 0, 0), (24, 3, 0, 0), (6, 4, 5, 6), (24, 4, 0, 0),
               (6, 7, 0, 7), (0, 0, 0, 0)], regs(-7, 2, 0, 0, 0, _MIN, -1)),
        _prog([(7, 2, 0, 1), (24, 2, 0, 0), (8, 3, 4, 0), (15, 0, 6, 0), (24, 3, 0, 0), (0, 0, 0, 0),
               (24, 4, 0, 0)], regs(7, -2, 0, 0, _MIN)),
        _prog(_LESS, regs(_MIN, 1, 0, 1)),
        _prog(_LESS, regs(_MAX, -1, 0, 1)),
        _prog(_LESS, regs(5, 5, 0, 1)),
        _prog([(13, 0, 1, 63), (12, 2, 1, 63), (24, 2, 0, 0), (13, 0, 1, 64)], regs(42, 0)),
        _prog([(12, 2, 1, -1), (24, 2, 0, 0), (12, 3, 1, -9), (0, 0, 0, 0)], regs(0, 9),
              list(range(100, 164))),
        _prog([(19, 0, 0, 0), (3, 0, 0, 1), (16, 0, 0, 0)], regs(-20, 1)),
        _prog([(19, 0, 0, 0), (19, 1, 0, 0), (20, 2, 0, 0), (20, 3, 0, 0), (24, 2, 0, 0), (24, 3, 0, 0),
               (20, 4, 0, 0)], regs(11, 22)),
        _prog([(21, 0, 0, 0)]),
        _prog([(22, 0, 0, 0)]),
        _prog([(23, 0, 0, 0), (24, 0, 0, 0), (14, 0, 0, 0)], inputs=[3, -1, _MIN]),
        _prog([(14, 0, -2, 0)]),
        _prog([(1, 0, 0, 0), (11, 0, 0, 0), (16, 0, 66, 0), (15, 0, 66, 0)]),
        _prog(_SORT, inputs=[5, 30, -4, 30, _MAX, _MIN]),
        _prog(_SORT, inputs=[7, 7, 6, 5, 4, 3, 2, 1]),
        _prog(_FACT, inputs=[8]),
        _prog(_FACT, inputs=[9]),
        _prog(_FIB, regs(0, 0, 0, 35)),
        _prog(_FIB, regs(0, 0, 0, 50)),
    ]


def _stacker_cases():
    v_i = lambda shift: [3] + ([1] * -shift if shift < 0 else [2] * shift) + [0]   # vertical I at column 2 + shift
    four_cols = v_i(-2) + v_i(-1) + v_i(0) + v_i(1)
    return [
        (6, 10, [], [0]),
        (6, 10, [2, 3], []),
        (4, 4, [0], [0]),
        (4, 8, [0] * 16, four_cols * 4),
        (4, 8, [0] * 12, [0] * 12),
        (4, 8, [0] * 10, four_cols + [0] + four_cols),
        (4, 6, [0, 0], [3, 1, 1, 3, 0, 0]),
        (4, 6, [0, 1], [3, 1, 1, 0, 3, 3, 3, 0]),
        (6, 8, [2, 5, 6, 1], [6, 6, 0, 6, 1, 1, 1, 0, 6, 0]),
        (6, 8, [2], [6]),
        (6, 8, [2, 3], [6, 0, 6]),
        (4, 4, [1, 1, 1], [0, 0, 0, 0]),
        (5, 6, [1, 0, 1, 0], [6, 6, 0, 0, 6]),
        (4, 4, [1, 1, 2, 5, 6], [1, 6, 2, 1, 0, 2, 6]),
        (6, 10, [1, 1, 0, 2], [1, 1, 0, 2, 2, 0, 5, 5, 5, 5, 5, 1, 0, 0]),
        (8, 10, [3, 4, 2, 5, 6, 0, 1], [3, 1, 0, 4, 2, 2, 0, 3, 3, 0, 4, 4, 1, 1, 0, 3, 2, 2, 2, 0,
                                        3, 0, 1, 0]),
    ]


def _bank_cases():
    z = [], [], [], [], []
    return [
        (2023, 6, 15, 1, [100], [0], 0, 0, *z, [], [], [], []),
        (2024, 1, 31, 31, [1_000_000, 0], [0, 0], 1000, 0, *z, [31], [0], [1], [100]),
        (2023, 1, 31, 31, [1_000_000, 0], [0, 0], 1000, 0, *z, [31], [0], [1], [100]),
        (1900, 2, 1, 29, [1_000_000, 0], [0, 0], 1000, 0, *z, [30, 29], [0, 0], [1, 1], [1, 2]),
        (2000, 2, 1, 29, [1_000_000, 0], [0, 0], 1000, 0, *z, [30, 29], [0, 0], [1, 1], [1, 2]),
        (2023, 3, 1, 120, [500, 0], [0, 0], 0, 0, [], [], [], [], [], [1], [0], [1], [400]),
        (2023, 3, 1, 120, [500, 0], [0, 0], 0, 0, [61], [1], [0], [0], [400], [1], [0], [1], [400]),
        (2023, 3, 1, 3, [10, 10], [5, 0], 0, 0, [0, 1, 2], [3, 2, 3], [0, 0, 1], [0, 0, 1], [5, 10, 1],
         [2], [1], [1], [1]),
        (2023, 3, 1, 1, [0], [100], 0, 0, [0, 0, 0], [2, 2, 1], [0, 0, 0], [0, 0, 0], [100, 1, 1],
         [], [], [], []),
        (2023, 3, 1, 1, [0], [100], 0, 0, [0, 0, 0], [1, 2, 2], [0, 0, 0], [0, 0, 0], [1, 100, 1],
         [], [], [], []),
        (2023, 4, 29, 4, [1_000_000, 0], [0, 1_000_000], 7, 3, [0], [3], [0], [1], [1_000_000],
         [], [], [], []),
        (2023, 12, 31, 2, [1_000_000], [0], 1000, 1000, *z, [], [], [], []),
        (2023, 5, 31, 1, [0, 333], [1000, 0], 1, 1, [0], [3], [0], [1], [333], [], [], [], []),
        (2023, 5, 31, 1, [0], [1_000_000], 0, 1000, [0], [2], [0], [0], [999_999], [], [], [], []),
        (2023, 6, 29, 2, [1000], [1000], 1000, 1000, [1], [2], [0], [0], [2000], [], [], [], []),
        (2023, 4, 1, 61, [10_000, 0, 0], [0, 0, 0], 0, 0, *z, [31, 30, 29], [0, 0, 0], [1, 2, 1],
         [10, 20, 40]),
        (2100, 1, 1, 120, [1_000_000] * 6, [1_000_000] * 6, 1000, 1000,
         [d * 2 for d in range(60)], [2] * 60, [d % 6 for d in range(60)], [0] * 60, [1_000_000] * 60,
         [31, 1, 15, 28, 29, 30], [0, 1, 2, 3, 4, 5], [5, 4, 3, 2, 1, 0], [1_000_000] * 6),
    ]


def _toks(*formulas):
    """formula-sheet's lens, kinds, xs, ys and zs from formulas given as lists of
    (kind, x, y, z) tokens."""
    flat = [t for f in formulas for t in f]
    return ([len(f) for f in formulas], [t[0] for t in flat], [t[1] for t in flat],
            [t[2] for t in flat], [t[3] for t in flat])


def _sheet(formulas, edits=()):
    ecells = [c for c, _ in edits]
    return (*_toks(*formulas), ecells, *_toks(*(f for _, f in edits)))


def _n(x):
    return (0, x, 0, 0)


def _r(x):
    return (1, x, 0, 0)


def _o(x):
    return (2, x, 0, 0)


def _f(x, y, z):
    return (3, x, y, z)


def _sheet_cases():
    return [
        _sheet([[_n(5)]]),
        _sheet([[]]),
        _sheet([[_n(1), _o(1)], [_n(1), _n(2)], [_n(1), _n(2), _n(3), _o(7)]]),
        _sheet([[_r(0)], [_r(0), _n(1), _o(1)], [_f(4, 0, 0)], [_n(7)]]),
        _sheet([[_n(4)], [_r(1)], [_f(4, 0, 0)], [_f(4, 0, 1)], [_n(1), _n(2), _r(1), _o(7)]]),
        _sheet([[_n(1), _n(1), _r(9), _o(7)], [_r(9), _n(1), _n(2), _o(7)], [_n(0), _r(9), _n(2), _o(7)],
                [_n(0), _n(1), _r(4), _o(7)], [_r(4), _n(1)]]),
        _sheet([[_n(-7), _n(2), _o(4)], [_n(7), _n(-2), _o(4)], [_n(-7), _n(-2), _o(4)], [_n(5), _n(0), _o(4)],
                [_n(0), _n(5), _o(4)]]),
        _sheet([[_n(1_000_000), _n(1000), _o(3)], [_n(1_000_000), _n(1001), _o(3)], [_r(0), _o(8)],
                [_r(2), _n(-1), _o(1)], [_r(0), _r(0), _o(1), _n(-1), _o(3)], [_f(1, 0, 1)]]),
        _sheet([[_n(3)], [_n(-2)], [_n(1), _n(0), _o(4)], [_f(1, 0, 1)], [_f(2, 0, 1)], [_f(3, 0, 1)],
                [_f(4, 0, 2)], [_f(1, 0, 2)], [_f(2, 1, 0)], [_f(4, -1, 1)], [_f(3, 0, 30)]]),
        _sheet([[_r(-1)], [_r(2)], [_n(1), _r(2), _o(1)], [_n(2), _o(5), _r(3)]]),
        _sheet([[_n(2), _n(3), _o(5)], [_n(3), _n(2), _o(5)], [_n(3), _n(3), _o(6)], [_n(-1), _n(3), _o(6)],
                [_n(-5), _n(-4), _o(5)]]),
        _sheet([[_n(1)], [_r(0), _n(1), _o(1)], [_r(1), _r(0), _o(3)], [_f(1, 0, 2)]],
               [(0, [_n(2)]), (0, [_n(2)]), (0, [_r(3)]), (0, [_n(5)])]),
        _sheet([[_n(i)] for i in range(5)] + [[_r(i - 1), _r(i - 2), _o(1)] for i in range(5, 20)],
               [(0, [_n(1)]), (19, [_f(1, 0, 18)]), (3, [_r(19)]), (3, [_n(5)])]),
    ]


def _bj_cases():
    return [
        ([5, 5, 5, 5], [9, 0], [10, 1], 3),
        ([10, 10, 10], [100], [10], 1),
        ([1, 10, 10, 9, 10, 1], [100, 100], [10, 10], 1),
        ([10, 1, 13, 7, 10, 1], [100, 100], [10, 10], 1),
        ([1, 9, 12, 8, 3, 2, 10], [100], [5], 1),
        ([8, 6, 8, 10, 3, 10, 2, 5, 9, 10], [100], [10], 1),
        ([8, 6, 8, 10, 3, 10, 2, 5, 9, 10], [20], [10], 1),
        ([1, 6, 1, 10, 12, 9, 10], [100], [10], 1),
        ([1, 6, 1, 10, 12, 9, 10], [10], [10], 1),
        ([5, 6, 5, 10, 9, 3], [100], [10], 1),
        ([6, 10, 5, 9, 9], [100], [10], 1),
        ([6, 9, 5, 10, 10, 9], [100], [10], 1),
        ([1, 6, 6, 10, 9, 1, 9, 5], [100], [10], 1),
        ([1, 6, 7, 10, 9, 2, 10], [100], [10], 1),
        ([10, 7, 2, 10, 10, 5, 10, 6, 1, 10], [100], [10], 2),
        ([10, 6, 6, 10, 10, 1, 8, 10, 10, 6, 2, 1, 10, 7], [10, 100], [10, 10], 5),
        ([10, 1, 10, 9, 10, 10, 10, 1, 10, 9, 8], [100, 100], [10, 10], 9),
        ([10, 10, 9, 10, 9, 8, 1, 10, 7, 10, 2, 10], [100, 100], [10, 10], 2),
        ([10, 1, 10, 6], [100], [10], 1),
        ([10, 7, 2, 9, 10], [100], [10], 1),
    ]

# --- descriptions ---------------------------------------------------------------

_CPU = (
    "Run a program on a small processor and report its final state. Instruction i is "
    "ops[i] with fields a = fa[i], b = fb[i] and c = fc[i] (the four sequences have the "
    "same length n). The processor has 8 registers r0 to r7, starting as regs (length 8); "
    "a memory of 64 words, addresses 0 to 63, starting as memory (length 64); three flags "
    "Z, N and V, all starting false; a data stack holding at most 16 values and a call "
    "stack holding at most 8 return addresses, both starting empty; an input list, inputs, "
    "read from the front; and an output list, starting empty. Every register and memory "
    "word holds a 32-bit value, -2,147,483,648 to 2,147,483,647. To wrap a whole number x "
    "is to take the value in that range that differs from x by a multiple of 4,294,967,296. "
    "The program counter pc starts at 0. Repeat: if 300 instructions have been executed, "
    "stop with status 1; otherwise, if pc is outside 0 to n - 1, stop with status 2; "
    "otherwise execute instruction pc, which counts as executed and then sets pc to pc + 1 "
    "unless it says otherwise, except that an instruction that stops with a fault (status "
    "3 to 7) does not count as executed and leaves pc unchanged. Opcodes, where rA, rB "
    "and rC are the registers numbered a, b and c: 0 halt: stop with status 0 (it counts "
    "as executed and pc stays on it). 1 load: rA = b. 2 move: rA = rB. 3 add: rA = rB + "
    "rC. 4 subtract: rA = rB - rC. 5 multiply: rA = rB times rC. 6 divide: rA = rB divided "
    "by rC, the quotient rounded toward zero (-7 and 2 give -3). 7 remainder: rA = rB - q "
    "times rC, where q is that quotient. 6 and 7 stop with status 3 when rC is 0. 8 "
    "negate: rA = -rB. 9 shift left: rA = rB times 2 to the power c. 10 shift right: rA = "
    "rB divided by 2 to the power c, rounded down (-7 and 1 give -4). 11 compare: works out "
    "rB - rC but stores it nowhere. For opcodes 3 to 5 and 8 to 11 the exact result t is "
    "worked out first, without wrapping; the stored value is t wrapped, and the flags are "
    "set from it: Z is whether the wrapped value is 0, N whether it is below 0, and V "
    "whether it differs from t. Opcodes 6 and 7 store and set the flags the same way. No "
    "other opcode changes the flags. 12 load word: rA = memory[rB + c]. 13 store word: "
    "memory[rB + c] = rA. 12 and 13 stop with status 6 when rB + c is outside 0 to 63. 14 "
    "jump: pc = b. 15 jump if zero: pc = b when Z is true. 16 jump if not zero: pc = b when "
    "Z is false. 17 jump if less: pc = b when N differs from V. 18 jump if not less: pc = b "
    "when N equals V. (Opcodes 15 to 18 that do not jump go on to pc + 1.) 19 push: put rA "
    "on top of the data stack; status 4 when it already holds 16 values. 20 pop: take the "
    "top of the data stack into rA; status 5 when it is empty. 21 call: put pc + 1 on top "
    "of the call stack and set pc = b; status 4 when it already holds 8 addresses. 22 "
    "return: take the top of the call stack into pc; status 5 when it is empty. 23 input: "
    "take the next unread value of inputs into rA; status 7 when every value has been "
    "read. 24 output: add rA to the end of the output list. Return the output list, the "
    "status, the number of instructions executed, the final pc, the final registers r0 to "
    "r7, the final memory, and the flags Z, N and V in that order. n is 1 to 64; every op "
    "is 0 to 24; a field naming a register (a for opcodes 1, 2, 3 to 10, 12, 13, 19, 20, "
    "23 and 24; b for 2 to 13; c for 3 to 7 and 11) is 0 to 7; b of "
    "a load is a 32-bit value; c of a shift is 0 to 31; c of 12 and 13 is -64 to 64; b of "
    "a jump or call is -2 to 66; every other field is 0 and has no effect. Every value of "
    "regs, memory and inputs is a 32-bit value, and inputs has at most 40 values."
)

_STACKER = (
    "Play a falling-blocks game on a well width columns wide (numbered 0 to width - 1 from "
    "the left) and height rows high (numbered 0 to height - 1 from the bottom), starting "
    "empty. A piece has a kind 0 to 6, a rotation 0 to 3 and a position (x, y); it covers "
    "the four squares (x + dx, y + dy) for the four (dx, dy) of its kind and rotation in "
    "this table: kind 0: rotation 0 (0,2) (1,2) (2,2) (3,2); 1 (2,0) (2,1) (2,2) (2,3); 2 "
    "(0,1) (1,1) (2,1) (3,1); 3 (1,0) (1,1) (1,2) (1,3). kind 1: every rotation (1,1) (2,1) "
    "(1,2) (2,2). kind 2: 0 (0,2) (1,2) (2,2) (1,3); 1 (1,1) (1,2) (1,3) (2,2); 2 (0,2) "
    "(1,2) (2,2) (1,1); 3 (1,1) (1,2) (1,3) (0,2). kind 3: 0 (0,2) (1,2) (1,3) (2,3); 1 "
    "(1,3) (1,2) (2,2) (2,1); 2 (0,1) (1,1) (1,2) (2,2); 3 (0,3) (0,2) (1,2) (1,1). kind 4: "
    "0 (0,3) (1,3) (1,2) (2,2); 1 (2,3) (2,2) (1,2) (1,1); 2 (0,2) (1,2) (1,1) (2,1); 3 "
    "(1,3) (1,2) (0,2) (0,1). kind 5: 0 (0,2) (1,2) (2,2) (2,3); 1 (1,3) (1,2) (1,1) (2,1); "
    "2 (0,1) (0,2) (1,2) (2,2); 3 (0,3) (1,3) (1,2) (1,1). kind 6: 0 (0,3) (0,2) (1,2) "
    "(2,2); 1 (1,1) (1,2) (1,3) (2,3); 2 (0,2) (1,2) (2,2) (2,1); 3 (0,1) (1,1) (1,2) "
    "(1,3). A piece fits at a rotation and position when all four of its squares are "
    "inside the well and not filled. The pieces to play are queue, in order, and the "
    "player's commands are moves, in order. A piece spawns at rotation 0 and position "
    "((width - 4) divided by 2 rounded down, height - 4). There is a current piece, none at "
    "first, and a held kind, none at first. Repeat: if there is no current piece, take the "
    "next kind from queue and spawn it as the current piece, which may be held once (see "
    "6); stop with status 0 if queue has no kind left, and stop with status 2 if the new "
    "piece does not fit. Then stop with status 1 if moves has no command left; otherwise "
    "take the next command and carry it out. Commands: 1 and 2 move the piece one column "
    "left (x - 1) and right (x + 1), if it fits there, and otherwise do nothing. 5 moves it "
    "down one row (y - 1), if it fits there, and otherwise does nothing. 3 turns it to "
    "rotation (r + 1) mod 4 and 4 to rotation (r + 3) mod 4, where r is its rotation: try "
    "the offsets (0,0), (-1,0), (1,0), (0,1), (-2,0), (2,0) in that order, and the first "
    "offset (ox, oy) at which the turned piece fits at (x + ox, y + oy) is taken, with the "
    "new rotation; if none fits, nothing changes. 6 is hold: if the current piece may not "
    "be held, it does nothing. Otherwise, if no kind is held, the current piece's kind "
    "becomes held and the next kind from queue is spawned as the current piece (stop with "
    "status 0 if queue has no kind left); if a kind is held, the two swap: the current "
    "piece's kind becomes held and the old held kind is spawned. Either way stop with "
    "status 2 if the spawned piece does not fit, and a piece spawned by a hold may not be "
    "held. 0 is drop: move the piece down one row at a time while it fits there, then lock "
    "it: its four squares become filled and there is no current piece. Then every full row "
    "(one with all width squares filled) is removed, the rows above it move down to close "
    "the gap, and empty rows are added at the top. A lock that removes k rows (k = 1 to 4) "
    "scores (base + 50 times combo) times level, where base is 100, 300, 500 or 800 for k = "
    "1, 2, 3, 4, except that it is 1200 when k is 4 and the last earlier lock that removed "
    "any rows removed 4; combo is how many locks in a row, straight before this one, "
    "removed rows (0 when the lock before this one removed none, or there was none); and "
    "level is 1 plus (rows removed before this lock, divided by 10 rounded down). Return "
    "each column's height (1 plus the highest filled row in that column, or 0 if it has "
    "none), the score, the total rows removed, the number of locks, the status, and the "
    "held kind (-1 if none). width is 4 to 10, height is 4 to 10, queue has at most 30 "
    "kinds, each 0 to 6, and moves has at most 100 commands, each 0 to 6."
)

_BANK = (
    "Simulate a bank day by day. There are n accounts, numbered 0 to n - 1, with balances "
    "starting as balances and overdraft limits limits (both of length n). The first day "
    "simulated is year-month-day in the Gregorian calendar (a year is a leap year when it "
    "divides by 4, except that years dividing by 100 are not unless they divide by 400), "
    "and days days are simulated, day 0 being the first. One-off transaction k is on day "
    "number tx_day[k], is kind tx_kind[k] with account a = tx_acct[k], second account b = "
    "tx_other[k] and amount tx_amount[k] (the five sequences have the same length). Kinds: "
    "1 deposits the amount into a; 2 withdraws it from a; 3 transfers it from a to b. "
    "Standing order k pays so_amount[k] from account so_from[k] to account so_to[k] on day "
    "of the month so_dom[k] (the four sequences have the same length); in a month with "
    "fewer than so_dom[k] days it pays on the month's last day instead. A withdrawal or "
    "transfer, one-off or standing, is rejected, and changes nothing, when it would leave "
    "the paying account's balance below minus its limit, or when it is a transfer from an "
    "account to itself; otherwise it is carried out. Deposits are never rejected. A "
    "standing order is cancelled, and never pays again, once two of its payments in a row "
    "have been rejected (a payment carried out resets the count). Each day, in this order: "
    "first the day's one-off transactions, in the order of the sequences; then the "
    "standing orders due that day and not cancelled, in the order of the sequences; then "
    "interest accrues: each account with a balance above 0 adds balance times credit_ppm "
    "to its accrued sum, and each with a balance below 0 adds balance times debit_ppm "
    "(a negative amount) and is marked as having been overdrawn this month. Then, if the "
    "day is the last of its month: each account's accrued sum s is posted, by adding |s| "
    "divided by 1,000,000 rounded down to its balance when s is 0 or more and taking it "
    "away when s is below 0, and the sum goes back to 0; then each account marked as "
    "overdrawn this month is charged a fee of 1,000 and the mark is cleared. Nothing is "
    "posted for a month that has not ended by the last day simulated. Return the final "
    "balances; the number of rejected withdrawals and transfers, one-off and standing; "
    "whether each standing order was cancelled; the total interest added to balances; the "
    "total interest taken away; and the total fees charged. n is 1 to 6; each starting "
    "balance is 0 to 1,000,000 and each limit 0 to 1,000,000; year is 1900 to 2100, month "
    "1 to 12 and day a day of that month; days is 1 to 120; credit_ppm and debit_ppm are 0 "
    "to 1,000; there are at most 60 one-off transactions, each with tx_day 0 to days - 1, "
    "kind 1 to 3, accounts 0 to n - 1 (tx_other[k] is 0 and has no effect for kinds 1 and "
    "2) and amount 1 to 1,000,000; and at most 6 standing orders, each with so_dom 1 to "
    "31, accounts 0 to n - 1 and amount 1 to 1,000,000."
)

_SHEET = (
    "Evaluate a sheet of n formulas in reverse Polish notation, then apply edits. Formula "
    "i has lens[i] tokens; the tokens of all the formulas are listed one after another, "
    "token t being kinds[t] with fields x = xs[t], y = ys[t] and z = zs[t] (kinds, xs, ys "
    "and zs have the same length, the sum of lens). A formula is evaluated with a stack of "
    "values, each of which is a whole number or an error, starting empty, taking its "
    "tokens in order. Token kinds: 0 pushes the number x. 1 pushes the value of cell x, "
    "or an error if x is outside 0 to n - 1. 2 is an operator x: it takes values off the "
    "top of the stack, the last pushed being the rightmost argument, and pushes its "
    "result; x is 1 for a + b, 2 for a - b, 3 for a times b, 4 for a divided by b, the "
    "quotient rounded toward zero (-7 and 2 give -3; an error when b is 0), 5 for a < b "
    "(1 if true, else 0), 6 for a = b (1 if equal, else 0), each of these taking two "
    "arguments a and b; 7 is if, taking three arguments c, a and b, giving a if c is not "
    "0 and b if c is 0; 8 is negate, taking one argument a and giving -a. 3 pushes a "
    "function x of the cells y to z, both included: 1 their sum, 2 their smallest value, 3 "
    "their largest value, 4 how many of them have no error; it pushes an error instead "
    "when y or z is outside 0 to n - 1 or y is greater than z. An operator or function 1 to "
    "3 gives an error when any of its arguments or cells is an error, except that if gives "
    "an error only when c is an error or the argument it gives is an error, and function "
    "4 never gives an error. Any result of an operator or function whose size is more than "
    "1,000,000,000 is an error instead. The formula's value is an error if an operator "
    "finds fewer arguments on the stack than it takes, or if, after the last token, the "
    "stack does not hold exactly one value; otherwise it is that value. A cell's formula "
    "refers to every cell x of its kind 1 tokens with x in 0 to n - 1, and to every cell y "
    "to z of its kind 3 tokens with 0 <= y <= z <= n - 1, whether or not the formula is "
    "well formed and whichever argument an if gives. A cell is in a cycle when following "
    "references from it, one or more steps, can lead back to it; a cell that is in a "
    "cycle, or from which following references can reach a cell in a cycle, is an error, "
    "and every other cell's value is its formula's value. Edit e replaces the formula of "
    "cell edit_cells[e] with a formula of edit_lens[e] tokens, listed one after another in "
    "e_kinds, e_xs, e_ys and e_zs in the same way; after each edit the whole sheet is "
    "evaluated again. Return each cell's final value (0 for an error), whether each cell's "
    "final value is an error, and for each edit how many cells' values changed with it, "
    "where an error and a number are always different. n is 1 to 20; each formula and each "
    "edit has 0 to 8 tokens, and there are at most 4 edits, each for a cell 0 to n - 1; "
    "a kind 0 token's x is -1,000,000 to 1,000,000; a kind 1 token's x, and a kind 3 "
    "token's y and z, are -5 to 35; a kind 2 token's x is 1 to 8 and a kind 3 token's x is "
    "1 to 4; every other field is 0 and has no effect."
)

_BLACKJACK = (
    "Play rounds of blackjack by fixed rules, dealing from shoe, which lists the cards in "
    "the order they are dealt. A card is a rank 1 to 13: rank 1 is an ace, ranks 2 to 10 "
    "count their rank and ranks 11 to 13 count 10, as does a ten. A hand's total is the "
    "sum of its cards with each ace counting 1, plus 10 if the hand has an ace and that "
    "keeps the total at 21 or less, in which case the hand is soft (otherwise it is hard). "
    "A natural is a hand of two cards totalling 21, dealt as a player's or the dealer's "
    "first two cards. Player i has bankroll bankrolls[i] and always bets bets[i] (the two "
    "sequences have the same length). Play up to rounds rounds. At the start of a round, "
    "the players taking part are those whose bankroll is at least their bet; if there are "
    "none, play stops. Deal one card to each taking part, in order of player number, then "
    "one to the dealer (the up card), then a second card to each, in the same order, then "
    "a second card to the dealer. If the up card is an ace or counts 10 and the dealer has "
    "a natural, the round ends at once: each player with a natural keeps their bet and "
    "every other player loses their bet. Otherwise each player with a natural wins 3 "
    "times their bet divided by 2, rounded down, and plays no further, and the others play "
    "their hands in order of player number. A player whose two cards have the same rank, "
    "both aces or both eights, splits them if their bankroll is at least twice their bet: "
    "each card becomes a hand of its own, staked at the bet; the first hand then gets "
    "one more card, then the second does, and only then are they played: split aces "
    "stand, and split eights are each played in turn, first hand first, by the rules below. Split hands are never split again and are never naturals. A hand is "
    "played as follows. With two cards, a hard total of 10 or 11 and an up card of rank "
    "2 to 9, the player doubles if their bankroll is at least the total staked on their "
    "hands so far this round plus another bet: the hand's stake doubles, it gets exactly "
    "one more card, and it stands. Otherwise the player draws cards one at a time while "
    "the total is at most 21 and they want another: with a soft total they want one when "
    "it is at most 17; with a hard total, when it is at most 11, or when it is 12 to 16 "
    "and the up card is an ace or of rank 7 or more. Once all players have played, if some "
    "hand of theirs (naturals not included) has a total of 21 or less, the dealer draws "
    "cards while their total is below 17 (they stand on every 17, soft or hard); "
    "otherwise the dealer draws nothing. Then each hand (naturals not included) is "
    "settled: a total above 21 loses its stake; otherwise it wins its stake if the dealer "
    "is above 21 or below the hand's total, loses it if the dealer is above the hand's "
    "total, and keeps it if they are equal. Every win and loss is added to or taken from "
    "the player's bankroll when the round ends. If a card is needed when shoe has none "
    "left, play stops and the round in progress counts for nothing: no bankroll changes "
    "and none of its counts below. Return the final bankrolls, the number of rounds "
    "completed, the number of completed rounds in which the dealer drew to a total above "
    "21, and the number of naturals dealt to players in completed rounds. There are 1 to "
    "5 players; each bankroll is 0 to 100,000 and each bet 1 to 1,000; rounds is 1 to 20; "
    "shoe has at most 120 cards, each 1 to 13."
)

# --- examples -------------------------------------------------------------------

_CPU_EX = ([23, 1, 1, 1, 11, 15, 5, 13, 4, 14, 24, 19, 20, 0],
          [0, 1, 2, 3, 0, 0, 1, 1, 0, 0, 1, 1, 4, 0],
          [0, 1, 1, 0, 0, 10, 1, 3, 0, 4, 0, 0, 0, 0],
          [0, 0, 0, 0, 3, 0, 0, 5, 2, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 9], [0] * 64, [5, 7])
_STACKER_EX = (6, 8, [1, 1, 1, 0, 2, 5], [1, 1, 0, 0, 2, 2, 0, 6, 3, 2, 2, 0, 5, 0, 1])
_BANK_EX = (2024, 1, 30, 35, [1000000, 500], [0, 2000], 1000, 500,
           [0, 1, 3], [2, 3, 1], [1, 1, 1], [0, 1, 0], [1000, 400, 100],
           [31, 15], [0, 1], [1, 0], [2000, 3000])
_SHEET_EX = ([1, 3, 3, 4], [0, 1, 0, 2, 3, 3, 2, 1, 1, 0, 2],
            [6, 0, 7, 3, 1, 4, 1, 2, 1, 0, 7],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
            [0, 2], [1, 2], [0, 1, 2], [-3, 3, 8], [0, 0, 0], [0, 0, 0])
_BJ_EX = ([10, 9, 10, 7, 1, 8, 6, 8, 10, 2, 3, 9, 5, 10, 1, 10, 10, 10, 5, 6], [100, 30], [10, 10], 4)


# The last hidden test of each task is the costliest, for its Firth reference, of 40
# inputs at the largest sizes the description allows (README, "The third calibration pool").
CALIBRATION3: tuple[Task, ...] = (
    _t("mini-cpu", _CPU,
       [("ops", SI), ("fa", SI), ("fb", SI), ("fc", SI), ("regs", SI), ("memory", SI), ("inputs", SI)],
       [("output", SI), ("status", I), ("executed", I), ("pc", I), ("registers", SI),
        ("final_memory", SI), ("flags", SB)], _cpu, _CPU_EX,
       [*_cpu_cases(), *(_random_cpu(s) for s in (29, 57, 127, 279)), _random_cpu(314, 64)],
       ["seq", "loop", "rules", "state", "divmod", "bool-seq", "heavy"]),
    _t("stacker", _STACKER,
       [("width", I), ("height", I), ("queue", SI), ("moves", SI)],
       [("heights", SI), ("score", I), ("rows", I), ("locks", I), ("status", I), ("held", I)],
       _stacker, _STACKER_EX,
       [*_stacker_cases(), _random_stacker(1), _random_stacker(2),
        _greedy_stacker(3), _greedy_stacker(4, 7, 10), _greedy_stacker(5, 4, 10),
        _greedy_stacker(6, 10, 10, 30), _greedy_stacker(4, 8, 10, 30, noise=0.1)],
       ["seq", "nested-loop", "rules", "state", "bool-seq", "heavy"]),
    _t("bank-days", _BANK,
       [("year", I), ("month", I), ("day", I), ("days", I), ("balances", SI), ("limits", SI),
        ("credit_ppm", I), ("debit_ppm", I), ("tx_day", SI), ("tx_kind", SI), ("tx_acct", SI),
        ("tx_other", SI), ("tx_amount", SI), ("so_dom", SI), ("so_from", SI), ("so_to", SI),
        ("so_amount", SI)],
       [("final", SI), ("rejected", I), ("cancelled", SB), ("interest_added", I),
        ("interest_taken", I), ("fees", I)], _bank_days, _BANK_EX,
       [*_bank_cases(), *(_random_bank(s) for s in range(5)), _largest_bank(19)],
       ["seq", "loop", "rules", "state", "divmod", "bool-seq", "heavy"]),
    _t("formula-sheet", _SHEET,
       [("lens", SI), ("kinds", SI), ("xs", SI), ("ys", SI), ("zs", SI), ("edit_cells", SI),
        ("edit_lens", SI), ("e_kinds", SI), ("e_xs", SI), ("e_ys", SI), ("e_zs", SI)],
       [("values", SI), ("errors", SB), ("changed", SI)], _formula_sheet, _SHEET_EX,
       [*_sheet_cases(), *(_random_sheet(s) for s in range(5)), _random_sheet(5, 20, 4), _random_sheet(22, 20, 4)],
       ["seq", "nested-loop", "rules", "graph", "divmod", "bool-seq", "heavy"]),
    _t("blackjack", _BLACKJACK,
       [("shoe", SI), ("bankrolls", SI), ("bets", SI), ("rounds", I)],
       [("final", SI), ("rounds_played", I), ("dealer_busts", I), ("naturals", I)],
       _blackjack_table, _BJ_EX,
       [*_bj_cases(), *(_random_blackjack(s) for s in range(4)), _largest_blackjack(39)],
       ["seq", "loop", "rules", "state", "heavy"]),
)
