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
    i xs prim seq-int.len prim >=
    [ acc ]
    [
      acc i xs prim seq-int.at prim +
      i 1 prim +
      xs
      sum-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sum-loop
at: line 7, column 16
message: `prim seq-int.at` in `sum-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `sum-loop` is at line 10, column 7.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim >=
    [ max-val ]
    [
      i xs prim seq-int.at
      max-val prim >
      [ i xs prim seq-int.at ] [ max-val ] if
      i 1 prim +
      xs
      max-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 1 xs 0 prim seq-int.at max-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: max-loop
at: line 7, column 12
message: `prim seq-int.at` in `max-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `max-loop` is at line 9, column 14.

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
    i xs prim seq-int.len prim >=
    [ count ]
    [
      i xs prim seq-int.at k prim <
      [ count 1 prim + ] [ count ] if
      i 1 prim +
      xs
      k
      count-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: count-loop
at: line 7, column 12
message: `prim seq-int.at` in `count-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `count-loop` is at line 12, column 7.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim >=
    [ -1 ]
    [
      i xs prim seq-int.at x prim =
      [ i ] [ i 1 prim + xs x index-loop ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x 0 index-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: index-loop
at: line 7, column 12
message: `prim seq-int.at` in `index-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `index-loop` is at line 8, column 31.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      result i xs prim seq-int.at prim seq-int.push
      i 1 prim -
      xs
      reverse-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - xs reverse-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 7, column 19
message: `prim seq-int.at` in `reverse-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      sum i xs prim seq-int.at prim +
      result
      dup
      sum
      prim seq-int.push
      i 1 prim +
      xs
      prefix-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 16, column 5
message: The two branches of the `if` in `prefix-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prefix-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of `prefix-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      i xs prim seq-int.at 0 prim >
      [ result i xs prim seq-int.at prim seq-int.push ] [ result ] if
      i 1 prim +
      xs
      keep-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty keep-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: keep-loop
at: line 7, column 12
message: `prim seq-int.at` in `keep-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `keep-loop` is at line 8, column 21.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [
      i xs prim seq-int.at
      i 1 prim + xs prim seq-int.at
      prim <=
      [
        i 1 prim +
        xs
        sorted-loop
      ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 sorted-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sorted-loop
at: line 7, column 12
message: `prim seq-int.at` in `sorted-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `sorted-loop` is at line 8, column 21.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim >=
    [ sum ]
    [
      sum i xs prim seq-int.at i ys prim seq-int.at prim * prim +
      i 1 prim +
      xs
      ys
      dot-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: dot-loop
at: line 7, column 16
message: `prim seq-int.at` in `dot-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `dot-loop` is at line 7, column 37.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim >=
    [ true ]
    [
      i flags prim seq-bool.at
      [
        i 1 prim +
        flags
        all-loop
      ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags 0 all-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: all-loop
at: line 7, column 15
message: `prim seq-bool.at` in `all-loop` takes the sequence (Seq Bool) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int Seq Bool
hint: These are the values `prim seq-bool.at` takes, in another order. To push them in its order, write `flags i` in place of `i flags` on line 7. With that edit, the next error in `all-loop` is at line 11, column 9.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs i current max-run } {
    i xs prim seq-int.len prim >=
    [ max-run current prim > [ current ] [ max-run ] if ]
    [
      i xs prim seq-int.at i 1 prim + xs prim seq-int.at prim =
      [ current 1 prim + ] [ 1 ] if
      i 1 prim + xs
      run-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 1 0 run-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 12, column 5
message: In the false branch of the `if` in `run-loop` whose true branch is `[ max-run current prim > [ current ] ...`, `run-loop` needs 4 values (xs:Seq Int, i:Int, current:Int, max-run:Int), but the branch has pushed only 3 values before it (the result of an `if`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current:Int, max-run:Int. The branch already pushes the result of an `if`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-sum-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim >=
    [ false ]
    [
      i 1 prim + xs target i
      pair-sum-inner
      [
        i 1 prim +
        xs
        target
        pair-sum-outer
      ]
      if
    ]
    if
  };

: pair-sum-inner
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many start-i:Int^many -- ρ found:Bool^many)
  locals { i j xs target start-i } {
    j xs prim seq-int.len prim >=
    [ false ]
    [
      i start-i prim =
      [
        i 1 prim + j xs target start-i pair-sum-inner
      ]
      [
        i xs prim seq-int.at j xs prim seq-int.at prim + target prim =
        [ true ]
        [ i 1 prim + j xs target start-i pair-sum-inner ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 pair-sum-outer
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: pair-sum-outer
at: line 8, column 7
message: `pair-sum-inner` in `pair-sum-outer` takes 5 values (i:Int, j:Int, xs:Seq Int, target:Int, start-i:Int), bottom to top, but only 4 values are on the stack before it, bottom to top: the result of `prim +` (Int), `xs` (Seq Int), `target` (Int) and `i` (Int). `pair-sum-outer` calls `pair-sum-inner`, which has an error of its own; this report assumes `pair-sum-inner` keeps its stack effect.
hint: Push the missing value before `pair-sum-inner`. The locals here, `xs`, `target` and `i`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: pair-sum-inner
at: line 31, column 14
message: `prim seq-int.at` in `pair-sum-inner` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 31. With that edit, the next error in `pair-sum-inner` is at line 31, column 35.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim >=
    [ count ]
    [
      i xs prim seq-int.at xs 0 i
      count-check-duplicate
      [
        count 1 prim +
        i 1 prim +
        xs
        count-outer
      ]
      [
        i 1 prim +
        xs
        count-outer
      ]
      if
    ]
    if
  };

: count-check-duplicate
  (forall ρ; ρ search-start:Int^many xs:Seq Int^many val:Int^many -- ρ found:Bool^many)
  locals { search-start xs val } {
    search-start 0 prim <
    [ false ]
    [
      search-start xs prim seq-int.at val prim =
      [ true ] [ search-start 1 prim - xs val count-check-duplicate ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 0 count-outer
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-outer
at: line 20, column 7
message: The two branches of the `if` in `count-outer` whose true branch is `[ count 1 prim + i 1 prim ...` leave different numbers of values. The true branch leaves the result of `count-outer`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `count-outer`. `count-outer` calls `count-check-duplicate`, which has an error of its own; this report assumes `count-check-duplicate` keeps its stack effect.
hint: The false branch takes the result of `prim seq-int.at` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: count-check-duplicate
at: line 31, column 23
message: `prim seq-int.at` in `count-check-duplicate` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `search-start` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs search-start` in place of `search-start xs` on line 31. With that edit `count-check-duplicate` checks.

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
    i xs prim seq-int.len prim >=
    [
      j ys prim seq-int.len prim >=
      [ result ]
      [
        result j ys prim seq-int.at prim seq-int.push
        j 1 prim +
        xs
        ys
        merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim >=
      [
        result i xs prim seq-int.at prim seq-int.push
        i 1 prim +
        xs
        ys
        merge-loop
      ]
      [
        i xs prim seq-int.at j ys prim seq-int.at prim <=
        [
          result i xs prim seq-int.at prim seq-int.push
          i 1 prim +
          xs
          ys
          merge-loop
        ]
        [
          result j ys prim seq-int.at prim seq-int.push
          i xs ys
          j 1 prim +
          merge-loop
        ]
        if
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
code: firth.type.branch-mismatch
word: merge-loop
at: line 15, column 7
message: In the false branch of the `if` in `merge-loop` whose true branch is `[ result ]`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `result`), the result of `prim +` (from `j`), `xs` and `ys`, which by their names are for inputs in another order. Push each in its input's place, and write the local `i` for the input it does not push: write `xs ys i j 1 prim + result j ys prim seq-int.at prim seq-int.push merge-loop` in place of `result j ys prim seq-int.at prim seq-int.push j 1 prim + xs ys merge-loop` on line 9. With that edit, the next error in `merge-loop` is at line 37, column 9. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      result i xs prim seq-int.at prim seq-int.push
      i 1 prim -
      xs
      reverse-digits
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty n digits-loop
      dup prim seq-int.len 1 prim -
      swap
      reverse-digits
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: digits-loop
at: line 9, column 7
message: `digits-loop` in `digits-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div` on line 7. With that edit `digits-loop` checks.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 20, column 19
message: `prim seq-int.at` in `reverse-digits` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 20. With that edit `reverse-digits` checks.

error 3 of 3
code: firth.type.branch-mismatch
word: main
at: line 39, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ { 0 } ]`, `reverse-digits` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim -` and the result of `digits-loop`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `digits-loop` and `reverse-digits`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim -` and the result of `digits-loop`, in the place of the last 2 (i:Int, result:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ num:Int^many candidate:Int^many -- ρ prime:Bool^many)
  locals { num candidate } {
    candidate candidate prim * num prim >
    [ true ]
    [
      num candidate prim mod 0 prim =
      [ false ]
      [ num candidate 1 prim + is-prime ]
      if
    ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim > [ result ]
    [
      i 2 prim <
      [
        i 1 prim +
        n
        result
        primes-loop
      ]
      [
        i 2 is-prime
        [
          result i prim seq-int.push
          i 1 prim +
          n
          primes-loop
        ]
        [
          i 1 prim +
          n
          result
          primes-loop
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty primes-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: primes-loop
at: line 33, column 11
message: `primes-loop` in `primes-loop` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `n` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t104
hint: These are the values `primes-loop` takes, in another order. To push them in its order, write `n i 1 prim + result i prim seq-int.push` in place of `result i prim seq-int.push i 1 prim + n` on line 30. With that edit `primes-loop` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { xs i counts } {
    i xs prim seq-int.len prim >=
    [ counts ]
    [
      i xs prim seq-int.at
      counts
      swap
      dup
      prim seq-int.at
      1 prim +
      prim seq-int.set
      i 1 prim +
      xs
      histogram-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ dup 0 prim seq-int.push swap 1 prim + swap dup k prim < ] call
    xs
    histogram-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 18, column 5
message: The two branches of `if` in `histogram-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 26, column 13
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and `0` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, `0` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ val:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { val sorted i } {
    i sorted prim seq-int.len prim >=
    [ sorted val prim seq-int.push ]
    [
      i sorted prim seq-int.at val prim <=
      [
        sorted i val prim seq-int.set
        i 1 prim +
        sorted
        insert-sorted
      ]
      [ sorted i val prim seq-int.push i 1 prim + sorted insert-sorted ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim >=
    [ sorted ]
    [
      i xs prim seq-int.at sorted 0 insert-sorted
      i 1 prim +
      xs
      sort-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-sorted
at: line 15, column 7
message: The two branches of the `if` in `insert-sorted` whose true branch is `[ sorted i val prim seq-int.set i 1 ...` leave different numbers of values. The true branch leaves the result of `insert-sorted`; the false branch leaves 2 values, bottom to top: `sorted` and the result of `insert-sorted`.
hint: The false branch leaves 1 value more than the true branch: `sorted` is left below the result of `insert-sorted`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: sort-loop
at: line 26, column 12
message: `prim seq-int.at` in `sort-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 26. With that edit `sort-loop` checks. That edit was checked assuming `insert-sorted`, which has an error of its own, keeps its stack effect.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance-final:Int^many rejected-final:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim >=
    [ balance rejected ]
    [
      balance i txs prim seq-int.at prim + 0 prim >=
      [
        balance i txs prim seq-int.at prim +
        i 1 prim +
        txs
        ledger-loop
      ]
      [
        balance
        rejected 1 prim +
        i 1 prim +
        txs
        ledger-loop
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs 0 start 0 ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 21, column 7
message: In the true branch `[ balance i txs prim seq-int.at prim + ...` of the `if` in `ledger-loop`, `ledger-loop` needs 4 values (txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim +` and `txs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes, bottom to top, the result of `prim +` (from `balance`), the result of `prim +` (from `i`) and `txs`, which by their names are for inputs in another order. Push each in its input's place, and write the local `rejected` for the input it does not push: write `txs i 1 prim + balance i txs prim seq-int.at prim + rejected ledger-loop` in place of `balance i txs prim seq-int.at prim + i 1 prim + txs ledger-loop` on line 9. With that edit, the next error in `ledger-loop` is at line 7, column 21. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated-list:Seq Int^many reason-list:Seq Int^many -- ρ stock-left:Seq Int^many allocated-final:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated-list reason-list } {
    i items prim seq-int.len prim >=
    [ stock allocated-list reason-list ]
    [
      i items prim seq-int.at
      stock
      swap
      prim seq-int.at
      i qtys prim seq-int.at
      i whole prim seq-bool.at
      (reason and allocated)
      (if item-stock >= order-qty then reason 0, alloc order-qty)
      (else if item-stock == 0 then reason 2, alloc 0)
      (else if whole then reason 3, alloc 0)
      (else reason 1, alloc item-stock)
      i 1 prim +
      stock
      items
      qtys
      whole
      allocate-loop
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 13, column 7
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.
