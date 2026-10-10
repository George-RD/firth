def solve(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    deltas = [-width, 1, width, -1]
    history = []  # (prev_player, box_index or -1, box_from)
    read = pushes = blocked = undos = dead = 0

    def solved():
        return all(cells[b] == 2 for b in boxes)

    for m in moves:
        if solved():
            break
        read += 1
        if m == 4:
            if history:
                prev, k, bfrom = history.pop()
                player = prev
                if k >= 0:
                    boxes[k] = bfrom
                undos += 1
            continue
        d = deltas[m]
        t = player + d
        if cells[t] == 1:
            blocked += 1
            continue
        if t in boxes:
            u = t + d
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue
            k = boxes.index(t)
            boxes[k] = u
            history.append((player, k, t))
            player = t
            pushes += 1
            if (cells[u] != 2
                    and (cells[u - width] == 1 or cells[u + width] == 1)
                    and (cells[u - 1] == 1 or cells[u + 1] == 1)):
                dead += 1
        else:
            history.append((player, -1, -1))
            player = t
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, solved())


main = solve
