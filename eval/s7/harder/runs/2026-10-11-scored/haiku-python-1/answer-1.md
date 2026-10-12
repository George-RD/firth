### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    history = []
    read = pushes = blocked = undos = dead = 0
    deltas = (-width, 1, width, -1)

    def is_wall(i):
        return i < 0 or i >= len(cells) or cells[i] == 1

    def is_dead(u):
        return (cells[u] != 2
                and (is_wall(u - width) or is_wall(u + width))
                and (is_wall(u - 1) or is_wall(u + 1)))

    def solved():
        return all(cells[b] == 2 for b in boxes)

    for mv in moves:
        if solved():
            break
        read += 1
        if mv == 4:
            if history:
                rec = history.pop()
                undos += 1
                player = rec[1]
                if rec[0] == 'push':
                    boxes[rec[2]] = rec[3]
            continue
        t = player + deltas[mv]
        if is_wall(t):
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + deltas[mv]
            if is_wall(u) or u in boxes:
                blocked += 1
                continue
            boxes[k] = u
            history.append(('push', player, k, t))
            pushes += 1
            if is_dead(u):
                dead += 1
            player = t
        else:
            history.append(('step', player))
            player = t
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved())
```

### task: checkers
```python
def main(board, turn, plies):
    pos = []
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        pos.append((r, c))
    index = {p: i for i, p in enumerate(pos)}

    def owner(v):
        if v in (1, 2):
            return 'w'
        if v in (3, 4):
            return 'b'
        return None

    def dirs(side, king):
        if king:
            return ((-1, -1), (-1, 1), (1, -1), (1, 1))
        d = -1 if side == 'w' else 1
        return ((d, -1), (d, 1))

    def gen(work, side, king, sq, landings, caps, out):
        r, c = pos[sq]
        ext = False
        for dr, dc in dirs(side, king):
            n = index.get((r + dr, c + dc))
            m = index.get((r + 2 * dr, c + 2 * dc))
            if n is None or m is None:
                continue
            if work[n] == 0 or owner(work[n]) == side:
                continue
            if work[m] != 0:
                continue
            ext = True
            w2 = list(work)
            w2[n] = 0
            l2 = landings + (m,)
            c2 = caps + (n,)
            if not king and pos[m][0] == (0 if side == 'w' else 7):
                out.append((l2, c2, True))
            else:
                gen(w2, side, king, m, l2, c2, out)
        if not ext and caps:
            out.append((landings, caps, False))

    def captures(board, side):
        res = []
        for i in range(32):
            v = board[i]
            if owner(v) != side:
                continue
            work = list(board)
            work[i] = 0
            out = []
            gen(work, side, v in (2, 4), i, (), (), out)
            for l, cp, cr in out:
                res.append((i, l, cp, cr))
        return res

    def steps(board, side):
        res = []
        for i in range(32):
            v = board[i]
            if owner(v) != side:
                continue
            r, c = pos[i]
            for dr, dc in dirs(side, v in (2, 4)):
                n = index.get((r + dr, c + dc))
                if n is not None and board[n] == 0:
                    res.append((i, n))
        return res

    board = list(board)
    side = 'w' if turn == 0 else 'b'
    played = wt = bt = crowned = 0
    result = 0
    while True:
        caps = captures(board, side)
        sts = [] if caps else steps(board, side)
        if not caps and not sts:
            result = 2 if side == 'w' else 1
            break
        if played == plies:
            result = 0
            break
        if caps:
            i, l, cp, cr = min(caps, key=lambda x: (-len(x[2]), x[0], x[1]))
            kind = board[i]
            board[i] = 0
            for n in cp:
                board[n] = 0
            if side == 'w':
                wt += len(cp)
            else:
                bt += len(cp)
            if cr:
                kind = 2 if side == 'w' else 4
                crowned += 1
            board[l[-1]] = kind
        else:
            i, n = min(sts)
            kind = board[i]
            board[i] = 0
            if kind == 1 and pos[n][0] == 0:
                kind = 2
                crowned += 1
            elif kind == 3 and pos[n][0] == 7:
                kind = 4
                crowned += 1
            board[n] = kind
        played += 1
        side = 'b' if side == 'w' else 'w'
    return (board, played, wt, bt, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    t = pattern
    n_tok = len(t)
    postfix_kind = {27: 'star', 28: 'plus', 29: 'opt'}

    def parse_alt(i):
        node, i = parse_seq(i)
        seqs = [node]
        while i < n_tok and t[i] == 30:
            node, i = parse_seq(i + 1)
            seqs.append(node)
        return ('alt', seqs), i

    def parse_seq(i):
        items = []
        while i < n_tok and t[i] not in (30, 32):
            node, i = parse_item(i)
            items.append(node)
        return ('seq', items), i

    def parse_item(i):
        node, i = parse_atom(i)
        while i < n_tok and t[i] in postfix_kind:
            node = (postfix_kind[t[i]], node)
            i += 1
        return node, i

    def parse_atom(i):
        if i >= n_tok:
            raise ValueError('unexpected end')
        tok = t[i]
        if tok <= 25:
            return ('lit', tok), i + 1
        if tok == 26:
            return ('lit', None), i + 1
        if tok == 31:
            node, j = parse_alt(i + 1)
            if j >= n_tok or t[j] != 32:
                raise ValueError('unclosed group')
            return node, j + 1
        raise ValueError('operator where an atom should start')

    def star(x, starts, s):
        result = set(starts)
        frontier = set(starts)
        while frontier:
            new = ends(x, frontier, s) - result
            result |= new
            frontier = new
        return result

    def ends(node, starts, s):
        kind = node[0]
        if kind == 'lit':
            want = node[1]
            out = set()
            for p in starts:
                if p < len(s) and (want is None or s[p] == want):
                    out.add(p + 1)
            return out
        if kind == 'seq':
            cur = set(starts)
            for item in node[1]:
                cur = ends(item, cur, s)
                if not cur:
                    break
            return cur
        if kind == 'alt':
            out = set()
            for sub in node[1]:
                out |= ends(sub, starts, s)
            return out
        if kind == 'opt':
            return set(starts) | ends(node[1], starts, s)
        if kind == 'star':
            return star(node[1], starts, s)
        return star(node[1], ends(node[1], starts, s), s)

    try:
        root, end = parse_alt(0)
        if end != n_tok:
            raise ValueError('unmatched close')
    except ValueError:
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    full = []
    longest = []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        E = ends(root, {0}, s)
        full.append(len(s) in E)
        longest.append(max(E) if E else -1)
    count = sum(1 for f in full if f)
    return (full, longest, count, True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    had_bye = [False] * n
    opps = [[] for _ in range(n)]
    met = [set() for _ in range(n)]
    whites = [0] * n
    last = [None] * n
    rematches = 0
    k = 0
    for _ in range(rounds):
        rank = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        if n % 2 == 1:
            bye = None
            for p in reversed(rank):
                if not had_bye[p]:
                    bye = p
                    break
            rank.remove(bye)
            score[bye] += 2
            had_bye[bye] = True
        while rank:
            a = rank.pop(0)
            j = 0
            for idx, b in enumerate(rank):
                if b not in met[a]:
                    j = idx
                    break
            b = rank.pop(j)
            if b in met[a]:
                rematches += 1
            if whites[a] != whites[b]:
                w, bl = (a, b) if whites[a] < whites[b] else (b, a)
            elif (last[a] == 'b') != (last[b] == 'b'):
                w, bl = (a, b) if last[a] == 'b' else (b, a)
            else:
                w, bl = a, b
            res = results[k]
            k += 1
            if res == 0:
                score[w] += 2
            elif res == 1:
                score[a] += 1
                score[b] += 1
            else:
                score[bl] += 2
            whites[w] += 1
            last[w] = 'w'
            last[bl] = 'b'
            met[a].add(b)
            met[b].add(a)
            opps[a].append(b)
            opps[b].append(a)
    buch = [sum(score[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-score[p], -buch[p], -ratings[p], p))
    return (score, buch, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]    # each lot: [qty, expiry, arrival seq]
    backs = [[] for _ in range(P)]   # each backorder: [owed, placed day]
    on_way = [None] * P
    earned = shipped = discarded = cancelled = supplies = 0
    seq = 0

    def units(p):
        return sum(L[0] for L in lots[p])

    def take(p, q):
        lots[p].sort(key=lambda L: (L[1], L[2]))
        taken = 0
        for L in lots[p]:
            if q == 0:
                break
            t = min(L[0], q)
            L[0] -= t
            q -= t
            taken += t
        lots[p] = [L for L in lots[p] if L[0] > 0]
        return taken

    def fill(p):
        nonlocal shipped, earned
        while backs[p] and units(p) > 0:
            b = backs[p][0]
            got = take(p, min(b[0], units(p)))
            shipped += got
            earned += got * price[p]
            b[0] -= got
            if b[0] == 0:
                backs[p].pop(0)

    for d in range(days):
        # first: discard expired lots
        for p in range(P):
            kept = []
            for L in lots[p]:
                if L[1] < d:
                    discarded += L[0]
                else:
                    kept.append(L)
            lots[p] = kept
        # second: supplies due today arrive
        for p in range(P):
            if on_way[p] == d:
                on_way[p] = None
                seq += 1
                lots[p].append([rq[p], d + shelf[p], seq])
                fill(p)
        # third: events of the day, in order
        for e in range(len(ev_day)):
            if ev_day[e] != d:
                continue
            p = ev_prod[e]
            q = ev_qty[e]
            if ev_kind[e] == 1:
                seq += 1
                lots[p].append([q, ev_expiry[e], seq])
                fill(p)
            else:
                if backs[p]:
                    backs[p].append([q, d])
                else:
                    got = take(p, min(q, units(p)))
                    shipped += got
                    earned += got * price[p]
                    if q - got > 0:
                        backs[p].append([q - got, d])
        # fourth: cancel backorders placed on day d - 7 or earlier
        for p in range(P):
            kept = []
            for b in backs[p]:
                if b[1] <= d - 7:
                    cancelled += b[0]
                else:
                    kept.append(b)
            backs[p] = kept
        # fifth: order supplies where stock is low
        for p in range(P):
            if on_way[p] is None and units(p) <= rp[p]:
                on_way[p] = d + lead[p]
                supplies += 1

    stock = [units(p) for p in range(P)]
    owed = sum(b[0] for p in range(P) for b in backs[p])
    return (stock, earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]   # each set: [block, dirty] entries, LRU first
    L2 = [[] for _ in range(s2)]
    l1h = l1m = l2h = l2m = mr = mw = 0

    def locate(sets, n, b):
        st = sets[b % n]
        for idx in range(len(st)):
            if st[idx][0] == b:
                return st, idx
        return st, -1

    def touch(st, idx):
        e = st.pop(idx)
        st.append(e)
        return e

    def insert(sets, n, ways, b, dirty):
        st = sets[b % n]
        ev = None
        if len(st) >= ways:
            ev = st.pop(0)
        st.append([b, dirty])
        return ev

    for a, wr in zip(addrs, writes):
        st, idx = locate(L1, s1, a)
        if idx >= 0:
            l1h += 1
            e = touch(st, idx)
            if wr:
                e[1] = True
            continue
        l1m += 1
        st2, idx2 = locate(L2, s2, a)
        if idx2 >= 0:
            l2h += 1
            touch(st2, idx2)
        else:
            l2m += 1
            mr += 1
            ev = insert(L2, s2, w2, a, False)
            if ev is not None and ev[1]:
                mw += 1
        ev1 = insert(L1, s1, w1, a, bool(wr))
        if ev1 is not None and ev1[1]:
            st3, idx3 = locate(L2, s2, ev1[0])
            if idx3 >= 0:
                e3 = touch(st3, idx3)
                e3[1] = True
            else:
                ev2 = insert(L2, s2, w2, ev1[0], True)
                if ev2 is not None and ev2[1]:
                    mw += 1

    dirty = sum(1 for sets in (L1, L2) for st in sets for e in st if e[1])
    l1_blocks = [e[0] for st in L1 for e in st]
    return (l1h, l1m, l2h, l2m, mr, mw, dirty, l1_blocks)
```
