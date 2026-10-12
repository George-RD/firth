def main(kinds, vals):
    st = []
    for i, kind in enumerate(kinds):
        if kind == 0:
            st.append(vals[i])
        elif kind == 5:
            if not st:
                return 0, 1
            st.append(st[-1])
        else:
            if len(st) < 2:
                return 0, 1
            b = st.pop()
            a = st.pop()
            if kind == 1:
                st.append(a + b)
            elif kind == 2:
                st.append(a - b)
            elif kind == 3:
                st.append(a * b)
            else:
                if b == 0:
                    return 0, 2
                q = a // b
                if q < 0 and q * b != a:
                    q += 1  # floor to truncation
                st.append(q)
    if len(st) != 1:
        return 0, 3
    return st[0], 0
