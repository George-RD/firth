def main(ops, args, limit):
    n = len(ops)
    data = []
    calls = []
    handlers = []
    pc = 0
    steps = 0
    caught = 0
    deepest = 0
    status = 0
    uncaught = 0
    LIM = 1000000000
    while True:
        if pc < 0 or pc >= n:
            status = 0
            break
        if steps >= limit:
            status = 2
            break
        op = ops[pc]
        a = args[pc]
        steps += 1
        nxt = pc + 1
        thrown = None
        if op == 0:
            if len(data) >= 32:
                thrown = 4
            else:
                data.append(a)
        elif 1 <= op <= 5:
            if len(data) < 2:
                thrown = 2
            else:
                r = data[-1]
                l = data[-2]
                if op == 1:
                    v = l + r
                elif op == 2:
                    v = l - r
                elif op == 3:
                    v = l * r
                else:
                    if r == 0:
                        thrown = 1
                        v = None
                    else:
                        q = abs(l) // abs(r)
                        if (l < 0) != (r < 0):
                            q = -q
                        v = q if op == 4 else l - r * q
                if thrown is None:
                    if v > LIM or v < -LIM:
                        thrown = 6
                    else:
                        data.pop(); data.pop()
                        data.append(v)
        elif op == 6:
            if len(data) < 1:
                thrown = 2
            elif len(data) >= 32:
                thrown = 4
            else:
                data.append(data[-1])
        elif op == 7:
            if len(data) < 2:
                thrown = 2
            else:
                data[-1], data[-2] = data[-2], data[-1]
        elif op == 8:
            if len(data) < 1:
                thrown = 2
            else:
                data.pop()
        elif op == 9:
            nxt = a
        elif op == 10:
            if len(data) < 1:
                thrown = 2
            else:
                if data.pop() == 0:
                    nxt = a
        elif op == 11:
            if len(calls) >= 16:
                thrown = 4
            else:
                calls.append(pc + 1)
                nxt = a
        elif op == 12:
            if not calls:
                status = 0
                break
            nxt = calls.pop()
        elif op == 13:
            if len(handlers) >= 8:
                thrown = 4
            else:
                handlers.append((a, len(data), len(calls)))
        elif op == 14:
            if not handlers:
                thrown = 3
            else:
                handlers.pop()
        elif op == 15:
            if len(data) < 1:
                thrown = 2
            else:
                thrown = data.pop()
        elif op == 16:
            status = 0
            break
        if thrown is not None:
            if not handlers:
                status = 1
                uncaught = thrown
                break
            t, dl, cl = handlers.pop()
            if len(data) > dl:
                del data[dl:]
            if len(calls) > cl:
                del calls[cl:]
            data.append(thrown)
            caught += 1
            nxt = t
        if len(data) > deepest:
            deepest = len(data)
        pc = nxt
    return (list(data), status, uncaught, steps, caught, deepest)
