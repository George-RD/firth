### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    D = [-width, 1, width, -1]
    hist = []
    read = pushes = blocked = undos = dead = 0
    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if hist:
                d, k = hist.pop()
                player -= d
                if k >= 0:
                    boxes[k] -= d
                undos += 1
        else:
            d = D[m]
            t = player + d
            if cells[t] == 1:
                blocked += 1
            elif t in boxes:
                k = boxes.index(t)
                u = t + d
                if cells[u] == 1 or u in boxes:
                    blocked += 1
                else:
                    boxes[k] = u
                    player = t
                    pushes += 1
                    if (cells[u] != 2
                            and (cells[u - width] == 1 or cells[u + width] == 1)
                            and (cells[u - 1] == 1 or cells[u + 1] == 1)):
                        dead += 1
                    hist.append((d, k))
            else:
                player = t
                hist.append((d, -1))
    solved = all(cells[b] == 2 for b in boxes)
    return (player, boxes, read, len(hist), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    board = list(board)

    def sq(r, c):
        if 0 <= r < 8 and 0 <= c < 8 and (r + c) % 2 == 1:
            return r * 4 + c // 2
        return -1

    nb = []
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        lst = []
        for dr in (-1, 1):
            for dc in (-1, 1):
                a = sq(r + dr, c + dc)
                b = sq(r + 2 * dr, c + 2 * dc)
                lst.append((dr, a, b))
        nb.append(lst)

    def owner(v):
        return 0 if v in (1, 2) else 1

    took = [0, 0]
    crowned_total = 0
    played = 0
    side = turn
    result = 0

    while True:
        far = 0 if side == 0 else 7
        mandir = -1 if side == 0 else 1
        records = []
        for s in range(32):
            v = board[s]
            if v == 0 or owner(v) != side:
                continue
            king = v in (2, 4)
            board[s] = 0

            def dfs(pos, king_now, land, caps, s=s, side=side):
                found = False
                for (dr, a, b) in nb[pos]:
                    if not king_now and dr != mandir:
                        continue
                    if a < 0 or b < 0:
                        continue
                    x = board[a]
                    if x == 0 or owner(x) == side:
                        continue
                    if board[b] != 0:
                        continue
                    found = True
                    board[a] = 0
                    nland = land + [b]
                    ncaps = caps + [a]
                    if (not king_now) and (b // 4) == far:
                        records.append((-len(ncaps), s, nland, ncaps, True))
                    else:
                        dfs(b, king_now, nland, ncaps)
                    board[a] = x
                if not found and land:
                    records.append((-len(caps), s, land, caps, False))

            dfs(s, king, [], [])
            board[s] = v

        if records:
            best = min(records, key=lambda t: (t[0], t[1], t[2]))
            negc, s, land, caps, crowned = best
            if played == plies:
                result = 0
                break
            v = board[s]
            board[s] = 0
            for c in caps:
                board[c] = 0
            if crowned:
                v = 2 if side == 0 else 4
                crowned_total += 1
            board[land[-1]] = v
            took[side] += len(caps)
        else:
            cands = []
            for s in range(32):
                v = board[s]
                if v == 0 or owner(v) != side:
                    continue
                king = v in (2, 4)
                for (dr, a, b) in nb[s]:
                    if not king and dr != mandir:
                        continue
                    if a < 0 or board[a] != 0:
                        continue
                    cands.append((s, a))
            if not cands:
                result = 2 if side == 0 else 1
                break
            if played == plies:
                result = 0
                break
            s, a = min(cands)
            v = board[s]
            board[s] = 0
            if v in (1, 3) and (a // 4) == far:
                v = 2 if side == 0 else 4
                crowned_total += 1
            board[a] = v
        played += 1
        side = 1 - side

    return (board, played, took[0], took[1], crowned_total, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    toks = list(pattern)
    n = len(toks)
    pos = [0]

    class Bad(Exception):
        pass

    def parse_alt():
        alts = [parse_seq()]
        while pos[0] < n and toks[pos[0]] == 30:
            pos[0] += 1
            alts.append(parse_seq())
        return ('alt', alts)

    def parse_seq():
        items = []
        while pos[0] < n and (toks[pos[0]] <= 26 or toks[pos[0]] == 31):
            items.append(parse_item())
        return ('seq', items)

    def parse_item():
        t = toks[pos[0]]
        if t <= 26:
            pos[0] += 1
            node = ('lit', t)
        else:
            pos[0] += 1
            node = parse_alt()
            if pos[0] < n and toks[pos[0]] == 32:
                pos[0] += 1
            else:
                raise Bad()
        while pos[0] < n and toks[pos[0]] in (27, 28, 29):
            op = toks[pos[0]]
            pos[0] += 1
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[op], node)
        return node

    valid = True
    try:
        tree = parse_alt()
        if pos[0] != n:
            valid = False
    except Bad:
        valid = False

    k = len(lens)
    if not valid:
        return ([False] * k, [-1] * k, 0, False)

    def ev(node, s, starts):
        kind = node[0]
        if kind == 'lit':
            c = node[1]
            ln = len(s)
            return {i + 1 for i in starts if i < ln and (c == 26 or s[i] == c)}
        if kind == 'seq':
            cur = set(starts)
            for it in node[1]:
                if not cur:
                    break
                cur = ev(it, s, cur)
            return cur
        if kind == 'alt':
            res = set()
            for sq in node[1]:
                res |= ev(sq, s, starts)
            return res
        if kind == 'opt':
            return set(starts) | ev(node[1], s, starts)
        if kind == 'star':
            return closure(node[1], s, set(starts))
        if kind == 'plus':
            first = ev(node[1], s, starts)
            return closure(node[1], s, first)
        raise Bad()

    def closure(child, s, starts):
        result = set(starts)
        frontier = set(starts)
        while frontier:
            new = ev(child, s, frontier) - result
            result |= new
            frontier = new
        return result

    full = []
    longest = []
    count = 0
    off = 0
    for ln in lens:
        s = list(chars[off:off + ln])
        off += ln
        ends = ev(tree, s, {0})
        f = ln in ends
        full.append(f)
        if f:
            count += 1
        longest.append(max(ends) if ends else -1)
    return (full, longest, count, True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    played = [set() for _ in range(n)]
    opps = [[] for _ in range(n)]
    whites = [0] * n
    last = [None] * n
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
        unpaired = pool
        pairs = []
        while unpaired:
            a = unpaired.pop(0)
            b = None
            for q in unpaired:
                if q not in played[a]:
                    b = q
                    break
            if b is None:
                b = unpaired[0]
                rematches += 1
            unpaired.remove(b)
            if whites[a] < whites[b]:
                w, bl = a, b
            elif whites[b] < whites[a]:
                w, bl = b, a
            else:
                a_black = last[a] == 'b'
                b_black = last[b] == 'b'
                if a_black and not b_black:
                    w, bl = a, b
                elif b_black and not a_black:
                    w, bl = b, a
                else:
                    w, bl = a, b
            pairs.append((w, bl))
        for (w, bl) in pairs:
            r = results[ri]
            ri += 1
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
            played[w].add(bl)
            played[bl].add(w)
            opps[w].append(bl)
            opps[bl].append(w)
    buch = [sum(score[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-score[p], -buch[p], -ratings[p], p))
    return (score, buch, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    from collections import deque
    P = len(price)
    lots = [[] for _ in range(P)]
    back = [deque() for _ in range(P)]
    on_way = [None] * P
    seq = [0]
    st = {'earned': 0, 'shipped': 0, 'discarded': 0, 'cancelled': 0, 'supplies': 0}

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
        seq[0] += 1
        lots[p].append([qty, expiry, seq[0]])
        while back[p] and stock(p) > 0:
            b = back[p][0]
            t = take(p, b[0])
            b[0] -= t
            if b[0] == 0:
                back[p].popleft()

    ne = len(ev_day)
    ei = 0
    for d in range(days):
        for p in range(P):
            keep = []
            for l in lots[p]:
                if l[1] < d:
                    st['discarded'] += l[0]
                else:
                    keep.append(l)
            lots[p] = keep
        for p in range(P):
            if on_way[p] == d:
                on_way[p] = None
                add_lot(p, rq[p], d + shelf[p])
        while ei < ne and ev_day[ei] == d:
            p = ev_prod[ei]
            q = ev_qty[ei]
            if ev_kind[ei] == 1:
                add_lot(p, q, ev_expiry[ei])
            else:
                if back[p]:
                    back[p].append([q, d])
                else:
                    t = take(p, q)
                    if q - t > 0:
                        back[p].append([q - t, d])
            ei += 1
        for p in range(P):
            newq = deque()
            for b in back[p]:
                if b[1] <= d - 7:
                    st['cancelled'] += b[0]
                else:
                    newq.append(b)
            back[p] = newq
        for p in range(P):
            if on_way[p] is None and stock(p) <= rp[p]:
                on_way[p] = d + lead[p]
                st['supplies'] += 1
    owed = sum(b[0] for p in range(P) for b in back[p])
    return ([stock(p) for p in range(P)], st['earned'], st['shipped'],
            st['discarded'], st['cancelled'], st['supplies'], owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    d1 = set()
    d2 = set()
    cnt = {'h1': 0, 'm1': 0, 'h2': 0, 'm2': 0, 'rd': 0, 'wr': 0}

    def use(level, s, a):
        st = level[a % s]
        st.remove(a)
        st.append(a)

    def put(level, s, w, dirty_set, a, dirty):
        st = level[a % s]
        ev = None
        ev_dirty = False
        if len(st) >= w:
            ev = st.pop(0)
            if ev in dirty_set:
                ev_dirty = True
                dirty_set.discard(ev)
        st.append(a)
        if dirty:
            dirty_set.add(a)
        else:
            dirty_set.discard(a)
        return ev, ev_dirty

    for a, wr in zip(addrs, writes):
        if a in L1[a % s1]:
            cnt['h1'] += 1
            use(L1, s1, a)
            if wr:
                d1.add(a)
        else:
            cnt['m1'] += 1
            if a in L2[a % s2]:
                cnt['h2'] += 1
                use(L2, s2, a)
            else:
                cnt['m2'] += 1
                cnt['rd'] += 1
                ev, evd = put(L2, s2, w2, d2, a, False)
                if ev is not None and evd:
                    cnt['wr'] += 1
            ev, evd = put(L1, s1, w1, d1, a, bool(wr))
            if ev is not None and evd:
                b = ev
                if b in L2[b % s2]:
                    use(L2, s2, b)
                    d2.add(b)
                else:
                    ev2, evd2 = put(L2, s2, w2, d2, b, True)
                    if ev2 is not None and evd2:
                        cnt['wr'] += 1
    blocks = []
    for st in L1:
        blocks.extend(st)
    return (cnt['h1'], cnt['m1'], cnt['h2'], cnt['m2'], cnt['rd'], cnt['wr'],
            len(d1) + len(d2), blocks)
```
