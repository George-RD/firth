"""Day-by-day bank simulation."""

PPM = 1_000_000
OVERDRAFT_FEE = 1_000


def is_leap(year):
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


def days_in_month(year, month):
    if month == 2:
        return 29 if is_leap(year) else 28
    return 30 if month in (4, 6, 9, 11) else 31


def main(year, month, day, days, balances, limits, credit_ppm, debit_ppm,
          tx_day, tx_kind, tx_acct, tx_other, tx_amount,
          so_dom, so_from, so_to, so_amount):
    n = len(balances)
    bal = list(balances)
    accrued = [0] * n
    overdrawn = [False] * n
    rejected = 0
    interest_added = interest_taken = fees = 0
    n_so = len(so_dom)
    cancelled = [False] * n_so
    so_rejects = [0] * n_so

    def pay(src, dst, amount):
        """Withdraw (dst is None) or transfer; return True if carried out."""
        if dst == src or bal[src] - amount < -limits[src]:
            return False
        bal[src] -= amount
        if dst is not None:
            bal[dst] += amount
        return True

    for d in range(days):
        month_len = days_in_month(year, month)

        for k, when in enumerate(tx_day):
            if when != d:
                continue
            kind, a, amount = tx_kind[k], tx_acct[k], tx_amount[k]
            if kind == 1:
                bal[a] += amount
            elif kind == 2:
                rejected += not pay(a, None, amount)
            else:
                rejected += not pay(a, tx_other[k], amount)

        for k in range(n_so):
            if cancelled[k] or min(so_dom[k], month_len) != day:
                continue
            if pay(so_from[k], so_to[k], so_amount[k]):
                so_rejects[k] = 0
            else:
                rejected += 1
                so_rejects[k] += 1
                cancelled[k] = so_rejects[k] >= 2

        for i in range(n):
            if bal[i] > 0:
                accrued[i] += bal[i] * credit_ppm
            elif bal[i] < 0:
                accrued[i] += bal[i] * debit_ppm
                overdrawn[i] = True

        if day == month_len:
            for i in range(n):
                posted = abs(accrued[i]) // PPM
                if accrued[i] >= 0:
                    bal[i] += posted
                    interest_added += posted
                else:
                    bal[i] -= posted
                    interest_taken += posted
                accrued[i] = 0
            for i in range(n):
                if overdrawn[i]:
                    bal[i] -= OVERDRAFT_FEE
                    fees += OVERDRAFT_FEE
                    overdrawn[i] = False

        day += 1
        if day > month_len:
            day = 1
            month += 1
            if month > 12:
                month = 1
                year += 1

    return bal, rejected, cancelled, interest_added, interest_taken, fees
