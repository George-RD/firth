Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs acc i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at acc prim +
      xs swap
      i 1 prim +
      sum-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 0 xs sum-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `sum-loop` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Int Int Seq Int.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value is Seq Int but `sum-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many max-val:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs max-val i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max-val prim <
      [
        xs i prim seq-int.at
        xs
        i 1 prim +
        max-loop
      ]
      [
        max-val
        xs
        i 1 prim +
        max-loop
      ]
      if
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 0 xs max-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `max-loop` in `max-loop` needs Seq Int Int Int on top of the stack, but the stack before it is .. Int Seq Int Int.
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: The second value from the top is Seq Int but `max-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many cnt:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k cnt i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        cnt 1 prim +
      ]
      [
        cnt
      ]
      if
      xs k swap
      i 1 prim +
      count-loop
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `count-loop` in `count-loop` needs Seq Int Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int Int.
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: The second value from the top is Seq Int but `count-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      xs result
      i 1 prim -
      reverse-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 2 more values than it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result sum i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      result swap prim seq-int.push
      xs result sum
      i 1 prim +
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 2 more values than it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        result
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
      ]
      if
      xs swap
      i 1 prim +
      filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs filter-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `filter-loop` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Int Seq Int.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Int Seq Int
hint: The top value is Seq Int but `filter-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        false
      ]
      [
        xs
        i 1 prim +
        check-sorted
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs 0 check-sorted
  };

```
On the example, it returned [False] instead of [True]

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs ys sum i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      xs ys swap
      i 1 prim +
      dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `dot-loop` in `dot-loop` needs Seq Int Seq Int Int Int on top of the stack, but the stack before it is .. Int Seq Int Seq Int Int.
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: The second value from the top is Seq Int but `dot-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ xs:Seq Int^many prev:Int^many current-len:Int^many max-len:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs prev current-len max-len i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at prev prim =
      [
        current-len 1 prim +
        xs
        xs i prim seq-int.at
        current-len 1 prim + max-len prim <
        [
          max-len
        ]
        [
          current-len 1 prim +
        ]
        if
        i 1 prim +
        count-run
      ]
      [
        1
        xs
        xs i prim seq-int.at
        current-len max-len prim <
        [
          max-len
        ]
        [
          current-len
        ]
        if
        i 1 prim +
        count-run
      ]
      if
    ]
    [
      current-len max-len prim <
      [
        max-len
      ]
      [
        current-len
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      xs 0 prim seq-int.at 1 0 1 xs count-run
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `count-run` in `count-run` needs Seq Int Int Int Int Int on top of the stack, but the stack before it is .. Int Seq Int Int Int Int.
expected: .. Seq Int Int Int Int Int
actual: .. Int Seq Int Int Int Int
hint: Value 4 from the top is Seq Int but `count-run` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-duplicate
  (forall ρ; ρ xs:Seq Int^many val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs val i } {
    i 0 prim <
    [
      xs i prim seq-int.at val prim =
      [
        true
      ]
      [
        xs val
        i 1 prim -
        is-duplicate
      ]
      if
    ]
    [ false ]
    if
  };

: count-dist-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs xs i prim seq-int.at
      i 1 prim -
      is-duplicate
      [
        result
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
      ]
      if
      xs swap
      i 1 prim +
      count-dist-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs count-dist-loop prim seq-int.len
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `count-dist-loop` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Int Seq Int.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Int Seq Int
hint: The top value is Seq Int but `count-dist-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ result-final:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        xs ys swap
        i 1 prim +
        j
        merge-loop
      ]
      [
        result ys j prim seq-int.at prim seq-int.push
        xs ys swap
        i
        j 1 prim +
        merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        xs ys swap
        i 1 prim +
        j
        merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          result ys j prim seq-int.at prim seq-int.push
          xs ys swap
          i
          j 1 prim +
          merge-loop
        ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `merge-loop` in `main` needs Seq Int Seq Int Seq Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int Seq Int Seq Int.
expected: .. Seq Int Seq Int Seq Int Int Int
actual: ρ Seq Int Int Int Seq Int Seq Int
hint: The top value is Seq Int but `merge-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result-final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [
      result
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      extract-digits
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ]
    [
      prim seq-int.empty n extract-digits
    ]
    if
  };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        n
        d 1 prim +
        is-prime-check
      ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [
      false
    ]
    [
      n
      2
      is-prime-check
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ result:Seq Int^many limit:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { result limit i } {
    i limit prim < prim not prim not
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      limit
      i 1 prim +
      sieve-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-int.empty n 2 sieve-loop
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many k:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at result xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      xs swap
      i 1 prim +
      k
      histogram-loop
    ]
    [ result ]
    if
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { result k i } {
    i k prim <
    [
      result 0 prim seq-int.push
      k
      i 1 prim +
      init-histogram
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k 0 init-histogram xs 0 k histogram-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves as many values as it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { result val i } {
    i result prim seq-int.len prim <
    [
      result i prim seq-int.at val prim <
      [
        result i val prim seq-int.set
      ]
      [
        result
        val
        i 1 prim +
        insert-sorted
      ]
      if
    ]
    [
      result val prim seq-int.push
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at 0 insert-sorted
      xs swap
      i 1 prim +
      sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs sort-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `sort-loop` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Int Seq Int.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Int Seq Int
hint: The top value is Seq Int but `sort-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ result-balance:Int^many result-rejected:Int^many)
  locals { start txs balance rejected i } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [
        balance
        rejected 1 prim +
        txs
        i 1 prim +
        ledger-loop
      ]
      [
        balance txs i prim seq-int.at prim +
        rejected
        txs
        i 1 prim +
        ledger-loop
      ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ result-balance:Int^many result-rejected:Int^many)
  locals { start txs } {
    start txs 0 0 txs ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 1 more value than it takes, and the false branch leaves 2 more values than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-order
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    j allocated prim seq-int.len prim =
    [
      stock allocated reasons
    ]
    [
      items j prim seq-int.at stock qtys j prim seq-int.at stock items j prim seq-int.at prim seq-int.at prim <
      [
        stock items j prim seq-int.at qtys j prim seq-int.at prim seq-int.set
        allocated qtys j prim seq-int.at prim seq-int.push
        reasons 0 prim seq-int.push
        stock allocated reasons items qtys whole j 1 prim + process-order
      ]
      [
        stock items j prim seq-int.at prim seq-int.at 0 prim =
        [
          stock
          allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          items qtys whole
          j 1 prim +
          process-order
        ]
        [
          whole j prim seq-bool.at
          [
            stock
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            items qtys whole
            j 1 prim +
            process-order
          ]
          [
            stock items j prim seq-int.at stock items j prim seq-int.at prim seq-int.at prim seq-int.set
            allocated stock items j prim seq-int.at prim seq-int.at prim seq-int.push
            reasons 1 prim seq-int.push
            stock allocated reasons items qtys whole j 1 prim + process-order
          ]
          if
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty prim seq-int.empty stock items qtys whole 0 process-order
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 3 more values than it takes, and the false branch leaves 6 more values than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.
