### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    delta = [-width, 1, width, -1]
    hist = []
    read = pushes = blocked = undos = dead = 0
    for m in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        read += 1
        if m == 4:
            if hist:
                d, k = hist.pop()
                player -= delta[d]
                if k >= 0:
                    boxes[k] -= delta[d]
                undos += 1
            continue
        t = player + delta[m]
        if cells[t] == 1:
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + delta[m]
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue
            boxes[k] = u
            player = t
            pushes += 1
            hist.append((m, k))
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
    coord = [(i // 4, 2 * (i % 4) + (1 if (i // 4) % 2 == 0 else 0)) for i in range(32)]
    idx = {coord[i]: i for i in range(32)}

    def side(p):
        return 0 if p in (1, 2) else 1

    def drs(p):
        if p == 1:
            return (-1,)
        if p == 3:
            return (1,)
        return (-1, 1)

    def captures(b, s):
        results = []
        far = 0 if s == 0 else 7

        def dfs(sq, p, bb, lands, caps, start):
            found = False
            r, c = coord[sq]
            for dr in drs(p):
                for dc in (-1, 1):
                    over = idx.get((r + dr, c + dc))
                    land = idx.get((r + 2 * dr, c + 2 * dc))
                    if over is None or land is None:
                        continue
                    if bb[over] != 0 and side(bb[over]) != s and bb[land] == 0:
                        found = True
                        nb = bb[:]
                        nb[over] = 0
                        nl = lands + [land]
                        nc = caps + [over]
                        if p in (1, 3) and coord[land][0] == far:
                            results.append((-len(nl), start, nl, nc, 2 if s == 0 else 4))
                        else:
                            dfs(land, p, nb, nl, nc, start)
            if not found and lands:
                results.append((-len(lands), start, lands, caps, p))

        for i in range(32):
            p = b[i]
            if p and side(p) == s:
                bb = b[:]
                bb[i] = 0
                dfs(i, p, bb, [], [], i)
        return results

    def steps(b, s):
        res = []
        for i in range(32):
            p = b[i]
            if p and side(p) == s:
                r, c = coord[i]
                for dr in drs(p):
                    for dc in (-1, 1):
                        t = idx.get((r + dr, c + dc))
                        if t is not None and b[t] == 0:
                            res.append((i, t))
        return res

    played = 0
    took = [0, 0]
    crowned = 0
    result = 0
    s = turn
    while True:
        caps = captures(board, s)
        stp = [] if caps else steps(board, s)
        if not caps and not stp:
            result = 2 if s == 0 else 1
            break
        if played >= plies:
            result = 0
            break
        if caps:
            best = min(caps, key=lambda x: (x[0], x[1], x[2]))
            _, start, lands, cp, final = best
            was_man = board[start] in (1, 3)
            board[start] = 0
            for q in cp:
                board[q] = 0
            board[lands[-1]] = final
            took[s] += len(cp)
            if was_man and final in (2, 4):
                crowned += 1
        else:
            i, t = min(stp)
            p = board[i]
            board[i] = 0
            if p == 1 and coord[t][0] == 0:
                p = 2
                crowned += 1
            elif p == 3 and coord[t][0] == 7:
                p = 4
                crowned += 1
            board[t] = p
        played += 1
        s = 1 - s
    return (board, played, took[0], took[1], crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    n = len(pattern)
    pos = [0]

    class Bad(Exception):
        pass

    def peek():
        return pattern[pos[0]] if pos[0] < n else None

    def parse_alt():
        seqs = [parse_seq()]
        while peek() == 30:
            pos[0] += 1
            seqs.append(parse_seq())
        return ('alt', seqs)

    def parse_seq():
        items = []
        while True:
            t = peek()
            if t is not None and (t <= 26 or t == 31):
                items.append(parse_item())
            else:
                break
        return ('seq', items)

    def parse_item():
        t = peek()
        pos[0] += 1
        if t <= 25:
            node = ('lit', t)
        elif t == 26:
            node = ('dot',)
        else:
            node = parse_alt()
            if peek() != 32:
                raise Bad()
            pos[0] += 1
        while peek() in (27, 28, 29):
            op = peek()
            pos[0] += 1
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[op], node)
        return node

    try:
        tree = parse_alt()
        if pos[0] != n:
            raise Bad()
        valid = True
    except Bad:
        valid = False

    k = len(lens)
    if not valid:
        return ([False] * k, [-1] * k, 0, False)

    def ev(node, ps, s):
        kind = node[0]
        if kind == 'lit':
            return frozenset(i + 1 for i in ps if i < len(s) and s[i] == node[1])
        if kind == 'dot':
            return frozenset(i + 1 for i in ps if i < len(s))
        if kind == 'seq':
            cur = ps
            for it in node[1]:
                cur = ev(it, cur, s)
            return cur
        if kind == 'alt':
            out = frozenset()
            for sq in node[1]:
                out = out | ev(sq, ps, s)
            return out
        if kind == 'opt':
            return ps | ev(node[1], ps, s)
        if kind == 'star':
            return closure(node[1], ps, s)
        if kind == 'plus':
            return closure(node[1], ev(node[1], ps, s), s)

    def closure(child, ps, s):
        result = set(ps)
        frontier = frozenset(ps)
        while frontier:
            new = ev(child, frontier, s) - result
            result |= new
            frontier = frozenset(new)
        return frozenset(result)

    full = []
    longest = []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        ends = ev(tree, frozenset([0]), s)
        full.append(L in ends)
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
        bye = None
        if n % 2 == 1:
            for p in reversed(order):
                if not had_bye[p]:
                    bye = p
                    break
            had_bye[bye] = True
            score[bye] += 2
            order = [p for p in order if p != bye]
        unpaired = list(order)
        pairs = []
        while unpaired:
            p = unpaired.pop(0)
            q = None
            for x in unpaired:
                if x not in played[p]:
                    q = x
                    break
            if q is None:
                q = unpaired[0]
                rematches += 1
            unpaired.remove(q)
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
    back = [[] for _ in range(P)]  # [qty, day]
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
        seq[0] += 1
        lots[p].append([expiry, seq[0], qty])
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
                    got = take(p, q)
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
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    c = {'h1': 0, 'm1': 0, 'h2': 0, 'm2': 0, 'rd': 0, 'wr': 0}

    def find(st, b):
        for i, e in enumerate(st):
            if e[0] == b:
                return i
        return -1

    def put2(b, dirty):
        st = L2[b % s2]
        if len(st) >= w2:
            ev = st.pop(0)
            if ev[1]:
                c['wr'] += 1
        st.append([b, dirty])

    for a, w in zip(addrs, writes):
        w = bool(w)
        st1 = L1[a % s1]
        i = find(st1, a)
        if i >= 0:
            c['h1'] += 1
            e = st1.pop(i)
            if w:
                e[1] = True
            st1.append(e)
            continue
        c['m1'] += 1
        st2 = L2[a % s2]
        j = find(st2, a)
        if j >= 0:
            c['h2'] += 1
            st2.append(st2.pop(j))
        else:
            c['m2'] += 1
            c['rd'] += 1
            put2(a, False)
        evicted = None
        if len(st1) >= w1:
            evicted = st1.pop(0)
        st1.append([a, w])
        if evicted is not None and evicted[1]:
            b = evicted[0]
            s = L2[b % s2]
            k = find(s, b)
            if k >= 0:
                e = s.pop(k)
                e[1] = True
                s.append(e)
            else:
                put2(b, True)
    dirty = sum(1 for st in L1 for e in st if e[1]) + sum(1 for st in L2 for e in st if e[1])
    blocks = [e[0] for st in L1 for e in st]
    return (c['h1'], c['m1'], c['h2'], c['m2'], c['rd'], c['wr'], dirty, blocks)
```
