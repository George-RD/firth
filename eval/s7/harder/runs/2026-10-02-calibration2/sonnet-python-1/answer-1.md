### task: poker
```python
def main(ranks1, suits1, ranks2, suits2):
    def ev(r, s):
        cnt = {}
        for x in r:
            cnt[x] = cnt.get(x, 0) + 1
        groups = sorted(cnt.items(), key=lambda kv: (-kv[1], -kv[0]))
        granks = [g[0] for g in groups]
        sizes = [g[1] for g in groups]
        flush = len(set(s)) == 1
        sr = sorted(r)
        straight = False
        high = 0
        if len(cnt) == 5:
            if sr[4] - sr[0] == 4:
                straight = True
                high = sr[4]
            elif sr == [2, 3, 4, 5, 14]:
                straight = True
                high = 5
        if straight and flush:
            cat = 8
        elif sizes == [4, 1]:
            cat = 7
        elif sizes == [3, 2]:
            cat = 6
        elif flush:
            cat = 5
        elif straight:
            cat = 4
        elif sizes == [3, 1, 1]:
            cat = 3
        elif sizes == [2, 2, 1]:
            cat = 2
        elif sizes == [2, 1, 1, 1]:
            cat = 1
        else:
            cat = 0
        if cat in (4, 8):
            key = [high]
        else:
            key = granks
        return cat, key

    c1, k1 = ev(ranks1, suits1)
    c2, k2 = ev(ranks2, suits2)
    a = (c1, k1)
    b = (c2, k2)
    if a > b:
        w = 1
    elif b > a:
        w = 2
    else:
        w = 0
    return (w, c1, c2)
```

### task: league-table
```python
def main(n, homes, aways, home_goals, away_goals):
    pts = [0] * n
    gf = [0] * n
    ga = [0] * n
    m = len(homes)
    for k in range(m):
        h, a, hg, ag = homes[k], aways[k], home_goals[k], away_goals[k]
        gf[h] += hg
        ga[h] += ag
        gf[a] += ag
        ga[a] += hg
        if hg > ag:
            pts[h] += 3
        elif hg < ag:
            pts[a] += 3
        else:
            pts[h] += 1
            pts[a] += 1

    def key(t):
        return (-pts[t], -(gf[t] - ga[t]), -gf[t])

    teams = sorted(range(n), key=lambda t: (key(t), t))
    order = []
    i = 0
    while i < n:
        j = i
        while j < n and key(teams[j]) == key(teams[i]):
            j += 1
        group = teams[i:j]
        if len(group) > 1:
            gs = set(group)
            h2h = {t: 0 for t in group}
            for k in range(m):
                h, a = homes[k], aways[k]
                if h in gs and a in gs:
                    hg, ag = home_goals[k], away_goals[k]
                    if hg > ag:
                        h2h[h] += 3
                    elif hg < ag:
                        h2h[a] += 3
                    else:
                        h2h[h] += 1
                        h2h[a] += 1
            group = sorted(group, key=lambda t: (-h2h[t], t))
        order.extend(group)
        i = j
    return (order, pts)
```

### task: bank-ledger
```python
def main(balances, limit, kinds, accts, others, amounts):
    bal = list(balances)
    n = len(bal)
    rej_count = [0] * n
    frozen = [False] * n
    rejected = 0
    for k in range(len(kinds)):
        kind = kinds[k]
        if kind == 4:
            for i in range(n):
                b = bal[i]
                if b < 0:
                    bal[i] = b - (-b + 9) // 10
                elif b >= 100:
                    bal[i] = b + b // 100
            continue
        a = accts[k]
        amt = amounts[k]
        b = others[k]
        bad = False
        if frozen[a]:
            bad = True
        elif kind == 3 and (frozen[b] or a == b):
            bad = True
        elif kind in (2, 3) and bal[a] - amt < -limit:
            bad = True
        if bad:
            rejected += 1
            rej_count[a] += 1
            if rej_count[a] >= 3:
                frozen[a] = True
            continue
        if kind == 1:
            bal[a] += amt
        else:
            before = bal[a]
            bal[a] -= amt
            if kind == 3:
                bal[b] += amt
            if before >= 0 and bal[a] < 0:
                bal[a] -= 5
    return (bal, rejected, frozen)
```

### task: order-book
```python
def main(kinds, sides, prices, qtys):
    n = len(kinds)
    filled = [0] * n
    resting = []  # [id, side, price, remaining]
    value = 0
    trades = 0
    for i in range(n):
        if kinds[i] == 1:
            j = qtys[i]
            resting = [r for r in resting if r[0] != j]
            continue
        side = sides[i]
        limit = prices[i]
        rem = qtys[i]
        while rem > 0:
            best = None
            for r in resting:
                if r[1] == side or r[3] <= 0:
                    continue
                if side == 0:
                    if limit != 0 and r[2] > limit:
                        continue
                    k = (r[2], r[0])
                else:
                    if limit != 0 and r[2] < limit:
                        continue
                    k = (-r[2], r[0])
                if best is None or k < best[0]:
                    best = (k, r)
            if best is None:
                break
            r = best[1]
            units = min(rem, r[3])
            rem -= units
            r[3] -= units
            filled[i] += units
            filled[r[0]] += units
            value += units * r[2]
            trades += 1
            if r[3] == 0:
                resting = [x for x in resting if x is not r]
        if rem > 0 and limit != 0:
            resting.append([i, side, limit, rem])
    return (filled, value, trades)
```

### task: spreadsheet
```python
def main(kinds, xs, ys):
    n = len(kinds)
    oob = [False] * n
    edges = [[] for _ in range(n)]
    for i in range(n):
        k, a, b = kinds[i], xs[i], ys[i]
        if k in (1, 2, 3):
            if not (0 <= a < n and 0 <= b < n):
                oob[i] = True
            else:
                edges[i] = [a, b]
        elif k in (4, 5):
            if a > b or a < 0 or b >= n or b < 0 or a >= n:
                oob[i] = True
            else:
                edges[i] = list(range(a, b + 1))
    reach = [[False] * n for _ in range(n)]
    for i in range(n):
        for j in edges[i]:
            reach[i][j] = True
    for m in range(n):
        for i in range(n):
            if reach[i][m]:
                for j in range(n):
                    if reach[m][j]:
                        reach[i][j] = True
    cyc = [reach[c][c] for c in range(n)]
    cycerr = [any(reach[i][j] and cyc[j] for j in range(n)) for i in range(n)]

    memo = {}

    def ev(i):
        if i in memo:
            return memo[i]
        if oob[i] or cycerr[i]:
            memo[i] = (0, True)
            return memo[i]
        k, a, b = kinds[i], xs[i], ys[i]
        if k == 0:
            res = (a, False)
        elif k in (1, 2, 3):
            va, ea = ev(a)
            vb, eb = ev(b)
            if ea or eb:
                res = (0, True)
            elif k == 1:
                res = (va + vb, False)
            elif k == 2:
                res = (va - vb, False)
            else:
                if vb == 0:
                    res = (0, True)
                else:
                    q = abs(va) // abs(vb)
                    if (va < 0) != (vb < 0):
                        q = -q
                    res = (q, False)
        elif k == 4:
            vals = [ev(c) for c in range(a, b + 1)]
            if any(e for _, e in vals):
                res = (0, True)
            else:
                res = (max(v for v, _ in vals), False)
        else:
            cnt = 0
            for c in range(a, b + 1):
                v, e = ev(c)
                if not e and v > 0:
                    cnt += 1
            res = (cnt, False)
        memo[i] = res
        return res

    values = []
    errors = []
    for i in range(n):
        v, e = ev(i)
        values.append(0 if e else v)
        errors.append(e)
    return (values, errors)
```

### task: elevator
```python
def main(times, floors):
    m = len(times)
    served = [-1] * m
    done = [False] * m
    t = 0
    floor = 0
    up = True
    moved = 0
    while True:
        waiting = [k for k in range(m) if not done[k] and times[k] <= t]
        here = [k for k in waiting if floors[k] == floor]
        if here:
            for k in here:
                served[k] = t
                done[k] = True
            t += 2
            continue
        if not waiting:
            pending = [times[k] for k in range(m) if not done[k]]
            if not pending:
                break
            t = min(pending)
            continue
        if up:
            beyond = any(floors[k] > floor for k in waiting)
        else:
            beyond = any(floors[k] < floor for k in waiting)
        if not beyond:
            up = not up
        floor += 1 if up else -1
        t += 1
        moved += 1
    return (served, t, moved)
```

### task: date-diff
```python
def main(y1, m1, d1, y2, m2, d2):
    import datetime
    a = datetime.date(y1, m1, d1)
    b = datetime.date(y2, m2, d2)
    return ((b - a).days, b.weekday(), b.timetuple().tm_yday)
```

### task: heap-alloc
```python
def main(size, kinds, vals):
    free = [True] * size
    n = len(kinds)
    results = []
    alloc = {}  # op index -> (start, length)

    def blocks():
        res = []
        i = 0
        while i < size:
            if free[i]:
                j = i
                while j < size and free[j]:
                    j += 1
                res.append((i, j - i))
                i = j
            else:
                i += 1
        return res

    for i in range(n):
        v = vals[i]
        if kinds[i] == 0:
            best = None
            for start, ln in blocks():
                if ln >= v and (best is None or ln < best[1]):
                    best = (start, ln)
            if best is None:
                results.append(-1)
            else:
                s = best[0]
                for c in range(s, s + v):
                    free[c] = False
                alloc[i] = (s, v)
                results.append(s)
        else:
            if 0 <= v < i and v in alloc:
                s, ln = alloc.pop(v)
                for c in range(s, s + ln):
                    free[c] = True
                results.append(0)
            else:
                results.append(-1)
    bl = blocks()
    largest = max([ln for _, ln in bl], default=0)
    return (results, len(bl), largest)
```
