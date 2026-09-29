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
  locals { xs } {
    xs 0 prim seq-int.at
    1
    xs
    loop-max
  };

: loop-max
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      max prim <
      [ xs i prim seq-int.at ]
      [ max ]
      if
      i 1 prim +
      xs
      loop-max
    ]
    [ max ]
    if
  };

```
On the example, it returned [2] instead of [9]

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len
    1 prim -
    xs
    prim seq-int.empty
    loop-reverse
  };

: loop-reverse
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      xs result
      loop-reverse
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-reverse
at: line 23, column 5
message: The two branches of the `if` in `loop-reverse` whose true branch is `[ xs i prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `loop-reverse`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `loop-reverse`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 0 prim seq-int.empty xs loop-prefix };

: loop-prefix
  (forall ρ; ρ sum:Int^many i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { sum i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      sum prim +
      dup
      result prim seq-int.push
      i 1 prim +
      xs
      loop-prefix
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-prefix
at: line 13, column 14
message: `prim seq-int.push` in `loop-prefix` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t28
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs loop-keep };

: loop-keep
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem 0 prim <
        [ result ]
        [ result elem prim seq-int.push ]
        if
      }
      i 1 prim +
      xs
      loop-keep
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop-keep
at: line 19, column 7
message: `loop-keep` in `loop-keep` takes i:Int, result:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Seq Int Int Seq Int
hint: The second value from the top, the result of `prim +` (Int), is not what `loop-keep` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len
    1 prim -
    0 xs
    loop-is-sorted
  };

: loop-is-sorted
  (forall ρ; ρ len:Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { len i xs } {
    i len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <
      [
        false
      ]
      [
        i 1 prim +
        len xs
        loop-is-sorted
      ]
      if
    ]
    [ true ]
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
: max
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim <
    [ b ]
    [ a ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len
    dup 0 prim =
    [ drop 0 ]
    [ dup 1 prim = [ drop 1 ] [ drop 1 1 1 xs loop-longest ] if ]
    if
  };

: loop-longest
  (forall ρ; ρ max-len:Int^many curr-len:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-len curr-len i xs } {
    i xs prim seq-int.len prim <
    [
      xs i 1 prim - prim seq-int.at
      xs i prim seq-int.at
      prim =
      [
        curr-len 1 prim +
        max-len
        max
        i 1 prim +
        xs
        loop-longest
      ]
      [
        curr-len
        max-len
        max
        i 1 prim +
        1
        xs
        loop-longest
      ]
      if
    ]
    [ curr-len max-len max ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-longest
at: line 45, column 7
message: In the true branch `[ curr-len 1 prim + max-len max i ...` of the `if` in `loop-longest`, `loop-longest` needs 4 values (max-len:Int, curr-len:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `max`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-longest`, exactly the values it takes, in this order: max-len:Int, curr-len:Int, i:Int, xs:Seq Int. The branch already pushes the result of `max`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-longest` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs loop-count-dist };

: loop-count-dist
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      0 i xs [ xs prim seq-int.at i prim < loop-find-dup ] dip
      [
        count 1 prim +
        i 1 prim +
        xs
        loop-count-dist
      ]
      [
        i 1 prim +
        xs
        loop-count-dist
      ]
      if
    ]
    [ count ]
    if
  };

: loop-find-dup
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many -- ρ is-dup:Bool^many)
  locals { j i xs } {
    j i prim <
    [
      xs j prim seq-int.at
      xs i prim seq-int.at
      prim =
      [ true ]
      [ j 1 prim + i xs loop-find-dup ]
      if
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-count-dist
at: line 22, column 7
message: The two branches of `if` in `loop-count-dist` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { 0 0 prim seq-int.empty xs ys loop-merge };

: loop-merge
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i j result xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          xs i prim seq-int.at
          result prim seq-int.push
          i 1 prim +
          j result xs ys
          loop-merge
        ]
        [
          ys j prim seq-int.at
          result prim seq-int.push
          j 1 prim +
          i result xs ys
          loop-merge
        ]
        if
      ]
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        j result xs ys
        loop-merge
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at
        result prim seq-int.push
        j 1 prim +
        i result xs ys
        loop-merge
      ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-merge
at: line 50, column 7
message: The two branches of the `if` in `loop-merge` whose true branch is `[ ys j prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `loop-merge`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `loop-merge`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    [ { 0 } ]
    [ n prim seq-int.empty loop-digits ]
    if
  };

: loop-digits
  (forall ρ; ρ num:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { num result } {
    num 0 prim =
    [
      result
      dup prim seq-int.len
      dup 1 prim -
      [ prim seq-int.at swap ] dip
      [ 0 swap loop-reverse-digits ] dip
    ]
    [
      num 10 prim mod
      result prim seq-int.push
      num 10 prim div
      result
      loop-digits
    ]
    if
  };

: loop-reverse-digits
  (forall ρ; ρ idx:Int^many len:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { idx len result } {
    idx len prim <
    [ idx len result loop-reverse-digits ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-digits
at: line 28, column 5
message: In the true branch `[ result dup prim seq-int.len dup 1 prim ...` of the `if` in `loop-digits`, `swap` (inside a quotation in that branch) needs 2 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        2 n loop-check-prime
      ]
      if
    ]
    if
  };

: loop-check-prime
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod
      0 prim =
      [ false ]
      [ d 1 prim + n loop-check-prime ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { 2 prim seq-int.empty n loop-primes };

: loop-primes
  (forall ρ; ρ i:Int^many result:Seq Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { i result n } {
    i n prim <
    prim not
    [
      i is-prime
      [
        i result prim seq-int.push
        i 1 prim +
        n
        loop-primes
      ]
      [
        i 1 prim +
        n
        loop-primes
      ]
      if
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-primes
at: line 54, column 7
message: In the false branch of the `if` in `loop-primes` whose true branch is `[ i result prim seq-int.push i 1 prim ...`, `loop-primes` needs 3 values (i:Int, result:Seq Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-primes`, exactly the values it takes, in this order: i:Int, result:Seq Int, n:Int. The branch already pushes the result of `prim +` and `n`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0
    [ prim seq-int.empty k loop-init-hist ] dip
    0 xs
    loop-histogram
  };

: loop-init-hist
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      loop-init-hist
    ]
    [ result ]
    if
  };

: loop-histogram
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { v } {
        v result prim seq-int.at
        1 prim +
        v result prim seq-int.set
      }
      i 1 prim +
      xs
      loop-histogram
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 5, column 28
message: `loop-init-hist` in `main` needs Int Int Seq Int on top of the stack, but the stack before it is .. Int Seq Int ?t4. `main` calls `loop-init-hist`, which has an error of its own; this report assumes `loop-init-hist` keeps its stack effect.
expected: .. Int Int Seq Int
actual: .. Seq Int ?t4
hint: `loop-init-hist` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.word-input-mismatch
word: loop-init-hist
at: line 18, column 7
message: `loop-init-hist` in `loop-init-hist` takes i:Int, k:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `k` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t24
hint: These are the values `loop-init-hist` takes, in another order. To push them in its order, write `i 1 prim + k result 0 prim seq-int.push` in place of `result 0 prim seq-int.push i 1 prim + k`. With that edit `loop-init-hist` checks.

error 3 of 3
code: firth.type.primitive-input-mismatch
word: loop-histogram
at: line 31, column 18
message: `prim seq-int.at` in `loop-histogram` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `v` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t23 Int Int ?t23
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `result v` in place of `v result`. With that edit, the next error in `loop-histogram` is at line 33, column 18.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 loop-sort };

: loop-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i } {
    i arr prim seq-int.len prim <
    [
      i arr loop-insert
      i 1 prim +
      loop-sort
    ]
    [ arr ]
    if
  };

: loop-insert
  (forall ρ; ρ i:Int^many arr:Seq Int^many -- ρ result:Seq Int^many)
  locals { i arr } {
    i 0 prim >
    [
      arr i 1 prim - prim seq-int.at
      arr i prim seq-int.at
      prim <
      [
        arr i prim seq-int.at
        arr i 1 prim - prim seq-int.set
        arr i 1 prim - prim seq-int.at
        arr i prim seq-int.set
        i 1 prim -
        arr
        loop-insert
      ]
      [ arr ]
      if
    ]
    [ arr ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: loop-insert
at: line 21, column 9
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs loop-ledger };

: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim +
        dup 0 prim <
        [
          drop
          balance
          rejected 1 prim +
        ]
        [
          swap drop
          rejected
        ]
        if
      }
      i 1 prim +
      txs
      loop-ledger
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-ledger
at: line 23, column 9
message: In the false branch of the `if` in `loop-ledger` whose true branch is `[ drop balance rejected 1 prim + ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim +` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { 0 stock prim seq-int.empty prim seq-int.empty prim seq-int.empty whole loop-alloc };

: loop-alloc
  (forall ρ; ρ i:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { i stock allocated reasons whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim <
            [
              stock item qty r prim seq-int.set
              qty
              0
            ]
            [
              r 0 prim =
              [
                stock
                0
                2
              ]
              [
                whole i prim seq-bool.at
                [
                  stock
                  0
                  3
                ]
                [
                  stock item 0 r prim seq-int.set
                  r
                  1
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
      i 1 prim +
      allocated
      reasons
      whole
      loop-alloc
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 110
message: `loop-alloc` in `main` takes i:Int, stock:Seq Int, allocated:Seq Int, reasons:Seq Int, whole:Seq Bool, bottom to top, but here it gets, bottom to top, `stock` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `whole` (Seq Bool). `main` calls `loop-alloc`, which has an error of its own; this report assumes `loop-alloc` keeps its stack effect.
expected: .. Int Seq Int Seq Int Seq Int Seq Bool
actual: ρ Seq Int Seq Int Int Seq Int Seq Int Seq Int Seq Int Seq Bool
hint: Value 5 from the top, `stock` (Seq Int), is not what `loop-alloc` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: loop-alloc
at: line 8, column 7
message: `items` is not a defined word, primitive or local.
actual: items
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
