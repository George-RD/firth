"""Reverse-Polish spreadsheet with cycle detection and edits.

A value is an int or None (error).
"""

LIMIT = 1_000_000_000

# operator code -> number of arguments
ARITY = {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 3, 8: 1}


def trunc_div(a, b):
    q = abs(a) // abs(b)
    return q if (a >= 0) == (b >= 0) else -q


def checked(x):
    return None if abs(x) > LIMIT else x


def apply_operator(op, args):
    if op == 7:
        c, a, b = args
        if c is None:
            return None
        return a if c != 0 else b
    if any(a is None for a in args):
        return None
    if op == 8:
        return checked(-args[0])
    a, b = args
    if op == 1:
        return checked(a + b)
    if op == 2:
        return checked(a - b)
    if op == 3:
        return checked(a * b)
    if op == 4:
        return None if b == 0 else checked(trunc_div(a, b))
    if op == 5:
        return int(a < b)
    return int(a == b)


def apply_function(fn, cells):
    if fn == 4:
        return sum(v is not None for v in cells)
    if any(v is None for v in cells):
        return None
    if fn == 1:
        return checked(sum(cells))
    return min(cells) if fn == 2 else max(cells)


def references(tokens, n):
    """Cells that a formula refers to, well formed or not."""
    refs = set()
    for kind, x, y, z in tokens:
        if kind == 1 and 0 <= x < n:
            refs.add(x)
        elif kind == 3 and 0 <= y <= z < n:
            refs.update(range(y, z + 1))
    return refs


def evaluate(tokens, n, cell_value):
    stack = []
    for kind, x, y, z in tokens:
        if kind == 0:
            stack.append(x)
        elif kind == 1:
            stack.append(cell_value(x) if 0 <= x < n else None)
        elif kind == 2:
            arity = ARITY[x]
            if len(stack) < arity:
                return None
            args = stack[len(stack) - arity:]
            del stack[len(stack) - arity:]
            stack.append(apply_operator(x, args))
        else:
            if 0 <= y <= z < n:
                stack.append(apply_function(x, [cell_value(i) for i in range(y, z + 1)]))
            else:
                stack.append(None)
    return stack[0] if len(stack) == 1 else None


def evaluate_sheet(formulas):
    n = len(formulas)
    refs = [references(f, n) for f in formulas]

    # reach[i]: cells reachable from i in one or more steps
    reach = [set(r) for r in refs]
    changed = True
    while changed:
        changed = False
        for i in range(n):
            new = set(reach[i])
            for j in reach[i]:
                new |= reach[j]
            if new != reach[i]:
                reach[i] = new
                changed = True
    in_cycle = [i in reach[i] for i in range(n)]
    bad = [in_cycle[i] or any(in_cycle[j] for j in reach[i]) for i in range(n)]

    values = [None] * n
    done = [False] * n

    def cell_value(i):
        if bad[i]:
            return None
        if not done[i]:
            values[i] = evaluate(formulas[i], n, cell_value)
            done[i] = True
        return values[i]

    return [cell_value(i) for i in range(n)]


def split_tokens(lens, kinds, xs, ys, zs):
    result, pos = [], 0
    for length in lens:
        result.append(list(zip(kinds[pos:pos + length], xs[pos:pos + length],
                               ys[pos:pos + length], zs[pos:pos + length])))
        pos += length
    return result


def main(lens, kinds, xs, ys, zs, edit_cells, edit_lens, e_kinds, e_xs, e_ys, e_zs):
    formulas = split_tokens(lens, kinds, xs, ys, zs)
    edits = split_tokens(edit_lens, e_kinds, e_xs, e_ys, e_zs)

    values = evaluate_sheet(formulas)
    changed_counts = []
    for cell, tokens in zip(edit_cells, edits):
        formulas[cell] = tokens
        new_values = evaluate_sheet(formulas)
        changed_counts.append(sum(a != b for a, b in zip(values, new_values)))
        values = new_values

    return ([0 if v is None else v for v in values],
            [v is None for v in values],
            changed_counts)
