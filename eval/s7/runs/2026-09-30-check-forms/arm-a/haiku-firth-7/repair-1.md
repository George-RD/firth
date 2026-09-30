Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: seq-sum
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many index:Int^many -- ρ total:Int^many)
  locals { index xs sum } {
    index xs prim seq-int.len prim <
    [ 
      sum xs index prim seq-int.at prim +
      xs index 1 prim + sum-loop
    ] [ sum ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: sum-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs sum }` in `sum-loop` gives `index` the value the stack effect calls `sum` (Int), `xs` the value named `xs` (Seq Int), `sum` the value the stack effect calls `index` (Int).
actual: sum-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum xs index }` in `sum-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 max-loop };

: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many index:Int^many -- ρ largest:Int^many)
  locals { index xs max } {
    index xs prim seq-int.len prim <
    [ 
      xs index prim seq-int.at max prim <
      [ xs index prim seq-int.at ] [ max ] if
      xs index 1 prim + max-loop
    ] [ max ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: max-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs max }` in `max-loop` gives `index` the value the stack effect calls `max` (Int), `xs` the value named `xs` (Seq Int), `max` the value the stack effect calls `index` (Int).
actual: max-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { max xs index }` in `max-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } { 0 xs 0 k count-loop };

: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many index:Int^many k:Int^many -- ρ count:Int^many)
  locals { k index xs count } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at k prim <
      [ count 1 prim + ] [ count ] if
      xs index 1 prim + k count-loop
    ] [ count ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: count-below
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs }` in `count-below` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: count-below
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `count-below`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `count-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: count-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k index xs count }` in `count-loop` gives `k` the value the stack effect calls `count` (Int), `index` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `index` (Int), `count` the value the stack effect calls `k` (Int).
actual: count-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count xs index k }` in `count-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } { xs 0 x index-loop };

: index-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many x:Int^many -- ρ index:Int^many)
  locals { x index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at x prim =
      [ index ] [ xs index 1 prim + x index-loop ] if
    ] [ -1 ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: index-of
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x xs }` in `index-of` gives `x` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `x` (Int).
actual: index-of
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs x }` in `index-of`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `index-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: index-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x index xs }` in `index-loop` gives `x` the value the stack effect calls `xs` (Seq Int), `index` the value named `index` (Int), `xs` the value the stack effect calls `x` (Int).
actual: index-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs index x }` in `index-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many index:Int^many -- ρ reversed:Seq Int^many)
  locals { index xs result } {
    index xs prim seq-int.len prim <
    [
      result xs index prim seq-int.at prim seq-int.push
      xs index 1 prim + reverse-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: reverse-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs result }` in `reverse-loop` gives `index` the value the stack effect calls `result` (Seq Int), `xs` the value named `xs` (Seq Int), `result` the value the stack effect calls `index` (Int).
actual: reverse-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs index }` in `reverse-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-sums
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many index:Int^many -- ρ sums:Seq Int^many)
  locals { index xs sum result } {
    index xs prim seq-int.len prim <
    [
      sum xs index prim seq-int.at prim +
      result sum prim seq-int.push
      xs index 1 prim + prefix-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: prefix-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs sum result }` in `prefix-loop` gives `index` the value the stack effect calls `result` (Seq Int), `xs` the value the stack effect calls `sum` (Int), `sum` the value the stack effect calls `xs` (Seq Int), `result` the value the stack effect calls `index` (Int).
actual: prefix-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result sum xs index }` in `prefix-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many index:Int^many -- ρ positives:Seq Int^many)
  locals { index xs result } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at 0 prim >
      [ result xs index prim seq-int.at prim seq-int.push ] [ result ] if
      xs index 1 prim + keep-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: keep-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs result }` in `keep-loop` gives `index` the value the stack effect calls `result` (Seq Int), `xs` the value named `xs` (Seq Int), `result` the value the stack effect calls `index` (Int).
actual: keep-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs index }` in `keep-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ true ] [ true xs 0 sort-check ] if
  };

: sort-check
  (forall ρ; ρ is-sorted:Bool^many xs:Seq Int^many index:Int^many -- ρ sorted:Bool^many)
  locals { index xs is-sorted } {
    is-sorted prim not
    [ false ] [
      index xs prim seq-int.len 1 prim - prim <
      [
        xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim <=
        xs index 1 prim + sort-check
      ] [ is-sorted ] if
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: sort-check
at: line 10, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs is-sorted }` in `sort-check` gives `index` the value the stack effect calls `is-sorted` (Bool), `xs` the value named `xs` (Seq Int), `is-sorted` the value the stack effect calls `index` (Int).
actual: sort-check
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { is-sorted xs index }` in `sort-check`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs } { 0 xs ys 0 dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many index:Int^many -- ρ product:Int^many)
  locals { index ys xs sum } {
    index xs prim seq-int.len prim <
    [
      sum xs index prim seq-int.at ys index prim seq-int.at prim * prim +
      xs ys index 1 prim + dot-loop
    ] [ sum ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: dot
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs }` in `dot` gives `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int).
actual: dot
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `dot`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `dot-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: dot-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index ys xs sum }` in `dot-loop` gives `index` the value the stack effect calls `sum` (Int), `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int), `sum` the value the stack effect calls `index` (Int).
actual: dot-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum xs ys index }` in `dot-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-int.len 0 prim =
    [ true ] [ true flags 0 all-loop ] if
  };

: all-loop
  (forall ρ; ρ result:Bool^many flags:Seq Bool^many index:Int^many -- ρ all:Bool^many)
  locals { index flags result } {
    result prim not
    [ false ] [
      index flags prim seq-int.len prim <
      [
        flags index prim seq-int.at
        flags index 1 prim + all-loop
      ] [ result ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: all-true
at: line 4, column 11
message: `prim seq-int.len` in `all-true` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: ρ Seq Bool Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.locals-order
word: all-loop
at: line 10, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index flags result }` in `all-loop` gives `index` the value the stack effect calls `result` (Bool), `flags` the value named `flags` (Seq Bool), `result` the value the stack effect calls `index` (Int).
actual: all-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result flags index }` in `all-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ] [ 1 1 xs 0 run-loop ] if
  };

: run-loop
  (forall ρ; ρ max-len:Int^many cur-len:Int^many xs:Seq Int^many index:Int^many -- ρ length:Int^many)
  locals { index xs cur-len max-len } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at xs index 1 prim - prim seq-int.at prim =
      [ cur-len 1 prim + ] [ max-len cur-len prim > [ cur-len ] [ max-len ] if 1 ] if
      xs index 1 prim + run-loop
    ] [ max-len cur-len prim > [ cur-len ] [ max-len ] if ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: run-loop
at: line 10, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs cur-len max-len }` in `run-loop` gives `index` the value the stack effect calls `max-len` (Int), `xs` the value the stack effect calls `cur-len` (Int), `cur-len` the value the stack effect calls `xs` (Seq Int), `max-len` the value the stack effect calls `index` (Int).
actual: run-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { max-len cur-len xs index }` in `run-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } { false xs target 0 pair-loop };

: pair-loop
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many index:Int^many -- ρ found:Bool^many)
  locals { index target xs found } {
    found prim not
    [
      index xs prim seq-int.len prim <
      [
        xs index prim seq-int.at 
        xs target prim seq-int.at xs index prim seq-int.at prim - prim =
        [ true ] [ false xs target index 1 prim + pair-loop ] if
      ] [ found ] if
    ] [ true ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: has-pair-sum
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { target xs }` in `has-pair-sum` gives `target` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `target` (Int).
actual: has-pair-sum
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs target }` in `has-pair-sum`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `pair-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: pair-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index target xs found }` in `pair-loop` gives `index` the value the stack effect calls `found` (Bool), `target` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `target` (Int), `found` the value the stack effect calls `index` (Int).
actual: pair-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { found xs target index }` in `pair-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty xs 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many index:Int^many -- ρ count:Int^many)
  locals { index xs seen } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      seen prim seq-int.len
      [ xs index prim seq-int.at seen 0 in-seq ] call
      prim not
      [ seen xs index prim seq-int.at prim seq-int.push ] [ seen ] if
      xs index 1 prim + distinct-loop
    ] [ seen prim seq-int.len ] if
  };

: in-seq
  (forall ρ; ρ x:Int^many seq:Seq Int^many idx:Int^many -- ρ found:Bool^many)
  locals { idx seq x } {
    idx seq prim seq-int.len prim <
    [
      seq idx prim seq-int.at x prim =
      [ true ] [ x seq idx 1 prim + in-seq ] if
    ] [ false ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: distinct-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index xs seen }` in `distinct-loop` gives `index` the value the stack effect calls `seen` (Seq Int), `xs` the value named `xs` (Seq Int), `seen` the value the stack effect calls `index` (Int).
actual: distinct-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { seen xs index }` in `distinct-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `in-seq`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: in-seq
at: line 21, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { idx seq x }` in `in-seq` gives `idx` the value the stack effect calls `x` (Int), `seq` the value named `seq` (Seq Int), `x` the value the stack effect calls `idx` (Int).
actual: in-seq
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { x seq idx }` in `in-seq`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-sorted
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many xi:Int^many yi:Int^many -- ρ merged:Seq Int^many)
  locals { yi xi ys xs result } {
    xi xs prim seq-int.len prim <
    yi ys prim seq-int.len prim < prim and
    [
      xs xi prim seq-int.at ys yi prim seq-int.at prim <=
      [
        result xs xi prim seq-int.at prim seq-int.push
        xs ys xi 1 prim + yi merge-loop
      ] [
        result ys yi prim seq-int.at prim seq-int.push
        xs ys xi yi 1 prim + merge-loop
      ] if
    ] [
      xi xs prim seq-int.len prim <
      [
        result xs xi prim seq-int.at prim seq-int.push
        xs ys xi 1 prim + yi merge-loop
      ] [
        yi ys prim seq-int.len prim <
        [
          result ys yi prim seq-int.at prim seq-int.push
          xs ys xi yi 1 prim + merge-loop
        ] [ result ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: merge-sorted
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs }` in `merge-sorted` gives `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int).
actual: merge-sorted
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `merge-sorted`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `merge-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: merge-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { yi xi ys xs result }` in `merge-loop` gives `yi` the value the stack effect calls `result` (Seq Int), `xi` the value the stack effect calls `xs` (Seq Int), `ys` the value named `ys` (Seq Int), `xs` the value the stack effect calls `xi` (Int), `result` the value the stack effect calls `yi` (Int).
actual: merge-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs ys xi yi }` in `merge-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ] [ prim seq-int.empty n digits-loop ] if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim >
    [
      n 10 prim mod
      result swap prim seq-int.push
      n 10 prim div digits-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: digits-loop
at: line 10, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n result }` in `digits-loop` gives `n` the value the stack effect calls `result` (Seq Int), `result` the value the stack effect calls `n` (Int).
actual: digits-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result n }` in `digits-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: primes-up-to
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <=
    [
      i
      [ 2 i is-prime ] call
      [ result i prim seq-int.push ] [ result ] if
      i 1 prim + n primes-loop
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ p:Int^many -- ρ prime:Bool^many)
  locals { p } {
    p 2 prim <
    [ false ] [
      p 2 prim =
      [ true ] [
        p 2 prim mod 0 prim =
        [ false ] [ true 2 p check-prime ] if
      ] if
    ] if
  };

: check-prime
  (forall ρ; ρ is-prime:Bool^many d:Int^many p:Int^many -- ρ prime:Bool^many)
  locals { p d is-prime } {
    is-prime prim not
    [ false ] [
      d d prim * p prim <=
      [
        p d prim mod 0 prim =
        [ false p d check-prime ] [ d 2 prim + p check-prime ] if
      ] [ true ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: primes-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n i result }` in `primes-loop` gives `n` the value the stack effect calls `result` (Seq Int), `i` the value named `i` (Int), `result` the value the stack effect calls `n` (Int).
actual: primes-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i n }` in `primes-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.locals-order
word: check-prime
at: line 32, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { p d is-prime }` in `check-prime` gives `p` the value the stack effect calls `is-prime` (Bool), `d` the value named `d` (Int), `is-prime` the value the stack effect calls `p` (Int).
actual: check-prime
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { is-prime d p }` in `check-prime`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } {
    prim seq-int.empty
    [ 0 ] k [ prim seq-int.push ] compose call
    xs 0 k histogram-fill
  };

: histogram-fill
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many index:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k index xs counts } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      counts swap
      [ prim seq-int.at 1 prim + ] dip
      prim seq-int.set
      xs index 1 prim + k histogram-fill
    ] [ counts ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: histogram
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs }` in `histogram` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: histogram
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `histogram`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.locals-order
word: histogram-fill
at: line 11, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k index xs counts }` in `histogram-fill` gives `k` the value the stack effect calls `counts` (Seq Int), `index` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `index` (Int), `counts` the value the stack effect calls `k` (Int).
actual: histogram-fill
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { counts xs index k }` in `histogram-fill`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs sort-helper };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ xs ] [ xs 0 1 sort-pass ] if
  };

: sort-pass
  (forall ρ; ρ xs:Seq Int^many i:Int^many n:Int^many -- ρ sorted:Seq Int^many)
  locals { n i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim >
      [
        xs i 1 prim + prim seq-int.at
        xs i
        [ prim seq-int.at xs i 1 prim + prim seq-int.set ] dip
        prim seq-int.set
      ] [ xs ] if
      xs i 1 prim + n sort-pass
    ] [ xs ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: sort-pass
at: line 14, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n i xs }` in `sort-pass` gives `n` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `n` (Int).
actual: sort-pass
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i n }` in `sort-pass`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many index:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { index txs rejected balance } {
    index txs prim seq-int.len prim <
    [
      balance txs index prim seq-int.at prim +
      0 prim <
      [ balance rejected 1 prim + txs index 1 prim + ledger-loop ] [
        balance txs index prim seq-int.at prim +
        rejected
        txs index 1 prim + ledger-loop
      ] if
    ] [ balance rejected ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: ledger
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { txs start }` in `ledger` gives `txs` the value the stack effect calls `start` (Int), `start` the value the stack effect calls `txs` (Seq Int).
actual: ledger
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { start txs }` in `ledger`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `ledger-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: ledger-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { index txs rejected balance }` in `ledger-loop` gives `index` the value the stack effect calls `balance` (Int), `txs` the value the stack effect calls `rejected` (Int), `rejected` the value the stack effect calls `txs` (Seq Int), `balance` the value the stack effect calls `index` (Int).
actual: ledger-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { balance rejected txs index }` in `ledger-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-batch
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } { 
    stock prim seq-int.empty prim seq-int.empty 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many index:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items index reasons alloc stock } {
    index qtys prim seq-int.len prim <
    [
      items index prim seq-int.at
      stock swap prim seq-int.at
      qtys index prim seq-int.at
      whole index prim seq-int.at
      [ allocate-decide ] dip
      index allocate-loop
    ] [ stock alloc reasons ] if
  };

: allocate-decide
  (forall ρ; ρ item-idx:Int^many r:Int^many qty:Int^many whole:Bool^many -- ρ result-qty:Int^many reason:Int^many)
  locals { whole qty r item-idx } {
    qty r prim <=
    [ qty 0 ] [
      r 0 prim =
      [ 0 2 ] [
        whole
        [ 0 3 ] [ r 1 ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.locals-order
word: allocate-batch
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { whole qtys items stock }` in `allocate-batch` gives `whole` the value the stack effect calls `stock` (Seq Int), `qtys` the value the stack effect calls `items` (Seq Int), `items` the value the stack effect calls `qtys` (Seq Int), `stock` the value the stack effect calls `whole` (Seq Bool).
actual: allocate-batch
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { stock items qtys whole }` in `allocate-batch`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `allocate-loop`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.name.locals-order
word: allocate-loop
at: line 9, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { whole qtys items index reasons alloc stock }` in `allocate-loop` gives `whole` the value the stack effect calls `stock` (Seq Int), `qtys` the value the stack effect calls `alloc` (Seq Int), `items` the value the stack effect calls `reasons` (Seq Int), `index` the value named `index` (Int), `reasons` the value the stack effect calls `items` (Seq Int), `alloc` the value the stack effect calls `qtys` (Seq Int), `stock` the value the stack effect calls `whole` (Seq Bool).
actual: allocate-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { stock alloc reasons index items qtys whole }` in `allocate-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `allocate-decide`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.name.locals-order
word: allocate-decide
at: line 23, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { whole qty r item-idx }` in `allocate-decide` gives `whole` the value the stack effect calls `item-idx` (Int), `qty` the value the stack effect calls `r` (Int), `r` the value the stack effect calls `qty` (Int), `item-idx` the value the stack effect calls `whole` (Bool).
actual: allocate-decide
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { item-idx r qty whole }` in `allocate-decide`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.
