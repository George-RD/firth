def solve(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]  # each set: list of [block, dirty], LRU first
    L2 = [[] for _ in range(s2)]
    h1 = m1 = h2 = m2 = reads = mwrites = 0

    def find(level, a, nsets):
        for e in level[a % nsets]:
            if e[0] == a:
                return e
        return None

    def use(level, e, a, nsets):
        st = level[a % nsets]
        st.remove(e)
        st.append(e)

    def put(level, a, dirty, nsets, ways):
        # returns evicted entry or None
        st = level[a % nsets]
        ev = None
        if len(st) >= ways:
            ev = st.pop(0)
        st.append([a, dirty])
        return ev

    for a, w in zip(addrs, writes):
        e = find(L1, a, s1)
        if e is not None:
            h1 += 1
            use(L1, e, a, s1)
            if w:
                e[1] = True
            continue
        m1 += 1
        e2 = find(L2, a, s2)
        if e2 is not None:
            h2 += 1
            use(L2, e2, a, s2)
        else:
            m2 += 1
            reads += 1
            ev = put(L2, a, False, s2, w2)
            if ev is not None and ev[1]:
                mwrites += 1
        ev = put(L1, a, bool(w), s1, w1)
        if ev is not None and ev[1]:
            b = ev[0]
            eb = find(L2, b, s2)
            if eb is not None:
                use(L2, eb, b, s2)
                eb[1] = True
            else:
                ev2 = put(L2, b, True, s2, w2)
                if ev2 is not None and ev2[1]:
                    mwrites += 1
    dirty = sum(1 for lv in (L1, L2) for st in lv for e in st if e[1])
    blocks = [e[0] for st in L1 for e in st]
    return (h1, m1, h2, m2, reads, mwrites, dirty, blocks)


main = solve
