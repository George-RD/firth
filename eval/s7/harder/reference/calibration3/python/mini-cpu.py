"""Small 32-bit processor simulator."""

MAX_STEPS = 300
DATA_STACK_LIMIT = 16
CALL_STACK_LIMIT = 8
MEM_SIZE = 64


def wrap(x):
    return (x + 2**31) % 2**32 - 2**31


def trunc_div(a, b):
    q = abs(a) // abs(b)
    return q if (a >= 0) == (b >= 0) else -q


def main(ops, fa, fb, fc, regs, memory, inputs):
    n = len(ops)
    regs = list(regs)
    mem = list(memory)
    z = neg = v = False
    data, calls, out = [], [], []
    in_pos = 0
    pc = 0
    executed = 0
    status = 0

    def set_flags(t):
        nonlocal z, neg, v
        w = wrap(t)
        z, neg, v = (w == 0), (w < 0), (w != t)
        return w

    while True:
        if executed == MAX_STEPS:
            status = 1
            break
        if not 0 <= pc < n:
            status = 2
            break
        op, a, b, c = ops[pc], fa[pc], fb[pc], fc[pc]
        next_pc = pc + 1
        fault = 0

        if op == 0:
            executed += 1
            status = 0
            break
        elif op == 1:
            regs[a] = b
        elif op == 2:
            regs[a] = regs[b]
        elif op in (3, 4, 5, 8, 9, 10, 11):
            x = regs[b]
            y = regs[c] if op in (3, 4, 5, 11) else 0   # a shift's c is a count, not a register
            if op == 3:
                t = x + y
            elif op == 4 or op == 11:
                t = x - y
            elif op == 5:
                t = x * y
            elif op == 8:
                t = -x
            elif op == 9:
                t = x * 2**c
            else:
                t = x >> c
            w = set_flags(t)
            if op != 11:
                regs[a] = w
        elif op in (6, 7):
            x, y = regs[b], regs[c]
            if y == 0:
                fault = 3
            else:
                q = trunc_div(x, y)
                regs[a] = set_flags(q if op == 6 else x - q * y)
        elif op in (12, 13):
            addr = regs[b] + c
            if not 0 <= addr < MEM_SIZE:
                fault = 6
            elif op == 12:
                regs[a] = mem[addr]
            else:
                mem[addr] = regs[a]
        elif op == 14:
            next_pc = b
        elif op == 15:
            if z:
                next_pc = b
        elif op == 16:
            if not z:
                next_pc = b
        elif op == 17:
            if neg != v:
                next_pc = b
        elif op == 18:
            if neg == v:
                next_pc = b
        elif op == 19:
            if len(data) >= DATA_STACK_LIMIT:
                fault = 4
            else:
                data.append(regs[a])
        elif op == 20:
            if not data:
                fault = 5
            else:
                regs[a] = data.pop()
        elif op == 21:
            if len(calls) >= CALL_STACK_LIMIT:
                fault = 4
            else:
                calls.append(pc + 1)
                next_pc = b
        elif op == 22:
            if not calls:
                fault = 5
            else:
                next_pc = calls.pop()
        elif op == 23:
            if in_pos >= len(inputs):
                fault = 7
            else:
                regs[a] = inputs[in_pos]
                in_pos += 1
        elif op == 24:
            out.append(regs[a])

        if fault:
            status = fault
            break
        executed += 1
        pc = next_pc

    return out, status, executed, pc, regs, mem, [z, neg, v]
