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
  locals { xs } { 0 [ xs ] sum-helper };

: sum-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    xs i prim seq-int.len prim >= [ acc ] [
      xs i prim seq-int.at prim + [ xs i 1 prim + ] dip sum-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 28
message: `sum-helper` in `main` needs Int Seq Int Int on top of the stack, but the stack before it is ρ Int [ .. -- .. Seq Int ]. `main` calls `sum-helper`, which has an error of its own; this report assumes `sum-helper` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Int [ .. -- .. Seq Int ]
hint: `sum-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: sum-helper
at: line 10, column 7
message: The two branches of `if` in `sum-helper` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at [ xs 1 ] max-helper };

: max-helper
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    xs i prim seq-int.len prim >= [ max ] [
      xs i prim seq-int.at [ max ] [ ] if
      [ xs i 1 prim + ] dip max-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 49
message: `max-helper` in `main` needs Int Seq Int Int on top of the stack, but the stack before it is ρ Int [ .. -- .. Seq Int Int ]. `main` calls `max-helper`, which has an error of its own; this report assumes `max-helper` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Int [ .. -- .. Seq Int Int ]
hint: `max-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: max-helper
at: line 9, column 40
message: The two branches of the `if` in `max-helper` whose true branch is `[ max ]` leave different numbers of values. The true branch leaves `max`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `max` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 [ xs k ] count-below-helper };

: count-below-helper
  (forall ρ; ρ count:Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs k i } {
    xs i prim seq-int.len prim >= [ count ] [
      xs i prim seq-int.at k prim < [
        count 1 prim + [ xs k i 1 prim + ] dip count-below-helper
      ] [
        count [ xs k i 1 prim + ] dip count-below-helper
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 32
message: `count-below-helper` in `main` takes 4 values (count:Int, xs:Seq Int, k:Int, i:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the quotation `[ xs k ]`. `main` calls `count-below-helper`, which has an error of its own; this report assumes `count-below-helper` keeps its stack effect.
hint: Push the 2 missing values before `count-below-helper`. The locals here, `xs` and `k`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: count-below-helper
at: line 8, column 10
message: `prim seq-int.len` in `count-below-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Int Seq Int Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { [ xs x 0 ] index-of-helper };

: index-of-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    xs i prim seq-int.len prim >= [
      -1
    ] [
      xs i prim seq-int.at x prim = [
        i
      ] [
        [ xs x i 1 prim + ] dip index-of-helper
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 32
message: `index-of-helper` in `main` takes 3 values (xs:Seq Int, x:Int, i:Int), bottom to top, but only 1 value is on the stack before it: the quotation `[ xs x 0 ]`. `main` calls `index-of-helper`, which has an error of its own; this report assumes `index-of-helper` keeps its stack effect.
hint: Push the 2 missing values before `index-of-helper`. The locals here, `xs` and `x`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: index-of-helper
at: line 8, column 10
message: `prim seq-int.len` in `index-of-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Seq Int Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty [ xs ] reverse-helper };

: reverse-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    xs i prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at result prim seq-int.push [ xs i 1 prim + ] dip reverse-helper
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
at: line 3, column 45
message: `reverse-helper` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int [ .. -- .. Seq Int ]. `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int [ .. -- .. Seq Int ]
hint: `reverse-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 8, column 10
message: `prim seq-int.len` in `reverse-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Seq Int Seq Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 [ xs ] prefix-sums-helper };

: prefix-sums-helper
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    xs i prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at sum prim + [ result ] prefix-sums-push [ xs i 1 prim + ] dip prefix-sums-helper
    ] if
  };

: prefix-sums-push
  (forall ρ; ρ result:Seq Int^many sum:Int^many -- ρ result2:Seq Int^many sum:Int^many)
  locals { result sum } {
    result sum prim seq-int.push sum
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 47
message: `prefix-sums-helper` in `main` needs Seq Int Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Int [ .. -- .. Seq Int ]. `main` calls `prefix-sums-helper`, which has an error of its own; this report assumes `prefix-sums-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int Int
actual: ρ Seq Int Int [ .. -- .. Seq Int ]
hint: `prefix-sums-helper` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: prefix-sums-helper
at: line 8, column 10
message: `prim seq-int.len` in `prefix-sums-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Seq Int Int Seq Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty [ xs ] keep-positive-helper };

: keep-positive-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    xs i prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at [ 0 prim > ] [ 0 prim > ] if [
        result xs i prim seq-int.at prim seq-int.push [ xs i 1 prim + ] dip keep-positive-helper
      ] [
        [ xs i 1 prim + ] dip keep-positive-helper
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 45
message: `keep-positive-helper` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int [ .. -- .. Seq Int ]. `main` calls `keep-positive-helper`, which has an error of its own; this report assumes `keep-positive-helper` keeps its stack effect.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int [ .. -- .. Seq Int ]
hint: `keep-positive-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: keep-positive-helper
at: line 15, column 9
message: The two branches of `if` in `keep-positive-helper` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { [ xs ] is-sorted-helper };

: is-sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    xs i prim seq-int.len 1 prim - prim <= [
      true
    ] [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [
        [ xs i 1 prim + ] dip is-sorted-helper
      ] [
        false
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 26
message: `is-sorted-helper` in `main` needs Seq Int Int on top of the stack, but the stack before it is ρ [ .. -- .. Seq Int ]. `main` calls `is-sorted-helper`, which has an error of its own; this report assumes `is-sorted-helper` keeps its stack effect.
expected: .. Seq Int Int
actual: ρ [ .. -- .. Seq Int ]
hint: `is-sorted-helper` takes 2 values but only 1 value is available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: is-sorted-helper
at: line 8, column 10
message: `prim seq-int.len` in `is-sorted-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Seq Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 [ xs ys ] dot-helper };

: dot-helper
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { sum xs ys i } {
    xs i prim seq-int.len prim >= [
      sum
    ] [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + [ xs ys i 1 prim + ] dip dot-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 34
message: `dot-helper` in `main` takes 4 values (sum:Int, xs:Seq Int, ys:Seq Int, i:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the quotation `[ xs ys ]`. `main` calls `dot-helper`, which has an error of its own; this report assumes `dot-helper` keeps its stack effect.
hint: Push the 2 missing values before `dot-helper`. The locals here, `xs` and `ys`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: dot-helper
at: line 8, column 10
message: `prim seq-int.len` in `dot-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Int Seq Int Seq Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { [ flags ] all-true-helper };

: all-true-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    flags i prim seq-bool.len prim >= [
      true
    ] [
      flags i prim seq-bool.at [
        [ flags i 1 prim + ] dip all-true-helper
      ] [
        false
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 32
message: `all-true-helper` in `main` needs Seq Bool Int on top of the stack, but the stack before it is ρ [ .. -- .. Seq Bool ]. `main` calls `all-true-helper`, which has an error of its own; this report assumes `all-true-helper` keeps its stack effect.
expected: .. Seq Bool Int
actual: ρ [ .. -- .. Seq Bool ]
hint: `all-true-helper` takes 2 values but only 1 value is available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: all-true-helper
at: line 8, column 13
message: `prim seq-bool.len` in `all-true-helper` takes Seq Bool, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Bool
actual: ρ Seq Bool Int Seq Bool Int
hint: The top value, `i` (Int), is not what `prim seq-bool.len` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs 0 prim seq-int.len 0 prim <= [
      0
    ] [
      xs 0 prim seq-int.at 1 1 [ xs ] longest-run-helper
    ] if
  };

: longest-run-helper
  (forall ρ; ρ max-len:Int^many curr-len:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max-len curr-len xs i } {
    xs i prim seq-int.len prim >= [
      curr-len max-len prim > [ curr-len ] [ max-len ] if
    ] [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [
        curr-len 1 prim + [ max-len xs i 1 prim + ] dip longest-run-helper
      ] [
        curr-len max-len prim > [ [ 1 1 xs i 1 prim + ] dip longest-run-helper ] [ [ max-len 1 xs i 1 prim + ] dip longest-run-helper ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 4, column 10
message: `prim seq-int.len` in `main` takes Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int).
expected: .. Seq Int
actual: ρ Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: longest-run-helper
at: line 14, column 10
message: `prim seq-int.len` in `longest-run-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Int Int Seq Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { [ xs target 0 ] has-pair-sum-helper };

: has-pair-sum-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    xs i prim seq-int.len prim >= [
      false
    ] [
      xs j prim seq-int.len prim >= [
        [ xs target i 1 prim + ] dip has-pair-sum-helper
      ] [
        i j prim = [
          [ xs target i j 1 prim + ] dip has-pair-sum-helper
        ] [
          xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [
            true
          ] [
            [ xs target i j 1 prim + ] dip has-pair-sum-helper
          ] if
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 42
message: `has-pair-sum-helper` in `main` takes 4 values (xs:Seq Int, target:Int, i:Int, j:Int), bottom to top, but only 1 value is on the stack before it: the quotation `[ xs target 0 ]`. `main` calls `has-pair-sum-helper`, which has an error of its own; this report assumes `has-pair-sum-helper` keeps its stack effect.
hint: Push the 3 missing values before `has-pair-sum-helper`. The locals here, `xs` and `target`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.branch-mismatch
word: has-pair-sum-helper
at: line 23, column 9
message: The two branches of `if` in `has-pair-sum-helper` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 2 values. The `if` takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { [ xs 0 prim seq-int.empty ] count-distinct-helper };

: count-distinct-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs i seen } {
    xs i prim seq-int.len prim >= [
      seen 0 prim seq-int.len
    ] [
      xs i prim seq-int.at [ xs i seen ] has-seen-value [
        [ xs i 1 prim + ] dip count-distinct-helper
      ] [
        xs i prim seq-int.at seen prim seq-int.push [ xs i 1 prim + ] dip count-distinct-helper
      ] if
    ] if
  };

: has-seen-value
  (forall ρ; ρ xs:Seq Int^many i:Int^many val:Int^many seen:Seq Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs i val seen j } {
    seen j prim seq-int.len prim >= [
      false
    ] [
      seen j prim seq-int.at val prim = [
        true
      ] [
        [ xs i val seen j 1 prim + ] dip has-seen-value
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 47
message: `count-distinct-helper` in `main` takes 3 values (xs:Seq Int, i:Int, seen:Seq Int), bottom to top, but only 1 value is on the stack before it: the quotation `[ xs 0 prim seq-int.empty ]`. `main` calls `count-distinct-helper`, which has an error of its own; this report assumes `count-distinct-helper` keeps its stack effect.
hint: Push the 2 missing values before `count-distinct-helper`. The local here, `xs`, is not a value on the stack: writing a local's name pushes its value.

error 2 of 3
code: firth.type.branch-mismatch
word: count-distinct-helper
at: line 15, column 9
message: The two branches of `if` in `count-distinct-helper` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller. `count-distinct-helper` calls `has-seen-value`, which has an error of its own; this report assumes `has-seen-value` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.primitive-input-mismatch
word: has-seen-value
at: line 22, column 12
message: `prim seq-int.len` in `has-seen-value` takes Seq Int, bottom to top, but here it gets, bottom to top, `j` (Int).
expected: .. Seq Int
actual: ρ Seq Int Int Int Seq Int Int Seq Int Int
hint: The top value, `j` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 [ xs ys ] merge-sorted-helper };

: merge-sorted-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    xs i prim seq-int.len prim >= [
      [ result ys j ] add-remaining-ys
    ] [
      ys j prim seq-int.len prim >= [
        [ result xs i ] add-remaining-xs
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim <= [
          result xs i prim seq-int.at prim seq-int.push [ xs ys i 1 prim + j ] dip merge-sorted-helper
        ] [
          result ys j prim seq-int.at prim seq-int.push [ xs ys i j 1 prim + ] dip merge-sorted-helper
        ] if
      ] if
    ] if
  };

: add-remaining-xs
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    xs i prim seq-int.len prim >= [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.push [ xs i 1 prim + ] dip add-remaining-xs
    ] if
  };

: add-remaining-ys
  (forall ρ; ρ result:Seq Int^many ys:Seq Int^many j:Int^many -- ρ final:Seq Int^many)
  locals { result ys j } {
    ys j prim seq-int.len prim >= [
      result
    ] [
      result ys j prim seq-int.at prim seq-int.push [ ys j 1 prim + ] dip add-remaining-ys
    ] if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.word-input-mismatch
word: main
at: line 3, column 55
message: `merge-sorted-helper` in `main` needs Seq Int Int Int Seq Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int Int [ .. -- .. Seq Int Seq Int ]. `main` calls `merge-sorted-helper`, which has an error of its own; this report assumes `merge-sorted-helper` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int Seq Int
actual: ρ Seq Int Int Int [ .. -- .. Seq Int Seq Int ]
hint: `merge-sorted-helper` takes 5 values but only 4 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 4
code: firth.type.branch-mismatch
word: merge-sorted-helper
at: line 19, column 9
message: The two branches of `if` in `merge-sorted-helper` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `merge-sorted-helper` calls `add-remaining-xs`, which has an error of its own; this report assumes `add-remaining-xs` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 4
code: firth.type.primitive-input-mismatch
word: add-remaining-xs
at: line 26, column 10
message: `prim seq-int.len` in `add-remaining-xs` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Seq Int Seq Int Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 4 of 4
code: firth.type.primitive-input-mismatch
word: add-remaining-ys
at: line 36, column 10
message: `prim seq-int.len` in `add-remaining-ys` takes Seq Int, bottom to top, but here it gets, bottom to top, `j` (Int).
expected: .. Seq Int
actual: ρ Seq Int Seq Int Int Seq Int Int
hint: The top value, `j` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
      n 0 prim < [ n 0 prim - ] [ n ] if [ prim seq-int.empty ] digits-helper
    ] if
  };

: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      result n 10 prim mod prim seq-int.push [ n 10 prim div ] dip digits-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 7, column 65
message: `digits-helper` in `main` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int) and the quotation `[ prim seq-int.empty ]`.
expected: .. Int Seq Int
actual: .. Int [ .. -- .. Seq Int ]
hint: The top value, the quotation `[ prim seq-int.empty ]`, is not what `digits-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    n 2 prim < [
      prim seq-int.empty
    ] [
      [ n 1 prim + prim seq-bool.empty ] make-sieve [ n ] sieve-eratosthenes [ prim seq-int.empty n 2 ] collect-primes
    ] if
  };

: make-sieve
  (forall ρ; ρ sieve:Seq Bool^many n:Int^many i:Int^many -- ρ result:Seq Bool^many)
  locals { sieve n i } {
    i n prim >= [
      sieve
    ] [
      [ sieve i true prim seq-bool.set ] dip i 1 prim + make-sieve
    ] if
  };

: sieve-eratosthenes
  (forall ρ; ρ sieve:Seq Bool^many n:Int^many p:Int^many -- ρ result:Seq Bool^many)
  locals { sieve n p } {
    p p prim * n prim > [
      sieve
    ] [
      sieve p prim seq-bool.at [
        [ sieve p ] mark-multiples [ n p p prim * ] dip sieve-eratosthenes
      ] [
        [ n p 1 prim + ] dip sieve-eratosthenes
      ] if
    ] if
  };

: mark-multiples
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many multiple:Int^many n:Int^many -- ρ result:Seq Bool^many)
  locals { sieve p multiple n } {
    multiple n prim > [
      sieve
    ] [
      [ sieve multiple false prim seq-bool.set ] dip [ p multiple prim + ] mark-multiples
    ] if
  };

: collect-primes
  (forall ρ; ρ result:Seq Int^many sieve:Seq Bool^many n:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sieve n i } {
    i n prim > [
      result
    ] [
      sieve i prim seq-bool.at [
        result i prim seq-int.push [ sieve n i 1 prim + ] dip collect-primes
      ] [
        [ sieve n i 1 prim + ] dip collect-primes
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 5 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 5
code: firth.type.branch-mismatch
word: main
at: line 8, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ prim seq-int.empty ]`, `make-sieve` needs 3 values (sieve:Seq Bool, n:Int, i:Int), but the branch has pushed only 1 value before it (the quotation `[ n 1 prim + prim seq-bool.empty ]`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `main` calls `make-sieve`, which has an error of its own; this report assumes `make-sieve` keeps its stack effect.
hint: Make the branch push, just before `make-sieve`, exactly the values it takes, in this order: sieve:Seq Bool, n:Int, i:Int. The branch already pushes the quotation `[ n 1 prim + prim seq-bool.empty ]`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `make-sieve` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 5
code: firth.type.branch-mismatch
word: make-sieve
at: line 18, column 7
message: In the false branch of the `if` in `make-sieve` whose true branch is `[ sieve ]`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ sieve i true prim seq-bool.set ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 5
code: firth.type.branch-mismatch
word: sieve-eratosthenes
at: line 31, column 9
message: In the true branch `[ [ sieve p ] mark-multiples [ n ...` of the `if` in `sieve-eratosthenes`, `mark-multiples` needs 4 values (sieve:Seq Bool, p:Int, multiple:Int, n:Int), but the branch has pushed only 1 value before it (the quotation `[ sieve p ]`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `sieve-eratosthenes` calls `mark-multiples`, which has an error of its own; this report assumes `mark-multiples` keeps its stack effect.
hint: Make the branch push, just before `mark-multiples`, exactly the values it takes, in this order: sieve:Seq Bool, p:Int, multiple:Int, n:Int. The branch already pushes the quotation `[ sieve p ]`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `mark-multiples` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 5
code: firth.type.branch-mismatch
word: mark-multiples
at: line 42, column 7
message: In the false branch of the `if` in `mark-multiples` whose true branch is `[ sieve ]`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ sieve multiple false prim seq-bool.set ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 5 of 5
code: firth.type.branch-mismatch
word: collect-primes
at: line 55, column 9
message: In the false branch of the `if` in `collect-primes` whose true branch is `[ result i prim seq-int.push [ sieve n ...`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ sieve n i 1 prim + ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ k ] make-histogram [ xs k 0 ] fill-histogram
  };

: make-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result k i } {
    i k prim >= [
      result
    ] [
      [ result 0 prim seq-int.push ] dip [ k i 1 prim + ] fill-histogram
    ] if
  };

: fill-histogram
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs k i } {
    xs i prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at [ result xs k i 1 prim + ] increment-histogram
    ] if
  };

: increment-histogram
  (forall ρ; ρ idx:Int^many result:Seq Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { idx result xs k i } {
    result idx prim seq-int.at 1 prim + [ result idx ] prim seq-int.set [ xs k i ] dip fill-histogram
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: main
at: line 4, column 11
message: `make-histogram` in `main` takes 3 values (result:Seq Int, k:Int, i:Int), bottom to top, but only 1 value is on the stack before it: the quotation `[ k ]`. `main` calls `make-histogram`, which has an error of its own; this report assumes `make-histogram` keeps its stack effect.
hint: Push the 2 missing values before `make-histogram`. The locals here, `xs` and `k`, are not values on the stack: writing a local's name pushes its value.

error 2 of 4
code: firth.type.branch-mismatch
word: make-histogram
at: line 14, column 7
message: In the false branch of the `if` in `make-histogram` whose true branch is `[ result ]`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ result 0 prim seq-int.push ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `make-histogram` calls `fill-histogram`, which has an error of its own; this report assumes `fill-histogram` keeps its stack effect.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 4
code: firth.type.branch-mismatch
word: fill-histogram
at: line 24, column 7
message: The two branches of `if` in `fill-histogram` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 3 values from the stack below the `if` and leaves 1 value. The false branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `fill-histogram` calls `increment-histogram`, which has an error of its own; this report assumes `increment-histogram` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 4
code: firth.type.stack-underflow
word: increment-histogram
at: line 30, column 56
message: `prim seq-int.set` in `increment-histogram` takes 3 values (the sequence (Seq Int), the index (Int) and the new value (Int)), bottom to top, but only 2 values are on the stack before it, bottom to top: the result of `prim +` (Int) and the quotation `[ result idx ]`.
hint: Push the missing value before `prim seq-int.set`. The locals here, `idx`, `result`, `xs`, `k` and `i`, are not values on the stack: writing a local's name pushes its value.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { [ xs prim seq-int.empty 0 ] insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs sorted i } {
    xs i prim seq-int.len prim >= [
      sorted
    ] [
      xs i prim seq-int.at [ xs sorted i 1 prim + ] insert-element
    ] if
  };

: insert-element
  (forall ρ; ρ val:Int^many xs:Seq Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { val xs sorted i } {
    [ val sorted 0 ] insert-at-pos [ xs i 1 prim + ] dip insertion-sort
  };

: insert-at-pos
  (forall ρ; ρ val:Int^many sorted:Seq Int^many j:Int^many -- ρ sorted2:Seq Int^many)
  locals { val sorted j } {
    sorted j prim seq-int.len prim >= [
      sorted val prim seq-int.push
    ] [
      sorted j prim seq-int.at val prim > [
        [ val sorted j ] shift-and-insert
      ] [
        [ val sorted j 1 prim + ] dip insert-at-pos
      ] if
    ] if
  };

: shift-and-insert
  (forall ρ; ρ val:Int^many sorted:Seq Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { val sorted j } {
    sorted j prim seq-int.len j prim - [ sorted j ] shift-right val prim seq-int.push
  };

: shift-right
  (forall ρ; ρ sorted:Seq Int^many j:Int^many count:Int^many -- ρ result:Seq Int^many)
  locals { sorted j count } {
    count 0 prim = [
      sorted
    ] [
      [ sorted j prim seq-int.len 1 prim - dup sorted swap prim seq-int.at prim seq-int.set ] dip [ j 1 prim - count 1 prim - ] dip shift-right
    ] if
  };

```
On the example, the run failed:
The checker found 6 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 6
code: firth.type.stack-underflow
word: main
at: line 3, column 47
message: `insertion-sort` in `main` takes 3 values (xs:Seq Int, sorted:Seq Int, i:Int), bottom to top, but only 1 value is on the stack before it: the quotation `[ xs prim seq-int.empty 0 ]`. `main` calls `insertion-sort`, which has an error of its own; this report assumes `insertion-sort` keeps its stack effect.
hint: Push the 2 missing values before `insertion-sort`. The local here, `xs`, is not a value on the stack: writing a local's name pushes its value.

error 2 of 6
code: firth.type.branch-mismatch
word: insertion-sort
at: line 12, column 7
message: The two branches of `if` in `insertion-sort` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `insertion-sort` calls `insert-element`, which has an error of its own; this report assumes `insert-element` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 6
code: firth.type.stack-underflow
word: insert-element
at: line 18, column 22
message: `insert-at-pos` in `insert-element` takes 3 values (val:Int, sorted:Seq Int, j:Int), bottom to top, but only 1 value is on the stack before it: the quotation `[ val sorted 0 ]`. `insert-element` calls `insert-at-pos`, which has an error of its own; this report assumes `insert-at-pos` keeps its stack effect.
hint: Push the 2 missing values before `insert-at-pos`. The locals here, `val`, `xs`, `sorted` and `i`, are not values on the stack: writing a local's name pushes its value.

error 4 of 6
code: firth.type.branch-mismatch
word: insert-at-pos
at: line 31, column 9
message: The two branches of `if` in `insert-at-pos` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 2 values. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `insert-at-pos` calls `shift-and-insert`, which has an error of its own; this report assumes `shift-and-insert` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 5 of 6
code: firth.type.primitive-input-mismatch
word: shift-and-insert
at: line 38, column 14
message: `prim seq-int.len` in `shift-and-insert` takes Seq Int, bottom to top, but here it gets, bottom to top, `j` (Int).
expected: .. Seq Int
actual: ρ Int Seq Int Int Seq Int Int
hint: The top value, `j` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 6 of 6
code: firth.type.primitive-input-mismatch
word: shift-right
at: line 47, column 18
message: `prim seq-int.len` in `shift-right` takes Seq Int, bottom to top, but here it gets, bottom to top, `j` (Int).
expected: .. Seq Int
actual: .. Int
hint: The top value, `j` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 [ txs ] process-transactions };

: process-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    txs i prim seq-int.len prim >= [
      balance rejected
    ] [
      txs i prim seq-int.at balance prim + 0 prim < [
        balance rejected 1 prim + [ txs i 1 prim + ] dip process-transactions
      ] [
        balance txs i prim seq-int.at prim + rejected [ txs i 1 prim + ] dip process-transactions
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 44
message: `process-transactions` in `main` takes balance:Int, rejected:Int, i:Int, txs:Seq Int, bottom to top, but here it gets, bottom to top, `start` (Int), `0` (Int), `0` (Int) and the quotation `[ txs ]`. `main` calls `process-transactions`, which has an error of its own; this report assumes `process-transactions` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Int Int Int [ .. -- .. Seq Int ]
hint: The top value, the quotation `[ txs ]`, is not what `process-transactions` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: process-transactions
at: line 8, column 11
message: `prim seq-int.len` in `process-transactions` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ Int Int Int Seq Int Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    stock prim seq-int.empty prim seq-int.empty 0 [ items qtys whole ] process-orders
  };

: process-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    items i prim seq-int.len prim >= [
      stock allocated reasons
    ] [
      items i prim seq-int.at [ stock qtys i prim seq-int.at whole i prim seq-bool.at [ stock i ] allocate-for-order ] process-single-order
    ] if
  };

: process-single-order
  (forall ρ; ρ item-idx:Int^many result:Int^many alloc-qty:Int^many reason:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { item-idx result alloc-qty reason stock allocated reasons i items qtys whole } {
    stock item-idx result prim seq-int.set [ allocated alloc-qty prim seq-int.push ] [ reasons reason prim seq-int.push ] dip [ items qtys whole i 1 prim + ] dip process-orders
  };

: allocate-for-order
  (forall ρ; ρ item-idx:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many -- ρ item-idx:Int^many result:Int^many alloc-qty:Int^many reason:Int^many)
  locals { item-idx qty whole stock } {
    stock item-idx prim seq-int.at [ r ] dup [ r qty prim <= ] [
      qty 0 [ qty ]
    ] [
      r 0 prim = [
        0 2 [ 0 ]
      ] [
        whole [
          0 3 [ 0 ]
        ] [
          r 1 [ r ]
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: main
at: line 4, column 72
message: `process-orders` in `main` takes 7 values (stock:Seq Int, allocated:Seq Int, reasons:Seq Int, i:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool), bottom to top, but only 5 values are on the stack before it, bottom to top: `stock` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and the quotation `[ items qtys whole ]`. `main` calls `process-orders`, which has an error of its own; this report assumes `process-orders` keeps its stack effect.
hint: Push the 2 missing values before `process-orders`. The locals here, `stock`, `items`, `qtys` and `whole`, are not values on the stack: writing a local's name pushes its value.

error 2 of 4
code: firth.type.branch-mismatch
word: process-orders
at: line 14, column 7
message: The two branches of `if` in `process-orders` leave different numbers of values: the true branch pushes 3 values, and the false branch takes 9 values from the stack below the `if` and leaves 3 values. The false branch takes 9 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `process-orders` calls `process-single-order`, which has an error of its own; this report assumes `process-single-order` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 4
code: firth.type.word-input-mismatch
word: process-single-order
at: line 20, column 163
message: `process-orders` in `process-single-order` takes stock:Seq Int, allocated:Seq Int, reasons:Seq Int, i:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), the result of `prim seq-int.push` (Seq Int), `items` (Seq Int), `qtys` (Seq Int), `whole` (Seq Bool), the result of `prim +` (Int) and the quotation `[ allocated alloc-qty prim seq-int.push ]`. `process-single-order` calls `process-orders`, which has an error of its own; this report assumes `process-orders` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Int Seq Int Seq Int Seq Bool
actual: ρ Seq Int Seq Int Seq Int Seq Int Seq Bool Int [ .. -- .. Seq Int ]
hint: The top value, the quotation `[ allocated alloc-qty prim seq-int.push ]`, is not what `process-orders` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 4 of 4
code: firth.name.unresolved
word: allocate-for-order
at: line 26, column 38
message: `r` is not a defined word, primitive or local.
actual: r
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
