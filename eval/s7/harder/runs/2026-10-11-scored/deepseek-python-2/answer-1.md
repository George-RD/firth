### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = boxes[:]
    hist = []
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    read = 0
    deltas = [-width, 1, width, -1]
    for move in moves:
        if all(cells[b] == 2 for b in boxes):
            break
        if move == 4:
            if hist:
                d, box_idx = hist.pop()
                delta = deltas[d]
                player -= delta
                if box_idx is not None:
                    boxes[box_idx] -= delta
                undos += 1
        else:
            d = move
            delta = deltas[d]
            t = player + delta
            if cells[t] == 1:
                blocked += 1
            else:
                box_idx = -1
                for idx, b in enumerate(boxes):
                    if b == t:
                        box_idx = idx
                        break
                if box_idx != -1:
                    u = t + delta
                    if cells[u] == 1 or u in boxes:
                        blocked += 1
                    else:
                        boxes[box_idx] = u
                        player = t
                        hist.append((d, box_idx))
                        pushes += 1
                        if cells[u] != 2:
                            wall_vert = (cells[u - width] == 1) or (cells[u + width] == 1)
                            wall_horiz = (cells[u - 1] == 1) or (cells[u + 1] == 1)
                            if wall_vert and wall_horiz:
                                dead += 1
                else:
                    player = t
                    hist.append((d, None))
        read += 1
    solved = all(cells[b] == 2 for b in boxes)
    return (player, boxes, read, len(hist), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    b = board[:]
    coords = []
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        coords.append((r, c))
    coord_to_i = {pos: i for i, pos in enumerate(coords)}

    steps = [dict() for _ in range(32)]
    jumps = [dict() for _ in range(32)]
    for i in range(32):
        r, c = coords[i]
        for dr in (-1, 1):
            for dc in (-1, 1):
                nr, nc = r + dr, c + dc
                if 0 <= nr < 8 and 0 <= nc < 8:
                    j = coord_to_i.get((nr, nc))
                    if j is not None:
                        steps[i][(dr, dc)] = j
                nr2, nc2 = r + 2*dr, c + 2*dc
                if 0 <= nr2 < 8 and 0 <= nc2 < 8:
                    over = coord_to_i.get((r+dr, c+dc))
                    land = coord_to_i.get((nr2, nc2))
                    if over is not None and land is not None:
                        jumps[i][(dr, dc)] = (over, land)

    white_took = 0
    black_took = 0
    crowned = 0

    def gen_captures(side):
        results = []
        opp_vals = {3,4} if side == 0 else {1,2}
        for start in range(32):
            piece = b[start]
            if side == 0 and piece not in (1,2): continue
            if side == 1 and piece not in (3,4): continue
            def dfs(current, piece, landings, cap_count):
                if piece == 1: drs = (-1,)
                elif piece == 3: drs = (1,)
                else: drs = (-1, 1)
                found = False
                for dr in drs:
                    for dc in (-1, 1):
                        jump = jumps[current].get((dr, dc))
                        if not jump: continue
                        over, land = jump
                        if b[over] in opp_vals and b[land] == 0:
                            found = True
                            captured = b[over]
                            b[current] = 0
                            b[over] = 0
                            new_piece = piece
                            crowned_now = False
                            r = land // 4
                            if piece == 1 and r == 0:
                                new_piece = 2
                                crowned_now = True
                            elif piece == 3 and r == 7:
                                new_piece = 4
                                crowned_now = True
                            b[land] = new_piece
                            landings.append(land)
                            if crowned_now:
                                results.append((start, tuple(landings), cap_count+1, new_piece))
                            else:
                                dfs(land, new_piece, landings, cap_count+1)
                            landings.pop()
                            b[land] = 0
                            b[over] = captured
                            b[current] = piece
                if not found and cap_count > 0:
                    results.append((start, tuple(landings), cap_count, piece))
            dfs(start, piece, [], 0)
        return results

    def apply_capture(cap):
        nonlocal white_took, black_took, crowned
        start, landings, _, _ = cap
        side = 0 if b[start] in (1,2) else 1
        piece = b[start]
        b[start] = 0
        current = start
        for land in landings:
            r1, c1 = coords[current]
            r2, c2 = coords[land]
            over_r, over_c = (r1+r2)//2, (c1+c2)//2
            over = coord_to_i[(over_r, over_c)]
            captured = b[over]
            if side == 0:
                white_took += 1
            else:
                black_took += 1
            b[over] = 0
            b[current] = 0
            r = land // 4
            if piece == 1 and r == 0:
                piece = 2
                crowned += 1
            elif piece == 3 and r == 7:
                piece = 4
                crowned += 1
            b[land] = piece
            current = land

    def gen_steps(side):
        steps_list = []
        for start in range(32):
            piece = b[start]
            if side == 0 and piece not in (1,2): continue
            if side == 1 and piece not in (3,4): continue
            if piece == 1: drs = (-1,)
            elif piece == 3: drs = (1,)
            else: drs = (-1, 1)
            for dr in drs:
                for dc in (-1, 1):
                    dest = steps[start].get((dr, dc))
                    if dest is not None and b[dest] == 0:
                        steps_list.append((start, dest))
        return steps_list

    def apply_step(step):
        nonlocal crowned
        start, dest = step
        piece = b[start]
        b[start] = 0
        r = dest // 4
        if piece == 1 and r == 0:
            piece = 2
            crowned += 1
        elif piece == 3 and r == 7:
            piece = 4
            crowned += 1
        b[dest] = piece

    played = 0
    side = turn
    result = 0

    while True:
        caps = gen_captures(side)
        if caps:
            if played >= plies:
                result = 0
                break
            caps.sort(key=lambda c: (-c[2], c[0], c[1]))
            chosen = caps[0]
            apply_capture(chosen)
            played += 1
            side = 1 - side
        else:
            steps_list = gen_steps(side)
            if not steps_list:
                result = 2 if side == 0 else 1
                break
            if played >= plies:
                result = 0
                break
            steps_list.sort(key=lambda s: (s[0], s[1]))
            chosen = steps_list[0]
            apply_step(chosen)
            played += 1
            side = 1 - side

    return (b, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    tokens = pattern
    i = 0
    valid = True

    def parse_alt():
        nonlocal i, valid
        seqs = []
        seqs.append(parse_seq())
        while i < len(tokens) and tokens[i] == 30:
            i += 1
            seqs.append(parse_seq())
        return ('alt', tuple(seqs))

    def parse_seq():
        nonlocal i, valid
        items = []
        while i < len(tokens) and tokens[i] not in (30, 32):
            if tokens[i] in (27, 28, 29):
                valid = False
                return ('seq', ())
            atom = parse_atom()
            if not valid:
                return ('seq', ())
            node = atom
            while i < len(tokens) and tokens[i] in (27, 28, 29):
                op = tokens[i]
                i += 1
                node = ('rep', op, node)
            items.append(node)
        return ('seq', tuple(items))

    def parse_atom():
        nonlocal i, valid
        if i >= len(tokens):
            valid = False
            return None
        t = tokens[i]
        if 0 <= t <= 25:
            i += 1
            return ('char', t)
        elif t == 26:
            i += 1
            return ('dot',)
        elif t == 31:
            i += 1
            node = parse_alt()
            if not valid:
                return None
            if i >= len(tokens) or tokens[i] != 32:
                valid = False
                return None
            i += 1
            return node
        else:
            valid = False
            return None

    ast = parse_alt()
    if i != len(tokens):
        valid = False
    if not valid:
        ast = None

    strings = []
    pos = 0
    for L in lens:
        strings.append(chars[pos:pos+L])
        pos += L

    full_list = []
    longest_list = []
    count = 0

    if not valid:
        for _ in strings:
            full_list.append(False)
            longest_list.append(-1)
        return (full_list, longest_list, 0, False)

    from functools import lru_cache

    for s in strings:
        @lru_cache(maxsize=None)
        def match(node, pos):
            typ = node[0]
            if typ == 'char':
                c = node[1]
                if pos < len(s) and s[pos] == c:
                    return frozenset([pos+1])
                return frozenset()
            elif typ == 'dot':
                if pos < len(s):
                    return frozenset([pos+1])
                return frozenset()
            elif typ == 'alt':
                res = set()
                for seq in node[1]:
                    res.update(match(seq, pos))
                return frozenset(res)
            elif typ == 'seq':
                current = {pos}
                for item in node[1]:
                    nxt = set()
                    for p in current:
                        nxt.update(match(item, p))
                    current = nxt
                    if not current:
                        break
                return frozenset(current)
            elif typ == 'rep':
                op = node[1]
                sub = node[2]
                if op == 29:
                    res = {pos}
                    res.update(match(sub, pos))
                    return frozenset(res)
                elif op == 27:
                    initial = {pos}
                elif op == 28:
                    initial = set(match(sub, pos))
                    if not initial:
                        return frozenset()
                visited = set(initial)
                queue = list(initial)
                while queue:
                    p = queue.pop()
                    for q in match(sub, p):
                        if q not in visited:
                            visited.add(q)
                            queue.append(q)
                return frozenset(visited)
            return frozenset()

        ends = match(ast, 0)
        if ends:
            longest = max(ends)
        else:
            longest = -1
        full = len(s) in ends
        if full:
            count += 1
        full_list.append(full)
        longest_list.append(longest)

    return (full_list, longest_list, count, True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    N = len(ratings)
    scores = [0] * N
    whites = [0] * N
    last_color = [None] * N
    played = [set() for _ in range(N)]
    opponents = [[] for _ in range(N)]
    has_bye = [False] * N
    rematches = 0
    res_idx = 0

    for rnd in range(rounds):
        ranking = sorted(range(N), key=lambda p: (-scores[p], -ratings[p], p))
        bye_player = None
        if N % 2 == 1:
            for p in reversed(ranking):
                if not has_bye[p]:
                    bye_player = p
                    break
            if bye_player is not None:
                has_bye[bye_player] = True
                scores[bye_player] += 2

        paired = set()
        if bye_player is not None:
            paired.add(bye_player)

        for p in ranking:
            if p in paired:
                continue
            opponent = None
            for q in ranking:
                if q == p or q in paired:
                    continue
                if q not in played[p]:
                    opponent = q
                    break
            if opponent is None:
                for q in ranking:
                    if q == p or q in paired:
                        continue
                    opponent = q
                    break
                if opponent is not None:
                    rematches += 1
            if opponent is None:
                continue
            paired.add(p)
            paired.add(opponent)

            if whites[p] < whites[opponent]:
                white = p
                black = opponent
            elif whites[p] > whites[opponent]:
                white = opponent
                black = p
            else:
                last_p = last_color[p]
                last_q = last_color[opponent]
                if last_p == 0 and last_q != 0:
                    white = p
                    black = opponent
                elif last_q == 0 and last_p != 0:
                    white = opponent
                    black = p
                else:
                    white = p
                    black = opponent

            whites[white] += 1
            last_color[white] = 1
            last_color[black] = 0

            res = results[res_idx]
            res_idx += 1
            if res == 0:
                scores[white] += 2
            elif res == 1:
                scores[white] += 1
                scores[black] += 1
            elif res == 2:
                scores[black] += 2

            opponents[p].append(opponent)
            opponents[opponent].append(p)
            played[p].add(opponent)
            played[opponent].add(p)

    buchholz = []
    for p in range(N):
        total = 0
        for opp in opponents[p]:
            total += scores[opp]
        buchholz.append(total)

    final_ranking = sorted(range(N), key=lambda p: (-scores[p], -buchholz[p], -ratings[p], p))
    return (scores, buchholz, final_ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    backorder = [[] for _ in range(P)]
    pending_supply = [None] * P
    seq = 0
    earned = 0
    total_shipped = 0
    discarded = 0
    cancelled = 0
    supplies = 0

    def take_from_stock(p, q):
        nonlocal total_shipped, earned
        remaining = q
        shipped = 0
        lots[p].sort(key=lambda x: (x[1], x[2]))
        i = 0
        while remaining > 0 and i < len(lots[p]):
            lot = lots[p][i]
            take = min(lot[0], remaining)
            lot[0] -= take
            remaining -= take
            shipped += take
            if lot[0] == 0:
                lots[p].pop(i)
            else:
                i += 1
        if shipped:
            total_shipped += shipped
            earned += shipped * price[p]
        return shipped, remaining

    def fill_backorders(p):
        while backorder[p]:
            bo = backorder[p][0]
            shipped, remaining = take_from_stock(p, bo[0])
            if shipped == 0:
                break
            bo[0] -= shipped
            if bo[0] == 0:
                backorder[p].pop(0)

    def add_lot(p, qty, expiry):
        nonlocal seq
        lots[p].append([qty, expiry, seq])
        seq += 1
        fill_backorders(p)

    event_idx = 0
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
            if pending_supply[p] == d:
                add_lot(p, rq[p], d + shelf[p])
                pending_supply[p] = None
        while event_idx < E and ev_day[event_idx] == d:
            kind = ev_kind[event_idx]
            p = ev_prod[event_idx]
            qty = ev_qty[event_idx]
            if kind == 1:
                expiry = ev_expiry[event_idx]
                add_lot(p, qty, expiry)
            else:
                if backorder[p]:
                    backorder[p].append([qty, d])
                else:
                    shipped, remaining = take_from_stock(p, qty)
                    if remaining > 0:
                        backorder[p].append([remaining, d])
            event_idx += 1
        for p in range(P):
            while backorder[p] and backorder[p][0][1] <= d - 7:
                bo = backorder[p].pop(0)
                cancelled += bo[0]
        for p in range(P):
            if pending_supply[p] is None:
                stock = sum(lot[0] for lot in lots[p])
                if stock <= rp[p]:
                    pending_supply[p] = d + lead[p]
                    supplies += 1

    stock = [sum(lot[0] for lot in lots[p]) for p in range(P)]
    owed = sum(sum(bo[0] for bo in backorder[p]) for p in range(P))
    return (stock, earned, total_shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    l1_hits = l1_misses = l2_hits = l2_misses = 0
    mem_reads = mem_writes = 0

    def find(cache, set_idx, block):
        for i, entry in enumerate(cache[set_idx]):
            if entry[0] == block:
                return i
        return -1

    for i, a in enumerate(addrs):
        is_write = writes[i]
        set1 = a % s1
        set2 = a % s2

        idx1 = find(L1, set1, a)
        if idx1 != -1:
            l1_hits += 1
            entry = L1[set1].pop(idx1)
            entry[1] = entry[1] or is_write
            L1[set1].append(entry)
        else:
            l1_misses += 1
            idx2 = find(L2, set2, a)
            if idx2 != -1:
                l2_hits += 1
                entry2 = L2[set2].pop(idx2)
                L2[set2].append(entry2)
            else:
                l2_misses += 1
                mem_reads += 1
                if len(L2[set2]) >= w2:
                    evicted = L2[set2].pop(0)
                    if evicted[1]:
                        mem_writes += 1
                L2[set2].append([a, False])
            if len(L1[set1]) >= w1:
                evicted1 = L1[set1].pop(0)
                b = evicted1[0]
                b_dirty = evicted1[1]
                if b_dirty:
                    set_b2 = b % s2
                    idx_b2 = find(L2, set_b2, b)
                    if idx_b2 != -1:
                        entry_b2 = L2[set_b2].pop(idx_b2)
                        entry_b2[1] = True
                        L2[set_b2].append(entry_b2)
                    else:
                        if len(L2[set_b2]) >= w2:
                            evicted2 = L2[set_b2].pop(0)
                            if evicted2[1]:
                                mem_writes += 1
                        L2[set_b2].append([b, True])
            L1[set1].append([a, is_write])

    dirty = 0
    for s in L1:
        for entry in s:
            if entry[1]:
                dirty += 1
    for s in L2:
        for entry in s:
            if entry[1]:
                dirty += 1

    l1_blocks = []
    for s in L1:
        for entry in s:
            l1_blocks.append(entry[0])

    return (l1_hits, l1_misses, l2_hits, l2_misses, mem_reads, mem_writes, dirty, l1_blocks)
```