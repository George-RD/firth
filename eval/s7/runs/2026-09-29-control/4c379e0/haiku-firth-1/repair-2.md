Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs idx acc } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at acc prim + xs idx 1 prim + sum-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 57
message: `sum-loop` in `sum-loop` needs Seq Int Int Int on top of the stack, but the stack before it is .. Int Seq Int Int.
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: The second value from the top is Seq Int but `sum-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs idx max } {
    idx xs prim seq-int.len prim <
    [ 
      xs idx prim seq-int.at max prim <
      [ xs idx 1 prim + max max-loop ]
      [ xs idx 1 prim + xs idx prim seq-int.at max-loop ]
      if
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 1 xs 0 prim seq-int.at max-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 17, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many k:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs idx k cnt } {
    idx xs prim seq-int.len prim <
    [ 
      xs idx prim seq-int.at k prim <
      [ xs idx 1 prim + k cnt 1 prim + count-loop ]
      [ xs idx 1 prim + k cnt count-loop ]
      if
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 count-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 17, column 5
message: `count-loop` in `main` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int.
expected: .. Seq Int Int Int Int
actual: ρ Seq Int Int Int
hint: `count-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ rev:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim <
    [ xs idx prim seq-int.at result prim seq-int.push xs idx 1 prim - result reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs idx sum result } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at sum prim + xs idx 1 prim + result sum prim seq-int.push prefix-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 86
message: `prefix-loop` in `prefix-loop` needs Seq Int Int Int Seq Int on top of the stack, but the stack before it is .. Int Seq Int Int Seq Int.
expected: .. Seq Int Int Int Seq Int
actual: .. Int Seq Int Int Seq Int
hint: The third value from the top is Seq Int but `prefix-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [ 
      xs idx prim seq-int.at 0 prim <
      [ xs idx 1 prim + result filter-loop ]
      [ xs idx prim seq-int.at result prim seq-int.push xs idx 1 prim + filter-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty filter-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 8, column 39
message: `prim seq-int.push` in `filter-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t80.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t80
hint: The top value is ?t80 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim <
    [ 
      xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs idx 1 prim + sorted-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs prim seq-int.len 1 prim <
  [ true ]
  [ 0 sorted-loop ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 17, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many idx:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys idx sum } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + xs ys idx 1 prim + dot-loop ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 dot-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 90
message: `dot-loop` in `dot-loop` needs Seq Int Seq Int Int Int on top of the stack, but the stack before it is .. Int Seq Int Seq Int Int.
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: The second value from the top is Seq Int but `dot-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many idx:Int^many -- ρ all:Bool^many)
  locals { flags idx } {
    idx flags prim seq-bool.len prim <
    [ 
      flags idx prim seq-bool.at
      [ idx 1 prim + all-loop ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 all-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 9, column 7
message: In the true branch `[ idx 1 prim + all-loop ]` of the `if` in `all-loop`, `all-loop` needs 2 values (flags:Seq Bool, idx:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: flags:Seq Bool, idx:Int. The branch already pushes the result of `prim +`, in the place of the last one (idx:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many cur-run:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs idx cur-run max-run } {
    idx xs prim seq-int.len prim <
    [ 
      xs idx prim seq-int.at xs idx 1 prim - prim seq-int.at prim =
      [ xs idx 1 prim + cur-run 1 prim + max-run run-loop ]
      [ xs idx 1 prim + 1 cur-run max-run prim < [ cur-run ] [ max-run ] if run-loop ]
      if
    ]
    [ cur-run max-run prim < [ max-run ] [ cur-run ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ 1 1 0 run-loop ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 17, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-count
  (forall ρ; ρ xs:Seq Int^many val:Int^many idx:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs val idx found } {
    idx xs prim seq-int.len prim <
    [ 
      xs idx prim seq-int.at val prim =
      [ true ]
      [ xs val idx 1 prim + found inner-count ]
      if
    ]
    [ found ]
    if
  };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many cnt:Int^many -- ρ count:Int^many)
  locals { xs idx cnt } {
    idx xs prim seq-int.len prim <
    [ 
      xs xs idx prim seq-int.at 0 false inner-count
      [ xs idx 1 prim + cnt 1 prim + distinct-loop ]
      [ xs idx 1 prim + cnt distinct-loop ]
      if
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 distinct-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 31, column 5
message: `distinct-loop` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int.
expected: .. Seq Int Int Int
actual: ρ Seq Int Int
hint: `distinct-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim < 
      [ xs i prim seq-int.at ys j prim seq-int.at prim <
        [ xs i prim seq-int.at result prim seq-int.push xs ys i 1 prim + j merge-loop ]
        [ ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + merge-loop ]
        if
      ]
      [ xs i prim seq-int.at result prim seq-int.push xs ys i 1 prim + j merge-loop ]
      if
    ]
    [ j ys prim seq-int.len prim <
      [ ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + merge-loop ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty merge-loop;

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 24, column 22
message: `merge-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `merge-loop` and in what order.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digit-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim =
  [ 0 prim seq-int.empty prim seq-int.push ]
  [ prim seq-int.empty digit-loop ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 12, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [ 
      n d prim mod 0 prim =
      [ false ]
      [ n d 1 prim + is-prime-check ]
      if
    ]
    [ true ]
    if
  };

: sieve-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <
    [ 
      i 2 prim <
      [ n i 1 prim + result sieve-loop ]
      [ i 2 is-prime-check
        [ i result prim seq-int.push n i 1 prim + sieve-loop ]
        [ n i 1 prim + result sieve-loop ]
        if
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty sieve-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 23, column 44
message: `prim +` in `sieve-loop` needs Int Int on top of the stack, but the stack before it is .. Seq Int ?t96 Seq Int Int.
expected: .. Int Int
actual: .. Seq Int ?t96 Seq Int Int
hint: The second value from the top is Seq Int but `prim +` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many counts:Seq Int^many -- ρ hist:Seq Int^many)
  locals { xs k idx counts } {
    idx xs prim seq-int.len prim <
    [ 
      xs idx prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + counts v prim seq-int.set xs k idx 1 prim + histogram-loop }
    ]
    [ counts ]
    if
  };

: init-loop
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i counts } {
    i k prim <
    [ 0 counts prim seq-int.push k i 1 prim + init-loop ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty init-loop histogram-loop;

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 23, column 32
message: `histogram-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `histogram-loop` and in what order.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ x:Int^many result:Seq Int^many idx:Int^many -- ρ sorted:Seq Int^many)
  locals { x result idx } {
    idx 0 prim <
    [ result ]
    [ result idx prim seq-int.at x prim <
      [ result idx 1 prim + x result idx prim seq-int.set x result idx prim - insert-loop ]
      [ x result prim seq-int.push ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at result idx 1 prim - insert-loop xs idx 1 prim + sort-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty sort-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 9, column 7
message: The two branches of the `if` in `insert-loop` whose true branch is `[ result idx 1 prim + x result ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `result`, the result of `prim +` and the result of `insert-loop`; the false branch leaves the result of `prim seq-int.push`.
hint: The true branch leaves 2 values more than the false branch: `result` and the result of `prim +` are left below the result of `insert-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ result-balance:Int^many result-rejected:Int^many)
  locals { balance rejected txs idx } {
    idx txs prim seq-int.len prim <
    [ 
      balance txs idx prim seq-int.at prim + 0 prim <
      [ balance rejected 1 prim + txs idx 1 prim + ledger-loop ]
      [ balance txs idx prim seq-int.at prim + rejected txs idx 1 prim + ledger-loop ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 ledger-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 17, column 5
message: `ledger-loop` in `main` needs Int Int Seq Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int.
expected: .. Int Int Seq Int Int
actual: ρ Int Seq Int Int
hint: `ledger-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
    idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-left:Seq Int^many allocated-seq:Seq Int^many reasons-seq:Seq Int^many)
  locals { stock items qtys whole idx allocated reasons } {
    idx qtys prim seq-int.len prim <
    [ 
      stock items idx prim seq-int.at prim seq-int.at locals { current-stock } {
        qtys idx prim seq-int.at current-stock prim <
        [
          qtys idx prim seq-int.at stock items idx prim seq-int.at prim seq-int.set
          qtys idx prim seq-int.at allocated prim seq-int.push
          0 reasons prim seq-int.push
        ]
        [
          current-stock 0 prim =
          [
            stock
            0 allocated prim seq-int.push
            2 reasons prim seq-int.push
          ]
          [
            whole idx prim seq-bool.at
            [
              stock
              0 allocated prim seq-int.push
              3 reasons prim seq-int.push
            ]
            [
              stock items idx prim seq-int.at current-stock prim seq-int.set
              current-stock allocated prim seq-int.push
              1 reasons prim seq-int.push
            ]
            if
          ]
          if
        ]
        if
      }
      stock items qtys whole idx 1 prim + allocate-loop
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 allocate-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 42, column 5
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ stock items idx prim seq-int.at prim seq-int.at ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: the result of an `if`, the output `stock-left` of `allocate-loop`, the output `allocated-seq` of `allocate-loop` and the output `reasons-seq` of `allocate-loop`; the false branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`.
hint: The true branch leaves 1 value more than the false branch: the result of an `if` is left below the output `stock-left` of `allocate-loop`, the output `allocated-seq` of `allocate-loop` and the output `reasons-seq` of `allocate-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
