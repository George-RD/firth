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
  0 0 sum-helper;

: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    [ i xs prim seq-int.len prim = ] [ acc ] [
      xs i prim seq-int.at acc prim +
      xs i 1 prim + sum-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-helper
at: line 10, column 21
message: `sum-helper` in `sum-helper` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `sum-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at acc prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    xs prim seq-int.at 1 0 xs prim seq-int.len max-helper
  };

: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    [ i xs prim seq-int.len prim = ] [ max ] [
      xs i prim seq-int.at max [ prim < ] [ max ] [ xs i prim seq-int.at ] if
      i 1 prim + xs max-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 4, column 8
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Seq Int [ .. Seq Int Int -- .. Int ]).
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.branch-mismatch
word: max-helper
at: line 13, column 7
message: The two branches of the `if` in `max-helper` whose true branch is `[ max ]` leave different numbers of values. The true branch leaves `max`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, `max` and the result of `max-helper`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim seq-int.at` and `max` are left below the result of `max-helper`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-helper };

: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    [ i xs prim seq-int.len prim = ] [ count ] [
      xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if
      xs k i 1 prim + count-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: count-helper
at: line 10, column 23
message: `count-helper` in `count-helper` takes xs:Seq Int, k:Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: These are the values `count-helper` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` and `i 1 prim +` are for `i` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-helper };

: index-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    [ i xs prim seq-int.len prim = ] [ -1 ] [
      xs i prim seq-int.at x prim = [ i ] [
        xs x i 1 prim + index-helper
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: index-helper
at: line 12, column 7
message: `if` in `index-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    prim seq-int.empty xs prim seq-int.len 1 prim - reverse-helper
  };

: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i -1 prim = ] [ result ] [
      xs i prim seq-int.at result prim seq-int.push
      xs i 1 prim - reverse-helper result
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 53
message: `reverse-helper` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int. `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Int
hint: `reverse-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-helper
at: line 13, column 7
message: The two branches of the `if` in `reverse-helper` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `reverse-helper` and `result`.
hint: The false branch leaves 1 value more than the true branch: the result of `reverse-helper` is left below `result`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty 0 0 xs prefix-helper
  };

: prefix-helper
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i xs } {
    [ i xs prim seq-int.len prim = ] [ result ] [
      xs i prim seq-int.at sum prim +
      result swap prim seq-int.push
      result sum i 1 prim + xs prefix-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-helper
at: line 14, column 7
message: The two branches of the `if` in `prefix-helper` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prefix-helper`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `prefix-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty 0 xs filter-helper
  };

: filter-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    [ i xs prim seq-int.len prim = ] [ result ] [
      xs i prim seq-int.at dup 0 prim < [ drop ] [ result swap prim seq-int.push ] if
      result i 1 prim + xs filter-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-helper
at: line 11, column 84
message: The two branches of the `if` in `filter-helper` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 check-sorted };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    [ i xs prim seq-int.len 1 prim - prim = ] [ true ] [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < 
      [ false ] [
        xs i 1 prim + check-sorted
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: check-sorted
at: line 13, column 7
message: `if` in `check-sorted` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-helper };

: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    [ i xs prim seq-int.len prim = ] [ sum ] [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      xs ys i 1 prim + dot-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-helper
at: line 10, column 24
message: `dot-helper` in `dot-helper` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `dot-helper` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 check-all-true };

: check-all-true
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    [ i flags prim seq-bool.len prim = ] [ true ] [
      flags i prim seq-bool.at [ flags i 1 prim + check-all-true ] [ false ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: check-all-true
at: line 10, column 7
message: `if` in `check-all-true` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ xs prim seq-int.len 0 prim = ] [ 0 ] [
      xs 1 xs prim seq-int.at 1 0 longest-run-helper
    ] if
  };

: longest-run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-len max-len } {
    [ i xs prim seq-int.len prim = ] [ max-len ] [
      xs i prim seq-int.at current-val prim = 
      [ 
        xs i 1 prim + current-val current-len 1 prim + max-len longest-run-helper
      ] [
        [ current-len max-len prim < ] [ max-len ] [ current-len ] if
        xs i 1 prim + xs i prim seq-int.at 1 longest-run-helper
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 6, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `longest-run-helper` needs 5 values (xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int), but the branch has pushed only 4 values before it (`xs`, the result of `prim seq-int.at`, `1` and `0`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `longest-run-helper`, which has an error of its own; this report assumes `longest-run-helper` keeps its stack effect.
hint: Make the branch push, just before `longest-run-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int. The branch already pushes `xs`, the result of `prim seq-int.at`, `1` and `0`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `longest-run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.expected-bool
word: longest-run-helper
at: line 17, column 68
message: `if` in `longest-run-helper` needs a Bool condition under its two quotations, but the stack before it is .. ?t173 ?t172 [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 find-pair };

: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    [ i xs prim seq-int.len prim = ] [ false ] [
      xs i prim seq-int.at target swap prim - i 1 prim + xs target swap prim - check-for-sum
    ] if
  };

: check-for-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many need:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target need j } {
    [ j xs prim seq-int.len prim = ] [ false ] [
      xs j prim seq-int.at need prim = [ true ] [
        xs target need j 1 prim + check-for-sum
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-pair
at: line 10, column 7
message: The two branches of `if` in `find-pair` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller. `find-pair` calls `check-for-sum`, which has an error of its own; this report assumes `check-for-sum` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.expected-bool
word: check-for-sum
at: line 20, column 7
message: `if` in `check-for-sum` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 count-uniq };

: count-uniq
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    [ i xs prim seq-int.len prim = ] [ count ] [
      xs i prim seq-int.at xs 0 is-seen [ count ] [ count 1 prim + ] if
      xs i 1 prim + count-uniq
    ] if
  };

: is-seen
  (forall ρ; ρ xs:Seq Int^many j:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs j target } {
    [ j xs prim seq-int.len prim = ] [ false ] [
      xs j prim seq-int.at target prim = [ true ] [
        xs j 1 prim + target is-seen
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-uniq
at: line 9, column 33
message: `is-seen` in `count-uniq` takes xs:Seq Int, j:Int, target:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `0` (Int). `count-uniq` calls `is-seen`, which has an error of its own; this report assumes `is-seen` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t42 Int Seq Int Int
hint: These are the values `is-seen` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `0` are for `j` and `target`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.expected-bool
word: is-seen
at: line 21, column 7
message: `if` in `is-seen` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-helper };

: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs ys result i j } {
    [ i xs prim seq-int.len prim = ] [
      [ j ys prim seq-int.len prim = ] [ result ] [
        result ys j prim seq-int.at prim seq-int.push
        xs ys result i j 1 prim + merge-helper
      ] if
    ] [
      [ j ys prim seq-int.len prim = ] [
        result xs i prim seq-int.at prim seq-int.push
        xs ys result i 1 prim + j merge-helper
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result xs i prim seq-int.at prim seq-int.push
          xs ys result i 1 prim + j merge-helper
        ] [
          result ys j prim seq-int.at prim seq-int.push
          xs ys result i j 1 prim + merge-helper
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-helper
at: line 12, column 9
message: The two branches of the `if` in `merge-helper` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-helper`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `merge-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    [ n 0 prim = ] [ 0 prim seq-int.empty prim seq-int.push ] [
      prim seq-int.empty n digits-loop
    ] if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    [ n 0 prim = ] [ result ] [
      n 10 prim mod result prim seq-int.push
      n 10 prim div digits-loop result
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 4, column 43
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and the result of `prim seq-int.empty` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `prim seq-int.empty 0` in place of `0 prim seq-int.empty`. With that edit, the next error in `main` is at line 6, column 7. That edit was checked assuming `digits-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.branch-mismatch
word: digits-loop
at: line 15, column 7
message: The two branches of the `if` in `digits-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `digits-loop` and `result`.
hint: The false branch leaves 1 value more than the true branch: the result of `digits-loop` is left below `result`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n check-primes };

: check-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result candidate n } {
    [ candidate n prim <= ] [ result candidate is-prime [ result candidate prim seq-int.push ] [ result ] if
      result candidate 1 prim + n check-primes
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    [ num 2 prim < ] [ false ] [ num 2 prim = ] [ true ] [
      num 2 check-divisor
    ] if
  };

: check-divisor
  (forall ρ; ρ num:Int^many d:Int^many -- ρ result:Bool^many)
  locals { num d } {
    [ d d prim * num prim < ] [ true ] [
      num d prim mod 0 prim = [ false ] [
        num d 1 prim + check-divisor
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 25
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty k init-histogram xs 0 count-histogram };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result k } {
    [ k 0 prim = ] [ result ] [
      result 0 prim seq-int.push k 1 prim - init-histogram
    ] if
  };

: count-histogram
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    [ i xs prim seq-int.len prim = ] [ result ] [
      xs i prim seq-int.at result swap prim seq-int.at 1 prim + prim seq-int.set
      result xs i 1 prim + count-histogram
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: init-histogram
at: line 10, column 7
message: `if` in `init-histogram` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.branch-mismatch
word: count-histogram
at: line 19, column 7
message: In the false branch of the `if` in `count-histogram` whose true branch is `[ result ]`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs sort-insert-all };

: sort-insert-all
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    [ i xs prim seq-int.len prim = ] [ result ] [
      xs i prim seq-int.at result 0 insert-sorted
      result i 1 prim + xs sort-insert-all
    ] if
  };

: insert-sorted
  (forall ρ; ρ result:Seq Int^many value:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { result value pos } {
    [ pos result prim seq-int.len prim = ] [ result value prim seq-int.push ] [
      [ value result pos prim seq-int.at prim < ] [
        result pos value prim seq-int.set
      ] [
        result
      ] if
      swap
      pos 1 prim + insert-sorted value
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sort-insert-all
at: line 11, column 7
message: The two branches of the `if` in `sort-insert-all` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `insert-sorted` and the result of `sort-insert-all`. `sort-insert-all` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `insert-sorted` is left below the result of `sort-insert-all`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.expected-bool
word: insert-sorted
at: line 22, column 9
message: `if` in `insert-sorted` needs a Bool condition under its two quotations, but the stack before it is .. Int Int [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start start txs 0 0 process-transactions };

: process-transactions
  (forall ρ; ρ start:Int^many balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start balance txs i rejected } {
    [ i txs prim seq-int.len prim = ] [ balance rejected ] [
      balance txs i prim seq-int.at dup prim + 0 prim < [
        start balance txs i 1 prim + rejected 1 prim + process-transactions
      ] [
        start balance prim + txs i 1 prim + rejected process-transactions
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: process-transactions
at: line 13, column 9
message: The two branches of the `if` in `process-transactions` whose true branch is `[ start balance txs i 1 prim + ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the output `balance` of `process-transactions` and the output `rejected` of `process-transactions`; the false branch takes `balance` from below the `if` and leaves 2 values, bottom to top: the output `balance` of `process-transactions` and the output `rejected` of `process-transactions`.
hint: The false branch takes `balance` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 allocate-orders items qtys whole
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock stock-left allocated reasons order items qtys whole } {
    [ order qtys prim seq-int.len prim = ] [ stock-left allocated reasons ] [
      stock items order prim seq-int.at prim seq-int.at
      qtys order prim seq-int.at
      whole order prim seq-bool.at
      stock-left allocated reasons allocate-one
      stock-left allocated reasons order 1 prim + items qtys whole allocate-orders
    ] if
  };

: allocate-one
  (forall ρ; ρ current-stock:Int^many qty:Int^many whole:Bool^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { current-stock qty whole stock-left allocated reasons } {
    [ qty current-stock prim <= ] [
      stock-left qty prim seq-int.push allocated qty prim seq-int.push reasons 0 prim seq-int.push
    ] [
      [ current-stock 0 prim = ] [
        stock-left allocated reasons 2 prim seq-int.push
      ] [
        [ whole ] [
          stock-left allocated reasons 3 prim seq-int.push
        ] [
          stock-left current-stock prim seq-int.push allocated current-stock prim seq-int.push reasons 1 prim seq-int.push
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 22, column 31
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
