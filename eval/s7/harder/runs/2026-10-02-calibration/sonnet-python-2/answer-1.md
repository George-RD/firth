### task: bowling
```python
def main(rolls):
    totals = []
    i = 0
    total = 0
    for frame in range(9):
        if rolls[i] == 10:
            total += 10 + rolls[i + 1] + rolls[i + 2]
            i += 1
        else:
            s = rolls[i] + rolls[i + 1]
            if s == 10:
                total += 10 + rolls[i + 2]
            else:
                total += s
            i += 2
        totals.append(total)
    total += sum(rolls[i:])
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
        elif k == 5:
            if len(st) < 1:
                return (0, 1)
            st.append(st[-1])
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
    changed = True
    while changed:
        changed = False
        for f, t, w in zip(froms, tos, weights):
            if best[f] is None:
                continue
            cand = (best[f][0] + w, best[f][1] + 1)
            if best[t] is None or cand < best[t]:
                best[t] = cand
                changed = True
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
    while True:
        if pc < 0 or pc >= n:
            return (r, executed, 1)
        if executed >= limit:
            return (r, executed, 2)
        op, a, b = code[3 * pc], code[3 * pc + 1], code[3 * pc + 2]
        executed += 1
        if op == 0:
            return (r, executed, 0)
        nxt = pc + 1
        if op == 1:
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
```

### task: lis-smallest
```python
def main(xs):
    n = len(xs)
    if n == 0:
        return []
    L = [1] * n
    for i in range(n - 1, -1, -1):
        for j in range(i + 1, n):
            if xs[j] > xs[i] and L[j] + 1 > L[i]:
                L[i] = L[j] + 1
    total = max(L)
    res = []
    cur = -1
    prev = None
    for need in range(total, 0, -1):
        bi = -1
        for j in range(cur + 1, n):
            if L[j] == need and (prev is None or xs[j] > prev):
                if bi == -1 or xs[j] < xs[bi]:
                    bi = j
        res.append(xs[bi])
        prev = xs[bi]
        cur = bi
    return res
```
