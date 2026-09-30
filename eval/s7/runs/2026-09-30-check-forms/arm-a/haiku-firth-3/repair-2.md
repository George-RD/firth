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
      acc xs i prim seq-int.at prim +
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
code: firth.type.word-input-mismatch
word: sum-loop
at: line 10, column 7
message: `sum-loop` in `sum-loop` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `acc xs i prim seq-int.at prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at
      max-val prim >
      [ xs i prim seq-int.at ] [ max-val ] if
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
code: firth.type.word-input-mismatch
word: max-loop
at: line 12, column 7
message: `max-loop` in `max-loop` takes xs:Seq Int, i:Int, max-val:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at max-val prim > [ xs i prim seq-int.at ] [ max-val ] if` and `i 1 prim +` are for `i` and `max-val`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at k prim <
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
code: firth.type.word-input-mismatch
word: count-loop
at: line 12, column 7
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `k` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: These are the values `count-loop` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` and `i 1 prim +` are for `i` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at x prim =
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
code: firth.type.word-input-mismatch
word: index-loop
at: line 8, column 31
message: `index-loop` in `index-loop` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `x` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t60 ?t59
hint: These are the values `index-loop` takes, in another order. To push them in its order, write `xs x i 1 prim +` in place of `i 1 prim + xs x` on line 8. With that edit `index-loop` checks.

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
      result xs i prim seq-int.at prim seq-int.push
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
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': []}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 2}}, {'kind': 'literal', 'literal': {'type': 'seq-int'

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
      sum xs i prim seq-int.at prim +
      locals { new-sum } {
        result new-sum prim seq-int.push
        i 1 prim +
        xs
        new-sum
        prefix-loop
      }
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
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 13, column 9
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int), `xs` (Seq Int) and `new-sum` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Int Seq Int Seq Int Int Seq Int Int
hint: These are the values `prefix-loop` takes, in another order. By their names and types, `xs` is for `xs` and `result new-sum prim seq-int.push` is for `result`. Of the values of one type, `i 1 prim +` and `new-sum` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at 0 prim >
      [ result xs i prim seq-int.at prim seq-int.push ] [ result ] if
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
On the example, it returned [[3, -1, 0, 4]] instead of [[3, 4]]

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
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
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
code: firth.type.word-input-mismatch
word: sorted-loop
at: line 13, column 9
message: `sorted-loop` in `sorted-loop` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t35
hint: These are the values `sorted-loop` takes, in another order. To push them in its order, write `xs i 1 prim +` in place of `i 1 prim + xs` on line 11. With that edit `sorted-loop` checks.

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
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
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
code: firth.type.word-input-mismatch
word: dot-loop
at: line 11, column 7
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      flags i prim seq-bool.at
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
code: firth.type.word-input-mismatch
word: all-loop
at: line 11, column 9
message: `all-loop` in `all-loop` takes flags:Seq Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int ?t29
hint: These are the values `all-loop` takes, in another order. To push them in its order, write `flags i 1 prim +` in place of `i 1 prim + flags` on line 9. With that edit `all-loop` checks.

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
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
      [ current 1 prim + ] [ 1 ] if
      i 1 prim +
      xs
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
at: line 13, column 5
message: In the false branch of the `if` in `run-loop` whose true branch is `[ max-run current prim > [ current ] ...`, `run-loop` needs 4 values (xs:Seq Int, i:Int, current:Int, max-run:Int), but the branch has pushed only 3 values before it (the result of an `if`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current:Int, max-run:Int. The branch already pushes the result of an `if`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-sum-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many start-i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target start-i j } {
    j xs prim seq-int.len prim >=
    [ false ]
    [
      start-i j prim =
      [
        j 1 prim +
        xs
        target
        start-i
        pair-sum-inner
      ]
      [
        xs start-i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ j 1 prim + xs target start-i pair-sum-inner ]
        if
      ]
      if
    ]
    if
  };

: pair-sum-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim >=
    [ false ]
    [
      xs target i 1 prim + pair-sum-inner
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

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 pair-sum-outer
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: pair-sum-inner
at: line 13, column 9
message: `pair-sum-inner` in `pair-sum-inner` takes xs:Seq Int, target:Int, start-i:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `target` (Int) and `start-i` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int ?t70 ?t69 ?t68
hint: These are the values `pair-sum-inner` takes, in another order. To push them in its order, write `xs target start-i j 1 prim +` in place of `j 1 prim + xs target start-i` on line 9. With that edit, the next error in `pair-sum-inner` is at line 15, column 40.

error 2 of 2
code: firth.type.stack-underflow
word: pair-sum-outer
at: line 32, column 28
message: `pair-sum-inner` in `pair-sum-outer` takes 4 values (xs:Seq Int, target:Int, start-i:Int, j:Int), bottom to top, but only 3 values are on the stack before it, bottom to top: `xs` (Seq Int), `target` (Int) and the result of `prim +` (Int). `pair-sum-outer` calls `pair-sum-inner`, which has an error of its own; this report assumes `pair-sum-inner` keeps its stack effect.
hint: Push the missing value before `pair-sum-inner`. The locals here, `xs`, `target` and `i`, are not values on the stack: writing a local's name pushes its value.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-check-duplicate
  (forall ρ; ρ xs:Seq Int^many val:Int^many search-start:Int^many -- ρ found:Bool^many)
  locals { xs val search-start } {
    search-start 0 prim <
    [ false ]
    [
      xs search-start prim seq-int.at val prim =
      [ true ] [ xs val search-start 1 prim - count-check-duplicate ] if
    ]
    if
  };

: count-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim >=
    [ count ]
    [
      xs xs i prim seq-int.at i 1 prim - count-check-duplicate
      [ count 1 prim + i 1 prim + xs count-outer ]
      [ i 1 prim + xs count-outer ]
      if
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
code: firth.type.branch-mismatch
word: count-outer
at: line 22, column 7
message: In the false branch of the `if` in `count-outer` whose true branch is `[ count 1 prim + i 1 prim ...`, `count-outer` needs 3 values (xs:Seq Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-outer`, exactly the values it takes, in this order: xs:Seq Int, i:Int, count:Int. The branch already pushes, bottom to top, the result of `prim +` (from `i`) and `xs`, which by their names are for inputs in another order. Push each in its input's place, and write the local `count` for the input it does not push: write `xs i 1 prim + count count-outer` in place of `i 1 prim + xs count-outer` on line 21. With that edit, the next error in `count-outer` is at line 20, column 38. If `count-outer` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
      [ result ys j prim seq-int.at prim seq-int.push j 1 prim + xs ys merge-loop ]
      if
    ]
    [
      j ys prim seq-int.len prim >=
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys merge-loop ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <=
        [ result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop ]
        [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop ]
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
at: line 9, column 7
message: In the false branch of the `if` in `merge-loop` whose true branch is `[ result ]`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `result`), the result of `prim +` (from `j`), `xs` and `ys`, which by their names are for inputs in another order. Push each in its input's place, and write the local `i` for the input it does not push: write `xs ys i j 1 prim + result ys j prim seq-int.at prim seq-int.push merge-loop` in place of `result ys j prim seq-int.at prim seq-int.push j 1 prim + xs ys merge-loop` on line 8. With that edit, the next error in `merge-loop` is at line 20, column 7. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
      n 10 prim div
      result n 10 prim mod prim seq-int.push
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
      result xs i prim seq-int.at prim seq-int.push
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
code: firth.type.branch-mismatch
word: main
at: line 39, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ { 0 } ]`, `reverse-digits` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim -` and the result of `digits-loop`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim -` and the result of `digits-loop`, in the place of the last 2 (i:Int, result:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: make-empty-histogram
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { k i result } {
    i k prim >=
    [ result ]
    [ result 0 prim seq-int.push k i 1 prim + make-empty-histogram ]
    if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { xs i counts } {
    i xs prim seq-int.len prim >=
    [ counts ]
    [
      xs i prim seq-int.at
      locals { idx } {
        counts idx prim seq-int.at 1 prim + idx counts prim seq-int.set
        i 1 prim +
        xs
        histogram-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k 0 make-empty-histogram
    xs
    histogram-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: make-empty-histogram
at: line 6, column 47
message: `make-empty-histogram` in `make-empty-histogram` takes k:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t31 Int
hint: These are the values `make-empty-histogram` takes, in another order. To push them in its order, write `k i 1 prim + result 0 prim seq-int.push` in place of `result 0 prim seq-int.push k i 1 prim +` on line 6. With that edit `make-empty-histogram` checks.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 18, column 56
message: `prim seq-int.set` in `histogram-loop` takes the sequence (Seq Int), the index (Int) and the new value (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `idx` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Seq Int Int Int Seq Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `counts` is for the sequence. Of the values of one type, `counts idx prim seq-int.at 1 prim +` and `idx` are for the index and the new value, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 30, column 28
message: `make-empty-histogram` in `main` takes k:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `k` (Int) and `0` (Int). `main` calls `make-empty-histogram`, which has an error of its own; this report assumes `make-empty-histogram` keeps its stack effect.
expected: .. Int Int Seq Int
actual: .. Seq Int Int Int
hint: These are the values `make-empty-histogram` takes, in another order. To push them in its order, write `k 0 prim seq-int.empty` in place of `prim seq-int.empty k 0` on line 30. With that edit, the next error in `main` is at line 32, column 5. That edit was checked assuming `histogram-loop`, which has an error of its own, keeps its stack effect.

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
      sorted i prim seq-int.at val prim <=
      [
        sorted i val prim seq-int.set
        val sorted i 1 prim + insert-sorted
      ]
      [ sorted val i 1 prim + insert-sorted ]
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
      xs i prim seq-int.at sorted 0 insert-sorted
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
code: firth.type.branch-mismatch
word: insert-sorted
at: line 13, column 7
message: The two branches of the `if` in `insert-sorted` whose true branch is `[ sorted i val prim seq-int.set val sorted ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-sorted`; the false branch leaves the result of `insert-sorted`.
hint: The result of `prim seq-int.set` is a new value of `sorted`, but `insert-sorted` is then handed `sorted` as it was before, so the new value is left below. If `insert-sorted` should get the new value, bind it to the name `sorted` for the call: write `prim seq-int.set locals { sorted } { val sorted i 1 prim + insert-sorted }` in place of `prim seq-int.set val sorted i 1 prim + insert-sorted` on line 9. With that edit, the next error in `insert-sorted` is at line 11, column 31. Both branches run on the same stack and must leave the same values.

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
      items i prim seq-int.at
      locals { item-idx } {
        stock item-idx prim seq-int.at
        locals { item-stock } {
          qtys i prim seq-int.at
          locals { order-qty } {
            order-qty item-stock prim <=
            [
              stock item-idx order-qty prim seq-int.set
              i 1 prim +
              stock
              items
              qtys
              whole
              allocated-list order-qty prim seq-int.push
              reason-list 0 prim seq-int.push
              allocate-loop
            ]
            [
              item-stock 0 prim =
              [
                i 1 prim +
                stock
                items
                qtys
                whole
                allocated-list 0 prim seq-int.push
                reason-list 2 prim seq-int.push
                allocate-loop
              ]
              [
                whole i prim seq-bool.at
                [
                  i 1 prim +
                  stock
                  items
                  qtys
                  whole
                  allocated-list 0 prim seq-int.push
                  reason-list 3 prim seq-int.push
                  allocate-loop
                ]
                [
                  stock item-idx item-stock prim seq-int.set
                  i 1 prim +
                  stock
                  items
                  qtys
                  whole
                  allocated-list item-stock prim seq-int.push
                  reason-list 1 prim seq-int.push
                  allocate-loop
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
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
code: firth.type.branch-mismatch
word: allocate-loop
at: line 60, column 17
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ i 1 prim + stock items qtys ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the output `stock-left` of `allocate-loop`, the output `allocated-final` of `allocate-loop` and the output `reasons` of `allocate-loop`; the false branch leaves 4 values, bottom to top: the result of `prim seq-int.set`, the output `stock-left` of `allocate-loop`, the output `allocated-final` of `allocate-loop` and the output `reasons` of `allocate-loop`.
hint: The result of `prim seq-int.set` is a new value of `stock`, but `allocate-loop` is then handed `stock` as it was before, so the new value is left below. If `allocate-loop` should get the new value, bind it to the name `stock` for the call: write `prim seq-int.set locals { stock } { i 1 prim + stock items qtys whole allocated-list item-stock prim seq-int.push reason-list 1 prim seq-int.push allocate-loop }` in place of `prim seq-int.set i 1 prim + stock items qtys whole allocated-list item-stock prim seq-int.push reason-list 1 prim seq-int.push allocate-loop` on line 50. With that edit, the next error in `allocate-loop` is at line 56, column 13. Both branches run on the same stack and must leave the same values.
