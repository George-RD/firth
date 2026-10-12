### task: poker
```python
def main(ranks1, suits1, ranks2, suits2):
    def ev(r, s):
        cnt = {}
        for x in r:
            cnt[x] = cnt.get(x, 0) + 1
        groups = sorted(cnt.items(), key=lambda kv: (-kv[1], -kv[0]))
        sizes = [g[1] for g in groups]
        flush = len(set(s)) == 1
        rs = sorted(r)
        straight = False
        high = 0
        if len(cnt) == 5:
            if rs[4] - rs[0] == 4:
                straight = True
                high = rs[4]
            elif rs == [2, 3, 4, 5, 14]:
                straight = True
                high = 5
        if straight and flush:
            cat = 8
        elif sizes[0] == 4:
            cat = 7
        elif sizes[0] == 3 and sizes[1] == 2:
            cat = 6
        elif flush:
            cat = 5
        elif straight:
            cat = 4
        elif sizes[0] == 3:
            cat = 3
        elif sizes[0] == 2 and sizes[1] == 2:
            cat = 2
        elif sizes[0] == 2:
            cat = 1
        else:
            cat = 0
        if cat in (4, 8):
            tb = [high]
        else:
            tb = [g[0] for g in groups]
        return cat, tb

    c1, t1 = ev(ranks1, suits1)
    c2, t2 = ev(ranks2, suits2)
    k1 = (c1, t1)
    k2 = (c2, t2)
    if k1 > k2:
        w = 1
    elif k2 > k1:
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
    for h, a, hg, ag in zip(homes, aways, home_goals, away_goals):
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
    groups = {}
    for t in range(n):
        key = (pts[t], gf[t] - ga[t], gf[t])
        groups.setdefault(key, []).append(t)
    order = []
    for key in sorted(groups.keys(), reverse=True):
        g = groups[key]
        if len(g) > 1:
            gs = set(g)
            h2h = {t: 0 for t in g}
            for h, a, hg, ag in zip(homes, aways, home_goals, away_goals):
                if h in gs and a in gs:
                    if hg > ag:
                        h2h[h] += 3
                    elif hg < ag:
                        h2h[a] += 3
                    else:
                        h2h[h] += 1
                        h2h[a] += 1
            g = sorted(g, key=lambda t: (-h2h[t], t))
        order.extend(g)
    return (order, pts)
```

### task: bank-ledger
```python
def main(balances, limit, kinds, accts, others, amounts):
    n = len(balances)
    bal = list(balances)
    rej = [0] * n
    frozen = [False] * n
    rejected = 0
    for k in range(len(kinds)):
        kind = kinds[k]
        if kind == 4:
            for i in range(n):
                b = bal[i]
                if b < 0:
                    bal[i] = b - ((-b + 9) // 10)
                elif b >= 100:
                    bal[i] = b + b // 100
            continue
        a = accts[k]
        o = others[k]
        amt = amounts[k]
        bad = False
        if frozen[a]:
            bad = True
        elif kind == 3 and (frozen[o] or o == a):
            bad = True
        elif kind in (2, 3) and bal[a] - amt < -limit:
            bad = True
        if bad:
            rejected += 1
            rej[a] += 1
            if rej[a] >= 3:
                frozen[a] = True
            continue
        if kind == 1:
            bal[a] += amt
        else:
            before = bal[a]
            bal[a] -= amt
            if kind == 3:
                bal[o] += amt
            if before >= 0 and bal[a] < 0:
                bal[a] -= 5
    return (bal, rejected, frozen)
```

### task: order-book
```python
def main(kinds, sides, prices, qtys):
    m = len(kinds)
    filled = [0] * m
    book = []  # [side, price, remaining, seq]
    value = 0
    trades = 0
    for i in range(m):
        if kinds[i] == 1:
            j = qtys[i]
            if 0 <= j < i and kinds[j] == 0:
                book = [o for o in book if o[3] != j]
            continue
        side = sides[i]
        price = prices[i]
        q = qtys[i]
        while q > 0:
            best = None
            for o in book:
                if o[0] == side:
                    continue
                if side == 0:
                    if price != 0 and o[1] > price:
                        continue
                    key = (o[1], o[3])
                else:
                    if price != 0 and o[1] < price:
                        continue
                    key = (-o[1], o[3])
                if best is None or key < best[0]:
                    best = (key, o)
            if best is None:
                break
            o = best[1]
            t = min(q, o[2])
            value += t * o[1]
            trades += 1
            filled[i] += t
            filled[o[3]] += t
            q -= t
            o[2] -= t
            if o[2] == 0:
                book.remove(o)
        if q > 0 and price > 0:
            book.append([side, price, q, i])
    return (filled, value, trades)
```

### task: spreadsheet
```python
def main(kinds, xs, ys):
    n = len(kinds)
    refs = [[] for _ in range(n)]
    bad = [False] * n
    for i in range(n):
        k = kinds[i]
        a = xs[i]
        b = ys[i]
        if k == 0:
            continue
        if k in (1, 2, 3):
            lst = [a, b]
            if not (0 <= a < n and 0 <= b < n):
                bad[i] = True
            refs[i] = [c for c in lst if 0 <= c < n]
        else:
            if a > b:
                bad[i] = True
                refs[i] = []
            else:
                if a < 0 or b < 0 or a >= n or b >= n:
                    bad[i] = True
                refs[i] = [c for c in range(a, b + 1) if 0 <= c < n]
    # reachability in >= 1 steps
    reach = [[False] * n for _ in range(n)]
    for i in range(n):
        for c in refs[i]:
            reach[i][c] = True
    for m in range(n):
        for i in range(n):
            if reach[i][m]:
                for j in range(n):
                    if reach[m][j]:
                        reach[i][j] = True
    cyc = [False] * n
    for i in range(n):
        for c in range(n):
            if reach[i][c] and reach[c][c]:
                cyc[i] = True
                break
    values = [0] * n
    errors = [False] * n
    done = [False] * n

    def tdiv(x, y):
        q = abs(x) // abs(y)
        return q if (x >= 0) == (y >= 0) else -q

    def ev(i):
        if done[i]:
            return
        done[i] = True
        if bad[i] or cyc[i]:
            errors[i] = True
            values[i] = 0
            return
        k = kinds[i]
        a = xs[i]
        b = ys[i]
        if k == 0:
            values[i] = a
            return
        for c in refs[i]:
            ev(c)
        if k == 5:
            values[i] = sum(1 for c in refs[i] if not errors[c] and values[c] > 0)
            return
        if any(errors[c] for c in refs[i]):
            errors[i] = True
            values[i] = 0
            return
        if k == 1:
            values[i] = values[a] + values[b]
        elif k == 2:
            values[i] = values[a] - values[b]
        elif k == 3:
            if values[b] == 0:
                errors[i] = True
                values[i] = 0
            else:
                values[i] = tdiv(values[a], values[b])
        elif k == 4:
            values[i] = max(values[c] for c in range(a, b + 1))

    for i in range(n):
        ev(i)
    return (values, errors)
```

### task: elevator
```python
def main(times, floors):
    m = len(times)
    served = [None] * m
    t = 0
    f = 0
    d = 1
    moved = 0
    while True:
        waiting = [k for k in range(m) if served[k] is None and times[k] <= t]
        here = [k for k in waiting if floors[k] == f]
        if here:
            for k in here:
                served[k] = t
            t += 2
            continue
        if not waiting:
            rest = [times[k] for k in range(m) if served[k] is None]
            if not rest:
                break
            t = min(rest)
            continue
        if d == 1:
            ahead = any(floors[k] > f for k in waiting)
        else:
            ahead = any(floors[k] < f for k in waiting)
        if not ahead:
            d = -d
        f += d
        t += 1
        moved += 1
    return (served, t, moved)
```

### task: date-diff
```python
def main(y1, m1, d1, y2, m2, d2):
    def leap(y):
        return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)

    def mdays(y, m):
        if m == 2:
            return 29 if leap(y) else 28
        if m in (4, 6, 9, 11):
            return 30
        return 31

    def doy(y, m, d):
        return sum(mdays(y, i) for i in range(1, m)) + d

    def ordinal(y, m, d):
        total = 0
        for yy in range(1600, y):
            total += 366 if leap(yy) else 365
        return total + doy(y, m, d)

    o1 = ordinal(y1, m1, d1)
    o2 = ordinal(y2, m2, d2)
    o2000 = ordinal(2000, 1, 1)
    days = o2 - o1
    weekday = (5 + (o2 - o2000)) % 7
    return (days, weekday, doy(y2, m2, d2))
```

### task: heap-alloc
```python
def main(size, kinds, vals):
    free = [True] * size
    allocs = {}
    results = []

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

    for i in range(len(kinds)):
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
                allocs[i] = (s, v)
                results.append(s)
        else:
            if 0 <= v < i and v in allocs:
                s, ln = allocs.pop(v)
                for c in range(s, s + ln):
                    free[c] = True
                results.append(0)
            else:
                results.append(-1)
    bl = blocks()
    largest = max((ln for _, ln in bl), default=0)
    return (results, len(bl), largest)
```
