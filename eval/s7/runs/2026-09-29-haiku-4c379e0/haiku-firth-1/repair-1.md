Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [
      acc xs i prim seq-int.at prim +
      i 1 prim +
      xs sum-loop
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 8, column 10
message: `sum-loop` in `sum-loop` needs Seq Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int.
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: The top value is Seq Int but `sum-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxval:Int^many -- ρ result:Int^many)
  locals { xs i maxval } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at maxval
      [ maxval xs i prim seq-int.at ] [ xs i prim seq-int.at ] if
      i 1 prim +
      xs max-loop
    ] [
      maxval
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 xs 0 prim seq-int.at max-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 7, column 64
message: The two branches of the `if` in `max-loop` whose true branch is `[ maxval xs i prim seq-int.at ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `maxval` and the result of `prim seq-int.at`; the false branch leaves the result of `prim seq-int.at`.
hint: The true branch leaves 1 value more than the false branch: `maxval` is left below the result of `prim seq-int.at`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        count 1 prim +
      ] [
        count
      ] if
      i 1 prim +
      xs k count-loop
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 13, column 12
message: `count-loop` in `count-loop` needs Seq Int Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int Int.
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: The second value from the top is Seq Int but `count-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [
        i
      ] [
        i 1 prim +
        xs x find-loop
      ] if
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x 0 find-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 11, column 14
message: `find-loop` in `find-loop` needs Seq Int Int Int on top of the stack, but the stack before it is .. Int ?t57 ?t56.
expected: .. Seq Int Int Int
actual: .. Int ?t57 ?t56
hint: The top value is ?t56 but `find-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-build
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      i 1 prim -
      xs reverse-build
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-build
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 17, column 56
message: `reverse-build` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Seq Int Int.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: The top value is Int but `reverse-build` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-build
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      result sum prim seq-int.push
      i 1 prim +
      xs prefix-build
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-build
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 9, column 10
message: `prefix-build` in `prefix-build` needs Seq Int Int Int Seq Int on top of the stack, but the stack before it is .. Int Seq Int Int Seq Int.
expected: .. Seq Int Int Int Seq Int
actual: .. Int Seq Int Int Seq Int
hint: The third value from the top is Seq Int but `prefix-build` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        result
      ] [
        result xs i prim seq-int.at prim seq-int.push
      ] if
      i 1 prim +
      xs filter-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-loop
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        0 prim seq-bool.empty
      ] [
        i 1 prim +
        xs check-sorted
      ] if
    ] [
      1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 check-sorted
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 9
message: The two branches of the `if` in `check-sorted` whose true branch is `[ 0 prim seq-bool.empty ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `0` and the result of `prim seq-bool.empty`; the false branch leaves the result of `check-sorted`.
hint: The true branch leaves 1 value more than the false branch: `0` is left below the result of `prim seq-bool.empty`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      i 1 prim +
      xs ys dot-loop
    ] [
      sum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 8, column 13
message: `dot-loop` in `dot-loop` needs Seq Int Seq Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int Seq Int.
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: The top value is Seq Int but `dot-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        i 1 prim +
        flags check-all
      ] [
        0
      ] if
    ] [
      1
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags 0 check-all
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 9, column 15
message: `check-all` in `check-all` needs Seq Bool Int on top of the stack, but the stack before it is .. Int ?t27.
expected: .. Seq Bool Int
actual: .. Int ?t27
hint: The top value is ?t27 but `check-all` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: scan-runs
  (forall ρ; ρ xs:Seq Int^many i:Int^many curr:Int^many currlen:Int^many maxlen:Int^many -- ρ result:Int^many)
  locals { xs i curr currlen maxlen } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at curr prim =
      [
        currlen 1 prim +
        [ maxlen currlen 1 prim + ] [ maxlen ] if
        i 1 prim +
        xs xs i prim seq-int.at scan-runs
      ] [
        currlen [ maxlen ] [ currlen ] if
        i 1 prim +
        xs xs i prim seq-int.at scan-runs
      ] if
    ] [
      [ maxlen currlen ] [ maxlen ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ] [
      xs 1 xs 0 prim seq-int.at 1 0 scan-runs
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 9, column 48
message: The two branches of the `if` in `scan-runs` whose true branch is `[ maxlen currlen 1 prim + ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `maxlen` and the result of `prim +`; the false branch leaves `maxlen`.
hint: The true branch leaves 1 value more than the false branch: `maxlen` is left below the result of `prim +`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [
      target xs i prim seq-int.at prim - xs prim seq-int.len prim < 0 prim < prim and
      [
        i 1 prim +
        [ 1 ] [ xs target check-pair ] if
      ] [
        i 1 prim +
        xs target check-pair
      ] if
    ] [
      0
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 check-pair
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 9, column 40
message: The two branches of `if` in `check-pair` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-unique
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim <
    [
      xs xs i prim seq-int.at 0 i prim - count-index
      [
        count 1 prim +
      ] [
        count
      ] if
      i 1 prim +
      xs count-unique
    ] [
      count
    ] if
  };

: count-index
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many j:Int^many found:Int^many -- ρ result:Int^many)
  locals { xs x i j found } {
    j 0 prim < prim not
    [
      found
    ] [
      xs j prim seq-int.at x prim =
      [
        1
      ] [
        j 1 prim -
        xs x i count-index
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 0 count-unique
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 7
message: In the true branch `[ xs xs i prim seq-int.at 0 i ...` of the `if` in `count-unique`, `count-index` needs 5 values (xs:Seq Int, x:Int, i:Int, j:Int, found:Int), but the branch has pushed only 3 values before it (`xs`, the result of `prim seq-int.at` and the result of `prim -`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-index`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int, j:Int, found:Int. The branch already pushes `xs`, the result of `prim seq-int.at` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-index` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-step
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        xs ys merge-step
      ] [
        result ys j prim seq-int.at prim seq-int.push
        j 1 prim +
        xs ys merge-step
      ] if
    ] [
      i xs prim seq-int.len prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        xs ys merge-step
      ] [
        j ys prim seq-int.len prim <
        [
          result ys j prim seq-int.at prim seq-int.push
          j 1 prim +
          xs ys merge-step
        ] [
          result
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-step
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 30, column 11
message: In the true branch `[ result ys j prim seq-int.at prim seq-int.push ...` of the `if` in `merge-step`, `merge-step` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-step`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `merge-step` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: extract-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ] [
      n 10 prim mod
      n 10 prim div
      [ prim seq-int.push result swap ] [ result ] if
      extract-digits
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ] [
      n prim seq-int.empty extract-digits
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 52
message: In the true branch `[ prim seq-int.push result swap ]` of the `if` in `extract-digits`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed nothing before it. It would take the result of `prim mod` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Push every value `prim seq-int.push` takes inside the branch, just before it and in this order: Seq Int, Int, for example by writing the locals that hold them. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: sieve-mark
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many k:Int^many n:Int^many -- ρ result:Seq Bool^many)
  locals { sieve p k n } {
    k n prim <
    [
      sieve k 0 prim seq-bool.set
      k p prim +
      sieve p mark-sieve
    ] [
      sieve
    ] if
  };

: mark-sieve
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many k:Int^many n:Int^many -- ρ result:Seq Bool^many)
  locals { sieve p k n } {
    k n prim <
    [
      sieve k 0 prim seq-bool.set
      k p prim +
      sieve p mark-sieve
    ] [
      sieve
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    0
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 6, column 17
message: `prim seq-bool.set` in `sieve-mark` needs Seq Bool Int Bool on top of the stack, but the stack before it is .. Seq Bool Int ?t21 Seq Bool Int Int.
expected: .. Seq Bool Int Bool
actual: .. ?t23 ?t22 ?t21 ?t23 ?t22 Int
hint: The top value is Int but `prim seq-bool.set` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: build-histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      counts
      xs i prim seq-int.at prim seq-int.at 1 prim +
      prim seq-int.set
      i 1 prim +
      xs k build-histogram
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    xs k 0 prim seq-int.empty build-histogram
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 7
message: In the true branch `[ xs i prim seq-int.at counts xs i ...` of the `if` in `build-histogram`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim +`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-one
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs x i } {
    i 0 prim = prim not
    [
      xs i 1 prim - prim seq-int.at x prim <
      [
        xs i prim seq-int.at
        i 1 prim -
        xs x insert-one
      ] [
        xs i x prim seq-int.set
      ] if
    ] [
      xs i x prim seq-int.set
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at insert-one
      i 1 prim +
      xs sort-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 9
message: The two branches of the `if` in `insert-one` whose true branch is `[ xs i prim seq-int.at i 1 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `insert-one`; the false branch leaves the result of `prim seq-int.set`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `insert-one`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: process-transactions
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ final-balance:Int^many rejected-count:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [
        rejected 1 prim +
        i 1 prim +
        txs process-transactions
      ] [
        balance txs i prim seq-int.at prim +
        i 1 prim +
        txs process-transactions
      ] if
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs 0 start 0 process-transactions
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 18, column 7
message: In the true branch `[ balance txs i prim seq-int.at prim + ...` of the `if` in `process-transactions`, `process-transactions` (inside a quotation in that branch) needs 4 values (txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim +` and `txs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `process-transactions`, exactly the values it takes, in this order: txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes the result of `prim +`, the result of `prim +` and `txs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `process-transactions` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-left:Seq Int^many alloc-seq:Seq Int^many reason-seq:Seq Int^many)
  locals { stock items qtys whole j allocated reasons } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      stock
      items j prim seq-int.at prim seq-int.at
      qtys j prim seq-int.at
      whole j prim seq-bool.at
      [ process-order-logic ]
      j 1 prim +
      stock allocated reasons process-order
    ] [
      stock allocated reasons
    ] if
  };

: process-order-logic
  (forall ρ; ρ item:Int^many r:Int^many qty:Int^many is-whole:Bool^many -- ρ alloc:Int^many reason:Int^many)
  locals { item r qty is-whole } {
    qty r prim <
    [
      qty 0
    ] [
      r 0 prim =
      [
        0 2
      ] [
        is-whole
        [
          0 3
        ] [
          r 1
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty process-order
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 7
message: The two branches of the `if` in `process-order` whose true branch is `[ items j prim seq-int.at stock items j ...` leave different numbers of values. The true branch leaves 5 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.at`, the output `stock-left` of `process-order`, the output `alloc-seq` of `process-order` and the output `reason-seq` of `process-order`; the false branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and the result of `prim seq-int.at` are left below the output `stock-left` of `process-order`, the output `alloc-seq` of `process-order` and the output `reason-seq` of `process-order`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.
