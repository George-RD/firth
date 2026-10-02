def main(rolls):
    # Score frame by frame, walking a roll index.
    totals, pos, running = [], 0, 0
    for frame in range(10):
        first = rolls[pos]
        if first == 10:
            running += 10 + rolls[pos + 1] + rolls[pos + 2]
            pos += 1
        else:
            second = rolls[pos + 1]
            bonus = rolls[pos + 2] if first + second == 10 else 0
            running += first + second + bonus
            pos += 2
        totals.append(running)
    return totals
