### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    dirs = [-width, 1, width, -1]

    def is_wall(c):
        return cells[c] == 1

    def is_dead(c):
        if cells[c] == 2:
            return False
        return (is_wall(c - width) or is_wall(c + width)) and (is_wall(c - 1) or is_wall(c + 1))

    read = 0
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    history = []
    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if history:
                prev, k, bprev = history.pop()
                undos += 1
                player = prev
                if k >= 0:
                    boxes[k] = bprev
            continue
        d = dirs[m]
        t = player + d
        if is_wall(t):
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + d
            if is_wall(u) or u in boxes:
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
    rc = []
    idx = {}
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        rc.append((r, c))
        idx[(r, c)] = i

    def nb(i, dr, dc):
        return idx.get((rc[i][0] + dr, rc[i][1] + dc), -1)

    def side_of(p):
        if p in (1, 2):
            return 1
        if p in (3, 4):
            return 2
        return 0

    def dirs_for(p):
        if p in (2, 4):
            return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        if p == 1:
            return [(-1, -1), (-1, 1)]
        return [(1, -1), (1, 1)]

    def captures(b, start):
        p = b[start]
        opp = 3 - side_of(p)
        man = p in (1, 3)
        far = 0 if p == 1 else 7
        out = []
        landings = []
        caps = []

        def dfs(cur):
            any_jump = False
            for dr, dc in dirs_for(p):
                m = nb(cur, dr, dc)
                if m < 0 or side_of(b[m]) != opp:
                    continue
                l = nb(m, dr, dc)
                if l < 0 or b[l] != 0:
                    continue
                any_jump = True
                v = b[m]
                b[m] = 0
                landings.append(l)
                caps.append(m)
                if man and rc[l][0] == far:
                    out.append((tuple(landings), tuple(caps)))
                elif not dfs(l):
                    out.append((tuple(landings), tuple(caps)))
                landings.pop()
                caps.pop()
                b[m] = v
            return any_jump

        b[start] = 0
        dfs(start)
        b[start] = p
        return out

    b = list(board)
    side = 1 if turn == 0 else 2
    played = 0
    took = {1: 0, 2: 0}
    crowned = 0
    result = 0
    while True:
        allcaps = []
        for s in range(32):
            if side_of(b[s]) == side:
                for landings, caps in captures(b, s):
                    allcaps.append((s, landings, caps))
        steps = []
        if not allcaps:
            for s in range(32):
                if side_of(b[s]) == side:
                    for dr, dc in dirs_for(b[s]):
                        t = nb(s, dr, dc)
                        if t >= 0 and b[t] == 0:
                            steps.append((s, t))
            if not steps:
                result = 2 if side == 1 else 1
                break
        if played == plies:
            result = 0
            break
        if allcaps:
            s, landings, caps = min(allcaps, key=lambda t: (-len(t[2]), t[0], t[1]))
            p = b[s]
            b[s] = 0
            for c in caps:
                b[c] = 0
            end = landings[-1]
            if p in (1, 3) and rc[end][0] == (0 if p == 1 else 7):
                p = p + 1
                crowned += 1
            b[end] = p
            took[side] += len(caps)
        else:
            s, t = min(steps)
            p = b[s]
            b[s] = 0
            if p in (1, 3) and rc[t][0] == (0 if p == 1 else 7):
                p = p + 1
                crowned += 1
            b[t] = p
        played += 1
        side = 3 - side
    return (b, played, took[1], took[2], crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    toks = pattern
    n = len(toks)
    pos = [0]

    class Bad(Exception):
        pass

    def parse_alt():
        seqs = [parse_seq()]
        while pos[0] < n and toks[pos[0]] == 30:
            pos[0] += 1
            seqs.append(parse_seq())
        return ('alt', seqs)

    def parse_seq():
        items = []
        while pos[0] < n and toks[pos[0]] not in (30, 32):
            items.append(parse_item())
        return ('seq', items)

    def parse_item():
        t = toks[pos[0]]
        if t <= 26:
            pos[0] += 1
            node = ('lit', -1 if t == 26 else t)
        elif t == 31:
            pos[0] += 1
            node = parse_alt()
            if pos[0] >= n or toks[pos[0]] != 32:
                raise Bad()
            pos[0] += 1
        else:
            raise Bad()
        while pos[0] < n and toks[pos[0]] in (27, 28, 29):
            op = toks[pos[0]]
            pos[0] += 1
            if op == 27:
                node = ('star', node)
            elif op == 28:
                node = ('plus', node)
            else:
                node = ('opt', node)
        return node

    def ends(node, s, i):
        t = node[0]
        if t == 'lit':
            if i < len(s) and (node[1] == -1 or s[i] == node[1]):
                return {i + 1}
            return set()
        if t == 'seq':
            cur = {i}
            for it in node[1]:
                nxt = set()
                for j in cur:
                    nxt |= ends(it, s, j)
                cur = nxt
                if not cur:
                    break
            return cur
        if t == 'alt':
            r = set()
            for sq in node[1]:
                r |= ends(sq, s, i)
            return r
        if t == 'opt':
            return {i} | ends(node[1], s, i)
        inner = node[1]
        if t == 'star':
            reach = {i}
            frontier = [i]
        else:
            reach = set(ends(inner, s, i))
            frontier = list(reach)
        while frontier:
            j = frontier.pop()
            for e in ends(inner, s, j):
                if e not in reach:
                    reach.add(e)
                    frontier.append(e)
        return reach

    try:
        root = parse_alt()
        if pos[0] != n:
            raise Bad()
    except Bad:
        k = len(lens)
        return ([False] * k, [-1] * k, 0, False)

    full = []
    longest = []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        E = ends(root, s, 0)
        full.append(L in E)
        longest.append(max(E) if E else -1)
    count = sum(1 for f in full if f)
    return (full, longest, count, True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    played = [set() for _ in range(n)]
    last = [None] * n
    whites = [0] * n
    had_bye = [False] * n
    games = []
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
        while order:
            a = order[0]
            b = None
            for q in order[1:]:
                if q not in played[a]:
                    b = q
                    break
            if b is None:
                b = order[1]
            if b in played[a]:
                rematches += 1
            order = [p for p in order if p != a and p != b]
            if whites[a] < whites[b]:
                w, k = a, b
            elif whites[b] < whites[a]:
                w, k = b, a
            else:
                a_black = last[a] == 'B'
                b_black = last[b] == 'B'
                if b_black and not a_black:
                    w, k = b, a
                else:
                    w, k = a, b
            res = results[ri]
            ri += 1
            if res == 0:
                score[w] += 2
            elif res == 1:
                score[w] += 1
                score[k] += 1
            else:
                score[k] += 2
            whites[w] += 1
            last[w] = 'W'
            last[k] = 'B'
            played[a].add(b)
            played[b].add(a)
            games.append((w, k))
    bh = [0] * n
    for w, k in games:
        bh[w] += score[k]
        bh[k] += score[w]
    ranking = sorted(range(n), key=lambda p: (-score[p], -bh[p], -ratings[p], p))
    return (score, bh, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    back = [[] for _ in range(P)]
    onway = [None] * P
    T = [0, 0, 0, 0, 0]
    arrivals = [0]

    def stock_of(p):
        return sum(l[0] for l in lots[p])

    def take(p, q):
        taken = 0
        for l in sorted(lots[p], key=lambda x: (x[1], x[2])):
            if q == 0:
                break
            x = min(l[0], q)
            l[0] -= x
            q -= x
            taken += x
        lots[p] = [l for l in lots[p] if l[0] > 0]
        return taken

    def ship(p, q):
        t = take(p, q)
        T[1] += t
        T[0] += t * price[p]
        return t

    def fill(p):
        while back[p] and stock_of(p) > 0:
            front = back[p][0]
            t = ship(p, min(front[0], stock_of(p)))
            front[0] -= t
            if front[0] == 0:
                back[p].pop(0)

    def add_lot(p, q, expiry):
        lots[p].append([q, expiry, arrivals[0]])
        arrivals[0] += 1
        fill(p)

    for d in range(days):
        for p in range(P):
            kept = []
            for l in lots[p]:
                if l[1] < d:
                    T[2] += l[0]
                else:
                    kept.append(l)
            lots[p] = kept
        for p in range(P):
            if onway[p] == d:
                onway[p] = None
                add_lot(p, rq[p], d + shelf[p])
        for e in range(len(ev_day)):
            if ev_day[e] != d:
                continue
            p = ev_prod[e]
            q = ev_qty[e]
            if ev_kind[e] == 1:
                add_lot(p, q, ev_expiry[e])
            else:
                if back[p]:
                    back[p].append([q, d])
                else:
                    t = ship(p, min(q, stock_of(p)))
                    if q - t > 0:
                        back[p].append([q - t, d])
        for p in range(P):
            kept = []
            for bo in back[p]:
                if bo[1] <= d - 7:
                    T[3] += bo[0]
                else:
                    kept.append(bo)
            back[p] = kept
        for p in range(P):
            if onway[p] is None and stock_of(p) <= rp[p]:
                onway[p] = d + lead[p]
                T[4] += 1
    stock = [stock_of(p) for p in range(P)]
    owed = sum(bo[0] for p in range(P) for bo in back[p])
    return (stock, T[0], T[1], T[2], T[3], T[4], owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    h1 = m1 = h2 = m2 = mr = mw = 0

    def find(S, b):
        for e in S:
            if e[0] == b:
                return e
        return None

    def touch(S, e):
        S.remove(e)
        S.append(e)

    def put(S, ways, b, dirty):
        ev = None
        if len(S) >= ways:
            ev = S.pop(0)
        S.append([b, dirty])
        return ev

    for a, wr in zip(addrs, writes):
        S1 = L1[a % s1]
        e = find(S1, a)
        if e is not None:
            h1 += 1
            touch(S1, e)
            if wr:
                e[1] = True
            continue
        m1 += 1
        S2 = L2[a % s2]
        e2 = find(S2, a)
        if e2 is not None:
            h2 += 1
            touch(S2, e2)
        else:
            m2 += 1
            mr += 1
            ev = put(S2, w2, a, False)
            if ev is not None and ev[1]:
                mw += 1
        ev1 = put(S1, w1, a, wr)
        if ev1 is not None and ev1[1]:
            b = ev1[0]
            Sb = L2[b % s2]
            e3 = find(Sb, b)
            if e3 is not None:
                touch(Sb, e3)
                e3[1] = True
            else:
                ev2 = put(Sb, w2, b, True)
                if ev2 is not None and ev2[1]:
                    mw += 1
    dirty = 0
    for S in L1 + L2:
        for e in S:
            if e[1]:
                dirty += 1
    l1_blocks = []
    for S in L1:
        for e in S:
            l1_blocks.append(e[0])
    return (h1, m1, h2, m2, mr, mw, dirty, l1_blocks)
```
