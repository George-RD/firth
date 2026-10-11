### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    dirs = [-width, 1, width, -1]
    boxes = list(boxes)
    history = []
    read = 0
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0

    def solved():
        return all(cells[b] == 2 for b in boxes)

    for move in moves:
        if solved():
            break
        read += 1
        if move == 4:
            if history:
                undos += 1
                d, is_push, bi = history.pop()
                delta = dirs[d]
                old_player = player - delta
                if is_push:
                    boxes[bi] = player
                player = old_player
            continue

        d = move
        delta = dirs[d]
        t = player + delta
        if cells[t] == 1:
            blocked += 1
            continue

        bi = -1
        for i, b in enumerate(boxes):
            if b == t:
                bi = i
                break

        if bi != -1:
            u = t + delta
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue

            player = t
            boxes[bi] = u
            history.append((d, True, bi))
            pushes += 1

            if cells[u] != 2:
                r = u // width
                c = u % width
                wall_above = r > 0 and cells[u - width] == 1
                wall_below = r < height - 1 and cells[u + width] == 1
                wall_left = c > 0 and cells[u - 1] == 1
                wall_right = c < width - 1 and cells[u + 1] == 1
                if (wall_above or wall_below) and (wall_left or wall_right):
                    dead += 1
        else:
            player = t
            history.append((d, False, -1))

    solved_final = solved()
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved_final)
```

### task: checkers
```python
def main(board, turn, plies):
    def idx_to_rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def rc_to_idx(r, c):
        if r < 0 or r > 7 or c < 0 or c > 7 or (r + c) % 2 != 1:
            return None
        offset = 1 if r % 2 == 0 else 0
        k = (c - offset) // 2
        return r * 4 + k

    def is_own(p, side):
        if side == 0:
            return p == 1 or p == 2
        else:
            return p == 3 or p == 4

    def is_opponent(p, side):
        if side == 0:
            return p == 3 or p == 4
        else:
            return p == 1 or p == 2

    def is_man(p):
        return p == 1 or p == 3

    def is_far_row(i, side):
        r, c = idx_to_rc(i)
        if side == 0:
            return r == 0
        else:
            return r == 7

    def allowed_dr(piece, side):
        if piece == 1:
            return [-1]
        if piece == 3:
            return [1]
        return [-1, 1]

    def gen_captures(start, piece, board, side):
        b = board[:]
        b[start] = 0
        results = []

        def rec(cur, piece_type, b, landings, captured_count):
            r, c = idx_to_rc(cur)
            moves = []
            for dr in allowed_dr(piece_type, side):
                for dc in [-1, 1]:
                    mid = rc_to_idx(r + dr, c + dc)
                    if mid is None:
                        continue
                    land = rc_to_idx(r + 2 * dr, c + 2 * dc)
                    if land is None:
                        continue
                    if is_opponent(b[mid], side) and b[land] == 0:
                        moves.append((mid, land))

            if not moves:
                final_b = b[:]
                final_piece = piece_type
                crowned = False
                if is_man(piece_type) and is_far_row(cur, side):
                    final_piece = 2 if side == 0 else 4
                    crowned = True
                final_b[cur] = final_piece
                results.append((start, captured_count, landings[:], final_b, crowned))
                return

            for mid, land in moves:
                nb = b[:]
                nb[mid] = 0
                new_landings = landings + [land]
                new_count = captured_count + 1
                if is_man(piece_type) and is_far_row(land, side):
                    final_b = nb[:]
                    final_piece = 2 if side == 0 else 4
                    final_b[land] = final_piece
                    results.append((start, new_count, new_landings, final_b, True))
                else:
                    rec(land, piece_type, nb, new_landings, new_count)

        rec(start, piece, b, [], 0)
        return results

    played = 0
    white_took = 0
    black_took = 0
    crowned_count = 0
    result = 0
    side = turn

    while True:
        all_caps = []
        for i, p in enumerate(board):
            if is_own(p, side):
                all_caps.extend(gen_captures(i, p, board, side))

        if all_caps:
            if played >= plies:
                result = 0
                break
            max_cap = max(c[1] for c in all_caps)
            best = None
            best_key = None
            for cap in all_caps:
                if cap[1] == max_cap:
                    key = (cap[0], cap[2])
                    if best is None or key < best_key:
                        best = cap
                        best_key = key
            start, count, landings, final_board, crowned = best
            board = final_board
            played += 1
            if side == 0:
                white_took += count
            else:
                black_took += count
            if crowned:
                crowned_count += 1
            side = 1 - side
            continue

        steps = []
        for i, p in enumerate(board):
            if is_own(p, side):
                r, c = idx_to_rc(i)
                for dr in allowed_dr(p, side):
                    for dc in [-1, 1]:
                        j = rc_to_idx(r + dr, c + dc)
                        if j is not None and board[j] == 0:
                            steps.append((i, j, p))

        if not steps:
            result = 2 if side == 0 else 1
            break

        if played >= plies:
            result = 0
            break

        start, dest, p = min(steps, key=lambda x: (x[0], x[1]))
        board[start] = 0
        new_p = p
        if is_man(p) and is_far_row(dest, side):
            new_p = 2 if side == 0 else 4
            crowned_count += 1
        board[dest] = new_p
        played += 1
        side = 1 - side

    return (board, played, white_took, black_took, crowned_count, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    tokens = pattern
    valid = True

    def parse_alt(pos):
        seqs = []
        node, pos = parse_sequence(pos)
        if node is None:
            return None, pos
        seqs.append(node)
        while pos < len(tokens) and tokens[pos] == 30:
            pos += 1
            node, pos = parse_sequence(pos)
            if node is None:
                return None, pos
            seqs.append(node)
        return ('alt', seqs), pos

    def parse_sequence(pos):
        items = []
        while pos < len(tokens) and tokens[pos] not in (30, 32):
            node, pos = parse_item(pos)
            if node is None:
                return None, pos
            items.append(node)
        return ('seq', items), pos

    def parse_item(pos):
        node, pos = parse_atom(pos)
        if node is None:
            return None, pos
        while pos < len(tokens) and tokens[pos] in (27, 28, 29):
            op = tokens[pos]
            pos += 1
            if op == 27:
                node = ('star', node)
            elif op == 28:
                node = ('plus', node)
            else:
                node = ('opt', node)
        return node, pos

    def parse_atom(pos):
        nonlocal valid
        if pos >= len(tokens):
            valid = False
            return None, pos
        tok = tokens[pos]
        if 0 <= tok <= 25:
            return ('lit', tok), pos + 1
        if tok == 26:
            return ('any',), pos + 1
        if tok == 31:
            node, pos = parse_alt(pos + 1)
            if node is None:
                return None, pos
            if pos >= len(tokens) or tokens[pos] != 32:
                valid = False
                return None, pos
            return node, pos + 1
        valid = False
        return None, pos

    root, pos = parse_alt(0)
    if not valid or pos != len(tokens):
        valid = False

    if not valid:
        n = len(lens)
        return ([False] * n, [-1] * n, 0, False)

    strings = []
    idx = 0
    for L in lens:
        strings.append(tuple(chars[idx:idx + L]))
        idx += L

    def match_node(node, s, pos, memo):
        key = (node, pos)
        if key in memo:
            return memo[key]
        typ = node[0]
        if typ == 'lit':
            res = {pos + 1} if pos < len(s) and s[pos] == node[1] else set()
        elif typ == 'any':
            res = {pos + 1} if pos < len(s) else set()
        elif typ == 'seq':
            res = {pos}
            for item in node[1]:
                new = set()
                for p in res:
                    new |= match_node(item, s, p, memo)
                res = new
                if not res:
                    break
        elif typ == 'alt':
            res = set()
            for seq in node[1]:
                res |= match_node(seq, s, pos, memo)
        elif typ == 'star':
            res = {pos}
            stack = [pos]
            while stack:
                p = stack.pop()
                for q in match_node(node[1], s, p, memo):
                    if q not in res:
                        res.add(q)
                        stack.append(q)
        elif typ == 'plus':
            first = match_node(node[1], s, pos, memo)
            res = set(first)
            stack = list(first)
            while stack:
                p = stack.pop()
                for q in match_node(node[1], s, p, memo):
                    if q not in res:
                        res.add(q)
                        stack.append(q)
        elif typ == 'opt':
            res = {pos} | match_node(node[1], s, pos, memo)
        else:
            res = set()
        memo[key] = res
        return res

    full = []
    longest = []
    count = 0
    for s in strings:
        memo = {}
        ends = match_node(root, s, 0, memo)
        if not ends:
            full.append(False)
            longest.append(-1)
        else:
            full.append(len(s) in ends)
            longest.append(max(ends))
        if full[-1]:
            count += 1

    return (full, longest, count, True)
```

### task: swiss
```python
def main(ratings, rounds, results):
    N = len(ratings)
    score = [0] * N
    whites = [0] * N
    last_color = [None] * N
    opponents = [set() for _ in range(N)]
    games_opponents = [[] for _ in range(N)]
    had_bye = [False] * N
    rematches = 0
    games_per_round = N // 2
    res_idx = 0

    for r in range(rounds):
        ranking = sorted(range(N), key=lambda p: (-score[p], -ratings[p], p))
        bye_player = None
        if N % 2 == 1:
            for p in reversed(ranking):
                if not had_bye[p]:
                    bye_player = p
                    break
            if bye_player is not None:
                score[bye_player] += 2
                had_bye[bye_player] = True

        unpaired = [p for p in ranking if p != bye_player]
        pairs = []
        while unpaired:
            A = unpaired.pop(0)
            B = None
            for cand in unpaired:
                if cand not in opponents[A]:
                    B = cand
                    break
            if B is None:
                B = unpaired[0]
                rematches += 1
            unpaired.remove(B)
            pairs.append((A, B))

        for A, B in pairs:
            if whites[A] < whites[B]:
                white, black = A, B
            elif whites[B] < whites[A]:
                white, black = B, A
            else:
                if last_color[A] == False and last_color[B] != False:
                    white, black = A, B
                elif last_color[B] == False and last_color[A] != False:
                    white, black = B, A
                else:
                    white, black = A, B

            res = results[res_idx]
            res_idx += 1
            if res == 0:
                score[white] += 2
            elif res == 1:
                score[white] += 1
                score[black] += 1
            else:
                score[black] += 2

            whites[white] += 1
            last_color[white] = True
            last_color[black] = False
            opponents[white].add(black)
            opponents[black].add(white)
            games_opponents[white].append(black)
            games_opponents[black].append(white)

    buchholz = [0] * N
    for p in range(N):
        buchholz[p] = sum(score[opp] for opp in games_opponents[p])

    ranking = sorted(range(N), key=lambda p: (-score[p], -buchholz[p], -ratings[p], p))
    return (score, buchholz, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    backorders = [[] for _ in range(P)]
    supply_due = [None] * P
    arrival_seq = 0
    earned = 0
    shipped = 0
    discarded = 0
    cancelled = 0
    supplies = 0
    ev_idx = 0
    E = len(ev_day)

    def add_lot(p, qty, expiry):
        nonlocal arrival_seq
        lots[p].append([qty, expiry, arrival_seq])
        arrival_seq += 1
        lots[p].sort(key=lambda x: (x[1], x[2]))

    def take_stock(p, q):
        taken = 0
        while q > 0 and lots[p]:
            lot = lots[p][0]
            take = min(q, lot[0])
            lot[0] -= take
            q -= take
            taken += take
            if lot[0] == 0:
                lots[p].pop(0)
        return taken

    def fill_backorders(p):
        nonlocal earned, shipped
        while backorders[p] and lots[p]:
            owed, placed = backorders[p][0]
            taken = take_stock(p, owed)
            if taken == 0:
                break
            shipped += taken
            earned += taken * price[p]
            owed -= taken
            if owed == 0:
                backorders[p].pop(0)
            else:
                backorders[p][0][0] = owed
                break

    for d in range(days):
        for p in range(P):
            while lots[p] and lots[p][0][1] < d:
                qty, exp, arr = lots[p].pop(0)
                discarded += qty

        for p in range(P):
            if supply_due[p] is not None and supply_due[p] == d:
                add_lot(p, rq[p], d + shelf[p])
                supply_due[p] = None
                fill_backorders(p)

        while ev_idx < E and ev_day[ev_idx] == d:
            kind = ev_kind[ev_idx]
            p = ev_prod[ev_idx]
            qty = ev_qty[ev_idx]
            if kind == 1:
                exp = ev_expiry[ev_idx]
                add_lot(p, qty, exp)
                fill_backorders(p)
            else:
                if backorders[p]:
                    backorders[p].append([qty, d])
                else:
                    taken = take_stock(p, qty)
                    if taken > 0:
                        shipped += taken
                        earned += taken * price[p]
                    remaining = qty - taken
                    if remaining > 0:
                        backorders[p].append([remaining, d])
            ev_idx += 1

        for p in range(P):
            while backorders[p] and backorders[p][0][1] <= d - 7:
                owed, placed = backorders[p].pop(0)
                cancelled += owed

        for p in range(P):
            if supply_due[p] is None:
                stock_units = sum(lot[0] for lot in lots[p])
                if stock_units <= rp[p]:
                    supply_due[p] = d + lead[p]
                    supplies += 1

    stock = [sum(lot[0] for lot in lots[p]) for p in range(P)]
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

    def find_entry(cache, set_idx, block):
        for i, entry in enumerate(cache[set_idx]):
            if entry[0] == block:
                return i
        return -1

    def handle_writeback(b):
        nonlocal mem_writes
        set2 = b % s2
        idx = find_entry(L2, set2, b)
        if idx != -1:
            entry = L2[set2].pop(idx)
            entry[1] = 1
            L2[set2].append(entry)
        else:
            if len(L2[set2]) == w2:
                evicted = L2[set2].pop(0)
                if evicted[1] == 1:
                    mem_writes += 1
            L2[set2].append([b, 1])

    for a, is_write in zip(addrs, writes):
        set1 = a % s1
        idx1 = find_entry(L1, set1, a)
        if idx1 != -1:
            l1_hits += 1
            entry = L1[set1].pop(idx1)
            if is_write:
                entry[1] = 1
            L1[set1].append(entry)
            continue

        l1_misses += 1
        set2 = a % s2
        idx2 = find_entry(L2, set2, a)
        if idx2 != -1:
            l2_hits += 1
            entry = L2[set2].pop(idx2)
            L2[set2].append(entry)
        else:
            l2_misses += 1
            mem_reads += 1
            if len(L2[set2]) == w2:
                evicted = L2[set2].pop(0)
                if evicted[1] == 1:
                    mem_writes += 1
            L2[set2].append([a, 0])

        if len(L1[set1]) == w1:
            evicted = L1[set1].pop(0)
            if evicted[1] == 1:
                handle_writeback(evicted[0])
        L1[set1].append([a, 1 if is_write else 0])

    dirty = 0
    for s in L1:
        for entry in s:
            if entry[1] == 1:
                dirty += 1
    for s in L2:
        for entry in s:
            if entry[1] == 1:
                dirty += 1

    l1_blocks = []
    for s in L1:
        for entry in s:
            l1_blocks.append(entry[0])

    return (l1_hits, l1_misses, l2_hits, l2_misses, mem_reads, mem_writes, dirty, l1_blocks)
```