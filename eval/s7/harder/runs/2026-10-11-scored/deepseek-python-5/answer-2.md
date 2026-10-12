### task: checkers
```python
def main(board, turn, plies):
    def idx_to_rc(i):
        r = i // 4
        c = 2 * (i % 4) + (1 if r % 2 == 0 else 0)
        return r, c

    def rc_to_idx(r, c):
        if r < 0 or r > 7 or c < 0 or c > 7 or (r + c) % 2 != 1:
            return None
        offset = 1 if r % 2 == 0 else 0
        k = (c - offset) // 2
        return r * 4 + k

    def is_own(p, side):
        if side == 0:
            return p == 1 or p == 2
        else:
            return p == 3 or p == 4

    def is_opponent(p, side):
        if side == 0:
            return p == 3 or p == 4
        else:
            return p == 1 or p == 2

    def is_man(p):
        return p == 1 or p == 3

    def is_far_row(i, side):
        r, c = idx_to_rc(i)
        if side == 0:
            return r == 0
        else:
            return r == 7

    def allowed_dr(piece, side):
        if piece == 1:
            return [-1]
        if piece == 3:
            return [1]
        return [-1, 1]

    def gen_captures(start, piece, board, side):
        b = board[:]
        b[start] = 0
        results = []

        def rec(cur, piece_type, b, landings, captured_count):
            r, c = idx_to_rc(cur)
            moves = []
            for dr in allowed_dr(piece_type, side):
                for dc in [-1, 1]:
                    mid = rc_to_idx(r + dr, c + dc)
                    if mid is None:
                        continue
                    land = rc_to_idx(r + 2 * dr, c + 2 * dc)
                    if land is None:
                        continue
                    if is_opponent(b[mid], side) and b[land] == 0:
                        moves.append((mid, land))

            if not moves:
                final_b = b[:]
                final_piece = piece_type
                crowned = False
                if is_man(piece_type) and is_far_row(cur, side):
                    final_piece = 2 if side == 0 else 4
                    crowned = True
                final_b[cur] = final_piece
                results.append((start, captured_count, landings[:], final_b, crowned))
                return

            for mid, land in moves:
                nb = b[:]
                nb[mid] = 0
                new_landings = landings + [land]
                new_count = captured_count + 1
                if is_man(piece_type) and is_far_row(land, side):
                    final_b = nb[:]
                    final_piece = 2 if side == 0 else 4
                    final_b[land] = final_piece
                    results.append((start, new_count, new_landings, final_b, True))
                else:
                    rec(land, piece_type, nb, new_landings, new_count)

        rec(start, piece, b, [], 0)
        return results

    played = 0
    white_took = 0
    black_took = 0
    crowned_count = 0
    result = 0
    side = turn

    while True:
        all_caps = []
        for i, p in enumerate(board):
            if is_own(p, side):
                all_caps.extend(gen_captures(i, p, board, side))
        all_caps = [c for c in all_caps if c[1] > 0]

        if all_caps:
            if played >= plies:
                result = 0
                break
            max_cap = max(c[1] for c in all_caps)
            best = None
            best_key = None
            for cap in all_caps:
                if cap[1] == max_cap:
                    key = (cap[0], cap[2])
                    if best is None or key < best_key:
                        best = cap
                        best_key = key
            start, count, landings, final_board, crowned = best
            board = final_board
            played += 1
            if side == 0:
                white_took += count
            else:
                black_took += count
            if crowned:
                crowned_count += 1
            side = 1 - side
            continue

        steps = []
        for i, p in enumerate(board):
            if is_own(p, side):
                r, c = idx_to_rc(i)
                for dr in allowed_dr(p, side):
                    for dc in [-1, 1]:
                        j = rc_to_idx(r + dr, c + dc)
                        if j is not None and board[j] == 0:
                            steps.append((i, j, p))

        if not steps:
            result = 2 if side == 0 else 1
            break

        if played >= plies:
            result = 0
            break

        start, dest, p = min(steps, key=lambda x: (x[0], x[1]))
        board[start] = 0
        new_p = p
        if is_man(p) and is_far_row(dest, side):
            new_p = 2 if side == 0 else 4
            crowned_count += 1
        board[dest] = new_p
        played += 1
        side = 1 - side

    return (board, played, white_took, black_took, crowned_count, result)
```

### task: regex
```python
def main(pattern, lens, chars):
    tokens = pattern
    valid = True

    def parse_alt(pos):
        seqs = []
        node, pos = parse_sequence(pos)
        if node is None:
            return None, pos
        seqs.append(node)
        while pos < len(tokens) and tokens[pos] == 30:
            pos += 1
            node, pos = parse_sequence(pos)
            if node is None:
                return None, pos
            seqs.append(node)
        return ('alt', tuple(seqs)), pos

    def parse_sequence(pos):
        items = []
        while pos < len(tokens) and tokens[pos] not in (30, 32):
            node, pos = parse_item(pos)
            if node is None:
                return None, pos
            items.append(node)
        return ('seq', tuple(items)), pos

    def parse_item(pos):
        node, pos = parse_atom(pos)
        if node is None:
            return None, pos
        while pos < len(tokens) and tokens[pos] in (27, 28, 29):
            op = tokens[pos]
            pos += 1
            if op == 27:
                node = ('star', node)
            elif op == 28:
                node = ('plus', node)
            else:
                node = ('opt', node)
        return node, pos

    def parse_atom(pos):
        nonlocal valid
        if pos >= len(tokens):
            valid = False
            return None, pos
        tok = tokens[pos]
        if 0 <= tok <= 25:
            return ('lit', tok), pos + 1
        if tok == 26:
            return ('any',), pos + 1
        if tok == 31:
            node, pos = parse_alt(pos + 1)
            if node is None:
                return None, pos
            if pos >= len(tokens) or tokens[pos] != 32:
                valid = False
                return None, pos
            return node, pos + 1
        valid = False
        return None, pos

    root, pos = parse_alt(0)
    if not valid or pos != len(tokens):
        valid = False

    if not valid:
        n = len(lens)
        return ([False] * n, [-1] * n, 0, False)

    strings = []
    idx = 0
    for L in lens:
        strings.append(tuple(chars[idx:idx + L]))
        idx += L

    def match_node(node, s, pos, memo):
        key = (node, pos)
        if key in memo:
            return memo[key]
        typ = node[0]
        if typ == 'lit':
            res = {pos + 1} if pos < len(s) and s[pos] == node[1] else set()
        elif typ == 'any':
            res = {pos + 1} if pos < len(s) else set()
        elif typ == 'seq':
            res = {pos}
            for item in node[1]:
                new = set()
                for p in res:
                    new |= match_node(item, s, p, memo)
                res = new
                if not res:
                    break
        elif typ == 'alt':
            res = set()
            for seq in node[1]:
                res |= match_node(seq, s, pos, memo)
        elif typ == 'star':
            res = {pos}
            stack = [pos]
            while stack:
                p = stack.pop()
                for q in match_node(node[1], s, p, memo):
                    if q not in res:
                        res.add(q)
                        stack.append(q)
        elif typ == 'plus':
            first = match_node(node[1], s, pos, memo)
            res = set(first)
            stack = list(first)
            while stack:
                p = stack.pop()
                for q in match_node(node[1], s, p, memo):
                    if q not in res:
                        res.add(q)
                        stack.append(q)
        elif typ == 'opt':
            res = {pos} | match_node(node[1], s, pos, memo)
        else:
            res = set()
        memo[key] = res
        return res

    full = []
    longest = []
    count = 0
    for s in strings:
        memo = {}
        ends = match_node(root, s, 0, memo)
        if not ends:
            full.append(False)
            longest.append(-1)
        else:
            full.append(len(s) in ends)
            longest.append(max(ends))
        if full[-1]:
            count += 1

    return (full, longest, count, True)
```