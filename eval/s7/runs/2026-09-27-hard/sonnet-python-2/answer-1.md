### task: sort3
```python
def main(a, b, c):
    lo, mid, hi = sorted([a, b, c])
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
    x, y, z = sides
    if x <= 0 or x + y <= z:
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
    q = a // b
    r = a % b
    return (q, r)
```

### task: isqrt
```python
import math

def main(n):
    return math.isqrt(n)
```

### task: is-prime
```python
def main(n):
    if n < 2:
        return False
    if n < 4:
        return True
    if n % 2 == 0:
        return False
    i = 3
    while i * i <= n:
        if n % i == 0:
            return False
        i += 2
    return True
```

### task: digit-sum
```python
def main(n):
    return sum(int(d) for d in str(abs(n)))
```

### task: lcm
```python
import math

def main(a, b):
    return a // math.gcd(a, b) * b
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
