def main(code, regs, limit):
    r = list(regs)
    count = len(code) // 3
    pc = executed = 0
    while 0 <= pc < count:
        if executed >= limit:
            return r, executed, 2
        op, a, b = code[3 * pc], code[3 * pc + 1], code[3 * pc + 2]
        executed += 1
        nxt = pc + 1
        if op == 0:
            return r, executed, 0
        elif op == 1:
            r[a] = b
        elif op == 2:
            r[a] = r[a] + r[b]
        elif op == 3:
            r[a] = r[a] - r[b]
        elif op == 4:
            r[a] = r[a] * r[b]
        elif op == 5:
            r[a] = r[b]
        elif op == 6 and r[a] != 0:
            nxt = b
        elif op == 7 and r[a] < 0:
            nxt = b
        pc = nxt
    return r, executed, 1
