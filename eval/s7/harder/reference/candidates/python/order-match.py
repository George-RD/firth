def main(kind, side, price, qty, trader, tif):
    n = len(kind)
    book = {}  # id -> [side, price, qty, trader]
    trades = vol = notional = selfc = cancels = rejected = killed = 0
    for i in range(n):
        k = kind[i]
        if k == 2:
            oid = price[i]
            if oid in book:
                del book[oid]
                cancels += 1
            else:
                rejected += 1
            continue
        s = side[i]
        p = price[i]
        q = qty[i]
        t = trader[i]

        def can(o):
            if o[0] == s:
                return False
            if k == 1:
                return True
            return o[1] <= p if s == 0 else o[1] >= p

        if tif[i] == 2:
            tot = sum(o[2] for o in book.values() if can(o) and o[3] != t)
            if tot < q:
                killed += 1
                continue
        while q > 0:
            cands = [(oid, o) for oid, o in book.items() if can(o)]
            if not cands:
                break
            if s == 0:
                oid, o = min(cands, key=lambda x: (x[1][1], x[0]))
            else:
                oid, o = min(cands, key=lambda x: (-x[1][1], x[0]))
            if o[3] == t:
                selfc += o[2]
                del book[oid]
                continue
            m = min(q, o[2])
            trades += 1
            vol += m
            notional += m * o[1]
            q -= m
            o[2] -= m
            if o[2] == 0:
                del book[oid]
        if k == 0 and tif[i] == 0 and q > 0:
            book[i] = [s, p, q, t]
    buys = sorted((x for x in book.items() if x[1][0] == 0), key=lambda x: (-x[1][1], x[0]))
    sells = sorted((x for x in book.items() if x[1][0] == 1), key=lambda x: (x[1][1], x[0]))
    rest = buys + sells
    return (trades, vol, notional, selfc, cancels, rejected, killed,
            [x[0] for x in rest], [x[1][2] for x in rest])
