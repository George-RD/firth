### task: checkers
```python
def main(board, turn, plies):
    dirs = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def to_index(r, c):
        if r < 0 or r >= 8 or c < 0 or c >= 8:
            return -1
        if (r + c) % 2 != 1:
            return -1
        if r % 2 == 0:
            if c % 2 != 1:
                return -1
            k = (c - 1) // 2
        else:
            if c % 2 != 0:
                return -1
            k = c // 2
        return r * 4 + k

    neighbor = [[-1] * 4 for _ in range(32)]
    for s in range(32):
        r = s // 4
        c = 2 * (s % 4) + (1 if r % 2 == 0 else 0)
        for di, (dr, dc) in enumerate(dirs):
            neighbor[s][di] = to_index(r + dr, c + dc)

    def dir_index(dr, dc):
        if dr == -1 and dc == -1: return 0
        if dr == -1 and dc == 1: return 1
        if dr == 1 and dc == -1: return 2
        if dr == 1 and dc == 1: return 3
        return -1

    def generate_captures(b, side):
        results = []
        for s in range(32):
            val = b[s]
            if side == 0:
                if val not in (1, 2): continue
            else:
                if val not in (3, 4): continue

            def explore(nb, cur, piece, captured, landings, jumps):
                found = False
                if piece == 1:
                    drs = [-1]
                elif piece == 3:
                    drs = [1]
                else:
                    drs = [-1, 1]
                for dr in drs:
                    for dc in [-1, 1]:
                        di = dir_index(dr, dc)
                        m = neighbor[cur][di]
                        if m == -1: continue
                        if side == 0:
                            if nb[m] not in (3, 4): continue
                        else:
                            if nb[m] not in (1, 2): continue
                        l = neighbor[m][di]
                        if l == -1: continue
                        if nb[l] != 0: continue
                        found = True
                        nnb = nb[:]
                        nnb[cur] = 0
                        nnb[m] = 0
                        new_piece = piece
                        promoted = False
                        if piece == 1 and l < 4:
                            new_piece = 2
                            promoted = True
                        elif piece == 3 and l >= 28:
                            new_piece = 4
                            promoted = True
                        nnb[l] = new_piece
                        new_landings = landings + [l]
                        new_jumps = jumps + [(cur, m, l, promoted)]
                        if promoted:
                            results.append((captured + 1, s, new_landings, new_jumps, nnb, True))
                        else:
                            explore(nnb, l, new_piece, captured + 1, new_landings, new_jumps)
                if not found and captured > 0:
                    results.append((captured, s, landings, jumps, nb, False))

            explore(b, s, val, 0, [], [])
        return results

    def generate_steps(b, side):
        steps = []
        for s in range(32):
            val = b[s]
            if side == 0:
                if val not in (1, 2): continue
            else:
                if val not in (3, 4): continue
            if val == 1:
                drs = [-1]
            elif val == 3:
                drs = [1]
            else:
                drs = [-1, 1]
            for dr in drs:
                for dc in [-1, 1]:
                    di = dir_index(dr, dc)
                    t = neighbor[s][di]
                    if t != -1 and b[t] == 0:
                        steps.append((s, t))
        return steps

    board = board[:]
    played = 0
    white_took = 0
    black_took = 0
    crowned = 0
    result = 0

    while True:
        captures = generate_captures(board, turn)
        if captures:
            if played >= plies:
                result = 0
                break
            max_cap = max(c[0] for c in captures)
            cand = [c for c in captures if c[0] == max_cap]
            chosen = min(cand, key=lambda c: (c[1], c[2]))
            captured, start, landings, jumps, new_board, promoted = chosen
            board = new_board[:]
            if turn == 0:
                white_took += captured
            else:
                black_took += captured
            if promoted:
                crowned += 1
            played += 1
            turn = 1 - turn
        else:
            steps = generate_steps(board, turn)
            if not steps:
                result = 2 if turn == 0 else 1
                break
            if played >= plies:
                result = 0
                break
            chosen = min(steps, key=lambda x: (x[0], x[1]))
            s, t = chosen
            val = board[s]
            board[s] = 0
            new_val = val
            if val == 1 and t < 4:
                new_val = 2
                crowned += 1
            elif val == 3 and t >= 28:
                new_val = 4
                crowned += 1
            board[t] = new_val
            played += 1
            turn = 1 - turn

    return (board, played, white_took, black_took, crowned, result)
```

### task: cache-sim
```python
def main(s1, w1, s2, w2, addrs, writes):
    L1 = [[] for _ in range(s1)]
    L2 = [[] for _ in range(s2)]
    l1_hits = l1_misses = l2_hits = l2_misses = mem_reads = mem_writes = 0

    def find_idx(level, set_idx, block):
        if level == 1:
            for i, e in enumerate(L1[set_idx]):
                if e[0] == block:
                    return i
        else:
            for i, e in enumerate(L2[set_idx]):
                if e[0] == block:
                    return i
        return -1

    def move_to_mru(level, set_idx, idx):
        if level == 1:
            e = L1[set_idx].pop(idx)
            L1[set_idx].append(e)
        else:
            e = L2[set_idx].pop(idx)
            L2[set_idx].append(e)

    def insert_l2(set_idx, block, dirty):
        nonlocal mem_writes
        if len(L2[set_idx]) == w2:
            ev_block, ev_dirty = L2[set_idx].pop(0)
            if ev_dirty:
                mem_writes += 1
        L2[set_idx].append([block, dirty])

    def insert_l1(set_idx, block, dirty):
        nonlocal mem_writes
        if len(L1[set_idx]) == w1:
            ev_block, ev_dirty = L1[set_idx].pop(0)
            if ev_dirty:
                set2 = ev_block % s2
                idx2 = find_idx(2, set2, ev_block)
                if idx2 != -1:
                    move_to_mru(2, set2, idx2)
                    L2[set2][-1][1] = True
                else:
                    insert_l2(set2, ev_block, True)
        L1[set_idx].append([block, dirty])

    for addr, is_write in zip(addrs, writes):
        set1 = addr % s1
        idx1 = find_idx(1, set1, addr)
        if idx1 != -1:
            l1_hits += 1
            move_to_mru(1, set1, idx1)
            if is_write:
                L1[set1][-1][1] = True
        else:
            l1_misses += 1
            set2 = addr % s2
            idx2 = find_idx(2, set2, addr)
            if idx2 != -1:
                l2_hits += 1
                move_to_mru(2, set2, idx2)
            else:
                l2_misses += 1
                mem_reads += 1
                insert_l2(set2, addr, False)
            insert_l1(set1, addr, is_write)

    dirty = 0
    for s in L1:
        for e in s:
            if e[1]:
                dirty += 1
    for s in L2:
        for e in s:
            if e[1]:
                dirty += 1

    l1_blocks = []
    for s in L1:
        for e in s:
            l1_blocks.append(e[0])

    return (l1_hits, l1_misses, l2_hits, l2_misses, mem_reads, mem_writes, dirty, l1_blocks)
```