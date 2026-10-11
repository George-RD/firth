### task: regex
```python
def main(pattern, lens, chars):
    tokens = pattern
    pos = 0
    valid = True

    class Invalid(Exception):
        pass

    def parse_alternation():
        nonlocal pos
        seqs = [parse_sequence()]
        while pos < len(tokens) and tokens[pos] == 30:
            pos += 1
            seqs.append(parse_sequence())
        return ('alt', seqs)

    def parse_sequence():
        nonlocal pos
        items = []
        while pos < len(tokens):
            t = tokens[pos]
            if (0 <= t <= 26) or t == 31:
                items.append(parse_item())
            else:
                break
        if pos < len(tokens) and tokens[pos] in (27, 28, 29):
            raise Invalid
        return ('seq', items)

    def parse_item():
        nonlocal pos
        atom = parse_atom()
        ops = []
        while pos < len(tokens) and tokens[pos] in (27, 28, 29):
            ops.append(tokens[pos])
            pos += 1
        return ('item', atom, ops)

    def parse_atom():
        nonlocal pos
        if pos >= len(tokens):
            raise Invalid
        t = tokens[pos]
        if 0 <= t <= 25:
            pos += 1
            return ('lit', t)
        if t == 26:
            pos += 1
            return ('any',)
        if t == 31:
            pos += 1
            alt = parse_alternation()
            if pos >= len(tokens) or tokens[pos] != 32:
                raise Invalid
            pos += 1
            return alt
        raise Invalid

    try:
        ast = parse_alternation()
        if pos != len(tokens):
            valid = False
        else:
            valid = True
    except Invalid:
        valid = False

    def closure(f, p):
        seen = {p}
        stack = [p]
        while stack:
            q = stack.pop()
            for r in f(q):
                if r not in seen:
                    seen.add(r)
                    stack.append(r)
        return seen

    def plus(f, p):
        first = f(p)
        seen = set(first)
        stack = list(first)
        while stack:
            q = stack.pop()
            for r in f(q):
                if r not in seen:
                    seen.add(r)
                    stack.append(r)
        return seen

    def optional(f, p):
        return {p} | f(p)

    def match_node(node, s, p):
        typ = node[0]
        if typ == 'alt':
            res = set()
            for seq in node[1]:
                res |= match_node(seq, s, p)
            return res
        if typ == 'seq':
            cur = {p}
            for item in node[1]:
                nxt = set()
                for q in cur:
                    nxt |= match_item(item, s, q)
                cur = nxt
                if not cur:
                    break
            return cur
        if typ == 'lit':
            if p < len(s) and s[p] == node[1]:
                return {p + 1}
            return set()
        if typ == 'any':
            if p < len(s):
                return {p + 1}
            return set()
        return set()

    def match_item(item, s, p):
        atom = item[1]
        ops = item[2]

        def base(q):
            return match_node(atom, s, q)

        m = base
        for op in ops:
            prev = m
            if op == 27:
                def m(q, prev=prev):
                    return closure(prev, q)
            elif op == 28:
                def m(q, prev=prev):
                    return plus(prev, q)
            elif op == 29:
                def m(q, prev=prev):
                    return optional(prev, q)
        return m(p)

    full = []
    longest = []
    count = 0
    offset = 0

    if not valid:
        for _ in lens:
            full.append(False)
            longest.append(-1)
        return (full, longest, 0, False)

    for L in lens:
        s = chars[offset:offset + L]
        offset += L
        ends = match_node(ast, s, 0)
        is_full = L in ends
        full.append(is_full)
        if ends:
            longest.append(max(ends))
        else:
            longest.append(-1)
        if is_full:
            count += 1

    return (full, longest, count, valid)
```