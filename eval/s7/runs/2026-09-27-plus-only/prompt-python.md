For each task, write a Python 3 function named `main`. Use only the standard library. Do not use tools; answer directly.

Answer every task in this exact format, one block per task, and nothing that could be mistaken for one:

### task: <task id>
```python
<source>
```

If you believe a task cannot be written with what is available, still give your best attempt, and add one line after the block starting `NOTE:`.

# Tasks

## triple
Return three times n.
Arguments, in order: n: Int.
Return: r: Int.
Example: main(4) returns 12.

## sum3
Return a + b + c.
Arguments, in order: a: Int, b: Int, c: Int.
Return: r: Int.
Example: main(1, 2, 3) returns 6.

## times10
Return ten times n.
Arguments, in order: n: Int.
Return: r: Int.
Example: main(3) returns 30.

## affine
Return 4*x + 7.
Arguments, in order: x: Int.
Return: r: Int.
Example: main(1) returns 11.

## pair-sum
Leave b and then a + b on the stack (a + b on top).
Arguments, in order: a: Int, b: Int.
Return: b: Int, s: Int (as a tuple, in this order).
Example: main(2, 5) returns (5, 7).

## select
If flag is true return a, otherwise return b.
Arguments, in order: a: Int, b: Int, flag: Bool.
Return: r: Int.
Example: main(7, 9, True) returns 7.

## not
Return the Boolean negation of p.
Arguments, in order: p: Bool.
Return: r: Bool.
Example: main(True) returns False.

## and
Return p AND q.
Arguments, in order: p: Bool, q: Bool.
Return: r: Bool.
Example: main(True, False) returns False.

## xor
Return p XOR q (true when exactly one is true).
Arguments, in order: p: Bool, q: Bool.
Return: r: Bool.
Example: main(True, False) returns True.

## majority
Return true when at least two of p, q, r are true.
Arguments, in order: p: Bool, q: Bool, r: Bool.
Return: m: Bool.
Example: main(True, False, True) returns True.

## count-true
Return how many of p, q, r are true, as an Int.
Arguments, in order: p: Bool, q: Bool, r: Bool.
Return: n: Int.
Example: main(True, False, True) returns 2.

## max
Return the larger of a and b.
Arguments, in order: a: Int, b: Int.
Return: r: Int.
Example: main(3, 8) returns 8.

## min3
Return the smallest of a, b and c.
Arguments, in order: a: Int, b: Int, c: Int.
Return: r: Int.
Example: main(4, 2, 9) returns 2.

## abs-diff
Return |a - b|.
Arguments, in order: a: Int, b: Int.
Return: r: Int.
Example: main(3, 10) returns 7.

## clamp
Return x limited to the range lo..hi (lo <= hi is guaranteed).
Arguments, in order: x: Int, lo: Int, hi: Int.
Return: r: Int.
Example: main(15, 0, 10) returns 10.

## is-even
Return true when n is even.
Arguments, in order: n: Int.
Return: r: Bool.
Example: main(6) returns True.

## sum-to
Return 0 + 1 + ... + n.
Arguments, in order: n: Int.
Return: r: Int.
Example: main(4) returns 10.

## factorial
Return n! (0! = 1).
Arguments, in order: n: Int.
Return: r: Int.
Example: main(4) returns 24.

## fib
Return the n-th Fibonacci number, with fib(0) = 0 and fib(1) = 1.
Arguments, in order: n: Int.
Return: r: Int.
Example: main(6) returns 8.

## gcd
Return the greatest common divisor of a and b (both at least 1).
Arguments, in order: a: Int, b: Int.
Return: r: Int.
Example: main(12, 18) returns 6.

## power
Return base raised to exp (0^0 = 1).
Arguments, in order: base: Int, exp: Int.
Return: r: Int.
Example: main(3, 4) returns 81.

## collatz-steps
Return how many Collatz steps it takes n (n >= 1) to reach 1: halve even numbers, map odd n to 3n + 1.
Arguments, in order: n: Int.
Return: r: Int.
Example: main(6) returns 8.

