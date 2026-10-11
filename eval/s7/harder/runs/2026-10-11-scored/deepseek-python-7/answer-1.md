### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    w = width
    h = height
    walls = [c == 1 for c in cells]
    goals = [c == 2 for c in cells]
    boxes = boxes[:]
    history = []
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    read = 0

    def is_goal(cell):
        return goals[cell]

    def solved():
        return all(is_goal(b) for b in boxes)

    delta = [-w, 1, w, -1]
    opp = [2, 3, 0, 1]

    idx = 0
    while idx < len(moves):
        if solved():
            break
        mv = moves[idx]
        read += 1
        idx += 1

        if mv == 4:
            if history:
                d, is_push, box_idx = history.pop()
                player += delta[opp[d]]
                if is_push:
                    boxes[box_idx] += delta[opp[d]]
                undos += 1
        else:
            d = mv
            t = player + delta[d]
            if walls[t]:
                blocked += 1
            else:
                box_idx = -1
                for i, b in enumerate(boxes):
                    if b == t:
                        box_idx = i
                        break
                if box_idx != -1:
                    u = t + delta[d]
                    if walls[u] or u in boxes:
                        blocked += 1
                    else:
                        boxes[box_idx] = u
                        player = t
                        history.append((d, True, box_idx))
                        pushes += 1
                        if not is_goal(u):
                            above = u - w
                            below = u + w
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
    DIRS = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def sq(r, c):
        if r < 0 or r > 7 or c < 0 or c > 7:
            return -1
        if r % 2 == 0:
            if c % 2 == 0:
                return -1
        else:
            if c % 2 == 1:
                return -1
        k = (c - (1 if r % 2 == 0 else 0)) // 2
        return r * 4 + k

    step_info = [[-1] * 4 for _ in range(32)]
    jump_info = [[(-1, -1)] * 4 for _ in range(32)]
    for i in range(32):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        for d, (dr, dc) in enumerate(DIRS):
            nr, nc = r + dr, c + dc
            mid = sq(nr, nc)
            step_info[i][d] = mid
            if mid != -1:
                nr2, nc2 = nr + dr, nc + dc
                dest = sq(nr2, nc2)
                jump_info[i][d] = (mid, dest)
            else:
                jump_info[i][d] = (-1, -1)

    def is_side(val, side):
        if side == 0:
            return val in (1, 2)
        return val in (3, 4)

    def is_opponent(val, side):
        if side == 0:
            return val in (3, 4)
        return val in (1, 2)

    def is_man(piece):
        return piece in (1, 3)

    def far_row(side):
        return 0 if side == 0 else 7

    def can_move_dir(piece, d):
        dr = DIRS[d][0]
        if piece == 1:
            return dr == -1
        if piece == 3:
            return dr == 1
        return True

    def gen_captures(start, side, board):
        b = board[:]
        piece = b[start]
        b[start] = 0
        memo = {}

        def dfs(cur):
            key = (cur, tuple(b))
            if key in memo:
                return memo[key]
            results = []
            moved = False
            for d in range(4):
                if not can_move_dir(piece, d):
                    continue
                mid, dest = jump_info[cur][d]
                if mid == -1 or dest == -1:
                    continue
                if is_opponent(b[mid], side) and b[dest] == 0:
                    moved = True
                    mid_val = b[mid]
                    b[mid] = 0
                    if is_man(piece) and (dest // 4) == far_row(side):
                        results.append((1, [dest], [(mid, dest)]))
                    else:
                        sub = dfs(dest)
                        for add_count, add_landings, add_jumps in sub:
                            results.append((1 + add_count, [dest] + add_landings, [(mid, dest)] + add_jumps))
                    b[mid] = mid_val
            if not moved:
                results = [(0, [], [])]
            memo[key] = results
            return results

        sub = dfs(start)
        caps = []
        for count, landings, jumps in sub:
            if count > 0:
                caps.append({
                    'start': start,
                    'count': count,
                    'landings': landings,
                    'jumps': jumps
                })
        return caps

    board = board[:]
    played = 0
    white_took = 0
    black_took = 0
    crowned = 0
    result = 0

    while True:
        captures = []
        for i in range(32):
            if is_side(board[i], turn):
                captures.extend(gen_captures(i, turn, board))

        steps = []
        if not captures:
            for i in range(32):
                if is_side(board[i], turn):
                    piece = board[i]
                    for d in range(4):
                        if not can_move_dir(piece, d):
                            continue
                        dest = step_info[i][d]
                        if dest != -1 and board[dest] == 0:
                            steps.append((i, dest))

        if not captures and not steps:
            result = 2 if turn == 0 else 1
            break
        if played >= plies:
            result = 0
            break

        if captures:
            best = min(captures, key=lambda c: (-c['count'], c['start'], c['landings']))
            start = best['start']
            piece = board[start]
            board[start] = 0
            for mid, dest in best['jumps']:
                board[mid] = 0
            final_dest = best['jumps'][-1][1]
            if is_man(piece) and (final_dest // 4) == far_row(turn):
                board[final_dest] = 2 if turn == 0 else 4
                crowned += 1
            else:
                board[final_dest] = piece
            if turn == 0:
                white_took += best['count']
            else:
                black_took += best['count']
        else:
            start, dest = min(steps, key=lambda x: (x[0], x[1]))
            piece = board[start]
            board[start] = 0
            if is_man(piece) and (dest // 4) == far_row(turn):
                board[dest] = 2 if turn == 0 else 4
                crowned += 1
            else:
                board[dest] = piece

        played += 1
        turn = 1 - turn

    return (board, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    def parse_alt(tokens, i):
        sequences = []
        while True:
            seq, i = parse_seq(tokens, i)
            sequences.append(seq)
            if i < len(tokens) and tokens[i] == 30:
                i += 1
                continue
            break
        return ('alt', sequences), i

    def parse_seq(tokens, i):
        items = []
        while i < len(tokens) and can_start_atom(tokens[i]):
            item, i = parse_item(tokens, i)
            items.append(item)
        return items, i

    def can_start_atom(tok):
        return tok <= 26 or tok == 31

    def parse_item(tokens, i):
        atom, i = parse_atom(tokens, i)
        ops = []
        while i < len(tokens) and tokens[i] in (27, 28, 29):
            ops.append(tokens[i])
            i += 1
        return (atom, ops), i

    def parse_atom(tokens, i):
        if i >= len(tokens):
            raise ValueError
        tok = tokens[i]
        if tok <= 26:
            return ('char', tok), i + 1
        if tok == 31:
            i += 1
            alt, i = parse_alt(tokens, i)
            if i >= len(tokens) or tokens[i] != 32:
                raise ValueError
            return alt, i + 1
        raise ValueError

    valid = True
    ast = None
    try:
        ast, i = parse_alt(pattern, 0)
        if i != len(pattern):
            valid = False
    except ValueError:
        valid = False

    if not valid:
        n = len(lens)
        return ([False] * n, [-1] * n, 0, False)

    strings = []
    offset = 0
    for L in lens:
        strings.append(chars[offset:offset + L])
        offset += L

    full = []
    longest = []
    count = 0

    for s in strings:
        def match_alt(alt, pos):
            res = set()
            for seq in alt[1]:
                res |= match_seq(seq, pos)
            return res

        def match_seq(seq, pos):
            current = {pos}
            for item in seq:
                nxt = set()
                for p in current:
                    nxt |= match_item(item, p)
                current = nxt
                if not current:
                    break
            return current

        def match_item(item, pos):
            atom, ops = item

            def F_start(p):
                return match_atom(atom, p)

            F = F_start
            for op in ops:
                old = F
                if op == 29:
                    def F(p, old=old):
                        return {p} | old(p)
                elif op == 27:
                    def F(p, old=old):
                        seen = set()
                        stack = [p]
                        while stack:
                            x = stack.pop()
                            if x in seen:
                                continue
                            seen.add(x)
                            for y in old(x):
                                if y not in seen:
                                    stack.append(y)
                        return seen
                elif op == 28:
                    def F(p, old=old):
                        seen = set()
                        stack = list(old(p))
                        while stack:
                            x = stack.pop()
                            if x in seen:
                                continue
                            seen.add(x)
                            for y in old(x):
                                if y not in seen:
                                    stack.append(y)
                        return seen

            return F(pos)

        def match_atom(atom, pos):
            if atom[0] == 'char':
                code = atom[1]
                if pos < len(s):
                    if code == 26 or s[pos] == code:
                        return {pos + 1}
                return set()
            return match_alt(atom, pos)

        ends = match_alt(ast, 0)
        is_full = len(s) in ends
        if is_full:
            count += 1
        full.append(is_full)
        longest.append(max(ends) if ends else -1)

    return (full, longest, count, valid)
```

### task: swiss
```python
def main(ratings, rounds, results):
    n = len(ratings)
    scores = [0] * n
    whites = [0] * n
    last_black = [None] * n
    played = [[] for _ in range(n)]
    had_bye = [False] * n
    rematches = 0
    res_idx = 0

    for _ in range(rounds):
        ranked = sorted(range(n), key=lambda p: (-scores[p], -ratings[p], p))
        bye_player = None
        if n % 2 == 1:
            for p in reversed(ranked):
                if not had_bye[p]:
                    bye_player = p
                    break
            had_bye[bye_player] = True
            scores[bye_player] += 2

        unpaired = set(ranked)
        if bye_player is not None:
            unpaired.remove(bye_player)

        games = []
        for p1 in ranked:
            if p1 not in unpaired:
                continue
            unpaired.remove(p1)

            q_chosen = None
            for q in ranked:
                if q in unpaired and q not in played[p1]:
                    q_chosen = q
                    break
            if q_chosen is None:
                for q in ranked:
                    if q in unpaired:
                        q_chosen = q
                        break
                rematches += 1

            unpaired.remove(q_chosen)
            p2 = q_chosen

            if whites[p1] < whites[p2]:
                white, black = p1, p2
            elif whites[p2] < whites[p1]:
                white, black = p2, p1
            else:
                p1_black = (last_black[p1] is True)
                p2_black = (last_black[p2] is True)
                if p1_black != p2_black:
                    white = p1 if p1_black else p2
                    black = p2 if p1_black else p1
                else:
                    white, black = p1, p2

            games.append((white, black))

        for white, black in games:
            whites[white] += 1
            res = results[res_idx]
            res_idx += 1
            if res == 0:
                scores[white] += 2
            elif res == 1:
                scores[white] += 1
                scores[black] += 1
            elif res == 2:
                scores[black] += 2

            played[white].append(black)
            played[black].append(white)
            last_black[white] = False
            last_black[black] = True

    buchholz = [0] * n
    for p in range(n):
        buchholz[p] = sum(scores[opp] for opp in played[p])

    ranking = sorted(range(n), key=lambda p: (-scores[p], -buchholz[p], -ratings[p], p))
    return (scores, buchholz, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    stock = [0] * P
    backorders = [[] for _ in range(P)]
    pending_supplies = [[] for _ in range(P)]
    arrival_counter = 0

    earned = 0
    shipped = 0
    discarded = 0
    cancelled = 0
    supplies = 0

    def remove_units(p, qty):
        lots[p].sort(key=lambda x: (x[1], x[2]))
        i = 0
        while qty > 0 and i < len(lots[p]):
            lot = lots[p][i]
            if lot[0] <= qty:
                qty -= lot[0]
                stock[p] -= lot[0]
                lots[p].pop(i)
            else:
                lot[0] -= qty
                stock[p] -= qty
                qty = 0
                i += 1

    def fill_backorders(p):
        nonlocal earned, shipped
        while backorders[p] and stock[p] > 0:
            bo = backorders[p][0]
            take = min(bo[0], stock[p])
            if take > 0:
                remove_units(p, take)
                bo[0] -= take
                shipped += take
                earned += take * price[p]
            if bo[0] == 0:
                backorders[p].pop(0)

    def add_lot(p, qty, expiry):
        nonlocal arrival_counter
        if qty <= 0:
            return
        lots[p].append([qty, expiry, arrival_counter])
        arrival_counter += 1
        stock[p] += qty
        fill_backorders(p)

    event_ptr = 0
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
            new_due = []
            for due in pending_supplies[p]:
                if due == d:
                    add_lot(p, rq[p], d + shelf[p])
                else:
                    new_due.append(due)
            pending_supplies[p] = new_due

        while event_ptr < len(ev_day) and ev_day[event_ptr] == d:
            kind = ev_kind[event_ptr]
            p = ev_prod[event_ptr]
            qty = ev_qty[event_ptr]
            if kind == 1:
                expiry = ev_expiry[event_ptr]
                add_lot(p, qty, expiry)
            else:
                if backorders[p]:
                    backorders[p].append([qty, d])
                else:
                    take = min(qty, stock[p])
                    if take > 0:
                        remove_units(p, take)
                        shipped += take
                        earned += take * price[p]
                    rem = qty - take
                    if rem > 0:
                        backorders[p].append([rem, d])
            event_ptr += 1

        for p in range(P):
            new_bo = []
            for bo in backorders[p]:
                owed, placed = bo
                if placed <= d - 7:
                    cancelled += owed
                else:
                    new_bo.append(bo)
            backorders[p] = new_bo

        for p in range(P):
            if not pending_supplies[p] and stock[p] <= rp[p]:
                pending_supplies[p].append(d + lead[p])
                supplies += 1

    owed = sum(bo[0] for p in range(P) for bo in backorders[p])
    stock_list = [stock[p] for p in range(P)]
    return (stock_list, earned, shipped, discarded, cancelled, supplies, owed)
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

    def l1_find(s, b):
        for i, (blk, drt) in enumerate(L1[s]):
            if blk == b:
                return i
        return -1

    def l2_find(s, b):
        for i, (blk, drt) in enumerate(L2[s]):
            if blk == b:
                return i
        return -1

    def l1_use(s, idx):
        ent = L1[s].pop(idx)
        L1[s].append(ent)

    def l2_use(s, idx):
        ent = L2[s].pop(idx)
        L2[s].append(ent)

    def l2_put_clean(b):
        nonlocal mem_writes
        s = b % s2
        if len(L2[s]) >= w2:
            evict = L2[s].pop(0)
            if evict[1]:
                mem_writes += 1
        L2[s].append([b, False])

    def l2_put_dirty(b):
        nonlocal mem_writes
        s = b % s2
        if len(L2[s]) >= w2:
            evict = L2[s].pop(0)
            if evict[1]:
                mem_writes += 1
        L2[s].append([b, True])

    def l1_put(b, dirty):
        s = b % s1
        if len(L1[s]) >= w1:
            evict = L1[s].pop(0)
            if evict[1]:
                b2 = evict[0]
                s2idx = b2 % s2
                idx2 = l2_find(s2idx, b2)
                if idx2 != -1:
                    L2[s2idx][idx2][1] = True
                    l2_use(s2idx, idx2)
                else:
                    l2_put_dirty(b2)
        L1[s].append([b, dirty])

    for addr, is_write in zip(addrs, writes):
        s1idx = addr % s1
        idx1 = l1_find(s1idx, addr)
        if idx1 != -1:
            l1_hits += 1
            if is_write:
                L1[s1idx][idx1][1] = True
            l1_use(s1idx, idx1)
        else:
            l1_misses += 1
            s2idx = addr % s2
            idx2 = l2_find(s2idx, addr)
            if idx2 != -1:
                l2_hits += 1
                l2_use(s2idx, idx2)
            else:
                l2_misses += 1
                mem_reads += 1
                l2_put_clean(addr)
            l1_put(addr, is_write)

    dirty = 0
    for s in range(s1):
        for ent in L1[s]:
            if ent[1]:
                dirty += 1
    for s in range(s2):
        for ent in L2[s]:
            if ent[1]:
                dirty += 1

    l1_blocks = []
    for s in range(s1):
        for ent in L1[s]:
            l1_blocks.append(ent[0])

    return (l1_hits, l1_misses, l2_hits, l2_misses, mem_reads, mem_writes, dirty, l1_blocks)
```