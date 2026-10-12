import heapq


def main(n, froms, tos, weights, source):
    adj = [[] for _ in range(n)]
    for a, b, w in zip(froms, tos, weights):
        adj[a].append((b, w))
    best = [None] * n
    heap = [(0, 0, source)]
    while heap:
        d, h, v = heapq.heappop(heap)
        if best[v] is not None:
            continue
        best[v] = (d, h)
        for b, w in adj[v]:
            if best[b] is None:
                heapq.heappush(heap, (d + w, h + 1, b))
    return [-1 if b is None else b[0] for b in best], [-1 if b is None else b[1] for b in best]
