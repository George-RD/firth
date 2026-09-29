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
  locals { xs } { sum-loop xs 0 0 };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ total:Int^many)
  locals { xs i sum } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at sum prim +
      sum-loop
    ] [
      sum
    ] if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 19
message: `sum-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `sum-loop` and in what order.

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
    xs 0 prim seq-int.at xs 1 max-loop
  };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs i max } {
    i 1 prim + xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i 1 prim + prim seq-int.at dup max prim < [
        drop
      ] [
        swap drop
      ] if
      xs i 2 prim + max-loop
    ] [
      max
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 31
message: `max-loop` in `main` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `1` (Int). `main` calls `max-loop`, which has an error of its own; this report assumes `max-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 21, column 7
message: The two branches of the `if` in `max-loop` whose true branch is `[ xs i 1 prim + xs i ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `max-loop`; the false branch leaves `max`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `max-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { count-loop xs k 0 0 };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ count:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at k prim < [
        xs k i count 1 prim + count-loop
      ] [
        xs k i 1 prim + count count-loop
      ] if
    ] [
      count
    ] if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 21
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
  locals { xs x } { index-loop xs x 0 };

: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        xs x i 1 prim + index-loop
      ] if
    ] [
      -1
    ] if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 21
message: `index-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `index-loop` and in what order.

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
    prim seq-int.empty xs rev-build
  };

: rev-build
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result xs } {
    xs prim seq-int.len 0 prim > [
      xs prim seq-int.len 1 prim - dup xs swap prim seq-int.at result prim seq-int.push
      xs result
      rev-build
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: rev-build
at: line 10, column 27
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs ps-build
  };

: ps-build
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim +
      result i prim seq-int.push
      result swap xs i 1 prim + ps-build
    ] [
      result
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 29
message: `ps-build` in `main` needs Seq Int Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Int Seq Int. `main` calls `ps-build`, which has an error of its own; this report assumes `ps-build` keeps its stack effect.
expected: .. Seq Int Int Seq Int Int
actual: ρ Seq Int Int Seq Int
hint: `ps-build` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: ps-build
at: line 16, column 7
message: The two branches of the `if` in `ps-build` whose true branch is `[ xs i prim seq-int.at sum prim + ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `ps-build`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `ps-build`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 keep-loop
  };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup 0 prim < [
        drop result xs i 1 prim + keep-loop
      ] [
        result prim seq-int.push xs i 1 prim + keep-loop
      ] if
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: keep-loop
at: line 14, column 16
message: `prim seq-int.push` in `keep-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs prim seq-int.len 1 prim < [
      true
    ] [
      xs 0 is-sorted-loop
    ] if
  };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [
        false
      ] [
        xs i 1 prim + is-sorted-loop
      ] if
    ] [
      true
    ] if
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
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { dot-loop xs ys 0 0 };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      xs ys i 1 prim + dot-loop
    ] [
      sum
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 22
message: `dot-loop` needs more values than the stack holds here. `main` calls `dot-loop`, which has an error of its own; this report assumes `dot-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `dot-loop` and in what order.

error 2 of 2
code: firth.type.word-input-mismatch
word: dot-loop
at: line 10, column 24
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { all-loop flags 0 };

: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim < [
      flags i prim seq-bool.at [
        flags i 1 prim + all-loop
      ] [
        false
      ] if
    ] [
      true
    ] if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 22
message: `all-loop` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `all-loop` and in what order.

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
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 0 1 1 run-loop
    ] if
  };

: run-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many i:Int^many maxlen:Int^many runlen:Int^many -- ρ length:Int^many)
  locals { xs prev i maxlen runlen } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup prev prim = [
        runlen 1 prim + dup maxlen prim < [
          drop xs i 1 prim + maxlen runlen 1 prim + run-loop
        ] [
          xs i 1 prim + swap run-loop
        ] if
      ] [
        xs i 1 prim + swap 1 maxlen runlen prim < [
          runlen
        ] [
          maxlen
        ] if run-loop
      ] if
    ] [
      maxlen runlen prim < [
        runlen
      ] [
        maxlen
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 8, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `run-loop` needs 5 values (xs:Seq Int, prev:Int, i:Int, maxlen:Int, runlen:Int), but the branch has pushed only 4 values before it (`xs`, `0`, `1` and `1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `run-loop`, which has an error of its own; this report assumes `run-loop` keeps its stack effect.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, prev:Int, i:Int, maxlen:Int, runlen:Int. The branch already pushes `xs`, `0`, `1` and `1`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 20, column 11
message: In the false branch of the `if` in `run-loop` whose true branch is `[ drop xs i 1 prim + maxlen ...`, `run-loop` needs 5 values (xs:Seq Int, prev:Int, i:Int, maxlen:Int, runlen:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). It would take the result of `prim seq-int.at` and the result of `prim +` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, prev:Int, i:Int, maxlen:Int, runlen:Int. The branch already pushes the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { has-pair-loop xs target 0 };

: has-pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at xs inner-pair-loop target i 1 prim + has-pair-loop
    ] [
      false
    ] if
  };

: inner-pair-loop
  (forall ρ; ρ xs:Seq Int^many j:Int^many curr:Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs j curr target i } {
    j xs prim seq-int.len prim < [
      j i prim = [
        xs j 1 prim + curr target i inner-pair-loop
      ] [
        xs j prim seq-int.at curr prim + target prim = [
          true
        ] [
          xs j 1 prim + curr target i inner-pair-loop
        ] if
      ] if
    ] [
      xs target i 1 prim + has-pair-loop
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 26
message: `has-pair-loop` needs more values than the stack holds here. `main` calls `has-pair-loop`, which has an error of its own; this report assumes `has-pair-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `has-pair-loop` and in what order.

error 2 of 2
code: firth.type.branch-mismatch
word: has-pair-loop
at: line 12, column 7
message: In the true branch `[ xs i prim seq-int.at xs inner-pair-loop target ...` of the `if` in `has-pair-loop`, `inner-pair-loop` needs 5 values (xs:Seq Int, j:Int, curr:Int, target:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and `xs`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-pair-loop`, exactly the values it takes, in this order: xs:Seq Int, j:Int, curr:Int, target:Int, i:Int. The branch already pushes the result of `prim seq-int.at` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-pair-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 distinct-loop
  };

: distinct-loop
  (forall ρ; ρ dists:Seq Int^many xs:Seq Int^many i:Int^many -- ρ count:Int^many)
  locals { dists xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dists is-in [
        dists xs i 1 prim + distinct-loop
      ] [
        dists prim seq-int.push xs i 1 prim + distinct-loop
      ] if
    ] [
      dists prim seq-int.len
    ] if
  };

: is-in
  (forall ρ; ρ dists:Seq Int^many val:Int^many -- ρ found:Bool^many)
  locals { dists val } {
    dists 0 find-val val
  };

: find-val
  (forall ρ; ρ dists:Seq Int^many i:Int^many val:Int^many -- ρ found:Bool^many)
  locals { dists i val } {
    i dists prim seq-int.len prim < [
      dists i prim seq-int.at val prim = [
        true
      ] [
        dists i 1 prim + val find-val
      ] if
    ] [
      false
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: distinct-loop
at: line 15, column 9
message: In the false branch of the `if` in `distinct-loop` whose true branch is `[ dists xs i 1 prim + distinct-loop ]`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`dists`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `distinct-loop` calls `is-in`, which has an error of its own; this report assumes `is-in` keeps its stack effect.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `dists`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last one (Int) after it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: is-in
at: line 24, column 13
message: The quotation run by `dip` in `is-in` does not accept the stack below it (ρ Seq Int Int Int [ .. Seq Int Int Int -- .. Bool ]).
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty xs ys 0 0 merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [
          result prim seq-int.push xs ys i j 1 prim + merge-loop
        ] if
      ] [
        xs i prim seq-int.at result prim seq-int.push xs ys i 1 prim + j merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + merge-loop
      ] [
        result
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 19, column 9
message: In the true branch `[ xs i prim seq-int.at ys j prim ...` of the `if` in `merge-loop`, `prim seq-int.push` (inside a quotation in that branch) needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `result`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last one (Int) after it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    n 0 prim = [
      { 0 }
    ] [
      n prim seq-int.empty digit-loop
    ] if
  };

: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim > [
      n 10 prim mod result prim seq-int.push n 10 prim div digit-loop
    ] [
      result reverse-seq
    ] if
  };

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - rev-seq-loop
  };

: rev-seq-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.push xs i 1 prim - rev-seq-loop
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: digit-loop
at: line 14, column 9
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 1 prim < [
      prim seq-int.empty
    ] [
      prim seq-int.empty 2 n prime-loop
    ] if
  };

: prime-loop
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { primes candidate limit } {
    candidate limit prim < [
      candidate is-prime [
        primes candidate prim seq-int.push candidate 1 prim + limit prime-loop
      ] [
        primes candidate 1 prim + limit prime-loop
      ] if
    ] [
      candidate limit prim = [
        candidate is-prime [
          primes candidate prim seq-int.push
        ] [
          primes
        ] if
      ] [
        primes
      ] if
    ] if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim < [
      false
    ] [
      num 2 prim = [
        true
      ] [
        num 2 check-divisor
      ] if
    ] if
  };

: check-divisor
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim < [
      num divisor prim mod 0 prim = [
        false
      ] [
        num divisor 2 prim + check-divisor
      ] if
    ] [
      true
    ] if
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
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k init-histogram xs 0 hist-loop
  };

: init-histogram
  (forall ρ; ρ counts:Seq Int^many remaining:Int^many -- ρ counts:Seq Int^many)
  locals { counts remaining } {
    remaining 0 prim > [
      counts 0 prim seq-int.push remaining 1 prim - init-histogram
    ] [
      counts
    ] if
  };

: hist-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set
      xs i 1 prim + hist-loop
    ] [
      counts
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved-effect
word: init-histogram
at: line 10, column 17
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: hist-loop
at: line 21, column 81
message: `prim seq-int.set` in `hist-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `counts` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Seq Int Int
hint: The second value from the top, `counts` (Seq Int), is not what `prim seq-int.set` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs sort-insertion
  };

: sort-insertion
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 1 insert-step
  };

: insert-step
  (forall ρ; ρ xs:Seq Int^many sorted:Int^many unsorted:Int^many -- ρ sorted:Seq Int^many)
  locals { xs sorted unsorted } {
    unsorted xs prim seq-int.len prim < [
      xs xs unsorted prim seq-int.at xs sorted 0 find-insert-pos prim seq-int.set
      xs sorted 1 prim + unsorted 1 prim + insert-step
    ] [
      xs
    ] if
  };

: find-insert-pos
  (forall ρ; ρ xs:Seq Int^many val:Int^many pos:Int^many -- ρ xs:Seq Int^many)
  locals { xs val pos } {
    pos 0 prim < [
      xs
    ] [
      xs pos prim seq-int.at val prim < [
        xs val pos find-insert-pos
      ] [
        xs
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insert-step
at: line 21, column 7
message: The two branches of the `if` in `insert-step` whose true branch is `[ xs xs unsorted prim seq-int.at xs sorted ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-step`; the false branch leaves `xs`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-step`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 txs 0 ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at balance prim + dup 0 prim < [
        drop balance rejected 1 prim + txs i 1 prim + ledger-loop
      ] [
        balance rejected txs i 1 prim + ledger-loop
      ] if
    ] [
      balance rejected
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 15, column 9
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ drop balance rejected 1 prim + txs ...` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: the output `balance` of `ledger-loop` and the output `rejected` of `ledger-loop`; the false branch leaves 2 values, bottom to top: the output `balance` of `ledger-loop` and the output `rejected` of `ledger-loop`.
hint: The true branch takes the result of `prim +` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

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
    stock prim seq-int.empty prim seq-int.empty 0 allocate-orders
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons order items qtys whole } {
    order qtys prim seq-int.len prim < [
      items order prim seq-int.at dup stock swap prim seq-int.at dup
      qtys order prim seq-int.at dup
      whole order prim seq-bool.at
      process-order
    ] [
      stock alloc reasons
    ] if
  };

: process-order
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many item:Int^many current-stock:Int^many qty:Int^many w:Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons order items qtys whole item current-stock qty w } {
    qty current-stock prim < [
      current-stock 0 prim = [
        alloc 0 prim seq-int.push reasons 2 prim seq-int.push stock item current-stock prim seq-int.set order 1 prim + items qtys whole allocate-orders
      ] [
        w [
          alloc 0 prim seq-int.push reasons 3 prim seq-int.push stock item current-stock prim seq-int.set order 1 prim + items qtys whole allocate-orders
        ] [
          alloc current-stock prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set order 1 prim + items qtys whole allocate-orders
        ] if
      ] if
    ] [
      alloc qty prim seq-int.push reasons 0 prim seq-int.push stock item current-stock qty prim - prim seq-int.set order 1 prim + items qtys whole allocate-orders
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 4, column 51
message: `allocate-orders` needs more values than the stack holds here. `main` calls `allocate-orders`, which has an error of its own; this report assumes `allocate-orders` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `allocate-orders` and in what order.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-orders
at: line 17, column 7
message: In the true branch `[ items order prim seq-int.at dup stock swap ...` of the `if` in `allocate-orders`, `process-order` needs 11 values (stock:Seq Int, alloc:Seq Int, reasons:Seq Int, order:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, item:Int, current-stock:Int, qty:Int, w:Bool), but the branch has pushed only 6 values before it (the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `process-order`, exactly the values it takes, in this order: stock:Seq Int, alloc:Seq Int, reasons:Seq Int, order:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, item:Int, current-stock:Int, qty:Int, w:Bool. The branch already pushes the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`: keep each in its place where it is one of these and replace it where it is not, and push the other 5 in their places, for example by writing the locals that hold them. If `process-order` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
