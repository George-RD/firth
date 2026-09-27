### task: sort3
```python
def main(a, b, c):
    return tuple(sorted([a, b, c]))
```

### task: median3
```python
def main(a, b, c):
    return sorted([a, b, c])[1]
```

### task: triangle-kind
```python
def main(a, b, c):
    if a <= 0 or b <= 0 or c <= 0:
        return 0
    sides = sorted([a, b, c])
    if sides[0] + sides[1] <= sides[2]:
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
    if n == 2:
        return True
    if n % 2 == 0:
        return False
    for i in range(3, int(n**0.5) + 1, 2):
        if n % i == 0:
            return False
    return True
```

### task: digit-sum
```python
def main(n):
    return sum(int(d) for d in str(abs(n)))
```

### task: lcm
```python
def main(a, b):
    def gcd(x, y):
        while y:
            x, y = y, x % y
        return x
    g = gcd(a, b)
    return (a * b) // g
```

### task: allocate
```python
def main(remaining, requested, whole):
    if requested <= remaining:
        return (remaining - requested, requested, 0)
    elif remaining == 0:
        return (remaining, 0, 2)
    elif whole:
        return (remaining, 0, 3)
    else:
        return (0, remaining, 1)
```
