### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)

    def solved():
        return all(cells[b] == 2 for b in boxes)

    history = []
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    read = 0
    dirs = {0: -width, 1: 1, 2: width, 3: -1}

    for i, m in enumerate(moves):
        if solved():
            read = i
            break

        if m == 4:
            if history:
                old_p, new_p, box_idx, old_b, new_b = history.pop()
                if box_idx != -1:
                    boxes[box_idx] = old_b
                player = old_p
                undos += 1
        else:
            dr = dirs[m]
            t = player + dr
            if cells[t] == 1:
                blocked += 1
            else:
                box_idx = -1
                for k, b in enumerate(boxes):
                    if b == t:
                        box_idx = k
                        break

                if box_idx != -1:
                    u = t + dr
                    if cells[u] == 1 or any(b == u for b in boxes):
                        blocked += 1
                    else:
                        old_p = player
                        old_b = boxes[box_idx]
                        boxes[box_idx] = u
                        player = t
                        pushes += 1

                        if cells[u] != 2:
                            r = u // width
                            c = u % width
                            if (cells[u - width] == 1 or cells[u + width] == 1) and (
                                cells[u - 1] == 1 or cells[u + 1] == 1
                            ):
                                dead += 1

                        history.append((old_p, t, box_idx, old_b, u))
                else:
                    old_p = player
                    player = t
                    history.append((old_p, t, -1, -1, -1))

        read = i + 1
    else:
        read = len(moves)

    return (
        player,
        boxes,
        read,
        len(history),
        pushes,
        blocked,
        undos,
        dead,
        solved(),
    )
```

### task: checkers
```python
def main(board, turn, plies):
    board = list(board)

    def rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def sq(r, c):
        if 0 <= r < 8 and 0 <= c < 8 and (r + c) % 2 == 1:
            return r * 4 + c // 2
        return -1

    def dirs_for(piece):
        if piece == 1:
            return [(-1, -1), (-1, 1)]
        if piece == 3:
            return [(1, -1), (1, 1)]
        return [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def gen_captures(b, start):
        piece = b[start]
        if piece == 0:
            return []
        if piece in (1, 2):
            opp = (3, 4)
        else:
            opp = (1, 2)
        dirs = dirs_for(piece)
        results = []

        def dfs(nb, pos, seq, caps):
            r, c = rc(pos)
            found = False
            for dr, dc in dirs:
                mid = sq(r + dr, c + dc)
                dest = sq(r + 2 * dr, c + 2 * dc)
                if mid == -1 or dest == -1:
                    continue
                if nb[mid] not in opp:
                    continue
                if nb[dest] != 0:
                    continue

                found = True
                nxt = nb[:]
                nxt[pos] = 0
                nxt[mid] = 0
                nxt[dest] = piece
                new_seq = seq + [dest]
                new_caps = caps + [mid]

                if piece == 1 and rc(dest)[0] == 0:
                    results.append((new_seq, new_caps))
                elif piece == 3 and rc(dest)[0] == 7:
                    results.append((new_seq, new_caps))
                else:
                    dfs(nxt, dest, new_seq, new_caps)

            if not found and seq:
                results.append((seq, caps))

        dfs(b[:], start, [], [])
        return results

    def get_capture_moves(b, side):
        moves = []
        for i in range(32):
            piece = b[i]
            if side == 0 and piece not in (1, 2):
                continue
            if side == 1 and piece not in (3, 4):
                continue
            if piece == 0:
                continue
            for seq, caps in gen_captures(b, i):
                moves.append((len(seq), i, seq, caps))
        return moves

    def get_step_moves(b, side):
        moves = []
        for i in range(32):
            piece = b[i]
            if side == 0 and piece not in (1, 2):
                continue
            if side == 1 and piece not in (3, 4):
                continue
            r, c = rc(i)
            for dr, dc in dirs_for(piece):
                dest = sq(r + dr, c + dc)
                if dest != -1 and b[dest] == 0:
                    moves.append((i, dest))
        return moves

    side = turn
    played = 0
    white_took = 0
    black_took = 0
    crowned = 0
    result = 0

    while True:
        cap_moves = get_capture_moves(board, side)
        chosen_cap = None
        chosen_step = None

        if cap_moves:
            maxlen = max(m[0] for m in cap_moves)
            cands = [m for m in cap_moves if m[0] == maxlen]
            chosen_cap = min(cands, key=lambda m: (m[1], tuple(m[2])))
        else:
            step_moves = get_step_moves(board, side)
            if not step_moves:
                result = 2 if side == 0 else 1
                break
            chosen_step = min(step_moves, key=lambda m: (m[0], m[1]))

        if played >= plies:
            result = 0
            break

        if chosen_cap is not None:
            _, start, seq, caps = chosen_cap
            piece = board[start]
            for cap in caps:
                board[cap] = 0
            board[start] = 0
            final = seq[-1]
            crowned_flag = False
            if piece == 1 and rc(final)[0] == 0:
                board[final] = 2
                crowned_flag = True
            elif piece == 3 and rc(final)[0] == 7:
                board[final] = 4
                crowned_flag = True
            else:
                board[final] = piece

            if side == 0:
                white_took += len(caps)
            else:
                black_took += len(caps)
            if crowned_flag:
                crowned += 1
        else:
            start, dest = chosen_step
            piece = board[start]
            board[start] = 0
            crowned_flag = False
            if piece == 1 and rc(dest)[0] == 0:
                board[dest] = 2
                crowned_flag = True
            elif piece == 3 and rc(dest)[0] == 7:
                board[dest] = 4
                crowned_flag = True
            else:
                board[dest] = piece
            if crowned_flag:
                crowned += 1

        played += 1
        side = 1 - side

    return (board, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    tokens = pattern
    idx = 0

    def parse_alt():
        nonlocal idx
        seqs = [parse_seq()]
        while idx < len(tokens) and tokens[idx] == 30:
            idx += 1
            seqs.append(parse_seq())
        return ("alt", seqs)

    def parse_seq():
        nonlocal idx
        items = []
        while idx < len(tokens) and tokens[idx] not in (30, 32):
            items.append(parse_item())
        return ("seq", items)

    def parse_item():
        nonlocal idx
        atom = parse_atom()
        posts = []
        while idx < len(tokens) and tokens[idx] in (27, 28, 29):
            posts.append(tokens[idx])
            idx += 1
        return ("item", atom, posts)

    def parse_atom():
        nonlocal idx
        if idx >= len(tokens):
            raise ValueError
        t = tokens[idx]
        if t <= 25:
            idx += 1
            return ("char", t)
        if t == 26:
            idx += 1
            return ("dot",)
        if t == 31:
            idx += 1
            alt = parse_alt()
            if idx >= len(tokens) or tokens[idx] != 32:
                raise ValueError
            idx += 1
            return alt
        raise ValueError

    try:
        ast = parse_alt()
        valid = idx == len(tokens)
    except ValueError:
        valid = False

    if not valid:
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    def ends(node, s, pos):
        typ = node[0]

        if typ == "char":
            if pos < len(s) and s[pos] == node[1]:
                return {pos + 1}
            return set()

        if typ == "dot":
            if pos < len(s):
                return {pos + 1}
            return set()

        if typ == "alt":
            res = set()
            for seq in node[1]:
                res |= ends(seq, s, pos)
            return res

        if typ == "seq":
            states = {pos}
            for item in node[1]:
                new_states = set()
                for p in states:
                    new_states |= ends(item, s, p)
                states = new_states
                if not states:
                    break
            return states

        if typ == "item":
            expr = node[1]
            for op in node[2]:
                if op == 27:
                    expr = ("star", expr)
                elif op == 28:
                    expr = ("plus", expr)
                elif op == 29:
                    expr = ("opt", expr)
            return ends(expr, s, pos)

        if typ == "star":
            res = {pos}
            frontier = [pos]
            while frontier:
                p = frontier.pop()
                for q in ends(node[1], s, p):
                    if q not in res:
                        res.add(q)
                        frontier.append(q)
            return res

        if typ == "plus":
            first = set()
            for q in ends(node[1], s, pos):
                first.add(q)
            res = set(first)
            frontier = list(first)
            while frontier:
                p = frontier.pop()
                for q in ends(node[1], s, p):
                    if q not in res:
                        res.add(q)
                        frontier.append(q)
            return res

        if typ == "opt":
            res = {pos}
            res |= ends(node[1], s, pos)
            return res

        return set()

    strings = []
    ci = 0
    for L in lens:
        strings.append(chars[ci:ci + L])
        ci += L

    full = []
    longest = []
    count = 0

    for s in strings:
        ends_set = ends(ast, s, 0)
        n = len(s)
        is_full = n in ends_set
        full.append(is_full)
        if is_full:
            count += 1
        if ends_set:
            longest.append(max(ends_set))
        else:
            longest.append(-1)

    return (full, longest, count, True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    scores = [0] * n
    whites = [0] * n
    last_color = [-1] * n
    had_bye = [False] * n
    played = [set() for _ in range(n)]
    opponents = [[] for _ in range(n)]
    rematches = 0
    ridx = 0

    for _ in range(rounds):
        order = sorted(range(n), key=lambda p: (-scores[p], -ratings[p], p))

        bye = None
        if n % 2 == 1:
            for p in reversed(order):
                if not had_bye[p]:
                    bye = p
                    break
            if bye is not None:
                scores[bye] += 2
                had_bye[bye] = True

        remaining = [p for p in order if p != bye]
        games = []

        while remaining:
            first = remaining[0]
            second = None
            for cand in remaining[1:]:
                if cand not in played[first]:
                    second = cand
                    break
            if second is None:
                second = remaining[1]

            if second in played[first]:
                rematches += 1

            if whites[first] < whites[second]:
                white, black = first, second
            elif whites[second] < whites[first]:
                white, black = second, first
            else:
                b1 = last_color[first] == 1
                b2 = last_color[second] == 1
                if b1 != b2:
                    white = first if b1 else second
                else:
                    white = first
            black = second if white == first else first

            games.append((white, black))
            played[first].add(second)
            played[second].add(first)
            remaining.remove(first)
            remaining.remove(second)

        for white, black in games:
            res = results[ridx]
            ridx += 1

            opponents[white].append(black)
            opponents[black].append(white)

            whites[white] += 1
            last_color[white] = 0
            last_color[black] = 1

            if res == 0:
                scores[white] += 2
            elif res == 1:
                scores[white] += 1
                scores[black] += 1
            else:
                scores[black] += 2

    buchholz = [sum(scores[opp] for opp in opponents[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-scores[p], -buchholz[p], -ratings[p], p))

    return (scores, buchholz, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    backorders = [[] for _ in range(P)]
    supply_due = [None] * P

    arrival_counter = 0
    supplies = 0
    earned = 0
    shipped = 0
    discarded = 0
    cancelled = 0

    def stock_sum(p):
        return sum(lot[0] for lot in lots[p])

    def add_lot(p, qty, expiry):
        nonlocal arrival_counter
        if qty <= 0:
            return
        lots[p].append([qty, expiry, arrival_counter])
        arrival_counter += 1

    def take_stock(p, amount):
        nonlocal shipped, earned
        taken = 0
        lots[p].sort(key=lambda x: (x[1], x[2]))
        new_lots = []
        for lot in lots[p]:
            if amount <= 0:
                new_lots.append(lot)
                continue
            if lot[0] <= amount:
                taken += lot[0]
                amount -= lot[0]
            else:
                lot[0] -= amount
                taken += amount
                amount = 0
                new_lots.append(lot)
        lots[p] = new_lots
        if taken > 0:
            shipped += taken
            earned += taken * price[p]
        return taken

    def fill_backorders(p):
        while backorders[p] and stock_sum(p) > 0:
            owed = backorders[p][0][0]
            avail = stock_sum(p)
            amt = min(owed, avail)
            taken = take_stock(p, amt)
            if taken == 0:
                break
            owed -= taken
            if owed <= 0:
                backorders[p].pop(0)
            else:
                backorders[p][0][0] = owed

    e = 0
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
            if supply_due[p] == d:
                add_lot(p, rq[p], d + shelf[p])
                supply_due[p] = None
                fill_backorders(p)

        while e < len(ev_day) and ev_day[e] == d:
            kind = ev_kind[e]
            p = ev_prod[e]
            qty = ev_qty[e]

            if kind == 1:
                add_lot(p, qty, ev_expiry[e])
                fill_backorders(p)
            else:
                if backorders[p]:
                    backorders[p].append([qty, d])
                else:
                    avail = stock_sum(p)
                    take = min(qty, avail)
                    if take > 0:
                        take_stock(p, take)
                    left = qty - take
                    if left > 0:
                        backorders[p].append([left, d])
            e += 1

        cancel_day = d - 7
        for p in range(P):
            while backorders[p] and backorders[p][0][1] <= cancel_day:
                owed, _ = backorders[p].pop(0)
                cancelled += owed

        for p in range(P):
            if supply_due[p] is None and stock_sum(p) <= rp[p]:
                supply_due[p] = d + lead[p]
                supplies += 1

    stock = [stock_sum(p) for p in range(P)]
    owed = sum(bo[0] for p in range(P) for bo in backorders[p])

    return (stock, earned, shipped, discarded, cancelled, supplies, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]

    l1_hits = 0
    l1_misses = 0
    l2_hits = 0
    l2_misses = 0
    mem_reads = 0
    mem_writes = 0

    def find(level, set_idx, block):
        for i, entry in enumerate(level[set_idx]):
            if entry[0] == block:
                return i
        return -1

    def put_L2(block, dirty):
        nonlocal mem_writes
        set_idx = block % s2
        idx = find(L2, set_idx, block)
        if idx != -1:
            entry = L2[set_idx].pop(idx)
            if dirty:
                entry[1] = True
            L2[set_idx].append(entry)
            return

        if len(L2[set_idx]) >= w2:
            evicted = L2[set_idx].pop(0)
            if evicted[1]:
                mem_writes += 1
        L2[set_idx].append([block, dirty])

    for block, is_write in zip(addrs, writes):
        set1 = block % s1
        idx1 = find(L1, set1, block)

        if idx1 != -1:
            l1_hits += 1
            entry = L1[set1].pop(idx1)
            if is_write:
                entry[1] = True
            L1[set1].append(entry)
        else:
            l1_misses += 1
            set2 = block % s2
            idx2 = find(L2, set2, block)

            if idx2 != -1:
                l2_hits += 1
                entry = L2[set2].pop(idx2)
                L2[set2].append(entry)
            else:
                l2_misses += 1
                mem_reads += 1
                put_L2(block, False)

            if len(L1[set1]) >= w1:
                evicted = L1[set1].pop(0)
                if evicted[1]:
                    b = evicted[0]
                    set2b = b % s2
                    idx2b = find(L2, set2b, b)
                    if idx2b != -1:
                        entry = L2[set2b].pop(idx2b)
                        entry[1] = True
                        L2[set2b].append(entry)
                    else:
                        put_L2(b, True)

            L1[set1].append([block, is_write])

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