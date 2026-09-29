Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs xs 0 prim seq-int.at 1 max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max prim <
      [
        xs i prim seq-int.at locals { new-max } { xs i 1 prim + new-max max-loop }
      ]
      [
        xs i 1 prim + max max-loop
      ]
      if
    ]
    [
      max
    ]
    if
  };

```
On the example, it returned [1] instead of [9]

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty locals { xs rev } { xs rev xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many rev:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs rev i } {
    0 i prim <
    [
      xs i prim seq-int.at rev prim seq-int.push locals { new-rev } { xs new-rev i 1 prim - reverse-loop }
    ]
    [
      rev
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 10, column 32
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `rev` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `rev xs i prim seq-int.at` in place of `xs i prim seq-int.at rev`. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 locals { xs result sum } { xs result sum 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs result sum i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim + locals { new-sum } { new-sum result prim seq-int.push locals { new-result } { xs new-result new-sum i 1 prim + prefix-loop } }
    ]
    [
      result
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 10, column 75
message: `prim seq-int.push` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `new-sum` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t30 Int Int ?t30
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result new-sum` in place of `new-sum result`. With that edit `prefix-loop` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty locals { xs result } { xs result 0 filter-loop };

: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        xs i prim seq-int.at result prim seq-int.push locals { new-result } { xs new-result i 1 prim + filter-loop }
      ]
      [
        xs result i 1 prim + filter-loop
      ]
      if
    ]
    [
      result
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: filter-loop
at: line 12, column 37
message: `prim seq-int.push` in `filter-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t46
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `filter-loop` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  true locals { xs sorted } { xs sorted 0 check-sorted };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many sorted:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { xs sorted i } {
    sorted
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not
        [
          false
        ]
        [
          xs sorted i 1 prim + check-sorted
        ]
        if
      ]
      [
        true
      ]
      if
    ]
    [
      false
    ]
    if
  };

```
On the example, it returned [False] instead of [True]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 locals { xs maxlen } { xs maxlen 0 1 run-loop };

: run-loop
  (forall ρ; ρ xs:Seq Int^many maxlen:Int^many i:Int^many runlen:Int^many -- ρ result:Int^many)
  locals { xs maxlen i runlen } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        1
      ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          runlen 1 prim +
        ]
        [
          1
        ]
        if
      ]
      if locals { cur-len } { cur-len maxlen prim < [ cur-len ] [ maxlen ] if locals { new-max } { xs new-max i 1 prim + run-loop } }
    ]
    [
      maxlen
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 29, column 5
message: In the true branch `[ i 0 prim = [ 1 ] ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, maxlen:Int, i:Int, runlen:Int), but the branch has pushed only 3 values before it (`xs`, `new-max` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, maxlen:Int, i:Int, runlen:Int. The branch already pushes `xs`, `new-max` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false locals { xs target found } { xs target found 0 pair-search };

: pair-search
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { xs target found i } {
    found
    [
      true
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs target i i 1 prim + pair-inner
      ]
      [
        false
      ]
      if
    ]
    if
  };

: pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true
      ]
      [
        xs target i j 1 prim + pair-inner
      ]
      if
    ]
    [
      xs target i 1 prim + pair-search
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-inner
at: line 42, column 5
message: In the false branch of the `if` in `pair-inner` whose true branch is `[ xs i prim seq-int.at xs j prim ...`, `pair-search` needs 4 values (xs:Seq Int, target:Int, found:Bool, i:Int), but the branch has pushed only 3 values before it (`xs`, `target` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `pair-search`, exactly the values it takes, in this order: xs:Seq Int, target:Int, found:Bool, i:Int. The branch already pushes `xs`, `target` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `pair-search` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 locals { xs count } { xs count 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs count i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 0 is-new-value
      [
        count 1 prim + locals { new-count } { xs new-count i 1 prim + distinct-loop }
      ]
      [
        xs count i 1 prim + distinct-loop
      ]
      if
    ]
    [
      count
    ]
    if
  };

: is-new-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many start:Int^many -- ρ result:Bool^many)
  locals { xs val start } { xs val start start check-new };

: check-new
  (forall ρ; ρ xs:Seq Int^many val:Int^many start:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs val start i } {
    i start prim <
    [
      xs i prim seq-int.at val prim =
      [
        false
      ]
      [
        xs val start i 1 prim + check-new
      ]
      if
    ]
    [
      true
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-loop
at: line 22, column 5
message: The two branches of the `if` in `distinct-loop` whose true branch is `[ xs i prim seq-int.at xs i 0 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `distinct-loop`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `distinct-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ res:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          xs i prim seq-int.at result prim seq-int.push locals { new-result } { xs ys new-result i 1 prim + j merge-loop }
        ]
        [
          ys j prim seq-int.at result prim seq-int.push locals { new-result } { xs ys new-result i j 1 prim + merge-loop }
        ]
        if
      ]
      [
        xs i prim seq-int.at result prim seq-int.push locals { new-result } { xs ys new-result i 1 prim + j merge-loop }
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at result prim seq-int.push locals { new-result } { xs ys new-result i j 1 prim + merge-loop }
      ]
      [
        result
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 14, column 39
message: `prim seq-int.push` in `merge-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t148 ?t147 Int ?t149
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit, the next error in `merge-loop` is at line 17, column 39.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      prim seq-int.empty n digits-loop
    ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod result prim seq-int.push locals { new-result } { new-result n 10 prim div digits-loop }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digits-loop
at: line 22, column 28
message: `prim seq-int.push` in `digits-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `digits-loop` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty locals { n primes } { n primes 2 prime-loop };

: prime-loop
  (forall ρ; ρ n:Int^many primes:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { n primes i } {
    i n prim < prim not
    [
      n primes i prime-loop
    ]
    [
      i locals { check-i } { check-i 2 is-prime }
      [
        i primes prim seq-int.push locals { new-primes } { n new-primes i 1 prim + prime-loop }
      ]
      [
        n primes i 1 prim + prime-loop
      ]
      if
    ]
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
      n 2 check-prime-divisor
    ]
    if
  };

: check-prime-divisor
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        n d 1 prim + check-prime-divisor
      ]
      if
    ]
    [
      true
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prime-loop
at: line 22, column 5
message: The two branches of the `if` in `prime-loop` whose true branch is `[ n primes i prime-loop ]` leave different numbers of values. The true branch leaves the result of `prime-loop`; the false branch leaves 2 values, bottom to top: `check-i` and the result of `prime-loop`.
hint: The false branch leaves 1 value more than the true branch: `check-i` is left below the result of `prime-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { xs k prim seq-int.empty 0 init-hist };

: init-hist
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs k counts i } {
    i k prim <
    [
      counts 0 prim seq-int.push locals { new-counts } { xs k new-counts i 1 prim + init-hist }
    ]
    [
      xs k counts 0 count-hist
    ]
    if
  };

: count-hist
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs k counts i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { val } { val counts val prim seq-int.at 1 prim + counts val prim seq-int.set locals { new-counts } { xs k new-counts i 1 prim + count-hist } }
    ]
    [
      counts
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-hist
at: line 28, column 5
message: The two branches of the `if` in `count-hist` whose true branch is `[ xs i prim seq-int.at locals { val ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `val` and the result of `count-hist`; the false branch leaves `counts`.
hint: The true branch leaves 1 value more than the false branch: `val` is left below the result of `count-hist`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs sort-step };

: sort-step
  (forall ρ; ρ xs:Seq Int^many sorted:Seq Int^many -- ρ res:Seq Int^many)
  locals { xs sorted } {
    sorted prim seq-int.len 0 prim =
    [
      prim seq-int.empty
    ]
    [
      sorted 0 prim seq-int.at locals { min-val } { sorted 1 sorted prim seq-int.len min-val find-min-remove locals { new-sorted } { new-sorted min-val prim seq-int.push locals { added-sorted } { xs added-sorted sort-step } } }
    ]
    if
  };

: find-min-remove
  (forall ρ; ρ sorted:Seq Int^many i:Int^many min:Int^many -- ρ result:Seq Int^many)
  locals { sorted i min } {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at min prim <
      [
        sorted i prim seq-int.at
      ]
      [
        min
      ]
      if locals { cur-min } { sorted i 1 prim + cur-min find-min-remove }
    ]
    [
      min
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sort-step
at: line 15, column 5
message: The two branches of the `if` in `sort-step` whose true branch is `[ prim seq-int.empty ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.empty`; the false branch leaves 2 values, bottom to top: `sorted` and the result of `sort-step`. `sort-step` calls `find-min-remove`, which has an error of its own; this report assumes `find-min-remove` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: `sorted` is left below the result of `sort-step`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: find-min-remove
at: line 35, column 5
message: The two branches of `if` in `find-min-remove` leave different stacks. Below the condition and the two quotations the stack is ρ; the true branch leaves ρ Seq Int and the false branch leaves ρ Int.
expected: ρ Seq Int
actual: ρ Int
hint: Both leave 1 value, but the top value is Seq Int after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 locals { start txs balance rejected } { start txs balance rejected 0 apply-tx };

: apply-tx
  (forall ρ; ρ start:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { start txs balance rejected i } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at balance prim + 0 prim < 
      [
        start txs balance rejected 1 prim + i 1 prim + apply-tx
      ]
      [
        txs i prim seq-int.at balance prim + locals { new-balance } { start txs new-balance rejected i 1 prim + apply-tx }
      ]
      if
    ]
    [
      balance rejected
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 45
message: `roll 3` in `main` ran out of values: the stack before it is ρ Int Seq Int Int.
expected: .. ?t3
actual: ρ
hint: A word can only use values declared as inputs in its signature or pushed earlier in its body. Add the missing input to the signature or push it first. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 
  locals { stock items qtys whole alloc reasons idx } 
  { stock items qtys whole alloc reasons idx process-order };

: process-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole alloc reasons idx } {
    idx qtys prim seq-int.len prim <
    [
      items idx prim seq-int.at locals { item-idx } { stock item-idx prim seq-int.at } locals { available } { qtys idx prim seq-int.at whole idx prim seq-bool.at stock items qtys whole alloc reasons available determine-allocation
    ]
    [
      stock alloc reasons
    ]
    if
  };

: determine-allocation
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many available:Int^many qty:Int^many full:Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole alloc reasons available qty full } {
    qty available prim < prim not
    [
      alloc qty prim seq-int.push locals { new-alloc } { reasons 0 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons 0 continue-process } }
    ]
    [
      available 0 prim =
      [
        alloc 0 prim seq-int.push locals { new-alloc } { reasons 2 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons 0 continue-process } }
      ]
      [
        full
        [
          alloc 0 prim seq-int.push locals { new-alloc } { reasons 3 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons 0 continue-process } }
        ]
        [
          alloc available prim seq-int.push locals { new-alloc } { reasons 1 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons available continue-process } }
        ]
        if
      ]
      if
    ]
    if
  };

: continue-process
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many deduct:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock alloc reasons deduct } { stock alloc reasons };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 13, column 5
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
