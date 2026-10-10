### task: mini-cpu
```python
def main(ops, fa, fb, fc, regs, memory, inputs):
    def wrap(x):
        return (x + 2147483648) % 4294967296 - 2147483648

    n = len(ops)
    r = list(regs)
    mem = list(memory)
    flags = [False, False, False]
    ds = []
    cs = []
    inp = 0
    out = []
    pc = 0
    ex = 0
    status = 0

    def setf(t):
        w = wrap(t)
        flags[0] = (w == 0)
        flags[1] = (w < 0)
        flags[2] = (w != t)
        return w

    def tdiv(x, y):
        q = abs(x) // abs(y)
        if (x < 0) != (y < 0):
            q = -q
        return q

    while True:
        if ex >= 300:
            status = 1
            break
        if pc < 0 or pc >= n:
            status = 2
            break
        op = ops[pc]
        a = fa[pc]
        b = fb[pc]
        c = fc[pc]
        npc = pc + 1
        fault = 0
        if op == 0:
            ex += 1
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
        elif op == 6:
            if r[c] == 0:
                fault = 3
            else:
                r[a] = setf(tdiv(r[b], r[c]))
        elif op == 7:
            if r[c] == 0:
                fault = 3
            else:
                q = tdiv(r[b], r[c])
                r[a] = setf(r[b] - q * r[c])
        elif op == 8:
            r[a] = setf(-r[b])
        elif op == 9:
            r[a] = setf(r[b] * (2 ** c))
        elif op == 10:
            r[a] = setf(r[b] >> c)
        elif op == 11:
            setf(r[b] - r[c])
        elif op == 12:
            addr = r[b] + c
            if addr < 0 or addr > 63:
                fault = 6
            else:
                r[a] = mem[addr]
        elif op == 13:
            addr = r[b] + c
            if addr < 0 or addr > 63:
                fault = 6
            else:
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
                fault = 4
            else:
                ds.append(r[a])
        elif op == 20:
            if not ds:
                fault = 5
            else:
                r[a] = ds.pop()
        elif op == 21:
            if len(cs) >= 8:
                fault = 4
            else:
                cs.append(pc + 1)
                npc = b
        elif op == 22:
            if not cs:
                fault = 5
            else:
                npc = cs.pop()
        elif op == 23:
            if inp >= len(inputs):
                fault = 7
            else:
                r[a] = inputs[inp]
                inp += 1
        elif op == 24:
            out.append(r[a])
        if fault:
            status = fault
            break
        ex += 1
        pc = npc
    return (out, status, ex, pc, r, mem, [flags[0], flags[1], flags[2]])
```

### task: stacker
```python
def main(width, height, queue, moves):
    SHAPES = {
        0: [[(0,2),(1,2),(2,2),(3,2)], [(2,0),(2,1),(2,2),(2,3)],
            [(0,1),(1,1),(2,1),(3,1)], [(1,0),(1,1),(1,2),(1,3)]],
        1: [[(1,1),(2,1),(1,2),(2,2)]] * 4,
        2: [[(0,2),(1,2),(2,2),(1,3)], [(1,1),(1,2),(1,3),(2,2)],
            [(0,2),(1,2),(2,2),(1,1)], [(1,1),(1,2),(1,3),(0,2)]],
        3: [[(0,2),(1,2),(1,3),(2,3)], [(1,3),(1,2),(2,2),(2,1)],
            [(0,1),(1,1),(1,2),(2,2)], [(0,3),(0,2),(1,2),(1,1)]],
        4: [[(0,3),(1,3),(1,2),(2,2)], [(2,3),(2,2),(1,2),(1,1)],
            [(0,2),(1,2),(1,1),(2,1)], [(1,3),(1,2),(0,2),(0,1)]],
        5: [[(0,2),(1,2),(2,2),(2,3)], [(1,3),(1,2),(1,1),(2,1)],
            [(0,1),(0,2),(1,2),(2,2)], [(0,3),(1,3),(1,2),(1,1)]],
        6: [[(0,3),(0,2),(1,2),(2,2)], [(1,1),(1,2),(1,3),(2,3)],
            [(0,2),(1,2),(2,2),(2,1)], [(0,1),(1,1),(1,2),(1,3)]],
    }
    grid = [[False] * width for _ in range(height)]

    def fits(kind, rot, x, y):
        for dx, dy in SHAPES[kind][rot]:
            X = x + dx
            Y = y + dy
            if X < 0 or X >= width or Y < 0 or Y >= height:
                return False
            if grid[Y][X]:
                return False
        return True

    cur = None  # [kind, rot, x, y]
    held = -1
    may_hold = False
    qi = 0
    mi = 0
    score = 0
    rows = 0
    locks = 0
    run = 0
    last_nonzero = 0
    status = 0
    sx = (width - 4) // 2
    sy = height - 4

    while True:
        if cur is None:
            if qi >= len(queue):
                status = 0
                break
            kind = queue[qi]
            qi += 1
            cur = [kind, 0, sx, sy]
            may_hold = True
            if not fits(kind, 0, sx, sy):
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
            for ox, oy in ((0,0), (-1,0), (1,0), (0,1), (-2,0), (2,0)):
                if fits(kind, nr, x + ox, y + oy):
                    cur[1] = nr
                    cur[2] = x + ox
                    cur[3] = y + oy
                    break
        elif cmd == 6:
            if may_hold:
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
                may_hold = False
                if not fits(nk, 0, sx, sy):
                    status = 2
                    break
        elif cmd == 0:
            while fits(kind, rot, x, y - 1):
                y -= 1
            for dx, dy in SHAPES[kind][rot]:
                grid[y + dy][x + dx] = True
            cur = None
            locks += 1
            newgrid = [row for row in grid if not all(row)]
            k = height - len(newgrid)
            if k > 0:
                if k == 4 and last_nonzero == 4:
                    base = 1200
                else:
                    base = {1: 100, 2: 300, 3: 500, 4: 800}[k]
                level = 1 + rows // 10
                score += (base + 50 * run) * level
                run += 1
                rows += k
                last_nonzero = k
                for _ in range(k):
                    newgrid.append([False] * width)
                grid = newgrid
            else:
                run = 0

    heights = []
    for cx in range(width):
        h = 0
        for cy in range(height):
            if grid[cy][cx]:
                h = cy + 1
        heights.append(h)
    return (heights, score, rows, locks, status, held)
```

### task: bank-days
```python
def main(year, month, day, days, balances, limits, credit_ppm, debit_ppm,
         tx_day, tx_kind, tx_acct, tx_other, tx_amount,
         so_dom, so_from, so_to, so_amount):
    def leap(y):
        return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)

    def dim(y, m):
        if m == 2:
            return 29 if leap(y) else 28
        if m in (4, 6, 9, 11):
            return 30
        return 31

    n = len(balances)
    bal = list(balances)
    accrued = [0] * n
    overdrawn = [False] * n
    nso = len(so_dom)
    fails = [0] * nso
    cancelled = [False] * nso
    rejected = 0
    added = 0
    taken = 0
    fees = 0
    y, m, d = year, month, day

    for t in range(days):
        for k in range(len(tx_day)):
            if tx_day[k] != t:
                continue
            kind = tx_kind[k]
            a = tx_acct[k]
            amt = tx_amount[k]
            if kind == 1:
                bal[a] += amt
            elif kind == 2:
                if bal[a] - amt < -limits[a]:
                    rejected += 1
                else:
                    bal[a] -= amt
            else:
                b = tx_other[k]
                if a == b or bal[a] - amt < -limits[a]:
                    rejected += 1
                else:
                    bal[a] -= amt
                    bal[b] += amt
        last = dim(y, m)
        for k in range(nso):
            if cancelled[k]:
                continue
            due = min(so_dom[k], last)
            if d != due:
                continue
            a = so_from[k]
            b = so_to[k]
            amt = so_amount[k]
            if a == b or bal[a] - amt < -limits[a]:
                rejected += 1
                fails[k] += 1
                if fails[k] >= 2:
                    cancelled[k] = True
            else:
                bal[a] -= amt
                bal[b] += amt
                fails[k] = 0
        for i in range(n):
            if bal[i] > 0:
                accrued[i] += bal[i] * credit_ppm
            elif bal[i] < 0:
                accrued[i] += bal[i] * debit_ppm
                overdrawn[i] = True
        if d == last:
            for i in range(n):
                s = accrued[i]
                if s >= 0:
                    v = s // 1000000
                    bal[i] += v
                    added += v
                else:
                    v = (-s) // 1000000
                    bal[i] -= v
                    taken += v
                accrued[i] = 0
            for i in range(n):
                if overdrawn[i]:
                    bal[i] -= 1000
                    fees += 1000
                    overdrawn[i] = False
        # advance date
        d += 1
        if d > last:
            d = 1
            m += 1
            if m > 12:
                m = 1
                y += 1
    return (bal, rejected, cancelled, added, taken, fees)
```

### task: formula-sheet
```python
def main(lens, kinds, xs, ys, zs, edit_cells, edit_lens, e_kinds, e_xs, e_ys, e_zs):
    n = len(lens)
    LIM = 1000000000
    formulas = []
    pos = 0
    for i in range(n):
        L = lens[i]
        formulas.append([(kinds[t], xs[t], ys[t], zs[t]) for t in range(pos, pos + L)])
        pos += L

    def refs(f):
        s = set()
        for (k, x, y, z) in f:
            if k == 1:
                if 0 <= x <= n - 1:
                    s.add(x)
            elif k == 3:
                if 0 <= y <= z <= n - 1:
                    for c in range(y, z + 1):
                        s.add(c)
        return s

    def evaluate_all():
        reach = [[False] * n for _ in range(n)]
        for i in range(n):
            for j in refs(formulas[i]):
                reach[i][j] = True
        for k in range(n):
            for i in range(n):
                if reach[i][k]:
                    for j in range(n):
                        if reach[k][j]:
                            reach[i][j] = True
        incycle = [reach[i][i] for i in range(n)]
        bad = [incycle[i] or any(reach[i][j] and incycle[j] for j in range(n))
               for i in range(n)]
        vals = [None] * n
        done = [False] * n

        def calc(i):
            if done[i]:
                return vals[i]
            done[i] = True
            if bad[i]:
                vals[i] = None
                return None
            for j in refs(formulas[i]):
                calc(j)
            vals[i] = run(formulas[i], vals)
            return vals[i]

        def run(f, cv):
            st = []
            for (k, x, y, z) in f:
                if k == 0:
                    st.append(x)
                elif k == 1:
                    if 0 <= x <= n - 1:
                        st.append(cv[x])
                    else:
                        st.append(None)
                elif k == 2:
                    ar = 3 if x == 7 else (1 if x == 8 else 2)
                    if len(st) < ar:
                        return None
                    args = st[len(st) - ar:]
                    del st[len(st) - ar:]
                    if x == 7:
                        c, a, b = args
                        if c is None:
                            res = None
                        else:
                            res = a if c != 0 else b
                    elif x == 8:
                        a = args[0]
                        res = None if a is None else -a
                    else:
                        a, b = args
                        if a is None or b is None:
                            res = None
                        elif x == 1:
                            res = a + b
                        elif x == 2:
                            res = a - b
                        elif x == 3:
                            res = a * b
                        elif x == 4:
                            if b == 0:
                                res = None
                            else:
                                q = abs(a) // abs(b)
                                if (a < 0) != (b < 0):
                                    q = -q
                                res = q
                        elif x == 5:
                            res = 1 if a < b else 0
                        else:
                            res = 1 if a == b else 0
                    if res is not None and abs(res) > LIM:
                        res = None
                    st.append(res)
                else:
                    if not (0 <= y <= n - 1 and 0 <= z <= n - 1 and y <= z):
                        st.append(None)
                    else:
                        cells = [cv[c] for c in range(y, z + 1)]
                        if x == 4:
                            res = sum(1 for v in cells if v is not None)
                        elif any(v is None for v in cells):
                            res = None
                        elif x == 1:
                            res = sum(cells)
                        elif x == 2:
                            res = min(cells)
                        else:
                            res = max(cells)
                        if res is not None and abs(res) > LIM:
                            res = None
                        st.append(res)
            if len(st) != 1:
                return None
            return st[0]

        for i in range(n):
            calc(i)
        return vals

    cur = evaluate_all()
    changed = []
    epos = 0
    for e in range(len(edit_cells)):
        L = edit_lens[e]
        formulas[edit_cells[e]] = [(e_kinds[t], e_xs[t], e_ys[t], e_zs[t])
                                   for t in range(epos, epos + L)]
        epos += L
        nv = evaluate_all()
        changed.append(sum(1 for i in range(n) if nv[i] != cur[i]))
        cur = nv
    values = [0 if v is None else v for v in cur]
    errors = [v is None for v in cur]
    return (values, errors, changed)
```

### task: blackjack
```python
def main(shoe, bankrolls, bets, rounds):
    class NoCard(Exception):
        pass

    bank = list(bankrolls)
    pos = [0]

    def draw():
        if pos[0] >= len(shoe):
            raise NoCard()
        c = shoe[pos[0]]
        pos[0] += 1
        return c

    def total(cards):
        s = sum(min(c, 10) for c in cards)
        if 1 in cards and s + 10 <= 21:
            return s + 10, True
        return s, False

    played = 0
    busts = 0
    nat = 0
    for _ in range(rounds):
        taking = [i for i in range(len(bank)) if bank[i] >= bets[i]]
        if not taking:
            break
        start = pos[0]
        try:
            cards = {}
            for i in taking:
                cards[i] = [draw()]
            up = draw()
            for i in taking:
                cards[i].append(draw())
            hole = draw()
            dealer = [up, hole]
            delta = {i: 0 for i in taking}
            natural = {i: total(cards[i])[0] == 21 for i in taking}
            rnat = sum(1 for i in taking if natural[i])
            rbust = 0
            dealer_nat = (up == 1 or up >= 10) and total(dealer)[0] == 21
            if dealer_nat:
                for i in taking:
                    if not natural[i]:
                        delta[i] -= bets[i]
            else:
                for i in taking:
                    if natural[i]:
                        delta[i] += (3 * bets[i]) // 2
                allhands = []  # (player, cards, stake)
                for i in taking:
                    if natural[i]:
                        continue
                    bet = bets[i]
                    bk = bank[i]
                    c0 = cards[i]

                    def play_hand(h, stakes, k, bet=bet, bk=bk):
                        t, soft = total(h)
                        if (len(h) == 2 and not soft and t in (10, 11)
                                and 2 <= up <= 9 and bk >= sum(stakes) + bet):
                            stakes[k] *= 2
                            h.append(draw())
                            return
                        while True:
                            t, soft = total(h)
                            if t > 21:
                                break
                            if soft:
                                want = t <= 17
                            else:
                                want = t <= 11 or (12 <= t <= 16 and (up == 1 or up >= 7))
                            if not want:
                                break
                            h.append(draw())

                    if c0[0] == c0[1] and c0[0] in (1, 8) and bk >= 2 * bet:
                        hs = [[c0[0]], [c0[1]]]
                        stakes = [bet, bet]
                        hs[0].append(draw())
                        hs[1].append(draw())
                        if c0[0] != 1:
                            play_hand(hs[0], stakes, 0)
                            play_hand(hs[1], stakes, 1)
                    else:
                        hs = [c0]
                        stakes = [bet]
                        play_hand(c0, stakes, 0)
                    for k in range(len(hs)):
                        allhands.append((i, hs[k], stakes[k]))
                if any(total(h)[0] <= 21 for (_, h, _) in allhands):
                    drew = False
                    while total(dealer)[0] < 17:
                        dealer.append(draw())
                        drew = True
                    if drew and total(dealer)[0] > 21:
                        rbust = 1
                dt = total(dealer)[0]
                for (i, h, stake) in allhands:
                    ht = total(h)[0]
                    if ht > 21:
                        delta[i] -= stake
                    elif dt > 21 or dt < ht:
                        delta[i] += stake
                    elif dt > ht:
                        delta[i] -= stake
        except NoCard:
            pos[0] = start
            break
        for i in taking:
            bank[i] += delta[i]
        played += 1
        busts += rbust
        nat += rnat
    return (bank, played, busts, nat)
```
