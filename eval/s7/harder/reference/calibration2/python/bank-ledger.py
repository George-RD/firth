"""Bank ledger with freezing, overdraft fee and month-end interest."""


def main(balances, limit, kinds, accts, others, amounts):
    bal = list(balances)
    n = len(bal)
    rej = [0] * n
    frozen = [False] * n
    rejected = 0
    for k, a, b, amt in zip(kinds, accts, others, amounts):
        if k == 4:
            for i in range(n):
                v = bal[i]
                if v < 0:
                    bal[i] = v - (-v + 9) // 10
                elif v >= 100:
                    bal[i] = v + v // 100
            continue
        bad = frozen[a]
        if k == 3 and (frozen[b] or a == b):
            bad = True
        if k in (2, 3) and bal[a] - amt < -limit:
            bad = True
        if bad:
            rejected += 1
            rej[a] += 1
            if rej[a] >= 3:
                frozen[a] = True
            continue
        if k == 1:
            bal[a] += amt
        else:
            before = bal[a]
            bal[a] -= amt
            if k == 3:
                bal[b] += amt
            if before >= 0 and bal[a] < 0:
                bal[a] -= 5
    return bal, rejected, frozen
