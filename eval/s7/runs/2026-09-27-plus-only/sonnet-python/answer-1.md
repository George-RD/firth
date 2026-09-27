### task: triple
```python
def main(n):
    return 3 * n
```

### task: sum3
```python
def main(a, b, c):
    return a + b + c
```

### task: times10
```python
def main(n):
    return 10 * n
```

### task: affine
```python
def main(x):
    return 4 * x + 7
```

### task: pair-sum
```python
def main(a, b):
    return (b, a + b)
```

### task: select
```python
def main(a, b, flag):
    return a if flag else b
```

### task: not
```python
def main(p):
    return not p
```

### task: and
```python
def main(p, q):
    return p and q
```

### task: xor
```python
def main(p, q):
    return p != q
```

### task: majority
```python
def main(p, q, r):
    return (p + q + r) >= 2
```

### task: count-true
```python
def main(p, q, r):
    return int(p) + int(q) + int(r)
```

### task: max
```python
def main(a, b):
    return a if a > b else b
```

### task: min3
```python
def main(a, b, c):
    return min(a, b, c)
```

### task: abs-diff
```python
def main(a, b):
    return abs(a - b)
```

### task: clamp
```python
def main(x, lo, hi):
    if x < lo:
        return lo
    if x > hi:
        return hi
    return x
```

### task: is-even
```python
def main(n):
    return n % 2 == 0
```

### task: sum-to
```python
def main(n):
    return n * (n + 1) // 2
```

### task: factorial
```python
def main(n):
    r = 1
    for i in range(2, n + 1):
        r *= i
    return r
```

### task: fib
```python
def main(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
```

### task: gcd
```python
def main(a, b):
    while b:
        a, b = b, a % b
    return a
```

### task: power
```python
def main(base, exp):
    return base ** exp
```

### task: collatz-steps
```python
def main(n):
    steps = 0
    while n != 1:
        if n % 2 == 0:
            n = n // 2
        else:
            n = 3 * n + 1
        steps += 1
    return steps
```
