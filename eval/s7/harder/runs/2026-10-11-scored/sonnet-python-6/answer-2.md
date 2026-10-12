### task: sokoban
```python
def main(width, height, cells, player, boxes, moves):
    boxes = list(boxes)
    deltas = [-width, 1, width, -1]
    history = []
    read = pushes = blocked = undos = dead = 0

    def all_on_goal():
        return all(cells[b] == 2 for b in boxes)

    for m in moves:
        if all_on_goal():
            break
        read += 1
        if m == 4:
            if history:
                d, k = history.pop()
                if k >= 0:
                    # the box was pushed from the worker's current cell
                    boxes[k] = player
                player -= d
                undos += 1
            continue
        d = deltas[m]
        t = player + d
        if cells[t] == 1:
            blocked += 1
            continue
        if t in boxes:
            k = boxes.index(t)
            u = t + d
            if cells[u] == 1 or u in boxes:
                blocked += 1
                continue
            boxes[k] = u
            player = t
            pushes += 1
            history.append((d, k))
            if cells[u] != 2:
                vert = cells[u - width] == 1 or cells[u + width] == 1
                horiz = cells[u - 1] == 1 or cells[u + 1] == 1
                if vert and horiz:
                    dead += 1
        else:
            player = t
            history.append((d, -1))
    return (player, boxes, read, len(history), pushes, blocked, undos, dead, all_on_goal())
```
