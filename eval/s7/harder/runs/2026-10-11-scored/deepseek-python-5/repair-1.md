Some of your python answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## checkers
Play draughts on an 8 by 8 board, both sides moving by a fixed rule, and report the result. Only the 32 dark squares are used, numbered 0 to 31: square i is in row r = i divided by 4, rounded down (row 0 at the top), and in column 2 times (i mod 4), plus 1 when r is even. board[i] is 0 for empty, 1 for a white man, 2 for a white king, 3 for a black man and 4 for a black king. White men move up (towards row 0) and black men down; kings move both ways. A step moves a piece to an empty square diagonally next to it, in a direction it may move. A jump moves a piece over a diagonally next square holding a piece of the other side, in a direction it may move, to the empty square just beyond; the piece jumped over is taken off the board at once, and the square the capturing piece started from counts as empty during the capture, so it may land there. A capture is a sequence of jumps by one piece: after each jump, if that piece can jump again from where it landed, it must, and a capture is complete only when it cannot, except that a man that lands on the far row (row 0 for white, row 7 for black) is crowned king and its capture ends there. A man that steps onto its far row is crowned too. The side to move must capture if any of its pieces can; then it plays the complete capture that takes the most pieces, choosing among equals the one whose piece starts on the lowest-numbered square, then the one whose list of landing squares, read in order, is lower at the first place the lists differ, whatever its last landing. If it cannot capture it makes the step whose piece starts on the lowest-numbered square, and among those the step to the lowest-numbered square. White moves first if turn is 0 and black if turn is 1, then the sides alternate. Before each move, if the side to move has no capture or step, it has lost and play stops; otherwise, if plies moves have been played, play stops; otherwise it moves. So a side with no move when the limit is reached has still lost. Return the final board, the number of moves played, the number of pieces white took, the number black took, the number of men crowned (by a step or at the end of a capture, on either side), and the result: 1 if white won, 2 if black won, 0 if play stopped at the move limit. board has 32 values, each 0 to 4, with at most 12 pieces of each side, no white man on row 0 and no black man on row 7; turn is 0 or 1; plies is 1 to 40.
Arguments, in order: board: list[int], turn: int, plies: int.
Return: board: list[int], played: int, white_took: int, black_took: int, crowned: int, result: int (as a tuple, in this order).
Example: main([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 1, 0, 0, 0], 0, 2) returns ([0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 2, 3, 0, 0, 0).

Your answer:
```
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
On the example, it returned [[0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 2, 3, 0, 0, 0] instead of [[0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 2, 3, 0, 0, 0]

## regex
Match strings against a regular expression given as tokens. Token 0 to 25 is that letter; 26 is '.', matching any one letter; 27 '*', 28 '+' and 29 '?' are postfix operators; 30 is '|'; 31 '(' and 32 ')'. The pattern's grammar: an alternation is one or more sequences separated by '|'; a sequence is zero or more items, one after another; an item is an atom followed by zero or more postfix operators; an atom is a letter, '.', or '(' alternation ')'. The whole pattern is one alternation. A postfix operator applies to its item's atom together with any operators already after it, so ab* repeats only the b and (a*)? is a*?: '*' matches zero or more repeats, '+' one or more, '?' zero or one. A sequence matches its items one after another (an empty sequence matches the empty string), and an alternation matches if any of its sequences does. A pattern that does not fit the grammar, such as one with an operator where an atom should start, a '(' never closed or a ')' with no '(' open, is invalid. The strings are given together: string j has lens[j] letters, and chars holds every string's letters, string 0 first. For each string, return whether the whole string matches the pattern, and the length of the longest start of it (from no letters up to all of them) that matches, or -1 if none does. Also return how many strings match whole and whether the pattern is valid; for an invalid pattern every string gives false and -1, the count is 0 and validity is false. pattern has at most 20 tokens, each 0 to 32; lens has 1 to 8 values, each 0 to 12, adding up to the length of chars; every value of chars is 0 to 25.
Arguments, in order: pattern: list[int], lens: list[int], chars: list[int].
Return: full: list[bool], longest: list[int], count: int, valid: bool (as a tuple, in this order).
Example: main([0, 27, 1, 30, 31, 2, 3, 32, 28], [3, 2, 4, 0, 3, 1, 3], [0, 0, 1, 2, 3, 2, 3, 2, 3, 2, 3, 2, 1, 0, 1, 1]) returns ([True, True, True, False, False, True, False], [3, 2, 4, -1, 2, 1, 2], 4, True).

Your answer:
```
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
        return ('alt', seqs), pos

    def parse_sequence(pos):
        items = []
        while pos < len(tokens) and tokens[pos] not in (30, 32):
            node, pos = parse_item(pos)
            if node is None:
                return None, pos
            items.append(node)
        return ('seq', items), pos

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
On the example, the run failed:
Traceback (most recent call last):
  File "<string>", line 10, in <module>
  File "solution.py", line 131, in main
  File "solution.py", line 80, in match_node
TypeError: unhashable type: 'list'
