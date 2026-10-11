def main(points, bestOf, finalSet, noAd, server):
    need = bestOf // 2 + 1
    wins = [0, 0]
    sets = [[0, 0]]
    cur = [0, 0]
    gs = server          # server of the current game / first server of tiebreak
    tb = False
    tb_first = 0
    mode_target = 7
    breaks = [0, 0]
    read = 0
    winner = -1

    def deciding():
        return len(sets) == bestOf

    def start_set():
        nonlocal tb, mode_target
        sets.append([0, 0])
        if deciding() and finalSet == 2:
            tb = True
            mode_target = 10
        return

    # initial set may itself be a match tiebreak only if bestOf==1 (not possible)
    for p in points:
        if winner != -1:
            break
        read += 1
        q = 1 - p
        cur[p] += 1
        s = sets[-1]
        if tb:
            if cur[p] >= mode_target and cur[p] - cur[q] >= 2:
                if mode_target == 10 and deciding() and finalSet == 2:
                    s[0], s[1] = cur[0], cur[1]
                else:
                    s[p] = 7
                    s[q] = 6
                wins[p] += 1
                cur = [0, 0]
                tb = False
                gs = 1 - tb_first
                if wins[p] >= need:
                    winner = p
                else:
                    start_set()
                    if tb:
                        tb_first = gs
            else:
                s[0], s[1] = (cur[0], cur[1]) if (mode_target == 10) else (s[0], s[1])
            continue
        # normal game
        if noAd:
            gw = cur[p] >= 4
        else:
            gw = cur[p] >= 4 and cur[p] - cur[q] >= 2
        if not gw:
            continue
        if p != gs:
            breaks[p] += 1
        cur = [0, 0]
        gs = 1 - gs
        s[p] += 1
        if s[p] >= 6 and s[p] - s[q] >= 2:
            wins[p] += 1
            if wins[p] >= need:
                winner = p
            else:
                start_set()
                if tb:
                    tb_first = gs
        elif s[0] == 6 and s[1] == 6 and not (deciding() and finalSet == 1):
            tb = True
            mode_target = 7
            tb_first = gs
    flat = []
    for s in sets:
        flat.extend(s)
    if winner != -1:
        return (flat, winner, read, [0, 0], -1, breaks)
    if tb:
        k = cur[0] + cur[1]
        ns = tb_first if ((k + 1) // 2) % 2 == 0 else 1 - tb_first
    else:
        ns = gs
    return (flat, -1, read, list(cur), ns, breaks)
