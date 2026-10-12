def main(ops, keys):
    # node: [key, left, right, height]
    rot = [0]

    def h(n):
        return n[3] if n else 0

    def upd(n):
        n[3] = 1 + max(h(n[1]), h(n[2]))

    def bal(n):
        return h(n[1]) - h(n[2])

    def rr(n):
        c = n[1]
        n[1] = c[2]
        c[2] = n
        upd(n)
        upd(c)
        rot[0] += 1
        return c

    def rl(n):
        c = n[2]
        n[2] = c[1]
        c[1] = n
        upd(n)
        upd(c)
        rot[0] += 1
        return c

    def rebalance(n):
        upd(n)
        b = bal(n)
        if b == 2:
            if bal(n[1]) < 0:
                n[1] = rl(n[1])
            n = rr(n)
        elif b == -2:
            if bal(n[2]) > 0:
                n[2] = rr(n[2])
            n = rl(n)
        return n

    def ins(n, k):
        if n is None:
            return [k, None, None, 1]
        if k < n[0]:
            n[1] = ins(n[1], k)
        else:
            n[2] = ins(n[2], k)
        return rebalance(n)

    def dele(n, k):
        if k < n[0]:
            n[1] = dele(n[1], k)
        elif k > n[0]:
            n[2] = dele(n[2], k)
        else:
            if n[1] is None:
                return n[2]
            if n[2] is None:
                return n[1]
            m = n[2]
            while m[1]:
                m = m[1]
            n[0] = m[0]
            n[2] = dele(n[2], m[0])
        return rebalance(n)

    def has(n, k):
        while n:
            if k == n[0]:
                return True
            n = n[1] if k < n[0] else n[2]
        return False

    root = None
    found = []
    ignored = 0
    for o, k in zip(ops, keys):
        if o == 0:
            if has(root, k):
                ignored += 1
            else:
                root = ins(root, k)
        elif o == 1:
            if not has(root, k):
                ignored += 1
            else:
                root = dele(root, k)
        else:
            found.append(has(root, k))
    pre = []

    def walk(n):
        if n:
            pre.append(n[0])
            walk(n[1])
            walk(n[2])

    walk(root)
    return (pre, found, rot[0], ignored, h(root))
