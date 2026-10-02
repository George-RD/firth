"""Day difference, weekday and day of year, from first principles."""


def _leap(y):
    return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)


def _mdays(y, m):
    if m == 2:
        return 29 if _leap(y) else 28
    return 30 if m in (4, 6, 9, 11) else 31


def _doy(y, m, d):
    return sum(_mdays(y, i) for i in range(1, m)) + d


def _days_since_2000(y, m, d):
    total = _doy(y, m, d) - 1
    if y >= 2000:
        for i in range(2000, y):
            total += 366 if _leap(i) else 365
    else:
        for i in range(y, 2000):
            total -= 366 if _leap(i) else 365
    return total


def main(y1, m1, d1, y2, m2, d2):
    a = _days_since_2000(y1, m1, d1)
    b = _days_since_2000(y2, m2, d2)
    return b - a, (b + 5) % 7, _doy(y2, m2, d2)
