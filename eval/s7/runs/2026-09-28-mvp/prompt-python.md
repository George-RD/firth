For each task, write a Python 3 function named `main`. Use only the standard library.

Do not use any tool except reading this prompt file and writing your answer file, and do not use the internet. After you answer, you will be shown how each answer did on its task's example: the result, or the diagnostics if it failed. You may then fix your answers; there are at most 2 such rounds.

Answer every task in this exact format, one block per task, and nothing that could be mistaken for one:

### task: <task id>
```python
<source>
```

If you believe a task cannot be written with what is available, still give your best attempt, and add one line after the block starting `NOTE:`.

# Tasks

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Arguments, in order: xs: list[int].
Return: total: int.
Example: main([4, 5, 6]) returns 15.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Arguments, in order: xs: list[int].
Return: largest: int.
Example: main([3, 9, 2]) returns 9.

## count-below
Count the numbers in the sequence that are strictly less than k.
Arguments, in order: xs: list[int], k: int.
Return: count: int.
Example: main([1, 5, 2, 8], 4) returns 2.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Arguments, in order: xs: list[int], x: int.
Return: index: int.
Example: main([7, 3, 9, 3], 3) returns 1.

## reverse
Return the sequence in reverse order.
Arguments, in order: xs: list[int].
Return: reversed: list[int].
Example: main([1, 2, 3]) returns [3, 2, 1].

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Arguments, in order: xs: list[int].
Return: sums: list[int].
Example: main([1, 2, 3]) returns [1, 3, 6].

## keep-positive
Return the elements that are greater than 0, in their original order.
Arguments, in order: xs: list[int].
Return: positives: list[int].
Example: main([3, -1, 0, 4]) returns [3, 4].

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Arguments, in order: xs: list[int].
Return: sorted: bool.
Example: main([1, 2, 2, 5]) returns True.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Arguments, in order: xs: list[int], ys: list[int].
Return: product: int.
Example: main([1, 2, 3], [4, 5, 6]) returns 32.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Arguments, in order: flags: list[bool].
Return: all: bool.
Example: main([True, True, False]) returns False.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Arguments, in order: xs: list[int].
Return: length: int.
Example: main([1, 1, 2, 2, 2, 1]) returns 3.

## has-pair-sum
Return true if two elements at different positions add up to target.
Arguments, in order: xs: list[int], target: int.
Return: found: bool.
Example: main([1, 4, 6, 2], 8) returns True.

## count-distinct
Return how many different values the sequence contains.
Arguments, in order: xs: list[int].
Return: count: int.
Example: main([3, 1, 3, 2, 1]) returns 3.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Arguments, in order: xs: list[int], ys: list[int].
Return: merged: list[int].
Example: main([1, 4, 9], [2, 3, 10]) returns [1, 2, 3, 4, 9, 10].

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Arguments, in order: n: int.
Return: digits: list[int].
Example: main(305) returns [3, 0, 5].

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Arguments, in order: n: int.
Return: primes: list[int].
Example: main(10) returns [2, 3, 5, 7].

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Arguments, in order: xs: list[int], k: int.
Return: counts: list[int].
Example: main([0, 2, 2, 1, 2], 3) returns [1, 1, 3].

## sort
Return the elements sorted in non-decreasing order.
Arguments, in order: xs: list[int].
Return: sorted: list[int].
Example: main([3, 1, 2]) returns [1, 2, 3].

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Arguments, in order: start: int, txs: list[int].
Return: balance: int, rejected: int (as a tuple, in this order).
Example: main(10, [5, -20, -15, 4]) returns (4, 1).

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Arguments, in order: stock: list[int], items: list[int], qtys: list[int], whole: list[bool].
Return: stock-left: list[int], allocated: list[int], reasons: list[int] (as a tuple, in this order).
Example: main([10, 3], [0, 1, 0, 1], [4, 5, 7, 1], [False, True, False, False]) returns ([0, 2], [4, 0, 6, 1], [0, 3, 1, 0]).
