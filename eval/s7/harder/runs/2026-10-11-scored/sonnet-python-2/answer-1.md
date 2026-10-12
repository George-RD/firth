### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    w = width
    delta = [-w, 1, w, -1]
    hist = []
    read = pushes = blocked = undos = dead = 0
    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if hist:
                dirn, k = hist.pop()
                dl = delta[dirn]
                if k >= 0:
                    boxes[k] = player
                player -= dl
                undos += 1
            continue
        dl = delta[m]
        t = player + dl
        if cells[t] == 1:
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + dl
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue
            boxes[k] = u
            player = t
            pushes += 1
            if (cells[u] != 2
                    and (cells[u - w] == 1 or cells[u + w] == 1)
                    and (cells[u - 1] == 1 or cells[u + 1] == 1)):
                dead += 1
            hist.append((m, k))
        else:
            player = t
            hist.append((m, -1))
    solved = all(cells[b] == 2 for b in boxes)
    return (player, boxes, read, len(hist), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    board = list(board)
    rc = [(i // 4, 2 * (i % 4) + (1 if (i // 4) % 2 == 0 else 0)) for i in range(32)]
    rc_sq = {rc[i]: i for i in range(32)}

    def nb(i, dr, dc):
        r, c = rc[i]
        return rc_sq.get((r + dr, c + dc))

    def side(p):
        return 0 if p in (1, 2) else 1

    def dirs_for(p):
        if p in (2, 4):
            return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        if p == 1:
            return [(-1, -1), (-1, 1)]
        return [(1, -1), (1, 1)]

    def far_row(s):
        return 0 if s == 0 else 7

    def dfs(b, cur, piece, start, lands, caps, out, sd):
        found = False
        for dr, dc in dirs_for(piece):
            m = nb(cur, dr, dc)
            if m is None or b[m] == 0 or side(b[m]) == sd:
                continue
            l = nb(m, dr, dc)
            if l is None or b[l] != 0:
                continue
            found = True
            saved = b[m]
            b[m] = 0
            if piece in (1, 3) and rc[l][0] == far_row(sd):
                out.append((len(lands) + 1, start, lands + [l], caps + [m], l, True))
            else:
                dfs(b, l, piece, start, lands + [l], caps + [m], out, sd)
            b[m] = saved
        if not found and lands:
            out.append((len(lands), start, lands, caps, cur, False))

    def captures(sd):
        out = []
        for s in range(32):
            p = board[s]
            if p != 0 and side(p) == sd:
                b = board[:]
                b[s] = 0
                dfs(b, s, p, s, [], [], out, sd)
        return out

    def steps(sd):
        best = None
        for s in range(32):
            p = board[s]
            if p != 0 and side(p) == sd:
                for dr, dc in dirs_for(p):
                    d = nb(s, dr, dc)
                    if d is not None and board[d] == 0:
                        if best is None or (s, d) < best:
                            best = (s, d)
        return best

    played = 0
    took = [0, 0]
    crowned = 0
    result = 0
    t = turn
    while True:
        caps = captures(t)
        st = None
        if not caps:
            st = steps(t)
            if st is None:
                result = 2 if t == 0 else 1
                break
        if played == plies:
            break
        if caps:
            best = min(caps, key=lambda x: (-x[0], x[1], x[2]))
            cnt, start, lands, cp, final, crowns = best
            piece = board[start]
            board[start] = 0
            for m in cp:
                board[m] = 0
            if crowns:
                piece = 2 if t == 0 else 4
                crowned += 1
            board[final] = piece
            took[t] += cnt
        else:
            s, d = st
            piece = board[s]
            board[s] = 0
            if piece in (1, 3) and rc[d][0] == far_row(t):
                piece = 2 if t == 0 else 4
                crowned += 1
            board[d] = piece
        played += 1
        t = 1 - t
    return (board, played, took[0], took[1], crowned, result)
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
        while pos[0] < n and pattern[pos[0]] not in (30, 32):
            items.append(parse_item())
        return ('seq', items)

    def parse_item():
        node = parse_atom()
        while pos[0] < n and pattern[pos[0]] in (27, 28, 29):
            op = pattern[pos[0]]
            pos[0] += 1
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[op], node)
        return node

    def parse_atom():
        if pos[0] >= n:
            raise Bad()
        t = pattern[pos[0]]
        if t <= 25:
            pos[0] += 1
            return ('lit', t)
        if t == 26:
            pos[0] += 1
            return ('any',)
        if t == 31:
            pos[0] += 1
            node = parse_alt()
            if pos[0] >= n or pattern[pos[0]] != 32:
                raise Bad()
            pos[0] += 1
            return node
        raise Bad()

    try:
        root = parse_alt()
        if pos[0] != n:
            raise Bad()
        valid = True
    except Bad:
        valid = False

    k = len(lens)
    if not valid:
        return ([False] * k, [-1] * k, 0, False)

    def ev(node, s, cur):
        kind = node[0]
        if kind == 'lit':
            return {p + 1 for p in cur if p < len(s) and s[p] == node[1]}
        if kind == 'any':
            return {p + 1 for p in cur if p < len(s)}
        if kind == 'alt':
            res = set()
            for sq in node[1]:
                res |= ev(sq, s, cur)
            return res
        if kind == 'seq':
            c = set(cur)
            for it in node[1]:
                c = ev(it, s, c)
                if not c:
                    break
            return c
        if kind == 'opt':
            return set(cur) | ev(node[1], s, cur)
        if kind == 'star':
            res = set(cur)
            frontier = set(cur)
            while frontier:
                new = ev(node[1], s, frontier) - res
                res |= new
                frontier = new
            return res
        if kind == 'plus':
            first = ev(node[1], s, cur)
            res = set(first)
            frontier = set(first)
            while frontier:
                new = ev(node[1], s, frontier) - res
                res |= new
                frontier = new
            return res
        raise Bad()

    full = []
    longest = []
    off = 0
    for ln in lens:
        s = chars[off:off + ln]
        off += ln
        ends = ev(root, s, {0})
        full.append(ln in ends)
        longest.append(max(ends) if ends else -1)
    return (full, longest, sum(1 for f in full if f), True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    whites = [0] * n
    last = [None] * n
    had_bye = [False] * n
    played = [set() for _ in range(n)]
    opps = [[] for _ in range(n)]
    rematches = 0
    ri = 0
    for _ in range(rounds):
        rank = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        if n % 2 == 1:
            for p in reversed(rank):
                if not had_bye[p]:
                    had_bye[p] = True
                    score[p] += 2
                    rank.remove(p)
                    break
        pos = {p: i for i, p in enumerate(rank)}
        paired = set()
        pairs = []
        for a in rank:
            if a in paired:
                continue
            paired.add(a)
            cand = None
            for b in rank:
                if b not in paired and b not in played[a]:
                    cand = b
                    break
            if cand is None:
                for b in rank:
                    if b not in paired:
                        cand = b
                        break
                rematches += 1
            b = cand
            paired.add(b)
            if whites[a] < whites[b]:
                w, bl = a, b
            elif whites[b] < whites[a]:
                w, bl = b, a
            else:
                la = last[a] == 'b'
                lb = last[b] == 'b'
                if la and not lb:
                    w, bl = a, b
                elif lb and not la:
                    w, bl = b, a
                else:
                    w, bl = a, b
            pairs.append((w, bl))
        for w, bl in pairs:
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
    P = len(price)
    lots = [[] for _ in range(P)]  # [expiry, seq, qty]
    back = [[] for _ in range(P)]  # [owed, placed]
    pending = [None] * P
    st = {'seq': 0, 'earned': 0, 'shipped': 0, 'disc': 0, 'canc': 0, 'sup': 0}

    def stock(p):
        return sum(l[2] for l in lots[p])

    def take(p, q):
        got = 0
        lots[p].sort(key=lambda l: (l[0], l[1]))
        while q > 0 and lots[p]:
            l = lots[p][0]
            t = min(q, l[2])
            l[2] -= t
            q -= t
            got += t
            if l[2] == 0:
                lots[p].pop(0)
        st['shipped'] += got
        st['earned'] += got * price[p]
        return got

    def arrive(p, qty, expiry):
        lots[p].append([expiry, st['seq'], qty])
        st['seq'] += 1
        while back[p] and stock(p) > 0:
            b = back[p][0]
            got = take(p, b[0])
            b[0] -= got
            if b[0] == 0:
                back[p].pop(0)

    ei = 0
    E = len(ev_day)
    for d in range(days):
        for p in range(P):
            keep = []
            for l in lots[p]:
                if l[0] < d:
                    st['disc'] += l[2]
                else:
                    keep.append(l)
            lots[p] = keep
        for p in range(P):
            if pending[p] == d:
                pending[p] = None
                arrive(p, rq[p], d + shelf[p])
        while ei < E and ev_day[ei] == d:
            p = ev_prod[ei]
            q = ev_qty[ei]
            if ev_kind[ei] == 1:
                arrive(p, q, ev_expiry[ei])
            else:
                if back[p]:
                    back[p].append([q, d])
                else:
                    got = take(p, q)
                    if q - got > 0:
                        back[p].append([q - got, d])
            ei += 1
        for p in range(P):
            keep = []
            for b in back[p]:
                if b[1] <= d - 7:
                    st['canc'] += b[0]
                else:
                    keep.append(b)
            back[p] = keep
        for p in range(P):
            if pending[p] is None and stock(p) <= rp[p]:
                pending[p] = d + lead[p]
                st['sup'] += 1
    owed = sum(b[0] for p in range(P) for b in back[p])
    return ([stock(p) for p in range(P)], st['earned'], st['shipped'], st['disc'],
            st['canc'], st['sup'], owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]  # entries [block, dirty], LRU first
    L2 = [[] for _ in range(s2)]
    st = {'h1': 0, 'm1': 0, 'h2': 0, 'm2': 0, 'rd': 0, 'wr': 0}

    def find(s, a):
        for i, e in enumerate(s):
            if e[0] == a:
                return i
        return -1

    def put(s, ways, a, dirty):
        # returns evicted entry or None
        ev = None
        if len(s) >= ways:
            ev = s.pop(0)
        s.append([a, dirty])
        return ev

    def put_l2(a, dirty):
        ev = put(L2[a % s2], w2, a, dirty)
        if ev is not None and ev[1]:
            st['wr'] += 1

    for a, wflag in zip(addrs, writes):
        s = L1[a % s1]
        i = find(s, a)
        if i >= 0:
            st['h1'] += 1
            e = s.pop(i)
            if wflag:
                e[1] = True
            s.append(e)
            continue
        st['m1'] += 1
        t = L2[a % s2]
        j = find(t, a)
        if j >= 0:
            st['h2'] += 1
            t.append(t.pop(j))
        else:
            st['m2'] += 1
            st['rd'] += 1
            put_l2(a, False)
        ev = put(s, w1, a, bool(wflag))
        if ev is not None and ev[1]:
            b = ev[0]
            t = L2[b % s2]
            j = find(t, b)
            if j >= 0:
                e = t.pop(j)
                e[1] = True
                t.append(e)
            else:
                put_l2(b, True)
    dirty = sum(1 for lv in (L1, L2) for s in lv for e in s if e[1])
    blocks = [e[0] for s in L1 for e in s]
    return (st['h1'], st['m1'], st['h2'], st['m2'], st['rd'], st['wr'], dirty, blocks)
```
