### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    deltas = [-width, 1, width, -1]
    hist = []
    read = pushes = blocked = undos = dead = 0
    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if hist:
                d, k = hist.pop()
                undos += 1
                if k is not None:
                    boxes[k] = player
                player -= deltas[d]
            continue
        dl = deltas[m]
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
                    and (cells[u - width] == 1 or cells[u + width] == 1)
                    and (cells[u - 1] == 1 or cells[u + 1] == 1)):
                dead += 1
            hist.append((m, k))
        else:
            player = t
            hist.append((m, None))
    solved = all(cells[b] == 2 for b in boxes)
    return (player, boxes, read, len(hist), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    board = list(board)
    rc = []
    idx = {}
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        rc.append((r, c))
        idx[(r, c)] = i

    def nb(i, dr, dc):
        r, c = rc[i]
        return idx.get((r + dr, c + dc))

    def side(p):
        return 0 if p in (1, 2) else 1

    def dirs(p):
        if p == 1:
            return [(-1, -1), (-1, 1)]
        if p == 3:
            return [(1, -1), (1, 1)]
        return [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def far_row(p):
        return 0 if side(p) == 0 else 7

    def captures(sd):
        results = []

        def dfs(pos, piece, b, land, caps, start):
            found = False
            for dr, dc in dirs(piece):
                adj = nb(pos, dr, dc)
                if adj is None:
                    continue
                beyond = nb(adj, dr, dc)
                if beyond is None:
                    continue
                if b[adj] != 0 and side(b[adj]) != sd and b[beyond] == 0:
                    found = True
                    saved = b[adj]
                    b[adj] = 0
                    newp = piece
                    crowned = False
                    if piece in (1, 3) and rc[beyond][0] == far_row(piece):
                        newp = piece + 1
                        crowned = True
                    nland = land + [beyond]
                    ncaps = caps + [adj]
                    if crowned:
                        results.append((-len(ncaps), start, nland, ncaps, newp, True))
                    else:
                        dfs(beyond, newp, b, nland, ncaps, start)
                    b[adj] = saved
            if not found and land:
                results.append((-len(caps), start, land, caps, piece, False))

        for i in range(32):
            p = board[i]
            if p != 0 and side(p) == sd:
                b = list(board)
                b[i] = 0
                dfs(i, p, b, [], [], i)
        return results

    def steps(sd):
        best = None
        for i in range(32):
            p = board[i]
            if p == 0 or side(p) != sd:
                continue
            for dr, dc in dirs(p):
                j = nb(i, dr, dc)
                if j is not None and board[j] == 0:
                    cand = (i, j)
                    if best is None or cand < best:
                        best = cand
        return best

    played = 0
    took = [0, 0]
    crowned_n = 0
    result = 0
    sd = turn
    while True:
        caps = captures(sd)
        st = None
        if not caps:
            st = steps(sd)
            if st is None:
                result = 2 if sd == 0 else 1
                break
        if played >= plies:
            result = 0
            break
        if caps:
            mv = min(caps, key=lambda x: (x[0], x[1], x[2]))
            _, start, land, captured, newp, crowned = mv
            board[start] = 0
            for s in captured:
                board[s] = 0
            board[land[-1]] = newp
            took[sd] += len(captured)
            if crowned:
                crowned_n += 1
        else:
            i, j = st
            p = board[i]
            board[i] = 0
            if p in (1, 3) and rc[j][0] == far_row(p):
                p += 1
                crowned_n += 1
            board[j] = p
        played += 1
        sd = 1 - sd
    return (board, played, took[0], took[1], crowned_n, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    n = len(pattern)
    pos = [0]

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
                raise ValueError
            pos[0] += 1
        else:
            raise ValueError
        while pos[0] < n and pattern[pos[0]] in (27, 28, 29):
            op = pattern[pos[0]]
            pos[0] += 1
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[op], node)
        return node

    try:
        ast = parse_alt()
        if pos[0] != n:
            raise ValueError
    except ValueError:
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    def ev(node, starts, s):
        k = node[0]
        if k == 'lit':
            return {p + 1 for p in starts if p < len(s) and s[p] == node[1]}
        if k == 'any':
            return {p + 1 for p in starts if p < len(s)}
        if k == 'seq':
            cur = set(starts)
            for it in node[1]:
                cur = ev(it, cur, s)
                if not cur:
                    break
            return cur
        if k == 'alt':
            out = set()
            for sq in node[1]:
                out |= ev(sq, starts, s)
            return out
        if k == 'opt':
            return set(starts) | ev(node[1], starts, s)
        if k == 'star':
            return star(node[1], starts, s)
        if k == 'plus':
            first = ev(node[1], starts, s)
            return star(node[1], first, s)
        raise ValueError

    def star(child, starts, s):
        result = set(starts)
        frontier = set(starts)
        while frontier:
            new = ev(child, frontier, s) - result
            result |= new
            frontier = new
        return result

    full = []
    longest = []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        ends = ev(ast, {0}, s)
        full.append(L in ends)
        longest.append(max(ends) if ends else -1)
    return (full, longest, sum(1 for f in full if f), True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    scores = [0] * n
    whites = [0] * n
    last = [None] * n
    had_bye = [False] * n
    played = [set() for _ in range(n)]
    opps = [[] for _ in range(n)]
    rematches = 0
    half = n // 2
    gi = 0
    for rd in range(rounds):
        order = sorted(range(n), key=lambda p: (-scores[p], -ratings[p], p))
        avail = list(order)
        bye = None
        if n % 2 == 1:
            for p in reversed(order):
                if not had_bye[p]:
                    bye = p
                    break
            if bye is not None:
                had_bye[bye] = True
                avail.remove(bye)
        pairs = []
        unpaired = list(avail)
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
            pairs.append((a, b))
        for a, b in pairs:
            if whites[a] < whites[b]:
                w, bl = a, b
            elif whites[b] < whites[a]:
                w, bl = b, a
            else:
                la = last[a] == 'B'
                lb = last[b] == 'B'
                if la and not lb:
                    w, bl = a, b
                elif lb and not la:
                    w, bl = b, a
                else:
                    w, bl = a, b
            r = results[gi]
            gi += 1
            if r == 0:
                scores[w] += 2
            elif r == 1:
                scores[w] += 1
                scores[bl] += 1
            else:
                scores[bl] += 2
            whites[w] += 1
            last[w] = 'W'
            last[bl] = 'B'
            played[a].add(b)
            played[b].add(a)
            opps[a].append(b)
            opps[b].append(a)
        if bye is not None:
            scores[bye] += 2
    buch = [sum(scores[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-scores[p], -buch[p], -ratings[p], p))
    return (scores, buch, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]  # [qty, expiry, seq]
    back = [[] for _ in range(P)]  # [owed, placed]
    due = [None] * P
    st = {'seq': 0, 'earned': 0, 'shipped': 0, 'discarded': 0,
          'cancelled': 0, 'supplies': 0}

    def stock(p):
        return sum(l[0] for l in lots[p])

    def take(p, q):
        got = 0
        lots[p].sort(key=lambda l: (l[1], l[2]))
        while q > got and lots[p]:
            l = lots[p][0]
            t = min(l[0], q - got)
            l[0] -= t
            got += t
            if l[0] == 0:
                lots[p].pop(0)
        st['shipped'] += got
        st['earned'] += got * price[p]
        return got

    def arrive(p, qty, expiry):
        lots[p].append([qty, expiry, st['seq']])
        st['seq'] += 1
        while back[p] and stock(p) > 0:
            b = back[p][0]
            got = take(p, b[0])
            b[0] -= got
            if b[0] == 0:
                back[p].pop(0)

    e = 0
    ne = len(ev_day)
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
            if due[p] == d:
                due[p] = None
                arrive(p, rq[p], d + shelf[p])
        while e < ne and ev_day[e] == d:
            p = ev_prod[e]
            q = ev_qty[e]
            if ev_kind[e] == 1:
                arrive(p, q, ev_expiry[e])
            else:
                if back[p]:
                    back[p].append([q, d])
                else:
                    got = take(p, min(q, stock(p)))
                    if q - got > 0:
                        back[p].append([q - got, d])
            e += 1
        for p in range(P):
            keep = []
            for b in back[p]:
                if b[1] <= d - 7:
                    st['cancelled'] += b[0]
                else:
                    keep.append(b)
            back[p] = keep
        for p in range(P):
            if due[p] is None and stock(p) <= rp[p]:
                due[p] = d + lead[p]
                st['supplies'] += 1
    owed = sum(b[0] for p in range(P) for b in back[p])
    return ([stock(p) for p in range(P)], st['earned'], st['shipped'],
            st['discarded'], st['cancelled'], st['supplies'], owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    l1 = [[] for _ in range(s1)]
    l2 = [[] for _ in range(s2)]
    d1 = set()
    d2 = set()
    c = {'h1': 0, 'm1': 0, 'h2': 0, 'm2': 0, 'rd': 0, 'wr': 0}

    def put2(b, dirty):
        s = l2[b % s2]
        if len(s) >= w2:
            ev = s.pop(0)
            if ev in d2:
                d2.discard(ev)
                c['wr'] += 1
        s.append(b)
        if dirty:
            d2.add(b)

    for a, w in zip(addrs, writes):
        s = l1[a % s1]
        if a in s:
            c['h1'] += 1
            s.remove(a)
            s.append(a)
            if w:
                d1.add(a)
            continue
        c['m1'] += 1
        t = l2[a % s2]
        if a in t:
            c['h2'] += 1
            t.remove(a)
            t.append(a)
        else:
            c['m2'] += 1
            c['rd'] += 1
            put2(a, False)
        evicted = None
        if len(s) >= w1:
            evicted = s.pop(0)
        s.append(a)
        if w:
            d1.add(a)
        if evicted is not None and evicted in d1:
            d1.discard(evicted)
            t = l2[evicted % s2]
            if evicted in t:
                t.remove(evicted)
                t.append(evicted)
                d2.add(evicted)
            else:
                put2(evicted, True)
    blocks = []
    for s in l1:
        blocks.extend(s)
    return (c['h1'], c['m1'], c['h2'], c['m2'], c['rd'], c['wr'],
            len(d1) + len(d2), blocks)
```
