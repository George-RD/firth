"""Candidate tasks for the next scored set of the harder S7 tier.

The 2026-10-11 scored set is not reused: the checker's fix hints that followed
that run were built and tested on its programs, so its tasks would test the
hints on their own cases. These nine tasks are new, and none has been sent to a
model. Which six of them become the next scored set is decided by a rule fixed
before any of them is run (`next-run/calibration.md`); the others are kept
here and are never scored.

Six are whole simulations or interpreters with interacting rules, the genre
of the earlier pools: an order book with time in force and self-trade
prevention (`order-match`), Go with captures, suicide and ko (`go-game`), a
stack machine with exception handlers (`stack-vm`), tennis scoring with
tiebreaks and serve order (`tennis`), a timetable with change times
(`timetable`) and an expression language with assignment (`expr-eval`).
Three are hard in another way: an algorithm, since direct simulation or
enumeration is too slow at the stated sizes (`josephus`, `perm-rank`), and
edge cases in a binary format (`wire-decode`).

Every description states every bound an answer depends on, so every result
fits in a 64-bit `Int`. Each `ref` is the task's meaning, written in plain
Python independently of any Firth code; hidden inputs are scored against it
and never shown to the author.
"""
from __future__ import annotations

import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from task import Task, _t  # noqa: E402

I, B, SI, SB = "Int", "Bool", "Seq Int", "Seq Bool"


# --- order-book ------------------------------------------------------------------

def _order_book(kind, side, price, qty, trader, tif):
    book = []  # resting orders: [number, side, price, remaining, trader]
    trades = volume = notional = self_cancelled = cancelled = rejected = killed = 0
    for i, k in enumerate(kind):
        if k == 2:
            hit = [r for r in book if r[0] == price[i]]
            if hit:
                book.remove(hit[0])
                cancelled += 1
            else:
                rejected += 1
            continue
        s, left, who, p = side[i], qty[i], trader[i], price[i]

        def crosses(r):
            if r[1] == s:
                return False
            if k == 1:
                return True
            return r[2] <= p if s == 0 else r[2] >= p

        def rank(r):
            return (r[2], r[0]) if s == 0 else (-r[2], r[0])

        if tif[i] == 2 and sum(r[3] for r in book if crosses(r) and r[4] != who) < left:
            killed += 1
            continue
        while left > 0:
            ready = [r for r in book if crosses(r)]
            if not ready:
                break
            best = min(ready, key=rank)
            if best[4] == who:
                book.remove(best)
                self_cancelled += best[3]
                continue
            q = min(left, best[3])
            trades += 1
            volume += q
            notional += q * best[2]
            best[3] -= q
            left -= q
            if best[3] == 0:
                book.remove(best)
        if left > 0 and k == 0 and tif[i] == 0:
            book.append([i, s, p, left, who])
    bids = sorted((r for r in book if r[1] == 0), key=lambda r: (-r[2], r[0]))
    asks = sorted((r for r in book if r[1] == 1), key=lambda r: (r[2], r[0]))
    rest = bids + asks
    return (trades, volume, notional, self_cancelled, cancelled, rejected, killed,
            [r[0] for r in rest], [r[3] for r in rest])


# --- go-game ---------------------------------------------------------------------

def _go_game(size, moves):
    n = size
    board = [0] * (n * n)

    def around(i):
        r, c = divmod(i, n)
        if r > 0:
            yield i - n
        if c < n - 1:
            yield i + 1
        if r < n - 1:
            yield i + n
        if c > 0:
            yield i - 1

    def group(b, i):
        seen, todo, libs = {i}, [i], set()
        while todo:
            j = todo.pop()
            for k in around(j):
                if b[k] == 0:
                    libs.add(k)
                elif b[k] == b[i] and k not in seen:
                    seen.add(k)
                    todo.append(k)
        return seen, libs

    player = 1
    before = [None, None, None]   # before[c]: the board just before c's latest turn
    took = [0, 0, 0]
    illegal = read = 0
    passes = 0
    for m in moves:
        if passes == 2:
            break
        read += 1
        if m == -1:
            before[player] = board[:]
            passes += 1
            player = 3 - player
            continue
        if board[m] != 0:
            illegal += 1
            continue
        b = board[:]
        b[m] = player
        gone = 0
        for k in around(m):
            if b[k] == 3 - player:
                stones, libs = group(b, k)
                if not libs:
                    for s in stones:
                        b[s] = 0
                    gone += len(stones)
        if not group(b, m)[1]:
            illegal += 1
            continue
        if b == before[3 - player]:
            illegal += 1
            continue
        before[player] = board
        board = b
        took[player] += gone
        passes = 0
        player = 3 - player
    area = [0, 0, 0]
    seen = set()
    for i in range(n * n):
        if board[i]:
            area[board[i]] += 1
        elif i not in seen:
            region, todo, edge = {i}, [i], set()
            while todo:
                j = todo.pop()
                for k in around(j):
                    if board[k] == 0:
                        if k not in region:
                            region.add(k)
                            todo.append(k)
                    else:
                        edge.add(board[k])
            seen |= region
            if len(edge) == 1:
                area[edge.pop()] += len(region)
    return board, took[1], took[2], illegal, read, area[1] - area[2]


# --- stack-vm --------------------------------------------------------------------

_LIMIT = 10 ** 9


def _trunc_div(a, b):
    q = abs(a) // abs(b)
    return q if (a < 0) == (b < 0) else -q


def _stack_vm(ops, args, limit):
    stack, calls, frames = [], [], []
    pc = steps = caught = 0
    deepest = 0
    status = code = 0
    while 0 <= pc < len(ops):
        if steps == limit:
            status = 2
            break
        steps += 1
        op, a = ops[pc], args[pc]
        nxt = pc + 1
        thrown = None
        need = {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 1, 7: 2, 8: 1, 10: 1, 15: 1}.get(op, 0)
        if len(stack) < need:
            thrown = 2
        elif op == 0 or op == 6:
            if len(stack) == 32:
                thrown = 4
            else:
                stack.append(a if op == 0 else stack[-1])
        elif 1 <= op <= 5:
            x, y = stack[-2], stack[-1]
            if op in (4, 5) and y == 0:
                thrown = 1
            else:
                r = (x + y if op == 1 else x - y if op == 2 else x * y if op == 3
                     else _trunc_div(x, y) if op == 4 else x - y * _trunc_div(x, y))
                if abs(r) > _LIMIT:
                    thrown = 6
                else:
                    stack[-2:] = [r]
        elif op == 7:
            stack[-2], stack[-1] = stack[-1], stack[-2]
        elif op == 8:
            stack.pop()
        elif op == 9:
            nxt = a
        elif op == 10:
            if stack.pop() == 0:
                nxt = a
        elif op == 11:
            if len(calls) == 16:
                thrown = 4
            else:
                calls.append(pc + 1)
                nxt = a
        elif op == 12:
            if not calls:
                break
            nxt = calls.pop()
        elif op == 13:
            if len(frames) == 8:
                thrown = 4
            else:
                frames.append((a, len(stack), len(calls)))
        elif op == 14:
            if not frames:
                thrown = 3
            else:
                frames.pop()
        elif op == 15:
            thrown = stack.pop()
        elif op == 16:
            break
        if thrown is not None:
            if not frames:
                status, code = 1, thrown
                deepest = max(deepest, len(stack))
                break
            h, depth, ncalls = frames.pop()
            del stack[depth:]
            del calls[ncalls:]
            stack.append(thrown)
            caught += 1
            nxt = h
        deepest = max(deepest, len(stack))
        pc = nxt
    return stack, status, code, steps, caught, deepest


# --- josephus --------------------------------------------------------------------

def _removed(n, k, m):
    """The m-th person removed from a circle of n, counting k (m = n: the survivor)."""
    p = (k - 1) % (n - m + 1)
    for size in range(n - m + 2, n + 1):
        p = (p + k) % size
    return p


def _survivor(n, k):
    if k == 1:
        return n - 1
    sizes = []
    while n >= k:
        sizes.append(n)
        n -= n // k
    r = _removed(n, k, n)
    for size in reversed(sizes):
        r -= size % k
        r = r + size if r < 0 else r + r // (k - 1)
    return r


def _josephus(n, k, m):
    return [_survivor(a, b) for a, b in zip(n, k)], [_removed(a, b, c) for a, b, c in zip(n, k, m)]


# --- perm-rank -------------------------------------------------------------------

def _arrangements(counts):
    """The number of distinct orders of a multiset with these counts per value."""
    total, placed = 1, 0
    for c in counts:
        for i in range(1, c + 1):
            placed += 1
            total = total * placed // i
    return total


def _perm_rank(items, perm, k):
    counts = [items.count(v) for v in range(10)]
    total = _arrangements(counts)

    def rank_of(p):
        left = counts[:]
        r = 0
        for x in p:
            for v in range(x):
                if left[v]:
                    left[v] -= 1
                    r += _arrangements(left)
                    left[v] += 1
            left[x] -= 1
        return r

    def unrank(r):
        left = counts[:]
        out = []
        for _ in range(len(items)):
            for v in range(10):
                if left[v]:
                    left[v] -= 1
                    here = _arrangements(left)
                    if r < here:
                        out.append(v)
                        break
                    r -= here
                    left[v] += 1
        return out

    rank = rank_of(perm) if sorted(perm) == sorted(items) else -1
    kth = unrank(k) if k < total else []
    nxt = unrank(rank + 1) if rank != -1 and rank + 1 < total else []
    return total, rank, kth, nxt


# --- wire-decode -----------------------------------------------------------------

class _Bad(Exception):
    def __init__(self, code):
        self.code = code


def _wire_decode(data):
    pos = 0
    fields, wires, values = [], [], []

    def varint():
        nonlocal pos
        v = 0
        for i in range(8):
            if pos >= len(data):
                raise _Bad(1)
            b = data[pos]
            pos += 1
            v += (b % 128) << (7 * i)
            if b < 128:
                if i > 0 and b == 0:
                    raise _Bad(2)
                return v
        raise _Bad(3)

    while pos < len(data):
        start = pos
        try:
            tag = varint()
            field, wire = tag // 8, tag % 8
            if field == 0:
                raise _Bad(4)
            if wire == 0:
                v = varint()
            elif wire == 1:
                u = varint()
                v = u // 2 if u % 2 == 0 else -(u // 2) - 1
            elif wire == 2:
                v = varint()
                if pos + v > len(data):
                    raise _Bad(1)
                pos += v
            elif wire == 5:
                if pos + 4 > len(data):
                    raise _Bad(1)
                v = sum(data[pos + j] << (8 * j) for j in range(4))
                pos += 4
            else:
                raise _Bad(5)
        except _Bad as bad:
            return fields, wires, values, bad.code, start
        fields.append(field)
        wires.append(wire)
        values.append(v)
    return fields, wires, values, 0, -1


# --- tennis ----------------------------------------------------------------------

def _tennis(points, best_of, final_set, no_ad, server):
    need = best_of // 2 + 1
    sets = [[0, 0]]
    won = [0, 0]
    breaks = [0, 0]
    pts = [0, 0]
    tiebreak = False
    tb_first = 0
    winner = -1
    read = 0

    def deciding():
        return len(sets) == best_of

    def start_tiebreak():
        nonlocal tiebreak, tb_first
        tiebreak = True
        tb_first = server

    if deciding() and final_set == 2:
        start_tiebreak()
    for w in points:
        if winner != -1:
            break
        read += 1
        pts[w] += 1
        g = sets[-1]
        set_over = False
        if tiebreak:
            target = 10 if deciding() and final_set == 2 else 7
            if target == 10:
                g[0], g[1] = pts
            if pts[w] >= target and pts[w] - pts[1 - w] >= 2:
                if target != 10:
                    g[w] += 1
                tiebreak = False
                server = 1 - tb_first
                pts = [0, 0]
                set_over = True
        else:
            if (pts[w] >= 4 and pts[w] - pts[1 - w] >= 2) or (no_ad and pts == ([4, 3] if w == 0 else [3, 4])):
                g[w] += 1
                if w != server:
                    breaks[w] += 1
                server = 1 - server
                pts = [0, 0]
                if g[w] >= 6 and g[w] - g[1 - w] >= 2:
                    set_over = True
                elif g == [6, 6] and not (deciding() and final_set == 1):
                    start_tiebreak()
        if set_over:
            won[w] += 1
            if won[w] == need:
                winner = w
            else:
                sets.append([0, 0])
                if deciding() and final_set == 2:
                    start_tiebreak()
    if winner != -1:
        now, nxt = [0, 0], -1
    else:
        now = pts
        if tiebreak:
            k = sum(pts)
            nxt = tb_first if k == 0 or (k + 1) // 2 % 2 == 0 else 1 - tb_first
        else:
            nxt = server
    return [v for g in sets for v in g], winner, read, now, nxt, breaks


# --- timetable -------------------------------------------------------------------

def _timetable(stations, change, origin, start, c_from, c_to, c_dep, c_arr, c_train):
    inf = float("inf")
    best = [inf] * stations
    best[origin] = start
    fewest = [-1] * stations
    fewest[origin] = 0
    trains = sorted(set(c_train))
    legs = {t: sorted((i for i in range(len(c_train)) if c_train[i] == t), key=lambda i: c_dep[i])
            for t in trains}
    reach = best[:]          # earliest arrival with at most k - 1 trains
    for k in range(1, len(trains) + 1):
        nxt = reach[:]
        for t in trains:
            aboard = False
            for i in legs[t]:
                s = c_from[i]
                ready = start if s == origin else reach[s] + change
                if not aboard and ready <= c_dep[i]:
                    aboard = True
                if aboard and c_arr[i] < nxt[c_to[i]]:
                    nxt[c_to[i]] = c_arr[i]
        for s in range(stations):
            if nxt[s] < best[s]:
                best[s] = nxt[s]
                fewest[s] = k
        reach = nxt
    return [-1 if v == inf else v for v in best], fewest


# --- expr-eval -------------------------------------------------------------------

_BIG = 10 ** 12


class _Fail(Exception):
    def __init__(self, code):
        self.code = code


def _expr_eval(kinds, vals):
    env = [None] * 8
    values, status = [], []
    statements, cur = [], []
    for k, v in zip(kinds, vals):
        if k == 2 and v == 10:
            statements.append(cur)
            cur = []
        else:
            cur.append((k, v))
    statements.append(cur)

    def check(n):
        if abs(n) > _BIG:
            raise _Fail(5)
        return n

    for toks in statements:
        if not toks:
            continue
        pos = 0

        def peek(off=0):
            return toks[pos + off] if pos + off < len(toks) else None

        def is_op(t, v):
            return t is not None and t[0] == 2 and t[1] == v

        # Parse to a tree first: ("num", n) ("var", i) ("set", i, e) ("neg", e) (op, l, r)
        def assign():
            nonlocal pos
            t = peek()
            if t is not None and t[0] == 1 and is_op(peek(1), 9):
                pos += 2
                return ("set", t[1], assign())
            return additive()

        def additive():
            nonlocal pos
            node = term()
            while is_op(peek(), 1) or is_op(peek(), 2):
                op = peek()[1]
                pos += 1
                node = (op, node, term())
            return node

        def term():
            nonlocal pos
            node = unary()
            while any(is_op(peek(), o) for o in (3, 4, 5)):
                op = peek()[1]
                pos += 1
                node = (op, node, unary())
            return node

        def unary():
            nonlocal pos
            if is_op(peek(), 2):
                pos += 1
                return ("neg", unary())
            return power()

        def power():
            nonlocal pos
            node = atom()
            if is_op(peek(), 6):
                pos += 1
                return (6, node, unary())
            return node

        def atom():
            nonlocal pos
            t = peek()
            if t is None:
                raise _Fail(1)
            if t[0] == 0:
                pos += 1
                return ("num", t[1])
            if t[0] == 1:
                pos += 1
                return ("var", t[1])
            if is_op(t, 7):
                pos += 1
                node = assign()
                if not is_op(peek(), 8):
                    raise _Fail(1)
                pos += 1
                return node
            raise _Fail(1)

        def run(node):
            tag = node[0]
            if tag == "num":
                return node[1]
            if tag == "var":
                if env[node[1]] is None:
                    raise _Fail(2)
                return env[node[1]]
            if tag == "set":
                val = run(node[2])
                env[node[1]] = val
                return val
            if tag == "neg":
                return check(-run(node[1]))
            a = run(node[1])
            b = run(node[2])
            if tag == 1:
                return check(a + b)
            if tag == 2:
                return check(a - b)
            if tag == 3:
                return check(a * b)
            if tag in (4, 5):
                if b == 0:
                    raise _Fail(3)
                q = _trunc_div(a, b)
                return check(q if tag == 4 else a - b * q)
            if b < 0:
                raise _Fail(4)
            if a in (0, 1):
                return 1 if b == 0 else a
            if a == -1:
                return 1 if b % 2 == 0 else -1
            r = 1
            for _ in range(b):
                r = check(r * a)
            return r

        try:
            tree = assign()
            if pos != len(toks):
                raise _Fail(1)
        except _Fail as f:
            values.append(0)
            status.append(f.code)
            continue
        try:
            values.append(run(tree))
            status.append(0)
        except _Fail as f:
            values.append(0)
            status.append(f.code)
    return values, status, [0 if v is None else v for v in env], [v is not None for v in env]


# --- descriptions ----------------------------------------------------------------

_ORDER_BOOK = (
    "Run an order book and report what traded and what is left. Order i is given by "
    "kind[i], side[i], price[i], qty[i], trader[i] and tif[i], and the orders arrive in "
    "order, 0 first. kind is 0 for a limit order, 1 for a market order and 2 for a cancel. "
    "side is 0 to buy and 1 to sell. tif (time in force) is 0 for good till cancelled, 1 "
    "for immediate or cancel and 2 for fill or kill. The book holds resting orders, each "
    "with its order number, side, price, the quantity it still has and its trader. A "
    "cancel removes the resting order whose number is price[i] from the book and counts as "
    "a cancel; if no resting order has that number (it was never a resting order, has "
    "already gone from the book, or has not arrived yet), the cancel is rejected and "
    "changes nothing. For a cancel, side, qty, trader and tif are not used. For a limit "
    "or market order, a resting order can match it if it is on the other side and, for a "
    "limit order, its price is no worse: a resting sell matches a limit buy if its price "
    "is at most the buy's price, and a resting buy matches a limit sell if its price is at "
    "least the sell's price. A market order matches every resting order on the other side. "
    "Among the resting orders that can match, the best is the lowest-priced sell for a buy, "
    "or the highest-priced buy for a sell, and between equal prices the lower order "
    "number. A fill or kill order is checked first: if the quantities of the resting orders "
    "that can match it and belong to another trader add up to less than its quantity, it "
    "is killed and nothing at all happens, not even the self-trade removals below. "
    "Otherwise the incoming order matches repeatedly while it has quantity left and "
    "some resting order can match it. Take the best resting order. If it belongs to the same "
    "trader as the incoming order, it is removed from the book (its remaining quantity "
    "counts as self-cancelled) and matching goes on. Otherwise they trade: the quantity is "
    "the smaller of the two remaining quantities, the price is the resting order's price, "
    "both lose that quantity, and a resting order with nothing left leaves the book. After "
    "matching, a limit order that is good till cancelled and has quantity left rests in "
    "the book with that quantity; any other order's remaining quantity is dropped, and a "
    "market order never rests. Return the number of trades, the total quantity traded, the "
    "sum over trades of quantity times price, the total quantity self-cancelled, the number "
    "of cancels, the number of rejected cancels, the number of orders killed, and the "
    "resting orders at the end, as their numbers and, in the same order, their remaining "
    "quantities: buys first, best first (highest price, then lower number), then sells, "
    "best first (lowest price, then lower number). The six sequences have the same "
    "length, at most 30; kind is 0 to 2, side 0 or 1, tif 0 to 2, qty 1 to 1,000 and "
    "trader 0 to 9; price is 1 to 1,000 for a limit or market order (a market order's "
    "price is not used) and 0 to 29 for a cancel."
)

_GO_GAME = (
    "Play a game of Go and report the result. The board has size rows of size points; "
    "point (row r, column c) is number r times size plus c, and two points are neighbours "
    "if they are next to each other in a row or a column. Black (1) moves first, then the "
    "players take turns. Read the moves in order. A move is a point to play on, or -1 to "
    "pass. A pass is a turn. Playing on a point: if the point is not empty, the move is "
    "illegal. Otherwise put a stone of the player's colour there. A group is a set of stones "
    "of one colour joined through neighbours; its liberties are the empty points next to "
    "any of its stones. First, every group of the opponent's colour next to the new stone "
    "that now has no liberties is captured: its stones are removed. Then, if the new "
    "stone's own group has no liberties, the move is illegal (suicide). Then, if the whole "
    "board is now exactly as it was just before the opponent's latest turn, the move is "
    "illegal (ko). An illegal move changes nothing and is not a turn: the same player "
    "reads the next move. Otherwise the move is a turn and the captured stones count for "
    "the player who made it. The game ends when two turns in a row are passes, and moves "
    "after that are not read. At the end, each player's area is their stones on the board "
    "plus every empty point in a region (empty points joined through neighbours) whose "
    "neighbouring stones are all of that player's colour; a region next to both colours, "
    "or to none, counts for nobody. Return the final board (0 empty, 1 black, 2 white, "
    "point 0 first), the number of stones black captured, the number white captured, the "
    "number of illegal moves, the number of moves read, and black's area minus white's. "
    "size is 2 to 7; moves has at most 60 values, each -1 or a point of the board."
)

_STACK_VM = (
    "Run a program on a small stack machine with exceptions and report the final state. "
    "Instruction i is the operation ops[i] with the argument args[i]; the machine starts "
    "at instruction 0 with an empty data stack, an empty call stack and no handlers. "
    "Before each instruction: if the instruction number is not an instruction of the "
    "program (below 0, or not below the program's length), the machine halts normally; "
    "otherwise, if limit instructions have already run, it stops out of steps. Then the "
    "instruction runs and counts as run, and the machine goes on to the next instruction "
    "unless it says otherwise. The operations: 0 push args[i]; 1 add, 2 subtract, 3 "
    "multiply, 4 divide and 5 remainder, each taking the top two values, the top one as "
    "the right operand, and pushing the result; 6 duplicate the top value; 7 swap the top "
    "two; 8 drop the top value; 9 jump to instruction args[i]; 10 pop a value and jump to "
    "args[i] if it is 0; 11 call: push the number of the next instruction on the call "
    "stack and jump to args[i]; 12 return: pop the call stack and jump there, or halt "
    "normally if it is empty; 13 try: push a handler holding args[i], the data stack's "
    "length and the call stack's length; 14 end try: pop the latest handler; 15 throw: pop "
    "a value and throw it; 16 halt normally. Division rounds toward zero, and the remainder "
    "is the left operand minus the right operand times the quotient. An instruction throws "
    "instead of doing anything (it changes nothing first) in these cases: the data stack "
    "has fewer values than it takes (code 2; add to remainder and swap take two, duplicate, "
    "drop, the conditional jump and throw take one); divide or remainder by 0 (code 1); end "
    "try with no handler (code 3); push or duplicate when the data stack already holds 32 "
    "values, call when the call stack already holds 16, or try when there are already 8 "
    "handlers (code 4); a result of add, subtract, multiply, divide or remainder above "
    "1,000,000,000 or below -1,000,000,000 (code 6). Throw (15) throws the value it popped. "
    "When a value is thrown: if there is no handler, the machine stops with an uncaught "
    "exception; otherwise the latest handler is popped, the data stack and the call stack "
    "are cut back to the lengths it holds (if they are longer), the thrown value is pushed "
    "(even onto 32 values), "
    "and the machine jumps to the instruction it holds. Return the data stack (bottom "
    "first), the status (0 halted normally, 1 uncaught exception, 2 out of steps), the "
    "uncaught value (0 unless the status is 1), the number of instructions run, the number "
    "of exceptions caught by a handler, and the largest length the data stack had at any "
    "point. ops and args have the same length, 1 to 60; every op is 0 to 16; args are -1,000 "
    "to 1,000 for a push and 0 to 60 for a jump, conditional jump, call or try, and are "
    "not used by other operations (they are 0); limit is 1 to 800."
)

_JOSEPHUS = (
    "Answer questions about the Josephus elimination. For question i, n[i] people stand in "
    "a circle, numbered 0 to n[i] - 1 in order around it. Counting starts at person 0, "
    "who is counted first, and goes around the circle; the person counted k[i]-th is "
    "removed, and counting starts again at 1 with the next person still in the circle "
    "after them. This goes on until everyone has been removed; the last person removed "
    "is the survivor. Return, for each question in order, the survivor's number, and, "
    "in a second sequence, the number of the m[i]-th person removed. n, k and m have the "
    "same length, 1 to 3; n is 1 to 1,000,000,000,000; k is 1 to 12; m is 1 to 200 and "
    "at most n."
)

_PERM_RANK = (
    "Rank and unrank the orders of a multiset. items is a list of digits (0 to 9), "
    "possibly repeated. Its arrangements are the different sequences that use exactly "
    "items' digits, each as many times as it appears in items; two arrangements are "
    "different if they differ at some position. List every arrangement in increasing "
    "order, comparing two arrangements at the first position where they differ (the "
    "smaller digit first), and number them from 0. Return the number of arrangements; "
    "the number of perm in the list, or -1 if perm is not an arrangement of items; the "
    "arrangement numbered k, or an empty sequence if there is none; and the arrangement "
    "after perm in the list, or an empty sequence if perm is the last one or not an "
    "arrangement. items has 1 to 20 digits and perm 0 to 20, each 0 to 9; k is 0 to "
    "10,000,000,000,000,000."
)

_WIRE = (
    "Decode a stream of records in a binary format. data is a list of bytes (0 to 255). "
    "A varint is read one byte at a time: byte j of it (from 0) adds its low 7 bits (the "
    "byte mod 128) times 128 to the power j to the value, and the varint ends at the "
    "first byte below 128. A record is a varint tag, then a payload: its field is the tag "
    "divided by 8 (rounded down) and its wire type is the tag mod 8. Wire type 0: the "
    "payload is a varint, and the value is that varint. Wire type 1: the payload is a "
    "varint u, and the value is u / 2 if u is even and -(u + 1) / 2 if u is odd. Wire type "
    "2: the payload is a varint L followed by L bytes, which are skipped; the value is L. "
    "Wire type 5: the payload is 4 bytes, and the value is the first byte plus 256 times "
    "the second plus 65,536 times the third plus 16,777,216 times the fourth. Records "
    "are read one after another from the first byte until the data is used up. Reading "
    "stops at the first error, in the record where it happens, and that record is not "
    "kept: the data ends in the middle of a record (error 1); a varint of more than one "
    "byte whose last byte is 0 (error 2); a varint whose first 8 bytes are all 128 or more "
    "(error 3); a tag whose field is 0 (error 4); a tag whose wire type is not 0, 1, 2 or "
    "5 (error 5). The tag is checked as soon as it is read, field first. Return the field, "
    "the wire type and the value of each record read before any error, in order (three "
    "sequences); the error (0 if none); and the position in data of the first byte of the "
    "record with the error (-1 if none). data has at most 200 bytes."
)

_TENNIS = (
    "Score a tennis match point by point. points lists who won each point, 0 or 1. The "
    "match is best of bestOf sets (3 or 5): the first player to win more than half of them "
    "wins the match, and points after that are not read. A game is won by the first "
    "player to have at least 4 points and 2 more than the other; but if noAd is true, at 3 "
    "points each the next point wins the game. A set is won by the first player to have "
    "at least 6 games and 2 more than the other, except that at 6 games each a tiebreak is "
    "played, and its winner wins the set 7 games to 6. A tiebreak is won by the first "
    "player to have at least 7 points and 2 more than the other. The deciding set (the "
    "last possible one, which is only reached at equal sets) follows finalSet: 0, it is "
    "like the others; 1, it has no tiebreak, and is won only by 2 games; 2, it is a match "
    "tiebreak instead of a set, won like a tiebreak but at 10 points instead of 7. The "
    "player server serves the first game; the server changes after every game. In a "
    "tiebreak, the player whose turn it is to serve serves the first point, then the "
    "other player serves the next two points, and so on, changing every two points. After a "
    "tiebreak, the next set's first game is served by the player who did not serve the "
    "tiebreak's first point. A break is a game (not a tiebreak) won by the player not "
    "serving it. Return the games of every set that has started, as player 0's games "
    "then player 1's for each set in order, where a set starts when the one before it "
    "ends (the first at the start) and a match tiebreak, finished or not, is given as its "
    "points so far; the "
    "winner (-1 if the match is not over); the number of points read; the points each "
    "player has in the current game or tiebreak (0 and 0 if the match is over); who "
    "serves the next point (-1 if the match is over); and the number of breaks each "
    "player won. points has at most 400 values; server is 0 or 1."
)

_TIMETABLE = (
    "Find the earliest arrival at every station of a railway. Stations are 0 to "
    "stations - 1. Connection i is a train, train[i], leaving station fromSt[i] at time "
    "dep[i] and arriving at station toSt[i] at time arr[i], with no stop between. Each "
    "train's connections, taken in order of departure, form one run: each leaves from the "
    "station where the one before it arrived, no earlier than it arrived. A traveller "
    "starts at station origin at time start. They can board a train at a station for one "
    "of its connections leaving there: at the origin, if the connection leaves at start or "
    "later; elsewhere, if they arrived there by another train at least change before the "
    "connection leaves. Once aboard, they can stay on for the train's later connections "
    "and get off where any of them arrives. Return, for each station, the earliest time "
    "the traveller can be there (start for the origin, -1 if they cannot get there) and "
    "the fewest trains used by a journey that arrives that early (0 for the origin, -1 if "
    "they cannot get there). Taking one train is one train used, and taking the same train "
    "again later counts again. stations is 2 to 12; change is 0 to 10; origin is a "
    "station; start is 0 to 1,440. fromSt, toSt, dep, arr and train have the same length, at "
    "most 60, and are listed in order of dep, which never decreases; fromSt and toSt are "
    "different stations; dep is 0 to 1,440 and less than arr, which is at most 1,440; "
    "train is 0 to 11."
)

_EXPR_EVAL = (
    "Run a small expression language. The program is a list of tokens: token i has kind "
    "kinds[i] and value vals[i]. Kind 0 is a number, its value; kind 1 is the variable "
    "with that number, 0 to 7; kind 2 is a symbol: 1 +, 2 -, 3 *, 4 /, 5 %, 6 ^, 7 (, 8 ), "
    "9 = and 10 ;. Semicolons split the program into statements, and a statement with no "
    "tokens is ignored. Each statement must be an expression by this grammar, using all "
    "its tokens: an expression is a variable followed by = and an expression (an "
    "assignment), or else a sum; a sum is one or more products joined by + or -, taken left "
    "to right; a product is one or more factors joined by *, / or %, left to right; a "
    "factor is - followed by a factor (negation), or a power; a power is an atom, "
    "optionally followed by ^ and a factor; an atom is a number, a variable, or an "
    "expression in parentheses. So -2^2 is -(2^2), 2^3^2 is 2^(3^2) and 2^-1 is 2^(-1). "
    "A statement that does not fit the grammar fails with code 1 and does nothing. "
    "Otherwise it is evaluated, operands left before right. An assignment evaluates its "
    "right side, gives the variable that value, and has that value. Variables start with "
    "no value, and keep values between statements. / is division rounding toward zero; % "
    "is the left operand minus the right times their quotient; a^b is a multiplied by "
    "itself b times (a^0 is 1, and 0^0 is 1). A statement stops at its first error: "
    "reading a variable with no value (code 2), dividing or taking % by 0 (code 3), a "
    "negative power (code 4), or any value (of a negation, an operation or a power) above "
    "1,000,000,000,000 or below -1,000,000,000,000 (code 5). Assignments it made before "
    "the error stay. Return, for each statement that is not ignored, its value (0 if it "
    "failed) and its code (0 if it did not fail), then each variable's value (0 if it has "
    "none) and whether it has one. kinds and vals have the same length, at most 60; a "
    "number is 0 to 9,999, a variable 0 to 7 and a symbol 1 to 10."
)


# --- random inputs ---------------------------------------------------------------

def _random_order_book(seed, n=None):
    rng = random.Random(seed)
    n = rng.randint(1, 30) if n is None else n
    kind, side, price, qty, trader, tif = [], [], [], [], [], []
    mid = rng.randint(20, 980)
    for i in range(n):
        k = rng.choices((0, 1, 2), (6, 1, 2))[0]
        kind.append(k)
        side.append(rng.randint(0, 1))
        price.append(rng.randint(0, i) if k == 2 else max(1, min(1000, mid + rng.randint(-8, 8))))
        qty.append(rng.choice((rng.randint(1, 20), rng.randint(1, 1000))))
        trader.append(rng.randint(0, rng.choice((1, 3, 9))))
        tif.append(rng.choices((0, 1, 2), (5, 2, 2))[0])
    return kind, side, price, qty, trader, tif


def _random_go(seed, size=None, n=None):
    rng = random.Random(seed)
    size = rng.randint(2, 7) if size is None else size
    n = rng.randint(0, 60) if n is None else n
    moves = []
    for _ in range(n):
        moves.append(-1 if rng.random() < 0.06 else rng.randrange(size * size))
    return size, moves


def _random_stack_vm(seed, n=None, limit=None):
    """A program built from small pieces (arithmetic on pushed values, a counted
    loop, a call to a routine, a guarded block with a handler), with random
    instructions mixed in, so most runs do more than fault at once."""
    rng = random.Random(seed)
    n = rng.randint(1, 60) if n is None else n
    ops, args = [], []

    def put(op, arg=0):
        ops.append(op)
        args.append(arg)

    def piece():
        r = rng.random()
        if r < 0.3:
            for _ in range(rng.randint(1, 3)):
                put(0, rng.randint(-1000, 1000) if rng.random() < 0.3 else rng.randint(-9, 9))
            for _ in range(rng.randint(0, 3)):
                put(rng.choice((1, 2, 3, 4, 5, 6, 7, 8)))
        elif r < 0.5:   # count down from k: push k; top: dup, jz end, push 1, sub, jmp top; end: drop
            put(0, rng.randint(0, 12))
            top = len(ops)
            put(6)
            put(10, top + 5)
            put(0, rng.choice((1, 1, 2)))
            put(2)
            put(9, top)
            put(8)
        elif r < 0.7:   # try: guard a throw or a fault; handler drops or keeps the code
            at = len(ops)
            put(13, 0)
            put(0, rng.randint(-5, 5))
            put(rng.choice((15, 4, 14, 0)), rng.randint(0, 3))
            put(14)
            put(9, len(ops) + 2)
            args[at] = len(ops)
            put(rng.choice((8, 6, 0)), 1)
        elif r < 0.85:   # call a routine placed after a jump over it
            put(11, len(ops) + 2)
            put(9, len(ops) + 4)
            put(rng.choice((6, 0, 3, 1)), rng.randint(1, 4))
            put(12)
        else:
            op = rng.randrange(17)
            put(op, rng.randint(-9, 9) if op == 0 else rng.randint(0, 60) if op in (9, 10, 11, 13) else 0)

    while len(ops) < n:
        piece()
    del ops[n:], args[n:]
    args = [min(a, 60) if op in (9, 10, 11, 13) else a if op == 0 else 0 for op, a in zip(ops, args)]
    return ops, args, rng.randint(1, 800) if limit is None else limit


def _random_josephus(seed, q=None):
    rng = random.Random(seed)
    q = rng.randint(1, 3) if q is None else q
    n = [rng.choice((rng.randint(1, 30), rng.randint(1, 10 ** rng.randint(2, 12)), 10 ** 12 - rng.randint(0, 9)))
         for _ in range(q)]
    k = [rng.randint(1, 12) for _ in range(q)]
    m = [rng.randint(1, min(a, 200)) for a in n]
    return n, k, m


def _random_perm_rank(seed):
    rng = random.Random(seed)
    items = [rng.randint(0, rng.choice((1, 3, 9))) for _ in range(rng.randint(1, 20))]
    perm = items[:]
    rng.shuffle(perm)
    r = rng.random()
    if r < 0.1:
        perm = sorted(items, reverse=True)
    elif r < 0.2 and perm:
        perm[rng.randrange(len(perm))] = rng.randint(0, 9)
    elif r < 0.25:
        perm = perm[:-1]
    total = _arrangements([items.count(v) for v in range(10)])
    k = rng.choice((rng.randrange(total), total - 1, total, rng.randint(0, 10 ** 16)))
    return items, perm, k


def _random_wire(seed, n=None):
    rng = random.Random(seed)
    want = rng.randint(0, 200) if n is None else n
    data = []

    def varint(v):
        out = []
        while True:
            out.append(v % 128 + (128 if v >= 128 else 0))
            v //= 128
            if not v:
                return out

    while len(data) < want:
        wire = rng.choices((0, 1, 2, 5, 3), (4, 3, 2, 2, 0.15))[0]
        field = 0 if rng.random() < 0.005 else rng.choice((rng.randint(1, 15), rng.randint(16, 3000)))
        rec = varint(field * 8 + wire)
        if wire in (0, 1):
            rec += varint(rng.choice((rng.randint(0, 200), rng.randint(0, 2 ** rng.randint(8, 56) - 1))))
        elif wire == 2:
            size = rng.randint(0, 12)
            rec += varint(size) + [rng.randint(0, 255) for _ in range(size)]
        elif wire == 5:
            rec += [rng.randint(0, 255) for _ in range(4)]
        if rng.random() < 0.03 and rec[-1] < 128 and wire in (0, 1):   # a non-minimal varint payload
            rec[-1] += 128
            rec.append(0)
        data += rec
    del data[want:]                                # often cuts the last record short
    if rng.random() < 0.03:
        data[rng.randrange(len(data)):] = [255] * 9  # a varint that is too long
        del data[200:]
    return (data,)


def _random_tennis(seed, n=None, bias=None):
    rng = random.Random(seed)
    n = rng.randint(0, 400) if n is None else n
    bias = rng.uniform(0.3, 0.7) if bias is None else bias
    hold = rng.uniform(0.55, 0.7)
    points = [int(rng.random() < bias) if rng.random() < 0.5 else int(rng.random() > hold) for _ in range(n)]
    return points, rng.choice((3, 5)), rng.randint(0, 2), rng.random() < 0.3, rng.randint(0, 1)


def _random_timetable(seed, n=None):
    rng = random.Random(seed)
    stations = rng.randint(2, 12)
    trains = rng.randint(1, 12)
    conns = []
    budget = rng.randint(1, 60) if n is None else n
    for t in range(trains):
        if len(conns) >= budget:
            break
        at = rng.randrange(stations)
        time = rng.randint(0, 600)
        for _ in range(rng.randint(1, max(1, min(8, budget - len(conns))))):
            to = rng.choice([s for s in range(stations) if s != at])
            dep = time + rng.randint(0, 20)
            arr = dep + rng.randint(1, 60)
            if arr > 1440:
                break
            conns.append((at, to, dep, arr, t))
            at, time = to, arr
    conns.sort(key=lambda c: c[2])
    cols = [list(c) for c in zip(*conns)] if conns else [[], [], [], [], []]
    return (stations, rng.randint(0, 10), rng.randrange(stations), rng.randint(0, 300), *cols)


def _random_expr(seed, n=None):
    rng = random.Random(seed)
    n = rng.randint(1, 60) if n is None else n
    kinds, vals = [], []
    known = set()   # variables an earlier statement assigns (if it does not fail)

    def expr(out, depth, top=False):
        if depth > 3 or rng.random() < 0.3:
            r = rng.random()
            if r < 0.45 or (r < 0.8 and not known and rng.random() < 0.8):
                out.append((0, rng.choice((0, 1, 2, 3, 7, 10, rng.randint(0, 9999)))))
            elif r < 0.8:
                out.append((1, rng.choice(sorted(known)) if known and rng.random() < 0.95 else rng.randint(0, 7)))
            else:
                out.append((2, 7))
                expr(out, depth + 1, True)
                out.append((2, 8))
            return
        r = rng.random()
        if r < 0.15 and top:
            out += [(1, rng.randint(0, 7)), (2, 9)]
            expr(out, depth + 1, True)
        elif r < 0.25:
            out.append((2, 2))
            expr(out, depth + 1)
        else:
            expr(out, depth + 1)
            out.append((2, rng.choice((1, 2, 3, 4, 5, 6, 1, 2, 3))))
            expr(out, depth + 1)

    while True:
        out = []
        target = rng.randint(0, 7) if rng.random() < 0.5 else None
        if target is not None:
            out += [(1, target), (2, 9)]
        expr(out, 0, True)
        if rng.random() < 0.08:   # noise: often a syntax error
            k = rng.randint(0, 2)
            out.insert(rng.randint(0, len(out)), (k, rng.randint(0, 7) if k == 1 else rng.randint(1, 10)))
        out.append((2, 10))
        if len(kinds) + len(out) > n:
            break
        for k, v in out:
            kinds.append(k)
            vals.append(v)
        if target is not None:
            known.add(target)
    return kinds, vals


# --- hand-picked hidden tests ----------------------------------------------------

def _ob(*orders):
    """order-book inputs from (kind, side, price, qty, trader, tif) rows."""
    cols = [list(c) for c in zip(*orders)] if orders else [[]] * 6
    return tuple(cols)


_LIM, _MKT, _CXL = 0, 1, 2
_BUY, _SELL = 0, 1
_GTC, _IOC, _FOK = 0, 1, 2


def _order_book_cases():
    L, M, C, Bu, Se = _LIM, _MKT, _CXL, _BUY, _SELL
    return [
        # Price before time: a later, better sell is taken first; equal prices by number.
        _ob((L, Se, 105, 5, 1, _GTC), (L, Se, 103, 5, 2, _GTC), (L, Se, 103, 5, 3, _GTC),
            (L, Bu, 105, 12, 4, _GTC)),
        # A sell crossing resting buys trades at the buys' prices, highest first; the rest rests.
        _ob((L, Bu, 98, 4, 1, _GTC), (L, Bu, 99, 4, 2, _GTC), (L, Bu, 99, 4, 3, _GTC),
            (L, Se, 97, 20, 4, _GTC)),
        # Self-trade: the best sell is the buyer's own and is removed; matching goes on.
        _ob((L, Se, 50, 7, 1, _GTC), (L, Se, 51, 3, 2, _GTC), (L, Bu, 60, 5, 1, _GTC)),
        # Fill or kill: enough only when the buyer's own order is counted, so it is killed and
        # the own order stays.
        _ob((L, Se, 10, 4, 1, _GTC), (L, Se, 11, 4, 2, _GTC), (L, Bu, 11, 6, 1, _FOK)),
        # Fill or kill with exactly enough from others: fills, removing its own order on the way.
        _ob((L, Se, 10, 4, 1, _GTC), (L, Se, 11, 4, 2, _GTC), (L, Se, 12, 2, 3, _GTC),
            (L, Bu, 12, 6, 1, _FOK)),
        # Fill or kill not crossing at all is killed; a fill or kill sell market order fills.
        _ob((L, Bu, 20, 5, 1, _GTC), (L, Se, 21, 1, 2, _FOK), (M, Se, 1, 5, 3, _FOK)),
        # Immediate or cancel: a partial fill, the rest dropped; one with no match is dropped.
        _ob((L, Se, 30, 3, 1, _GTC), (L, Bu, 31, 5, 2, _IOC), (L, Bu, 29, 5, 2, _IOC),
            (L, Bu, 29, 2, 3, _GTC)),
        # A market buy sweeps three prices; a good-till-cancelled market order never rests.
        _ob((L, Se, 7, 2, 1, _GTC), (L, Se, 9, 2, 2, _GTC), (L, Se, 8, 2, 3, _GTC),
            (M, Bu, 1, 10, 4, _GTC), (M, Se, 500, 3, 5, _GTC)),
        # Cancels: a partly filled resting order (done), a filled one, a market order, a cancel,
        # a later order and one already cancelled (all rejected).
        _ob((L, Se, 40, 5, 1, _GTC), (L, Bu, 40, 2, 2, _GTC), (C, 0, 0, 1, 0, 0),
            (L, Se, 41, 1, 1, _GTC), (L, Bu, 41, 1, 2, _GTC), (C, 0, 3, 1, 0, 0),
            (M, Bu, 1, 1, 3, _GTC), (C, 0, 6, 1, 0, 0), (C, 0, 7, 1, 0, 0), (C, 0, 10, 1, 0, 0),
            (C, 0, 0, 1, 0, 0), (L, Bu, 5, 1, 4, _GTC)),
        # The final book: buys best first, then sells best first, equal prices by number.
        _ob((L, Se, 12, 1, 1, _GTC), (L, Bu, 8, 2, 2, _GTC), (L, Se, 11, 3, 3, _GTC),
            (L, Bu, 9, 4, 4, _GTC), (L, Bu, 8, 5, 5, _GTC), (L, Se, 11, 6, 6, _GTC),
            (L, Bu, 9, 7, 7, _IOC)),
        # Only the best order is checked for self-trade: a deeper own order stays.
        _ob((L, Se, 20, 5, 2, _GTC), (L, Se, 25, 5, 1, _GTC), (L, Bu, 30, 3, 1, _GTC)),
        # A cancel naming an order removed by self-trade is rejected; both sides fill exactly.
        _ob((L, Bu, 70, 3, 1, _GTC), (L, Se, 70, 3, 1, _GTC), (C, 0, 0, 1, 0, 0),
            (L, Bu, 70, 4, 2, _GTC), (L, Se, 69, 4, 3, _IOC)),
        # A market order with an empty book, and a cancel as the first order.
        _ob((C, 1, 0, 9, 9, 2), (M, Bu, 1000, 1000, 9, _IOC)),
        # Large quantities and prices.
        _ob((L, Se, 1000, 1000, 0, _GTC), (L, Se, 999, 1000, 1, _GTC), (L, Bu, 1000, 1000, 2, _IOC),
            (M, Bu, 1, 1000, 3, _FOK), (M, Bu, 1, 1000, 4, _FOK)),
    ]


def _go_cases():
    def pt(size, r, c):
        return r * size + c
    P = -1
    s3 = lambda r, c: pt(3, r, c)  # noqa: E731
    s4 = lambda r, c: pt(4, r, c)  # noqa: E731
    s5 = lambda r, c: pt(5, r, c)  # noqa: E731
    return [
        # A corner stone captured; then an occupied point is illegal and black plays again.
        (3, [s3(1, 0), s3(0, 0), s3(0, 1), s3(0, 1), s3(2, 2), P, P, s3(1, 1)]),
        # Suicide into a single eye is illegal; white must play elsewhere.
        (3, [s3(0, 1), s3(2, 2), s3(1, 0), s3(2, 1), s3(1, 1), s3(0, 0), s3(1, 2), P, P]),
        # A move that would have no liberties but captures first is legal.
        (4, [s4(0, 1), s4(0, 0), s4(1, 0), s4(3, 3), s4(2, 0), s4(1, 1), s4(3, 0), s4(0, 2),
             s4(1, 2), s4(2, 1), s4(2, 2), P, P]),
        # Ko: black captures, white's immediate recapture is illegal, white plays elsewhere,
        # black fills elsewhere, and white's recapture is then legal.
        (5, [s5(0, 1), s5(0, 2), s5(1, 0), s5(1, 3), s5(2, 1), s5(2, 2), s5(4, 4), s5(1, 1),
             s5(1, 2), s5(1, 1), s5(3, 3), s5(4, 0), s5(1, 1), P, P]),
        # Two passes end the game, even with an illegal move between them; later moves unread.
        (3, [s3(1, 1), P, s3(1, 1), P, s3(0, 0), s3(0, 1)]),
        # A pass, a move and a pass are not two passes in a row.
        (3, [P, s3(0, 0), P, s3(2, 2), P, P, s3(1, 1)]),
        # An empty board: no area for anyone.
        (4, [P, P]),
        # The 2 by 2 board: two stones captured, then an occupied point.
        (2, [0, 3, 1, 2, P, 0, P, 3, P, P]),
        # A group of four captured at once, and two white groups captured by one stone.
        (5, [s5(0, 0), s5(1, 0), s5(0, 1), s5(1, 1), s5(0, 2), s5(1, 2), s5(0, 3), s5(1, 3),
             s5(2, 0), s5(0, 4), s5(2, 1), s5(1, 4), s5(2, 2), P, s5(2, 3), P, s5(2, 4)]),
        (4, [s4(1, 1), s4(0, 1), s4(1, 2), s4(0, 2), s4(1, 0), s4(3, 3), s4(1, 3), s4(2, 3),
             s4(0, 0), s4(3, 2), s4(0, 3)]),
        # A neutral region touching both colours, and territory for each.
        (5, [s5(0, 1), s5(0, 3), s5(1, 1), s5(1, 3), s5(2, 1), s5(2, 3), s5(3, 1), s5(3, 3),
             s5(4, 1), s5(4, 3), P, P]),
        # The board recreated two turns back is not ko: only the position just before the
        # opponent's latest turn counts.
        (4, [s4(0, 1), s4(0, 2), s4(1, 0), s4(1, 3), s4(2, 1), s4(2, 2), s4(1, 2), s4(1, 1),
             s4(3, 3), s4(1, 2), P, P]),
    ]


def _vm(*code, limit=800):
    ops = [c[0] for c in code]
    args = [c[1] if len(c) > 1 else 0 for c in code]
    return ops, args, limit


(_PUSH, _ADD, _SUB, _MUL, _DIV, _REM, _DUP, _SWAP, _DROP, _JMP, _JZ, _CALL, _RET, _TRY,
 _ENDTRY, _THROW, _HALT) = range(17)


def _stack_vm_cases():
    P = _PUSH
    return [
        # Division and remainder round toward zero for every sign.
        _vm((P, -7), (P, 2), (_DIV,), (P, -7), (P, 2), (_REM,), (P, 7), (P, -2), (_DIV,), (P, 7), (P, -2),
            (_REM,), (P, -7), (P, -2), (_DIV,), (P, -7), (P, -2), (_REM,)),
        # Underflow is thrown before anything changes, and is not caught.
        _vm((P, 5), (_ADD,), (P, 6)),
        # Divide by zero caught: the stack is cut back to the try's length and the code pushed.
        _vm((P, 1), (_TRY, 7), (P, 2), (P, 3), (P, 0), (_DIV,), (_HALT,), (P, 9), (_ADD,)),
        # Nested handlers: the inner catches a throw, rethrows it, the outer catches it.
        _vm((_TRY, 9), (_TRY, 5), (P, 42), (_THROW,), (_HALT,), (P, 1), (_ADD,), (_THROW,), (_HALT,),
            (P, 100), (_ADD,), (_HALT,)),
        # End try with no handler: code 3, uncaught; a later instruction does not run.
        _vm((P, 1), (_ENDTRY,), (P, 2)),
        # The 33rd value pushed throws code 4.
        _vm(*([(P, 1)] * 33)),
        # Caught with 32 values kept: the code is pushed anyway, making 33.
        _vm(*([(P, 1)] * 32), (_TRY, 35), (P, 1), (_HALT,), (_DROP,)),
        # Duplicating in a loop until the stack is full, caught by the handler.
        _vm((_TRY, 4), (P, 7), (_DUP,), (_JMP, 2), (P, -1), (_HALT,)),
        # Unbounded recursion: the 17th call throws code 4.
        _vm((_CALL, 0)),
        # A routine: call, return to the caller; return with an empty call stack halts.
        _vm((P, 3), (_CALL, 4), (P, 10), (_RET,), (_DUP,), (_MUL,), (_RET,)),
        # A conditional jump on a value that is not 0 falls through; jumping to the
        # program's length halts normally.
        _vm((P, 4), (_JZ, 3), (_JMP, 4), (P, 9)),
        # Out of steps in an endless loop, with the limit counted exactly.
        _vm((P, 1), (_JMP, 0), limit=7),
        # Halting by running off the end exactly when the limit is reached is a normal halt.
        _vm((P, 1), (P, 2), (_ADD,), limit=3),
        # A result above 1,000,000,000 throws code 6, and so does one below -1,000,000,000;
        # exactly 1,000,000,000 is fine.
        _vm((P, 1000), (P, 1000), (_MUL,), (P, 1000), (_MUL,), (_TRY, 9), (P, 1), (_ADD,), (_HALT,),
            (P, 0), (P, 1000), (_SUB,), (P, 1000), (_MUL,), (P, 1000), (_MUL,), (P, 2), (_MUL,)),
        # A throw inside a call: the handler cuts the call stack back, so a return halts.
        _vm((_TRY, 5), (_CALL, 3), (_HALT,), (P, 8), (_THROW,), (P, 1), (_RET,)),
        # The handler's saved length is longer than the stack when the throw comes.
        _vm((P, 1), (P, 2), (P, 3), (_TRY, 7), (_DROP,), (_DROP,), (_THROW,), (P, 5)),
        # Throwing 0, uncaught: status 1 with value 0.
        _vm((P, 0), (_THROW,)),
        # The ninth handler throws code 4, caught by the eighth.
        _vm(*([(_TRY, 9)] * 9), (P, 2), (_MUL,)),
        # Swap, then a conditional jump pops its value, leaving too few to subtract.
        _vm((P, 2), (P, 3), (_SWAP,), (_JZ, 0), (_SUB,)),
        # A swap underflow is caught; a drop underflow after it is not.
        _vm((_TRY, 3), (P, 4), (_SWAP,), (_DROP,), (_DROP,), (_TRY, 8), (_DROP,), (_HALT,), (P, 6)),
    ]


def _josephus_cases():
    def q(*rows):
        return tuple(list(c) for c in zip(*rows))
    return [
        # One person, and counting by 1 removes everyone in order.
        q((1, 1, 1), (1, 7, 1), (9, 1, 9)),
        q((9, 1, 4), (5, 9, 1), (5, 9, 5)),
        # Counting past the end of a small circle, and k equal to n.
        q((6, 6, 2), (6, 6, 6), (12, 12, 12)),
        # The well-known circle of 41 counting by 3, and by 2.
        q((41, 3, 1), (41, 3, 13), (41, 3, 41)),
        q((41, 2, 41),),
        # Counting by 2 in large circles, and the largest circle counting by 12.
        q((10 ** 12, 2, 200), (2 ** 39, 2, 1), (2 ** 39 + 1, 2, 2)),
        q((10 ** 12, 12, 200),),
        # Removals that wrap around the circle before the m-th.
        q((150, 7, 200 - 50), (37, 12, 37), (13, 12, 13)),
        # Large circles counting by 11 and 10, a circle one larger than k, and two people.
        q((999_999_999_999, 11, 1), (123_456_789_012, 10, 200), (13, 12, 12)),
        q((2, 2, 2),),
    ]


def _perm_rank_cases():
    return [
        # A single digit: one arrangement.
        ([7], [7], 0),
        ([7], [7], 1),
        # All digits the same: rank 0, nothing after it.
        ([3, 3, 3, 3], [3, 3, 3, 3], 0),
        # The last arrangement has nothing after it; k past the end gives an empty one.
        ([2, 1, 0], [2, 1, 0], 6),
        ([1, 0, 1, 0], [1, 1, 0, 0], 5),
        # Not an arrangement: wrong counts, wrong length, empty.
        ([1, 2, 2], [1, 1, 2], 2),
        ([1, 2, 2], [1, 2], 2),
        ([1, 2, 2], [], 0),
        # Repeated digits counted once per distinct arrangement.
        ([0, 0, 1, 1, 2], [1, 0, 2, 1, 0], 17),
        # Twenty digits, two of each, and their largest arrangement.
        ([9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
         [9, 9, 8, 8, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0], 2_375_880_867_359_999),
        ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
         [5, 0, 9, 1, 8, 2, 7, 3, 6, 4, 4, 6, 3, 7, 2, 8, 1, 9, 0, 5], 1_000_000_000_000_000),
        # Ten different digits, and a k of exactly the number of arrangements.
        ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [9, 8, 7, 6, 5, 4, 3, 2, 0, 1], 3_628_800),
        ([4, 4, 4, 1, 1, 9, 9, 9, 9, 0, 0, 0, 0, 0, 2, 2, 7, 7, 7, 7],
         [0, 0, 0, 0, 0, 1, 1, 2, 2, 4, 4, 4, 7, 7, 7, 7, 9, 9, 9, 9], 10 ** 16),
    ]


def _wire_cases():
    return [
        # No data.
        ([],),
        # One record of each wire type, with multi-byte varints.
        ([8, 150, 1, 17, 3, 26, 2, 9, 9, 45, 1, 0, 0, 0],),
        # Zigzag values 0, -1, 1, -2 and the largest 8-byte one; the largest 4-byte value.
        ([9, 0, 9, 1, 9, 2, 9, 3, 9, 255, 255, 255, 255, 255, 255, 255, 127, 13, 255, 255, 255, 255],),
        # The largest 8-byte varint is fine; a ninth byte is error 3.
        ([8, 255, 255, 255, 255, 255, 255, 255, 127, 8, 128, 128, 128, 128, 128, 128, 128, 128, 1],),
        # A length of 0, and a field above 15 with a two-byte tag.
        ([10, 0, 128, 1, 5],),
        # Data ending inside a tag, inside a varint payload, inside skipped bytes, inside a
        # 4-byte payload.
        ([8, 1, 136],),
        ([8, 200],),
        ([18, 5, 1, 2, 3, 4],),
        ([8, 1, 13, 0, 0, 0],),
        # Non-minimal varints in a tag and in a payload; a single 0 byte is minimal.
        ([8, 0, 136, 0, 1],),
        ([8, 0, 8, 255, 0],),
        # Field 0 (checked before the wire type), wire types 3, 4, 6 and 7.
        ([5, 1, 2, 3, 4],),
        ([0],),
        ([8, 1, 11, 1],),
        ([12, 1],),
        ([14, 1],),
        ([15, 1],),
        # A length that runs past the end, and one that ends exactly at the end.
        ([10, 3, 1, 2],),
        ([10, 3, 1, 2, 3],),
        # A large tag: field 2,000,000 with wire type 5.
        ([133, 136, 232, 7, 1, 2, 3, 4],),
    ]


def _games(*winners):
    """Points for whole love games won by the given players."""
    return [w for w in winners for _ in range(4)]


def _tennis_cases():
    six0 = _games(*[0] * 6)
    deuce = [0, 1, 0, 1, 0, 1, 1, 0, 0, 0]          # deuce twice, then player 0 wins
    tb_games = []
    for i in range(12):
        tb_games += _games(i % 2)
    return [
        # 6-0 6-0: the match ends and later points are not read.
        (six0 + six0 + [1, 1, 1], 3, 0, False, 0),
        # Deuce and advantage in a game; then an unfinished game.
        (deuce + [1, 1], 3, 0, False, 1),
        # No-ad: at 3 points each the next point wins.
        ([0, 0, 0, 1, 1, 1, 1] + [0, 0, 0, 1, 1, 1, 0], 3, 0, True, 0),
        # A tiebreak: the serve order within it, and the next set's first server.
        (tb_games + [0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0] + [1, 1], 3, 0, False, 0),
        # Breaks: player 1 wins games player 0 serves.
        (_games(1, 1, 1, 0, 1, 1, 1), 3, 0, False, 0),
        # The deciding set with no tiebreak: 9-7.
        (six0 + _games(*[1] * 6) + tb_games + _games(0, 1, 0, 0), 3, 1, False, 1),
        # The deciding set as a match tiebreak, won 11-9.
        (six0 + _games(*[1] * 6) + [0, 1] * 9 + [0, 0], 3, 2, False, 0),
        # Best of five with a tiebreak in the fifth set.
        (six0 + _games(*[1] * 6) + six0 + _games(*[1] * 6) + tb_games + [1] * 7, 5, 0, False, 1),
        # Unfinished, in the middle of a tiebreak: the points and who serves next.
        (tb_games + [0, 0, 1], 3, 0, False, 1),
        # No points at all.
        ([], 5, 2, True, 1),
        # A set won 7-5, then a new set started at 0-0.
        (_games(0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0), 3, 0, False, 0),
        # A match tiebreak that needs more than 10 points; unfinished at 12-11.
        (six0 + _games(*[1] * 6) + [0, 1] * 11 + [0], 3, 2, True, 1),
        # A tiebreak at 6-6 in the deciding set under rule 0, won 7-5 in points.
        (six0 + _games(*[1] * 6) + tb_games + [0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0], 3, 0, False, 0),
        # Many deuces, no-ad off, then the match continues.
        ([0, 1] * 30 + [1, 1], 3, 0, False, 0),
    ]


def _tt(stations, change, origin, start, *conns):
    conns = sorted(conns, key=lambda c: c[2])
    cols = [list(c) for c in zip(*conns)] if conns else [[], [], [], [], []]
    return (stations, change, origin, start, *cols)


def _timetable_cases():
    # (from, to, dep, arr, train)
    return [
        # One train along four stations.
        _tt(5, 2, 0, 0, (0, 1, 10, 20, 0), (1, 2, 20, 30, 0), (2, 3, 35, 40, 0)),
        # A change needs `change` minutes: 3 is too long for this one, 2 is not.
        _tt(4, 3, 0, 0, (0, 1, 0, 10, 0), (1, 2, 12, 20, 1), (1, 3, 13, 20, 2)),
        _tt(4, 2, 0, 0, (0, 1, 0, 10, 0), (1, 2, 12, 20, 1), (1, 3, 13, 20, 2)),
        # Staying aboard needs no change time; boarding at the origin needs none either.
        _tt(4, 10, 0, 5, (0, 1, 5, 6, 0), (1, 2, 6, 7, 0), (2, 3, 7, 8, 0), (0, 3, 4, 5, 1)),
        # The fewest trains among journeys arriving equally early.
        _tt(4, 0, 0, 0, (0, 1, 0, 5, 0), (1, 3, 5, 9, 1), (0, 2, 0, 3, 2), (2, 3, 4, 9, 3),
            (0, 3, 1, 9, 4)),
        # Earliest wins over fewer trains; the trains count is for the earliest journey.
        _tt(3, 1, 0, 0, (0, 2, 0, 50, 0), (0, 1, 0, 10, 1), (1, 2, 11, 20, 2)),
        # Unreachable stations; a station reached only from a train that left before start.
        _tt(5, 0, 1, 100, (1, 2, 90, 95, 0), (1, 3, 100, 110, 1), (4, 0, 0, 10, 2)),
        # Coming back to the origin changes nothing there.
        _tt(3, 0, 0, 0, (0, 1, 0, 5, 0), (1, 0, 6, 9, 1), (0, 2, 10, 12, 2)),
        # Change time 0: arrive and leave in the same minute.
        _tt(3, 0, 0, 0, (0, 1, 0, 10, 0), (1, 2, 10, 15, 1)),
        # A train calling at a station twice: the first arrival counts.
        _tt(4, 5, 0, 0, (0, 1, 0, 10, 0), (1, 2, 10, 20, 0), (2, 1, 20, 30, 0), (1, 3, 30, 40, 0)),
        # Two connections leaving at the same time, and a longer journey with three changes.
        _tt(6, 1, 2, 0, (2, 0, 0, 5, 0), (2, 1, 0, 4, 1), (1, 3, 5, 8, 2), (0, 3, 6, 7, 3),
            (3, 4, 9, 12, 4), (4, 5, 13, 14, 5)),
        # No connections.
        _tt(2, 0, 1, 0),
    ]


_TOK = {"+": 1, "-": 2, "*": 3, "/": 4, "%": 5, "^": 6, "(": 7, ")": 8, "=": 9, ";": 10}


def _ex(text):
    """expr-eval inputs from text: numbers, x0 to x7, and symbols, separated by spaces."""
    kinds, vals = [], []
    for w in text.split():
        if w in _TOK:
            kinds.append(2)
            vals.append(_TOK[w])
        elif w.startswith("x"):
            kinds.append(1)
            vals.append(int(w[1:]))
        else:
            kinds.append(0)
            vals.append(int(w))
    return kinds, vals


def _expr_cases():
    return [
        # Precedence and grouping: powers to the right, - and / to the left, negation below ^.
        _ex("2 ^ 3 ^ 2 ; - 2 ^ 2 ; 10 - 3 - 2 ; 7 / 2 * 2 ; 2 * 3 + 4 * 5 ; ( 2 + 3 ) * 4"),
        # Rounding toward zero for every sign.
        _ex("0 - 7 / 2 ; ( 0 - 7 ) / 2 ; ( 0 - 7 ) % 2 ; 7 % ( 0 - 2 ) ; 7 / ( 0 - 2 ) ; "
            "( 0 - 7 ) % ( 0 - 2 ) ; - 7 / 2 ; - 7 % 2"),
        # Each error code, with what was assigned before it kept.
        _ex("x1 ; x0 = 5 + ( x1 = 2 ) / 0 ; x2 = 2 ^ - 1 ; x3 = 9999 ^ 4 ; x4 = 9999 ^ 3 ; x0"),
        # Assignment chains and assignment in parentheses.
        _ex("x0 = x1 = 3 ; x2 = ( x3 = 4 ) * x0 ; x2 + x3 + x1"),
        # Statements that do not fit the grammar, and empty statements.
        _ex("3 = 4 ; ; ( 1 + 2 ; 1 2 ; x0 = = 1 ; + 1 ; ( x0 ) = 1 ; x0 = 1 ; ; x0 ^ ; - ; ( ) ;"),
        # Powers of 0, 1 and -1, and the largest powers of 2 within bounds.
        _ex("0 ^ 0 ; 0 ^ 9999 ; 1 ^ 9999 ; ( 0 - 1 ) ^ 9999 ; ( 0 - 1 ) ^ 9998 ; 2 ^ 39 ; 2 ^ 40 ; "
            "( 0 - 2 ) ^ 39 ; 9999 ^ 0"),
        # The bound itself is allowed; one more is not; negation can break the bound too.
        _ex("x0 = 1000 * 1000 ; x0 * x0 ; x0 * x0 + 1 ; 0 - x0 * x0 ; 0 - x0 * x0 - 1 ; "
            "- ( x0 * x0 ) - 1"),
        # Double negation, a negative power after the error, and a variable read before set.
        _ex("- - 3 ; 2 ^ - - 2 ; - 2 ^ - 2 ; x5 = x5 + 1 ; x5"),
        # Left before right: the left error is the one reported.
        _ex("x6 / 0 ; 1 / 0 + x6 ; ( x7 = 0 ) + 1 / x7 ; x7"),
        # A trailing semicolon, and a statement of a single number.
        _ex("42 ;"),
        # No tokens at all.
        ([], []),
    ]


# --- examples --------------------------------------------------------------------

_ORDER_BOOK_EX = _ob((_LIM, _SELL, 101, 5, 1, _GTC), (_LIM, _SELL, 100, 3, 2, _GTC), (_LIM, _BUY, 101, 6, 3, _GTC),
                     (_CXL, 0, 0, 1, 0, 0), (_CXL, 0, 0, 1, 0, 0), (_MKT, _SELL, 1, 4, 3, _IOC),
                     (_LIM, _BUY, 99, 2, 4, _GTC))
_GO_EX = (3, [4, 0, 1, 2, 3, -1, -1])
_STACK_VM_EX = _vm((_PUSH, 6), (_CALL, 6), (_TRY, 9), (_PUSH, 0), (_DIV,), (_HALT,), (_DUP,), (_MUL,), (_RET,),
                   (_PUSH, 1), (_ADD,), limit=100)
_JOSEPHUS_EX = ([7, 10, 1], [3, 2, 5], [2, 10, 1])
_PERM_RANK_EX = ([2, 1, 1], [1, 2, 1], 2)
_WIRE_EX = ([8, 150, 1, 17, 3, 26, 2, 0, 0, 8, 128, 0],)
_TENNIS_EX = ([0, 0, 0, 0] + [0, 0, 0, 0] + [1, 1, 0, 1, 1] + [0, 1, 0, 1, 0, 1, 0, 0] + [0, 1], 3, 0, False, 0)
_TIMETABLE_EX = _tt(4, 2, 0, 5, (0, 1, 5, 10, 0), (1, 2, 11, 20, 1), (1, 2, 12, 18, 2), (0, 2, 6, 19, 3),
                    (2, 3, 20, 30, 4))
_EXPR_EX = _ex("x0 = 7 ; x1 = x0 * 2 - 3 ^ 2 ; x1 / 0 ; - x1 % 3")


# The costliest input for each Firth reference among the inputs `costliest.py
# --candidates` runs (its record is costliest-candidates.tsv): kernel steps
# 223,807 (order-match), 74,975 (go-game), 189,834 (stack-vm), 207,883
# (josephus), 30,421 (perm-rank), 47,341 (wire-decode), 56,746 (tennis),
# 63,753 (timetable) and 56,261 (expr-eval).
_ORDER_BOOK_MAX = _ob(*([(0, 1, 500 + i, 1, i % 10, 0) for i in range(29)] + [(1, 0, 1, 1000, 9, 0)]))
_GO_MAX = _random_go(102, 7, 60)
_STACK_VM_MAX = _random_stack_vm(134, 60, 800)
_JOSEPHUS_MAX = ([10 ** 12, 10 ** 12 - 1, 999_999_999_989], [12] * 3, [200] * 3)
_PERM_RANK_MAX = (list(range(10)) * 2, sorted(list(range(10)) * 2), 10 ** 15)
_WIRE_MAX = ([8, 1] * 100,)
_TENNIS_MAX = _random_tennis(101, 400)
_TIMETABLE_MAX = _random_timetable(114, 60)
_EXPR_MAX = _ex(" ; ".join(["2 ^ 39"] * 10) + " ; 9999 ^ 3 ^ 9")

# The last hidden test of each task is its costliest input (README, "The candidate set").
CANDIDATES: tuple[Task, ...] = (
    _t("order-match", _ORDER_BOOK,
       [("kind", SI), ("side", SI), ("price", SI), ("qty", SI), ("trader", SI), ("tif", SI)],
       [("trades", I), ("volume", I), ("notional", I), ("selfCancelled", I), ("cancels", I),
        ("rejected", I), ("killed", I), ("restingIds", SI), ("restingQty", SI)],
       _order_book, _ORDER_BOOK_EX,
       [*_order_book_cases(), *(_random_order_book(s) for s in (1, 2, 3, 4)), _ORDER_BOOK_MAX],
       ["seq", "nested-loop", "rules", "state", "sort", "heavy"]),
    _t("go-game", _GO_GAME,
       [("size", I), ("moves", SI)],
       [("board", SI), ("blackTook", I), ("whiteTook", I), ("illegal", I), ("read", I), ("score", I)],
       _go_game, _GO_EX,
       [*_go_cases(), *(_random_go(s) for s in (1, 2, 3, 4)), _GO_MAX],
       ["seq", "nested-loop", "rules", "state", "search", "heavy"]),
    _t("stack-vm", _STACK_VM,
       [("ops", SI), ("args", SI), ("limit", I)],
       [("stack", SI), ("status", I), ("uncaught", I), ("steps", I), ("caught", I), ("deepest", I)],
       _stack_vm, _STACK_VM_EX,
       [*_stack_vm_cases(), *(_random_stack_vm(s) for s in (1, 2, 3, 4)), _STACK_VM_MAX],
       ["seq", "loop", "rules", "state", "divmod", "heavy"]),
    _t("josephus", _JOSEPHUS,
       [("n", SI), ("k", SI), ("m", SI)],
       [("survivor", SI), ("removed", SI)],
       _josephus, _JOSEPHUS_EX,
       [*_josephus_cases(), *(_random_josephus(s) for s in (1, 2, 3, 4)), _JOSEPHUS_MAX],
       ["seq", "loop", "divmod", "algorithm", "heavy"]),
    _t("perm-rank", _PERM_RANK,
       [("items", SI), ("perm", SI), ("k", I)],
       [("total", I), ("rank", I), ("kth", SI), ("after", SI)],
       _perm_rank, _PERM_RANK_EX,
       [*_perm_rank_cases(), *(_random_perm_rank(s) for s in (1, 2, 3, 4)), _PERM_RANK_MAX],
       ["seq", "nested-loop", "divmod", "algorithm", "heavy"]),
    _t("wire-decode", _WIRE,
       [("data", SI)],
       [("fields", SI), ("wires", SI), ("values", SI), ("error", I), ("errorAt", I)],
       _wire_decode, _WIRE_EX,
       [*_wire_cases(), *(_random_wire(s) for s in (1, 2, 3, 4)), _WIRE_MAX],
       ["seq", "loop", "rules", "parse", "divmod", "heavy"]),
    _t("tennis", _TENNIS,
       [("points", SI), ("bestOf", I), ("finalSet", I), ("noAd", B), ("server", I)],
       [("sets", SI), ("winner", I), ("read", I), ("current", SI), ("nextServer", I), ("breaks", SI)],
       _tennis, _TENNIS_EX,
       [*_tennis_cases(), *(_random_tennis(s) for s in (1, 2, 3, 4)), _TENNIS_MAX],
       ["seq", "loop", "rules", "state", "heavy"]),
    _t("timetable", _TIMETABLE,
       [("stations", I), ("change", I), ("origin", I), ("start", I), ("fromSt", SI), ("toSt", SI), ("dep", SI),
        ("arr", SI), ("train", SI)],
       [("arrive", SI), ("trains", SI)],
       _timetable, _TIMETABLE_EX,
       [*_timetable_cases(), *(_random_timetable(s) for s in (1, 2, 3, 4)), _TIMETABLE_MAX],
       ["seq", "nested-loop", "rules", "search", "heavy"]),
    _t("expr-eval", _EXPR_EVAL,
       [("kinds", SI), ("vals", SI)],
       [("values", SI), ("codes", SI), ("vars", SI), ("assigned", SB)],
       _expr_eval, _EXPR_EX,
       [*_expr_cases(), *(_random_expr(s) for s in (1, 2, 3, 4)), _EXPR_MAX],
       ["seq", "nested-loop", "rules", "parse", "divmod", "bool-seq", "heavy"]),
)
