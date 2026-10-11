### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    w = width
    boxes = list(boxes)
    hist = []
    read = pushes = blocked = undos = dead = 0
    deltas = [-w, 1, w, -1]

    def solved():
        return all(cells[b] == 2 for b in boxes)

    def is_dead(u):
        if cells[u] == 2:
            return False
        wall_ud = cells[u - w] == 1 or cells[u + w] == 1
        wall_lr = cells[u - 1] == 1 or cells[u + 1] == 1
        return wall_ud and wall_lr

    for m in moves:
        if solved():
            break
        read += 1
        if m == 4:
            if hist:
                entry = hist.pop()
                undos += 1
                if entry[0] == 'push':
                    _, k, p0, tb, _ub = entry
                    boxes[k] = tb
                    player = p0
                else:
                    player = entry[1]
            continue
        d = deltas[m]
        t = player + d
        if cells[t] == 1:
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + d
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue
            hist.append(('push', k, player, t, u))
            boxes[k] = u
            player = t
            pushes += 1
            if is_dead(u):
                dead += 1
        else:
            hist.append(('step', player))
            player = t
    return (player, boxes, read, len(hist), pushes, blocked, undos, dead, solved())
```

### task: checkers
```python
def main(board, turn, plies):
    b = list(board)
    RC = []
    for i in range(32):
        r = i // 4
        RC.append((r, 2 * (i % 4) + (1 if r % 2 == 0 else 0)))

    def idx(r, c):
        if 0 <= r < 8 and 0 <= c < 8 and (r + c) % 2 == 1:
            return r * 4 + c // 2
        return -1

    def side_of(piece):
        return 0 if piece in (1, 2) else 1

    def dirs(piece):
        if piece == 1:
            return [(-1, -1), (-1, 1)]
        if piece == 3:
            return [(1, -1), (1, 1)]
        return [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def far(side):
        return 0 if side == 0 else 7

    def cont(p, piece):
        side = side_of(piece)
        r, c = RC[p]
        out = []
        for dr, dc in dirs(piece):
            m = idx(r + dr, c + dc)
            l = idx(r + 2 * dr, c + 2 * dc)
            if m < 0 or l < 0:
                continue
            pm = b[m]
            if pm == 0 or side_of(pm) == side or b[l] != 0:
                continue
            b[m] = 0
            if piece in (1, 3) and l // 4 == far(side):
                out.append([l])
            else:
                subs = cont(l, piece)
                if subs:
                    for sub in subs:
                        out.append([l] + sub)
                else:
                    out.append([l])
            b[m] = pm
        return out

    def captures(side):
        res = []
        for s in range(32):
            piece = b[s]
            if piece == 0 or side_of(piece) != side:
                continue
            b[s] = 0
            for seq in cont(s, piece):
                res.append((s, seq))
            b[s] = piece
        return res

    def steps(side):
        res = []
        for s in range(32):
            piece = b[s]
            if piece == 0 or side_of(piece) != side:
                continue
            r, c = RC[s]
            for dr, dc in dirs(piece):
                n = idx(r + dr, c + dc)
                if n >= 0 and b[n] == 0:
                    res.append((s, n))
        return res

    white_took = black_took = crowned = played = 0
    result = 0
    while True:
        side = (turn + played) % 2
        caps = captures(side)
        sts = [] if caps else steps(side)
        if not caps and not sts:
            result = 2 if side == 0 else 1
            break
        if played == plies:
            result = 0
            break
        played += 1
        if caps:
            s, seq = min(caps, key=lambda t: (-len(t[1]), t[0], tuple(t[1])))
            piece = b[s]
            b[s] = 0
            pr, pc = RC[s]
            for l in seq:
                lr, lc = RC[l]
                b[idx((pr + lr) // 2, (pc + lc) // 2)] = 0
                pr, pc = lr, lc
            if side == 0:
                white_took += len(seq)
            else:
                black_took += len(seq)
            last = seq[-1]
            if piece in (1, 3) and last // 4 == far(side):
                piece += 1
                crowned += 1
            b[last] = piece
        else:
            s, n = min(sts)
            piece = b[s]
            b[s] = 0
            if piece in (1, 3) and n // 4 == far(side):
                piece += 1
                crowned += 1
            b[n] = piece
    return (b, played, white_took, black_took, crowned, result)
```

### task: regex
```python
class _Invalid(Exception):
    pass


def main(pattern, lens, chars):
    toks = list(pattern)
    n = len(toks)
    pos = 0

    def parse_alt():
        nonlocal pos
        seqs = [parse_seq()]
        while pos < n and toks[pos] == 30:
            pos += 1
            seqs.append(parse_seq())
        return ('alt', seqs)

    def parse_seq():
        items = []
        while pos < n and toks[pos] not in (30, 32):
            items.append(parse_item())
        return ('seq', items)

    def parse_item():
        nonlocal pos
        node = parse_atom()
        while pos < n and toks[pos] in (27, 28, 29):
            op = toks[pos]
            pos += 1
            kind = 'star' if op == 27 else ('plus' if op == 28 else 'opt')
            node = (kind, node)
        return node

    def parse_atom():
        nonlocal pos
        if pos >= n:
            raise _Invalid()
        t = toks[pos]
        if 0 <= t <= 26:
            pos += 1
            return ('lit', t)
        if t == 31:
            pos += 1
            node = parse_alt()
            if pos < n and toks[pos] == 32:
                pos += 1
                return node
        raise _Invalid()

    try:
        root = parse_alt()
        if pos != n:
            raise _Invalid()
    except _Invalid:
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    def closure(child, s, starts):
        seen = set(starts)
        frontier = set(starts)
        while frontier:
            nxt = set()
            for p in frontier:
                for q in ends(child, s, p):
                    if q not in seen:
                        seen.add(q)
                        nxt.add(q)
            frontier = nxt
        return seen

    def ends(node, s, i):
        kind = node[0]
        if kind == 'lit':
            c = node[1]
            if i < len(s) and (c == 26 or s[i] == c):
                return {i + 1}
            return set()
        if kind == 'alt':
            out = set()
            for sq in node[1]:
                out |= ends(sq, s, i)
            return out
        if kind == 'seq':
            cur = {i}
            for it in node[1]:
                nxt = set()
                for p in cur:
                    nxt |= ends(it, s, p)
                cur = nxt
                if not cur:
                    break
            return cur
        if kind == 'opt':
            return {i} | ends(node[1], s, i)
        if kind == 'star':
            return closure(node[1], s, {i})
        return closure(node[1], s, ends(node[1], s, i))

    strs = []
    off = 0
    for L in lens:
        strs.append(chars[off:off + L])
        off += L

    full = []
    longest = []
    for s in strs:
        e = ends(root, s, 0)
        full.append(len(s) in e)
        longest.append(max(e) if e else -1)
    return (full, longest, sum(1 for f in full if f), True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    P = len(ratings)
    score = [0] * P
    whites = [0] * P
    last = [None] * P
    had_bye = [False] * P
    opp = [[] for _ in range(P)]
    met = set()
    rematches = 0
    k = 0
    for _ in range(rounds):
        order = sorted(range(P), key=lambda p: (-score[p], -ratings[p], p))
        if P % 2 == 1:
            for p in reversed(order):
                if not had_bye[p]:
                    had_bye[p] = True
                    score[p] += 2
                    order.remove(p)
                    break
        remaining = list(order)
        pairs = []
        while remaining:
            a = remaining.pop(0)
            j = 0
            for jj, b in enumerate(remaining):
                if (min(a, b), max(a, b)) not in met:
                    j = jj
                    break
            b = remaining.pop(j)
            key = (min(a, b), max(a, b))
            if key in met:
                rematches += 1
            met.add(key)
            pairs.append((a, b))
        for a, b in pairs:
            if whites[a] != whites[b]:
                w, bl = (a, b) if whites[a] < whites[b] else (b, a)
            elif (last[a] == 'B') != (last[b] == 'B'):
                w, bl = (a, b) if last[a] == 'B' else (b, a)
            else:
                w, bl = a, b
            whites[w] += 1
            last[w] = 'W'
            last[bl] = 'B'
            res = results[k]
            k += 1
            if res == 0:
                score[w] += 2
            elif res == 1:
                score[w] += 1
                score[bl] += 1
            else:
                score[bl] += 2
            opp[a].append(b)
            opp[b].append(a)
    buch = [sum(score[q] for q in opp[p]) for p in range(P)]
    ranking = sorted(range(P), key=lambda p: (-score[p], -buch[p], -ratings[p], p))
    return (score, buch, ranking, whites, rematches)
```

### task: warehouse
```python
from collections import deque


def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    back = [deque() for _ in range(P)]
    due = [None] * P
    seq = 0
    earned = shipped = discarded = cancelled = supplies = 0

    def stock(p):
        return sum(L[2] for L in lots[p])

    def ship(p, q):
        nonlocal earned, shipped
        lots[p].sort(key=lambda L: (L[0], L[1]))
        need = q
        while need > 0:
            L = lots[p][0]
            t = min(L[2], need)
            L[2] -= t
            need -= t
            if L[2] == 0:
                lots[p].pop(0)
        shipped += q
        earned += q * price[p]

    def fill(p):
        while back[p] and stock(p) > 0:
            head = back[p][0]
            t = min(head[0], stock(p))
            ship(p, t)
            head[0] -= t
            if head[0] == 0:
                back[p].popleft()

    def arrive(p, qty, expiry):
        nonlocal seq
        seq += 1
        lots[p].append([expiry, seq, qty])
        fill(p)

    def place_order(p, qty, d):
        if back[p]:
            back[p].append([qty, d])
            return
        t = min(stock(p), qty)
        if t > 0:
            ship(p, t)
        if qty - t > 0:
            back[p].append([qty - t, d])

    e = 0
    E = len(ev_day)
    for d in range(days):
        for p in range(P):
            kept = []
            for L in lots[p]:
                if L[0] < d:
                    discarded += L[2]
                else:
                    kept.append(L)
            lots[p] = kept
        for p in range(P):
            if due[p] == d:
                due[p] = None
                arrive(p, rq[p], d + shelf[p])
        while e < E and ev_day[e] == d:
            p = ev_prod[e]
            if ev_kind[e] == 1:
                arrive(p, ev_qty[e], ev_expiry[e])
            else:
                place_order(p, ev_qty[e], d)
            e += 1
        for p in range(P):
            kept = deque()
            for entry in back[p]:
                if entry[1] <= d - 7:
                    cancelled += entry[0]
                else:
                    kept.append(entry)
            back[p] = kept
        for p in range(P):
            if due[p] is None and stock(p) <= rp[p]:
                due[p] = d + lead[p]
                supplies += 1

    stock_final = [stock(p) for p in range(P)]
    owed = sum(entry[0] for p in range(P) for entry in back[p])
    return (stock_final, earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    h1 = m1 = h2 = m2 = mr = mw = 0

    def find(entries, blk):
        for i, e in enumerate(entries):
            if e[0] == blk:
                return i
        return -1

    def put_l2(blk, dirty):
        nonlocal mw
        st = L2[blk % s2]
        if len(st) == w2:
            ev = st.pop(0)
            if ev[1]:
                mw += 1
        st.append([blk, dirty])

    for a, wr in zip(addrs, writes):
        st1 = L1[a % s1]
        i = find(st1, a)
        if i >= 0:
            h1 += 1
            e = st1.pop(i)
            if wr:
                e[1] = True
            st1.append(e)
            continue
        m1 += 1
        st2 = L2[a % s2]
        j = find(st2, a)
        if j >= 0:
            h2 += 1
            st2.append(st2.pop(j))
        else:
            m2 += 1
            mr += 1
            put_l2(a, False)
        if len(st1) == w1:
            ev = st1.pop(0)
            if ev[1]:
                bb = ev[0]
                st3 = L2[bb % s2]
                k = find(st3, bb)
                if k >= 0:
                    e2 = st3.pop(k)
                    e2[1] = True
                    st3.append(e2)
                else:
                    put_l2(bb, True)
        st1.append([a, wr])

    dirty = sum(1 for st in L1 for e in st if e[1]) + sum(1 for st in L2 for e in st if e[1])
    l1_blocks = [e[0] for st in L1 for e in st]
    return (h1, m1, h2, m2, mr, mw, dirty, l1_blocks)
```
