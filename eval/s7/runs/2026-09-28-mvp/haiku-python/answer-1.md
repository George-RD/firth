### task: seq-sum
```python
def main(xs):
    return sum(xs)
```

### task: seq-max
```python
def main(xs):
    return max(xs)
```

### task: count-below
```python
def main(xs, k):
    return sum(1 for x in xs if x < k)
```

### task: index-of
```python
def main(xs, x):
    try:
        return xs.index(x)
    except ValueError:
        return -1
```

### task: reverse
```python
def main(xs):
    return xs[::-1]
```

### task: prefix-sums
```python
def main(xs):
    result = []
    total = 0
    for x in xs:
        total += x
        result.append(total)
    return result
```

### task: keep-positive
```python
def main(xs):
    return [x for x in xs if x > 0]
```

### task: is-sorted
```python
def main(xs):
    for i in range(len(xs) - 1):
        if xs[i] > xs[i + 1]:
            return False
    return True
```

### task: dot
```python
def main(xs, ys):
    return sum(x * y for x, y in zip(xs, ys))
```

### task: all-true
```python
def main(flags):
    for flag in flags:
        if not flag:
            return False
    return True
```

### task: longest-run
```python
def main(xs):
    if not xs:
        return 0
    max_run = 1
    current_run = 1
    for i in range(1, len(xs)):
        if xs[i] == xs[i - 1]:
            current_run += 1
            max_run = max(max_run, current_run)
        else:
            current_run = 1
    return max_run
```

### task: has-pair-sum
```python
def main(xs, target):
    seen = set()
    for x in xs:
        if target - x in seen:
            return True
        seen.add(x)
    return False
```

### task: count-distinct
```python
def main(xs):
    return len(set(xs))
```

### task: merge-sorted
```python
def main(xs, ys):
    result = []
    i = j = 0
    while i < len(xs) and j < len(ys):
        if xs[i] <= ys[j]:
            result.append(xs[i])
            i += 1
        else:
            result.append(ys[j])
            j += 1
    result.extend(xs[i:])
    result.extend(ys[j:])
    return result
```

### task: digits
```python
def main(n):
    if n == 0:
        return [0]
    digits = []
    while n > 0:
        digits.append(n % 10)
        n //= 10
    return digits[::-1]
```

### task: primes-up-to
```python
def main(n):
    if n < 2:
        return []
    is_prime = [True] * (n + 1)
    is_prime[0] = is_prime[1] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            for j in range(i * i, n + 1, i):
                is_prime[j] = False
    return [i for i in range(2, n + 1) if is_prime[i]]
```

### task: histogram
```python
def main(xs, k):
    counts = [0] * k
    for x in xs:
        counts[x] += 1
    return counts
```

### task: sort
```python
def main(xs):
    return sorted(xs)
```

### task: ledger
```python
def main(start, txs):
    balance = start
    rejected = 0
    for tx in txs:
        if balance + tx >= 0:
            balance += tx
        else:
            rejected += 1
    return (balance, rejected)
```

### task: allocate-batch
```python
def main(stock, items, qtys, whole):
    stock = list(stock)
    allocated = []
    reasons = []
    
    for i in range(len(items)):
        item_idx = items[i]
        qty = qtys[i]
        is_whole = whole[i]
        current_stock = stock[item_idx]
        
        if qty <= current_stock:
            allocated.append(qty)
            reasons.append(0)
            stock[item_idx] -= qty
        elif current_stock == 0:
            allocated.append(0)
            reasons.append(2)
        elif is_whole:
            allocated.append(0)
            reasons.append(3)
        else:
            allocated.append(current_stock)
            reasons.append(1)
            stock[item_idx] = 0
    
    return (stock, allocated, reasons)
```
