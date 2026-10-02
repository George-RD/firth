"""The calibration pool of the harder S7 tier (`todo.s7-harder-task-tier`).

These tasks are for calibration only: they are run to find out whether the
planned primary subject sits at the ceiling on tasks of this kind, and they
are never scored. The scored tier is a different, frozen set, written after
calibration and before any scored trial, so no task is swapped out after a
ceiling result.

The pool spans seven kinds of difficulty, one task each, plus a second
dynamic-programming task: a rule-heavy classic (`bowling`), a stateful
simulation (`lru`), an evaluator with error codes (`rpn`), a two-dimensional
dynamic program (`edit-cost`), a graph search with a tie-break (`shortest-hops`),
sorting then merging with three outputs (`merge-ranges`), an interpreter at
allocator weight (`tiny-vm`) and a reconstruction with a tie-break
(`lis-smallest`). Every description states its input bounds, so an author
can tell whether a quadratic loop fits the step budget.

Each `ref` is the task's meaning, written in plain Python independently of
any Firth code. Hidden inputs are scored against it and never shown to the
author. `test_harder.py` checks the refs against values worked out by hand.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from task import Task, _t  # noqa: E402

I, B, SI, SB = "Int", "Bool", "Seq Int", "Seq Bool"


def _bowling(rolls):
    out, i, total = [], 0, 0
    for _ in range(10):
        if rolls[i] == 10:
            total += 10 + rolls[i + 1] + rolls[i + 2]
            i += 1
        elif rolls[i] + rolls[i + 1] == 10:
            total += 10 + rolls[i + 2]
            i += 2
        else:
            total += rolls[i] + rolls[i + 1]
            i += 2
        out.append(total)
    return (out,)


def _lru(cap, keys):
    cache, misses = [], 0
    for k in keys:
        if k in cache:
            cache.remove(k)
        else:
            misses += 1
            if len(cache) == cap:
                cache.pop(0)
        cache.append(k)
    return misses, cache


def _quot(a, b):
    q = abs(a) // abs(b)
    return q if (a < 0) == (b < 0) else -q


def _rpn(kinds, vals):
    stack = []
    for kind, v in zip(kinds, vals):
        if kind == 0:
            stack.append(v)
            continue
        need = 1 if kind == 5 else 2
        if len(stack) < need:
            return 0, 1
        if kind == 5:
            stack.append(stack[-1])
            continue
        b, a = stack.pop(), stack.pop()
        if kind == 4 and b == 0:
            return 0, 2
        stack.append({1: a + b, 2: a - b, 3: a * b, 4: _quot(a, b) if b else 0}[kind])
    return (stack[0], 0) if len(stack) == 1 else (0, 3)


def _edit_cost(xs, ys, insert, delete, replace):
    prev = [j * insert for j in range(len(ys) + 1)]
    for i, x in enumerate(xs, 1):
        cur = [i * delete]
        for j, y in enumerate(ys, 1):
            cur.append(min(prev[j] + delete, cur[j - 1] + insert, prev[j - 1] + (0 if x == y else replace)))
        prev = cur
    return (prev[-1],)


def _shortest_hops(n, froms, tos, weights, source):
    INF = None
    best = [INF] * n  # (distance, hops)
    best[source] = (0, 0)
    for _ in range(n):
        for a, b, w in zip(froms, tos, weights):
            if best[a] is not None:
                cand = (best[a][0] + w, best[a][1] + 1)
                if best[b] is None or cand < best[b]:
                    best[b] = cand
    return ([-1 if p is None else p[0] for p in best], [-1 if p is None else p[1] for p in best])


def _merge_ranges(starts, ends):
    rs = sorted(zip(starts, ends))
    out_s, out_e = [], []
    for s, e in rs:
        if out_s and s <= out_e[-1] + 1:
            out_e[-1] = max(out_e[-1], e)
        else:
            out_s.append(s)
            out_e.append(e)
    return out_s, out_e, sum(e - s + 1 for s, e in zip(out_s, out_e))


def _tiny_vm(code, regs, limit):
    r, pc, steps = list(regs), 0, 0
    n = len(code) // 3
    while True:
        if not 0 <= pc < n:
            return r, steps, 1
        if steps == limit:
            return r, steps, 2
        op, a, b = code[3 * pc:3 * pc + 3]
        steps += 1
        pc += 1
        if op == 0:
            return r, steps, 0
        if op == 1:
            r[a] = b
        elif op == 2:
            r[a] += r[b]
        elif op == 3:
            r[a] -= r[b]
        elif op == 4:
            r[a] *= r[b]
        elif op == 5:
            r[a] = r[b]
        elif op == 6:
            if r[a] != 0:
                pc = b
        elif op == 7:
            if r[a] < 0:
                pc = b


def _lis_smallest(xs):
    n = len(xs)
    after = [1] * n  # length of the longest increasing subsequence starting at i
    for i in range(n - 1, -1, -1):
        for j in range(i + 1, n):
            if xs[j] > xs[i]:
                after[i] = max(after[i], 1 + after[j])
    out, need, last, start = [], max(after, default=0), None, 0
    while need:
        pick = None
        for j in range(start, n):
            if after[j] == need and (last is None or xs[j] > last) and (pick is None or xs[j] < xs[pick]):
                pick = j
        out.append(xs[pick])
        last, start, need = xs[pick], pick + 1, need - 1
    return (out,)


CALIBRATION: tuple[Task, ...] = (
    _t("bowling",
       "rolls lists the pins knocked down by each roll of one complete, valid game of "
       "ten-pin bowling. A game has ten frames. In frames 1 to 9, a first roll of 10 is a "
       "strike and ends the frame; otherwise the frame has two rolls. A frame scores its "
       "pins plus a bonus: after a strike, the pins of the next two rolls; after a spare "
       "(two rolls in one frame totalling 10), the pins of the next roll. The tenth frame "
       "has a third roll only when its first two rolls make a strike or a spare; those "
       "extra rolls count once, as the tenth frame's bonus. Return the running total after "
       "each frame (ten numbers).",
       [("rolls", SI)], [("totals", SI)], _bowling,
       ([10, 7, 3, 9, 0, 10, 0, 8, 8, 2, 0, 6, 10, 10, 10, 8, 1],),
       [([0] * 20,),
        ([10] * 12,),
        ([5] * 21,),
        ([1, 4, 4, 5, 6, 4, 5, 5, 10, 0, 1, 7, 3, 6, 4, 10, 2, 8, 6],),
        ([3, 4] * 9 + [10, 10, 10],),
        ([3, 4] * 9 + [7, 3, 10],),
        ([3, 4] * 9 + [10, 3, 5],),
        ([10, 10, 10, 10, 10, 10, 10, 10, 10, 9, 1, 0],),
        ([0, 10, 10, 0, 10] + [0, 0] * 6 + [10, 0, 10],),
        ([9, 1] * 10 + [9],),
        ([10, 0, 0] + [1, 1] * 8,)],
       ["seq", "loop", "rules"]),
    _t("lru",
       "A cache holds at most cap distinct keys (cap is at least 1). Process keys in order. "
       "If a key is in the cache, it is a hit and becomes the most recently used key. "
       "Otherwise it is a miss: if the cache already holds cap keys, the least recently "
       "used key is removed first, then the key is added as the most recently used. The "
       "cache starts empty. Return the number of misses and the keys left in the cache, "
       "from least to most recently used. keys has at most 60 elements.",
       [("cap", I), ("keys", SI)], [("misses", I), ("cache", SI)], _lru,
       (2, [1, 2, 1, 3, 2]),
       [(1, []),
        (1, [5, 5, 5]),
        (1, [1, 2, 1, 2]),
        (3, [1, 2, 3, 4, 1, 2, 5, 1, 2, 3, 4, 5]),
        (4, [1, 2, 3, 4, 1, 2, 5, 1, 2, 3, 4, 5]),
        (5, [7, 3, 7, 3, 7]),
        (2, [-1, 0, -1, 2, 0, -1]),
        (3, [4, 4, 1, 4, 2, 3, 1, 4, 2, 2, 5, 3]),
        (6, [i % 7 for i in range(40)] + [3, 1, 4, 1, 5, 9, 2, 6]),
        (3, [9, 8, 7, 8, 9, 6, 9, 8, 7, 6, 5, 9, 9, 7])],
       ["seq", "loop", "state"]),
    _t("rpn",
       "Evaluate a program for a stack calculator. Token i is kinds[i] and vals[i] (the two "
       "sequences have the same length). Kinds: 0 pushes vals[i]; 1 to 4 pop b (the top), "
       "then a, and push a + b, a - b, a * b, or a divided by b with the quotient rounded "
       "toward zero (-7 and 2 give -3); 5 pushes a copy of the top value. vals[i] is used "
       "only by kind 0. Stop at the first error. Return (result, status): status 1 when a "
       "token needs more values than the calculator's stack holds, 2 when a division has b "
       "= 0, and, after the last token, 3 when the stack does not hold exactly one value. "
       "With status 1, 2 or 3, result is 0. Otherwise status is 0 and result is the one "
       "value left.",
       [("kinds", SI), ("vals", SI)], [("result", I), ("status", I)], _rpn,
       ([0, 0, 0, 3, 1], [2, 3, 4, 0, 0]),
       [([], []),
        ([0], [42]),
        ([0, 0], [1, 2]),
        ([1], [0]),
        ([0, 1], [5, 0]),
        ([5, 0], [0, 1]),
        ([0, 0, 4], [-7, 2, 0]),
        ([0, 0, 4], [7, -2, 0]),
        ([0, 0, 4], [-8, -3, 0]),
        ([0, 0, 4], [-1, 5, 0]),
        ([0, 0, 4, 0, 1], [5, 0, 0, 1, 0]),
        ([0, 5, 3, 5, 3, 0, 2], [3, 0, 0, 0, 0, 80, 0]),
        ([0, 0, 2, 0, 0, 0, 3, 3, 0, 4, 1], [10, 4, 0, 2, 3, -1, 0, 0, -5, 0, 0]),
        ([0, 0, 3, 0, 2], [100000, 100000, 0, 1, 0]),
        ([0, 0, 0, 1], [1, 2, 3, 0])],
       ["seq", "loop", "rules", "divmod"]),
    _t("edit-cost",
       "Return the least total cost of turning xs into ys with these edits: inserting one "
       "element costs insert, deleting one costs delete, and replacing one element with a "
       "different value costs replace. insert, delete and replace are each at least 1. Each sequence has "
       "at most 25 elements.",
       [("xs", SI), ("ys", SI), ("insert", I), ("delete", I), ("replace", I)], [("cost", I)], _edit_cost,
       ([1, 2, 3], [1, 3, 4], 1, 1, 1),
       [([], [], 3, 4, 5),
        ([], [1, 2, 3], 2, 7, 1),
        ([4, 4], [], 2, 7, 1),
        ([1, 2, 3], [3, 2, 1], 1, 1, 1),
        ([1, 2, 3], [1, 9, 3], 1, 1, 5),
        ([1, 2, 3], [1, 9, 3], 3, 3, 5),
        ([5, 6, 7, 8], [6, 7, 8, 9], 2, 2, 1),
        ([1, 1, 1, 1], [1, 1], 1, 3, 1),
        ([3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9],
         [2, 7, 1, 8, 2, 8, 1, 8, 2, 8, 4, 5, 9], 2, 3, 4),
        (list(range(20)), list(range(5, 25)), 1, 1, 1),
        ([i % 4 for i in range(25)], [i % 5 for i in range(25)], 3, 2, 4)],
       ["seq", "nested-loop", "cmp", "dp"]),
    _t("shortest-hops",
       "A directed graph has nodes 0 to n - 1 and edges froms[k] -> tos[k] of weight "
       "weights[k] (the three sequences have the same length; weights are 0 or more; there "
       "can be several edges between two nodes). For every node, find the least total "
       "weight of a path from source to it and, among the paths with that weight, the "
       "fewest edges. Return both as sequences of length n: dist[v] and hops[v], each -1 "
       "when v cannot be reached. The source has distance 0 and 0 hops. n is at most 12 "
       "and there are at most 40 edges.",
       [("n", I), ("froms", SI), ("tos", SI), ("weights", SI), ("source", I)],
       [("dist", SI), ("hops", SI)], _shortest_hops,
       (4, [0, 0, 1, 2], [1, 2, 3, 3], [1, 4, 1, 1], 0),
       [(1, [], [], [], 0),
        (3, [], [], [], 1),
        (3, [0, 1], [1, 2], [5, 5], 2),
        (3, [0, 1, 0], [1, 2, 2], [0, 0, 0], 0),
        (4, [0, 1, 2, 0], [1, 2, 3, 3], [1, 1, 1, 3], 0),
        (4, [0, 1, 2, 0], [1, 2, 3, 3], [1, 1, 1, 4], 0),
        (5, [0, 0, 1, 2, 3, 3], [1, 2, 3, 3, 4, 4], [2, 2, 0, 0, 7, 3], 0),
        (5, [0, 1, 2, 3, 4], [1, 2, 3, 4, 0], [1, 1, 1, 1, 1], 3),
        (6, [0, 0, 1, 1, 2, 4, 3, 5], [1, 2, 3, 4, 4, 3, 5, 0], [3, 1, 1, 0, 2, 0, 0, 1], 0),
        (4, [0, 0, 1, 1], [1, 1, 2, 2], [5, 2, 3, 1], 0),
        (12, [i for i in range(11)] + [0, 2, 4, 6, 8, 0, 5, 10] + [11, 3],
         [i + 1 for i in range(11)] + [2, 4, 6, 8, 10, 5, 10, 11] + [0, 0],
         [1] * 11 + [2, 2, 2, 2, 2, 5, 5, 1] + [1, 1], 0)],
       ["seq", "nested-loop", "cmp", "graph"]),
    _t("merge-ranges",
       "Range k covers the whole numbers from starts[k] to ends[k], both included (the two "
       "sequences have the same length, and starts[k] <= ends[k]); the ranges are in no "
       "particular order. Merge ranges that overlap or are next to each other (as 1 to 3 "
       "and 4 to 6 are) until no two of them do. Return the merged ranges' starts and ends, "
       "ordered by start, and how many whole numbers they cover in all. There are at most "
       "30 ranges.",
       [("starts", SI), ("ends", SI)], [("merged-starts", SI), ("merged-ends", SI), ("covered", I)],
       _merge_ranges,
       ([8, 1, 4, 15], [10, 3, 6, 15]),
       [([], []),
        ([5], [5]),
        ([1, 3], [2, 4]),
        ([1, 4], [2, 5]),
        ([1, 1], [10, 3]),
        ([-5, -2, 0], [-3, -1, 0]),
        ([10, 1, 5], [12, 3, 7]),
        ([1, 2, 3, 4], [10, 2, 3, 4]),
        ([20, 0, 9, 4, 30, 13], [25, 3, 12, 8, 30, 19]),
        ([7, 7, 7], [7, 9, 8]),
        ([3 * k % 31 for k in range(30)], [3 * k % 31 + k % 3 for k in range(30)])],
       ["seq", "nested-loop", "cmp", "sort", "heavy"]),
    _t("tiny-vm",
       "Run a program for a machine with four registers r[0] to r[3], which start as regs. "
       "Instruction i is code[3i], code[3i+1], code[3i+2]: an operation op and two operands "
       "a and b (code's length is a multiple of 3; a register operand is always 0 to 3). "
       "Operations: 0 halts; 1 sets r[a] to b; 2 adds r[b] to r[a]; 3 subtracts r[b] from "
       "r[a]; 4 multiplies r[a] by r[b]; 5 copies r[b] into r[a]; 6 jumps to instruction b "
       "if r[a] is not 0; 7 jumps to instruction b if r[a] is less than 0. Execution starts "
       "at instruction 0 and otherwise goes to the next instruction. Before each "
       "instruction: if its number is not between 0 and the number of instructions minus 1, "
       "stop with status 1; otherwise, if limit instructions have already been executed, "
       "stop with status 2. Executing a halt stops with status 0. Return the registers, the "
       "number of instructions executed (a halt counts) and the status. limit is at most "
       "300.",
       [("code", SI), ("regs", SI), ("limit", I)], [("regs-out", SI), ("executed", I), ("status", I)],
       _tiny_vm,
       ([1, 0, 5, 1, 1, 1, 1, 2, 1, 4, 1, 0, 3, 0, 2, 6, 0, 3, 0, 0, 0], [0, 0, 0, 0], 100),
       [([], [1, 2, 3, 4], 10),
        ([0, 0, 0], [1, 2, 3, 4], 10),
        ([0, 0, 0], [1, 2, 3, 4], 1),
        ([0, 0, 0], [1, 2, 3, 4], 0),
        ([6, 0, -1, 0, 0, 0], [1, 0, 0, 0], 10),
        ([1, 0, 7], [0, 0, 0, 0], 1),
        ([1, 3, -9, 2, 3, 3, 4, 3, 2], [0, 5, 2, 7], 10),
        ([5, 0, 3, 3, 1, 2], [0, 4, 6, 9], 5),
        ([6, 0, 5, 1, 1, 7, 0, 0, 0], [0, 0, 0, 0], 50),
        ([6, 0, 5, 1, 1, 7, 0, 0, 0], [1, 0, 0, 0], 50),
        ([7, 2, 2, 1, 3, 1, 0, 0, 0], [0, 0, -1, 0], 50),
        ([7, 2, 2, 1, 3, 1, 0, 0, 0], [0, 0, 1, 0], 50),
        ([1, 1, 1, 2, 0, 1, 6, 0, 1], [0, 0, 0, 0], 7),
        ([1, 1, 1, 2, 0, 1, 6, 0, 1], [0, 0, 0, 0], 300),
        ([1, 0, 10, 1, 1, 1, 1, 3, 0, 2, 3, 0, 3, 0, 1, 6, 0, 3, 0, 0, 0], [0, 0, 0, 0], 300),
        ([1, 0, 6, 1, 1, 2, 3, 0, 1, 7, 0, 6, 2, 2, 1, 6, 1, 2, 1, 3, 77, 0, 0, 0],
         [5, 5, 5, 5], 300)],
       ["seq", "loop", "rules", "heavy"]),
    _t("lis-smallest",
       "Return a longest strictly increasing subsequence of xs (elements in their original "
       "order, not necessarily next to each other, each greater than the one before). When "
       "there are several, return the one whose values are smallest in dictionary order: "
       "the smallest first value, then among those the smallest second value, and so on. "
       "xs has at most 30 elements.",
       [("xs", SI)], [("lis", SI)], _lis_smallest,
       ([5, 1, 6, 2, 7, 3],),
       [([],),
        ([4],),
        ([3, 3, 3],),
        ([5, 4, 3, 2, 1],),
        ([1, 2, 3, 4],),
        ([2, 9, 3, 8, 4],),
        ([10, 1, 11, 2, 12, 3],),
        ([3, 1, 2, 0, 5, 4, 6],),
        ([7, 8, 1, 2, 9, 3, -1, 0, 4],),
        ([0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15],),
        ([(k * 7) % 23 - 11 for k in range(30)],)],
       ["seq", "nested-loop", "cmp", "dp", "heavy"]),
)
