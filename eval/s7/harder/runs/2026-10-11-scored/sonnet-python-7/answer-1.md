### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    delta = [-width, 1, width, -1]
    hist = []
    read = pushes = blocked = undos = dead = 0
    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if hist:
                d, k = hist.pop()
                player -= delta[d]
                if k >= 0:
                    boxes[k] -= delta[d]
                undos += 1
            continue
        t = player + delta[m]
        if cells[t] == 1:
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + delta[m]
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue
            boxes[k] = u
            player = t
            pushes += 1
            hist.append((m, k))
            if (cells[u] != 2
                    and (cells[u - width] == 1 or cells[u + width] == 1)
                    and (cells[u - 1] == 1 or cells[u + 1] == 1)):
                dead += 1
        else:
            player = t
            hist.append((m, -1))
    solved = all(cells[b] == 2 for b in boxes)
    return (player, boxes, read, len(hist), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    b = list(board)
    W_DIRS = [(-1, -1), (-1, 1)]
    B_DIRS = [(1, -1), (1, 1)]
    ALL = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def idx(r, c):
        return r * 4 + c // 2

    def inb(r, c):
        return 0 <= r < 8 and 0 <= c < 8

    def owner(p):
        if p in (1, 2):
            return 0
        if p in (3, 4):
            return 1
        return -1

    def dirs(p):
        if p == 1:
            return W_DIRS
        if p == 3:
            return B_DIRS
        return ALL

    def explore(bd, r, c, piece, side, start, lands, ncap, out):
        moved = False
        far = 0 if side == 0 else 7
        for dr, dc in dirs(piece):
            mr, mc = r + dr, c + dc
            lr, lc = r + 2 * dr, c + 2 * dc
            if not inb(lr, lc):
                continue
            mi = idx(mr, mc)
            li = idx(lr, lc)
            mid = bd[mi]
            if mid != 0 and owner(mid) != side and bd[li] == 0:
                moved = True
                bd[mi] = 0
                crowned = piece in (1, 3) and lr == far
                newp = piece + 1 if crowned else piece
                bd[li] = newp
                lands.append(li)
                if crowned:
                    out.append((ncap + 1, start, tuple(lands), bd[:], True))
                else:
                    explore(bd, lr, lc, newp, side, start, lands, ncap + 1, out)
                lands.pop()
                bd[li] = 0
                bd[mi] = mid
        if not moved and ncap > 0:
            out.append((ncap, start, tuple(lands), bd[:], False))

    def captures(side):
        out = []
        for sq in range(32):
            p = b[sq]
            if p != 0 and owner(p) == side:
                tmp = b[:]
                tmp[sq] = 0
                r, c = rc(sq)
                explore(tmp, r, c, p, side, sq, [], 0, out)
        return out

    def steps(side):
        best = None
        for sq in range(32):
            p = b[sq]
            if p != 0 and owner(p) == side:
                r, c = rc(sq)
                for dr, dc in dirs(p):
                    nr, nc = r + dr, c + dc
                    if inb(nr, nc) and b[idx(nr, nc)] == 0:
                        cand = (sq, idx(nr, nc))
                        if best is None or cand < best:
                            best = cand
        return best

    played = 0
    wt = bt = crowned = 0
    side = turn
    result = 0
    while True:
        caps = captures(side)
        st = None
        if not caps:
            st = steps(side)
            if st is None:
                result = 2 if side == 0 else 1
                break
        if played >= plies:
            result = 0
            break
        if caps:
            best = min(caps, key=lambda x: (-x[0], x[1], x[2]))
            b = best[3]
            if side == 0:
                wt += best[0]
            else:
                bt += best[0]
            if best[4]:
                crowned += 1
        else:
            sq, dest = st
            p = b[sq]
            b[sq] = 0
            nr, _ = rc(dest)
            if p == 1 and nr == 0:
                p = 2
                crowned += 1
            elif p == 3 and nr == 7:
                p = 4
                crowned += 1
            b[dest] = p
        played += 1
        side = 1 - side
    return (b, played, wt, bt, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    n = len(pattern)
    pos = [0]

    class Bad(Exception):
        pass

    def parse_alt():
        seqs = [parse_seq()]
        while pos[0] < n and pattern[pos[0]] == 30:
            pos[0] += 1
            seqs.append(parse_seq())
        return ('alt', seqs)

    def parse_seq():
        items = []
        while pos[0] < n and (pattern[pos[0]] <= 26 or pattern[pos[0]] == 31):
            items.append(parse_item())
        return ('seq', items)

    def parse_item():
        t = pattern[pos[0]]
        pos[0] += 1
        if t <= 25:
            node = ('lit', t)
        elif t == 26:
            node = ('any',)
        else:
            node = parse_alt()
            if pos[0] >= n or pattern[pos[0]] != 32:
                raise Bad()
            pos[0] += 1
        while pos[0] < n and pattern[pos[0]] in (27, 28, 29):
            op = pattern[pos[0]]
            pos[0] += 1
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[op], node)
        return node

    try:
        root = parse_alt()
        if pos[0] != n:
            raise Bad()
    except Bad:
        k = len(lens)
        return ([False] * k, [-1] * k, 0, False)

    def closure(node, s, start):
        result = set(start)
        frontier = set(start)
        while frontier:
            new = ends(node, s, frontier) - result
            result |= new
            frontier = new
        return result

    def ends(node, s, starts):
        kind = node[0]
        if kind == 'lit':
            return {i + 1 for i in starts if i < len(s) and s[i] == node[1]}
        if kind == 'any':
            return {i + 1 for i in starts if i < len(s)}
        if kind == 'seq':
            cur = set(starts)
            for it in node[1]:
                cur = ends(it, s, cur)
                if not cur:
                    break
            return cur
        if kind == 'alt':
            res = set()
            for sq in node[1]:
                res |= ends(sq, s, starts)
            return res
        if kind == 'opt':
            return set(starts) | ends(node[1], s, starts)
        if kind == 'star':
            return closure(node[1], s, starts)
        if kind == 'plus':
            first = ends(node[1], s, starts)
            return closure(node[1], s, first)
        return set()

    full = []
    longest = []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        e = ends(root, s, {0})
        full.append(L in e)
        longest.append(max(e) if e else -1)
    return (full, longest, sum(1 for f in full if f), True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    whites = [0] * n
    last = [None] * n
    played = [set() for _ in range(n)]
    opps = [[] for _ in range(n)]
    had_bye = [False] * n
    rematches = 0
    ri = 0
    for _ in range(rounds):
        rank = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        pool = list(rank)
        if n % 2 == 1:
            for p in reversed(rank):
                if not had_bye[p]:
                    had_bye[p] = True
                    score[p] += 2
                    pool.remove(p)
                    break
        pairs = []
        while pool:
            a = pool.pop(0)
            pick = None
            for q in pool:
                if q not in played[a]:
                    pick = q
                    break
            if pick is None:
                pick = pool[0]
                rematches += 1
            pool.remove(pick)
            pairs.append((a, pick))
        for a, b in pairs:
            if whites[a] < whites[b]:
                w, k = a, b
            elif whites[b] < whites[a]:
                w, k = b, a
            else:
                a_black = last[a] == 'B'
                b_black = last[b] == 'B'
                if a_black and not b_black:
                    w, k = a, b
                elif b_black and not a_black:
                    w, k = b, a
                else:
                    w, k = a, b
            r = results[ri]
            ri += 1
            if r == 0:
                score[w] += 2
            elif r == 1:
                score[w] += 1
                score[k] += 1
            else:
                score[k] += 2
            whites[w] += 1
            last[w] = 'W'
            last[k] = 'B'
            played[w].add(k)
            played[k].add(w)
            opps[w].append(k)
            opps[k].append(w)
    buch = [sum(score[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-score[p], -buch[p], -ratings[p], p))
    return (score, buch, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    backs = [[] for _ in range(P)]
    on_way = [None] * P
    st = {'seq': 0, 'earned': 0, 'shipped': 0, 'disc': 0, 'canc': 0, 'sup': 0}

    def stock(p):
        return sum(l[0] for l in lots[p])

    def take(p, q):
        got = 0
        lots[p].sort(key=lambda l: (l[1], l[2]))
        while q > 0 and lots[p]:
            l = lots[p][0]
            t = min(q, l[0])
            l[0] -= t
            q -= t
            got += t
            if l[0] == 0:
                lots[p].pop(0)
        st['shipped'] += got
        st['earned'] += got * price[p]
        return got

    def add_lot(p, qty, expiry):
        lots[p].append([qty, expiry, st['seq']])
        st['seq'] += 1
        while backs[p] and stock(p) > 0:
            bo = backs[p][0]
            t = take(p, min(bo[0], stock(p)))
            bo[0] -= t
            if bo[0] == 0:
                backs[p].pop(0)

    e = 0
    ne = len(ev_day)
    for d in range(days):
        for p in range(P):
            keep = []
            for l in lots[p]:
                if l[1] < d:
                    st['disc'] += l[0]
                else:
                    keep.append(l)
            lots[p] = keep
        for p in range(P):
            if on_way[p] is not None and on_way[p] == d:
                add_lot(p, rq[p], d + shelf[p])
                on_way[p] = None
        while e < ne and ev_day[e] == d:
            p = ev_prod[e]
            q = ev_qty[e]
            if ev_kind[e] == 1:
                add_lot(p, q, ev_expiry[e])
            else:
                if backs[p]:
                    backs[p].append([q, d])
                else:
                    t = take(p, min(q, stock(p)))
                    if q - t > 0:
                        backs[p].append([q - t, d])
            e += 1
        for p in range(P):
            keep = []
            for bo in backs[p]:
                if bo[1] <= d - 7:
                    st['canc'] += bo[0]
                else:
                    keep.append(bo)
            backs[p] = keep
        for p in range(P):
            if on_way[p] is None and stock(p) <= rp[p]:
                on_way[p] = d + lead[p]
                st['sup'] += 1
    owed = sum(bo[0] for p in range(P) for bo in backs[p])
    return ([stock(p) for p in range(P)], st['earned'], st['shipped'],
            st['disc'], st['canc'], st['sup'], owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    sets1 = [[] for _ in range(s1)]
    sets2 = [[] for _ in range(s2)]
    d1 = set()
    d2 = set()
    cnt = {'h1': 0, 'm1': 0, 'h2': 0, 'm2': 0, 'rd': 0, 'wr': 0}

    def use(sets, s, a):
        st = sets[a % s]
        st.remove(a)
        st.append(a)

    def put(sets, s, w, dirty, a, isdirty):
        st = sets[a % s]
        victim = None
        vdirty = False
        if len(st) >= w:
            victim = st.pop(0)
            vdirty = victim in dirty
            dirty.discard(victim)
        st.append(a)
        if isdirty:
            dirty.add(a)
        else:
            dirty.discard(a)
        return victim, vdirty

    for i in range(len(addrs)):
        a = addrs[i]
        wr = bool(writes[i])
        if a in sets1[a % s1]:
            cnt['h1'] += 1
            use(sets1, s1, a)
            if wr:
                d1.add(a)
            continue
        cnt['m1'] += 1
        if a in sets2[a % s2]:
            cnt['h2'] += 1
            use(sets2, s2, a)
        else:
            cnt['m2'] += 1
            cnt['rd'] += 1
            victim, vd = put(sets2, s2, w2, d2, a, False)
            if victim is not None and vd:
                cnt['wr'] += 1
        victim, vd = put(sets1, s1, w1, d1, a, wr)
        if victim is not None and vd:
            b = victim
            if b in sets2[b % s2]:
                use(sets2, s2, b)
                d2.add(b)
            else:
                v2, vd2 = put(sets2, s2, w2, d2, b, True)
                if v2 is not None and vd2:
                    cnt['wr'] += 1
    blocks = []
    for st in sets1:
        blocks.extend(st)
    return (cnt['h1'], cnt['m1'], cnt['h2'], cnt['m2'], cnt['rd'], cnt['wr'],
            len(d1) + len(d2), blocks)
```
