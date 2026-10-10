def solve(board, turn, plies):
    board = list(board)

    def pos(i):
        r = i // 4
        return r, 2 * (i % 4) + (1 if r % 2 == 0 else 0)

    sq = {}
    for i in range(32):
        sq[pos(i)] = i

    def side(p):
        return 0 if p in (1, 2) else 1

    def dirs(p):
        if p in (2, 4):
            return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        return [(-1, -1), (-1, 1)] if p == 1 else [(1, -1), (1, 1)]

    def far_row(s):
        return 0 if s == 0 else 7

    def jumps_from(b, i, p):
        # list of (over_square, landing_square) available to piece p at i
        out = []
        r, c = pos(i)
        for dr, dc in dirs(p):
            o = sq.get((r + dr, c + dc))
            l = sq.get((r + 2 * dr, c + 2 * dc))
            if o is None or l is None:
                continue
            if b[o] != 0 and side(b[o]) != side(p) and b[l] == 0:
                out.append((o, l))
        return out

    def captures(b, s):
        # all complete captures: (count, start, landings, final_square, crowned)
        results = []
        for i in range(32):
            p = b[i]
            if p == 0 or side(p) != s:
                continue

            def dfs(cur, piece, path, taken):
                js = jumps_from(b, cur, piece)
                if not js:
                    results.append((len(taken), i, tuple(path), tuple(taken), piece))
                    return
                for o, l in js:
                    saved = b[o]
                    b[o] = 0
                    nl = pos(l)[0]
                    if piece in (1, 3) and nl == far_row(s):
                        results.append((len(taken) + 1, i, tuple(path + [l]),
                                        tuple(taken + [o]), piece + 1))
                    else:
                        dfs(l, piece, path + [l], taken + [o])
                    b[o] = saved

            b[i] = 0
            dfs(i, p, [], [])
            b[i] = p
        return [r for r in results if r[0] > 0]

    def steps(b, s):
        out = []
        for i in range(32):
            p = b[i]
            if p == 0 or side(p) != s:
                continue
            r, c = pos(i)
            for dr, dc in dirs(p):
                t = sq.get((r + dr, c + dc))
                if t is not None and b[t] == 0:
                    out.append((i, t))
        return out

    played = 0
    took = [0, 0]
    crowned = 0
    result = 0
    s = turn
    while True:
        caps = captures(board, s)
        sts = [] if caps else steps(board, s)
        if not caps and not sts:
            result = 2 if s == 0 else 1
            break
        if played == plies:
            break
        if caps:
            best = min(caps, key=lambda x: (-x[0], x[1], x[2]))
            n, start, path, taken, final = best
            p = board[start]
            board[start] = 0
            for o in taken:
                board[o] = 0
            board[path[-1]] = final
            took[s] += n
            if final != p:
                crowned += 1
        else:
            i, t = min(sts)
            p = board[i]
            board[i] = 0
            if p in (1, 3) and pos(t)[0] == far_row(s):
                board[t] = p + 1
                crowned += 1
            else:
                board[t] = p
        played += 1
        s = 1 - s
    return (board, played, took[0], took[1], crowned, result)


main = solve
