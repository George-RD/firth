### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    n = width * height
    delta = [-width, 1, width, -1]
    history = []
    pushes = 0
    blocked = 0
    undos = 0
    dead = 0
    read = 0

    def is_goal(cell):
        return cells[cell] == 2

    def all_solved():
        return all(is_goal(b) for b in boxes)

    def box_at(cell):
        for i, b in enumerate(boxes):
            if b == cell:
                return i
        return -1

    def is_wall(cell):
        if cell < 0 or cell >= n:
            return True
        return cells[cell] == 1

    for d in moves:
        if all_solved():
            break
        read += 1
        if d == 4:
            if history:
                undos += 1
                hd, is_push, bi = history.pop()
                player -= delta[hd]
                if is_push:
                    boxes[bi] -= delta[hd]
            continue

        t = player + delta[d]
        if is_wall(t):
            blocked += 1
            continue

        bi = box_at(t)
        if bi != -1:
            u = t + delta[d]
            if is_wall(u) or box_at(u) != -1:
                blocked += 1
                continue
            boxes[bi] = u
            player = t
            history.append((d, True, bi))
            pushes += 1
            if cells[u] != 2:
                above = u - width
                below = u + width
                left = u - 1
                right = u + 1
                if (is_wall(above) or is_wall(below)) and (is_wall(left) or is_wall(right)):
                    dead += 1
        else:
            player = t
            history.append((d, False, -1))

    solved = all_solved()
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved)
```

### task: checkers
```python
def main(board, turn, plies):
    def sq_to_rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def rc_to_sq(r, c):
        if r < 0 or r >= 8 or c < 0 or c >= 8:
            return -1
        if (r + c) % 2 != 1:
            return -1
        return r * 4 + ((c - (1 if r % 2 == 0 else 0)) // 2)

    def is_white(p):
        return p == 1 or p == 2

    def is_black(p):
        return p == 3 or p == 4

    def allowed_dirs(p):
        if p == 1:
            return [(-1, -1), (-1, 1)]
        if p == 3:
            return [(1, -1), (1, 1)]
        return [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def gen_captures(bstate, start, pv):
        captures = []

        def dfs(cur, piece, b, count, lands, caps):
            r, c = sq_to_rc(cur)
            found = False
            for dr, dc in allowed_dirs(piece):
                nr, nc = r + dr, c + dc
                mid = rc_to_sq(nr, nc)
                if mid == -1:
                    continue
                mp = b[mid]
                if mp != 0 and ((is_white(piece) and is_black(mp)) or (is_black(piece) and is_white(mp))):
                    lr, lc = r + 2 * dr, c + 2 * dc
                    land = rc_to_sq(lr, lc)
                    if land == -1:
                        continue
                    if b[land] == 0:
                        found = True
                        nb = b[:]
                        nb[cur] = 0
                        nb[mid] = 0
                        nb[land] = piece
                        new_lands = lands + [land]
                        new_caps = caps + [mid]
                        new_count = count + 1
                        new_piece = piece
                        crowned = False
                        if piece == 1 and lr == 0:
                            new_piece = 2
                            crowned = True
                        elif piece == 3 and lr == 7:
                            new_piece = 4
                            crowned = True
                        if crowned:
                            captures.append((new_count, new_lands, land, new_piece, new_caps))
                        else:
                            dfs(land, new_piece, nb, new_count, new_lands, new_caps)
            if not found and count > 0:
                captures.append((count, lands, cur, piece, caps))

        dfs(start, pv, bstate, 0, [], [])
        return captures

    def get_all_captures(bstate, side):
        res = []
        for i in range(32):
            pv = bstate[i]
            if pv == 0:
                continue
            if side == 0 and not is_white(pv):
                continue
            if side == 1 and not is_black(pv):
                continue
            for cap in gen_captures(bstate, i, pv):
                res.append((i, cap))
        return res

    def choose_capture(caps):
        best = None
        for start, cap in caps:
            count, lands, final_pos, final_pv, caps_list = cap
            if best is None:
                best = (start, cap)
            else:
                bstart, bcap = best
                bcount, blands, _, _, _ = bcap
                if count > bcount:
                    best = (start, cap)
                elif count == bcount:
                    if start < bstart:
                        best = (start, cap)
                    elif start == bstart and lands < blands:
                        best = (start, cap)
        return best

    def get_steps(bstate, side):
        steps = []
        for i in range(32):
            pv = bstate[i]
            if pv == 0:
                continue
            if side == 0 and not is_white(pv):
                continue
            if side == 1 and not is_black(pv):
                continue
            r, c = sq_to_rc(i)
            for dr, dc in allowed_dirs(pv):
                nr, nc = r + dr, c + dc
                target = rc_to_sq(nr, nc)
                if target == -1:
                    continue
                if bstate[target] == 0:
                    new_pv = pv
                    crown = False
                    if pv == 1 and nr == 0:
                        new_pv = 2
                        crown = True
                    elif pv == 3 and nr == 7:
                        new_pv = 4
                        crown = True
                    steps.append((i, target, new_pv, crown))
        if not steps:
            return None
        steps.sort(key=lambda x: (x[0], x[1]))
        return steps[0]

    b = board[:]
    current = turn
    played = 0
    white_took = 0
    black_took = 0
    crowned = 0
    result = 0

    while True:
        side = current
        all_caps = get_all_captures(b, side)
        if all_caps:
            if played >= plies:
                result = 0
                break
            best = choose_capture(all_caps)
            start, (count, lands, final_pos, final_pv, caps_list) = best
            initial_pv = b[start]
            b[start] = 0
            for mid in caps_list:
                b[mid] = 0
            b[final_pos] = final_pv
            if side == 0:
                white_took += count
            else:
                black_took += count
            if initial_pv in (1, 3) and final_pv in (2, 4):
                crowned += 1
            played += 1
            current = 1 - current
        else:
            step = get_steps(b, side)
            if step is None:
                if side == 0:
                    result = 2
                else:
                    result = 1
                break
            if played >= plies:
                result = 0
                break
            start, target, new_pv, crown = step
            b[start] = 0
            b[target] = new_pv
            if crown:
                crowned += 1
            played += 1
            current = 1 - current

    return (b, played, white_took, black_took, crowned, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    class Char:
        def __init__(self, c):
            self.c = c

    class Any:
        pass

    class Seq:
        def __init__(self, items):
            self.items = items

    class Alt:
        def __init__(self, seqs):
            self.seqs = seqs

    class Star:
        def __init__(self, sub):
            self.sub = sub

    class Plus:
        def __init__(self, sub):
            self.sub = sub

    class Opt:
        def __init__(self, sub):
            self.sub = sub

    def parse(tokens):
        pos = 0

        def error():
            raise ValueError

        def parse_atom():
            nonlocal pos
            if pos >= len(tokens):
                error()
            t = tokens[pos]
            if t <= 25:
                pos += 1
                return Char(t)
            if t == 26:
                pos += 1
                return Any()
            if t == 31:
                pos += 1
                inner = parse_alt()
                if pos >= len(tokens) or tokens[pos] != 32:
                    error()
                pos += 1
                return inner
            error()

        def parse_item():
            nonlocal pos
            atom = parse_atom()
            while pos < len(tokens) and tokens[pos] in (27, 28, 29):
                op = tokens[pos]
                pos += 1
                if op == 27:
                    atom = Star(atom)
                elif op == 28:
                    atom = Plus(atom)
                else:
                    atom = Opt(atom)
            return atom

        def parse_seq():
            nonlocal pos
            items = []
            while pos < len(tokens) and (tokens[pos] <= 26 or tokens[pos] == 31):
                items.append(parse_item())
            if pos < len(tokens) and tokens[pos] in (27, 28, 29):
                error()
            return Seq(items)

        def parse_alt():
            nonlocal pos
            seqs = [parse_seq()]
            while pos < len(tokens) and tokens[pos] == 30:
                pos += 1
                seqs.append(parse_seq())
            return Alt(seqs)

        try:
            expr = parse_alt()
            if pos != len(tokens):
                raise ValueError
            return expr
        except ValueError:
            return None

    expr = parse(pattern)
    if expr is None:
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    def match_expr(expr, s, pos, memo):
        key = (id(expr), pos)
        if key in memo:
            return memo[key]
        result = set()
        if isinstance(expr, Char):
            if pos < len(s) and s[pos] == expr.c:
                result.add(pos + 1)
        elif isinstance(expr, Any):
            if pos < len(s):
                result.add(pos + 1)
        elif isinstance(expr, Alt):
            for seq in expr.seqs:
                result |= match_expr(seq, s, pos, memo)
        elif isinstance(expr, Seq):
            cur = {pos}
            for item in expr.items:
                nxt = set()
                for p in cur:
                    nxt |= match_expr(item, s, p, memo)
                cur = nxt
                if not cur:
                    break
            result = cur
        elif isinstance(expr, Star):
            seen = {pos}
            stack = [pos]
            while stack:
                p = stack.pop()
                for q in match_expr(expr.sub, s, p, memo):
                    if q not in seen:
                        seen.add(q)
                        stack.append(q)
            result = seen
        elif isinstance(expr, Plus):
            first = match_expr(expr.sub, s, pos, memo)
            if first:
                for q in first:
                    seen = {q}
                    stack = [q]
                    while stack:
                        p = stack.pop()
                        for r in match_expr(expr.sub, s, p, memo):
                            if r not in seen:
                                seen.add(r)
                                stack.append(r)
                    result |= seen
        elif isinstance(expr, Opt):
            result.add(pos)
            result |= match_expr(expr.sub, s, pos, memo)
        memo[key] = result
        return result

    full = []
    longest = []
    count = 0
    idx = 0
    for L in lens:
        s = chars[idx:idx + L]
        idx += L
        ends = match_expr(expr, s, 0, {})
        is_full = L in ends
        full.append(is_full)
        if is_full:
            count += 1
        longest.append(max(ends) if ends else -1)
    return (full, longest, count, True)
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
    bye_set = set()
    rematches = 0
    res_idx = 0

    for r in range(rounds):
        ranked = sorted(range(N), key=lambda p: (-scores[p], -ratings[p], p))
        available = ranked[:]

        if N % 2 == 1:
            bye = None
            for p in reversed(ranked):
                if p not in bye_set:
                    bye = p
                    break
            bye_set.add(bye)
            scores[bye] += 2
            available.remove(bye)

        while available:
            p = available.pop(0)
            q = None
            for cand in available:
                if cand not in played[p]:
                    q = cand
                    break
            if q is None:
                q = available[0]
            available.remove(q)

            if whites[p] < whites[q]:
                white = p
            elif whites[q] < whites[p]:
                white = q
            else:
                p_black = (last_color[p] == 1)
                q_black = (last_color[q] == 1)
                if p_black != q_black:
                    white = p if p_black else q
                else:
                    white = p
            black = q if white == p else p

            if q in played[p]:
                rematches += 1

            whites[white] += 1
            last_color[white] = 0
            last_color[black] = 1
            opponents[white].append(black)
            opponents[black].append(white)
            played[white].add(black)
            played[black].add(white)

            res = results[res_idx]
            res_idx += 1
            if res == 0:
                scores[white] += 2
            elif res == 1:
                scores[white] += 1
                scores[black] += 1
            else:
                scores[black] += 2

    buchholz = [0] * N
    for p in range(N):
        buchholz[p] = sum(scores[o] for o in opponents[p])

    ranking = sorted(range(N), key=lambda p: (-scores[p], -buchholz[p], -ratings[p], p))
    return (scores, buchholz, ranking, whites, rematches)
```

### task: warehouse
```python
def main(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]
    backorders = [[] for _ in range(P)]
    pending_due = [None] * P
    arrival_seq = 0
    earned = 0
    shipped_total = 0
    discarded = 0
    cancelled = 0
    supplies_ordered = 0
    E = len(ev_day)
    event_idx = 0

    def stock_units(p):
        return sum(lot[0] for lot in lots[p])

    def add_lot(p, qty, expiry):
        nonlocal arrival_seq
        lots[p].append([qty, expiry, arrival_seq])
        arrival_seq += 1

    def take_stock(p, qty):
        remaining = qty
        lots[p].sort(key=lambda x: (x[1], x[2]))
        i = 0
        while remaining > 0 and i < len(lots[p]):
            lot = lots[p][i]
            take = min(lot[0], remaining)
            lot[0] -= take
            remaining -= take
            if lot[0] == 0:
                lots[p].pop(i)
            else:
                i += 1
        return qty - remaining

    def fill_backorders(p):
        nonlocal earned, shipped_total
        while backorders[p] and stock_units(p) > 0:
            order = backorders[p][0]
            take = take_stock(p, order[0])
            if take > 0:
                order[0] -= take
                earned += take * price[p]
                shipped_total += take
            if order[0] == 0:
                backorders[p].pop(0)
            else:
                break

    for d in range(days):
        for p in range(P):
            new_lots = []
            for qty, exp, seq in lots[p]:
                if exp < d:
                    discarded += qty
                else:
                    new_lots.append([qty, exp, seq])
            lots[p] = new_lots

        for p in range(P):
            if pending_due[p] == d:
                add_lot(p, rq[p], d + shelf[p])
                fill_backorders(p)
                pending_due[p] = None

        while event_idx < E and ev_day[event_idx] == d:
            kind = ev_kind[event_idx]
            p = ev_prod[event_idx]
            qty = ev_qty[event_idx]
            if kind == 1:
                exp = ev_expiry[event_idx]
                add_lot(p, qty, exp)
                fill_backorders(p)
            else:
                if backorders[p]:
                    backorders[p].append([qty, d])
                else:
                    take = take_stock(p, qty)
                    if take > 0:
                        earned += take * price[p]
                        shipped_total += take
                    remaining = qty - take
                    if remaining > 0:
                        backorders[p].append([remaining, d])
            event_idx += 1

        for p in range(P):
            while backorders[p] and backorders[p][0][1] <= d - 7:
                order = backorders[p].pop(0)
                cancelled += order[0]

        for p in range(P):
            if pending_due[p] is None and stock_units(p) <= rp[p]:
                pending_due[p] = d + lead[p]
                supplies_ordered += 1

    stock = [stock_units(p) for p in range(P)]
    owed = sum(sum(order[0] for order in backorders[p]) for p in range(P))
    return (stock, earned, shipped_total, discarded, cancelled, supplies_ordered, owed)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    l1_hits = l1_misses = l2_hits = l2_misses = 0
    mem_reads = mem_writes = 0

    def find_in_set(entries, block):
        for idx, entry in enumerate(entries):
            if entry[0] == block:
                return idx
        return -1

    def l2_put(set_idx, block, dirty):
        nonlocal mem_writes
        entries = L2[set_idx]
        if len(entries) >= w2:
            evict_block, evict_dirty = entries.pop(0)
            if evict_dirty:
                mem_writes += 1
        entries.append([block, dirty])

    def l1_put(set_idx, block, dirty):
        entries = L1[set_idx]
        if len(entries) >= w1:
            evict_block, evict_dirty = entries.pop(0)
            if evict_dirty:
                s2_set = evict_block % s2
                idx = find_in_set(L2[s2_set], evict_block)
                if idx != -1:
                    entry = L2[s2_set].pop(idx)
                    entry[1] = True
                    L2[s2_set].append(entry)
                else:
                    l2_put(s2_set, evict_block, True)
        entries.append([block, dirty])

    def l1_use(set_idx, block, write):
        entries = L1[set_idx]
        idx = find_in_set(entries, block)
        if idx != -1:
            entry = entries.pop(idx)
            if write:
                entry[1] = True
            entries.append(entry)

    def l2_use(set_idx, block):
        entries = L2[set_idx]
        idx = find_in_set(entries, block)
        if idx != -1:
            entry = entries.pop(idx)
            entries.append(entry)

    for addr, write in zip(addrs, writes):
        set1 = addr % s1
        idx1 = find_in_set(L1[set1], addr)
        if idx1 != -1:
            l1_hits += 1
            l1_use(set1, addr, write)
        else:
            l1_misses += 1
            set2 = addr % s2
            idx2 = find_in_set(L2[set2], addr)
            if idx2 != -1:
                l2_hits += 1
                l2_use(set2, addr)
            else:
                l2_misses += 1
                mem_reads += 1
                l2_put(set2, addr, False)
            l1_put(set1, addr, write)

    dirty = 0
    for entries in L1:
        for entry in entries:
            if entry[1]:
                dirty += 1
    for entries in L2:
        for entry in entries:
            if entry[1]:
                dirty += 1

    l1_blocks = []
    for entries in L1:
        for entry in entries:
            l1_blocks.append(entry[0])

    return (l1_hits, l1_misses, l2_hits, l2_misses, mem_reads, mem_writes, dirty, l1_blocks)
```