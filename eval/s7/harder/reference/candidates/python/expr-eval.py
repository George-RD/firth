def main(kinds, vals):
    LIM = 10**12
    class Syn(Exception):
        pass
    class Err(Exception):
        def __init__(self, c):
            self.c = c

    def parse(t):
        pos = [0]
        def peek():
            return t[pos[0]] if pos[0] < len(t) else None
        def sym(x):
            return peek() == (2, x)
        def expr():
            if pos[0] + 1 < len(t) and t[pos[0]][0] == 1 and t[pos[0] + 1] == (2, 9):
                v = t[pos[0]][1]
                pos[0] += 2
                return ('as', v, expr())
            return sumx()
        def sumx():
            n = prod()
            while sym(1) or sym(2):
                op = t[pos[0]][1]; pos[0] += 1
                n = ('bin', op, n, prod())
            return n
        def prod():
            n = factor()
            while sym(3) or sym(4) or sym(5):
                op = t[pos[0]][1]; pos[0] += 1
                n = ('bin', op, n, factor())
            return n
        def factor():
            if sym(2):
                pos[0] += 1
                return ('neg', factor())
            return power()
        def power():
            a = atom()
            if sym(6):
                pos[0] += 1
                return ('bin', 6, a, factor())
            return a
        def atom():
            p = peek()
            if p is None:
                raise Syn()
            if p[0] == 0:
                pos[0] += 1
                return ('num', p[1])
            if p[0] == 1:
                pos[0] += 1
                return ('var', p[1])
            if p == (2, 7):
                pos[0] += 1
                e = expr()
                if not sym(8):
                    raise Syn()
                pos[0] += 1
                return e
            raise Syn()
        e = expr()
        if pos[0] != len(t):
            raise Syn()
        return e

    env = [None] * 8

    def chk(v):
        if v > LIM or v < -LIM:
            raise Err(5)
        return v

    def ev(n):
        k = n[0]
        if k == 'num':
            return n[1]
        if k == 'var':
            if env[n[1]] is None:
                raise Err(2)
            return env[n[1]]
        if k == 'as':
            v = ev(n[2]); env[n[1]] = v
            return v
        if k == 'neg':
            return chk(-ev(n[1]))
        op = n[1]
        a = ev(n[2]); b = ev(n[3])
        if op == 1:
            return chk(a + b)
        if op == 2:
            return chk(a - b)
        if op == 3:
            return chk(a * b)
        if op in (4, 5):
            if b == 0:
                raise Err(3)
            q = abs(a) // abs(b)
            if (a < 0) != (b < 0):
                q = -q
            return chk(q if op == 4 else a - b * q)
        if b < 0:
            raise Err(4)
        if b == 0 or a == 1:
            return 1
        if a == 0:
            return 0
        if a == -1:
            return -1 if b % 2 else 1
        if b > 45:
            raise Err(5)
        return chk(a ** b)

    stmts, cur = [], []
    for kd, v in zip(kinds, vals):
        if kd == 2 and v == 10:
            stmts.append(cur); cur = []
        else:
            cur.append((kd, v))
    stmts.append(cur)
    values, codes = [], []
    for s in stmts:
        if not s:
            continue
        try:
            tree = parse(s)
        except Syn:
            values.append(0); codes.append(1); continue
        try:
            values.append(ev(tree)); codes.append(0)
        except Err as e:
            values.append(0); codes.append(e.c)
    return (values, codes, [0 if x is None else x for x in env], [x is not None for x in env])
