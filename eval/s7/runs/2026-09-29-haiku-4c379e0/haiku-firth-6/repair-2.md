Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i len xs } {
    i len prim <
    [ xs i prim seq-int.at sum prim + swap drop sum-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 11, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 xs prim seq-int.len max-loop };

: max-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i len xs max } {
    i len prim <
    [ xs i prim seq-int.at max dup prim < [ drop ] [ swap drop ] if max-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 11, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs prim seq-int.len count-loop };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i len xs k } {
    i len prim <
    [ xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if swap drop count-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 3, column 45
message: `count-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `count-loop` and in what order.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs prim seq-int.len x xs find-index };

: find-index
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i len xs x } {
    i len prim <
    [ xs i prim seq-int.at x prim =
      [ i drop drop drop ]
      [ i 1 prim + i drop find-index ]
      if
    ]
    [ drop -1 drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 15, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    [ ]
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - reverse-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 10, column 35
message: `prim seq-int.push` in `reverse-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t20.
expected: .. Seq Int Int
actual: .. Int Int ?t20
hint: The top value is ?t20 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i len xs } {
    i len prim <
    [ xs i prim seq-int.at sum prim + sum 1 prim + result prim seq-int.push drop prefix-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 11, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len keep-positive-loop };

: keep-positive-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [ xs i prim seq-int.at dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      i 1 prim + keep-positive-loop
    ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 5
message: In the true branch `[ xs i prim seq-int.at dup 0 prim ...` of the `if` in `keep-positive-loop`, `keep-positive-loop` needs 4 values (result:Seq Int, i:Int, len:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `keep-positive-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, len:Int, xs:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `keep-positive-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    xs prim seq-int.len dup 1 prim <
    [ drop true ]
    [ xs 0 1 check-sorted ]
    if
  };

: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim < 
      [ false ]
      [ i 1 prim + check-sorted ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 7, column 5
message: The two branches of the `if` in `main` whose true branch is `[ drop true ]` leave different numbers of values. The true branch takes the result of `prim seq-int.len` from below the `if` and leaves `true`; the false branch leaves 2 values, bottom to top: `xs` and the result of `check-sorted`.
hint: The false branch leaves 2 values more than the true branch: `xs` and the result of `check-sorted` are left by the false branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs prim seq-int.len dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i len xs ys } {
    i len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 3, column 46
message: `dot-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `dot-loop` and in what order.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 0 flags prim seq-bool.len all-true-loop };

: all-true-loop
  (forall ρ; ρ i:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { i len flags } {
    i len prim <
    [ flags i prim seq-bool.at
      [ i 1 prim + all-true-loop ]
      [ drop drop false ]
      if
    ]
    [ drop drop true ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 15, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len dup 0 prim <
    [ drop 0 ]
    [ dup 1 prim <
      [ drop 1 ]
      [ 1 1 xs 0 prim seq-int.at longest-run-loop ]
      if
    ]
    if
  };

: longest-run-loop
  (forall ρ; ρ i:Int^many current:Int^many max:Int^many prev:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i current max prev xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup prev prim =
      [ current 1 prim + max dup prim < [ drop ] [ swap drop ] if i 1 prim + longest-run-loop ]
      [ swap drop 1 max i 1 prim + longest-run-loop ]
      if
    ]
    [ drop drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 9, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ drop 1 ]`, `longest-run-loop` needs 5 values (i:Int, current:Int, max:Int, prev:Int, xs:Seq Int), but the branch has pushed only 3 values before it (`1`, `1` and the result of `prim seq-int.at`). It would take the result of `prim seq-int.len` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `longest-run-loop`, exactly the values it takes, in this order: i:Int, current:Int, max:Int, prev:Int, xs:Seq Int. The branch already pushes `1`, `1` and the result of `prim seq-int.at`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `longest-run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len check-pairs };

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target } {
    i len prim <
    [ i 1 prim + xs target find-pair-for ]
    [ drop drop false ]
    if
  };

: find-pair-for
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ drop drop drop true ]
      [ j 1 prim + find-pair-for ]
      if
    ]
    [ drop drop drop check-pairs ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 3, column 48
message: `check-pairs` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `check-pairs` and in what order.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i len xs } {
    i len prim <
    [ xs i prim seq-int.at xs 0 i is-new-value
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim + count-distinct-loop
    ]
    [ drop drop drop ]
    if
  };

: is-new-value
  (forall ρ; ρ val:Int^many start:Int^many end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val start end xs } {
    start end prim <
    [ xs start prim seq-int.at val prim =
      [ drop drop drop false ]
      [ start 1 prim + is-new-value ]
      if
    ]
    [ drop drop drop true ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 5
message: In the true branch `[ xs i prim seq-int.at xs 0 i ...` of the `if` in `count-distinct-loop`, `count-distinct-loop` needs 4 values (count:Int, i:Int, len:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-distinct-loop`, exactly the values it takes, in this order: count:Int, i:Int, len:Int, xs:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-distinct-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-sorted-loop };

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim <
    prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-sorted-loop ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-sorted-loop ]
      if
    ]
    [ i xs prim seq-int.len prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-sorted-loop ]
      [ j ys prim seq-int.len prim <
        [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-sorted-loop ]
        [ drop drop drop drop ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 21, column 9
message: In the true branch `[ ys j prim seq-int.at result prim seq-int.push ...` of the `if` in `merge-sorted-loop`, `merge-sorted-loop` needs 5 values (result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-sorted-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `merge-sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ [ 0 ] ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    n 0 prim <
    [ drop ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digits-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 5
message: In the true branch `[ drop ]` of the `if` in `digits-loop`, `drop` needs 1 value, but the branch has pushed nothing before it. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `drop` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result i n } {
    i n prim <
    [ i is-prime
      [ i result prim seq-int.push ]
      [ result ]
      if
      i 1 prim + primes-loop
    ]
    [ drop drop drop ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 prim = [ true ] [ 2 n check-divisor ] if ]
    if
  };

: check-divisor
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ result:Bool^many)
  locals { divisor n } {
    divisor dup prim * n prim <
    [ n divisor prim mod 0 prim =
      [ false ]
      [ divisor 1 prim + check-divisor ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 5
message: In the true branch `[ i is-prime [ i result prim seq-int.push ...` of the `if` in `primes-loop`, `primes-loop` needs 3 values (result:Seq Int, i:Int, n:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `primes-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, n:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `primes-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty 0 k create-histogram 0 xs prim seq-int.len histogram-loop
  };

: create-histogram
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { counts i k } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + create-histogram ]
    [ drop drop ]
    if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i len xs counts } {
    i len prim <
    [ xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set i 1 prim + histogram-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 5
message: In the true branch `[ counts 0 prim seq-int.push i 1 prim ...` of the `if` in `create-histogram`, `create-histogram` needs 3 values (counts:Seq Int, i:Int, k:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `create-histogram`, exactly the values it takes, in this order: counts:Seq Int, i:Int, k:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `create-histogram` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len 1 prim - insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { result i len } {
    i len prim <
    [ result i result i prim seq-int.at insert-into i 1 prim + insertion-sort-loop ]
    [ drop drop drop ]
    if
  };

: insert-into
  (forall ρ; ρ pos:Int^many val:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { pos val j result } {
    j 0 prim <
    [ result pos val prim seq-int.set ]
    [ result j prim seq-int.at val prim <
      [ j 1 prim + insert-into ]
      [ result pos val prim seq-int.set ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 11, column 5
message: In the true branch `[ result i result i prim seq-int.at insert-into ...` of the `if` in `insertion-sort-loop`, `insert-into` needs 4 values (pos:Int, val:Int, j:Int, result:Seq Int), but the branch has pushed only 3 values before it (`result`, `i` and the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-into`, exactly the values it takes, in this order: pos:Int, val:Int, j:Int, result:Seq Int. The branch already pushes `result`, `i` and the result of `prim seq-int.at`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `insert-into` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs prim seq-int.len ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i len txs } {
    i len prim <
    [ txs i prim seq-int.at dup balance prim + dup 0 prim <
      [ drop drop rejected 1 prim + i 1 prim + ledger-loop ]
      [ balance rejected i 1 prim + ledger-loop ]
      if
    ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 7
message: In the true branch `[ drop drop rejected 1 prim + i ...` of the `if` in `ledger-loop`, `ledger-loop` needs 5 values (balance:Int, rejected:Int, i:Int, len:Int, txs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). Earlier in the branch, the result of `prim +` and the result of `prim seq-int.at` were already taken from below the `if`. The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: balance:Int, rejected:Int, i:Int, len:Int, txs:Seq Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many len:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock-left allocated reasons j len stock items qtys whole } {
    j len prim <
    [ items j prim seq-int.at dup
      stock swap prim seq-int.at dup
      qtys j prim seq-int.at dup
      whole j prim seq-bool.at
      locals { w q r item } {
        q r prim <
        [ r 0 prim =
          [ 0 2 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
          [ w
            [ 0 3 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
            [ r 1 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
            if
          ]
          if
        ]
        [ q r prim seq-int.set stock-left allocated reasons 0 ]
        if
        j 1 prim + allocate-loop
      }
    ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 4, column 92
message: `allocate-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `allocate-loop` and in what order.
