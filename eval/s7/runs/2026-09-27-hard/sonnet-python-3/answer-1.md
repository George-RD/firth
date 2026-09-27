### task: sort3
```python
def main(a, b, c):
    hi, mid, lo = sorted([a, b, c], reverse=True)
    return (lo, mid, hi)
```

### task: median3
```python
def main(a, b, c):
    return sorted([a, b, c])[1]
```

### task: triangle-kind
```python
def main(a, b, c):
    sides = sorted([a, b, c])
    lo1, lo2, hi = sides
    if lo1 <= 0 or lo1 + lo2 <= hi:
        return 0
    if a == b == c:
        return 1
    if a == b or b == c or a == c:
        return 2
    return 3
```

### task: divmod
```python
def main(a, b):
    return (a // b, a % b)
```

### task: isqrt
```python
def main(n):
    r = 0
    while (r + 1) * (r + 1) <= n:
        r += 1
    return r
```

### task: is-prime
```python
def main(n):
    if n < 2:
        return False
    i = 2
    while i * i <= n:
        if n % i == 0:
            return False
        i += 1
    return True
```

### task: digit-sum
```python
def main(n):
    n = abs(n)
    total = 0
    while n > 0:
        total += n % 10
        n //= 10
    return total
```

### task: lcm
```python
def main(a, b):
    def gcd(x, y):
        while y:
            x, y = y, x % y
        return x
    return a * b // gcd(a, b)
```

### task: allocate
```python
def main(remaining, requested, whole):
    if requested <= remaining:
        return (remaining - requested, requested, 0)
    if remaining == 0:
        return (remaining, 0, 2)
    if whole:
        return (remaining, 0, 3)
    return (0, remaining, 1)
```
