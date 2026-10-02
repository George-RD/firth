### task: poker
```python
def main(ranks1, suits1, ranks2, suits2):
    def ev(r, s):
        cnt = {}
        for x in r:
            cnt[x] = cnt.get(x, 0) + 1
        groups = sorted(cnt.items(), key=lambda kv: (-kv[1], -kv[0]))
        gr = [k for k, v in groups]
        sizes = [v for k, v in groups]
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
            return (8, [high])
        if sizes[0] == 4:
            return (7, gr)
        if sizes[0] == 3 and sizes[1] == 2:
            return (6, gr)
        if flush:
            return (5, gr)
        if straight:
            return (4, [high])
        if sizes[0] == 3:
            return (3, gr)
        if sizes[0] == 2 and sizes[1] == 2:
            return (2, gr)
        if sizes[0] == 2:
            return (1, gr)
        return (0, gr)

    e1 = ev(ranks1, suits1)
    e2 = ev(ranks2, suits2)
    if e1 > e2:
        w = 1
    elif e2 > e1:
        w = 2
    else:
        w = 0
    return (w, e1[0], e2[0])
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
    key = lambda t: (-pts[t], -(gf[t] - ga[t]), -gf[t])
    teams = sorted(range(n), key=key)
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
                    if home_goals[k] > away_goals[k]:
                        h2h[h] += 3
                    elif home_goals[k] < away_goals[k]:
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
        amt = amounts[k]
        b2 = others[k]
        bad = False
        if frozen[a]:
            bad = True
        elif kind == 3 and (frozen[b2] or a == b2):
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
            old = bal[a]
            bal[a] = old - amt
            if kind == 3:
                bal[b2] += amt
            if old >= 0 and bal[a] < 0:
                bal[a] -= 5
    return (bal, rejected, frozen)
```

### task: order-book
```python
def main(kinds, sides, prices, qtys):
    n = len(kinds)
    filled = [0] * n
    rem = [0] * n
    resting = []
    value = 0
    trades = 0
    for i in range(n):
        if kinds[i] == 1:
            j = qtys[i]
            if 0 <= j < i and kinds[j] == 0 and j in resting:
                resting.remove(j)
            continue
        rem[i] = qtys[i]
        side = sides[i]
        lim = prices[i]
        while rem[i] > 0:
            cands = []
            for j in resting:
                if sides[j] == side:
                    continue
                if lim != 0:
                    if side == 0 and prices[j] > lim:
                        continue
                    if side == 1 and prices[j] < lim:
                        continue
                cands.append(j)
            if not cands:
                break
            if side == 0:
                j = min(cands, key=lambda x: (prices[x], x))
            else:
                j = min(cands, key=lambda x: (-prices[x], x))
            q = min(rem[i], rem[j])
            value += q * prices[j]
            trades += 1
            filled[i] += q
            filled[j] += q
            rem[i] -= q
            rem[j] -= q
            if rem[j] == 0:
                resting.remove(j)
        if rem[i] > 0 and lim != 0:
            resting.append(i)
    return (filled, value, trades)
```

### task: spreadsheet
```python
def main(kinds, xs, ys):
    n = len(kinds)
    bad = [False] * n
    edges = [[] for _ in range(n)]
    for i in range(n):
        k = kinds[i]
        a, b = xs[i], ys[i]
        if k in (1, 2, 3):
            refs = [a, b]
            for r in refs:
                if 0 <= r < n:
                    edges[i].append(r)
                else:
                    bad[i] = True
        elif k in (4, 5):
            if a > b:
                bad[i] = True
            else:
                for r in range(a, b + 1):
                    if 0 <= r < n:
                        edges[i].append(r)
                    else:
                        bad[i] = True
    # reach[i]: cells reachable in one or more steps
    reach = []
    for i in range(n):
        seen = set()
        stack = list(edges[i])
        while stack:
            c = stack.pop()
            if c in seen:
                continue
            seen.add(c)
            stack.extend(edges[c])
        reach.append(seen)
    err0 = [False] * n
    for i in range(n):
        if bad[i]:
            err0[i] = True
        else:
            for c in reach[i]:
                if c in reach[c]:
                    err0[i] = True
                    break
        # a bad cell may also lead to a cycle; it is already an error
    memo = {}

    def comp(i):
        if i in memo:
            return memo[i]
        if err0[i]:
            memo[i] = (0, True)
            return memo[i]
        k = kinds[i]
        a, b = xs[i], ys[i]
        if k == 0:
            res = (a, False)
        elif k in (1, 2, 3):
            va, ea = comp(a)
            vb, eb = comp(b)
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
            vals = []
            err = False
            for r in range(a, b + 1):
                v, e = comp(r)
                if e:
                    err = True
                vals.append(v)
            res = (0, True) if err else (max(vals), False)
        elif k == 5:
            c = 0
            for r in range(a, b + 1):
                v, e = comp(r)
                if not e and v > 0:
                    c += 1
            res = (c, False)
        else:
            res = (0, True)
        memo[i] = res
        return res

    values = []
    errors = []
    for i in range(n):
        v, e = comp(i)
        values.append(v)
        errors.append(e)
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
            pend = [times[k] for k in range(m) if served[k] is None]
            if not pend:
                break
            t = min(pend)
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
    import datetime
    a = datetime.date(y1, m1, d1)
    b = datetime.date(y2, m2, d2)
    return ((b - a).days, b.weekday(), b.timetuple().tm_yday)
```

### task: heap-alloc
```python
def main(size, kinds, vals):
    cells = [False] * size  # True = used
    allocs = {}
    results = []

    def blocks():
        res = []
        i = 0
        while i < size:
            if not cells[i]:
                j = i
                while j < size and not cells[j]:
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
                    cells[c] = True
                allocs[i] = (s, v)
                results.append(s)
        else:
            if 0 <= v < i and v in allocs:
                s, ln = allocs.pop(v)
                for c in range(s, s + ln):
                    cells[c] = False
                results.append(0)
            else:
                results.append(-1)
    bl = blocks()
    largest = max((ln for s, ln in bl), default=0)
    return (results, len(bl), largest)
```
