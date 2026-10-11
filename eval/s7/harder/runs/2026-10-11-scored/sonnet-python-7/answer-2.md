### task: checkers
```python
def main(board, turn, plies):
    b = list(board)
    W_DIRS = [(-1, -1), (-1, 1)]
    B_DIRS = [(1, -1), (1, 1)]
    ALL = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    def rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def idx(r, c):
        return r * 4 + c // 2

    def inb(r, c):
        return 0 <= r < 8 and 0 <= c < 8

    def owner(p):
        if p in (1, 2):
            return 0
        if p in (3, 4):
            return 1
        return -1

    def dirs(p):
        if p == 1:
            return W_DIRS
        if p == 3:
            return B_DIRS
        return ALL

    # The moving piece is held in variables; its current square is empty in bd.
    def explore(bd, r, c, piece, side, start, lands, ncap, out):
        moved = False
        far = 0 if side == 0 else 7
        for dr, dc in dirs(piece):
            mr, mc = r + dr, c + dc
            lr, lc = r + 2 * dr, c + 2 * dc
            if not inb(lr, lc):
                continue
            mi = idx(mr, mc)
            li = idx(lr, lc)
            mid = bd[mi]
            if mid != 0 and owner(mid) != side and bd[li] == 0:
                moved = True
                bd[mi] = 0
                crowned = piece in (1, 3) and lr == far
                newp = piece + 1 if crowned else piece
                lands.append(li)
                if crowned:
                    snap = bd[:]
                    snap[li] = newp
                    out.append((ncap + 1, start, tuple(lands), snap, True))
                else:
                    explore(bd, lr, lc, newp, side, start, lands, ncap + 1, out)
                lands.pop()
                bd[mi] = mid
        if not moved and ncap > 0:
            snap = bd[:]
            snap[idx(r, c)] = piece
            out.append((ncap, start, tuple(lands), snap, False))

    def captures(side):
        out = []
        for sq in range(32):
            p = b[sq]
            if p != 0 and owner(p) == side:
                tmp = b[:]
                tmp[sq] = 0
                r, c = rc(sq)
                explore(tmp, r, c, p, side, sq, [], 0, out)
        return out

    def steps(side):
        best = None
        for sq in range(32):
            p = b[sq]
            if p != 0 and owner(p) == side:
                r, c = rc(sq)
                for dr, dc in dirs(p):
                    nr, nc = r + dr, c + dc
                    if inb(nr, nc) and b[idx(nr, nc)] == 0:
                        cand = (sq, idx(nr, nc))
                        if best is None or cand < best:
                            best = cand
        return best

    played = 0
    wt = bt = crowned = 0
    side = turn
    result = 0
    while True:
        caps = captures(side)
        st = None
        if not caps:
            st = steps(side)
            if st is None:
                result = 2 if side == 0 else 1
                break
        if played >= plies:
            result = 0
            break
        if caps:
            best = min(caps, key=lambda x: (-x[0], x[1], x[2]))
            b = best[3]
            if side == 0:
                wt += best[0]
            else:
                bt += best[0]
            if best[4]:
                crowned += 1
        else:
            sq, dest = st
            p = b[sq]
            b[sq] = 0
            nr, _ = rc(dest)
            if p == 1 and nr == 0:
                p = 2
                crowned += 1
            elif p == 3 and nr == 7:
                p = 4
                crowned += 1
            b[dest] = p
        played += 1
        side = 1 - side
    return (b, played, wt, bt, crowned, result)
```
