"""One-lift simulation."""


def main(times, floors):
    m = len(times)
    served = [None] * m
    t = floor = moved = 0
    up = True
    while True:
        waiting = [k for k in range(m) if served[k] is None and times[k] <= t]
        here = [k for k in waiting if floors[k] == floor]
        if here:
            for k in here:
                served[k] = t
            t += 2
        elif not waiting:
            pending = [times[k] for k in range(m) if served[k] is None]
            if not pending:
                break
            t = min(pending)
        else:
            if up:
                ahead = any(floors[k] > floor for k in waiting)
            else:
                ahead = any(floors[k] < floor for k in waiting)
            if not ahead:
                up = not up
            floor += 1 if up else -1
            t += 1
            moved += 1
    return served, t, moved
