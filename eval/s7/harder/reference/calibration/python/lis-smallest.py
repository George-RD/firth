def main(xs):
    n = len(xs)
    # best[i]: the dictionary-smallest longest increasing subsequence starting at i.
    best = [None] * n
    for i in range(n - 1, -1, -1):
        cand = [xs[i]]
        for j in range(i + 1, n):
            if xs[j] > xs[i]:
                c = [xs[i]] + best[j]
                if len(c) > len(cand) or (len(c) == len(cand) and c < cand):
                    cand = c
        best[i] = cand
    out = []
    for c in best:
        if len(c) > len(out) or (len(c) == len(out) and c < out):
            out = c
    return out
