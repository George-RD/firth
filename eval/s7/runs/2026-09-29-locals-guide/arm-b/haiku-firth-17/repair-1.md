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
  locals { i xs } {
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
code: firth.name.locals-order
word: sum-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs }` in `sum-helper` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int).
actual: sum-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i }` in `sum-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
  locals { i xs max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if i 1 prim + xs max-helper ]
    [ max ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: max-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs max }` in `max-helper` gives `i` the value the stack effect calls `max` (Int), `xs` the value named `xs` (Seq Int), `max` the value the stack effect calls `i` (Int).
actual: max-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { max xs i }` in `max-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } { 0 xs 0 count-below-helper };

: count-below-helper
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ result:Int^many)
  locals { k i xs count } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + xs k count-below-helper ]
    [ count ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs }` in `main` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `count-below-helper`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: count-below-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k i xs count }` in `count-below-helper` gives `k` the value the stack effect calls `count` (Int), `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `count` the value the stack effect calls `k` (Int).
actual: count-below-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count xs i k }` in `count-below-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } { xs 0 x index-of-helper };

: index-of-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ index:Int^many)
  locals { x i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at x prim = [ i ] [ i 1 prim + xs x index-of-helper ] if ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x xs }` in `main` gives `x` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `x` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs x }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `index-of-helper`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: index-of-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x i xs }` in `index-of-helper` gives `x` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `x` (Int).
actual: index-of-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i x }` in `index-of-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
  locals { i xs result } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - xs result reverse-helper ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: reverse-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result }` in `reverse-helper` gives `i` the value the stack effect calls `result` (Seq Int), `xs` the value named `xs` (Seq Int), `result` the value the stack effect calls `i` (Int).
actual: reverse-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs i }` in `reverse-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs 0 prefix-helper };

: prefix-helper
  (forall ρ; ρ sum:Int^many result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { i xs result sum } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sum prim + locals { new-sum } { result new-sum prim seq-int.push i 1 prim + xs new-sum prefix-helper } ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: prefix-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result sum }` in `prefix-helper` gives `i` the value the stack effect calls `sum` (Int), `xs` the value the stack effect calls `result` (Seq Int), `result` the value the stack effect calls `xs` (Seq Int), `sum` the value the stack effect calls `i` (Int).
actual: prefix-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum result xs i }` in `prefix-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { val } { val 0 prim < [ result ] [ result val prim seq-int.push ] if i 1 prim + xs keep-positive-helper } ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: keep-positive-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result }` in `keep-positive-helper` gives `i` the value the stack effect calls `result` (Seq Int), `xs` the value named `xs` (Seq Int), `result` the value the stack effect calls `i` (Int).
actual: keep-positive-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs i }` in `keep-positive-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
  locals { i xs } {
    i xs prim seq-int.len prim < prim not
    [ xs i prim seq-int.len 1 prim - prim < prim not [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [ i 1 prim + xs is-sorted-helper ] if ] [ true ] if ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: is-sorted-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs }` in `is-sorted-helper` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int).
actual: is-sorted-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i }` in `is-sorted-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs } { 0 xs ys 0 dot-helper };

: dot-helper
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ product:Int^many)
  locals { i ys xs sum } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + xs ys dot-helper ]
    [ sum ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs }` in `main` gives `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `dot-helper`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: dot-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i ys xs sum }` in `dot-helper` gives `i` the value the stack effect calls `sum` (Int), `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int), `sum` the value the stack effect calls `i` (Int).
actual: dot-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum xs ys i }` in `dot-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
  locals { i flags } {
    i flags prim seq-int.len prim <
    [ flags i prim seq-int.at [ i 1 prim + flags all-true-helper ] [ false ] if ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: all-true-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i flags }` in `all-true-helper` gives `i` the value the stack effect calls `flags` (Seq Bool), `flags` the value the stack effect calls `i` (Int).
actual: all-true-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { flags i }` in `all-true-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 0 1 locals { xs } { xs longest-run-helper };

: longest-run-helper
  (forall ρ; ρ max-len:Int^many current-len:Int^many last-val:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { xs last-val current-len max-len } {
    xs prim seq-int.len 0 prim =
    [ max-len ]
    [ xs 0 prim seq-int.at last-val prim = [ current-len 1 prim + ] [ 1 ] if locals { new-len } { xs 0 prim seq-int.at new-len max-len new-len prim < [ max-len ] [ new-len ] if xs 0 prim seq-int.at new-len longest-run-helper } ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 28
message: `longest-run-helper` in `main` takes max-len:Int, current-len:Int, last-val:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int), `0` (Int) and `xs` (Int). `main` calls `longest-run-helper`, which has an error of its own; this report assumes `longest-run-helper` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Seq Int Int Int Int
hint: The top value, `xs` (Int), is not what `longest-run-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.locals-order
word: longest-run-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs last-val current-len max-len }` in `longest-run-helper` gives `xs` the value the stack effect calls `max-len` (Int), `last-val` the value the stack effect calls `current-len` (Int), `current-len` the value the stack effect calls `last-val` (Int), `max-len` the value the stack effect calls `xs` (Seq Int).
actual: longest-run-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { max-len current-len last-val xs }` in `longest-run-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } { xs 0 target has-pair-sum-helper };

: has-pair-sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ found:Bool^many)
  locals { target i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { val } { i 1 prim + xs target val check-pair-sum } ]
    [ false ]
    if
  };

: check-pair-sum
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many val:Int^many -- ρ found:Bool^many)
  locals { val target xs j } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at val prim + target prim = [ true ] [ j 1 prim + xs target val check-pair-sum ] if ]
    [ xs j prim seq-int.len 1 prim + prim < [ j 1 prim + xs target has-pair-sum-helper ] [ false ] if ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { target xs }` in `main` gives `target` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `target` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs target }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `has-pair-sum-helper`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.name.locals-order
word: has-pair-sum-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { target i xs }` in `has-pair-sum-helper` gives `target` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `target` (Int).
actual: has-pair-sum-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i target }` in `has-pair-sum-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `check-pair-sum`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.name.locals-order
word: check-pair-sum
at: line 16, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { val target xs j }` in `check-pair-sum` gives `val` the value the stack effect calls `j` (Int), `target` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `target` (Int), `j` the value the stack effect calls `val` (Int).
actual: check-pair-sum
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { j xs target val }` in `check-pair-sum`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `has-pair-sum-helper`, which has an error of its own, keeps its stack effect.

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
  locals { xs seen } {
    xs prim seq-int.len 0 prim =
    [ seen prim seq-int.len ]
    [ xs 0 prim seq-int.at locals { val } { val seen is-in [ seen val prim seq-int.push ] [ seen ] if xs 0 drop count-distinct-helper } ]
    if
  };

: is-in
  (forall ρ; ρ val:Int^many seen:Seq Int^many -- ρ found:Bool^many)
  locals { seen val } { seen 0 val is-in-helper };

: is-in-helper
  (forall ρ; ρ seen:Seq Int^many i:Int^many val:Int^many -- ρ found:Bool^many)
  locals { val i seen } {
    i seen prim seq-int.len prim <
    [ seen i prim seq-int.at val prim = [ true ] [ i 1 prim + seen val is-in-helper ] if ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.locals-order
word: count-distinct-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs seen }` in `count-distinct-helper` gives `xs` the value the stack effect calls `seen` (Seq Int), `seen` the value the stack effect calls `xs` (Seq Int).
actual: count-distinct-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { seen xs }` in `count-distinct-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `is-in`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.name.locals-order
word: is-in
at: line 16, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { seen val }` in `is-in` gives `seen` the value the stack effect calls `val` (Int), `val` the value the stack effect calls `seen` (Seq Int).
actual: is-in
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { val seen }` in `is-in`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `is-in-helper`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.name.locals-order
word: is-in-helper
at: line 20, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { val i seen }` in `is-in-helper` gives `val` the value the stack effect calls `seen` (Seq Int), `i` the value named `i` (Int), `seen` the value the stack effect calls `val` (Int).
actual: is-in-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { seen i val }` in `is-in-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } { prim seq-int.empty xs ys 0 0 merge-sorted-helper };

: merge-sorted-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { j i ys xs result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys j merge-sorted-helper ] [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-sorted-helper ] if ]
    [ i xs prim seq-int.len prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys j merge-sorted-helper ] [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-sorted-helper ] [ result ] if ] if ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs }` in `main` gives `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `merge-sorted-helper`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: merge-sorted-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { j i ys xs result }` in `merge-sorted-helper` gives `j` the value the stack effect calls `result` (Seq Int), `i` the value the stack effect calls `xs` (Seq Int), `ys` the value named `ys` (Seq Int), `xs` the value the stack effect calls `i` (Int), `result` the value the stack effect calls `j` (Int).
actual: merge-sorted-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs ys i j }` in `merge-sorted-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
  locals { n result } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digits-helper ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: digits-helper
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n result }` in `digits-helper` gives `n` the value the stack effect calls `result` (Seq Int), `result` the value the stack effect calls `n` (Int).
actual: digits-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result n }` in `digits-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
  locals { n candidate result } {
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
  locals { n divisor } {
    divisor divisor prim * n prim < prim not
    [ true ]
    [ n divisor prim mod 0 prim = [ false ] [ divisor 1 prim + n is-prime-divisor ] if ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: is-prime-up-to
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n candidate result }` in `is-prime-up-to` gives `n` the value the stack effect calls `result` (Seq Int), `candidate` the value named `candidate` (Int), `result` the value the stack effect calls `n` (Int).
actual: is-prime-up-to
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result candidate n }` in `is-prime-up-to`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.locals-order
word: is-prime-divisor
at: line 25, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n divisor }` in `is-prime-divisor` gives `n` the value the stack effect calls `divisor` (Int), `divisor` the value the stack effect calls `n` (Int).
actual: is-prime-divisor
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { divisor n }` in `is-prime-divisor`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } { 0 locals { i } { [ i k prim < ] [ 0 i 1 prim + ] [ i xs histogram-loop ] ] };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs result } {
    xs prim seq-int.len 0 prim =
    [ result ]
    [ xs 0 prim seq-int.at result xs 0 drop histogram-loop ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 94
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
  locals { i xs sorted } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { val } { val sorted insert-into i 1 prim + xs insertion-sort } ]
    [ sorted ]
    if
  };

: insert-into
  (forall ρ; ρ val:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { sorted val } {
    sorted prim seq-int.len 0 prim =
    [ sorted val prim seq-int.push ]
    [ sorted sorted prim seq-int.len 1 prim - prim seq-int.at val prim < [ sorted val prim seq-int.push ] [ sorted val insert-into-loop 0 ] if ]
    if
  };

: insert-into-loop
  (forall ρ; ρ sorted:Seq Int^many val:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { i val sorted } {
    i sorted prim seq-int.len 1 prim - prim <
    [ sorted i prim seq-int.at val prim < [ sorted i val prim seq-int.set i 1 prim + val sorted insert-into-loop ] [ i 1 prim + val sorted insert-into-loop ] if ]
    [ sorted ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.locals-order
word: insertion-sort
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs sorted }` in `insertion-sort` gives `i` the value the stack effect calls `sorted` (Seq Int), `xs` the value named `xs` (Seq Int), `sorted` the value the stack effect calls `i` (Int).
actual: insertion-sort
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sorted xs i }` in `insertion-sort`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `insert-into`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.name.locals-order
word: insert-into
at: line 16, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { sorted val }` in `insert-into` gives `sorted` the value the stack effect calls `val` (Int), `val` the value the stack effect calls `sorted` (Seq Int).
actual: insert-into
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { val sorted }` in `insert-into`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `insert-into-loop`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.name.locals-order
word: insert-into-loop
at: line 25, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i val sorted }` in `insert-into-loop` gives `i` the value the stack effect calls `sorted` (Seq Int), `val` the value named `val` (Int), `sorted` the value the stack effect calls `i` (Int).
actual: insert-into-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sorted val i }` in `insert-into-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { i txs rejected balance } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { new-balance } { new-balance 0 prim < [ balance rejected 1 prim + i 1 prim + txs ledger-loop ] [ new-balance rejected i 1 prim + txs ledger-loop ] if } } ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { txs start }` in `main` gives `txs` the value the stack effect calls `start` (Int), `start` the value the stack effect calls `txs` (Seq Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { start txs }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `ledger-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: ledger-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i txs rejected balance }` in `ledger-loop` gives `i` the value the stack effect calls `balance` (Int), `txs` the value the stack effect calls `rejected` (Int), `rejected` the value the stack effect calls `txs` (Seq Int), `balance` the value the stack effect calls `i` (Int).
actual: ledger-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { balance rejected txs i }` in `ledger-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } { stock prim seq-int.empty prim seq-int.empty 0 allocate-batch-loop };

: allocate-batch-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { whole qtys items i reasons allocated stock } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at locals { item-id } { stock item-id prim seq-int.at locals { current-stock } { qtys i prim seq-int.at locals { qty } { current-stock qty prim < [ current-stock 0 prim = [ allocated qty prim seq-int.push 2 ] [ whole i prim seq-int.at [ allocated 0 prim seq-int.push 3 ] [ allocated current-stock prim seq-int.push 1 ] if ] if locals { alloc-qty reason } { stock item-id alloc-qty prim seq-int.set allocated alloc-qty prim seq-int.push reasons reason prim seq-int.push i 1 prim + allocate-batch-loop } ] [ allocated qty prim seq-int.push 0 ] if } } } ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { whole qtys items stock }` in `main` gives `whole` the value the stack effect calls `stock` (Seq Int), `qtys` the value the stack effect calls `items` (Seq Int), `items` the value the stack effect calls `qtys` (Seq Int), `stock` the value the stack effect calls `whole` (Seq Bool).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { stock items qtys whole }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `allocate-batch-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: allocate-batch-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { whole qtys items i reasons allocated stock }` in `allocate-batch-loop` gives `whole` the value the stack effect calls `stock` (Seq Int), `qtys` the value the stack effect calls `allocated` (Seq Int), `items` the value the stack effect calls `reasons` (Seq Int), `i` the value named `i` (Int), `reasons` the value the stack effect calls `items` (Seq Int), `allocated` the value the stack effect calls `qtys` (Seq Int), `stock` the value the stack effect calls `whole` (Seq Bool).
actual: allocate-batch-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { stock allocated reasons i items qtys whole }` in `allocate-batch-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.
