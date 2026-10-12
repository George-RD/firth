### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    bx = list(boxes)
    pos = player
    hist = []
    read = pushes = blocked = undos = dead = 0
    deltas = (-width, 1, width, -1)
    for m in moves:
        if all(cells[b] == 2 for b in bx):
            break
        read += 1
        if m == 4:
            if hist:
                old, k, orig = hist.pop()
                pos = old
                if k >= 0:
                    bx[k] = orig
                undos += 1
            continue
        t = pos + deltas[m]
        if cells[t] == 1:
            blocked += 1
            continue
        if t in bx:
            k = bx.index(t)
            u = t + deltas[m]
            if cells[u] == 1 or u in bx:
                blocked += 1
                continue
            hist.append((pos, k, t))
            bx[k] = u
            pos = t
            pushes += 1
            if (cells[u] != 2 and (cells[u - width] == 1 or cells[u + width] == 1)
                    and (cells[u - 1] == 1 or cells[u + 1] == 1)):
                dead += 1
        else:
            hist.append((pos, -1, -1))
            pos = t
    solved = all(cells[b] == 2 for b in bx)
    return (pos, bx, read, len(hist), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    b = list(board)
    coords = []
    index = {}
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        coords.append((r, c))
        index[(r, c)] = i

    def sq(r, c):
        return index.get((r, c), -1)

    def own(p, side):
        return p in ((1, 2) if side == 0 else (3, 4))

    def deltas(king, side):
        if king:
            return ((-1, -1), (-1, 1), (1, -1), (1, 1))
        return ((-1, -1), (-1, 1)) if side == 0 else ((1, -1), (1, 1))

    def captures(side):
        found = []
        far = 0 if side == 0 else 7
        for start in range(32):
            p = b[start]
            if not own(p, side):
                continue
            b[start] = 0

            def dfs(cur, king, path, taken):
                r, c = coords[cur]
                extended = False
                for dr, dc in deltas(king, side):
                    j = sq(r + dr, c + dc)
                    k = sq(r + 2 * dr, c + 2 * dc)
                    if j < 0 or k < 0 or not own(b[j], 1 - side) or b[k] != 0:
                        continue
                    extended = True
                    held = b[j]
                    b[j] = 0
                    if not king and coords[k][0] == far:
                        found.append((start, path + [k], taken + [j], True))
                    else:
                        dfs(k, king, path + [k], taken + [j])
                    b[j] = held
                if not extended and taken:
                    found.append((start, path, taken, False))

            dfs(start, p in (2, 4), [], [])
            b[start] = p
        return found

    def best_capture(side):
        caps = captures(side)
        if not caps:
            return None
        caps.sort(key=lambda x: (-len(x[2]), x[0], x[1]))
        return caps[0]

    def first_step(side):
        for start in range(32):
            p = b[start]
            if not own(p, side):
                continue
            r, c = coords[start]
            targets = []
            for dr, dc in deltas(p in (2, 4), side):
                t = sq(r + dr, c + dc)
                if t >= 0 and b[t] == 0:
                    targets.append(t)
            if targets:
                return start, min(targets)
        return None

    side = 0 if turn == 0 else 1
    played = 0
    white_took = black_took = crowned = 0
    result = 0
    while True:
        cap = best_capture(side)
        st = None if cap is not None else first_step(side)
        if cap is None and st is None:
            result = 2 if side == 0 else 1
            break
        if played == plies:
            result = 0
            break
        if cap is not None:
            start, path, taken, crown = cap
            piece = b[start]
            b[start] = 0
            for j in taken:
                b[j] = 0
            if crown:
                piece = 2 if side == 0 else 4
                crowned += 1
            b[path[-1]] = piece
            if side == 0:
                white_took += len(taken)
            else:
                black_took += len(taken)
        else:
            start, t = st
            piece = b[start]
            b[start] = 0
            if piece in (1, 3) and coords[t][0] == (0 if side == 0 else 7):
                piece = 2 if side == 0 else 4
                crowned += 1
            b[t] = piece
        played += 1
        side = 1 - side
    return (b, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    def parse(tokens):
        n = len(tokens)
        pos = 0

        def alt():
            nonlocal pos
            branches = [seq()]
            while pos < n and tokens[pos] == 30:
                pos += 1
                branches.append(seq())
            return ('alt', branches)

        def seq():
            nonlocal pos
            items = []
            while pos < n and tokens[pos] not in (30, 32):
                t = tokens[pos]
                if t == 31 or 0 <= t <= 26:
                    node = atom()
                    while pos < n and tokens[pos] in (27, 28, 29):
                        op = tokens[pos]
                        pos += 1
                        if op == 27:
                            node = ('star', node)
                        elif op == 28:
                            node = ('plus', node)
                        else:
                            node = ('opt', node)
                    items.append(node)
                else:
                    raise ValueError('operator where an atom should start')
            return ('seq', items)

        def atom():
            nonlocal pos
            t = tokens[pos]
            pos += 1
            if t == 31:
                inner = alt()
                if pos >= n or tokens[pos] != 32:
                    raise ValueError('unclosed (')
                pos += 1
                return inner
            if t == 26:
                return ('any',)
            return ('ch', t)

        root = alt()
        if pos != n:
            raise ValueError('unmatched )')
        return root

    def star(inner, S, s):
        result = set(S)
        frontier = set(S)
        while frontier:
            new = ends(inner, frontier, s) - result
            result |= new
            frontier = new
        return result

    def ends(node, S, s):
        kind = node[0]
        n = len(s)
        if kind == 'ch':
            return {i + 1 for i in S if i < n and s[i] == node[1]}
        if kind == 'any':
            return {i + 1 for i in S if i < n}
        if kind == 'seq':
            cur = set(S)
            for item in node[1]:
                cur = ends(item, cur, s)
            return cur
        if kind == 'alt':
            out = set()
            for br in node[1]:
                out |= ends(br, S, s)
            return out
        if kind == 'opt':
            return set(S) | ends(node[1], S, s)
        if kind == 'plus':
            return star(node[1], ends(node[1], S, s), s)
        return star(node[1], S, s)

    try:
        tree = parse(pattern)
    except (ValueError, IndexError):
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    full = []
    longest = []
    count = 0
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        res = ends(tree, {0}, s)
        ok = L in res
        full.append(ok)
        if ok:
            count += 1
        longest.append(max(res) if res else -1)
    return (full, longest, count, True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    whites = [0] * n
    last = [None] * n
    had_bye = [False] * n
    met = [[False] * n for _ in range(n)]
    opps = [[] for _ in range(n)]
    rematches = 0
    ri = 0
    for _ in range(rounds):
        order = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        if n % 2 == 1:
            bye = None
            for p in reversed(order):
                if not had_bye[p]:
                    bye = p
                    break
            had_bye[bye] = True
            score[bye] += 2
            order = [p for p in order if p != bye]
        pool = list(order)
        games = []
        while pool:
            a = pool.pop(0)
            idx_b = None
            for k, q in enumerate(pool):
                if not met[a][q]:
                    idx_b = k
                    break
            if idx_b is None:
                idx_b = 0
                rematches += 1
            b = pool.pop(idx_b)
            if whites[a] != whites[b]:
                white = a if whites[a] < whites[b] else b
            else:
                a_black = last[a] == 'b'
                b_black = last[b] == 'b'
                if b_black and not a_black:
                    white = b
                else:
                    white = a
            black = b if white == a else a
            games.append((white, black))
        for white, black in games:
            res = results[ri]
            ri += 1
            if res == 0:
                score[white] += 2
            elif res == 1:
                score[white] += 1
                score[black] += 1
            else:
                score[black] += 2
            whites[white] += 1
            last[white] = 'w'
            last[black] = 'b'
            met[white][black] = True
            met[black][white] = True
            opps[white].append(black)
            opps[black].append(white)
    buch = [sum(score[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-score[p], -buch[p], -ratings[p], p))
    return (score, buch, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    back = [[] for _ in range(P)]
    on_way = [False] * P
    due = [-1] * P
    seq = 0
    earned = shipped = discarded = cancelled = supplies = 0

    def stock(p):
        return sum(l[0] for l in lots[p])

    def take(p, q):
        got = 0
        lots[p].sort(key=lambda l: (l[1], l[2]))
        for l in lots[p]:
            if q <= 0:
                break
            t = min(q, l[0])
            l[0] -= t
            q -= t
            got += t
        lots[p] = [l for l in lots[p] if l[0] > 0]
        return got

    def fill(p):
        total = 0
        while back[p] and stock(p) > 0:
            head = back[p][0]
            t = take(p, min(head[0], stock(p)))
            head[0] -= t
            total += t
            if head[0] == 0:
                back[p].pop(0)
        return total

    for d in range(days):
        # first: lots past their expiry are thrown away
        for p in range(P):
            kept = []
            for l in lots[p]:
                if l[1] < d:
                    discarded += l[0]
                else:
                    kept.append(l)
            lots[p] = kept
        # second: supplies due today arrive
        for p in range(P):
            if on_way[p] and due[p] == d:
                on_way[p] = False
                seq += 1
                lots[p].append([rq[p], d + shelf[p], seq])
                u = fill(p)
                shipped += u
                earned += u * price[p]
        # third: events of the day, in order
        for e in range(len(ev_day)):
            if ev_day[e] != d:
                continue
            p = ev_prod[e]
            q = ev_qty[e]
            if ev_kind[e] == 1:
                seq += 1
                lots[p].append([q, ev_expiry[e], seq])
                u = fill(p)
                shipped += u
                earned += u * price[p]
            else:
                if back[p]:
                    back[p].append([q, d])
                else:
                    t = take(p, min(q, stock(p)))
                    shipped += t
                    earned += t * price[p]
                    if q - t > 0:
                        back[p].append([q - t, d])
        # fourth: backorders placed on day d - 7 or earlier are cancelled
        for p in range(P):
            keep = []
            for bo in back[p]:
                if bo[1] <= d - 7:
                    cancelled += bo[0]
                else:
                    keep.append(bo)
            back[p] = keep
        # fifth: reorder where nothing is on the way and stock is low
        for p in range(P):
            if not on_way[p] and stock(p) <= rp[p]:
                on_way[p] = True
                due[p] = d + lead[p]
                supplies += 1

    stock_out = [stock(p) for p in range(P)]
    owed = sum(bo[0] for p in range(P) for bo in back[p])
    return (stock_out, earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    l1h = l1m = l2h = l2m = mr = mw = 0

    def find_block(lst, blk):
        for k, e in enumerate(lst):
            if e[0] == blk:
                return k
        return -1

    for a, wr in zip(addrs, writes):
        wr = bool(wr)
        s = L1[a % s1]
        i = find_block(s, a)
        if i >= 0:
            l1h += 1
            e = s.pop(i)
            if wr:
                e[1] = True
            s.append(e)
            continue
        l1m += 1
        t = L2[a % s2]
        j = find_block(t, a)
        if j >= 0:
            l2h += 1
            e2 = t.pop(j)
            t.append(e2)
        else:
            l2m += 1
            mr += 1
            if len(t) >= w2:
                ev = t.pop(0)
                if ev[1]:
                    mw += 1
            t.append([a, False])
        # place the block into the first level
        if len(s) >= w1:
            ev = s.pop(0)
            if ev[1]:
                wb = L2[ev[0] % s2]
                k = find_block(wb, ev[0])
                if k >= 0:
                    e2 = wb.pop(k)
                    e2[1] = True
                    wb.append(e2)
                else:
                    if len(wb) >= w2:
                        ev2 = wb.pop(0)
                        if ev2[1]:
                            mw += 1
                    wb.append([ev[0], True])
        s.append([a, wr])

    dirty = sum(1 for st in L1 for e in st if e[1]) + sum(1 for st in L2 for e in st if e[1])
    l1_blocks = [e[0] for st in L1 for e in st]
    return (l1h, l1m, l2h, l2m, mr, mw, dirty, l1_blocks)
```

