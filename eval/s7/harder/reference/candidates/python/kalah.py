def main(pits, seeds, moves):
    n = 2 * pits + 2
    b = [seeds] * n
    b[pits] = 0
    b[2 * pits + 1] = 0
    store = [pits, 2 * pits + 1]
    cur = 0
    illegal = 0
    read = 0
    took = [0, 0]
    ended = False
    for j in moves:
        read += 1
        if j < 0 or j >= pits:
            illegal += 1
            continue
        pos = j if cur == 0 else pits + 1 + j
        if b[pos] == 0:
            illegal += 1
            continue
        k = b[pos]
        b[pos] = 0
        p = pos
        while k > 0:
            p = (p + 1) % n
            if p == store[1 - cur]:
                continue
            b[p] += 1
            k -= 1
        lo = 0 if cur == 0 else pits + 1
        if lo <= p < lo + pits and b[p] == 1:
            opp = 2 * pits - p
            if b[opp] > 0:
                got = b[opp] + 1
                b[opp] = 0
                b[p] = 0
                b[store[cur]] += got
                took[cur] += got
        s0 = all(b[i] == 0 for i in range(pits))
        s1 = all(b[i] == 0 for i in range(pits + 1, 2 * pits + 1))
        if s0 or s1:
            for i in range(pits):
                b[store[0]] += b[i]
                b[i] = 0
            for i in range(pits + 1, 2 * pits + 1):
                b[store[1]] += b[i]
                b[i] = 0
            ended = True
            break
        if p != store[cur]:
            cur = 1 - cur
    if ended:
        a, c = b[store[0]], b[store[1]]
        w = 0 if a > c else (1 if c > a else 2)
        return (b, -1, illegal, read, took, w)
    return (b, cur, illegal, read, took, -1)
