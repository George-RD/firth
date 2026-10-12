### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    bx = list(boxes)
    hist = []
    read = pushes = blocked = undos = dead = 0
    deltas = (-width, 1, width, -1)
    for m in moves:
        if all(cells[b] == 2 for b in bx):
            break
        read += 1
        if m == 4:
            if hist:
                prev, k, old = hist.pop()
                undos += 1
                player = prev
                if k >= 0:
                    bx[k] = old
            continue
        t = player + deltas[m]
        if cells[t] == 1:
            blocked += 1
            continue
        if t in bx:
            k = bx.index(t)
            u = t + deltas[m]
            if cells[u] == 1 or u in bx:
                blocked += 1
                continue
            bx[k] = u
            hist.append((player, k, t))
            pushes += 1
            if cells[u] != 2 and (cells[u - width] == 1 or cells[u + width] == 1) and (cells[u - 1] == 1 or cells[u + 1] == 1):
                dead += 1
            player = t
        else:
            hist.append((player, -1, -1))
            player = t
    solved = all(cells[b] == 2 for b in bx)
    return (player, bx, read, len(hist), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    b = list(board)
    white_took = black_took = crowned = 0

    def rc(i):
        r = i // 4
        return r, 2 * (i % 4) + (1 if r % 2 == 0 else 0)

    def sq(r, c):
        if 0 <= r < 8 and 0 <= c < 8 and (r + c) % 2 == 1:
            return r * 4 + c // 2
        return -1

    def owner(v):
        return 0 if v in (1, 2) else 1

    def dirs(v, side):
        if v in (2, 4):
            return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        return [(-1, -1), (-1, 1)] if side == 0 else [(1, -1), (1, 1)]

    def extend(bd, pos, kind, side, landings, jumped, out):
        r, c = rc(pos)
        any_jump = False
        for dr, dc in dirs(kind, side):
            mid = sq(r + dr, c + dc)
            land = sq(r + 2 * dr, c + 2 * dc)
            if mid < 0 or land < 0 or bd[mid] == 0 or owner(bd[mid]) == side or bd[land] != 0:
                continue
            any_jump = True
            nbd = list(bd)
            nbd[mid] = 0
            nl = landings + (land,)
            nj = jumped + (mid,)
            far = (r + 2 * dr) == (0 if side == 0 else 7)
            if kind in (1, 3) and far:
                out.append((nl, nj, True))
            else:
                extend(nbd, land, kind, side, nl, nj, out)
        if not any_jump and landings:
            out.append((landings, jumped, False))

    def captures(side):
        caps = []
        for i in range(32):
            v = b[i]
            if v == 0 or owner(v) != side:
                continue
            bd = list(b)
            bd[i] = 0
            out = []
            extend(bd, i, v, side, (), (), out)
            for nl, nj, cr in out:
                caps.append((i, nl, nj, cr))
        return caps

    def steps(side):
        res = []
        for i in range(32):
            v = b[i]
            if v == 0 or owner(v) != side:
                continue
            r, c = rc(i)
            for dr, dc in dirs(v, side):
                t = sq(r + dr, c + dc)
                if t >= 0 and b[t] == 0:
                    res.append((i, t))
        return res

    side = turn
    played = 0
    result = 0
    while True:
        caps = captures(side)
        st = [] if caps else steps(side)
        if not caps and not st:
            result = 2 if side == 0 else 1
            break
        if played == plies:
            result = 0
            break
        if caps:
            i, nl, nj, cr = min(caps, key=lambda x: (-len(x[2]), x[0], x[1]))
            v = b[i]
            b[i] = 0
            for m in nj:
                b[m] = 0
            if cr:
                v += 1
                crowned += 1
            b[nl[-1]] = v
            if side == 0:
                white_took += len(nj)
            else:
                black_took += len(nj)
        else:
            i, t = min(st)
            v = b[i]
            b[i] = 0
            if v in (1, 3) and rc(t)[0] == (0 if side == 0 else 7):
                v += 1
                crowned += 1
            b[t] = v
        played += 1
        side = 1 - side
    return (b, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    toks = list(pattern)
    n = len(toks)

    def parse_alt(pos):
        seqs = []
        while True:
            seq, pos = parse_seq(pos)
            seqs.append(seq)
            if pos < n and toks[pos] == 30:
                pos += 1
                continue
            return ('alt', seqs), pos

    def parse_seq(pos):
        items = []
        while pos < n and toks[pos] not in (30, 32):
            atom, pos = parse_atom(pos)
            while pos < n and toks[pos] in (27, 28, 29):
                atom = ('rep', atom, toks[pos])
                pos += 1
            items.append(atom)
        return ('seq', items), pos

    def parse_atom(pos):
        t = toks[pos]
        if t <= 25:
            return ('lit', t), pos + 1
        if t == 26:
            return ('any',), pos + 1
        if t == 31:
            inner, p2 = parse_alt(pos + 1)
            if p2 < n and toks[p2] == 32:
                return inner, p2 + 1
            raise ValueError("unclosed group")
        raise ValueError("operator without atom")

    try:
        root, end = parse_alt(0)
        if end != n:
            raise ValueError("unmatched close")
        valid = True
    except ValueError:
        valid = False

    if not valid:
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    def ends(node, s, i, memo):
        key = (id(node), i)
        if key in memo:
            return memo[key]
        kind = node[0]
        if kind == 'lit':
            res = {i + 1} if i < len(s) and s[i] == node[1] else set()
        elif kind == 'any':
            res = {i + 1} if i < len(s) else set()
        elif kind == 'alt':
            res = set()
            for seq in node[1]:
                res |= ends(seq, s, i, memo)
        elif kind == 'seq':
            pos = {i}
            for item in node[1]:
                nxt = set()
                for p in pos:
                    nxt |= ends(item, s, p, memo)
                pos = nxt
                if not pos:
                    break
            res = pos
        else:
            atom, op = node[1], node[2]
            if op == 29:
                res = {i} | ends(atom, s, i, memo)
            else:
                starts = {i} if op == 27 else ends(atom, s, i, memo)
                res = set(starts)
                frontier = set(starts)
                while frontier:
                    nxt = set()
                    for p in frontier:
                        for q in ends(atom, s, p, memo):
                            if q not in res:
                                res.add(q)
                                nxt.add(q)
                    frontier = nxt
        memo[key] = res
        return res

    full = []
    longest = []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        ends_set = ends(root, s, 0, {})
        full.append(len(s) in ends_set)
        longest.append(max(ends_set) if ends_set else -1)
    return (full, longest, sum(full), True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    had_bye = [False] * n
    whites = [0] * n
    last = [None] * n
    met = set()
    opps = [[] for _ in range(n)]
    rematches = 0
    ptr = 0
    for _ in range(rounds):
        order = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        if n % 2 == 1:
            bye = next(p for p in reversed(order) if not had_bye[p])
            had_bye[bye] = True
            score[bye] += 2
            order = [p for p in order if p != bye]
        free = list(order)
        pairs = []
        while free:
            a = free.pop(0)
            k = 0
            for idx, q in enumerate(free):
                if (min(a, q), max(a, q)) not in met:
                    k = idx
                    break
            b = free.pop(k)
            pairs.append((a, b))
        for a, b in pairs:
            if whites[a] != whites[b]:
                w, bl = (a, b) if whites[a] < whites[b] else (b, a)
            elif (last[a] == 'b') != (last[b] == 'b'):
                w, bl = (a, b) if last[a] == 'b' else (b, a)
            else:
                w, bl = a, b
            key = (min(a, b), max(a, b))
            if key in met:
                rematches += 1
            r = results[ptr]
            ptr += 1
            if r == 0:
                score[w] += 2
            elif r == 1:
                score[w] += 1
                score[bl] += 1
            else:
                score[bl] += 2
            whites[w] += 1
            last[w] = 'w'
            last[bl] = 'b'
            met.add(key)
            opps[a].append(b)
            opps[b].append(a)
    buch = [sum(score[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-score[p], -buch[p], -ratings[p], p))
    return (score, buch, ranking, whites, rematches)
```

### task: warehouse
```python
from collections import deque


def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    queues = [deque() for _ in range(P)]
    pending = [None] * P
    seq = 0
    earned = shipped = discarded = cancelled = supplies = 0

    def stock_of(p):
        return sum(l[2] for l in lots[p])

    def take(p, q):
        lots[p].sort(key=lambda l: (l[0], l[1]))
        got = 0
        for l in lots[p]:
            if got == q:
                break
            t = min(l[2], q - got)
            l[2] -= t
            got += t
        lots[p] = [l for l in lots[p] if l[2] > 0]

    def fill(p):
        nonlocal earned, shipped
        while queues[p] and stock_of(p) > 0:
            front = queues[p][0]
            t = min(front[0], stock_of(p))
            take(p, t)
            front[0] -= t
            shipped += t
            earned += t * price[p]
            if front[0] == 0:
                queues[p].popleft()

    def add_lot(p, qty, expiry):
        nonlocal seq
        seq += 1
        lots[p].append([expiry, seq, qty])
        fill(p)

    def order(p, qty, d):
        nonlocal earned, shipped
        if queues[p]:
            queues[p].append([qty, d])
            return
        t = min(stock_of(p), qty)
        if t:
            take(p, t)
            shipped += t
            earned += t * price[p]
        if qty - t > 0:
            queues[p].append([qty - t, d])

    for d in range(days):
        for p in range(P):
            kept = []
            for l in lots[p]:
                if l[0] < d:
                    discarded += l[2]
                else:
                    kept.append(l)
            lots[p] = kept
        for p in range(P):
            if pending[p] == d:
                pending[p] = None
                add_lot(p, rq[p], d + shelf[p])
        for e in range(len(ev_day)):
            if ev_day[e] != d:
                continue
            p = ev_prod[e]
            if ev_kind[e] == 1:
                add_lot(p, ev_qty[e], ev_expiry[e])
            else:
                order(p, ev_qty[e], d)
        for p in range(P):
            kept = deque()
            for ent in queues[p]:
                if ent[1] <= d - 7:
                    cancelled += ent[0]
                else:
                    kept.append(ent)
            queues[p] = kept
        for p in range(P):
            if pending[p] is None and stock_of(p) <= rp[p]:
                pending[p] = d + lead[p]
                supplies += 1
    stock = [stock_of(p) for p in range(P)]
    owed = sum(ent[0] for p in range(P) for ent in queues[p])
    return (stock, earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    l1 = [[] for _ in range(s1)]
    l2 = [[] for _ in range(s2)]
    h1 = m1 = h2 = m2 = mr = mw = 0

    def find(st, blk):
        for k, e in enumerate(st):
            if e[0] == blk:
                return k
        return -1

    def l2_put(blk, dirty):
        st = l2[blk % s2]
        ev = 0
        if len(st) == w2:
            old = st.pop(0)
            if old[1]:
                ev = 1
        st.append([blk, dirty])
        return ev

    for blk, wr in zip(addrs, writes):
        set1 = l1[blk % s1]
        idx = find(set1, blk)
        if idx >= 0:
            e = set1.pop(idx)
            if wr:
                e[1] = True
            set1.append(e)
            h1 += 1
            continue
        m1 += 1
        set2 = l2[blk % s2]
        idx2 = find(set2, blk)
        if idx2 >= 0:
            e2 = set2.pop(idx2)
            set2.append(e2)
            h2 += 1
        else:
            m2 += 1
            mr += 1
            mw += l2_put(blk, False)
        if len(set1) == w1:
            ev = set1.pop(0)
            if ev[1]:
                st2 = l2[ev[0] % s2]
                k2 = find(st2, ev[0])
                if k2 >= 0:
                    e2 = st2.pop(k2)
                    e2[1] = True
                    st2.append(e2)
                else:
                    mw += l2_put(ev[0], True)
        set1.append([blk, wr])

    dirty = sum(1 for st in l1 for e in st if e[1]) + sum(1 for st in l2 for e in st if e[1])
    blocks = [e[0] for st in l1 for e in st]
    return (h1, m1, h2, m2, mr, mw, dirty, blocks)
```
