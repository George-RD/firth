"""Candidate tasks for the next scored set of the harder S7 tier.

The 2026-10-11 scored set is not reused: the checker's fix hints that followed
that run were built and tested on its programs, so its tasks would test the
hints on their own cases. These nine tasks are new, and none has been sent to a
model. Which six of them become the next scored set is decided by a rule fixed
before any of them is run (`next-run/calibration.md`); the others are kept
here and are never scored.

Three are whole simulations with interacting rules, the genre of the earlier
pools: Go with captures, suicide and ko (`go-game`), tennis scoring with
tiebreaks and serve order (`tennis`) and Kalah sowing with captures and extra
moves (`kalah`). Six are hard in another way: an algorithm, since direct
simulation or enumeration is too slow at the stated sizes (`josephus`,
`perm-rank`); an exact procedure with tie-breaks and edge cases (a Huffman
code built in a stated order, `huffman`; an AVL tree with its rotation and
delete rules, `avl-tree`; list scheduling on several workers, `build-sched`);
and edge cases in a binary format (`wire-decode`).

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


# --- huffman ---------------------------------------------------------------------

def _huffman(freqs, msg):
    n = len(freqs)
    lengths = [0] * n
    used = [s for s in range(n) if freqs[s] > 0]
    if len(used) == 1:
        lengths[used[0]] = 1
    elif used:
        # A node is (weight, key, symbols): key is its smallest symbol.
        nodes = [(freqs[s], s, [s]) for s in used]
        while len(nodes) > 1:
            nodes.sort(key=lambda x: (x[0], x[1]))
            (w1, k1, s1), (w2, k2, s2) = nodes[0], nodes[1]
            for s in s1 + s2:
                lengths[s] += 1
            nodes = nodes[2:] + [(w1 + w2, min(k1, k2), s1 + s2)]
    codes = [-1] * n
    code, prev = -1, 0
    for s in sorted(used, key=lambda s: (lengths[s], s)):
        code = 0 if code == -1 else (code + 1) * 2 ** (lengths[s] - prev)
        prev = lengths[s]
        codes[s] = code
    bits, bad = [], -1
    for i, s in enumerate(msg):
        if not 0 <= s < n or codes[s] == -1:
            bad = i
            break
        bits += [codes[s] // 2 ** (lengths[s] - 1 - j) % 2 for j in range(lengths[s])]
    if bad != -1:
        bits = []
    return lengths, codes, bits, bad


# --- avl-tree --------------------------------------------------------------------

def _avl(ops, keys):
    # A node is [key, left, right, height]; None is empty.
    rotations = ignored = 0
    found = []

    def h(t):
        return t[3] if t else 0

    def fix(t):
        t[3] = 1 + max(h(t[1]), h(t[2]))
        return t

    def rot_right(t):
        nonlocal rotations
        rotations += 1
        l = t[1]
        t[1], l[2] = l[2], t
        fix(t)
        return fix(l)

    def rot_left(t):
        nonlocal rotations
        rotations += 1
        r = t[2]
        t[2], r[1] = r[1], t
        fix(t)
        return fix(r)

    def balance(t):
        fix(t)
        b = h(t[1]) - h(t[2])
        if b == 2:
            if h(t[1][1]) - h(t[1][2]) < 0:
                t[1] = rot_left(t[1])
            return rot_right(t)
        if b == -2:
            if h(t[2][1]) - h(t[2][2]) > 0:
                t[2] = rot_right(t[2])
            return rot_left(t)
        return t

    def insert(t, k):
        nonlocal ignored
        if t is None:
            return [k, None, None, 1]
        if k == t[0]:
            ignored += 1
            return t
        if k < t[0]:
            t[1] = insert(t[1], k)
        else:
            t[2] = insert(t[2], k)
        return balance(t)

    def delete(t, k):
        nonlocal ignored
        if t is None:
            ignored += 1
            return None
        if k < t[0]:
            t[1] = delete(t[1], k)
        elif k > t[0]:
            t[2] = delete(t[2], k)
        elif t[1] is None or t[2] is None:
            return t[1] or t[2]
        else:
            m = t[2]
            while m[1] is not None:
                m = m[1]
            t[0] = m[0]
            t[2] = delete(t[2], m[0])
        return balance(t)

    def has(t, k):
        while t is not None and t[0] != k:
            t = t[1] if k < t[0] else t[2]
        return t is not None

    root = None
    for op, k in zip(ops, keys):
        if op == 0:
            root = insert(root, k)
        elif op == 1:
            root = delete(root, k)
        else:
            found.append(has(root, k))
    pre = []

    def walk(t):
        if t:
            pre.append(t[0])
            walk(t[1])
            walk(t[2])
    walk(root)
    return pre, found, rotations, ignored, h(root)


# --- kalah -----------------------------------------------------------------------

def _kalah(pits, seeds, moves):
    p = pits
    board = [seeds] * p + [0] + [seeds] * p + [0]
    store = (p, 2 * p + 1)
    player, illegal, read, over = 0, 0, 0, False
    took = [0, 0]
    for mv in moves:
        if over:
            break
        read += 1
        if not 0 <= mv < p or board[player * (p + 1) + mv] == 0:
            illegal += 1
            continue
        i = player * (p + 1) + mv
        hand, board[i] = board[i], 0
        while hand:
            i = (i + 1) % (2 * p + 2)
            if i == store[1 - player]:
                continue
            board[i] += 1
            hand -= 1
        mine = range(player * (p + 1), player * (p + 1) + p)
        if i in mine and board[i] == 1:
            opp = 2 * p - i
            if board[opp] > 0:
                took[player] += board[opp] + 1
                board[store[player]] += board[opp] + 1
                board[i] = board[opp] = 0
        if all(board[j] == 0 for j in range(p)) or all(board[j] == 0 for j in range(p + 1, 2 * p + 1)):
            for side in (0, 1):
                for j in range(side * (p + 1), side * (p + 1) + p):
                    board[store[side]] += board[j]
                    board[j] = 0
            over = True
        elif i != store[player]:
            player = 1 - player
    if over:
        a, b = board[p], board[2 * p + 1]
        winner, nxt = (0 if a > b else 1 if b > a else 2), -1
    else:
        winner, nxt = -1, player
    return board, nxt, illegal, read, took, winner


# --- build-sched -----------------------------------------------------------------

def _build_sched(dur, before, after, prio, workers):
    n = len(dur)
    start, who, finish = [-1] * n, [-1] * n, [-1] * n
    busy = [-1] * workers           # the task each worker runs, or -1
    t = 0
    idle = 0
    while True:
        for w in range(workers):
            if busy[w] != -1 and finish[busy[w]] == t:
                busy[w] = -1
        ready = [i for i in range(n) if start[i] == -1
                 and all(finish[a] != -1 and finish[a] <= t for a, b in zip(before, after) if b == i)]
        ready.sort(key=lambda i: (-prio[i], -dur[i], i))
        for w in range(workers):
            if busy[w] == -1 and ready:
                i = ready.pop(0)
                start[i], who[i], finish[i] = t, w, t + dur[i]
                busy[w] = i
        running = [finish[busy[w]] for w in range(workers) if busy[w] != -1]
        if not running:
            break
        nxt = min(running)
        idle += sum(1 for w in range(workers) if busy[w] == -1) * (nxt - t)
        t = nxt
    makespan = max(finish) if max(finish) > 0 else 0
    return start, who, makespan, idle, start.count(-1)


# --- descriptions ----------------------------------------------------------------

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

_HUFFMAN = (
    "Build a Huffman code and encode a message. freqs[s] is the frequency of symbol s, for "
    "s from 0 to n - 1, where n is the length of freqs. Only symbols with a frequency above "
    "0 get a code. If no symbol does, no symbol has a code; if exactly one does, its code "
    "length is 1. Otherwise build a tree: start with one node for each such symbol, weighing "
    "its frequency, and while there is more than one node, take the two nodes that come "
    "first when ordered by weight, lowest first, and between equal weights by the smallest "
    "symbol the node holds, lowest first, and replace them by one node weighing their sum and "
    "holding the symbols of both. A symbol's code length is the number of times a node "
    "holding it was taken. Then give the codes in canonical form: list the symbols that have "
    "a code by length, shortest first, and between equal lengths by symbol, lowest first; the "
    "first gets code 0, and each next one gets the previous one's code plus 1, multiplied by 2 "
    "once for each bit by which its length exceeds the previous one's. Encode msg, a list of "
    "symbols, by writing each symbol's code in as many bits as its length, most significant "
    "bit first, one symbol after another. Return each symbol's code length (0 if it has no "
    "code), each symbol's code (-1 if it has none), the encoded bits as 0s and 1s, and -1; "
    "or, if a value in msg is not 0 to n - 1 or is a symbol with no code, the lengths, the "
    "codes, no bits, and the position in msg of the first such value. freqs has 1 to 20 "
    "values, each 0 to 1,000,000; msg has at most 100 values, each -5 to 45."
)

_AVL = (
    "Run operations on an AVL tree of distinct keys, starting empty, and report the final "
    "tree. Operation i is ops[i] with the key keys[i]: 0 insert, 1 delete, 2 look up. A "
    "node's height is 1 more than the larger of its two subtrees' heights (an empty subtree "
    "has height 0), and its balance is its left subtree's height minus its right subtree's. "
    "Insert: if the key is in the tree, the operation is ignored; otherwise go down from the "
    "root, left where the key is smaller than the node's and right where it is larger, and "
    "add a node with the key where the path leaves the tree. Delete: if the key is not in the "
    "tree, the operation is ignored; otherwise, if its node has at most one child, replace "
    "the node by that child (or by nothing); if it has two, copy the smallest key of its "
    "right subtree into it and delete that key from the right subtree in the same way. After "
    "an insert or delete, go back up the path from where a node was added or removed to the "
    "root, and at each node on it recompute its height and rebalance it: if its balance is "
    "2, first rotate its left child left if that child's balance is negative, then rotate "
    "the node right; if its balance is -2, first rotate its right child right if that "
    "child's balance is positive, then rotate the node left. Rotating a node right makes its "
    "left child the root of that subtree, with the node as the child's right child and the "
    "child's old right subtree as the node's left subtree; rotating left is the mirror image. "
    "A look up adds true to the results if the key is in the tree and false if not. Return "
    "the final tree's keys in preorder (a node, then its left subtree, then its right "
    "subtree), the look-up results in order, the number of rotations made (a rotation of a "
    "child and then of the node counts as two), the number of operations ignored, and the "
    "final tree's height. ops and keys have the same length, at most 60; each op is 0 to 2 "
    "and each key 0 to 999."
)

_KALAH = (
    "Play the sowing game Kalah and report the position. Each player has pits pits and a "
    "store: positions 0 to pits - 1 are player 0's pits, position pits is player 0's store, "
    "positions pits + 1 to 2 pits are player 1's pits, and position 2 pits + 1 is player 1's "
    "store. The pit at position j is opposite the pit at position 2 pits - j. Every pit "
    "starts with seeds seeds, and both stores start empty. Player 0 moves first. Read the "
    "moves in order. A move is j, meaning the mover's own j-th pit (position j for player 0, "
    "pits + 1 + j for player 1). If j is not 0 to pits - 1, or that pit is empty, the move "
    "is illegal: it is counted, and the same player moves next. Otherwise take all the seeds "
    "from the pit and sow them one at a time into the following positions in increasing "
    "order, going from 2 pits + 1 back to 0 and skipping the opponent's store. If the last "
    "seed lands in one of the mover's own pits that was empty before it (the pit just "
    "emptied counts as empty) and the opposite pit has seeds, the mover takes that seed and "
    "all the seeds of the opposite pit into their own store (a capture). Then, if all of "
    "either player's pits are empty, the game ends: each player moves the seeds left in "
    "their own pits into their own store, and no more moves are read. Otherwise, if the last "
    "seed landed in the mover's own store, the mover moves again, and if not, the other "
    "player moves next. Return the board (all 2 pits + 2 positions), the player to move next "
    "(-1 if the game has ended), the number of illegal moves, the number of moves read, the "
    "seeds each player took by captures (player 0's, then player 1's), and the winner: the "
    "player with the larger store, 2 if the stores are equal, or -1 if the game has not "
    "ended. pits is 1 to 6, seeds is 1 to 6, and moves has at most 80 values, each -1 to 7."
)

_SCHED = (
    "Schedule tasks that depend on each other on a number of workers. Task i takes dur[i] "
    "time units and has priority prio[i]; for each k, task before[k] must finish before task "
    "after[k] can start (a task may be given as depending on itself, and a pair may be "
    "repeated). The workers are numbered 0 to workers - 1, and time starts at 0. At time 0, "
    "and at each later moment when a running task finishes: first every worker whose task "
    "finishes then is free; a task is ready if it has not started and every task it depends "
    "on has finished at or before this moment; then, while some worker is free and some task "
    "is ready, the free worker with the lowest number starts the ready task with the highest "
    "priority, between equal priorities the one that takes longest, and between equal "
    "lengths the lowest-numbered, and it finishes dur time units later. Then time moves on "
    "to the next moment a running task finishes; when no task is running, the schedule ends, "
    "and a task that never became ready never starts. Return each task's start time and "
    "worker (-1 and -1 for a task that never started), the makespan (the latest finish, or "
    "0 if no task started), the idle time (summed over the workers, the time between 0 and "
    "the makespan when a worker had no task), and the number of tasks that never started. "
    "dur and prio have the same length, 1 to 16; each dur is 1 to 20 and each prio 0 to 9. "
    "before and after have the same length, at most 30, and each is a task number."
)

# --- random inputs ---------------------------------------------------------------

def _random_go(seed, size=None, n=None):
    rng = random.Random(seed)
    size = rng.randint(2, 7) if size is None else size
    n = rng.randint(0, 60) if n is None else n
    moves = []
    for _ in range(n):
        moves.append(-1 if rng.random() < 0.06 else rng.randrange(size * size))
    return size, moves


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


def _random_huffman(seed, n=None, m=None):
    rng = random.Random(seed)
    n = rng.randint(1, 20) if n is None else n
    shape = rng.random()
    if shape < 0.3:     # powers and Fibonacci-like weights make long codes
        freqs = [rng.choice((0, 1, 2 ** rng.randint(0, 19))) for _ in range(n)]
    elif shape < 0.6:   # many equal weights test the tie-break
        w = rng.randint(1, 5)
        freqs = [rng.choice((0, w, w, 2 * w)) for _ in range(n)]
    else:
        freqs = [rng.choice((0, rng.randint(1, 1_000_000), rng.randint(1, 30))) for _ in range(n)]
    m = rng.randint(0, 100) if m is None else m
    has = [s for s in range(n) if freqs[s] > 0] or [0]
    msg = [rng.choice(has) for _ in range(m)]
    if msg and rng.random() < 0.15:
        msg[rng.randrange(len(msg))] = rng.choice((-1, n, 45, rng.randrange(n)))
    return freqs, msg


def _random_avl(seed, n=None):
    rng = random.Random(seed)
    n = rng.randint(0, 60) if n is None else n
    span = rng.choice((10, 30, 1000))
    ops, keys = [], []
    for _ in range(n):
        ops.append(rng.choices((0, 1, 2), (5, 3, 2))[0])
        keys.append(rng.randrange(span))
    return ops, keys


def _random_kalah(seed, n=None, pits=None, seeds=None):
    rng = random.Random(seed)
    pits = rng.randint(1, 6) if pits is None else pits
    seeds = rng.randint(1, 6) if seeds is None else seeds
    n = rng.randint(0, 80) if n is None else n
    return pits, seeds, [rng.randint(-1, 7) if rng.random() < 0.08 else rng.randrange(pits) for _ in range(n)]


def _random_sched(seed, n=None, e=None):
    rng = random.Random(seed)
    n = rng.randint(1, 16) if n is None else n
    e = rng.randint(0, 30) if e is None else e
    dur = [rng.randint(1, 20) for _ in range(n)]
    prio = [rng.randint(0, rng.choice((0, 2, 9))) for _ in range(n)]
    before, after = [], []
    for _ in range(e):
        a, b = rng.randrange(n), rng.randrange(n)
        if rng.random() < 0.9 and a > b:
            a, b = b, a
        if rng.random() < 0.9 and a == b:
            continue
        before.append(a)
        after.append(b)
    return dur, before, after, prio, rng.randint(1, 4)


# --- hand-picked hidden tests ----------------------------------------------------

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


def _fib(k):
    a, b, out = 1, 1, []
    for _ in range(k):
        out.append(a)
        a, b = b, a + b
    return out


def _huffman_cases():
    return [
        # One symbol with a frequency: length 1, code 0.
        ([0, 7, 0], [1, 1]),
        # No symbol has a frequency: the first symbol of msg has no code; an empty msg is fine.
        ([0, 0, 0], [0]),
        ([0, 0], []),
        # Equal weights: the tie-break by smallest symbol decides every merge.
        ([1, 1, 1, 1, 1], [0, 1, 2, 3, 4]),
        # A merged node and a leaf of equal weight: the merged node holds symbol 0, so it
        # is taken before the leaf 2.
        ([1, 1, 2, 2], [3, 2, 1, 0]),
        # The same with the merged node's smallest symbol larger than the leaf's.
        ([2, 1, 1, 2], [0, 1, 2, 3]),
        # Fibonacci weights: a code 19 bits long.
        (_fib(20), [0, 19, 1, 18]),
        # Powers of two with zeros between: lengths 1 to 9.
        ([2 ** (k // 2) if k % 2 == 0 else 0 for k in range(20)], [18, 0, 2]),
        # Bad symbols: one with no code, one past the end, a negative one.
        ([3, 0, 3, 1], [0, 2, 1, 3]),
        ([3, 0, 3, 1], [0, 3, 4]),
        ([3, 0, 3, 1], [-1]),
        # Twenty symbols, all used, and a long message.
        ([s % 7 + 1 for s in range(20)], [s * 13 % 20 for s in range(100)]),
    ]


def _avl_cases():
    I, D, L = 0, 1, 2
    def run(*pairs):
        return [p[0] for p in pairs], [p[1] for p in pairs]
    return [
        # Nothing at all; a look-up in an empty tree.
        ([], []),
        run((L, 5)),
        # Ascending inserts: left rotations; descending: right rotations.
        run(*[(I, k) for k in range(1, 8)]),
        run(*[(I, k) for k in range(7, 0, -1)]),
        # Zig-zags: a right-left and a left-right double rotation.
        run((I, 1), (I, 3), (I, 2)),
        run((I, 3), (I, 1), (I, 2)),
        # A duplicate insert and deleting a missing key are ignored.
        run((I, 4), (I, 4), (D, 9), (I, 2), (D, 2), (D, 2)),
        # Deleting a leaf leaves the heavy child with balance 0: a single rotation.
        run((I, 2), (I, 1), (I, 4), (I, 3), (I, 5), (D, 1)),
        run((I, 4), (I, 5), (I, 2), (I, 1), (I, 3), (D, 5)),
        # Deleting a node with two children takes the smallest key on its right.
        run((I, 5), (I, 3), (I, 8), (I, 1), (I, 4), (I, 7), (I, 9), (D, 5), (L, 5), (L, 7)),
        # The successor has a right child, and its removal unbalances the tree.
        run((I, 10), (I, 5), (I, 20), (I, 3), (I, 15), (I, 30), (I, 17), (I, 2), (D, 10), (D, 3)),
        # Delete everything, root first, then insert again.
        run(*[(I, k) for k in (50, 20, 80, 10, 30, 70, 90)], *[(D, k) for k in (50, 70, 80, 90, 20, 30, 10)],
            (I, 999), (I, 0), (L, 999), (L, 50)),
    ]


def _kalah_cases():
    return [
        # One pit each: the seed goes into player 0's store, player 0's side is empty, and
        # player 1's seed is swept into player 1's store: a draw.
        (1, 1, [0]),
        # Three seeds in one pit go round past player 1's pit and back into the pit just
        # emptied: a capture of the opposite pit, and the game ends.
        (1, 3, [0]),
        # A last seed in the mover's store gives another move; then sowing passes player
        # 1's pits.
        (3, 3, [0, 1, 0, 2]),
        # Illegal moves: an empty pit, -1 and 7; the same player moves after each.
        (3, 1, [0, 0, 0, -1, 7, 2, 1]),
        # Player 1's last seed lands in its own empty pit, opposite player 0's empty pit:
        # no capture.
        (2, 1, [0, 1, 0]),
        # Many seeds: one pit sows more than a lap and skips the opponent's store.
        (2, 6, [0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0]),
        # Moves after the end are not read.
        (1, 1, [0, 0, 0, 0, 0]),
        # Six pits of six seeds: a long game.
        (6, 6, [2, 5, 0, 1, 3, 4, 2, 5, 0, 3, 1, 4, 5, 2, 0, 1, 3, 5, 4, 0, 2, 1, 5, 3, 0, 4, 2, 1, 5, 0]),
    ]


def _sched_cases():
    return [
        # One task, one worker.
        ([5], [], [], [0], 1),
        # A cycle never starts, nor the task after it; the third task runs.
        ([1, 1, 1, 2], [0, 1, 1], [1, 0, 3], [0, 0, 0, 0], 2),
        # A task that depends on itself never starts.
        ([3, 2], [0], [0], [0, 0], 1),
        # Equal priority: the longer first; equal length: the lower number first.
        ([2, 5, 2, 5], [], [], [1, 1, 1, 1], 1),
        # Priority beats length.
        ([9, 1, 4], [], [], [0, 3, 1], 1),
        # A dependency finishing at the moment a worker frees: the task starts then.
        ([2, 2, 3], [0], [2], [0, 0, 9], 2),
        # More workers than tasks: idle time, and the lowest free worker takes each task.
        ([4, 1, 2], [1], [2], [0, 0, 0], 4),
        # Repeated edges, and a chain that leaves workers waiting.
        ([3, 3, 3, 1], [0, 0, 1, 2], [1, 1, 2, 3], [0, 0, 0, 0], 3),
        # Sixteen tasks in layers on two workers.
        ([(i * 7) % 20 + 1 for i in range(16)], [i for i in range(12)], [i + 4 for i in range(12)],
         [i % 3 for i in range(16)], 2),
    ]


# --- examples --------------------------------------------------------------------

_GO_EX = (3, [4, 0, 1, 2, 3, -1, -1])
_JOSEPHUS_EX = ([7, 10, 1], [3, 2, 5], [2, 10, 1])
_PERM_RANK_EX = ([2, 1, 1], [1, 2, 1], 2)
_WIRE_EX = ([8, 150, 1, 17, 3, 26, 2, 0, 0, 8, 128, 0],)
_TENNIS_EX = ([0, 0, 0, 0] + [0, 0, 0, 0] + [1, 1, 0, 1, 1] + [0, 1, 0, 1, 0, 1, 0, 0] + [0, 1], 3, 0, False, 0)
_HUFFMAN_EX = ([5, 9, 12, 13, 16, 45], [0, 5, 1])
_AVL_EX = ([0, 0, 0, 0, 0, 1, 2, 2], [3, 2, 1, 4, 5, 2, 2, 4])
_KALAH_EX = (3, 3, [0, 1, 2, 5])
_SCHED_EX = ([3, 2, 4, 1], [0, 0], [2, 3], [0, 1, 0, 5], 2)


# The costliest input for each Firth reference among the inputs `costliest.py
# --candidates` runs (its record is costliest-candidates.tsv): kernel steps
# 74,975 (go-game), 207,883 (josephus), 36,355 (perm-rank, one of its hand
# cases, so it is moved to the end rather than repeated), 47,341 (wire-decode),
# 56,746 (tennis), 194,148 (huffman), 98,368 (avl-tree), 58,192 (kalah) and
# 89,832 (build-sched).
_GO_MAX = _random_go(102, 7, 60)
_JOSEPHUS_MAX = ([10 ** 12, 10 ** 12 - 1, 999_999_999_989], [12] * 3, [200] * 3)
_PERM_RANK_MAX = _perm_rank_cases()[10]
_WIRE_MAX = ([8, 1] * 100,)
_TENNIS_MAX = _random_tennis(101, 400)
_HUFFMAN_MAX = (_fib(20), [0] * 100)
_AVL_MAX = ([0] * 40 + [1] * 20, list(range(40)) + list(range(39, 19, -1)))
_KALAH_MAX = _random_kalah(109, 80, 6, 6)
_SCHED_MAX = ([1 + i % 20 for i in range(16)], [i % 15 for i in range(30)], [i % 15 + 1 for i in range(30)],
              [5] * 16, 4)

# The last hidden test of each task is its costliest input (README, "The candidate set").
CANDIDATES: tuple[Task, ...] = (
    _t("go-game", _GO_GAME,
       [("size", I), ("moves", SI)],
       [("board", SI), ("blackTook", I), ("whiteTook", I), ("illegal", I), ("read", I), ("score", I)],
       _go_game, _GO_EX,
       [*_go_cases(), *(_random_go(s) for s in (1, 2, 3, 4)), _GO_MAX],
       ["seq", "nested-loop", "rules", "state", "search", "heavy"]),
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
       [*(c for c in _perm_rank_cases() if c != _PERM_RANK_MAX), *(_random_perm_rank(s) for s in (1, 2, 3, 4)),
        _PERM_RANK_MAX],
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
    _t("huffman", _HUFFMAN,
       [("freqs", SI), ("msg", SI)],
       [("lengths", SI), ("codes", SI), ("bits", SI), ("bad", I)],
       _huffman, _HUFFMAN_EX,
       [*_huffman_cases(), *(_random_huffman(s) for s in (1, 2, 3, 4)), _HUFFMAN_MAX],
       ["seq", "nested-loop", "algorithm", "sort", "divmod", "heavy"]),
    _t("avl-tree", _AVL,
       [("ops", SI), ("keys", SI)],
       [("preorder", SI), ("found", SB), ("rotations", I), ("ignored", I), ("height", I)],
       _avl, _AVL_EX,
       [*_avl_cases(), *(_random_avl(s) for s in (1, 2, 3, 4)), _AVL_MAX],
       ["seq", "loop", "algorithm", "rules", "recursion", "heavy"]),
    _t("kalah", _KALAH,
       [("pits", I), ("seeds", I), ("moves", SI)],
       [("board", SI), ("toMove", I), ("illegal", I), ("read", I), ("took", SI), ("winner", I)],
       _kalah, _KALAH_EX,
       [*_kalah_cases(), *(_random_kalah(s) for s in (1, 2, 3, 4)), _KALAH_MAX],
       ["seq", "loop", "rules", "state", "heavy"]),
    _t("build-sched", _SCHED,
       [("dur", SI), ("before", SI), ("after", SI), ("prio", SI), ("workers", I)],
       [("start", SI), ("worker", SI), ("makespan", I), ("idle", I), ("unrun", I)],
       _build_sched, _SCHED_EX,
       [*_sched_cases(), *(_random_sched(s) for s in (1, 2, 3, 4)), _SCHED_MAX],
       ["seq", "nested-loop", "rules", "state", "sort", "heavy"]),
)
