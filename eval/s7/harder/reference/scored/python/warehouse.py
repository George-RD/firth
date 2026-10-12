def solve(days, price, rp, rq, lead, shelf, ev_day, ev_kind, ev_prod, ev_qty, ev_expiry):
    P = len(price)
    lots = [[] for _ in range(P)]  # each [qty, expiry, seq]
    backs = [[] for _ in range(P)]  # each [owed, placed_day]
    due = [None] * P
    seq = [0]
    earned = shipped = discarded = cancelled = supplies = 0

    def stock(p):
        return sum(l[0] for l in lots[p])

    def take(p, q):
        nonlocal earned, shipped
        got = 0
        lots[p].sort(key=lambda l: (l[1], l[2]))
        while q > 0 and lots[p]:
            lot = lots[p][0]
            k = min(q, lot[0])
            lot[0] -= k
            q -= k
            got += k
            if lot[0] == 0:
                lots[p].pop(0)
        shipped += got
        earned += got * price[p]
        return got

    def arrive(p, qty, expiry):
        seq[0] += 1
        lots[p].append([qty, expiry, seq[0]])
        while backs[p] and stock(p) > 0:
            b = backs[p][0]
            b[0] -= take(p, min(b[0], stock(p)))
            if b[0] == 0:
                backs[p].pop(0)

    for d in range(days):
        for p in range(P):
            kept = []
            for l in lots[p]:
                if l[1] < d:
                    discarded += l[0]
                else:
                    kept.append(l)
            lots[p] = kept
        for p in range(P):
            if due[p] == d:
                due[p] = None
                arrive(p, rq[p], d + shelf[p])
        for e in range(len(ev_day)):
            if ev_day[e] != d:
                continue
            p, q = ev_prod[e], ev_qty[e]
            if ev_kind[e] == 1:
                arrive(p, q, ev_expiry[e])
            else:
                if backs[p]:
                    backs[p].append([q, d])
                else:
                    got = take(p, min(q, stock(p)))
                    if q - got > 0:
                        backs[p].append([q - got, d])
        for p in range(P):
            keep = []
            for b in backs[p]:
                if b[1] <= d - 7:
                    cancelled += b[0]
                else:
                    keep.append(b)
            backs[p] = keep
        for p in range(P):
            if due[p] is None and stock(p) <= rp[p]:
                due[p] = d + lead[p]
                supplies += 1
    owed = sum(b[0] for p in range(P) for b in backs[p])
    return ([stock(p) for p in range(P)], earned, shipped, discarded, cancelled, supplies, owed)


main = solve
