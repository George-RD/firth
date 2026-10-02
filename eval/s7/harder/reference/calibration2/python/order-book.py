"""Price-time priority order book."""


def main(kinds, sides, prices, qtys):
    m = len(kinds)
    filled = [0] * m
    rest = {}  # op index -> remaining units, for resting limit orders
    value = trades = 0
    for i in range(m):
        if kinds[i] == 1:
            j = qtys[i]
            if 0 <= j < i:
                rest.pop(j, None)
            continue
        side, price, left = sides[i], prices[i], qtys[i]
        while left > 0:
            best = None
            for j in rest:
                if sides[j] == side:
                    continue
                pj = prices[j]
                if price != 0:
                    if side == 0 and pj > price:
                        continue
                    if side == 1 and pj < price:
                        continue
                rank = (pj, j) if side == 0 else (-pj, j)
                if best is None or rank < best[0]:
                    best = (rank, j)
            if best is None:
                break
            j = best[1]
            u = min(left, rest[j])
            left -= u
            rest[j] -= u
            filled[i] += u
            filled[j] += u
            value += u * prices[j]
            trades += 1
            if rest[j] == 0:
                del rest[j]
        if left > 0 and price != 0:
            rest[i] = left
    return filled, value, trades
