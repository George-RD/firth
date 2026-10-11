### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    deltas = [-width, 1, width, -1]
    goal = lambda c: cells[c] == 2
    wall = lambda c: cells[c] == 1
    history = []  # (prev_player, box_index or -1, box_from)
    read = 0
    pushes = blocked = undos = dead = 0
    for m in moves:
        if all(goal(b) for b in boxes):
            break
        read += 1
        if m == 4:
            if history:
                prev, k, frm = history.pop()
                player = prev
                if k >= 0:
                    boxes[k] = frm
                undos += 1
            continue
        d = deltas[m]
        t = player + d
        if wall(t):
            blocked += 1
            continue
        if t in boxes:
            u = t + d
            if wall(u) or u in boxes:
                blocked += 1
                continue
            k = boxes.index(t)
            boxes[k] = u
            history.append((player, k, t))
            player = t
            pushes += 1
            if not goal(u):
                vert = wall(u - width) or wall(u + width)
                horiz = wall(u - 1) or wall(u + 1)
                if vert and horiz:
                    dead += 1
        else:
            history.append((player, -1, -1))
            player = t
    solved = all(goal(b) for b in boxes)
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    board = list(board)

    def rc(i):
        r = i // 4
        return r, 2 * (i % 4) + (1 if r % 2 == 0 else 0)

    def sq(r, c):
        if r < 0 or r > 7 or c < 0 or c > 7:
            return None
        if (r + c) % 2 == 0:
            return None
        return r * 4 + c // 2

    def side(p):
        return 0 if p in (1, 2) else 1

    def dirs(p):
        if p in (2, 4):
            return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        if p == 1:
            return [(-1, -1), (-1, 1)]
        return [(1, -1), (1, 1)]

    def far_row(p):
        return 0 if p == 1 else 7

    def jumps_from(b, pos, p):
        res = []
        r, c = rc(pos)
        for dr, dc in dirs(p):
            m = sq(r + dr, c + dc)
            l = sq(r + 2 * dr, c + 2 * dc)
            if m is None or l is None:
                continue
            if b[m] != 0 and side(b[m]) != side(p) and b[l] == 0:
                res.append((m, l))
        return res

    def captures(b, start, p):
        # returns list of (count, landings, crowned)
        out = []
        b2 = list(b)
        b2[start] = 0

        def dfs(pos, piece, cur_b, lands, count):
            js = jumps_from(cur_b, pos, piece)
            if not js:
                out.append((count, list(lands), piece != p))
                return
            for m, l in js:
                saved = cur_b[m]
                cur_b[m] = 0
                newpiece = piece
                crowned_now = False
                if piece in (1, 3) and rc(l)[0] == far_row(piece):
                    newpiece = piece + 1
                    crowned_now = True
                lands.append(l)
                if crowned_now:
                    out.append((count + 1, list(lands), True))
                else:
                    dfs(l, newpiece, cur_b, lands, count + 1)
                lands.pop()
                cur_b[m] = saved

        dfs(start, p, b2, [], 0)
        return out

    wt = bt = crowned = 0
    played = 0
    result = 0
    while True:
        s = (turn + played) % 2
        best = None  # (-count, start, lands, crowned, captured_squares)
        for i in range(32):
            p = board[i]
            if p == 0 or side(p) != s:
                continue
            for cnt, lands, cr in captures(board, i, p):
                if cnt == 0:
                    continue
                key = (-cnt, i, lands)
                if best is None or key < best[0]:
                    best = (key, i, lands, cr)
        step = None
        if best is None:
            for i in range(32):
                p = board[i]
                if p == 0 or side(p) != s:
                    continue
                r, c = rc(i)
                cands = []
                for dr, dc in dirs(p):
                    t = sq(r + dr, c + dc)
                    if t is not None and board[t] == 0:
                        cands.append(t)
                if cands:
                    step = (i, min(cands))
                    break
        if best is None and step is None:
            result = 2 if s == 0 else 1
            break
        if played == plies:
            result = 0
            break
        if best is not None:
            _, start, lands, cr = best
            p = board[start]
            board[start] = 0
            pos = start
            taken = 0
            for l in lands:
                r1, c1 = rc(pos)
                r2, c2 = rc(l)
                m = sq((r1 + r2) // 2, (c1 + c2) // 2)
                board[m] = 0
                taken += 1
                pos = l
            if cr:
                p = p + 1
                crowned += 1
            board[pos] = p
            if s == 0:
                wt += taken
            else:
                bt += taken
        else:
            i, t = step
            p = board[i]
            board[i] = 0
            if p in (1, 3) and rc(t)[0] == far_row(p):
                p += 1
                crowned += 1
            board[t] = p
        played += 1
    return (board, played, wt, bt, crowned, result)
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
        while pos[0] < n:
            t = pattern[pos[0]]
            if t == 30 or t == 32:
                break
            if t <= 26:
                pos[0] += 1
                node = ('any',) if t == 26 else ('lit', t)
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
            items.append(node)
        return ('seq', items)

    try:
        tree = parse_alt()
        if pos[0] != n:
            raise ValueError
        valid = True
    except ValueError:
        valid = False

    k = len(lens)
    if not valid:
        return ([False] * k, [-1] * k, 0, False)

    def ends(node, S, s):
        kind = node[0]
        if not S:
            return set()
        if kind == 'lit':
            return {i + 1 for i in S if i < len(s) and s[i] == node[1]}
        if kind == 'any':
            return {i + 1 for i in S if i < len(s)}
        if kind == 'seq':
            cur = S
            for it in node[1]:
                cur = ends(it, cur, s)
                if not cur:
                    break
            return cur
        if kind == 'alt':
            r = set()
            for sq_ in node[1]:
                r |= ends(sq_, S, s)
            return r
        if kind == 'opt':
            return S | ends(node[1], S, s)
        if kind == 'star':
            return star(node[1], S, s)
        if kind == 'plus':
            return star(node[1], ends(node[1], S, s), s)

    def star(child, S, s):
        result = set(S)
        frontier = set(S)
        while frontier:
            new = ends(child, frontier, s) - result
            result |= new
            frontier = new
        return result

    full = []
    longest = []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        e = ends(tree, {0}, s)
        full.append(L in e)
        longest.append(max(e) if e else -1)
    return (full, longest, sum(1 for f in full if f), True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    played = [set() for _ in range(n)]
    opps = [[] for _ in range(n)]
    whites = [0] * n
    last = [None] * n  # 'w' or 'b'
    had_bye = [False] * n
    rematches = 0
    ri = 0
    for _ in range(rounds):
        order = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        bye = None
        if n % 2 == 1:
            for p in reversed(order):
                if not had_bye[p]:
                    bye = p
                    break
            had_bye[bye] = True
            score[bye] += 2
        pool = [p for p in order if p != bye]
        paired = set()
        pairs = []
        for p in pool:
            if p in paired:
                continue
            paired.add(p)
            cand = [q for q in pool if q not in paired]
            q = None
            for x in cand:
                if x not in played[p]:
                    q = x
                    break
            if q is None:
                q = cand[0]
                rematches += 1
            paired.add(q)
            if whites[p] < whites[q]:
                w, b = p, q
            elif whites[q] < whites[p]:
                w, b = q, p
            else:
                pb = last[p] == 'b'
                qb = last[q] == 'b'
                if pb and not qb:
                    w, b = p, q
                elif qb and not pb:
                    w, b = q, p
                else:
                    w, b = p, q
            pairs.append((w, b))
        for w, b in pairs:
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
            last[w] = 'w'
            last[b] = 'b'
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
    back = [[] for _ in range(P)]  # [owed, day]
    due = [None] * P
    seq = [0]
    st = {'earned': 0, 'shipped': 0, 'discarded': 0, 'cancelled': 0, 'supplies': 0}

    def stock(p):
        return sum(l[2] for l in lots[p])

    def take(p, q):
        lots[p].sort(key=lambda l: (l[0], l[1]))
        got = 0
        while q > 0 and lots[p]:
            l = lots[p][0]
            n = min(q, l[2])
            l[2] -= n
            q -= n
            got += n
            if l[2] == 0:
                lots[p].pop(0)
        st['shipped'] += got
        st['earned'] += got * price[p]
        return got

    def arrive(p, qty, expiry):
        seq[0] += 1
        lots[p].append([expiry, seq[0], qty])
        while back[p] and stock(p) > 0:
            b = back[p][0]
            n = take(p, min(b[0], stock(p)))
            b[0] -= n
            if b[0] == 0:
                back[p].pop(0)

    ei = 0
    E = len(ev_day)
    for d in range(days):
        for p in range(P):
            keep = []
            for l in lots[p]:
                if l[0] < d:
                    st['discarded'] += l[2]
                else:
                    keep.append(l)
            lots[p] = keep
        for p in range(P):
            if due[p] == d:
                due[p] = None
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
                    got = take(p, min(q, stock(p)))
                    if q - got > 0:
                        back[p].append([q - got, d])
            ei += 1
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
    L1 = [[] for _ in range(s1)]  # lists of [block, dirty], LRU first
    L2 = [[] for _ in range(s2)]
    c = {'h1': 0, 'm1': 0, 'h2': 0, 'm2': 0, 'rd': 0, 'wr': 0}

    def find(level, nsets, a):
        s = level[a % nsets]
        for e in s:
            if e[0] == a:
                return s, e
        return s, None

    def use(s, e):
        s.remove(e)
        s.append(e)

    def put(level, nsets, ways, a, dirty):
        s = level[a % nsets]
        ev = None
        if len(s) >= ways:
            ev = s.pop(0)
        s.append([a, dirty])
        return ev

    def put2(a, dirty):
        ev = put(L2, s2, w2, a, dirty)
        if ev is not None and ev[1]:
            c['wr'] += 1

    for a, w in zip(addrs, writes):
        s, e = find(L1, s1, a)
        if e is not None:
            c['h1'] += 1
            use(s, e)
            if w:
                e[1] = True
            continue
        c['m1'] += 1
        s2s, e2 = find(L2, s2, a)
        if e2 is not None:
            c['h2'] += 1
            use(s2s, e2)
        else:
            c['m2'] += 1
            c['rd'] += 1
            put2(a, False)
        ev = put(L1, s1, w1, a, bool(w))
        if ev is not None and ev[1]:
            b = ev[0]
            s2s, e2 = find(L2, s2, b)
            if e2 is not None:
                use(s2s, e2)
                e2[1] = True
            else:
                put2(b, True)
    dirty = sum(1 for lv in (L1, L2) for s in lv for e in s if e[1])
    blocks = [e[0] for s in L1 for e in s]
    return (c['h1'], c['m1'], c['h2'], c['m2'], c['rd'], c['wr'], dirty, blocks)
```
