Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim <
    [
      result
    ]
    [
      result xs idx prim seq-int.at prim seq-int.push
      xs
      idx 1 prim -
      swap
      reverse-from
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-from
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 1}}, {'kind': 'literal', 'literal': {'type': 'seq-int

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many acc:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx acc result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      acc prim +
      dup
      result swap prim seq-int.push
      xs idx 1 prim +
      swap
      prefix-from
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-from
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-from
at: line 12, column 7
message: `prefix-from` in `prefix-from` takes xs:Seq Int, idx:Int, acc:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Int Seq Int Int Seq Int
hint: The third value from the top, the result of `prim seq-int.push` (Seq Int), is not what `prefix-from` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      0 prim <
      [
        xs
        idx 1 prim +
        result
        filter-from
      ]
      [
        result xs idx prim seq-int.at prim seq-int.push
        xs
        idx 1 prim +
        swap
        filter-from
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-from
  };

```
On the example, it returned [[3, -1, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim <
    [
      xs idx prim seq-int.at
      xs idx 1 prim + prim seq-int.at
      prim <
      [
        false
      ]
      [
        xs
        idx 1 prim +
        check-sorted
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [
      true
    ]
    [
      xs 0 check-sorted
    ]
    if
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
: dot-from
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many idx:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys idx acc } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      ys idx prim seq-int.at
      prim *
      acc prim +
      xs
      ys
      idx 1 prim +
      swap
      dot-from
    ]
    [
      acc
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-from
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-from
at: line 14, column 7
message: `dot-from` in `dot-from` takes xs:Seq Int, ys:Seq Int, idx:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), the result of `prim +` (Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Int Seq Int
hint: These are the values `dot-from` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim +` and `idx 1 prim +` are for `idx` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: max-run
  (forall ρ; ρ xs:Seq Int^many idx:Int^many cur-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs idx cur-run max-run } {
    idx xs prim seq-int.len 1 prim - prim <
    [
      xs idx prim seq-int.at
      xs idx 1 prim + prim seq-int.at
      prim =
      [
        xs
        idx 1 prim +
        cur-run 1 prim +
        max-run
        max-run
      ]
      [
        xs
        idx 1 prim +
        1
        cur-run 1 prim +
        max-run prim <
        [
          cur-run 1 prim +
        ]
        [
          max-run
        ]
        if
      ]
      if
      max-run
    ]
    [
      cur-run 1 prim +
      max-run prim <
      [
        cur-run 1 prim +
      ]
      [
        max-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim <
    [
      0
    ]
    [
      xs 0 1 0 max-run
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-run
at: line 30, column 7
message: The two branches of the `if` in `max-run` whose true branch is `[ xs idx 1 prim + cur-run 1 ...` leave different numbers of values. The true branch leaves 5 values, bottom to top: `xs`, the result of `prim +`, the result of `prim +`, `max-run` and `max-run`; the false branch leaves 4 values, bottom to top: `xs`, the result of `prim +`, `1` and the result of an `if`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `prim +`, the result of `prim +`, `max-run` and `max-run`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct
  (forall ρ; ρ xs:Seq Int^many idx:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs idx seen } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      0
      [ dup seen swap prim seq-int.at prim = ]
      [
        true
      ]
      [
        false
      ]
      if
      [
        xs
        idx 1 prim +
        seen
        count-distinct
      ]
      [
        xs
        idx 1 prim +
        seen xs idx prim seq-int.at prim seq-int.push
        count-distinct
      ]
      if
    ]
    [
      seen prim seq-int.len
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty count-distinct
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-distinct
at: line 33, column 5
message: The two branches of the `if` in `count-distinct` whose true branch is `[ xs idx prim seq-int.at 0 [ dup ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, `0` and the result of `count-distinct`; the false branch leaves the result of `prim seq-int.len`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and `0` are left below the result of `count-distinct`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          result xs i prim seq-int.at prim seq-int.push
          xs
          ys
          i 1 prim +
          j
          swap
          merge-loop
        ]
        [
          result ys j prim seq-int.at prim seq-int.push
          xs
          ys
          i
          j 1 prim +
          swap
          merge-loop
        ]
        if
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        xs
        ys
        i 1 prim +
        j
        swap
        merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        xs
        ys
        i
        j 1 prim +
        swap
        merge-loop
      ]
      [
        result
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-loop
at: line 18, column 11
message: `merge-loop` in `merge-loop` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), `j` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int ?t149 ?t148 Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j swap`. With that edit, the next error in `merge-loop` is at line 21, column 11.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-from
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      swap
      digits-from
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n prim seq-int.empty digits-from
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
: is-prime
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim <
    [
      num divisor prim mod 0 prim =
      [
        false
      ]
      [
        num
        divisor 1 prim +
        is-prime
      ]
      if
    ]
    [
      true
    ]
    if
  };

: primes-from
  (forall ρ; ρ current:Int^many limit:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { current limit result } {
    current limit prim <
    [
      current 2 prim <
      [
        current
        limit
        result
        primes-from
      ]
      [
        current 2 is-prime
        [
          result current prim seq-int.push
          current 1 prim +
          limit
          swap
          primes-from
        ]
        [
          current
          limit
          result
          primes-from
        ]
        if
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty primes-from
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: primes-from
at: line 42, column 11
message: `primes-from` in `primes-from` takes current:Int, limit:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `limit` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t97 Int
hint: These are the values `primes-from` takes, in another order. To push them in its order, write `current 1 prim + limit result current prim seq-int.push` in place of `result current prim seq-int.push current 1 prim + limit swap`. With that edit `primes-from` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k idx counts } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      dup
      counts swap prim seq-int.at
      1 prim +
      swap
      counts swap prim seq-int.set
      xs
      k
      idx 1 prim +
      swap
      histogram-loop
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ dup k prim < ]
    [
      swap 0 prim seq-int.push swap
      1 prim +
      swap
    ]
    [ drop ]
    if
    xs k 0 swap histogram-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 11, column 19
message: `prim seq-int.set` in `histogram-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `counts` (Seq Int) and the result of `prim seq-int.at` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t33 Int Seq Int Int
hint: The second value from the top, `counts` (Seq Int), is not what `prim seq-int.set` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 36, column 5
message: The two branches of the `if` in `main` whose true branch is `[ swap 0 prim seq-int.push swap 1 prim ...` leave different numbers of values. The true branch takes `0` and the result of `prim seq-int.empty` from below the `if` and leaves 2 values, bottom to top: the result of `prim +` and the result of `prim seq-int.push`; the false branch takes `0` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: dup-below
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  locals { a b } {
    a b a
  };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      i 1 prim -
      [ dup 0 prim < ]
      [
        xs swap prim seq-int.at
        dup-below prim <
      ]
      [ drop false ]
      if
      [
        xs
        swap
        dup
        1 prim +
        xs
        swap
        prim seq-int.at
        swap
        prim seq-int.set
        swap
        1 prim -
        swap
      ]
      [
        drop
      ]
      if
      xs
      i 1 prim +
      insertion-sort
    ]
    [
      xs
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 1 insertion-sort
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insertion-sort
at: line 38, column 7
message: In the true branch `[ xs swap dup 1 prim + xs ...` of the `if` in `insertion-sort`, `swap` needs 2 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.set`). Earlier in the branch, the result of an `if` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: apply-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs idx } {
    idx txs prim seq-int.len prim <
    [
      txs idx prim seq-int.at
      balance prim +
      dup 0 prim <
      [
        drop
        balance
        rejected 1 prim +
      ]
      [
        balance
        rejected
      ]
      if
      txs
      idx 1 prim +
      apply-transactions
    ]
    [
      balance
      rejected
    ]
    if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ final-balance:Int^many rejected:Int^many)
  locals { balance txs } {
    balance 0 txs 0 apply-transactions
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: apply-transactions
at: line 18, column 7
message: The two branches of the `if` in `apply-transactions` whose true branch is `[ drop balance rejected 1 prim + ]` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: `balance` and the result of `prim +`; the false branch leaves 2 values, bottom to top: `balance` and `rejected`.
hint: The false branch leaves 1 value more than the true branch: `balance` is left below `rejected`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: dup-below
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  locals { a b } {
    a b a
  };

: allocate-item
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole order-idx allocated reasons } {
    order-idx qtys prim seq-int.len prim <
    [
      items order-idx prim seq-int.at
      dup
      stock swap prim seq-int.at
      dup
      qtys order-idx prim seq-int.at
      dup-below prim <
      [
        qtys order-idx prim seq-int.at
        allocated prim seq-int.push
        0
        reasons prim seq-int.push
        stock
        items
        qtys
        whole
        order-idx 1 prim +
        swap
        prim seq-int.push
        allocate-item
      ]
      [
        swap
        0 prim =
        [
          0
          allocated prim seq-int.push
          2
          reasons prim seq-int.push
          stock
          items
          qtys
          whole
          order-idx 1 prim +
          allocated
          reasons
          allocate-item
        ]
        [
          whole order-idx prim seq-bool.at
          [
            0
            allocated prim seq-int.push
            3
            reasons prim seq-int.push
            stock
            items
            qtys
            whole
            order-idx 1 prim +
            allocated
            reasons
            allocate-item
          ]
          [
            dup
            allocated prim seq-int.push
            1
            reasons prim seq-int.push
            stock
            swap
            prim seq-int.set
            items
            qtys
            whole
            order-idx 1 prim +
            swap
            prim seq-int.push
            allocate-item
          ]
          if
        ]
        if
      ]
      if
    ]
    [
      stock
      allocated
      reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-item
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-item
at: line 81, column 11
message: The two branches of `if` in `allocate-item` leave different numbers of values: the true branch pushes 5 values, and the false branch takes 3 values from the stack below the `if` and leaves 3 values. The false branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
