### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    delta = [-width, 1, width, -1]
    boxes = boxes[:]
    history = []
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    read = 0

    def is_goal(cell):
        return cells[cell] == 2

    def all_on_goal():
        for b in boxes:
            if not is_goal(b):
                return False
        return True

    for m in moves:
        if all_on_goal():
            break
        read += 1
        if m == 4:
            if history:
                d, bi = history.pop()
                if bi >= 0:
                    boxes[bi] -= delta[d]
                player -= delta[d]
                undos += 1
            continue
        d = m
        t = player + delta[d]
        if cells[t] == 1:
            blocked += 1
            continue
        box_idx = -1
        for i, b in enumerate(boxes):
            if b == t:
                box_idx = i
                break
        if box_idx >= 0:
            u = t + delta[d]
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue
            boxes[box_idx] = u
            player = t
            pushes += 1
            history.append((d, box_idx))
            if not is_goal(u):
                above = u - width
                below = u + width
                left = u - 1
                right = u + 1
                vert_wall = (cells[above] == 1) or (cells[below] == 1)
                horiz_wall = (cells[left] == 1) or (cells[right] == 1)
                if vert_wall and horiz_wall:
                    dead += 1
        else:
            player = t
            history.append((d, -1))

    solved = all_on_goal()
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    dirs = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def to_index(r, c):
        if r < 0 or r >= 8 or c < 0 or c >= 8:
            return -1
        if (r + c) % 2 != 1:
            return -1
        if r % 2 == 0:
            if c % 2 != 1:
                return -1
            k = (c - 1) // 2
        else:
            if c % 2 != 0:
                return -1
            k = c // 2
        return r * 4 + k

    neighbor = [[-1] * 4 for _ in range(32)]
    for s in range(32):
        r = s // 4
        c = 2 * (s % 4) + (1 if r % 2 == 0 else 0)
        for di, (dr, dc) in enumerate(dirs):
            neighbor[s][di] = to_index(r + dr, c + dc)

    def dir_index(dr, dc):
        if dr == -1 and dc == -1: return 0
        if dr == -1 and dc == 1: return 1
        if dr == 1 and dc == -1: return 2
        if dr == 1 and dc == 1: return 3
        return -1

    def generate_captures(b, side):
        results = []
        for s in range(32):
            val = b[s]
            if side == 0:
                if val not in (1, 2): continue
            else:
                if val not in (3, 4): continue

            def explore(nb, cur, piece, captured, landings, jumps):
                found = False
                if piece == 1:
                    drs = [-1]
                elif piece == 3:
                    drs = [1]
                else:
                    drs = [-1, 1]
                for dr in drs:
                    for dc in [-1, 1]:
                        di = dir_index(dr, dc)
                        m = neighbor[cur][di]
                        if m == -1: continue
                        if side == 0:
                            if nb[m] not in (3, 4): continue
                        else:
                            if nb[m] not in (1, 2): continue
                        l = neighbor[m][di]
                        if l == -1: continue
                        if nb[l] != 0: continue
                        found = True
                        nnb = nb[:]
                        nnb[cur] = 0
                        nnb[m] = 0
                        new_piece = piece
                        promoted = False
                        if piece == 1 and l < 8:
                            new_piece = 2
                            promoted = True
                        elif piece == 3 and l >= 28:
                            new_piece = 4
                            promoted = True
                        nnb[l] = new_piece
                        new_landings = landings + [l]
                        new_jumps = jumps + [(cur, m, l, promoted)]
                        if promoted:
                            results.append((captured + 1, s, new_landings, new_jumps, nnb, True))
                        else:
                            explore(nnb, l, new_piece, captured + 1, new_landings, new_jumps)
                if not found and captured > 0:
                    results.append((captured, s, landings, jumps, nb, False))

            explore(b, s, val, 0, [], [])
        return results

    def generate_steps(b, side):
        steps = []
        for s in range(32):
            val = b[s]
            if side == 0:
                if val not in (1, 2): continue
            else:
                if val not in (3, 4): continue
            if val == 1:
                drs = [-1]
            elif val == 3:
                drs = [1]
            else:
                drs = [-1, 1]
            for dr in drs:
                for dc in [-1, 1]:
                    di = dir_index(dr, dc)
                    t = neighbor[s][di]
                    if t != -1 and b[t] == 0:
                        steps.append((s, t))
        return steps

    board = board[:]
    played = 0
    white_took = 0
    black_took = 0
    crowned = 0
    result = 0

    while True:
        captures = generate_captures(board, turn)
        if captures:
            if played >= plies:
                result = 0
                break
            max_cap = max(c[0] for c in captures)
            cand = [c for c in captures if c[0] == max_cap]
            chosen = min(cand, key=lambda c: (c[1], c[2]))
            captured, start, landings, jumps, new_board, promoted = chosen
            board = new_board[:]
            if turn == 0:
                white_took += captured
            else:
                black_took += captured
            if promoted:
                crowned += 1
            played += 1
            turn = 1 - turn
        else:
            steps = generate_steps(board, turn)
            if not steps:
                result = 2 if turn == 0 else 1
                break
            if played >= plies:
                result = 0
                break
            chosen = min(steps, key=lambda x: (x[0], x[1]))
            s, t = chosen
            val = board[s]
            board[s] = 0
            new_val = val
            if val == 1 and t < 8:
                new_val = 2
                crowned += 1
            elif val == 3 and t >= 28:
                new_val = 4
                crowned += 1
            board[t] = new_val
            played += 1
            turn = 1 - turn

    return (board, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    n_pat = len(pattern)
    i = 0

    def error():
        raise ValueError

    def parse_alt():
        nonlocal i
        seqs = [parse_seq()]
        while i < n_pat and pattern[i] == 30:
            i += 1
            seqs.append(parse_seq())
        return ('alt', seqs)

    def parse_seq():
        nonlocal i
        items = []
        while i < n_pat and pattern[i] not in (30, 32):
            items.append(parse_item())
        return ('seq', items)

    def parse_item():
        nonlocal i
        atom = parse_atom()
        ops = []
        while i < n_pat and pattern[i] in (27, 28, 29):
            ops.append(pattern[i])
            i += 1
        return ('item', atom, ops)

    def parse_atom():
        nonlocal i
        if i >= n_pat:
            error()
        t = pattern[i]
        if 0 <= t <= 25:
            i += 1
            return ('char', t)
        elif t == 26:
            i += 1
            return ('dot',)
        elif t == 31:
            i += 1
            alt = parse_alt()
            if i >= n_pat or pattern[i] != 32:
                error()
            i += 1
            return alt
        else:
            error()

    valid = True
    try:
        ast = parse_alt()
        if i != n_pat:
            valid = False
    except ValueError:
        valid = False

    if not valid:
        num_strings = len(lens)
        return ([False] * num_strings, [-1] * num_strings, 0, False)

    def build_matrix(node, s):
        n = len(s)
        if node[0] == 'alt':
            seqs = node[1]
            M = [[False] * (n + 1) for _ in range(n + 1)]
            for seq in seqs:
                ms = build_matrix(seq, s)
                for a in range(n + 1):
                    for b in range(n + 1):
                        if ms[a][b]:
                            M[a][b] = True
            return M
        elif node[0] == 'seq':
            items = node[1]
            M = [[False] * (n + 1) for _ in range(n + 1)]
            for a in range(n + 1):
                M[a][a] = True
            for item in items:
                mi = build_matrix(item, s)
                newM = [[False] * (n + 1) for _ in range(n + 1)]
                for a in range(n + 1):
                    for k in range(n + 1):
                        if M[a][k]:
                            for b in range(n + 1):
                                if mi[k][b]:
                                    newM[a][b] = True
                M = newM
            return M
        elif node[0] == 'item':
            atom, ops = node[1], node[2]
            M = build_matrix(atom, s)
            for op in ops:
                if op == 27:
                    R = [row[:] for row in M]
                    for a in range(n + 1):
                        R[a][a] = True
                    for k in range(n + 1):
                        for a in range(n + 1):
                            if R[a][k]:
                                for b in range(n + 1):
                                    if R[k][b]:
                                        R[a][b] = True
                    M = R
                elif op == 28:
                    R = [row[:] for row in M]
                    for a in range(n + 1):
                        R[a][a] = True
                    for k in range(n + 1):
                        for a in range(n + 1):
                            if R[a][k]:
                                for b in range(n + 1):
                                    if R[k][b]:
                                        R[a][b] = True
                    newM = [[False] * (n + 1) for _ in range(n + 1)]
                    for a in range(n + 1):
                        for k in range(n + 1):
                            if M[a][k]:
                                for b in range(n + 1):
                                    if R[k][b]:
                                        newM[a][b] = True
                    M = newM
                elif op == 29:
                    newM = [row[:] for row in M]
                    for a in range(n + 1):
                        newM[a][a] = True
                    M = newM
            return M
        elif node[0] == 'char':
            t = node[1]
            M = [[False] * (n + 1) for _ in range(n + 1)]
            for a in range(n):
                if s[a] == t:
                    M[a][a + 1] = True
            return M
        else:
            M = [[False] * (n + 1) for _ in range(n + 1)]
            for a in range(n):
                M[a][a + 1] = True
            return M

    strings = []
    pos = 0
    for L in lens:
        strings.append(chars[pos:pos + L])
        pos += L

    full_list = []
    longest_list = []
    count = 0
    for s in strings:
        M = build_matrix(ast, s)
        n = len(s)
        full = M[0][n]
        if full:
            count += 1
        longest = -1
        for L in range(n, -1, -1):
            if M[0][L]:
                longest = L
                break
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
    last_color = [-1] * N
    played = [[] for _ in range(N)]
    had_bye = [False] * N
    rematches = 0
    res_idx = 0

    for _ in range(rounds):
        ranking = sorted(range(N), key=lambda p: (-scores[p], -ratings[p], p))
        bye_player = None
        if N % 2 == 1:
            for p in reversed(ranking):
                if not had_bye[p]:
                    bye_player = p
                    break
            if bye_player is not None:
                scores[bye_player] += 2
                had_bye[bye_player] = True

        participants = [p for p in ranking if p != bye_player]
        paired = [False] * N
        pairs = []
        for p in participants:
            if paired[p]:
                continue
            q = None
            for cand in participants:
                if cand == p or paired[cand]:
                    continue
                if cand not in played[p]:
                    q = cand
                    break
            if q is None:
                for cand in participants:
                    if cand != p and not paired[cand]:
                        q = cand
                        break
            pairs.append((p, q))
            paired[p] = True
            paired[q] = True
            if q in played[p]:
                rematches += 1

        for p, q in pairs:
            played[p].append(q)
            played[q].append(p)

        for p, q in pairs:
            res = results[res_idx]
            res_idx += 1
            if whites[p] < whites[q]:
                white, black = p, q
            elif whites[p] > whites[q]:
                white, black = q, p
            else:
                if last_color[p] == 1 and last_color[q] != 1:
                    white, black = p, q
                elif last_color[p] != 1 and last_color[q] == 1:
                    white, black = q, p
                else:
                    white, black = p, q
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

    buchholz = [0] * N
    for p in range(N):
        total = 0
        for opp in played[p]:
            total += scores[opp]
        buchholz[p] = total

    final_ranking = sorted(range(N), key=lambda p: (-scores[p], -buchholz[p], -ratings[p], p))

    return (scores, buchholz, final_ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    stock = [0] * P
    backorders = [[] for _ in range(P)]
    on_way = [False] * P
    due_day = [0] * P
    supplies = 0
    earned = 0
    shipped = 0
    discarded = 0
    cancelled = 0
    arrival_id = 0

    def take_units(p, q):
        taken = 0
        while q > 0 and lots[p]:
            best_idx = 0
            best_key = (lots[p][0][1], lots[p][0][2])
            for idx, lot in enumerate(lots[p]):
                key = (lot[1], lot[2])
                if key < best_key:
                    best_key = key
                    best_idx = idx
            lot = lots[p][best_idx]
            if lot[0] <= q:
                taken += lot[0]
                q -= lot[0]
                stock[p] -= lot[0]
                lots[p].pop(best_idx)
            else:
                lot[0] -= q
                stock[p] -= q
                taken += q
                q = 0
        return taken

    def fill_backorders(p):
        nonlocal shipped, earned
        while backorders[p] and stock[p] > 0:
            bo = backorders[p][0]
            take = min(bo[0], stock[p])
            if take == 0:
                break
            removed = take_units(p, take)
            bo[0] -= removed
            shipped += removed
            earned += removed * price[p]
            if bo[0] == 0:
                backorders[p].pop(0)

    def add_lot(p, qty, expiry):
        nonlocal arrival_id
        lots[p].append([qty, expiry, arrival_id])
        arrival_id += 1
        stock[p] += qty
        fill_backorders(p)

    event_idx = 0
    for d in range(days):
        for p in range(P):
            new_lots = []
            for lot in lots[p]:
                if lot[1] < d:
                    discarded += lot[0]
                    stock[p] -= lot[0]
                else:
                    new_lots.append(lot)
            lots[p] = new_lots

        for p in range(P):
            if on_way[p] and due_day[p] == d:
                add_lot(p, rq[p], d + shelf[p])
                on_way[p] = False

        while event_idx < len(ev_day) and ev_day[event_idx] == d:
            p = ev_prod[event_idx]
            qty = ev_qty[event_idx]
            kind = ev_kind[event_idx]
            if kind == 1:
                expiry = ev_expiry[event_idx]
                add_lot(p, qty, expiry)
            else:
                if backorders[p]:
                    backorders[p].append([qty, d])
                else:
                    take = min(stock[p], qty)
                    if take > 0:
                        removed = take_units(p, take)
                        shipped += removed
                        earned += removed * price[p]
                    remaining = qty - take
                    if remaining > 0:
                        backorders[p].append([remaining, d])
            event_idx += 1

        for p in range(P):
            while backorders[p] and backorders[p][0][1] <= d - 7:
                bo = backorders[p].pop(0)
                cancelled += bo[0]

        for p in range(P):
            if not on_way[p] and stock[p] <= rp[p]:
                supplies += 1
                on_way[p] = True
                due_day[p] = d + lead[p]

    final_stock = [sum(lot[0] for lot in lots[p]) for p in range(P)]
    owed = sum(sum(bo[0] for bo in backorders[p]) for p in range(P))

    return (final_stock, earned, shipped, discarded, cancelled, supplies, owed)
```