### task: bowling
```python
def main(rolls):
    totals = []
    i = 0
    total = 0
    for _ in range(10):
        if rolls[i] == 10:
            total += 10 + rolls[i + 1] + rolls[i + 2]
            i += 1
        elif rolls[i] + rolls[i + 1] == 10:
            total += 10 + rolls[i + 2]
            i += 2
        else:
            total += rolls[i] + rolls[i + 1]
            i += 2
        totals.append(total)
    return totals
```

### task: lru
```python
def main(cap, keys):
    cache = []
    misses = 0
    for k in keys:
        if k in cache:
            cache.remove(k)
            cache.append(k)
        else:
            misses += 1
            if len(cache) >= cap:
                cache.pop(0)
            cache.append(k)
    return (misses, cache)
```

### task: rpn
```python
def main(kinds, vals):
    st = []
    for k, v in zip(kinds, vals):
        if k == 0:
            st.append(v)
        elif k == 5:
            if len(st) < 1:
                return (0, 1)
            st.append(st[-1])
        elif 1 <= k <= 4:
            if len(st) < 2:
                return (0, 1)
            b = st.pop()
            a = st.pop()
            if k == 1:
                st.append(a + b)
            elif k == 2:
                st.append(a - b)
            elif k == 3:
                st.append(a * b)
            else:
                if b == 0:
                    return (0, 2)
                q = abs(a) // abs(b)
                if (a < 0) != (b < 0):
                    q = -q
                st.append(q)
    if len(st) != 1:
        return (0, 3)
    return (st[0], 0)
```

### task: edit-cost
```python
def main(xs, ys, insert, delete, replace):
    n, m = len(xs), len(ys)
    prev = [j * insert for j in range(m + 1)]
    for i in range(1, n + 1):
        cur = [i * delete] + [0] * m
        for j in range(1, m + 1):
            sub = prev[j - 1] + (0 if xs[i - 1] == ys[j - 1] else replace)
            cur[j] = min(sub, prev[j] + delete, cur[j - 1] + insert)
        prev = cur
    return prev[m]
```

### task: shortest-hops
```python
def main(n, froms, tos, weights, source):
    INF = None
    best = [INF] * n
    best[source] = (0, 0)
    for _ in range(n + 1):
        changed = False
        for f, t, w in zip(froms, tos, weights):
            if best[f] is None:
                continue
            cand = (best[f][0] + w, best[f][1] + 1)
            if best[t] is None or cand < best[t]:
                best[t] = cand
                changed = True
        if not changed:
            break
    dist = [-1 if b is None else b[0] for b in best]
    hops = [-1 if b is None else b[1] for b in best]
    return (dist, hops)
```

### task: merge-ranges
```python
def main(starts, ends):
    rs = sorted(zip(starts, ends))
    ms, me = [], []
    for s, e in rs:
        if me and s <= me[-1] + 1:
            if e > me[-1]:
                me[-1] = e
        else:
            ms.append(s)
            me.append(e)
    covered = sum(e - s + 1 for s, e in zip(ms, me))
    return (ms, me, covered)
```

### task: tiny-vm
```python
def main(code, regs, limit):
    r = list(regs)
    n = len(code) // 3
    pc = 0
    executed = 0
    status = 0
    while True:
        if pc < 0 or pc >= n:
            status = 1
            break
        if executed >= limit:
            status = 2
            break
        op, a, b = code[3 * pc], code[3 * pc + 1], code[3 * pc + 2]
        executed += 1
        nxt = pc + 1
        if op == 0:
            status = 0
            break
        elif op == 1:
            r[a] = b
        elif op == 2:
            r[a] = r[a] + r[b]
        elif op == 3:
            r[a] = r[a] - r[b]
        elif op == 4:
            r[a] = r[a] * r[b]
        elif op == 5:
            r[a] = r[b]
        elif op == 6:
            if r[a] != 0:
                nxt = b
        elif op == 7:
            if r[a] < 0:
                nxt = b
        pc = nxt
    return (r, executed, status)
```

### task: lis-smallest
```python
def main(xs):
    n = len(xs)
    if n == 0:
        return []
    f = [1] * n
    for i in range(n - 1, -1, -1):
        for j in range(i + 1, n):
            if xs[j] > xs[i] and f[j] + 1 > f[i]:
                f[i] = f[j] + 1
    L = max(f)
    res = []
    idx = -1
    prev = None
    need = L
    while need > 0:
        pick = -1
        for j in range(idx + 1, n):
            if f[j] == need and (prev is None or xs[j] > prev):
                if pick == -1 or xs[j] < xs[pick]:
                    pick = j
        res.append(xs[pick])
        prev = xs[pick]
        idx = pick
        need -= 1
    return res
```
