def solve(pattern, lens, chars):
    toks = list(pattern)
    n = len(toks)
    pos = [0]

    def peek():
        return toks[pos[0]] if pos[0] < n else None

    class Bad(Exception):
        pass

    def parse_alt():
        seqs = [parse_seq()]
        while peek() == 30:
            pos[0] += 1
            seqs.append(parse_seq())
        return ('alt', seqs)

    def parse_seq():
        items = []
        while peek() is not None and peek() not in (30, 32):
            items.append(parse_item())
        return ('seq', items)

    def parse_item():
        t = peek()
        if t <= 25:
            node = ('lit', t)
            pos[0] += 1
        elif t == 26:
            node = ('any',)
            pos[0] += 1
        elif t == 31:
            pos[0] += 1
            node = parse_alt()
            if peek() != 32:
                raise Bad()
            pos[0] += 1
        else:
            raise Bad()
        while peek() in (27, 28, 29):
            node = ({27: 'star', 28: 'plus', 29: 'opt'}[peek()], node)
            pos[0] += 1
        return node

    try:
        tree = parse_alt()
        if pos[0] != n:
            raise Bad()
    except Bad:
        return ([False] * len(lens), [-1] * len(lens), 0, False)

    def ends(node, s, starts):
        # set of end positions reachable by matching node from any start in starts
        k = node[0]
        if k == 'lit':
            return {i + 1 for i in starts if i < len(s) and s[i] == node[1]}
        if k == 'any':
            return {i + 1 for i in starts if i < len(s)}
        if k == 'alt':
            out = set()
            for sq in node[1]:
                out |= ends(sq, s, starts)
            return out
        if k == 'seq':
            cur = set(starts)
            for it in node[1]:
                cur = ends(it, s, cur)
            return cur
        if k == 'opt':
            return set(starts) | ends(node[1], s, starts)
        if k in ('star', 'plus'):
            result = set(starts) if k == 'star' else set()
            frontier = ends(node[1], s, starts)
            while frontier - result:
                new = frontier - result
                result |= new
                frontier = ends(node[1], s, new)
            return result
        raise ValueError(k)

    full, longest = [], []
    off = 0
    for L in lens:
        s = chars[off:off + L]
        off += L
        e = ends(tree, s, {0})
        full.append(L in e)
        longest.append(max(e) if e else -1)
    return (full, longest, sum(full), True)


main = solve
