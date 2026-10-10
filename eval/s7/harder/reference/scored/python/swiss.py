def solve(ratings, rounds, results):
    n = len(ratings)
    score = [0] * n
    whites = [0] * n
    last = [None] * n  # 'w' or 'b'
    played = [set() for _ in range(n)]
    opps = [[] for _ in range(n)]
    had_bye = [False] * n
    rematches = 0
    ri = 0
    for _ in range(rounds):
        rank = sorted(range(n), key=lambda p: (-score[p], -ratings[p], p))
        pool = list(rank)
        if n % 2 == 1:
            for p in reversed(rank):
                if not had_bye[p]:
                    had_bye[p] = True
                    score[p] += 2
                    pool.remove(p)
                    break
        paired = set()
        games = []
        for p in pool:
            if p in paired:
                continue
            paired.add(p)
            cand = [q for q in pool if q not in paired]
            q = next((x for x in cand if x not in played[p]), None)
            if q is None:
                q = cand[0]
                rematches += 1
            paired.add(q)
            if whites[p] < whites[q]:
                w, b = p, q
            elif whites[q] < whites[p]:
                w, b = q, p
            else:
                pb = last[p] == 'b'
                qb = last[q] == 'b'
                if pb and not qb:
                    w, b = p, q
                elif qb and not pb:
                    w, b = q, p
                else:
                    w, b = p, q
            games.append((w, b))
            played[p].add(q)
            played[q].add(p)
            opps[p].append(q)
            opps[q].append(p)
            whites[w] += 1
            last[w] = 'w'
            last[b] = 'b'
        deltas = []
        for w, b in games:
            r = results[ri]
            ri += 1
            if r == 0:
                score[w] += 2
            elif r == 1:
                score[w] += 1
                score[b] += 1
            else:
                score[b] += 2
    buch = [sum(score[o] for o in opps[p]) for p in range(n)]
    ranking = sorted(range(n), key=lambda p: (-score[p], -buch[p], -ratings[p], p))
    return (score, buch, ranking, whites, rematches)


main = solve
