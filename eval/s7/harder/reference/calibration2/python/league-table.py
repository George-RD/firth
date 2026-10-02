"""League table with a one-off head-to-head tie-break per tied group."""


def main(n, homes, aways, hg, ag):
    pts = [0] * n
    gf = [0] * n
    ga = [0] * n
    for h, a, x, y in zip(homes, aways, hg, ag):
        gf[h] += x
        ga[h] += y
        gf[a] += y
        ga[a] += x
        if x > y:
            pts[h] += 3
        elif x < y:
            pts[a] += 3
        else:
            pts[h] += 1
            pts[a] += 1
    key = lambda t: (pts[t], gf[t] - ga[t], gf[t])
    teams = sorted(range(n), key=lambda t: (tuple(-v for v in key(t)), t))
    order = []
    i = 0
    while i < n:
        j = i
        while j < n and key(teams[j]) == key(teams[i]):
            j += 1
        group = teams[i:j]
        h2h = {t: 0 for t in group}
        for h, a, x, y in zip(homes, aways, hg, ag):
            if h in h2h and a in h2h:
                if x > y:
                    h2h[h] += 3
                elif x < y:
                    h2h[a] += 3
                else:
                    h2h[h] += 1
                    h2h[a] += 1
        order += sorted(group, key=lambda t: (-h2h[t], t))
        i = j
    return order, pts
