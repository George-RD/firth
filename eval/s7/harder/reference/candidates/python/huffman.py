def main(freqs, msg):
    n = len(freqs)
    lengths = [0] * n
    codes = [-1] * n
    syms = [s for s in range(n) if freqs[s] > 0]
    if len(syms) == 1:
        lengths[syms[0]] = 1
    elif len(syms) > 1:
        nodes = [(freqs[s], s, [s]) for s in syms]
        while len(nodes) > 1:
            nodes.sort(key=lambda x: (x[0], x[1]))
            a = nodes.pop(0)
            b = nodes.pop(0)
            for s in a[2] + b[2]:
                lengths[s] += 1
            nodes.append((a[0] + b[0], min(a[1], b[1]), a[2] + b[2]))
    order = sorted((s for s in range(n) if lengths[s] > 0), key=lambda s: (lengths[s], s))
    code = 0
    prev = None
    for s in order:
        if prev is None:
            code = 0
        else:
            code = (code + 1) << (lengths[s] - lengths[prev])
        codes[s] = code
        prev = s
    bits = []
    for i, v in enumerate(msg):
        if not (0 <= v < n) or lengths[v] == 0:
            return (lengths, codes, [], i)
        L = lengths[v]
        bits.extend((codes[v] >> k) & 1 for k in range(L - 1, -1, -1))
    return (lengths, codes, bits, -1)
