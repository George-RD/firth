For each task, write a Python 3 function named `main`. Use only the standard library. Do not use tools; answer directly.

Answer every task in this exact format, one block per task, and nothing that could be mistaken for one:

### task: <task id>
```python
<source>
```

If you believe a task cannot be written with what is available, still give your best attempt, and add one line after the block starting `NOTE:`.

# Tasks

## sort3
Leave a, b and c sorted so the smallest is at the bottom and the largest on top.
Arguments, in order: a: Int, b: Int, c: Int.
Return: lo: Int, mid: Int, hi: Int (as a tuple, in this order).
Example: main(3, 1, 2) returns (1, 2, 3).

## median3
Return the middle value of a, b and c.
Arguments, in order: a: Int, b: Int, c: Int.
Return: m: Int.
Example: main(9, 1, 5) returns 5.

## triangle-kind
Classify side lengths a, b, c: return 0 if they cannot form a triangle with positive area (a zero side, or the two shorter sides sum to no more than the longest), 1 if equilateral, 2 if isosceles, 3 if scalene.
Arguments, in order: a: Int, b: Int, c: Int.
Return: kind: Int.
Example: main(3, 4, 5) returns 3.

## divmod
Return the quotient and then the remainder of a divided by b (b is at least 1).
Arguments, in order: a: Int, b: Int.
Return: q: Int, r: Int (as a tuple, in this order).
Example: main(17, 5) returns (3, 2).

## isqrt
Return the largest r with r * r <= n.
Arguments, in order: n: Int.
Return: r: Int.
Example: main(10) returns 3.

## is-prime
Return true when n is a prime number.
Arguments, in order: n: Int.
Return: r: Bool.
Example: main(7) returns True.

## digit-sum
Return the sum of the decimal digits of n.
Arguments, in order: n: Int.
Return: r: Int.
Example: main(42) returns 6.

## lcm
Return the least common multiple of a and b (both at least 1).
Arguments, in order: a: Int, b: Int.
Return: r: Int.
Example: main(4, 6) returns 12.

## allocate
Allocate stock for one order. If requested <= remaining, allocate all of it (reason 0). Otherwise, if remaining is 0, allocate nothing (reason 2). Otherwise, if whole is true the order must be filled completely, so allocate nothing (reason 3); if whole is false allocate everything that remains (reason 1). Return the stock left, the quantity allocated and the reason code.
Arguments, in order: remaining: Int, requested: Int, whole: Bool.
Return: left: Int, allocated: Int, reason: Int (as a tuple, in this order).
Example: main(10, 4, False) returns (6, 4, 0).
