"""Compare two five-card poker hands."""


def _analyse(ranks, suits):
    flush = len(set(suits)) == 1
    rs = sorted(ranks)
    straight_high = 0
    if len(set(rs)) == 5:
        if rs[4] - rs[0] == 4:
            straight_high = rs[4]
        elif rs == [2, 3, 4, 5, 14]:
            straight_high = 5
    counts = {}
    for r in ranks:
        counts[r] = counts.get(r, 0) + 1
    groups = sorted(((n, r) for r, n in counts.items()), reverse=True)
    sizes = [n for n, _ in groups]
    if straight_high and flush:
        cat = 8
    elif sizes[0] == 4:
        cat = 7
    elif sizes == [3, 2]:
        cat = 6
    elif flush:
        cat = 5
    elif straight_high:
        cat = 4
    elif sizes[0] == 3:
        cat = 3
    elif sizes == [2, 2, 1]:
        cat = 2
    elif sizes[0] == 2:
        cat = 1
    else:
        cat = 0
    if cat in (4, 8):
        key = [straight_high]
    else:
        key = [r for _, r in groups]
    return cat, key


def main(ranks1, suits1, ranks2, suits2):
    c1, k1 = _analyse(ranks1, suits1)
    c2, k2 = _analyse(ranks2, suits2)
    if (c1, k1) > (c2, k2):
        w = 1
    elif (c1, k1) < (c2, k2):
        w = 2
    else:
        w = 0
    return w, c1, c2
