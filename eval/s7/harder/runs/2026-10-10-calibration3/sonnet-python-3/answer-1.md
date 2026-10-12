### task: mini-cpu
```python
def main(ops, fa, fb, fc, regs, memory, inputs):
    n = len(ops)
    r = list(regs)
    mem = list(memory)
    flags = [False, False, False]
    ds = []
    cs = []
    inp = 0
    out = []
    pc = 0
    executed = 0
    status = None

    def wrap(x):
        return (x + 2 ** 31) % 2 ** 32 - 2 ** 31

    def setf(t):
        w = wrap(t)
        flags[0] = (w == 0)
        flags[1] = (w < 0)
        flags[2] = (w != t)
        return w

    while True:
        if executed == 300:
            status = 1
            break
        if pc < 0 or pc > n - 1:
            status = 2
            break
        op = ops[pc]
        a = fa[pc]
        b = fb[pc]
        c = fc[pc]
        npc = pc + 1
        if op == 0:
            executed += 1
            status = 0
            break
        elif op == 1:
            r[a] = b
        elif op == 2:
            r[a] = r[b]
        elif op == 3:
            r[a] = setf(r[b] + r[c])
        elif op == 4:
            r[a] = setf(r[b] - r[c])
        elif op == 5:
            r[a] = setf(r[b] * r[c])
        elif op == 6 or op == 7:
            if r[c] == 0:
                status = 3
                break
            x = r[b]
            y = r[c]
            q = abs(x) // abs(y)
            if (x < 0) != (y < 0):
                q = -q
            if op == 6:
                r[a] = setf(q)
            else:
                r[a] = setf(x - q * y)
        elif op == 8:
            r[a] = setf(-r[b])
        elif op == 9:
            r[a] = setf(r[b] * (1 << c))
        elif op == 10:
            r[a] = setf(r[b] >> c)
        elif op == 11:
            setf(r[b] - r[c])
        elif op == 12:
            addr = r[b] + c
            if addr < 0 or addr > 63:
                status = 6
                break
            r[a] = mem[addr]
        elif op == 13:
            addr = r[b] + c
            if addr < 0 or addr > 63:
                status = 6
                break
            mem[addr] = r[a]
        elif op == 14:
            npc = b
        elif op == 15:
            if flags[0]:
                npc = b
        elif op == 16:
            if not flags[0]:
                npc = b
        elif op == 17:
            if flags[1] != flags[2]:
                npc = b
        elif op == 18:
            if flags[1] == flags[2]:
                npc = b
        elif op == 19:
            if len(ds) >= 16:
                status = 4
                break
            ds.append(r[a])
        elif op == 20:
            if not ds:
                status = 5
                break
            r[a] = ds.pop()
        elif op == 21:
            if len(cs) >= 8:
                status = 4
                break
            cs.append(pc + 1)
            npc = b
        elif op == 22:
            if not cs:
                status = 5
                break
            npc = cs.pop()
        elif op == 23:
            if inp >= len(inputs):
                status = 7
                break
            r[a] = inputs[inp]
            inp += 1
        elif op == 24:
            out.append(r[a])
        executed += 1
        pc = npc
    return (out, status, executed, pc, r, mem, [flags[0], flags[1], flags[2]])
```

### task: stacker
```python
def main(width, height, queue, moves):
    P = {
        0: [[(0, 2), (1, 2), (2, 2), (3, 2)], [(2, 0), (2, 1), (2, 2), (2, 3)],
            [(0, 1), (1, 1), (2, 1), (3, 1)], [(1, 0), (1, 1), (1, 2), (1, 3)]],
        1: [[(1, 1), (2, 1), (1, 2), (2, 2)]] * 4,
        2: [[(0, 2), (1, 2), (2, 2), (1, 3)], [(1, 1), (1, 2), (1, 3), (2, 2)],
            [(0, 2), (1, 2), (2, 2), (1, 1)], [(1, 1), (1, 2), (1, 3), (0, 2)]],
        3: [[(0, 2), (1, 2), (1, 3), (2, 3)], [(1, 3), (1, 2), (2, 2), (2, 1)],
            [(0, 1), (1, 1), (1, 2), (2, 2)], [(0, 3), (0, 2), (1, 2), (1, 1)]],
        4: [[(0, 3), (1, 3), (1, 2), (2, 2)], [(2, 3), (2, 2), (1, 2), (1, 1)],
            [(0, 2), (1, 2), (1, 1), (2, 1)], [(1, 3), (1, 2), (0, 2), (0, 1)]],
        5: [[(0, 2), (1, 2), (2, 2), (2, 3)], [(1, 3), (1, 2), (1, 1), (2, 1)],
            [(0, 1), (0, 2), (1, 2), (2, 2)], [(0, 3), (1, 3), (1, 2), (1, 1)]],
        6: [[(0, 3), (0, 2), (1, 2), (2, 2)], [(1, 1), (1, 2), (1, 3), (2, 3)],
            [(0, 2), (1, 2), (2, 2), (2, 1)], [(0, 1), (1, 1), (1, 2), (1, 3)]],
    }
    grid = [[False] * width for _ in range(height)]

    def fits(kind, rot, x, y):
        for dx, dy in P[kind][rot]:
            X = x + dx
            Y = y + dy
            if X < 0 or X >= width or Y < 0 or Y >= height:
                return False
            if grid[Y][X]:
                return False
        return True

    sx = (width - 4) // 2
    sy = height - 4
    qi = 0
    mi = 0
    cur = None
    held = -1
    canhold = False
    score = 0
    total_rows = 0
    locks = 0
    combo = 0
    last_k = 0
    status = None

    while True:
        if cur is None:
            if qi >= len(queue):
                status = 0
                break
            k = queue[qi]
            qi += 1
            cur = [k, 0, sx, sy]
            canhold = True
            if not fits(k, 0, sx, sy):
                status = 2
                break
        if mi >= len(moves):
            status = 1
            break
        cmd = moves[mi]
        mi += 1
        kind, rot, x, y = cur
        if cmd == 1:
            if fits(kind, rot, x - 1, y):
                cur[2] = x - 1
        elif cmd == 2:
            if fits(kind, rot, x + 1, y):
                cur[2] = x + 1
        elif cmd == 5:
            if fits(kind, rot, x, y - 1):
                cur[3] = y - 1
        elif cmd == 3 or cmd == 4:
            nr = (rot + 1) % 4 if cmd == 3 else (rot + 3) % 4
            for ox, oy in ((0, 0), (-1, 0), (1, 0), (0, 1), (-2, 0), (2, 0)):
                if fits(kind, nr, x + ox, y + oy):
                    cur[1] = nr
                    cur[2] = x + ox
                    cur[3] = y + oy
                    break
        elif cmd == 6:
            if canhold:
                if held == -1:
                    held = kind
                    if qi >= len(queue):
                        status = 0
                        break
                    nk = queue[qi]
                    qi += 1
                else:
                    nk = held
                    held = kind
                cur = [nk, 0, sx, sy]
                canhold = False
                if not fits(nk, 0, sx, sy):
                    status = 2
                    break
        elif cmd == 0:
            while fits(kind, rot, x, y - 1):
                y -= 1
            for dx, dy in P[kind][rot]:
                grid[y + dy][x + dx] = True
            cur = None
            locks += 1
            newgrid = [row for row in grid if not all(row)]
            k = height - len(newgrid)
            while len(newgrid) < height:
                newgrid.append([False] * width)
            grid = newgrid
            if k > 0:
                base = {1: 100, 2: 300, 3: 500, 4: 800}[k]
                if k == 4 and last_k == 4:
                    base = 1200
                level = 1 + total_rows // 10
                score += (base + 50 * combo) * level
                combo += 1
                last_k = k
                total_rows += k
            else:
                combo = 0

    heights = []
    for cx in range(width):
        h = 0
        for ry in range(height):
            if grid[ry][cx]:
                h = ry + 1
        heights.append(h)
    return (heights, score, total_rows, locks, status, held)
```

### task: bank-days
```python
def main(year, month, day, days, balances, limits, credit_ppm, debit_ppm,
         tx_day, tx_kind, tx_acct, tx_other, tx_amount,
         so_dom, so_from, so_to, so_amount):
    n = len(balances)
    bal = list(balances)
    lim = list(limits)
    acc = [0] * n
    over = [False] * n
    ns = len(so_dom)
    cancelled = [False] * ns
    fails = [0] * ns
    rejected = 0
    added = 0
    taken = 0
    fees = 0

    def dim(y, m):
        if m == 2:
            leap = (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)
            return 29 if leap else 28
        if m in (4, 6, 9, 11):
            return 30
        return 31

    def attempt(a, b, amt, transfer):
        if transfer and a == b:
            return False
        if bal[a] - amt < -lim[a]:
            return False
        bal[a] -= amt
        if transfer:
            bal[b] += amt
        return True

    y, m, d = year, month, day
    for dayno in range(days):
        dm = dim(y, m)
        for k in range(len(tx_day)):
            if tx_day[k] != dayno:
                continue
            kind = tx_kind[k]
            a = tx_acct[k]
            amt = tx_amount[k]
            if kind == 1:
                bal[a] += amt
            elif kind == 2:
                if not attempt(a, a, amt, False):
                    rejected += 1
            else:
                if not attempt(a, tx_other[k], amt, True):
                    rejected += 1
        for k in range(ns):
            if cancelled[k]:
                continue
            if d != min(so_dom[k], dm):
                continue
            if attempt(so_from[k], so_to[k], so_amount[k], True):
                fails[k] = 0
            else:
                rejected += 1
                fails[k] += 1
                if fails[k] >= 2:
                    cancelled[k] = True
        for i in range(n):
            if bal[i] > 0:
                acc[i] += bal[i] * credit_ppm
            elif bal[i] < 0:
                acc[i] += bal[i] * debit_ppm
                over[i] = True
        if d == dm:
            for i in range(n):
                s = acc[i]
                if s >= 0:
                    v = s // 1000000
                    bal[i] += v
                    added += v
                else:
                    v = (-s) // 1000000
                    bal[i] -= v
                    taken += v
                acc[i] = 0
            for i in range(n):
                if over[i]:
                    bal[i] -= 1000
                    fees += 1000
                    over[i] = False
            d = 1
            m += 1
            if m > 12:
                m = 1
                y += 1
        else:
            d += 1
    return (bal, rejected, cancelled, added, taken, fees)
```

### task: formula-sheet
```python
def main(lens, kinds, xs, ys, zs, edit_cells, edit_lens, e_kinds, e_xs, e_ys, e_zs):
    n = len(lens)
    LIM = 1000000000
    formulas = []
    pos = 0
    for L in lens:
        formulas.append([(kinds[t], xs[t], ys[t], zs[t]) for t in range(pos, pos + L)])
        pos += L

    def refs(tokens):
        s = set()
        for k, x, y, z in tokens:
            if k == 1:
                if 0 <= x <= n - 1:
                    s.add(x)
            elif k == 3:
                if 0 <= y <= z <= n - 1:
                    for j in range(y, z + 1):
                        s.add(j)
        return s

    def evaluate_tokens(tokens, vals):
        stack = []
        for k, x, y, z in tokens:
            if k == 0:
                stack.append(x)
            elif k == 1:
                if 0 <= x <= n - 1:
                    stack.append(vals[x])
                else:
                    stack.append(None)
            elif k == 2:
                arity = 1 if x == 8 else (3 if x == 7 else 2)
                if len(stack) < arity:
                    return None
                args = stack[len(stack) - arity:]
                del stack[len(stack) - arity:]
                if x == 7:
                    c, a, b = args
                    if c is None:
                        r = None
                    else:
                        r = a if c != 0 else b
                elif x == 8:
                    a = args[0]
                    r = None if a is None else -a
                else:
                    a, b = args
                    if a is None or b is None:
                        r = None
                    elif x == 1:
                        r = a + b
                    elif x == 2:
                        r = a - b
                    elif x == 3:
                        r = a * b
                    elif x == 4:
                        if b == 0:
                            r = None
                        else:
                            r = abs(a) // abs(b)
                            if (a < 0) != (b < 0):
                                r = -r
                    elif x == 5:
                        r = 1 if a < b else 0
                    else:
                        r = 1 if a == b else 0
                if r is not None and abs(r) > LIM:
                    r = None
                stack.append(r)
            elif k == 3:
                if not (0 <= y <= z <= n - 1):
                    stack.append(None)
                else:
                    cells = [vals[i] for i in range(y, z + 1)]
                    if x == 4:
                        r = sum(1 for v in cells if v is not None)
                    elif any(v is None for v in cells):
                        r = None
                    elif x == 1:
                        r = sum(cells)
                    elif x == 2:
                        r = min(cells)
                    else:
                        r = max(cells)
                    if r is not None and abs(r) > LIM:
                        r = None
                    stack.append(r)
        if len(stack) != 1:
            return None
        return stack[0]

    def evaluate_sheet(fs):
        rs = [refs(f) for f in fs]
        reach = [[False] * n for _ in range(n)]
        for i in range(n):
            for j in rs[i]:
                reach[i][j] = True
        for kk in range(n):
            for i in range(n):
                if reach[i][kk]:
                    for j in range(n):
                        if reach[kk][j]:
                            reach[i][j] = True
        in_cycle = [reach[i][i] for i in range(n)]
        bad = [in_cycle[i] or any(reach[i][j] and in_cycle[j] for j in range(n))
               for i in range(n)]
        vals = [None] * n
        done = list(bad)

        def compute(i):
            if done[i]:
                return
            done[i] = True
            for j in rs[i]:
                compute(j)
            vals[i] = evaluate_tokens(fs[i], vals)

        for i in range(n):
            compute(i)
        return vals

    prev = evaluate_sheet(formulas)
    changed = []
    epos = 0
    for e in range(len(edit_cells)):
        L = edit_lens[e]
        formulas[edit_cells[e]] = [
            (e_kinds[t], e_xs[t], e_ys[t], e_zs[t]) for t in range(epos, epos + L)
        ]
        epos += L
        cur = evaluate_sheet(formulas)
        changed.append(sum(1 for i in range(n) if cur[i] != prev[i]))
        prev = cur
    values = [0 if v is None else v for v in prev]
    errors = [v is None for v in prev]
    return (values, errors, changed)
```

### task: blackjack
```python
def main(shoe, bankrolls, bets, rounds):
    bank = list(bankrolls)
    np_ = len(bank)
    ptr = 0
    played = 0
    busts = 0
    nats = 0

    class Out(Exception):
        pass

    def cval(c):
        return 10 if c >= 10 else c

    def total(cards):
        s = sum(cval(c) for c in cards)
        if 1 in cards and s + 10 <= 21:
            return s + 10, True
        return s, False

    for _ in range(rounds):
        part = [i for i in range(np_) if bank[i] >= bets[i]]
        if not part:
            break
        pos = [ptr]

        def draw():
            if pos[0] >= len(shoe):
                raise Out()
            c = shoe[pos[0]]
            pos[0] += 1
            return c

        try:
            cards = {}
            for i in part:
                cards[i] = [draw()]
            up = draw()
            for i in part:
                cards[i].append(draw())
            dealer = [up, draw()]

            delta = [0] * np_
            round_nats = 0
            round_bust = 0
            naturals = set()
            for i in part:
                if len(cards[i]) == 2 and total(cards[i])[0] == 21:
                    naturals.add(i)
            round_nats = len(naturals)
            dealer_nat = (up == 1 or up >= 10) and total(dealer)[0] == 21
            if dealer_nat:
                for i in part:
                    if i not in naturals:
                        delta[i] -= bets[i]
            else:
                for i in naturals:
                    delta[i] += (3 * bets[i]) // 2
                phands = {}
                for i in part:
                    if i in naturals:
                        continue
                    bet = bets[i]
                    c = cards[i]
                    hands = None
                    split = False
                    if c[0] == c[1] and c[0] in (1, 8) and bank[i] >= 2 * bet:
                        split = True
                        h1 = [[c[0]], bet]
                        h2 = [[c[1]], bet]
                        h1[0].append(draw())
                        h2[0].append(draw())
                        hands = [h1, h2]
                    else:
                        hands = [[c, bet]]
                    phands[i] = hands
                    if split and c[0] == 1:
                        continue
                    for h in hands:
                        hc = h[0]
                        t, soft = total(hc)
                        if len(hc) == 2 and (not soft) and t in (10, 11) and 2 <= up <= 9:
                            staked = sum(x[1] for x in hands)
                            if bank[i] >= staked + bet:
                                h[1] *= 2
                                hc.append(draw())
                                continue
                        while True:
                            t, soft = total(hc)
                            if t > 21:
                                break
                            if soft:
                                want = t <= 17
                            else:
                                want = t <= 11 or (12 <= t <= 16 and (up == 1 or up >= 7))
                            if not want:
                                break
                            hc.append(draw())
                live = False
                for i in phands:
                    for h in phands[i]:
                        if total(h[0])[0] <= 21:
                            live = True
                if live:
                    while total(dealer)[0] < 17:
                        dealer.append(draw())
                dt = total(dealer)[0]
                if dt > 21:
                    round_bust = 1
                for i in phands:
                    for h in phands[i]:
                        t = total(h[0])[0]
                        stake = h[1]
                        if t > 21:
                            delta[i] -= stake
                        elif dt > 21 or dt < t:
                            delta[i] += stake
                        elif dt > t:
                            delta[i] -= stake
        except Out:
            break
        ptr = pos[0]
        for i in range(np_):
            bank[i] += delta[i]
        played += 1
        busts += round_bust
        nats += round_nats
    return (bank, played, busts, nats)
```
