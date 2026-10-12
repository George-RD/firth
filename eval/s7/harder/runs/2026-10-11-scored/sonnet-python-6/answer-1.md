### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    deltas = [-width, 1, width, -1]
    history = []
    read = pushes = blocked = undos = dead = 0

    def all_on_goal():
        return all(cells[b] == 2 for b in boxes)

    for m in moves:
        if all_on_goal():
            break
        read += 1
        if m == 4:
            if history:
                d, k = history.pop()
                if k >= 0:
                    # box is at player + d; worker was at player - d
                    boxes[k] = player + d
                player -= d
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
            player = t
            pushes += 1
            history.append((d, k))
            if cells[u] != 2:
                vert = cells[u - width] == 1 or cells[u + width] == 1
                horiz = cells[u - 1] == 1 or cells[u + 1] == 1
                if vert and horiz:
                    dead += 1
        else:
            player = t
            history.append((d, -1))
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, all_on_goal())
```

### task: checkers
```python
def main(board, turn, plies):
    board = list(board)

    def nb(i, dr, dc):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        nr, nc = r + dr, c + dc
        if 0 <= nr < 8 and 0 <= nc < 8:
            return nr * 4 + nc // 2
        return None

    def side_of(p):
        if p in (1, 2):
            return 0
        if p in (3, 4):
            return 1
        return -1

    def dirs(p):
        if p == 1:
            return [(-1, -1), (-1, 1)]
        if p == 3:
            return [(1, -1), (1, 1)]
        return [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def far_row(side):
        return 0 if side == 0 else 7

    def captures_for(start, side):
        piece = board[start]
        results = []
        board[start] = 0

        def dfs(pos, p, path, caps):
            found = False
            for dr, dc in dirs(p):
                o = nb(pos, dr, dc)
                if o is None:
                    continue
                l = nb(pos, 2 * dr, 2 * dc)
                if l is None:
                    continue
                if side_of(board[o]) == 1 - side and board[l] == 0:
                    found = True
                    saved = board[o]
                    board[o] = 0
                    np_ = p
                    crowned = False
                    if p in (1, 3) and l // 4 == far_row(side):
                        np_ = p + 1
                        crowned = True
                    if crowned:
                        results.append((caps + 1, start, tuple(path + [l]), l, crowned))
                    else:
                        dfs(l, np_, path + [l], caps + 1)
                    board[o] = saved
            if not found and path:
                results.append((caps, start, tuple(path), pos, False))

        dfs(start, piece, [], 0)
        board[start] = piece
        return results

    def all_captures(side):
        res = []
        for i in range(32):
            if side_of(board[i]) == side:
                res.extend(captures_for(i, side))
        return res

    def all_steps(side):
        res = []
        for i in range(32):
            if side_of(board[i]) == side:
                for dr, dc in dirs(board[i]):
                    t = nb(i, dr, dc)
                    if t is not None and board[t] == 0:
                        res.append((i, t))
        return res

    played = 0
    took = [0, 0]
    crowned_n = 0
    result = 0
    side = turn
    while True:
        caps = all_captures(side)
        steps = [] if caps else all_steps(side)
        if not caps and not steps:
            result = 2 if side == 0 else 1
            break
        if played == plies:
            result = 0
            break
        if caps:
            best = min(caps, key=lambda x: (-x[0], x[1], x[2]))
            n, start, path, final, crowned = best
            piece = board[start]
            # remove captured pieces: replay the jumps
            pos = start
            board[start] = 0
            for l in path:
                # find the jumped square between pos and l
                r1, c1 = pos // 4, 2 * (pos % 4) + (1 if (pos // 4) % 2 == 0 else 0)
                r2, c2 = l // 4, 2 * (l % 4) + (1 if (l // 4) % 2 == 0 else 0)
                mid = nb(pos, (r2 - r1) // 2, (c2 - c1) // 2)
                board[mid] = 0
                pos = l
            if crowned:
                piece += 1
                crowned_n += 1
            board[final] = piece
            took[side] += n
        else:
            s, t = min(steps)
            piece = board[s]
            board[s] = 0
            if piece in (1, 3) and t // 4 == far_row(side):
                piece += 1
                crowned_n += 1
            board[t] = piece
        played += 1
        side = 1 - side
    return (board, played, took[0], took[1], crowned_n, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    n = len(pattern)
    pos = [0]
    valid = [True]

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
            if pos[0] < n and pattern[pos[0]] == 32:
                pos[0] += 1
            else:
                raise ValueError
        else:
            raise ValueError
        while pos[0] < n and pattern[pos[0]] in (27, 28, 29):
            op = pattern[pos[0]]
            pos[0] += 1
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[op], node)
        return node

    try:
        tree = parse_alt()
        if pos[0] != n:
            raise ValueError
    except ValueError:
        k = len(lens)
        return ([False] * k, [-1] * k, 0, False)

    def match(node, s, starts):
        kind = node[0]
        if kind == 'lit':
            return {i + 1 for i in starts if i < len(s) and s[i] == node[1]}
        if kind == 'any':
            return {i + 1 for i in starts if i < len(s)}
        if kind == 'seq':
            cur = set(starts)
            for it in node[1]:
                cur = match(it, s, cur)
                if not cur:
                    break
            return cur
        if kind == 'alt':
            out = set()
            for sq in node[1]:
                out |= match(sq, s, starts)
            return out
        if kind == 'opt':
            return set(starts) | match(node[1], s, starts)
        if kind == 'star':
            seen = set(starts)
            frontier = set(starts)
            while frontier:
                nxt = match(node[1], s, frontier) - seen
                seen |= nxt
                frontier = nxt
            return seen
        if kind == 'plus':
            first = match(node[1], s, starts)
            seen = set(first)
            frontier = set(first)
            while frontier:
                nxt = match(node[1], s, frontier) - seen
                seen |= nxt
                frontier = nxt
            return seen
        return set()

    full = []
    longest = []
    off = 0
    for ln in lens:
        s = chars[off:off + ln]
        off += ln
        ends = match(tree, s, {0})
        full.append(ln in ends)
        longest.append(max(ends) if ends else -1)
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
    last = [None] * n
    had_bye = [False] * n
    rematches = 0
    ri = 0
    for _ in range(rounds):
        order = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        active = list(order)
        bye = None
        if n % 2 == 1:
            for p in reversed(order):
                if not had_bye[p]:
                    bye = p
                    break
            if bye is not None:
                had_bye[bye] = True
                active.remove(bye)
        paired = set()
        pairs = []
        for p in active:
            if p in paired:
                continue
            paired.add(p)
            q = None
            for c in active:
                if c not in paired and c not in played[p]:
                    q = c
                    break
            if q is None:
                for c in active:
                    if c not in paired:
                        q = c
                        break
                if q is None:
                    continue
                rematches += 1
            paired.add(q)
            # colours
            if whites[p] < whites[q]:
                w, b = p, q
            elif whites[q] < whites[p]:
                w, b = q, p
            else:
                pl = last[p] == 'b'
                ql = last[q] == 'b'
                if pl and not ql:
                    w, b = p, q
                elif ql and not pl:
                    w, b = q, p
                else:
                    w, b = p, q
            pairs.append((w, b))
        if bye is not None:
            score[bye] += 2
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
    lots = [[] for _ in range(P)]  # each [expiry, seq, qty]
    back = [[] for _ in range(P)]  # each [owed, placed]
    due = [None] * P
    seq = [0]
    earned = shipped = discarded = cancelled = supplies = 0

    def stock(p):
        return sum(l[2] for l in lots[p])

    def take(p, q):
        nonlocal earned, shipped
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
        shipped += got
        earned += got * price[p]
        return got

    def arrive(p, qty, expiry):
        seq[0] += 1
        lots[p].append([expiry, seq[0], qty])
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
                if l[0] < d:
                    discarded += l[2]
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
                    got = take(p, q)
                    if q - got > 0:
                        back[p].append([q - got, d])
            e += 1
        for p in range(P):
            keep = []
            for b in back[p]:
                if b[1] <= d - 7:
                    cancelled += b[0]
                else:
                    keep.append(b)
            back[p] = keep
        for p in range(P):
            if due[p] is None and stock(p) <= rp[p]:
                due[p] = d + lead[p]
                supplies += 1
    owed = sum(b[0] for p in range(P) for b in back[p])
    return ([stock(p) for p in range(P)], earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]  # each entry [block, dirty], LRU first
    L2 = [[] for _ in range(s2)]
    l1h = l1m = l2h = l2m = reads = mwrites = 0

    def find(st, a):
        for i, e in enumerate(st):
            if e[0] == a:
                return i
        return -1

    def put(st, w, a, dirty):
        evicted = None
        if len(st) >= w:
            evicted = st.pop(0)
        st.append([a, dirty])
        return evicted

    for a, wr in zip(addrs, writes):
        st1 = L1[a % s1]
        i = find(st1, a)
        if i >= 0:
            l1h += 1
            e = st1.pop(i)
            if wr:
                e[1] = True
            st1.append(e)
            continue
        l1m += 1
        st2 = L2[a % s2]
        j = find(st2, a)
        if j >= 0:
            l2h += 1
            st2.append(st2.pop(j))
        else:
            l2m += 1
            reads += 1
            ev = put(st2, w2, a, False)
            if ev is not None and ev[1]:
                mwrites += 1
        ev = put(st1, w1, a, bool(wr))
        if ev is not None and ev[1]:
            b = ev[0]
            st2b = L2[b % s2]
            k = find(st2b, b)
            if k >= 0:
                e = st2b.pop(k)
                e[1] = True
                st2b.append(e)
            else:
                ev2 = put(st2b, w2, b, True)
                if ev2 is not None and ev2[1]:
                    mwrites += 1
    dirty = sum(1 for st in L1 for e in st if e[1]) + sum(1 for st in L2 for e in st if e[1])
    blocks = [e[0] for st in L1 for e in st]
    return (l1h, l1m, l2h, l2m, reads, mwrites, dirty, blocks)
```
