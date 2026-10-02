def main(starts, ends):
    order = sorted(range(len(starts)), key=lambda k: starts[k])
    ms, me = [], []
    for k in order:
        s, e = starts[k], ends[k]
        if me and s - 1 <= me[-1]:
            if e > me[-1]:
                me[-1] = e
        else:
            ms.append(s)
            me.append(e)
    return ms, me, sum(b - a + 1 for a, b in zip(ms, me))
