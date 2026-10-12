def main(n, k, m):
    surv, rem = [], []
    for N, K, M in zip(n, k, m):
        # survivor
        if K == 1:
            x = N - 1
        else:
            x, s = 0, 1
            while s < N:
                t = min((s - x - 1) // (K - 1), N - s)
                if t > 0:
                    x += K * t
                    s += t
                else:
                    s += 1
                    x = (x + K) % s
        surv.append(x)
        # m-th removed
        size = N - M + 1
        p = (K - 1) % size
        for s in range(size + 1, N + 1):
            p = (p + K) % s
        rem.append(p)
    return (surv, rem)
