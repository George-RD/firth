def main(data):
    n = len(data)
    pos = 0
    F, W, V = [], [], []

    def varint(p):
        # returns (value, newpos, err)
        v = 0
        j = 0
        while True:
            if p + j >= n:
                return 0, p, 1
            b = data[p + j]
            v += (b % 128) * 128 ** j
            if b < 128:
                if j > 0 and b == 0:
                    return 0, p, 2
                return v, p + j + 1, 0
            j += 1
            if j == 8:
                return 0, p, 3

    while pos < n:
        start = pos
        tag, p, e = varint(pos)
        if e:
            return (F, W, V, e, start)
        field, wt = tag // 8, tag % 8
        if field == 0:
            return (F, W, V, 4, start)
        if wt not in (0, 1, 2, 5):
            return (F, W, V, 5, start)
        if wt == 0:
            val, p, e = varint(p)
        elif wt == 1:
            u, p, e = varint(p)
            val = u // 2 if u % 2 == 0 else -(u + 1) // 2
        elif wt == 2:
            L, p, e = varint(p)
            if not e:
                if p + L > n:
                    e = 1
                else:
                    p += L
                    val = L
        else:
            if p + 4 > n:
                e = 1
            else:
                val = data[p] + 256*data[p+1] + 65536*data[p+2] + 16777216*data[p+3]
                p += 4
        if e:
            return (F, W, V, e, start)
        F.append(field); W.append(wt); V.append(val)
        pos = p
    return (F, W, V, 0, -1)
