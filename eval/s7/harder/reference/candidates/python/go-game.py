def main(size, moves):
    N = size * size
    board = [0] * N

    def nbrs(p):
        r, c = divmod(p, size)
        out = []
        if r > 0: out.append(p - size)
        if r < size - 1: out.append(p + size)
        if c > 0: out.append(p - 1)
        if c < size - 1: out.append(p + 1)
        return out

    def group(b, p):
        col = b[p]
        seen = {p}
        st = [p]
        libs = set()
        while st:
            x = st.pop()
            for y in nbrs(x):
                if b[y] == 0:
                    libs.add(y)
                elif b[y] == col and y not in seen:
                    seen.add(y)
                    st.append(y)
        return seen, libs

    took = {1: 0, 2: 0}
    illegal = 0
    read = 0
    player = 1
    history = []  # board before each turn
    passes = 0
    for mv in moves:
        read += 1
        if mv == -1:
            history.append(board[:])
            passes += 1
            player = 3 - player
            if passes >= 2:
                break
            continue
        if board[mv] != 0:
            illegal += 1
            continue
        nb = board[:]
        nb[mv] = player
        opp = 3 - player
        cap = 0
        done = set()
        for y in nbrs(mv):
            if nb[y] == opp and y not in done:
                g, libs = group(nb, y)
                done |= g
                if not libs:
                    for z in g:
                        nb[z] = 0
                    cap += len(g)
        _, libs = group(nb, mv)
        if not libs:
            illegal += 1
            continue
        if history and nb == history[-1]:
            illegal += 1
            continue
        history.append(board[:])
        board = nb
        took[player] += cap
        passes = 0
        player = opp
    area = {1: 0, 2: 0}
    seen = set()
    for p in range(N):
        if board[p]:
            area[board[p]] += 1
        elif p not in seen:
            reg = {p}
            st = [p]
            border = set()
            while st:
                x = st.pop()
                for y in nbrs(x):
                    if board[y] == 0:
                        if y not in reg:
                            reg.add(y)
                            st.append(y)
                    else:
                        border.add(board[y])
            seen |= reg
            if len(border) == 1:
                area[border.pop()] += len(reg)
    return (board, took[1], took[2], illegal, read, area[1] - area[2])
