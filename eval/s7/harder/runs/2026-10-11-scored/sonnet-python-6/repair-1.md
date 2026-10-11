Some of your python answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sokoban
Play moves in a warehouse puzzle and report what happened. The floor is a grid of width columns and height rows; cell (row r, column c) is number r times width plus c, and cells[i] is 0 for floor, 1 for wall and 2 for a goal (a goal is also floor). The worker stands on cell player, and boxes lists the cells holding boxes: box k starts on boxes[k]. Each move is 0 up (to the cell width lower in number), 1 right (one higher), 2 down (width higher), 3 left (one lower) or 4 undo. Read the moves in order. Before reading each move, the first one included, if every box is on a goal, stop: the puzzle is solved and the moves not yet read are not used. A move in a direction looks at the next cell t that way from the worker. If t is a wall, the move is blocked and nothing changes. If t holds a box, look at the cell u beyond it in the same direction: if u is a wall or holds a box, the move is blocked; otherwise the box moves to u and the worker to t, which is a push. Otherwise the worker moves to t, which is a step. A push or a step is recorded in the history, the latest last; a blocked move is not. A pushed box is dead if, after the push, it is not on a goal, has a wall above or below it, and also has a wall to its left or right. An undo takes back the latest move in the history and removes it from the history: the worker moves back the way it came, and if that move was a push, its box moves back too. An undo with an empty history does nothing. Return the worker's final cell, the final cell of each box (in the order of boxes), the number of moves read, the number of moves left in the history, the number of pushes made (an undone push still counts), the number of blocked moves, the number of undos that took a move back, the number of pushes that left a box dead (again counting undone ones), and whether every box is on a goal at the end. width and height are 3 to 12; cells has width times height values, each 0 to 2, and every cell in the first or last row or column is a wall; player and every value of boxes are cells that are not walls, boxes has 1 to 6 values, and no two of player and the boxes are the same cell; moves has at most 200 values, each 0 to 4.
Arguments, in order: width: int, height: int, cells: list[int], player: int, boxes: list[int], moves: list[int].
Return: player: int, boxes: list[int], read: int, history: int, pushes: int, blocked: int, undos: int, dead: int, solved: bool (as a tuple, in this order).
Example: main(6, 5, [1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1], 9, [15], [2, 1, 2, 3, 3, 4, 4, 0, 3, 3, 4, 1, 1]) returns (16, [21], 13, 6, 3, 1, 3, 1, False).

Your answer:
```
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
                    # box is at player + d; worker was at player - d
                    boxes[k] = player + d
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
On the example, it returned [16, [20], 13, 6, 3, 1, 3, 1, False] instead of [16, [21], 13, 6, 3, 1, 3, 1, False]
