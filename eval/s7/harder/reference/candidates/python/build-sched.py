def main(dur, before, after, prio, workers):
    n = len(dur)
    deps = [set() for _ in range(n)]
    for b, a in zip(before, after):
        deps[a].add(b)
    start = [-1] * n
    worker = [-1] * n
    finish = [None] * n
    busy = [None] * workers  # (task, end) or None
    t = 0
    while True:
        for w in range(workers):
            if busy[w] is not None and busy[w][1] <= t:
                finish[busy[w][0]] = busy[w][1]
                busy[w] = None
        while True:
            fw = next((w for w in range(workers) if busy[w] is None), None)
            if fw is None:
                break
            ready = [i for i in range(n) if start[i] == -1 and
                     all(finish[d] is not None and finish[d] <= t for d in deps[i])]
            if not ready:
                break
            i = min(ready, key=lambda i: (-prio[i], -dur[i], i))
            start[i] = t
            worker[i] = fw
            busy[fw] = (i, t + dur[i])
        ends = [b[1] for b in busy if b is not None]
        if not ends:
            break
        t = min(ends)
    started = [i for i in range(n) if start[i] != -1]
    makespan = max((start[i] + dur[i] for i in started), default=0)
    idle = makespan * workers - sum(dur[i] for i in started)
    unrun = n - len(started)
    return (start, worker, makespan, idle, unrun)
