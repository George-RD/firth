"""First-fit-by-smallest-block memory allocator."""


def _blocks(free):
    out, i, n = [], 0, len(free)
    while i < n:
        if free[i]:
            j = i
            while j < n and free[j]:
                j += 1
            out.append((i, j - i))
            i = j
        else:
            i += 1
    return out


def main(size, kinds, vals):
    free = [True] * size
    results = []
    alloc = {}  # op index -> (start, length) while live
    for i, (k, v) in enumerate(zip(kinds, vals)):
        if k == 0:
            fit = [(ln, st) for st, ln in _blocks(free) if ln >= v]
            if not fit:
                results.append(-1)
                continue
            _, st = min(fit)
            for c in range(st, st + v):
                free[c] = False
            alloc[i] = (st, v)
            results.append(st)
        else:
            if v in alloc:
                st, ln = alloc.pop(v)
                for c in range(st, st + ln):
                    free[c] = True
                results.append(0)
            else:
                results.append(-1)
    bl = _blocks(free)
    return results, len(bl), max((ln for _, ln in bl), default=0)
