"""Falling-blocks game simulator."""

SHAPES = {
    0: [[(0, 2), (1, 2), (2, 2), (3, 2)], [(2, 0), (2, 1), (2, 2), (2, 3)],
        [(0, 1), (1, 1), (2, 1), (3, 1)], [(1, 0), (1, 1), (1, 2), (1, 3)]],
    1: [[(1, 1), (2, 1), (1, 2), (2, 2)]] * 4,
    2: [[(0, 2), (1, 2), (2, 2), (1, 3)], [(1, 1), (1, 2), (1, 3), (2, 2)],
        [(0, 2), (1, 2), (2, 2), (1, 1)], [(1, 1), (1, 2), (1, 3), (0, 2)]],
    3: [[(0, 2), (1, 2), (1, 3), (2, 3)], [(1, 3), (1, 2), (2, 2), (2, 1)],
        [(0, 1), (1, 1), (1, 2), (2, 2)], [(0, 3), (0, 2), (1, 2), (1, 1)]],
    4: [[(0, 3), (1, 3), (1, 2), (2, 2)], [(2, 3), (2, 2), (1, 2), (1, 1)],
        [(0, 2), (1, 2), (1, 1), (2, 1)], [(1, 3), (1, 2), (0, 2), (0, 1)]],
    5: [[(0, 2), (1, 2), (2, 2), (2, 3)], [(1, 3), (1, 2), (1, 1), (2, 1)],
        [(0, 1), (0, 2), (1, 2), (2, 2)], [(0, 3), (1, 3), (1, 2), (1, 1)]],
    6: [[(0, 3), (0, 2), (1, 2), (2, 2)], [(1, 1), (1, 2), (1, 3), (2, 3)],
        [(0, 2), (1, 2), (2, 2), (2, 1)], [(0, 1), (1, 1), (1, 2), (1, 3)]],
}

ROTATION_OFFSETS = [(0, 0), (-1, 0), (1, 0), (0, 1), (-2, 0), (2, 0)]
LINE_BASE = {1: 100, 2: 300, 3: 500, 4: 800}


class Piece:
    def __init__(self, kind, x, y):
        self.kind, self.rot, self.x, self.y = kind, 0, x, y

    def cells(self, rot=None, x=None, y=None):
        rot = self.rot if rot is None else rot
        x = self.x if x is None else x
        y = self.y if y is None else y
        return [(x + dx, y + dy) for dx, dy in SHAPES[self.kind][rot]]


def main(width, height, queue, moves):
    grid = [[False] * width for _ in range(height)]  # grid[row][col]

    def fits(piece, rot=None, x=None, y=None):
        return all(0 <= cx < width and 0 <= cy < height and not grid[cy][cx]
                   for cx, cy in piece.cells(rot, x, y))

    def spawn(kind):
        return Piece(kind, (width - 4) // 2, height - 4)

    score = rows_total = locks = 0
    held = -1
    last_clear = 0   # rows removed by the last earlier lock that removed any
    combo = 0
    status = 1
    q_pos = m_pos = 0
    current = None
    can_hold = False

    def finish():
        heights = []
        for col in range(width):
            h = 0
            for row in range(height):
                if grid[row][col]:
                    h = row + 1
            heights.append(h)
        return heights, score, rows_total, locks, status, held

    while True:
        if current is None:
            if q_pos >= len(queue):
                status = 0
                return finish()
            current = spawn(queue[q_pos])
            q_pos += 1
            can_hold = True
            if not fits(current):
                status = 2
                return finish()
        if m_pos >= len(moves):
            status = 1
            return finish()
        cmd = moves[m_pos]
        m_pos += 1

        if cmd in (1, 2, 5):
            dx, dy = {1: (-1, 0), 2: (1, 0), 5: (0, -1)}[cmd]
            if fits(current, x=current.x + dx, y=current.y + dy):
                current.x += dx
                current.y += dy
        elif cmd in (3, 4):
            new_rot = (current.rot + (1 if cmd == 3 else 3)) % 4
            for ox, oy in ROTATION_OFFSETS:
                if fits(current, new_rot, current.x + ox, current.y + oy):
                    current.rot = new_rot
                    current.x += ox
                    current.y += oy
                    break
        elif cmd == 6:
            if can_hold:
                if held == -1:
                    held = current.kind
                    if q_pos >= len(queue):
                        status = 0
                        return finish()
                    new_kind = queue[q_pos]
                    q_pos += 1
                else:
                    new_kind, held = held, current.kind
                current = spawn(new_kind)
                can_hold = False
                if not fits(current):
                    status = 2
                    return finish()
        else:  # drop and lock
            while fits(current, y=current.y - 1):
                current.y -= 1
            for cx, cy in current.cells():
                grid[cy][cx] = True
            current = None
            locks += 1
            grid = [row for row in grid if not all(row)]
            k = height - len(grid)
            grid.extend([False] * width for _ in range(k))
            if k:
                base = 1200 if (k == 4 and last_clear == 4) else LINE_BASE[k]
                level = 1 + rows_total // 10
                score += (base + 50 * combo) * level
                rows_total += k
                combo += 1
                last_clear = k
            else:
                combo = 0
