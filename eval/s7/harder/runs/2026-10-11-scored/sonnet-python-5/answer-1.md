### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    D = [-width, 1, width, -1]
    boxes = list(boxes)
    hist = []
    read = pushes = blocked = undos = dead = 0
    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if hist:
                d, k = hist.pop()
                player -= D[d]
                if k >= 0:
                    boxes[k] -= D[d]
                undos += 1
            continue
        d = D[m]
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
            boxes[k] = u
            player = t
            hist.append((m, k))
            pushes += 1
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
    board = list(board)

    def rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def sq(r, c):
        if r < 0 or r > 7 or c < 0 or c > 7:
            return -1
        if (r + c) % 2 == 0:
            return -1
        return r * 4 + c // 2

    # sanity: square index must be consistent with rc
    def side_of(p):
        if p in (1, 2):
            return 0
        if p in (3, 4):
            return 1
        return -1

    def dirs(p):
        if p == 1:
            return [-1]
        if p == 3:
            return [1]
        return [-1, 1]

    def is_man(p):
        return p in (1, 3)

    def far_row(p):
        return 0 if side_of(p) == 0 else 7

    def jumps(b, pos, p, side):
        res = []
        r, c = rc(pos)
        for dr in dirs(p):
            for dc in (-1, 1):
                m = sq(r + dr, c + dc)
                l = sq(r + 2 * dr, c + 2 * dc)
                if m < 0 or l < 0:
                    continue
                if b[m] != 0 and side_of(b[m]) == 1 - side and b[l] == 0:
                    res.append((m, l))
        return res

    def captures(b, side):
        best = None
        for s in range(32):
            p = b[s]
            if p == 0 or side_of(p) != side:
                continue
            bb = list(b)
            bb[s] = 0
            found = []

            def dfs(bd, pos, piece, count, lands, caps):
                js = jumps(bd, pos, piece, side)
                if not js:
                    if count > 0:
                        found.append((count, lands, caps, piece))
                    return
                for (m, l) in js:
                    nb = list(bd)
                    nb[m] = 0
                    npiece = piece
                    ended = False
                    if is_man(piece) and rc(l)[0] == far_row(piece):
                        npiece = piece + 1
                        ended = True
                    if ended:
                        found.append((count + 1, lands + [l], caps + [m], npiece))
                    else:
                        dfs(nb, l, npiece, count + 1, lands + [l], caps + [m])

            dfs(bb, s, p, 0, [], [])
            for (count, lands, caps, piece) in found:
                key = (-count, s, lands)
                if best is None or key < best[0]:
                    best = (key, s, lands, caps, piece, p)
        return best

    def steps(b, side):
        for s in range(32):
            p = b[s]
            if p == 0 or side_of(p) != side:
                continue
            r, c = rc(s)
            cand = []
            for dr in dirs(p):
                for dc in (-1, 1):
                    t = sq(r + dr, c + dc)
                    if t >= 0 and b[t] == 0:
                        cand.append(t)
            if cand:
                return (s, min(cand))
        return None

    played = 0
    took = [0, 0]
    crowned = 0
    result = 0
    side = turn
    while True:
        cap = captures(board, side)
        st = None
        if cap is None:
            st = steps(board, side)
            if st is None:
                result = 2 if side == 0 else 1
                break
        if played >= plies:
            break
        if cap is not None:
            key, s, lands, caps, piece, orig = cap
            board[s] = 0
            for m in caps:
                board[m] = 0
            board[lands[-1]] = piece
            if is_man(orig) and not is_man(piece):
                crowned += 1
            took[side] += len(caps)
        else:
            s, t = st
            p = board[s]
            board[s] = 0
            if is_man(p) and rc(t)[0] == far_row(p):
                p += 1
                crowned += 1
            board[t] = p
        played += 1
        side = 1 - side
    return (board, played, took[0], took[1], crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    pos = [0]
    n = len(pattern)

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
        t = pattern[pos[0]]
        if t <= 25:
            node = ('lit', t)
            pos[0] += 1
        elif t == 26:
            node = ('any',)
            pos[0] += 1
        elif t == 31:
            pos[0] += 1
            node = parse_alt()
            if pos[0] >= n or pattern[pos[0]] != 32:
                raise Bad()
            pos[0] += 1
        else:
            raise Bad()
        while pos[0] < n and pattern[pos[0]] in (27, 28, 29):
            op = pattern[pos[0]]
            pos[0] += 1
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[op], node)
        return node

    try:
        ast = parse_alt()
        if pos[0] != n:
            raise Bad()
        valid = True
    except Bad:
        valid = False
        ast = None

    def ev(node, s, starts):
        k = node[0]
        if k == 'lit':
            return {i + 1 for i in starts if i < len(s) and s[i] == node[1]}
        if k == 'any':
            return {i + 1 for i in starts if i < len(s)}
        if k == 'alt':
            out = set()
            for sq in node[1]:
                out |= ev(sq, s, starts)
            return out
        if k == 'seq':
            cur = set(starts)
            for it in node[1]:
                cur = ev(it, s, cur)
                if not cur:
                    break
            return cur
        if k == 'opt':
            return set(starts) | ev(node[1], s, starts)
        if k in ('star', 'plus'):
            if k == 'star':
                result = set(starts)
                frontier = set(starts)
            else:
                result = ev(node[1], s, starts)
                frontier = set(result)
            while frontier:
                new = ev(node[1], s, frontier) - result
                result |= new
                frontier = new
            return result
        return set()

    full = []
    longest = []
    count = 0
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        if not valid:
            full.append(False)
            longest.append(-1)
            continue
        ends = ev(ast, s, {0})
        f = L in ends
        full.append(f)
        if f:
            count += 1
        longest.append(max(ends) if ends else -1)
    if not valid:
        count = 0
    return (full, longest, count, valid)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    whites = [0] * n
    last = [None] * n  # 'W' or 'B'
    played = [set() for _ in range(n)]
    opps = [[] for _ in range(n)]
    had_bye = [False] * n
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
        paired = set()
        games = []
        for p in rank:
            if p in paired:
                continue
            paired.add(p)
            q = None
            for x in rank:
                if x not in paired and x not in played[p]:
                    q = x
                    break
            if q is None:
                for x in rank:
                    if x not in paired:
                        q = x
                        break
                if q is not None:
                    rematches += 1
            if q is None:
                continue
            paired.add(q)
            if whites[p] < whites[q]:
                w, b = p, q
            elif whites[q] < whites[p]:
                w, b = q, p
            else:
                lp = last[p] == 'B'
                lq = last[q] == 'B'
                if lp and not lq:
                    w, b = p, q
                elif lq and not lp:
                    w, b = q, p
                else:
                    w, b = p, q
            games.append((w, b))
        for (w, b) in games:
            r = results[ri]
            ri += 1
            if r == 0:
                score[w] += 2
            elif r == 1:
                score[w] += 1
                score[b] += 1
            else:
                score[b] += 2
            whites[w] += 1
            last[w] = 'W'
            last[b] = 'B'
            played[w].add(b)
            played[b].add(w)
            opps[w].append(b)
            opps[b].append(w)
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
    due = [None] * P
    st = {'seq': 0, 'earned': 0, 'shipped': 0, 'disc': 0, 'canc': 0, 'sup': 0}

    def stock(p):
        return sum(l[2] for l in lots[p])

    def take(p, q):
        got = 0
        while q > 0 and lots[p]:
            lots[p].sort(key=lambda l: (l[0], l[1]))
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

    def add_lot(p, qty, expiry):
        lots[p].append([expiry, st['seq'], qty])
        st['seq'] += 1
        while back[p] and stock(p) > 0:
            b = back[p][0]
            t = take(p, min(b[0], stock(p)))
            b[0] -= t
            if b[0] == 0:
                back[p].pop(0)

    E = len(ev_day)
    ei = 0
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
            if due[p] == d:
                due[p] = None
                add_lot(p, rq[p], d + shelf[p])
        while ei < E and ev_day[ei] == d:
            p = ev_prod[ei]
            q = ev_qty[ei]
            if ev_kind[ei] == 1:
                add_lot(p, q, ev_expiry[ei])
            else:
                if back[p]:
                    back[p].append([q, d])
                else:
                    t = take(p, min(q, stock(p)))
                    if q - t > 0:
                        back[p].append([q - t, d])
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
            if due[p] is None and stock(p) <= rp[p]:
                due[p] = d + lead[p]
                st['sup'] += 1
    owed = sum(b[0] for p in range(P) for b in back[p])
    return ([stock(p) for p in range(P)], st['earned'], st['shipped'],
            st['disc'], st['canc'], st['sup'], owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]  # entries [block, dirty], LRU first
    L2 = [[] for _ in range(s2)]
    c = {'h1': 0, 'm1': 0, 'h2': 0, 'm2': 0, 'rd': 0, 'wr': 0}

    def find(s, a):
        for i, e in enumerate(s):
            if e[0] == a:
                return i
        return -1

    def put2(a, dirty):
        s = L2[a % s2]
        if len(s) >= w2:
            ev = s.pop(0)
            if ev[1]:
                c['wr'] += 1
        s.append([a, dirty])

    for a, w in zip(addrs, writes):
        s = L1[a % s1]
        i = find(s, a)
        if i >= 0:
            c['h1'] += 1
            e = s.pop(i)
            if w:
                e[1] = True
            s.append(e)
            continue
        c['m1'] += 1
        t = L2[a % s2]
        j = find(t, a)
        if j >= 0:
            c['h2'] += 1
            t.append(t.pop(j))
        else:
            c['m2'] += 1
            c['rd'] += 1
            put2(a, False)
        evicted = None
        if len(s) >= w1:
            evicted = s.pop(0)
        s.append([a, bool(w)])
        if evicted is not None and evicted[1]:
            b = evicted[0]
            t = L2[b % s2]
            j = find(t, b)
            if j >= 0:
                e = t.pop(j)
                e[1] = True
                t.append(e)
            else:
                put2(b, True)
    dirty = sum(1 for lv in (L1, L2) for s in lv for e in s if e[1])
    blocks = [e[0] for s in L1 for e in s]
    return (c['h1'], c['m1'], c['h2'], c['m2'], c['rd'], c['wr'], dirty, blocks)
```
