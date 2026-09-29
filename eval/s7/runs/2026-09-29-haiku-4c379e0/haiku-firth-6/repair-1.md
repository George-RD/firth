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
  locals { xs } { 0 0 xs prim seq-int.len sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs len i sum } {
    i len prim <
    [ xs i prim seq-int.at sum prim + swap drop sum-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs len i sum }` in `sum-loop` gives `xs` the value the stack effect calls `sum` (Int), `len` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `len` (Int), `sum` the value the stack effect calls `xs` (Seq Int).
actual: sum-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum i len xs }` in `sum-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 xs prim seq-int.len max-loop };

: max-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { xs len i max } {
    i len prim <
    [ xs i prim seq-int.at max dup prim < [ drop ] [ swap drop ] if max-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs len i max }` in `max-loop` gives `xs` the value the stack effect calls `i` (Int), `len` the value named `len` (Int), `i` the value the stack effect calls `xs` (Seq Int), `max` the value named `max` (Int).
actual: max-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i len xs max }` in `max-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs prim seq-int.len count-loop };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k len i count } {
    i len prim <
    [ xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if swap drop count-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs k len i count }` in `count-loop` gives `xs` the value the stack effect calls `count` (Int), `k` the value the stack effect calls `i` (Int), `len` the value named `len` (Int), `i` the value the stack effect calls `xs` (Seq Int), `count` the value the stack effect calls `k` (Int).
actual: count-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count i len xs k }` in `count-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs prim seq-int.len x xs find-index };

: find-index
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x len i } {
    i len prim <
    [ xs i prim seq-int.at x prim =
      [ i drop drop drop ]
      [ i 1 prim + i drop find-index ]
      if
    ]
    [ drop -1 drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs x len i }` in `find-index` gives `xs` the value the stack effect calls `i` (Int), `x` the value the stack effect calls `len` (Int), `len` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `x` (Int).
actual: find-index
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i len xs x }` in `find-index`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ ]
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - reverse-loop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs i result }` in `reverse-loop` gives `xs` the value the stack effect calls `result` (Seq Int), `i` the value named `i` (Int), `result` the value the stack effect calls `xs` (Seq Int).
actual: reverse-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i xs }` in `reverse-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs len i sum result } {
    i len prim <
    [ xs i prim seq-int.at sum prim + sum 1 prim + result prim seq-int.push drop prefix-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs len i sum result }` in `prefix-loop` gives `xs` the value the stack effect calls `result` (Seq Int), `len` the value the stack effect calls `sum` (Int), `i` the value named `i` (Int), `sum` the value the stack effect calls `len` (Int), `result` the value the stack effect calls `xs` (Seq Int).
actual: prefix-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result sum i len xs }` in `prefix-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len keep-positive-loop };

: keep-positive-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs len i result } {
    i len prim <
    [ xs i prim seq-int.at dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      i 1 prim + keep-positive-loop
    ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs len i result }` in `keep-positive-loop` gives `xs` the value the stack effect calls `result` (Seq Int), `len` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `len` (Int), `result` the value the stack effect calls `xs` (Seq Int).
actual: keep-positive-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i len xs }` in `keep-positive-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    xs prim seq-int.len dup 1 prim <
    [ drop true ]
    [ xs 0 1 check-sorted ]
    if
  };

: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim < 
      [ false ]
      [ i 1 prim + check-sorted ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 12, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs i }` in `check-sorted` gives `xs` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `xs` (Seq Int).
actual: check-sorted
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i xs }` in `check-sorted`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs prim seq-int.len dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys len i sum } {
    i len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs ys len i sum }` in `dot-loop` gives `xs` the value the stack effect calls `sum` (Int), `ys` the value the stack effect calls `i` (Int), `len` the value named `len` (Int), `i` the value the stack effect calls `xs` (Seq Int), `sum` the value the stack effect calls `ys` (Seq Int).
actual: dot-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum i len xs ys }` in `dot-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 0 flags prim seq-bool.len all-true-loop };

: all-true-loop
  (forall ρ; ρ i:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags len i } {
    i len prim <
    [ flags i prim seq-bool.at
      [ i 1 prim + all-true-loop ]
      [ drop drop false ]
      if
    ]
    [ drop drop true ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { flags len i }` in `all-true-loop` gives `flags` the value the stack effect calls `i` (Int), `len` the value named `len` (Int), `i` the value the stack effect calls `flags` (Seq Bool).
actual: all-true-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i len flags }` in `all-true-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    xs prim seq-int.len dup 0 prim <
    [ drop 0 ]
    [ dup 1 prim <
      [ drop 1 ]
      [ 1 1 xs 0 prim seq-int.at longest-run-loop ]
      if
    ]
    if
  };

: longest-run-loop
  (forall ρ; ρ i:Int^many current:Int^many max:Int^many prev:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs prev max current i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup prev prim =
      [ current 1 prim + max dup prim < [ drop ] [ swap drop ] if i 1 prim + longest-run-loop ]
      [ swap drop 1 max i 1 prim + longest-run-loop ]
      if
    ]
    [ drop drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 16, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs prev max current i }` in `longest-run-loop` gives `xs` the value the stack effect calls `i` (Int), `prev` the value the stack effect calls `current` (Int), `max` the value named `max` (Int), `current` the value the stack effect calls `prev` (Int), `i` the value the stack effect calls `xs` (Seq Int).
actual: longest-run-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i current max prev xs }` in `longest-run-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len check-pairs };

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target len i } {
    i len prim <
    [ i 1 prim + xs target find-pair-for ]
    [ drop drop false ]
    if
  };

: find-pair-for
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ drop drop drop true ]
      [ j 1 prim + find-pair-for ]
      if
    ]
    [ drop drop drop check-pairs ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs target len i }` in `check-pairs` gives `xs` the value the stack effect calls `i` (Int), `target` the value the stack effect calls `len` (Int), `len` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `target` (Int); `locals { xs target i j }` in `find-pair-for` gives `xs` the value the stack effect calls `j` (Int), `target` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `xs` (Seq Int), `j` the value the stack effect calls `target` (Int).
actual: check-pairs
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i len xs target }` in `check-pairs`, and `locals { j i xs target }` in `find-pair-for`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs len i count } {
    i len prim <
    [ xs i prim seq-int.at xs 0 i is-new-value
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim + count-distinct-loop
    ]
    [ drop drop drop ]
    if
  };

: is-new-value
  (forall ρ; ρ val:Int^many start:Int^many end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs end start val } {
    start end prim <
    [ xs start prim seq-int.at val prim =
      [ drop drop drop false ]
      [ start 1 prim + is-new-value ]
      if
    ]
    [ drop drop drop true ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs len i count }` in `count-distinct-loop` gives `xs` the value the stack effect calls `count` (Int), `len` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `len` (Int), `count` the value the stack effect calls `xs` (Seq Int); `locals { xs end start val }` in `is-new-value` gives `xs` the value the stack effect calls `val` (Int), `end` the value the stack effect calls `start` (Int), `start` the value the stack effect calls `end` (Int), `val` the value the stack effect calls `xs` (Seq Int).
actual: count-distinct-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count i len xs }` in `count-distinct-loop`, and `locals { val start end xs }` in `is-new-value`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-sorted-loop };

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys j i result } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim <
    prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-sorted-loop ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-sorted-loop ]
      if
    ]
    [ i xs prim seq-int.len prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-sorted-loop ]
      [ j ys prim seq-int.len prim <
        [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-sorted-loop ]
        [ drop drop drop drop ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs ys j i result }` in `merge-sorted-loop` gives `xs` the value the stack effect calls `result` (Seq Int), `ys` the value the stack effect calls `i` (Int), `j` the value named `j` (Int), `i` the value the stack effect calls `xs` (Seq Int), `result` the value the stack effect calls `ys` (Seq Int).
actual: merge-sorted-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i j xs ys }` in `merge-sorted-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    n 0 prim =
    [ [ 0 ] ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim <
    [ drop ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digits-loop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 12, column 12
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
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    i n prim <
    [ i is-prime
      [ i result prim seq-int.push ]
      [ result ]
      if
      i 1 prim + primes-loop
    ]
    [ drop drop drop ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 prim = [ true ] [ 2 n check-divisor ] if ]
    if
  };

: check-divisor
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ result:Bool^many)
  locals { n divisor } {
    divisor dup prim * n prim <
    [ n divisor prim mod 0 prim =
      [ false ]
      [ divisor 1 prim + check-divisor ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n i result }` in `primes-loop` gives `n` the value the stack effect calls `result` (Seq Int), `i` the value named `i` (Int), `result` the value the stack effect calls `n` (Int); `locals { n divisor }` in `check-divisor` gives `n` the value the stack effect calls `divisor` (Int), `divisor` the value the stack effect calls `n` (Int).
actual: primes-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i n }` in `primes-loop`, and `locals { divisor n }` in `check-divisor`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    prim seq-int.empty 0 k create-histogram 0 xs prim seq-int.len histogram-loop
  };

: create-histogram
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k i counts } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + create-histogram ]
    [ drop drop ]
    if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs counts len i } {
    i len prim <
    [ xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set i 1 prim + histogram-loop ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 9, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k i counts }` in `create-histogram` gives `k` the value the stack effect calls `counts` (Seq Int), `i` the value named `i` (Int), `counts` the value the stack effect calls `k` (Int); `locals { xs counts len i }` in `histogram-loop` gives `xs` the value the stack effect calls `i` (Int), `counts` the value the stack effect calls `len` (Int), `len` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `counts` (Seq Int).
actual: create-histogram
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { counts i k }` in `create-histogram`, and `locals { i len xs counts }` in `histogram-loop`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len 1 prim - insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { len i result } {
    i len prim <
    [ result i result i prim seq-int.at insert-into i 1 prim + insertion-sort-loop ]
    [ drop drop drop ]
    if
  };

: insert-into
  (forall ρ; ρ pos:Int^many val:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { result j val pos } {
    j 0 prim <
    [ result pos val prim seq-int.set ]
    [ result j prim seq-int.at val prim <
      [ j 1 prim + insert-into ]
      [ result pos val prim seq-int.set ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { len i result }` in `insertion-sort-loop` gives `len` the value the stack effect calls `result` (Seq Int), `i` the value named `i` (Int), `result` the value the stack effect calls `len` (Int); `locals { result j val pos }` in `insert-into` gives `result` the value the stack effect calls `pos` (Int), `j` the value the stack effect calls `val` (Int), `val` the value the stack effect calls `j` (Int), `pos` the value the stack effect calls `result` (Seq Int).
actual: insertion-sort-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i len }` in `insertion-sort-loop`, and `locals { pos val j result }` in `insert-into`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } { start 0 0 txs prim seq-int.len ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs len i rejected balance } {
    i len prim <
    [ txs i prim seq-int.at dup balance prim + dup 0 prim <
      [ drop drop rejected 1 prim + i 1 prim + ledger-loop ]
      [ balance rejected i 1 prim + ledger-loop ]
      if
    ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { txs start }` in `main` gives `txs` the value the stack effect calls `start` (Int), `start` the value the stack effect calls `txs` (Seq Int); `locals { txs len i rejected balance }` in `ledger-loop` gives `txs` the value the stack effect calls `balance` (Int), `len` the value the stack effect calls `rejected` (Int), `i` the value named `i` (Int), `rejected` the value the stack effect calls `len` (Int), `balance` the value the stack effect calls `txs` (Seq Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { start txs }` in `main`, and `locals { balance rejected i len txs }` in `ledger-loop`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many len:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole len j reasons allocated stock-left } {
    j len prim <
    [ items j prim seq-int.at dup
      stock swap prim seq-int.at dup
      qtys j prim seq-int.at dup
      whole j prim seq-bool.at
      locals { w q r item_stock item } {
        q r prim <
        [ r 0 prim =
          [ 0 2 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
          [ w
            [ 0 3 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
            [ r 1 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
            if
          ]
          if
        ]
        [ q r prim seq-int.set stock-left allocated reasons 0 ]
        if
        j 1 prim + allocate-loop
      }
    ]
    [ drop drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 15, column 26
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
