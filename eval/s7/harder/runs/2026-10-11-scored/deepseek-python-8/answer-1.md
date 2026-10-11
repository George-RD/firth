### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    walls = [c == 1 for c in cells]
    goals = [c == 2 for c in cells]
    boxes = list(boxes)
    history = []
    read = 0
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    dirs = [-width, 1, width, -1]

    def solved():
        return all(goals[b] for b in boxes)

    for mv in moves:
        if solved():
            break
        read += 1
        if mv == 4:
            if history:
                d, is_push, bi = history.pop()
                player -= d
                if is_push:
                    boxes[bi] -= d
                undos += 1
            continue
        d = dirs[mv]
        t = player + d
        if walls[t]:
            blocked += 1
            continue
        bi = -1
        for i, b in enumerate(boxes):
            if b == t:
                bi = i
                break
        if bi != -1:
            u = t + d
            if walls[u]:
                blocked += 1
                continue
            box_at_u = False
            for b in boxes:
                if b == u:
                    box_at_u = True
                    break
            if box_at_u:
                blocked += 1
                continue
            boxes[bi] = u
            player = t
            pushes += 1
            history.append((d, True, bi))
            if not goals[u]:
                above = u - width
                below = u + width
                left = u - 1
                right = u + 1
                if (walls[above] or walls[below]) and (walls[left] or walls[right]):
                    dead += 1
        else:
            player = t
            history.append((d, False, -1))

    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved())
```

### task: checkers
```python
def main(board, turn, plies):
    D = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def sq_to_rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def rc_to_sq(r, c):
        if r < 0 or r > 7 or c < 0 or c > 7:
            return -1
        return r * 4 + (c - (1 if r % 2 == 0 else 0)) // 2

    neigh = [[-1] * 4 for _ in range(32)]
    for i in range(32):
        r, c = sq_to_rc(i)
        for d, (dr, dc) in enumerate(D):
            nr, nc = r + dr, c + dc
            neigh[i][d] = rc_to_sq(nr, nc)

    def allowed_dirs(piece):
        if piece == 1:
            return (0, 1)
        if piece == 3:
            return (2, 3)
        return (0, 1, 2, 3)

    def is_opponent(piece, side):
        if side == 0:
            return piece in (3, 4)
        return piece in (1, 2)

    def gen_captures(bd, side):
        results = []
        for start in range(32):
            piece = bd[start]
            if piece == 0:
                continue
            if side == 0 and piece not in (1, 2):
                continue
            if side == 1 and piece not in (3, 4):
                continue

            def dfs(cur, cur_piece, b, captured, landings):
                can_continue = False
                for d in allowed_dirs(cur_piece):
                    mid = neigh[cur][d]
                    if mid == -1:
                        continue
                    land = neigh[mid][d]
                    if land == -1:
                        continue
                    if b[mid] == 0:
                        continue
                    if not is_opponent(b[mid], side):
                        continue
                    if b[land] != 0:
                        continue
                    can_continue = True
                    nb = b[:]
                    nb[cur] = 0
                    nb[mid] = 0
                    new_piece = cur_piece
                    crowned_now = False
                    if cur_piece == 1 and land // 4 == 0:
                        new_piece = 2
                        crowned_now = True
                    elif cur_piece == 3 and land // 4 == 7:
                        new_piece = 4
                        crowned_now = True
                    nb[land] = new_piece
                    new_landings = landings + [land]
                    if crowned_now:
                        results.append((captured + 1, start, tuple(new_landings), nb, True))
                    else:
                        dfs(land, new_piece, nb, captured + 1, new_landings)

                if not can_continue and captured > 0:
                    results.append((captured, start, tuple(landings), b, False))

            dfs(start, piece, bd, 0, [])
        return results

    def gen_steps(bd, side):
        res = []
        for start in range(32):
            piece = bd[start]
            if piece == 0:
                continue
            if side == 0 and piece not in (1, 2):
                continue
            if side == 1 and piece not in (3, 4):
                continue
            for d in allowed_dirs(piece):
                to = neigh[start][d]
                if to == -1:
                    continue
                if bd[to] != 0:
                    continue
                nb = bd[:]
                new_piece = piece
                crowned = False
                if piece == 1 and to // 4 == 0:
                    new_piece = 2
                    crowned = True
                elif piece == 3 and to // 4 == 7:
                    new_piece = 4
                    crowned = True
                nb[start] = 0
                nb[to] = new_piece
                res.append((start, to, nb, crowned))
        return res

    bd = list(board)
    cur_turn = turn
    played = 0
    white_took = 0
    black_took = 0
    crowned = 0
    result = 0

    while True:
        caps = gen_captures(bd, cur_turn)
        if caps:
            if played == plies:
                result = 0
                break
            max_cap = max(c[0] for c in caps)
            caps = [c for c in caps if c[0] == max_cap]
            caps.sort(key=lambda x: (x[1], x[2]))
            chosen = caps[0]
            captured = chosen[0]
            bd = chosen[3]
            if cur_turn == 0:
                white_took += captured
            else:
                black_took += captured
            if chosen[4]:
                crowned += 1
            played += 1
            cur_turn = 1 - cur_turn
        else:
            steps = gen_steps(bd, cur_turn)
            if not steps:
                result = 1 if cur_turn == 1 else 2
                break
            if played == plies:
                result = 0
                break
            steps.sort(key=lambda x: (x[0], x[1]))
            start, to, nb, crown = steps[0]
            bd = nb
            if crown:
                crowned += 1
            played += 1
            cur_turn = 1 - cur_turn

    return (bd, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    def parse_alt(tokens, pos):
        seqs = []
        seq, pos = parse_seq(tokens, pos)
        seqs.append(seq)
        while pos < len(tokens) and tokens[pos] == 30:
            pos += 1
            seq, pos = parse_seq(tokens, pos)
            seqs.append(seq)
        return ('alt', tuple(seqs)), pos

    def parse_seq(tokens, pos):
        items = []
        while pos < len(tokens) and tokens[pos] not in (30, 32):
            if tokens[pos] in (27, 28, 29):
                raise ValueError
            atom, pos = parse_atom(tokens, pos)
            node = atom
            while pos < len(tokens) and tokens[pos] in (27, 28, 29):
                op = tokens[pos]
                pos += 1
                if op == 27:
                    node = ('repeat', node, 0, None)
                elif op == 28:
                    node = ('repeat', node, 1, None)
                else:
                    node = ('repeat', node, 0, 1)
            items.append(node)
        return ('seq', tuple(items)), pos

    def parse_atom(tokens, pos):
        if pos >= len(tokens):
            raise ValueError
        t = tokens[pos]
        if t <= 25:
            return ('char', t), pos + 1
        if t == 26:
            return ('char', 26), pos + 1
        if t == 31:
            pos += 1
            alt, pos = parse_alt(tokens, pos)
            if pos >= len(tokens) or tokens[pos] != 32:
                raise ValueError
            return alt, pos + 1
        raise ValueError

    valid = True
    try:
        ast, pos = parse_alt(pattern, 0)
        if pos != len(pattern):
            valid = False
    except Exception:
        valid = False

    def match_string(s):
        memo = {}

        def closure(child, start):
            seen = {start}
            stack = [start]
            while stack:
                p = stack.pop()
                for q in match(child, p):
                    if q not in seen:
                        seen.add(q)
                        stack.append(q)
            return seen

        def match(node, pos):
            key = (node, pos)
            if key in memo:
                return memo[key]
            typ = node[0]
            if typ == 'char':
                if pos < len(s) and (node[1] == 26 or node[1] == s[pos]):
                    res = {pos + 1}
                else:
                    res = set()
            elif typ == 'seq':
                positions = {pos}
                for item in node[1]:
                    new = set()
                    for p in positions:
                        new |= match(item, p)
                    positions = new
                    if not positions:
                        break
                res = positions
            elif typ == 'alt':
                res = set()
                for seq in node[1]:
                    res |= match(seq, pos)
            else:
                child, mn, mx = node[1], node[2], node[3]
                if mx is None:
                    exact = {pos}
                    for k in range(1, mn + 1):
                        new = set()
                        for p in exact:
                            new |= match(child, p)
                        exact = new
                        if not exact:
                            break
                    if mn == 0:
                        start_set = {pos}
                    else:
                        start_set = exact
                    res = set()
                    for p in start_set:
                        res |= closure(child, p)
                else:
                    exact = {pos}
                    res = set()
                    if mn == 0:
                        res.add(pos)
                    for k in range(1, mx + 1):
                        new = set()
                        for p in exact:
                            new |= match(child, p)
                        exact = new
                        if k >= mn:
                            res |= exact
                        if not exact:
                            break
            memo[key] = frozenset(res)
            return memo[key]

        return match(ast, 0)

    full = []
    longest = []
    count = 0
    if not valid:
        full = [False] * len(lens)
        longest = [-1] * len(lens)
        count = 0
    else:
        idx = 0
        for L in lens:
            s = chars[idx:idx + L]
            idx += L
            ends = match_string(s)
            f = L in ends
            full.append(f)
            if f:
                count += 1
            if ends:
                longest.append(max(ends))
            else:
                longest.append(-1)

    return (full, longest, count, valid)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    scores = [0] * n
    whites = [0] * n
    last_color = [None] * n
    opponents = [[] for _ in range(n)]
    byes = [False] * n
    played_pairs = set()
    rematches = 0
    res_idx = 0

    for _ in range(rounds):
        order = list(range(n))
        order.sort(key=lambda p: (-scores[p], -ratings[p], p))

        bye = None
        if n % 2 == 1:
            for p in reversed(order):
                if not byes[p]:
                    bye = p
                    break
            byes[bye] = True
            scores[bye] += 2

        unpaired = [p for p in order if p != bye]
        while unpaired:
            A = unpaired.pop(0)
            B = None
            for cand in unpaired:
                key = (min(A, cand), max(A, cand))
                if key not in played_pairs:
                    B = cand
                    break
            if B is None:
                B = unpaired[0]
            unpaired.remove(B)

            key = (min(A, B), max(A, B))
            if key in played_pairs:
                rematches += 1
            played_pairs.add(key)

            if whites[A] < whites[B]:
                white, black = A, B
            elif whites[A] > whites[B]:
                white, black = B, A
            else:
                a_black = (last_color[A] == 'B')
                b_black = (last_color[B] == 'B')
                if a_black != b_black:
                    if a_black:
                        white, black = A, B
                    else:
                        white, black = B, A
                else:
                    white, black = A, B

            res = results[res_idx]
            res_idx += 1
            if res == 0:
                scores[white] += 2
            elif res == 1:
                scores[white] += 1
                scores[black] += 1
            else:
                scores[black] += 2

            whites[white] += 1
            last_color[white] = 'W'
            last_color[black] = 'B'
            opponents[A].append(B)
            opponents[B].append(A)

    buchholz = [0] * n
    for p in range(n):
        buchholz[p] = sum(scores[o] for o in opponents[p])

    ranking = list(range(n))
    ranking.sort(key=lambda p: (-scores[p], -buchholz[p], -ratings[p], p))
    return (scores, buchholz, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    backorders = [[] for _ in range(P)]
    pending = [[] for _ in range(P)]
    arrival_counter = 0
    shipped = 0
    earned = 0
    discarded = 0
    cancelled = 0
    supplies = 0

    def stock_total(p):
        return sum(lot[0] for lot in lots[p])

    def take_stock(p, q):
        nonlocal shipped, earned
        if q <= 0:
            return 0
        lots[p].sort(key=lambda x: (x[1], x[2]))
        taken = 0
        new_lots = []
        for lot in lots[p]:
            if q == 0:
                new_lots.append(lot)
                continue
            if lot[0] <= q:
                taken += lot[0]
                q -= lot[0]
            else:
                lot[0] -= q
                taken += q
                q = 0
                new_lots.append(lot)
        lots[p] = new_lots
        shipped += taken
        earned += taken * price[p]
        return taken

    def fill_backorders(p):
        while backorders[p] and stock_total(p) > 0:
            qty, day = backorders[p][0]
            taken = take_stock(p, qty)
            if taken == 0:
                break
            if taken == qty:
                backorders[p].pop(0)
            else:
                backorders[p][0][0] -= taken
                break

    def add_lot(p, qty, expiry):
        nonlocal arrival_counter
        if qty <= 0:
            return
        lots[p].append([qty, expiry, arrival_counter])
        arrival_counter += 1
        fill_backorders(p)

    def ship_order(p, qty, day):
        if backorders[p]:
            backorders[p].append([qty, day])
        else:
            taken = take_stock(p, qty)
            rem = qty - taken
            if rem > 0:
                backorders[p].append([rem, day])

    eidx = 0
    E = len(ev_day)
    for d in range(days):
        for p in range(P):
            new_lots = []
            for lot in lots[p]:
                if lot[1] < d:
                    discarded += lot[0]
                else:
                    new_lots.append(lot)
            lots[p] = new_lots

        for p in range(P):
            arrived = []
            remaining = []
            for due in pending[p]:
                if due == d:
                    arrived.append(due)
                else:
                    remaining.append(due)
            pending[p] = remaining
            for _ in arrived:
                add_lot(p, rq[p], d + shelf[p])

        while eidx < E and ev_day[eidx] == d:
            kind = ev_kind[eidx]
            p = ev_prod[eidx]
            qty = ev_qty[eidx]
            if kind == 1:
                expiry = ev_expiry[eidx]
                add_lot(p, qty, expiry)
            else:
                ship_order(p, qty, d)
            eidx += 1

        cutoff = d - 7
        for p in range(P):
            new_q = []
            for q, placed in backorders[p]:
                if placed <= cutoff:
                    cancelled += q
                else:
                    new_q.append([q, placed])
            backorders[p] = new_q

        for p in range(P):
            if not pending[p] and stock_total(p) <= rp[p]:
                pending[p].append(d + lead[p])
                supplies += 1

    stock = [stock_total(p) for p in range(P)]
    owed = 0
    for p in range(P):
        for q, _ in backorders[p]:
            owed += q

    return (stock, earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    l1 = [[] for _ in range(s1)]
    l2 = [[] for _ in range(s2)]
    l1_hits = 0
    l1_misses = 0
    l2_hits = 0
    l2_misses = 0
    mem_reads = 0
    mem_writes = 0

    def insert_l2(block, dirty):
        nonlocal mem_writes
        set_idx = block % s2
        st = l2[set_idx]
        if len(st) >= w2:
            evicted = st.pop(0)
            if evicted[1]:
                mem_writes += 1
        st.append([block, dirty])

    def insert_l1(block, dirty):
        set_idx = block % s1
        st = l1[set_idx]
        if len(st) >= w1:
            evicted_block, evicted_dirty = st.pop(0)
            if evicted_dirty:
                sidx2 = evicted_block % s2
                st2 = l2[sidx2]
                idx2 = -1
                for i, entry in enumerate(st2):
                    if entry[0] == evicted_block:
                        idx2 = i
                        break
                if idx2 != -1:
                    entry = st2.pop(idx2)
                    entry[1] = True
                    st2.append(entry)
                else:
                    insert_l2(evicted_block, True)
        st.append([block, dirty])

    for a, w in zip(addrs, writes):
        set1 = a % s1
        idx1 = -1
        for i, entry in enumerate(l1[set1]):
            if entry[0] == a:
                idx1 = i
                break

        if idx1 != -1:
            l1_hits += 1
            entry = l1[set1].pop(idx1)
            if w:
                entry[1] = True
            l1[set1].append(entry)
        else:
            l1_misses += 1
            set2 = a % s2
            idx2 = -1
            for i, entry in enumerate(l2[set2]):
                if entry[0] == a:
                    idx2 = i
                    break

            if idx2 != -1:
                l2_hits += 1
                entry = l2[set2].pop(idx2)
                l2[set2].append(entry)
            else:
                l2_misses += 1
                mem_reads += 1
                insert_l2(a, False)

            insert_l1(a, w)

    dirty = 0
    for st in l1:
        for entry in st:
            if entry[1]:
                dirty += 1
    for st in l2:
        for entry in st:
            if entry[1]:
                dirty += 1

    l1_blocks = []
    for st in l1:
        for entry in st:
            l1_blocks.append(entry[0])

    return (l1_hits, l1_misses, l2_hits, l2_misses, mem_reads, mem_writes, dirty, l1_blocks)
```