Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { i xs acc } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at acc prim + locals { new-acc } {
        new-acc xs i 1 prim + sum-loop
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 sum-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: sum-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs acc }` in `sum-loop` gives `i` the value the stack effect calls `acc` (Int), `xs` the value named `xs` (Seq Int), `acc` the value the stack effect calls `i` (Int).
actual: sum-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { acc xs i }` in `sum-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ current-max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { i xs current-max } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { elem } {
        [ current-max ]
        [ elem ]
        elem current-max prim <
        if
        xs i 1 prim + max-loop
      }
    ]
    [ current-max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 0 max-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: max-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs current-max }` in `max-loop` gives `i` the value the stack effect calls `current-max` (Int), `xs` the value named `xs` (Seq Int), `current-max` the value the stack effect calls `i` (Int).
actual: max-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { current-max xs i }` in `max-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ result:Int^many)
  locals { k i xs count } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at k prim <
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      xs i 1 prim + k count-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 xs 0 k count-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: count-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k i xs count }` in `count-loop` gives `k` the value the stack effect calls `count` (Int), `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `count` the value the stack effect calls `k` (Int).
actual: count-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count xs i k }` in `count-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at x prim =
      [
        i
      ]
      [
        xs x i 1 prim + index-loop
      ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: index-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x xs i }` in `index-loop` gives `x` the value the stack effect calls `i` (Int), `xs` the value named `xs` (Seq Int), `i` the value the stack effect calls `x` (Int).
actual: index-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i xs x }` in `index-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 21, column 28
message: `index-loop` in `main` takes i:Int, xs:Seq Int, x:Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `x` (Int) and `0` (Int). `main` calls `index-loop`, which has an error of its own; this report assumes `index-loop` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Seq Int Int Int
hint: These are the values `index-loop` takes, in another order. To push them in its order, write `0 xs x` in place of `xs x 0`. With that edit `main` checks.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [
      i xs prim seq-int.at result prim seq-int.push locals { new-result } {
        new-result xs i 1 prim - reverse-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: reverse-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result }` in `reverse-loop` gives `i` the value the stack effect calls `result` (Seq Int), `xs` the value named `xs` (Seq Int), `result` the value the stack effect calls `i` (Int).
actual: reverse-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs i }` in `reverse-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ sum:Int^many result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { i xs result sum } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at sum prim + locals { new-sum } {
        result new-sum prim seq-int.push locals { new-result } {
          new-sum new-result xs i 1 prim + prefix-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs 0 prefix-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: prefix-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result sum }` in `prefix-loop` gives `i` the value the stack effect calls `sum` (Int), `xs` the value the stack effect calls `result` (Seq Int), `result` the value the stack effect calls `xs` (Seq Int), `sum` the value the stack effect calls `i` (Int).
actual: prefix-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum result xs i }` in `prefix-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { elem } {
        elem 0 prim <
        [
          result
        ]
        [
          result elem prim seq-int.push
        ]
        if
        xs i 1 prim + keep-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: keep-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result }` in `keep-loop` gives `i` the value the stack effect calls `result` (Seq Int), `xs` the value named `xs` (Seq Int), `result` the value the stack effect calls `i` (Int).
actual: keep-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs i }` in `keep-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [
      i xs prim seq-int.at locals { curr } {
        i 1 prim + xs prim seq-int.at locals { next } {
          curr next prim <
          [
            xs i 1 prim + sorted-loop
          ]
          [
            next curr prim = [ xs i 1 prim + sorted-loop ] [ false ] if
          ]
          if
        }
      }
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sorted-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: sorted-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs }` in `sorted-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int).
actual: sorted-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i }` in `sorted-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ product:Int^many)
  locals { i ys xs sum } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at i ys prim seq-int.at prim * sum prim + locals { new-sum } {
        new-sum xs ys i 1 prim + dot-loop
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 xs ys 0 dot-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: dot-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i ys xs sum }` in `dot-loop` gives `i` the value the stack effect calls `sum` (Int), `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int), `sum` the value the stack effect calls `i` (Int).
actual: dot-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { sum xs ys i }` in `dot-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ result:Bool^many flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { i flags result } {
    i flags prim seq-bool.len prim <
    [
      i flags prim seq-bool.at
      [
        flags i 1 prim + all-loop
      ]
      [
        false
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true flags 0 all-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: all-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i flags result }` in `all-loop` gives `i` the value the stack effect calls `result` (Bool), `flags` the value named `flags` (Seq Bool), `result` the value the stack effect calls `i` (Int).
actual: all-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result flags i }` in `all-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ max-len:Int^many run-len:Int^many xs:Seq Int^many i:Int^many -- ρ length:Int^many)
  locals { i xs run-len max-len } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { curr } {
        i 1 prim + xs prim seq-int.len prim <
        [
          i 1 prim + xs prim seq-int.at locals { next } {
            curr next prim =
            [
              max-len run-len 1 prim + locals { new-run } {
                [ new-run ] [ max-len ] new-run max-len prim < if xs new-run i 1 prim + run-loop
              }
            ]
            [
              [ run-len ] [ max-len ] run-len max-len prim < if 1 xs i 1 prim + run-loop
            ]
            if
          }
        ]
        [
          [ run-len ] [ max-len ] run-len max-len prim < if
        ]
        if
      }
    ]
    [ max-len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 0 xs 0 run-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: run-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs run-len max-len }` in `run-loop` gives `i` the value the stack effect calls `max-len` (Int), `xs` the value the stack effect calls `run-len` (Int), `run-len` the value the stack effect calls `xs` (Seq Int), `max-len` the value the stack effect calls `i` (Int).
actual: run-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { max-len run-len xs i }` in `run-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-check
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs i } {
    i 1 prim + xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { xi } {
        i 1 prim + xs prim seq-int.len prim <
        [
          i 1 prim + xs prim seq-int.at locals { xj } {
            xi xj prim + target prim =
            [
              true
            ]
            [
              xs target i 1 prim + pair-check
            ]
            if
          }
        ]
        [
          xs target i 1 prim + pair-check
        ]
        if
      }
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pair-check };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: pair-check
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { target xs i }` in `pair-check` gives `target` the value the stack effect calls `i` (Int), `xs` the value named `xs` (Seq Int), `i` the value the stack effect calls `target` (Int).
actual: pair-check
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i xs target }` in `pair-check`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 32, column 38
message: `pair-check` in `main` takes i:Int, xs:Seq Int, target:Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `target` (Int) and `0` (Int). `main` calls `pair-check`, which has an error of its own; this report assumes `pair-check` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Seq Int Int Int
hint: These are the values `pair-check` takes, in another order. To push them in its order, write `0 xs target` in place of `xs target 0`. With that edit `main` checks.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-check
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { i xs count } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { elem } {
        0 locals { j } {
          [ j xs prim seq-int.len prim < ] [ j elem xs prim seq-int.at prim = prim not prim and ] [ true ] if
          [ j 1 prim + ] compose [ j ] compose prim or
        }
        [
          count 1 prim +
        ]
        [
          count
        ]
        if
        xs i 1 prim + distinct-check
      }
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 distinct-check };

```
On the example, the run failed:
code: firth.name.locals-order
word: distinct-check
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs count }` in `distinct-check` gives `i` the value the stack effect calls `count` (Int), `xs` the value named `xs` (Seq Int), `count` the value the stack effect calls `i` (Int).
actual: distinct-check
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count xs i }` in `distinct-check`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { j i ys xs result } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        i xs prim seq-int.at j ys prim seq-int.at prim < 
        [
          result i xs prim seq-int.at prim seq-int.push locals { new-result } {
            new-result xs ys i 1 prim + j merge-loop
          }
        ]
        [
          result j ys prim seq-int.at prim seq-int.push locals { new-result } {
            new-result xs ys i j 1 prim + merge-loop
          }
        ]
        if
      ]
      [
        i xs prim seq-int.len prim <
        [
          result i xs prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result j ys prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: merge-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { j i ys xs result }` in `merge-loop` gives `j` the value the stack effect calls `result` (Seq Int), `i` the value the stack effect calls `xs` (Seq Int), `ys` the value named `ys` (Seq Int), `xs` the value the stack effect calls `i` (Int), `result` the value the stack effect calls `j` (Int).
actual: merge-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs ys i j }` in `merge-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod locals { digit } {
        result digit prim seq-int.push locals { new-result } {
          n 10 prim div new-result digit-loop
        }
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many source:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { i source result } {
    i 0 prim <
    [
      i source prim seq-int.at result prim seq-int.push locals { new-result } {
        new-result source i 1 prim - reverse-digits
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n prim seq-int.empty digit-loop locals { rev-digits } {
        prim seq-int.empty rev-digits rev-digits prim seq-int.len 1 prim - reverse-digits
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.locals-order
word: digit-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n result }` in `digit-loop` gives `n` the value the stack effect calls `result` (Seq Int), `result` the value the stack effect calls `n` (Int).
actual: digit-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result n }` in `digit-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 3
code: firth.name.locals-order
word: reverse-digits
at: line 20, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i source result }` in `reverse-digits` gives `i` the value the stack effect calls `result` (Seq Int), `source` the value named `source` (Seq Int), `result` the value the stack effect calls `i` (Int).
actual: reverse-digits
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result source i }` in `reverse-digits`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 39, column 28
message: `digit-loop` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Seq Int. `main` calls `digit-loop`, which has an error of its own; this report assumes `digit-loop` keeps its stack effect.
expected: .. Seq Int Int
actual: .. Seq Int
hint: `digit-loop` takes 2 values but only 1 value is available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        n 2 prim mod 0 prim =
        [ false ]
        [
          2 locals { i } {
            [ i i prim * n prim < ] [ true ] [ true ] if
            [ i 2 prim + ]
            [ false ]
          }
        ]
        if
      ]
      if
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many i:Int^many -- ρ primes:Seq Int^many)
  locals { i n result } {
    i n prim <
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      i 1 prim + n sieve-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty n 2 sieve-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 19, column 9
message: The two branches of the `if` in `is-prime` whose true branch is `[ false ]` leave different numbers of values. The true branch leaves `false`; the false branch leaves 3 values, bottom to top: `true`, the quotation `[ i 2 prim + ]` and the quotation `[ false ]`.
hint: The false branch leaves 2 values more than the true branch: `true` and the quotation `[ i 2 prim + ]` are left below the quotation `[ false ]`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.locals-order
word: sieve-loop
at: line 28, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i n result }` in `sieve-loop` gives `i` the value the stack effect calls `result` (Seq Int), `n` the value named `n` (Int), `result` the value the stack effect calls `i` (Int).
actual: sieve-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result n i }` in `sieve-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `is-prime`, which has an error of its own, keeps its stack effect.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k i xs result } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { val } {
        val result prim seq-int.at locals { count } {
          result val count 1 prim + prim seq-int.set xs i 1 prim + k histogram-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0 locals { init } {
      prim seq-int.empty init init prim seq-int.push locals { result-init } {
        result-init 1 locals { j } {
          [ j k prim < ] [ true ] [ true ] if
          [ result-init j prim seq-int.push ]
          [ result-init ]
        }
      }
    }
    xs 0 k histogram-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: histogram-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k i xs result }` in `histogram-loop` gives `k` the value the stack effect calls `result` (Seq Int), `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `result` the value the stack effect calls `k` (Int).
actual: histogram-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs i k }` in `histogram-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 20, column 36
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `init` (Int) and `init` (Int).
expected: .. Seq Int Int
actual: ρ Seq Int Seq Int Int Int Int
hint: The second value from the top, `init` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ elem:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result elem } {
    result prim seq-int.len locals { len } {
      0 locals { i } {
        [ i len prim < ] [ elem result i prim seq-int.at prim < prim not ] [ true ] if
        [ i 1 prim + ]
        [ i ]
      }
    }
    locals { pos } {
      result pos elem prim seq-int.set
    }
  };

: sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at insert-sorted xs i 1 prim + sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 sort-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: insert-sorted
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result elem }` in `insert-sorted` gives `result` the value the stack effect calls `elem` (Int), `elem` the value the stack effect calls `result` (Seq Int).
actual: insert-sorted
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { elem result }` in `insert-sorted`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.locals-order
word: sort-loop
at: line 18, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result }` in `sort-loop` gives `i` the value the stack effect calls `result` (Seq Int), `xs` the value named `xs` (Seq Int), `result` the value the stack effect calls `i` (Int).
actual: sort-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result xs i }` in `sort-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `insert-sorted`, which has an error of its own, keeps its stack effect.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { i txs rejected balance } {
    i txs prim seq-int.len prim <
    [
      i txs prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim <
          [
            balance txs i 1 prim + rejected 1 prim + ledger-loop
          ]
          [
            new-balance txs i 1 prim + rejected ledger-loop
          ]
          if
        }
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: ledger-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i txs rejected balance }` in `ledger-loop` gives `i` the value the stack effect calls `balance` (Int), `txs` the value the stack effect calls `rejected` (Int), `rejected` the value the stack effect calls `txs` (Seq Int), `balance` the value the stack effect calls `i` (Int).
actual: ledger-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { balance rejected txs i }` in `ledger-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 25, column 40
message: `ledger-loop` in `main` takes balance:Int, rejected:Int, txs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `start` (Int), `txs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Int Seq Int Int
actual: ρ Int Seq Int Int Int
hint: These are the values `ledger-loop` takes, in another order. By their names and types, `txs` is for `txs`. Of the values of one type, `start` and `0` are for `balance`, `rejected` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { i whole qtys items stock reasons allocated } {
    i items prim seq-int.len prim <
    [
      i items prim seq-int.at locals { item } {
        i qtys prim seq-int.at locals { qty } {
          i whole prim seq-bool.at locals { whole-flag } {
            item stock prim seq-int.at locals { curr-stock } {
              qty curr-stock prim <
              [
                allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item qty prim seq-int.set items qtys whole i 1 prim + allocate-loop
              ]
              [
                qty curr-stock prim =
                [
                  allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item 0 prim seq-int.set items qtys whole i 1 prim + allocate-loop
                ]
                [
                  curr-stock 0 prim =
                  [
                    allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
                  ]
                  [
                    whole-flag
                    [
                      allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
                    ]
                    [
                      allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set items qtys whole i 1 prim + allocate-loop
                    ]
                    if
                  ]
                  if
                ]
                if
              ]
              if
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { prim seq-int.empty prim seq-int.empty stock items qtys whole 0 allocate-loop };

```
On the example, the run failed:
code: firth.name.locals-order
word: allocate-loop
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i whole qtys items stock reasons allocated }` in `allocate-loop` gives `i` the value the stack effect calls `allocated` (Seq Int), `whole` the value the stack effect calls `reasons` (Seq Int), `qtys` the value the stack effect calls `stock` (Seq Int), `items` the value named `items` (Seq Int), `stock` the value the stack effect calls `qtys` (Seq Int), `reasons` the value the stack effect calls `whole` (Seq Bool), `allocated` the value the stack effect calls `i` (Int).
actual: allocate-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { allocated reasons stock items qtys whole i }` in `allocate-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.
