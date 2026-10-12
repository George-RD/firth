### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    goals = set(i for i, v in enumerate(cells) if v == 2)
    boxes = boxes[:]
    history = []
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    read = 0
    deltas = [-width, 1, width, -1]

    for m in moves:
        if all(box in goals for box in boxes):
            break
        read += 1

        if m == 4:
            if history:
                undos += 1
                d, was_push, box_idx = history.pop()
                delta = deltas[d]
                if was_push:
                    boxes[box_idx] = player
                    player = player - delta
                else:
                    player = player - delta
            continue

        delta = deltas[m]
        t = player + delta

        if cells[t] == 1:
            blocked += 1
            continue

        box_idx = None
        for k, b in enumerate(boxes):
            if b == t:
                box_idx = k
                break

        if box_idx is not None:
            u = t + delta
            if cells[u] == 1:
                blocked += 1
                continue
            if any(b == u for b in boxes):
                blocked += 1
                continue
            boxes[box_idx] = u
            player = t
            pushes += 1
            history.append((m, True, box_idx))
            if u not in goals:
                above_below = (cells[u - width] == 1 or cells[u + width] == 1)
                left_right = (cells[u - 1] == 1 or cells[u + 1] == 1)
                if above_below and left_right:
                    dead += 1
        else:
            player = t
            history.append((m, False, -1))

    solved = all(box in goals for box in boxes)
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    coords = []
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        coords.append((r, c))

    def rc_to_sq(r, c):
        if r < 0 or r > 7 or c < 0 or c > 7:
            return None
        if (r + c) % 2 != 1:
            return None
        base = 1 if r % 2 == 0 else 0
        if (c - base) % 2 != 0:
            return None
        j = (c - base) // 2
        if j < 0 or j > 3:
            return None
        return r * 4 + j

    def neighbor(sq, dr, dc):
        r, c = coords[sq]
        return rc_to_sq(r + dr, c + dc)

    def mid_sq(a, b):
        ra, ca = coords[a]
        rb, cb = coords[b]
        return rc_to_sq((ra + rb) // 2, (ca + cb) // 2)

    def dirs_for(ptype):
        if ptype == 1:
            return [(-1, -1), (-1, 1)]
        if ptype == 3:
            return [(1, -1), (1, 1)]
        return [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def gen_captures(b, start, ptype, side):
        results = []
        opp = (3, 4) if side == 0 else (1, 2)

        def dfs(bd, sq, cur_type, captured, landings):
            found = False
            for dr, dc in dirs_for(cur_type):
                mid = neighbor(sq, dr, dc)
                if mid is None:
                    continue
                if bd[mid] not in opp:
                    continue
                land = neighbor(mid, dr, dc)
                if land is None:
                    continue
                if bd[land] != 0:
                    continue
                found = True
                nb = bd[:]
                nb[sq] = 0
                nb[mid] = 0
                lr, lc = coords[land]
                if cur_type in (1, 3):
                    far = 0 if cur_type == 1 else 7
                    if lr == far:
                        new_type = 2 if cur_type == 1 else 4
                        nb[land] = new_type
                        results.append((start, landings + [land], captured + 1, new_type))
                        continue
                nb[land] = cur_type
                dfs(nb, land, cur_type, captured + 1, landings + [land])
            if not found and captured > 0:
                results.append((start, landings, captured, cur_type))

        dfs(b, start, ptype, 0, [])
        return results

    def get_legal(b, side):
        my = (1, 2) if side == 0 else (3, 4)
        captures = []
        for i, val in enumerate(b):
            if val in my:
                captures.extend(gen_captures(b, i, val, side))

        if captures:
            maxc = max(c[2] for c in captures)
            best = [c for c in captures if c[2] == maxc]
            best.sort(key=lambda c: (c[0], c[1]))
            return ('capture', best[0])

        steps = []
        for i, val in enumerate(b):
            if val in my:
                for dr, dc in dirs_for(val):
                    dest = neighbor(i, dr, dc)
                    if dest is not None and b[dest] == 0:
                        steps.append((i, dest, val))

        if steps:
            steps.sort(key=lambda x: (x[0], x[1]))
            return ('step', steps[0])

        return (None, None)

    b = board[:]
    played = 0
    white_took = 0
    black_took = 0
    crowned = 0
    result = 0

    while True:
        side = turn
        typ, move = get_legal(b, side)

        if typ is None:
            result = 2 if side == 0 else 1
            break

        if played >= plies:
            result = 0
            break

        if typ == 'capture':
            start, landings, captured, final_type = move
            start_val = b[start]
            b[start] = 0
            prev = start
            for land in landings:
                b[prev] = 0
                mid = mid_sq(prev, land)
                b[mid] = 0
                prev = land
            b[prev] = final_type

            if side == 0:
                white_took += captured
            else:
                black_took += captured

            if start_val in (1, 3) and final_type in (2, 4):
                crowned += 1
        else:
            start, dest, val = move
            b[start] = 0
            final_type = val
            r, c = coords[dest]
            if val == 1 and r == 0:
                final_type = 2
                crowned += 1
            elif val == 3 and r == 7:
                final_type = 4
                crowned += 1
            b[dest] = final_type

        played += 1
        turn = 1 - turn

    return (b, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    tokens = pattern
    pos = 0
    valid = True

    class Invalid(Exception):
        pass

    def parse_alternation():
        nonlocal pos
        seqs = []
        seqs.append(parse_sequence())
        while pos < len(tokens) and tokens[pos] == 30:
            pos += 1
            seqs.append(parse_sequence())
        return ('alt', seqs)

    def parse_sequence():
        nonlocal pos
        items = []
        while pos < len(tokens):
            t = tokens[pos]
            if (0 <= t <= 26) or t == 31:
                items.append(parse_item())
            else:
                break
        if pos < len(tokens) and tokens[pos] in (27, 28, 29):
            raise Invalid
        return ('seq', items)

    def parse_item():
        nonlocal pos
        atom = parse_atom()
        ops = []
        while pos < len(tokens) and tokens[pos] in (27, 28, 29):
            ops.append(tokens[pos])
            pos += 1
        return ('item', atom, ops)

    def parse_atom():
        nonlocal pos
        if pos >= len(tokens):
            raise Invalid
        t = tokens[pos]
        if 0 <= t <= 25:
            pos += 1
            return ('lit', t)
        if t == 26:
            pos += 1
            return ('any',)
        if t == 31:
            pos += 1
            alt = parse_alternation()
            if pos >= len(tokens) or tokens[pos] != 32:
                raise Invalid
            pos += 1
            return ('alt', alt)
        raise Invalid

    try:
        ast = parse_alternation()
        if pos != len(tokens):
            valid = False
        else:
            valid = True
    except Invalid:
        valid = False

    def closure(m, s, p):
        seen = {p}
        stack = [p]
        while stack:
            q = stack.pop()
            for r in m(s, q):
                if r not in seen:
                    seen.add(r)
                    stack.append(r)
        return seen

    def plus(m, s, p):
        first = m(s, p)
        seen = set(first)
        stack = list(first)
        while stack:
            q = stack.pop()
            for r in m(s, q):
                if r not in seen:
                    seen.add(r)
                    stack.append(r)
        return seen

    def optional(m, s, p):
        res = {p}
        res |= m(s, p)
        return res

    def match_node(node, s, p):
        typ = node[0]
        if typ == 'alt':
            res = set()
            for seq in node[1]:
                res |= match_node(seq, s, p)
            return res
        if typ == 'seq':
            cur = {p}
            for item in node[1]:
                nxt = set()
                for q in cur:
                    nxt |= match_item(item, s, q)
                cur = nxt
                if not cur:
                    break
            return cur
        if typ == 'lit':
            if p < len(s) and s[p] == node[1]:
                return {p + 1}
            return set()
        if typ == 'any':
            if p < len(s):
                return {p + 1}
            return set()
        if typ == 'item':
            atom, ops = node[1], node[2]

            def base(q):
                return match_node(atom, s, q)

            m = base
            for op in ops:
                prev = m
                if op == 27:
                    m = lambda q, prev=prev: closure(prev, s, q)
                elif op == 28:
                    m = lambda q, prev=prev: plus(prev, s, q)
                elif op == 29:
                    m = lambda q, prev=prev: optional(prev, s, q)
            return m(p)
        return set()

    def match_item(item, s, p):
        atom, ops = item[1], item[2]

        def base(q):
            return match_node(atom, s, q)

        m = base
        for op in ops:
            prev = m
            if op == 27:
                m = lambda q, prev=prev: closure(prev, s, q)
            elif op == 28:
                m = lambda q, prev=prev: plus(prev, s, q)
            elif op == 29:
                m = lambda q, prev=prev: optional(prev, s, q)
        return m(p)

    full = []
    longest = []
    count = 0
    offset = 0

    if not valid:
        for _ in lens:
            full.append(False)
            longest.append(-1)
        return (full, longest, 0, False)

    for L in lens:
        s = chars[offset:offset + L]
        offset += L
        ends = match_node(ast, s, 0)
        is_full = L in ends
        full.append(is_full)
        if ends:
            longest.append(max(ends))
        else:
            longest.append(-1)
        if is_full:
            count += 1

    return (full, longest, count, valid)
```

### task: swiss
```python
def main(ratings, rounds, results):
    N = len(ratings)
    scores = [0] * N
    whites = [0] * N
    last_game = [None] * N
    bye_used = [False] * N
    played_sets = [set() for _ in range(N)]
    opponents_list = [[] for _ in range(N)]
    rematches = 0
    res_idx = 0

    for _ in range(rounds):
        order = sorted(range(N), key=lambda p: (-scores[p], -ratings[p], p))
        players = list(order)

        if N % 2 == 1:
            bye_p = None
            for p in reversed(order):
                if not bye_used[p]:
                    bye_p = p
                    break
            if bye_p is not None:
                scores[bye_p] += 2
                bye_used[bye_p] = True
                players.remove(bye_p)

        unpaired = players[:]
        pairs = []

        while unpaired:
            p1 = unpaired.pop(0)
            chosen = None
            for p2 in unpaired:
                if p2 not in played_sets[p1]:
                    chosen = p2
                    break
            if chosen is None:
                chosen = unpaired[0]
                rematches += 1
            unpaired.remove(chosen)

            if whites[p1] < whites[chosen]:
                white, black = p1, chosen
            elif whites[chosen] < whites[p1]:
                white, black = chosen, p1
            else:
                l1 = last_game[p1]
                l2 = last_game[chosen]
                is_black1 = (l1 == 1)
                is_black2 = (l2 == 1)
                if is_black1 and not is_black2:
                    white, black = p1, chosen
                elif is_black2 and not is_black1:
                    white, black = chosen, p1
                else:
                    white, black = p1, chosen

            pairs.append((white, black))

        for white, black in pairs:
            res = results[res_idx]
            res_idx += 1

            whites[white] += 1
            last_game[white] = 0
            last_game[black] = 1

            played_sets[white].add(black)
            played_sets[black].add(white)
            opponents_list[white].append(black)
            opponents_list[black].append(white)

            if res == 0:
                scores[white] += 2
            elif res == 1:
                scores[white] += 1
                scores[black] += 1
            elif res == 2:
                scores[black] += 2

    buchholz = [sum(scores[opp] for opp in opponents_list[p]) for p in range(N)]
    ranking = sorted(range(N), key=lambda p: (-scores[p], -buchholz[p], -ratings[p], p))

    return (scores, buchholz, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    from collections import deque

    P = len(price)
    lots = [[] for _ in range(P)]
    backorders = [deque() for _ in range(P)]
    pending = [None] * P
    arrival = 0
    earned = 0
    shipped = 0
    discarded = 0
    cancelled = 0
    supplies = 0

    def total_stock(p):
        return sum(lot[2] for lot in lots[p])

    def take_stock(p, qty):
        taken = 0
        while qty > 0:
            best_i = None
            best_key = None
            for i, (exp, arr, q) in enumerate(lots[p]):
                if q > 0:
                    key = (exp, arr)
                    if best_key is None or key < best_key:
                        best_key = key
                        best_i = i
            if best_i is None:
                break
            exp, arr, q = lots[p][best_i]
            take = min(q, qty)
            q -= take
            qty -= take
            taken += take
            if q == 0:
                lots[p].pop(best_i)
            else:
                lots[p][best_i] = [exp, arr, q]
        return taken

    def fill_backorders(p):
        nonlocal earned, shipped
        while backorders[p]:
            owed, day = backorders[p][0]
            taken = take_stock(p, owed)
            if taken == 0:
                break
            earned += taken * price[p]
            shipped += taken
            owed -= taken
            if owed == 0:
                backorders[p].popleft()
            else:
                backorders[p][0][0] = owed

    def add_lot(p, qty, expiry):
        nonlocal arrival
        if qty > 0:
            lots[p].append([expiry, arrival, qty])
            arrival += 1
        fill_backorders(p)

    e = 0
    E = len(ev_day)

    for d in range(days):
        for p in range(P):
            new_lots = []
            for exp, arr, q in lots[p]:
                if exp < d:
                    discarded += q
                else:
                    new_lots.append([exp, arr, q])
            lots[p] = new_lots

        for p in range(P):
            if pending[p] == d:
                add_lot(p, rq[p], d + shelf[p])
                pending[p] = None

        while e < E and ev_day[e] == d:
            kind = ev_kind[e]
            p = ev_prod[e]
            qty = ev_qty[e]
            if kind == 1:
                add_lot(p, qty, ev_expiry[e])
            else:
                if backorders[p]:
                    backorders[p].append([qty, d])
                else:
                    taken = take_stock(p, qty)
                    earned += taken * price[p]
                    shipped += taken
                    if qty > taken:
                        backorders[p].append([qty - taken, d])
            e += 1

        cutoff = d - 7
        for p in range(P):
            while backorders[p] and backorders[p][0][1] <= cutoff:
                owed, day = backorders[p].popleft()
                cancelled += owed

        for p in range(P):
            if pending[p] is None:
                if total_stock(p) <= rp[p]:
                    pending[p] = d + lead[p]
                    supplies += 1

    stock = [total_stock(p) for p in range(P)]
    owed = sum(backorders[p][i][0] for p in range(P) for i in range(len(backorders[p])))
    return (stock, earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    l1_sets = [[] for _ in range(s1)]
    l2_sets = [[] for _ in range(s2)]
    l1_hits = 0
    l1_misses = 0
    l2_hits = 0
    l2_misses = 0
    mem_reads = 0
    mem_writes = 0

    def l1_find(b):
        idx = b % s1
        for i, (blk, dirty) in enumerate(l1_sets[idx]):
            if blk == b:
                place = l1_sets[idx].pop(i)
                l1_sets[idx].append(place)
                return True
        return False

    def l1_put(b, dirty):
        idx = b % s1
        evicted = None
        if len(l1_sets[idx]) == w1:
            evicted = l1_sets[idx].pop(0)
        l1_sets[idx].append([b, dirty])
        return evicted

    def l2_find(b):
        idx = b % s2
        for i, (blk, dirty) in enumerate(l2_sets[idx]):
            if blk == b:
                place = l2_sets[idx].pop(i)
                l2_sets[idx].append(place)
                return True
        return False

    def l2_put(b, dirty):
        nonlocal mem_writes
        idx = b % s2
        if len(l2_sets[idx]) == w2:
            ev_b, ev_dirty = l2_sets[idx].pop(0)
            if ev_dirty:
                mem_writes += 1
        l2_sets[idx].append([b, dirty])

    for a, wr in zip(addrs, writes):
        if l1_find(a):
            l1_hits += 1
            if wr:
                idx = a % s1
                l1_sets[idx][-1][1] = True
        else:
            l1_misses += 1
            if l2_find(a):
                l2_hits += 1
            else:
                l2_misses += 1
                mem_reads += 1
                l2_put(a, False)

            evicted = l1_put(a, wr)
            if evicted is not None:
                b, b_dirty = evicted
                if b_dirty:
                    if l2_find(b):
                        idx = b % s2
                        l2_sets[idx][-1][1] = True
                    else:
                        l2_put(b, True)

    dirty = 0
    for s in l1_sets:
        for _, d in s:
            if d:
                dirty += 1
    for s in l2_sets:
        for _, d in s:
            if d:
                dirty += 1

    l1_blocks = []
    for s in l1_sets:
        for blk, _ in s:
            l1_blocks.append(blk)

    return (l1_hits, l1_misses, l2_hits, l2_misses, mem_reads, mem_writes, dirty, l1_blocks)
```