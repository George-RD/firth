def main(xs, ys, insert, delete, replace):
    n, m = len(xs), len(ys)
    d = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        for j in range(m + 1):
            if i == 0:
                d[i][j] = j * insert
            elif j == 0:
                d[i][j] = i * delete
            else:
                same = xs[i - 1] == ys[j - 1]
                d[i][j] = min(d[i - 1][j] + delete, d[i][j - 1] + insert,
                              d[i - 1][j - 1] + (0 if same else replace))
    return d[n][m]
