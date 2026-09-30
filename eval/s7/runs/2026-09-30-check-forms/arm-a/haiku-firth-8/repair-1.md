Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: seq-sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs } {
    i xs prim seq-int.len prim >=
    [ acc ]
    [ acc i xs prim seq-int.at prim + i 1 prim + xs seq-sum-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 swap seq-sum-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: seq-sum-loop
at: line 6, column 16
message: `prim seq-int.at` in `seq-sum-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 6. With that edit `seq-sum-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 12
message: `seq-sum-loop` in `main` takes acc:Int, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `seq-sum-loop`, which has an error of its own; this report assumes `seq-sum-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Seq Int Int Int
hint: The top value, `0` (Int), is not what `seq-sum-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim >=
    [ max ]
    [ 
      max i xs prim seq-int.at
      [ drop i xs prim seq-int.at ]
      [ ]
      prim >
      if
      i 1 prim + xs seq-max-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 xs prim seq-int.at 1 swap seq-max-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.elaboration.untracked-local
word: seq-max-loop
at: line 12, column 7
message: The local `i` is used after `if` on line 11 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 19, column 5
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
: count-below-loop
  (forall ρ; ρ count:Int^many i:Int^many k:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i k xs } {
    i xs prim seq-int.len prim >=
    [ count ]
    [
      i xs prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim + k xs count-below-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  swap 0 0 swap swap count-below-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: count-below-loop
at: line 7, column 12
message: `prim seq-int.at` in `count-below-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit `count-below-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 22
message: `count-below-loop` in `main` takes count:Int, i:Int, k:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `k` (Int), the input `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `count-below-loop`, which has an error of its own; this report assumes `count-below-loop` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `count-below-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-of-loop
  (forall ρ; ρ i:Int^many x:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i x xs } {
    i xs prim seq-int.len prim >=
    [ -1 ]
    [
      i xs prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + x xs index-of-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  swap 0 swap index-of-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: index-of-loop
at: line 7, column 12
message: `prim seq-int.at` in `index-of-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit `index-of-loop` checks.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [ result ]
    [ result i xs prim seq-int.at prim seq-int.push i 1 prim - xs reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 6, column 19
message: `prim seq-int.at` in `reverse-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 6. With that edit, the next error in `reverse-loop` is at line 6, column 67.

error 2 of 2
code: firth.name.unresolved
word: main
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
: prefix-sums-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      acc i xs prim seq-int.at prim +
      result acc i xs prim seq-int.at prim + prim seq-int.push
      i 1 prim + swap swap prefix-sums-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty 0 swap prefix-sums-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-sums-loop
at: line 11, column 5
message: In the false branch of the `if` in `prefix-sums-loop` whose true branch is `[ result ]`, `prefix-sums-loop` needs 4 values (i:Int, acc:Int, xs:Seq Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-sums-loop`, exactly the values it takes, in this order: i:Int, acc:Int, xs:Seq Int, result:Seq Int. The branch already pushes the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-sums-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 31
message: `prefix-sums-loop` in `main` takes i:Int, acc:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `prefix-sums-loop`, which has an error of its own; this report assumes `prefix-sums-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int
actual: ρ Seq Int Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `prefix-sums-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      i xs prim seq-int.at 0 prim >
      [ result i xs prim seq-int.at prim seq-int.push ]
      [ result ]
      if
      i 1 prim + xs keep-positive-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  prim seq-int.empty 0 swap keep-positive-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: keep-positive-loop
at: line 7, column 12
message: `prim seq-int.at` in `keep-positive-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `keep-positive-loop` is at line 8, column 21.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 29
message: `keep-positive-loop` in `main` takes i:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `keep-positive-loop`, which has an error of its own; this report assumes `keep-positive-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `keep-positive-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [
      i xs prim seq-int.at i 1 prim + xs prim seq-int.at prim <=
      [ i 1 prim + xs is-sorted-loop ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  0 swap is-sorted-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: is-sorted-loop
at: line 7, column 12
message: `prim seq-int.at` in `is-sorted-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `is-sorted-loop` is at line 7, column 42.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs ys } {
    i xs prim seq-int.len prim >=
    [ acc ]
    [
      acc i xs prim seq-int.at i ys prim seq-int.at prim * prim +
      i 1 prim + xs ys dot-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  swap 0 0 swap dot-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: dot-loop
at: line 7, column 16
message: `prim seq-int.at` in `dot-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 7. With that edit, the next error in `dot-loop` is at line 7, column 37.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 15, column 17
message: `dot-loop` in `main` takes acc:Int, i:Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the input `ys` (Seq Int), the input `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `dot-loop`, which has an error of its own; this report assumes `dot-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `dot-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true-loop
  (forall ρ; ρ i:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { i flags } {
    i flags prim seq-bool.len prim >=
    [ true ]
    [
      i flags prim seq-bool.at
      [ i 1 prim + flags all-true-loop ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  0 swap all-true-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: all-true-loop
at: line 7, column 15
message: `prim seq-bool.at` in `all-true-loop` takes the sequence (Seq Bool) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int Seq Bool
hint: These are the values `prim seq-bool.at` takes, in another order. To push them in its order, write `flags i` in place of `i flags` on line 7. With that edit `all-true-loop` checks.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run-loop
  (forall ρ; ρ i:Int^many current:Int^many max-len:Int^many max-val:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i current max-len max-val xs } {
    i xs prim seq-int.len prim >=
    [ max-len ]
    [
      i xs prim seq-int.at max-val prim =
      [ current 1 prim + ]
      [ 1 ]
      if
      current 1 prim + max-len prim > [ current 1 prim + ] [ max-len ] if
      i 1 prim + 
      current 1 prim + max-val prim = [ current 1 prim + ] [ 1 ] if
      i xs prim seq-int.at xs longest-run-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ 1 1 0 0 xs prim seq-int.at swap longest-run-loop ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: longest-run-loop
at: line 16, column 5
message: The two branches of the `if` in `longest-run-loop` whose true branch is `[ max-len ]` leave different numbers of values. The true branch leaves `max-len`; the false branch leaves 2 values, bottom to top: the result of an `if` and the result of `longest-run-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of an `if` is left below the result of `longest-run-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum-inner
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i j xs target } {
    j xs prim seq-int.len prim >=
    [ false ]
    [
      i j prim =
      [ i 1 prim + j xs target has-pair-sum-inner ]
      [
        i xs prim seq-int.at j xs prim seq-int.at prim + target prim =
        [ true ]
        [ i j 1 prim + xs target has-pair-sum-inner ]
        if
      ]
      if
    ]
    if
  };

: has-pair-sum-outer
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim >=
    [ false ]
    [
      i 0 xs target has-pair-sum-inner
      [ true ]
      [ i 1 prim + xs target has-pair-sum-outer ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  swap 0 swap target has-pair-sum-outer;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: has-pair-sum-inner
at: line 10, column 14
message: `prim seq-int.at` in `has-pair-sum-inner` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 10. With that edit, the next error in `has-pair-sum-inner` is at line 10, column 35.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 36, column 15
message: `target` is not a defined word, primitive or local.
actual: target
hint: `target` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-search
  (forall ρ; ρ i:Int^many val:Int^many seen:Seq Int^many -- ρ in-seen:Bool^many)
  locals { i val seen } {
    i seen prim seq-int.len prim >=
    [ false ]
    [
      i seen prim seq-int.at val prim =
      [ true ]
      [ i 1 prim + val seen count-distinct-search ]
      if
    ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many distinct:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs distinct } {
    i xs prim seq-int.len prim >=
    [ distinct ]
    [
      0 i xs prim seq-int.at distinct count-distinct-search
      [ distinct i 1 prim + xs count-distinct-loop ]
      [ distinct i xs prim seq-int.at prim seq-int.push i 1 prim + xs count-distinct-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  prim seq-int.empty 0 swap count-distinct-loop prim seq-int.len;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: count-distinct-search
at: line 7, column 14
message: `prim seq-int.at` in `count-distinct-search` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `seen` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `seen i` in place of `i seen` on line 7. With that edit `count-distinct-search` checks.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: count-distinct-loop
at: line 21, column 14
message: `prim seq-int.at` in `count-distinct-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 21. With that edit, the next error in `count-distinct-loop` is at line 22, column 32. That edit was checked assuming `count-distinct-search`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 31, column 29
message: `count-distinct-loop` in `main` takes i:Int, xs:Seq Int, distinct:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `count-distinct-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-sorted-loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i j xs ys result } {
    i xs prim seq-int.len prim >=
    [
      j ys prim seq-int.len prim >=
      [ result ]
      [ result j ys prim seq-int.at prim seq-int.push i j 1 prim + xs ys merge-sorted-loop ]
      if
    ]
    [
      j ys prim seq-int.len prim >=
      [ result i xs prim seq-int.at prim seq-int.push i 1 prim + j xs ys result merge-sorted-loop ]
      [
        i xs prim seq-int.at j ys prim seq-int.at prim <=
        [ result i xs prim seq-int.at prim seq-int.push i 1 prim + j xs ys result merge-sorted-loop ]
        [ result j ys prim seq-int.at prim seq-int.push i j 1 prim + xs ys result merge-sorted-loop ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  prim seq-int.empty swap swap 0 0 swap merge-sorted-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-sorted-loop
at: line 22, column 5
message: The two branches of the `if` in `merge-sorted-loop` whose true branch is `[ j ys prim seq-int.len prim >= [ ...` leave different numbers of values. The true branch leaves the result of an `if`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-sorted-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `merge-sorted-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 27, column 41
message: `merge-sorted-loop` in `main` takes i:Int, j:Int, xs:Seq Int, ys:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-sorted-loop`, which has an error of its own; this report assumes `merge-sorted-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `merge-sorted-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod result swap prim seq-int.push
      n 10 prim div digits-loop
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many result:Seq Int^many rev:Seq Int^many -- ρ result:Seq Int^many)
  locals { i result rev } {
    i result prim seq-int.len prim >=
    [ rev ]
    [ rev i result prim seq-int.at prim seq-int.push i 1 prim + result reverse-digits ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  n 0 prim =
  [ { 0 } ]
  [ prim seq-int.empty n digits-loop 0 swap prim seq-int.empty reverse-digits ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: digits-loop
at: line 8, column 21
message: `digits-loop` in `digits-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: The top value, the result of `prim div` (Int), is not what `digits-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 18, column 20
message: `prim seq-int.at` in `reverse-digits` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `result i` in place of `i result` on line 18. With that edit, the next error in `reverse-digits` is at line 18, column 72.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 24, column 3
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
: is-prime-loop
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim > 
    [ true ]
    [ n d prim mod 0 prim = [ false ] [ d 1 prim + n is-prime-loop ] if ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  n 2 prim <
  [ false ]
  [ 2 n is-prime-loop ]
  if;

: primes-loop
  (forall ρ; ρ i:Int^many limit:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i limit result } {
    i limit prim > 
    [ result ]
    [
      i is-prime
      [ result i prim seq-int.push i 1 prim + limit primes-loop ]
      [ i 1 prim + limit result primes-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  prim seq-int.empty 2 n primes-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: is-prime
at: line 12, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.type.word-input-mismatch
word: primes-loop
at: line 24, column 53
message: `primes-loop` in `primes-loop` takes i:Int, limit:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `limit` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t52
hint: These are the values `primes-loop` takes, in another order. To push them in its order, write `i 1 prim + limit result i prim seq-int.push` in place of `result i prim seq-int.push i 1 prim + limit` on line 24. With that edit `primes-loop` checks. That edit was checked assuming `is-prime`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 33, column 24
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-init-loop
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result } {
    i k prim >=
    [ result ]
    [ result 0 prim seq-int.push i 1 prim + k histogram-init-loop ]
    if
  };

: histogram-count-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim >=
    [ counts ]
    [
      i xs prim seq-int.at counts swap prim seq-int.at 1 prim + prim seq-int.set
      i 1 prim + xs histogram-count-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  swap prim seq-int.empty 0 swap histogram-init-loop 0 swap histogram-count-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: histogram-init-loop
at: line 6, column 47
message: `histogram-init-loop` in `histogram-init-loop` takes i:Int, k:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `k` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t30
hint: These are the values `histogram-init-loop` takes, in another order. To push them in its order, write `i 1 prim + k result 0 prim seq-int.push` in place of `result 0 prim seq-int.push i 1 prim + k` on line 6. With that edit `histogram-init-loop` checks.

error 2 of 3
code: firth.type.branch-mismatch
word: histogram-count-loop
at: line 19, column 5
message: In the false branch of the `if` in `histogram-count-loop` whose true branch is `[ counts ]`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 24, column 34
message: `histogram-init-loop` in `main` takes i:Int, k:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `histogram-init-loop`, which has an error of its own; this report assumes `histogram-init-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int Int Seq Int
hint: The third value from the top, the input `xs` (Seq Int), is not what `histogram-init-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort-inner
  (forall ρ; ρ j:Int^many val:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { j val result } {
    j 0 prim <=
    [ result val prim seq-int.push ]
    [
      j 1 prim - result prim seq-int.at val prim >
      [ result j 1 prim - val prim seq-int.at prim seq-int.set j 1 prim - val insertion-sort-inner ]
      [ result val prim seq-int.push ]
      if
    ]
    if
  };

: insertion-sort-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      result prim seq-int.len i xs prim seq-int.at insertion-sort-inner
      i 1 prim + xs sort-loop
    ]
    if
  };

: sort-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs } {
    i xs prim seq-int.len prim >=
    [ prim seq-int.empty ]
    [ 
      prim seq-int.empty i xs prim seq-int.at prim seq-int.push
      i 1 prim + xs
      [ prim seq-int.empty i xs prim seq-int.at prim seq-int.push ]
      [ i 1 prim + xs insertion-sort-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  prim seq-int.empty 0 swap insertion-sort-loop;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.branch-mismatch
word: insertion-sort-inner
at: line 10, column 7
message: The two branches of `if` in `insertion-sort-inner` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 4
code: firth.type.primitive-input-mismatch
word: insertion-sort-loop
at: line 21, column 36
message: `prim seq-int.at` in `insertion-sort-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 21. With that edit, the next error in `insertion-sort-loop` is at line 21, column 52. That edit was checked assuming `insertion-sort-inner` and `sort-loop`, which have errors of their own, keep their stack effects.

error 3 of 4
code: firth.type.branch-mismatch
word: sort-loop
at: line 37, column 7
message: The two branches of the `if` in `sort-loop` whose true branch is `[ prim seq-int.empty i xs prim seq-int.at prim seq-int.push ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.push`; the false branch takes the result of `prim +` from below the `if` and leaves the result of `insertion-sort-loop`. `sort-loop` calls `insertion-sort-loop`, which has an error of its own; this report assumes `insertion-sort-loop` keeps its stack effect.
hint: The false branch takes the result of `prim +` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

error 4 of 4
code: firth.type.word-input-mismatch
word: main
at: line 44, column 29
message: `insertion-sort-loop` in `main` takes i:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `insertion-sort-loop`, which has an error of its own; this report assumes `insertion-sort-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `insertion-sort-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim >=
    [ balance rejected ]
    [
      balance i txs prim seq-int.at prim + 0 prim <
      [ balance rejected 1 prim + i 1 prim + txs ledger-loop ]
      [ balance i txs prim seq-int.at prim + rejected i 1 prim + txs ledger-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap 0 0 swap ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: ledger-loop
at: line 7, column 21
message: `prim seq-int.at` in `ledger-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `txs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `txs i` in place of `i txs` on line 7. With that edit, the next error in `ledger-loop` is at line 9, column 23.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 17
message: `ledger-loop` in `main` takes balance:Int, rejected:Int, i:Int, txs:Seq Int, bottom to top, but here it gets, bottom to top, the input `txs` (Seq Int), the input `start` (Int), `0` (Int) and `0` (Int). `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Seq Int Int Int Int
hint: The top value, `0` (Int), is not what `ledger-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ item:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many -- ρ stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { item qty whole stock } {
    stock item prim seq-int.at qty prim <=
    [ stock item qty prim seq-int.set qty 0 ]
    [
      stock item prim seq-int.at 0 prim =
      [ stock 0 2 ]
      [
        whole
        [ stock 0 3 ]
        [ stock item stock item prim seq-int.at prim seq-int.set stock item prim seq-int.at 1 ]
        if
      ]
      if
    ]
    if
  };

: allocate-loop
  (forall ρ; ρ j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { j items qtys whole stock allocated reasons } {
    j items prim seq-int.len prim >=
    [ stock allocated reasons ]
    [
      j items prim seq-int.at j qtys prim seq-int.at j whole prim seq-bool.at stock allocate-order
      j allocated prim seq-int.push swap j reasons prim seq-int.push swap
      j 1 prim + items qtys whole swap allocate-loop
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 swap swap allocate-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 30, column 5
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ stock allocated reasons ]` leave different numbers of values. The true branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`; the false branch leaves 5 values, bottom to top: the output `stock` of `allocate-order`, the output `allocated` of `allocate-order`, the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`.
hint: The false branch leaves 2 values more than the true branch: the output `stock` of `allocate-order` and the output `allocated` of `allocate-order` are left below the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 35, column 53
message: `allocate-loop` in `main` takes j:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, stock:Seq Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `allocate-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
