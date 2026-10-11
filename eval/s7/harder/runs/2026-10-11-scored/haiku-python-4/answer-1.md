### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    deltas = (-width, 1, width, -1)
    history = []
    read = pushes = blocked = undos = dead = 0

    def is_dead(b):
        if cells[b] == 2:
            return False
        vert = cells[b - width] == 1 or cells[b + width] == 1
        horiz = cells[b - 1] == 1 or cells[b + 1] == 1
        return vert and horiz

    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if history:
                prev_player, k, prev_box = history.pop()
                player = prev_player
                if k >= 0:
                    boxes[k] = prev_box
                undos += 1
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
            boxes[k] = u
            history.append((player, k, t))
            player = t
            pushes += 1
            if is_dead(u):
                dead += 1
        else:
            history.append((player, -1, -1))
            player = t

    solved = all(cells[b] == 2 for b in boxes)
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    board = list(board)
    coords = [(i // 4, 2 * (i % 4) + (1 if (i // 4) % 2 == 0 else 0)) for i in range(32)]
    idx = {rc: i for i, rc in enumerate(coords)}
    DIRS = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    nb = [[idx.get((r + dr, c + dc)) for dr, dc in DIRS] for (r, c) in coords]
    far = (0, 7)

    def owner(p):
        if p in (1, 2):
            return 0
        if p in (3, 4):
            return 1
        return -1

    def dirs(p):
        if p in (2, 4):
            return [0, 1, 2, 3]
        if p == 1:
            return [0, 1]
        return [2, 3]

    def caps(s, king, side, landings, taken):
        out = []
        if king:
            ds = [0, 1, 2, 3]
        else:
            ds = [0, 1] if side == 0 else [2, 3]
        for d in ds:
            mid = nb[s][d]
            if mid is None:
                continue
            land = nb[mid][d]
            if land is None:
                continue
            p = board[mid]
            if owner(p) != 1 - side or board[land] != 0:
                continue
            board[mid] = 0
            nl = landings + [land]
            nt = taken + [mid]
            if not king and coords[land][0] == far[side]:
                out.append((nl, nt))
            else:
                sub = caps(land, king, side, nl, nt)
                if sub:
                    out.extend(sub)
                else:
                    out.append((nl, nt))
            board[mid] = p
        return out

    def best_capture(side):
        cands = []
        for s in range(32):
            p = board[s]
            if owner(p) != side:
                continue
            board[s] = 0
            for nl, nt in caps(s, p in (2, 4), side, [], []):
                cands.append((-len(nt), s, nl, nt))
            board[s] = p
        return min(cands) if cands else None

    def best_step(side):
        cands = []
        for s in range(32):
            p = board[s]
            if owner(p) != side:
                continue
            for d in dirs(p):
                t = nb[s][d]
                if t is not None and board[t] == 0:
                    cands.append((s, t))
        return min(cands) if cands else None

    played = 0
    wt = bt = crowned = 0
    result = 0
    while True:
        side = (turn + played) % 2
        cap = best_capture(side)
        st = None
        if cap is None:
            st = best_step(side)
            if st is None:
                result = 2 if side == 0 else 1
                break
        if played == plies:
            result = 0
            break
        if cap is not None:
            _, s, nl, nt = cap
            p = board[s]
            board[s] = 0
            for m in nt:
                board[m] = 0
            if side == 0:
                wt += len(nt)
            else:
                bt += len(nt)
            last = nl[-1]
            if p in (1, 3) and coords[last][0] == far[side]:
                p += 1
                crowned += 1
            board[last] = p
        else:
            s, t = st
            p = board[s]
            board[s] = 0
            if p in (1, 3) and coords[t][0] == far[side]:
                p += 1
                crowned += 1
            board[t] = p
        played += 1

    return (board, played, wt, bt, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    class Bad(Exception):
        pass

    toks = list(pattern)
    L = len(toks)

    def parse_alt(i):
        seqs = []
        seq, i = parse_seq(i)
        seqs.append(seq)
        while i < L and toks[i] == 30:
            seq, i = parse_seq(i + 1)
            seqs.append(seq)
        return ('alt', seqs), i

    def parse_seq(i):
        items = []
        while i < L and toks[i] not in (30, 32):
            t = toks[i]
            if t <= 26 or t == 31:
                node, i = parse_item(i)
                items.append(node)
            else:
                raise Bad()
        return ('seq', items), i

    def parse_item(i):
        node, i = parse_atom(i)
        while i < L and toks[i] in (27, 28, 29):
            k = toks[i]
            kind = 'star' if k == 27 else ('plus' if k == 28 else 'opt')
            node = (kind, node)
            i += 1
        return node, i

    def parse_atom(i):
        t = toks[i]
        if t <= 25:
            return ('lit', t), i + 1
        if t == 26:
            return ('any',), i + 1
        node, j = parse_alt(i + 1)
        if j < L and toks[j] == 32:
            return node, j + 1
        raise Bad()

    def closure(body, s, starts):
        result = set(starts)
        frontier = set(starts)
        while frontier:
            new = set()
            for p in frontier:
                for q in ends(body, s, p):
                    if q not in result:
                        result.add(q)
                        new.add(q)
            frontier = new
        return result

    def ends(node, s, pos):
        k = node[0]
        n = len(s)
        if k == 'lit':
            return {pos + 1} if pos < n and s[pos] == node[1] else set()
        if k == 'any':
            return {pos + 1} if pos < n else set()
        if k == 'seq':
            cur = {pos}
            for it in node[1]:
                nxt = set()
                for p in cur:
                    nxt |= ends(it, s, p)
                cur = nxt
                if not cur:
                    break
            return cur
        if k == 'alt':
            out = set()
            for sq in node[1]:
                out |= ends(sq, s, pos)
            return out
        if k == 'opt':
            return {pos} | ends(node[1], s, pos)
        if k == 'star':
            return closure(node[1], s, {pos})
        # 'plus'
        return closure(node[1], s, ends(node[1], s, pos))

    try:
        root, j = parse_alt(0)
        if j != L:
            raise Bad()
    except (Bad, IndexError):
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    full = []
    longest = []
    off = 0
    for ln in lens:
        s = chars[off:off + ln]
        off += ln
        e = ends(root, s, 0)
        full.append(len(s) in e)
        longest.append(max(e) if e else -1)
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
    opps = [[] for _ in range(n)]
    played = set()
    rematches = 0
    k = 0
    for _ in range(rounds):
        order = sorted(range(n), key=lambda p: (-scores[p], -ratings[p], p))
        if n % 2 == 1:
            bye = next(p for p in reversed(order) if not had_bye[p])
            had_bye[bye] = True
            scores[bye] += 2
            order = [p for p in order if p != bye]
        unpaired = list(order)
        pairs = []
        while unpaired:
            a = unpaired.pop(0)
            j = 0
            for idx, q in enumerate(unpaired):
                if (min(a, q), max(a, q)) not in played:
                    j = idx
                    break
            b = unpaired.pop(j)
            pairs.append((a, b))
        games = []
        for a, b in pairs:
            if (min(a, b), max(a, b)) in played:
                rematches += 1
            if whites[a] < whites[b]:
                w, bl = a, b
            elif whites[b] < whites[a]:
                w, bl = b, a
            elif last[b] == 'B' and last[a] != 'B':
                w, bl = b, a
            else:
                w, bl = a, b
            games.append((w, bl))
        for w, bl in games:
            r = results[k]
            k += 1
            whites[w] += 1
            last[w] = 'W'
            last[bl] = 'B'
            opps[w].append(bl)
            opps[bl].append(w)
            played.add((min(w, bl), max(w, bl)))
            if r == 0:
                scores[w] += 2
            elif r == 1:
                scores[w] += 1
                scores[bl] += 1
            else:
                scores[bl] += 2
    buch = [sum(scores[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-scores[p], -buch[p], -ratings[p], p))
    return (scores, buch, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    backs = [[] for _ in range(P)]
    on_way = [None] * P
    earned = shipped = discarded = cancelled = supplies = 0
    seq = 0

    def stock(p):
        return sum(L[0] for L in lots[p])

    def take(p, q):
        lots[p].sort(key=lambda L: (L[1], L[2]))
        got = 0
        for L in lots[p]:
            if q == 0:
                break
            t = min(L[0], q)
            L[0] -= t
            q -= t
            got += t
        lots[p] = [L for L in lots[p] if L[0] > 0]
        return got

    def fill(p):
        nonlocal earned, shipped
        while backs[p] and stock(p) > 0:
            b = backs[p][0]
            t = take(p, min(b[0], stock(p)))
            shipped += t
            earned += t * price[p]
            b[0] -= t
            if b[0] == 0:
                backs[p].pop(0)

    def add_lot(p, qty, expiry):
        nonlocal seq
        lots[p].append([qty, expiry, seq])
        seq += 1
        fill(p)

    for d in range(days):
        for p in range(P):
            keep = []
            for L in lots[p]:
                if L[1] < d:
                    discarded += L[0]
                else:
                    keep.append(L)
            lots[p] = keep
        for p in range(P):
            if on_way[p] == d:
                on_way[p] = None
                add_lot(p, rq[p], d + shelf[p])
        for e in range(len(ev_day)):
            if ev_day[e] != d:
                continue
            p = ev_prod[e]
            q = ev_qty[e]
            if ev_kind[e] == 1:
                add_lot(p, q, ev_expiry[e])
            elif backs[p]:
                backs[p].append([q, d])
            else:
                t = take(p, min(q, stock(p)))
                shipped += t
                earned += t * price[p]
                if q - t > 0:
                    backs[p].append([q - t, d])
        for p in range(P):
            keep = []
            for b in backs[p]:
                if b[1] <= d - 7:
                    cancelled += b[0]
                else:
                    keep.append(b)
            backs[p] = keep
        for p in range(P):
            if on_way[p] is None and stock(p) <= rp[p]:
                on_way[p] = d + lead[p]
                supplies += 1

    owed = sum(b[0] for p in range(P) for b in backs[p])
    return ([stock(p) for p in range(P)], earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    h1 = m1 = h2 = m2 = mr = mw = 0

    def find(sets, nsets, blk):
        for i, e in enumerate(sets[blk % nsets]):
            if e[0] == blk:
                return i
        return -1

    def use(sets, nsets, blk, mark):
        s = sets[blk % nsets]
        i = find(sets, nsets, blk)
        e = s.pop(i)
        if mark:
            e[1] = True
        s.append(e)

    def place(sets, nsets, ways, blk, dirty):
        s = sets[blk % nsets]
        ev = s.pop(0) if len(s) >= ways else None
        s.append([blk, dirty])
        return ev

    for a, wr in zip(addrs, writes):
        if find(L1, s1, a) >= 0:
            h1 += 1
            use(L1, s1, a, bool(wr))
            continue
        m1 += 1
        if find(L2, s2, a) >= 0:
            h2 += 1
            use(L2, s2, a, False)
        else:
            m2 += 1
            mr += 1
            ev = place(L2, s2, w2, a, False)
            if ev is not None and ev[1]:
                mw += 1
        ev1 = place(L1, s1, w1, a, bool(wr))
        if ev1 is not None and ev1[1]:
            b = ev1[0]
            if find(L2, s2, b) >= 0:
                use(L2, s2, b, True)
            else:
                ev2 = place(L2, s2, w2, b, True)
                if ev2 is not None and ev2[1]:
                    mw += 1

    dirty = sum(e[1] for s in L1 + L2 for e in s)
    l1_blocks = [e[0] for s in L1 for e in s]
    return (h1, m1, h2, m2, mr, mw, dirty, l1_blocks)
```
