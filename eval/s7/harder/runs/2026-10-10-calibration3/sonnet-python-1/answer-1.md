### task: mini-cpu
```python
def main(ops, fa, fb, fc, regs, memory, inputs):
    n = len(ops)
    r = list(regs)
    mem = list(memory)
    fl = [False, False, False]
    ds = []
    cs = []
    out = []
    ip = 0
    pc = 0
    ex = 0
    status = 0

    def wrap(x):
        return (x + 2147483648) % 4294967296 - 2147483648

    def setf(t):
        w = wrap(t)
        fl[0] = (w == 0)
        fl[1] = (w < 0)
        fl[2] = (w != t)
        return w

    while True:
        if ex == 300:
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
        elif op == 6 or op == 7:
            x = r[b]
            y = r[c]
            if y == 0:
                status = 3
                break
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
            r[a] = setf(r[b] * (2 ** c))
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
            if fl[0]:
                npc = b
        elif op == 16:
            if not fl[0]:
                npc = b
        elif op == 17:
            if fl[1] != fl[2]:
                npc = b
        elif op == 18:
            if fl[1] == fl[2]:
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
            if ip >= len(inputs):
                status = 7
                break
            r[a] = inputs[ip]
            ip += 1
        elif op == 24:
            out.append(r[a])
        ex += 1
        pc = npc
    return (out, status, ex, pc, r, mem, [fl[0], fl[1], fl[2]])
```

### task: stacker
```python
def main(width, height, queue, moves):
    SH = {
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
        for dx, dy in SH[kind][rot]:
            px = x + dx
            py = y + dy
            if px < 0 or px >= width or py < 0 or py >= height:
                return False
            if grid[py][px]:
                return False
        return True

    score = 0
    rows = 0
    locks = 0
    status = 0
    held = -1
    streak = 0
    last_k = 0
    cur = None  # [kind, rot, x, y]
    can_hold = False
    qi = 0
    mi = 0
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
            can_hold = True
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
            for ox, oy in ((0, 0), (-1, 0), (1, 0), (0, 1), (-2, 0), (2, 0)):
                if fits(kind, nr, x + ox, y + oy):
                    cur[1] = nr
                    cur[2] = x + ox
                    cur[3] = y + oy
                    break
        elif cmd == 6:
            if can_hold:
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
                can_hold = False
                if not fits(nk, 0, sx, sy):
                    status = 2
                    break
        elif cmd == 0:
            while fits(kind, rot, x, y - 1):
                y -= 1
            for dx, dy in SH[kind][rot]:
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
                level = 1 + rows // 10
                score += (base + 50 * streak) * level
                rows += k
                streak += 1
                last_k = k
            else:
                streak = 0

    heights = []
    for cx in range(width):
        h = 0
        for ry in range(height):
            if grid[ry][cx]:
                h = ry + 1
        heights.append(h)
    return (heights, score, rows, locks, status, held)
```

### task: bank-days
```python
def main(year, month, day, days, balances, limits, credit_ppm, debit_ppm,
         tx_day, tx_kind, tx_acct, tx_other, tx_amount,
         so_dom, so_from, so_to, so_amount):
    n = len(balances)
    bal = list(balances)

    def is_leap(y):
        return (y % 4 == 0 and y % 100 != 0) or y % 400 == 0

    def dim(y, m):
        if m == 2:
            return 29 if is_leap(y) else 28
        if m in (4, 6, 9, 11):
            return 30
        return 31

    accrued = [0] * n
    over = [False] * n
    rejected = 0
    nso = len(so_dom)
    cancelled = [False] * nso
    fails = [0] * nso
    added = 0
    taken = 0
    fees = 0

    def pay(a, b, amt):
        # returns True if carried out
        if a == b:
            return False
        if bal[a] - amt < -limits[a]:
            return False
        bal[a] -= amt
        bal[b] += amt
        return True

    y, m, d = year, month, day
    for dn in range(days):
        mdays = dim(y, m)
        for k in range(len(tx_day)):
            if tx_day[k] != dn:
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
                if not pay(a, tx_other[k], amt):
                    rejected += 1
        for k in range(nso):
            if cancelled[k]:
                continue
            due = min(so_dom[k], mdays)
            if d != due:
                continue
            if pay(so_from[k], so_to[k], so_amount[k]):
                fails[k] = 0
            else:
                rejected += 1
                fails[k] += 1
                if fails[k] >= 2:
                    cancelled[k] = True
        for i in range(n):
            if bal[i] > 0:
                accrued[i] += bal[i] * credit_ppm
            elif bal[i] < 0:
                accrued[i] += bal[i] * debit_ppm
                over[i] = True
        if d == mdays:
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
                if over[i]:
                    bal[i] -= 1000
                    fees += 1000
                    over[i] = False
        d += 1
        if d > mdays:
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
    forms = []
    pos = 0
    for L in lens:
        forms.append([(kinds[t], xs[t], ys[t], zs[t]) for t in range(pos, pos + L)])
        pos += L

    LIM = 1000000000

    def trunc_div(a, b):
        q = abs(a) // abs(b)
        if (a < 0) != (b < 0):
            q = -q
        return q

    def evaluate(f, getcell):
        st = []
        for kd, x, y, z in f:
            if kd == 0:
                st.append(x)
            elif kd == 1:
                if x < 0 or x >= n:
                    st.append(None)
                else:
                    st.append(getcell(x))
            elif kd == 2:
                ar = 3 if x == 7 else (1 if x == 8 else 2)
                if len(st) < ar:
                    return None
                args = st[len(st) - ar:]
                del st[len(st) - ar:]
                if x == 7:
                    c, a, b = args
                    if c is None:
                        res = None
                    elif c != 0:
                        res = a
                    else:
                        res = b
                else:
                    if any(v is None for v in args):
                        res = None
                    elif x == 8:
                        res = -args[0]
                    else:
                        a, b = args
                        if x == 1:
                            res = a + b
                        elif x == 2:
                            res = a - b
                        elif x == 3:
                            res = a * b
                        elif x == 4:
                            res = None if b == 0 else trunc_div(a, b)
                        elif x == 5:
                            res = 1 if a < b else 0
                        else:
                            res = 1 if a == b else 0
                if res is not None and abs(res) > LIM:
                    res = None
                st.append(res)
            else:
                if y < 0 or y >= n or z < 0 or z >= n or y > z:
                    st.append(None)
                else:
                    vals = [getcell(j) for j in range(y, z + 1)]
                    if x == 4:
                        res = sum(1 for v in vals if v is not None)
                    elif any(v is None for v in vals):
                        res = None
                    elif x == 1:
                        res = sum(vals)
                    elif x == 2:
                        res = min(vals)
                    else:
                        res = max(vals)
                    if res is not None and abs(res) > LIM:
                        res = None
                    st.append(res)
        if len(st) != 1:
            return None
        return st[0]

    def solve(forms):
        refs = []
        for f in forms:
            s = set()
            for kd, x, y, z in f:
                if kd == 1 and 0 <= x < n:
                    s.add(x)
                elif kd == 3 and 0 <= y <= z <= n - 1:
                    for j in range(y, z + 1):
                        s.add(j)
            refs.append(s)
        reach = [[False] * n for _ in range(n)]
        for i in range(n):
            for j in refs[i]:
                reach[i][j] = True
        for k in range(n):
            for i in range(n):
                if reach[i][k]:
                    for j in range(n):
                        if reach[k][j]:
                            reach[i][j] = True
        incyc = [reach[i][i] for i in range(n)]
        bad = [incyc[i] or any(reach[i][j] and incyc[j] for j in range(n)) for i in range(n)]
        memo = {}

        def getcell(i):
            if bad[i]:
                return None
            if i in memo:
                return memo[i]
            v = evaluate(forms[i], getcell)
            memo[i] = v
            return v

        return [getcell(i) for i in range(n)]

    cur = solve(forms)
    changed = []
    epos = 0
    for e in range(len(edit_cells)):
        L = edit_lens[e]
        f = [(e_kinds[t], e_xs[t], e_ys[t], e_zs[t]) for t in range(epos, epos + L)]
        epos += L
        forms[edit_cells[e]] = f
        new = solve(forms)
        cnt = 0
        for i in range(n):
            if new[i] != cur[i]:
                cnt += 1
        changed.append(cnt)
        cur = new
    values = [0 if v is None else v for v in cur]
    errors = [v is None for v in cur]
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

    def total(cards):
        s = sum(min(c, 10) for c in cards)
        if 1 in cards and s + 10 <= 21:
            return s + 10, True
        return s, False

    for _ in range(rounds):
        taking = [i for i in range(np_) if bank[i] >= bets[i]]
        if not taking:
            break
        p = ptr

        def draw():
            nonlocal p
            if p >= len(shoe):
                raise Out()
            c = shoe[p]
            p += 1
            return c

        try:
            hands0 = {i: [draw()] for i in taking}
            up = draw()
            for i in taking:
                hands0[i].append(draw())
            hole = draw()
            dealer = [up, hole]
            delta = {i: 0 for i in taking}
            rnats = 0
            for i in taking:
                if total(hands0[i])[0] == 21:
                    rnats += 1
            dealer_nat = (up == 1 or up >= 10) and total(dealer)[0] == 21
            dbust = 0
            if dealer_nat:
                for i in taking:
                    if total(hands0[i])[0] != 21:
                        delta[i] = -bets[i]
            else:
                allhands = []  # (player, cards list, stake)
                for i in taking:
                    h = hands0[i]
                    if total(h)[0] == 21:
                        delta[i] += (3 * bets[i]) // 2
                        continue
                    bet = bets[i]
                    myhands = []  # list of [cards, stake]

                    def play(hand):
                        cards, stake = hand
                        t, soft = total(cards)
                        if (len(cards) == 2 and not soft and t in (10, 11)
                                and 2 <= up <= 9):
                            staked = sum(hh[1] for hh in myhands)
                            if bank[i] >= staked + bet:
                                hand[1] = stake * 2
                                cards.append(draw())
                                return
                        while True:
                            t, soft = total(cards)
                            if t > 21:
                                break
                            if soft:
                                want = t <= 17
                            else:
                                want = t <= 11 or (12 <= t <= 16 and (up == 1 or up >= 7))
                            if not want:
                                break
                            cards.append(draw())

                    if h[0] == h[1] and h[0] in (1, 8) and bank[i] >= 2 * bet:
                        ha = [[h[0]], bet]
                        hb = [[h[1]], bet]
                        myhands.append(ha)
                        myhands.append(hb)
                        ha[0].append(draw())
                        hb[0].append(draw())
                        if h[0] == 8:
                            play(ha)
                            play(hb)
                    else:
                        hh = [list(h), bet]
                        myhands.append(hh)
                        play(hh)
                    for hh in myhands:
                        allhands.append((i, hh[0], hh[1]))
                if any(total(c)[0] <= 21 for _, c, _ in allhands):
                    while total(dealer)[0] < 17:
                        dealer.append(draw())
                dt = total(dealer)[0]
                if dt > 21:
                    dbust = 1
                for i, c, stake in allhands:
                    t = total(c)[0]
                    if t > 21:
                        delta[i] -= stake
                    elif dt > 21 or dt < t:
                        delta[i] += stake
                    elif dt > t:
                        delta[i] -= stake
        except Out:
            ptr = len(shoe)
            break
        ptr = p
        for i in taking:
            bank[i] += delta[i]
        played += 1
        busts += dbust
        nats += rnats
    return (bank, played, busts, nats)
```
