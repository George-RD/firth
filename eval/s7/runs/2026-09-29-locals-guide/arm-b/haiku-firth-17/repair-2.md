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
  0 locals { xs } { xs 0 sum-helper };

: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ total:Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at i 1 prim + xs sum-helper prim + ]
    [ 0 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 26
message: `sum-helper` in `main` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `xs` (Int) and `0` (Int). `main` calls `sum-helper`, which has an error of its own; this report assumes `sum-helper` keeps its stack effect.
expected: .. Seq Int Int
actual: ρ Seq Int Int Int
hint: The second value from the top, `xs` (Int), is not what `sum-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: sum-helper
at: line 9, column 42
message: `sum-helper` in `sum-helper` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-helper` takes, in another order. To push them in its order, write `xs i 1 prim +` in place of `i 1 prim + xs`. With that edit `sum-helper` checks.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 max-helper };

: max-helper
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ largest:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if i 1 prim + xs max-helper ]
    [ max ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: max-helper
at: line 9, column 89
message: `max-helper` in `max-helper` takes max:Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Int
actual: .. Int Int Seq Int
hint: These are the values `max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if` and `i 1 prim +` are for `max` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 xs 0 count-below-helper };

: count-below-helper
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ result:Int^many)
  locals { count xs i k } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + xs k count-below-helper ]
    [ count ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 28
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Seq Int Int Int [ .. Int Seq Int Int Int -- .. Int ]). `main` calls `count-below-helper`, which has an error of its own; this report assumes `count-below-helper` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.word-input-mismatch
word: count-below-helper
at: line 9, column 85
message: `count-below-helper` in `count-below-helper` takes count:Int, xs:Seq Int, i:Int, k:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `k` (Int).
expected: .. Int Seq Int Int Int
actual: .. Int Int Seq Int Int
hint: These are the values `count-below-helper` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` and `i 1 prim +` are for `count` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs 0 x index-of-helper };

: index-of-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ index:Int^many)
  locals { xs i x } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at x prim = [ i ] [ i 1 prim + xs x index-of-helper ] if ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: index-of-helper
at: line 9, column 61
message: `index-of-helper` in `index-of-helper` takes xs:Seq Int, i:Int, x:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `x` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t59 ?t58
hint: These are the values `index-of-helper` takes, in another order. To push them in its order, write `xs i 1 prim + x` in place of `i 1 prim + xs x`. With that edit `index-of-helper` checks.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-helper };

: reverse-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - xs result reverse-helper ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-helper
at: line 11, column 5
message: The two branches of the `if` in `reverse-helper` whose true branch is `[ xs i prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-helper`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `reverse-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  0 locals { xs } { xs 0 prefix-helper };

: prefix-helper
  (forall ρ; ρ sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { sum xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sum prim + locals { new-sum } { new-sum prim seq-int.empty prim seq-int.push i 1 prim + xs new-sum prefix-helper } ]
    [ prim seq-int.empty ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 26
message: `prefix-helper` in `main` takes sum:Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `xs` (Int) and `0` (Int). `main` calls `prefix-helper`, which has an error of its own; this report assumes `prefix-helper` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Seq Int Int Int
hint: The second value from the top, `xs` (Int), is not what `prefix-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: prefix-helper
at: line 11, column 5
message: The two branches of the `if` in `prefix-helper` whose true branch is `[ xs i prim seq-int.at sum prim + ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prefix-helper`; the false branch leaves the result of `prim seq-int.empty`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `prefix-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-positive-helper };

: keep-positive-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { val } { val 0 prim < [ result ] [ result val prim seq-int.push ] if i 1 prim + xs keep-positive-helper } ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: keep-positive-helper
at: line 9, column 119
message: `keep-positive-helper` in `keep-positive-helper` takes result:Seq Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Seq Int Int
actual: .. Seq Int Int Seq Int Seq Int Int Seq Int
hint: These are the values `keep-positive-helper` takes, in another order. To push them in its order, write `val 0 prim < [ result ] [ result val prim seq-int.push ] if xs i 1 prim +` in place of `val 0 prim < [ result ] [ result val prim seq-int.push ] if i 1 prim + xs`. With that edit `keep-positive-helper` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 is-sorted-helper };

: is-sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim < prim not
    [ xs i prim seq-int.len 1 prim - prim < prim not [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [ i 1 prim + xs is-sorted-helper ] if ] [ true ] if ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: is-sorted-helper
at: line 9, column 12
message: `prim seq-int.len` in `is-sorted-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: .. Int
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
  locals { xs ys } { 0 xs ys 0 dot-helper };

: dot-helper
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ product:Int^many)
  locals { sum xs ys i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + xs ys dot-helper ]
    [ sum ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-helper
at: line 9, column 84
message: `dot-helper` in `dot-helper` takes sum:Int, xs:Seq Int, ys:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Int Seq Int Seq Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dot-helper` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `sum` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-true-helper };

: all-true-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-int.len prim <
    [ flags i prim seq-int.at [ i 1 prim + flags all-true-helper ] [ false ] if ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: all-true-helper
at: line 8, column 13
message: `prim seq-int.len` in `all-true-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: ρ Seq Bool Int Int Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 0 xs longest-run-helper };

: longest-run-helper
  (forall ρ; ρ max-len:Int^many current-len:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-len current-len xs } {
    xs prim seq-int.len 0 prim =
    [ max-len ]
    [ xs 0 prim seq-int.at xs 1 prim seq-int.at prim = [ current-len 1 prim + ] [ 1 ] if locals { new-len } { new-len max-len prim < [ new-len xs 1 drop longest-run-helper ] [ max-len xs 1 drop longest-run-helper ] if } ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: longest-run-helper
at: line 11, column 5
message: In the false branch of the `if` in `longest-run-helper` whose true branch is `[ max-len ]`, `longest-run-helper` (inside a quotation in that branch) needs 3 values (max-len:Int, current-len:Int, xs:Seq Int), but the branch has pushed only 2 values before it (`new-len` or `max-len` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `longest-run-helper`, exactly the values it takes, in this order: max-len:Int, current-len:Int, xs:Seq Int. The branch already pushes `new-len` or `max-len` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `longest-run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs 0 target has-pair-sum-helper };

: has-pair-sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs i target } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { val } { i 1 prim + xs target val check-pair-sum } ]
    [ false ]
    if
  };

: check-pair-sum
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many val:Int^many -- ρ found:Bool^many)
  locals { j xs target val } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at val prim + target prim = [ true ] [ j 1 prim + xs target val check-pair-sum ] if ]
    [ false ]
    if
  };

```
On the example, it returned [False] instead of [True]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty xs count-distinct-helper };

: count-distinct-helper
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen xs } {
    xs prim seq-int.len 0 prim =
    [ seen prim seq-int.len ]
    [ xs 0 prim seq-int.at locals { val } { seen val is-in [ seen val prim seq-int.push ] [ seen ] if xs 0 drop count-distinct-helper } ]
    if
  };

: is-in
  (forall ρ; ρ val:Int^many seen:Seq Int^many -- ρ found:Bool^many)
  locals { val seen } { seen 0 val is-in-helper };

: is-in-helper
  (forall ρ; ρ seen:Seq Int^many i:Int^many val:Int^many -- ρ found:Bool^many)
  locals { seen i val } {
    i seen prim seq-int.len prim <
    [ seen i prim seq-int.at val prim = [ true ] [ i 1 prim + seen val is-in-helper ] if ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-distinct-helper
at: line 10, column 54
message: `is-in` in `count-distinct-helper` takes val:Int, seen:Seq Int, bottom to top, but here it gets, bottom to top, `seen` (Seq Int) and `val` (Int).
expected: .. Int Seq Int
actual: .. Seq Int ?t18 Int ?t18 Int
hint: These are the values `is-in` takes, in another order. To push them in its order, write `val seen` in place of `seen val`. With that edit `count-distinct-helper` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: is-in-helper
at: line 22, column 72
message: `is-in-helper` in `is-in-helper` takes seen:Seq Int, i:Int, val:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `seen` (Seq Int) and `val` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t53 ?t52
hint: These are the values `is-in-helper` takes, in another order. To push them in its order, write `seen i 1 prim + val` in place of `i 1 prim + seen val`. With that edit `is-in-helper` checks.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-sorted-helper };

: merge-sorted-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys j merge-sorted-helper ] [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-sorted-helper ] if ]
    [ i xs prim seq-int.len prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys j merge-sorted-helper ] [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-sorted-helper ] [ result ] if ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-sorted-helper
at: line 9, column 123
message: `merge-sorted-helper` in `merge-sorted-helper` takes result:Seq Int, xs:Seq Int, ys:Seq Int, i:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and `j` (Int).
expected: .. Seq Int Seq Int Seq Int Int Int
actual: .. Seq Int Int Seq Int ?t107 ?t106
hint: These are the values `merge-sorted-helper` takes, in another order. To push them in its order, write `result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys j`. With that edit, the next error in `merge-sorted-helper` is at line 10, column 103.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n digits-helper ] if };

: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digits-helper ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digits-helper
at: line 10, column 28
message: `prim seq-int.push` in `digits-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `digits-helper` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n is-prime-up-to };

: is-prime-up-to
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not
    [ result ]
    [ candidate is-prime [ result candidate prim seq-int.push candidate 1 prim + n is-prime-up-to ] [ candidate 1 prim + n is-prime-up-to ] if ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 prim = [ true ] [ 2 n is-prime-divisor ] if ]
    if
  };

: is-prime-divisor
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { divisor n } {
    divisor divisor prim * n prim < prim not
    [ true ]
    [ n divisor prim mod 0 prim = [ false ] [ divisor 1 prim + n is-prime-divisor ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-prime-up-to
at: line 10, column 141
message: In the false branch of the `if` in `is-prime-up-to` whose true branch is `[ result candidate prim seq-int.push candidate 1 prim ...`, `is-prime-up-to` needs 3 values (result:Seq Int, candidate:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime-up-to`, exactly the values it takes, in this order: result:Seq Int, candidate:Int, n:Int. The branch already pushes the result of `prim +` and `n`, in the place of the last 2 (candidate:Int, n:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Seq Int) before them, for example by writing the locals that hold it. If `is-prime-up-to` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty xs 0 histogram-loop };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { result xs i k } {
    i k prim <
    [ 0 result i histogram-count-loop i 1 prim + xs histogram-loop ]
    [ result ]
    if
  };

: histogram-count-loop
  (forall ρ; ρ count:Int^many result:Seq Int^many xs:Seq Int^many val:Int^many -- ρ res-with-count:Seq Int^many)
  locals { count result xs val } {
    xs prim seq-int.len 0 prim =
    [ result count prim seq-int.push ]
    [ xs 0 prim seq-int.at val prim = [ count 1 prim + result xs 0 drop val histogram-count-loop ] [ count result xs 0 drop val histogram-count-loop ] if ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 45
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Seq Int Int Int [ .. Seq Int Seq Int Int Int -- .. Seq Int ]). `main` calls `histogram-loop`, which has an error of its own; this report assumes `histogram-loop` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 11, column 5
message: In the true branch `[ 0 result i histogram-count-loop i 1 prim ...` of the `if` in `histogram-loop`, `histogram-count-loop` needs 4 values (count:Int, result:Seq Int, xs:Seq Int, val:Int), but the branch has pushed only 3 values before it (`0`, `result` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `histogram-count-loop`, exactly the values it takes, in this order: count:Int, result:Seq Int, xs:Seq Int, val:Int. The branch already pushes `0`, `result` and `i`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `histogram-count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 insertion-sort };

: insertion-sort
  (forall ρ; ρ sorted:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { val } { sorted val insert-into i 1 prim + xs insertion-sort } ]
    [ sorted ]
    if
  };

: insert-into
  (forall ρ; ρ val:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { val sorted } {
    sorted prim seq-int.len 0 prim =
    [ sorted val prim seq-int.push ]
    [ sorted sorted prim seq-int.len 1 prim - prim seq-int.at val prim < [ sorted val prim seq-int.push ] [ sorted val insert-into-loop 0 ] if ]
    if
  };

: insert-into-loop
  (forall ρ; ρ sorted:Seq Int^many val:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted val i } {
    i sorted prim seq-int.len 1 prim - prim <
    [ sorted i prim seq-int.at val prim < [ sorted i val prim seq-int.set i 1 prim + val sorted insert-into-loop ] [ i 1 prim + val sorted insert-into-loop ] if ]
    [ sorted ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: insertion-sort
at: line 9, column 56
message: `insert-into` in `insertion-sort` takes val:Int, sorted:Seq Int, bottom to top, but here it gets, bottom to top, `sorted` (Seq Int) and `val` (Int). `insertion-sort` calls `insert-into`, which has an error of its own; this report assumes `insert-into` keeps its stack effect.
expected: .. Int Seq Int
actual: .. Seq Int Int ?t20 ?t20 Int
hint: These are the values `insert-into` takes, in another order. To push them in its order, write `val sorted` in place of `sorted val`. With that edit, the next error in `insertion-sort` is at line 9, column 82.

error 2 of 3
code: firth.type.quotation-compose-mismatch
word: insert-into
at: line 19, column 107
message: `compose` in `insert-into` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Seq Int ] [ .. Seq Int -- .. Seq Int Seq Int Int ] [ .. Seq Int Int Int -- .. Seq Int Int ]. Expected Seq Int, found Int. `insert-into` calls `insert-into-loop`, which has an error of its own; this report assumes `insert-into-loop` keeps its stack effect.
expected: Seq Int
actual: Int

error 3 of 3
code: firth.type.branch-mismatch
word: insert-into-loop
at: line 27, column 159
message: The two branches of the `if` in `insert-into-loop` whose true branch is `[ sorted i val prim seq-int.set i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-into-loop`; the false branch leaves the result of `insert-into-loop`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-into-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { new-balance } { new-balance 0 prim < [ balance rejected 1 prim + i 1 prim + txs ledger-loop ] [ new-balance rejected i 1 prim + txs ledger-loop ] if } } ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ledger-loop
at: line 9, column 152
message: `ledger-loop` in `ledger-loop` takes balance:Int, rejected:Int, txs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `balance` (Int), the result of `prim +` (Int), the result of `prim +` (Int) and `txs` (Seq Int).
expected: .. Int Int Seq Int Int
actual: .. ?t75 Int Int ?t72
hint: These are the values `ledger-loop` takes, in another order. By their names and types, `balance` is for `balance` and `txs` is for `txs`. Of the values of one type, `rejected 1 prim +` and `i 1 prim +` are for `rejected` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 allocate-batch-loop };

: allocate-batch-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at locals { item-id } { stock item-id prim seq-int.at locals { current-stock } { qtys i prim seq-int.at locals { qty } { current-stock qty prim < [ current-stock 0 prim = [ allocated qty prim seq-int.push 2 ] [ whole i prim seq-int.at [ allocated 0 prim seq-int.push 3 ] [ allocated current-stock prim seq-int.push 1 ] if ] if locals { alloc-qty reason } { stock item-id alloc-qty prim seq-int.set allocated alloc-qty prim seq-int.push reasons reason prim seq-int.push i 1 prim + allocate-batch-loop } ] [ allocated qty prim seq-int.push 0 ] if } } } ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 85
message: `allocate-batch-loop` needs more values than the stack holds here. `main` calls `allocate-batch-loop`, which has an error of its own; this report assumes `allocate-batch-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `allocate-batch-loop` and in what order.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-batch-loop
at: line 9, column 570
message: The two branches of `if` in `allocate-batch-loop` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 3 values, and the false branch pushes 2 values. The condition and the values the branches take from below the `if` are looked for where the locals `current-stock`, `item-id`, `reasons`, `whole`, `allocated`, `qtys`, `stock` and `i` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.
