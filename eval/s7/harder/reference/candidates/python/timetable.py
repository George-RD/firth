def main(stations, change, origin, start, fromSt, toSt, dep, arr, train):
    INF = float('inf')
    n = len(fromSt)
    runs = {}
    for i in range(n):
        runs.setdefault(train[i], []).append(i)
    prev = [INF] * stations
    prev[origin] = start
    layers = [prev[:]]
    for k in range(1, n + 2):
        new = prev[:]
        for t, idxs in runs.items():
            riding = False
            for i in idxs:
                f = fromSt[i]
                if not riding:
                    if f == origin:
                        ok = dep[i] >= start
                    else:
                        ok = prev[f] != INF and prev[f] + change <= dep[i]
                    if ok:
                        riding = True
                if riding and arr[i] < new[toSt[i]]:
                    new[toSt[i]] = arr[i]
        layers.append(new)
        if new == prev:
            break
        prev = new
    final = layers[-1]
    arrive, trains = [], []
    for s in range(stations):
        if final[s] == INF:
            arrive.append(-1)
            trains.append(-1)
        else:
            arrive.append(final[s])
            for k, L in enumerate(layers):
                if L[s] == final[s]:
                    trains.append(k)
                    break
    return (arrive, trains)
