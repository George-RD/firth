"""Spreadsheet with ranges, cycle and error detection."""


def main(kinds, xs, ys):
    n = len(kinds)

    def refs(i):
        k, a, b = kinds[i], xs[i], ys[i]
        if k == 0:
            return [], False
        if k <= 3:
            r = [a, b]
        else:
            if a > b:
                return [], True
            r = list(range(a, b + 1))
        bad = any(c < 0 or c >= n for c in r)
        if bad:
            return [], True  # no reference of a bad cell is followed
        return r, False

    edges, base = [], []
    for i in range(n):
        e, bad = refs(i)
        edges.append(e)
        base.append(bad)
    # reach[i]: cells reachable from i in one or more steps
    reach = []
    for i in range(n):
        seen, stack = set(), list(edges[i])
        while stack:
            c = stack.pop()
            if c in seen:
                continue
            seen.add(c)
            stack.extend(edges[c])
        reach.append(seen)
    on_cycle = [c in reach[c] for c in range(n)]
    # a cell is an error if it reaches any cell that lies on a cycle
    for i in range(n):
        if any(on_cycle[c] for c in reach[i]):
            base[i] = True
    err = list(base)
    val = [0] * n
    state = {}

    def ev(i):
        if i in state:
            return
        state[i] = 1
        if base[i]:
            return
        k, a, b = kinds[i], xs[i], ys[i]
        for c in edges[i]:
            ev(c)
        if k == 0:
            val[i] = a
        elif k == 5:
            val[i] = sum(1 for c in edges[i] if not err[c] and val[c] > 0)
        elif any(err[c] for c in edges[i]):
            err[i] = True
        elif k == 1:
            val[i] = val[a] + val[b]
        elif k == 2:
            val[i] = val[a] - val[b]
        elif k == 3:
            if val[b] == 0:
                err[i] = True
            else:
                q = abs(val[a]) // abs(val[b])
                val[i] = q if (val[a] < 0) == (val[b] < 0) else -q
        else:
            val[i] = max(val[c] for c in edges[i])

    for i in range(n):
        ev(i)
    return [0 if err[i] else val[i] for i in range(n)], err
