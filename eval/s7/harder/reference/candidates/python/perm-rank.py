from math import factorial

def main(items, perm, k):
    cnt = [0]*10
    for d in items:
        cnt[d] += 1
    def multi(c):
        r = factorial(sum(c))
        for x in c:
            r //= factorial(x)
        return r
    total = multi(cnt)
    rank = -1
    after = []
    c = cnt[:]
    ok = len(perm) == len(items)
    if ok:
        c2 = [0]*10
        for d in perm:
            if not 0 <= d <= 9:
                ok = False
                break
            c2[d] += 1
        ok = ok and c2 == cnt
    if ok:
        c = cnt[:]
        r = 0
        for d in perm:
            for e in range(d):
                if c[e]:
                    c[e] -= 1
                    r += multi(c)
                    c[e] += 1
            c[d] -= 1
        rank = r
        if r + 1 < total:
            after = unrank(cnt, r + 1, multi)
    kth = unrank(cnt, k, multi) if 0 <= k < total else []
    return (total, rank, kth, after)

def unrank(cnt, k, multi):
    c = cnt[:]
    out = []
    for _ in range(sum(cnt)):
        for e in range(10):
            if c[e]:
                c[e] -= 1
                m = multi(c)
                if k < m:
                    out.append(e)
                    break
                k -= m
                c[e] += 1
    return out
