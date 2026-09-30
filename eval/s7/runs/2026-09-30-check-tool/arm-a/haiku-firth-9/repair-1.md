Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { acc i xs } {
    i xs prim seq-int.len prim <
    [ 
      xs
      i 1 prim +
      acc xs i prim seq-int.at prim +
      sum-helper
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: sum-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { acc i xs }` in `sum-helper` gives `acc` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `acc` (Int).
actual: sum-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i acc }` in `sum-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { max-val i xs } {
    i xs prim seq-int.len prim <
    [ 
      max-val xs i prim seq-int.at prim <
      [ xs i prim seq-int.at ]
      [ max-val ]
      if
      locals { new-max } {
        i 1 prim +
        xs new-max max-helper
      }
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 xs 0 prim seq-int.at max-helper
  };

```
On the example, the run failed:
code: firth.name.locals-order
word: max-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { max-val i xs }` in `max-helper` gives `max-val` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `max-val` (Int).
actual: max-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i max-val }` in `max-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { cnt i k xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at k prim <
      [ cnt 1 prim + ]
      [ cnt ]
      if
      locals { new-cnt } {
        i 1 prim +
        xs k new-cnt count-helper
      }
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 count-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: count-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { cnt i k xs }` in `count-helper` gives `cnt` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `k` (Int), `k` the value the stack effect calls `i` (Int), `xs` the value the stack effect calls `cnt` (Int).
actual: count-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k i cnt }` in `count-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: search-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { i x xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs x search-helper ]
      if
    ]
    [ 0 prim - 1 prim + ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  0 search-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: search-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i x xs }` in `search-helper` gives `i` the value the stack effect calls `xs` (Seq Int), `x` the value named `x` (Int), `xs` the value the stack effect calls `i` (Int).
actual: search-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs x i }` in `search-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    [ i 1 prim + xs i xs prim seq-int.at prim seq-int.push result reverse-helper ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - 
    xs prim seq-int.empty
    reverse-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: reverse-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result i xs }` in `reverse-helper` gives `result` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `result` (Seq Int).
actual: reverse-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i result }` in `reverse-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 15, column 5
message: `reverse-helper` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `xs` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int Seq Int
hint: These are the values `reverse-helper` takes, in another order. To push them in its order, write `xs xs prim seq-int.len 1 prim - prim seq-int.empty` in place of `xs prim seq-int.len 1 prim - xs prim seq-int.empty` on line 13. With that edit `main` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        i 1 prim +
        xs new-sum result new-sum prim seq-int.push prefix-helper
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  0 0 prim seq-int.empty prefix-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: prefix-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result sum i xs }` in `prefix-helper` gives `result` the value the stack effect calls `xs` (Seq Int), `sum` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `sum` (Int), `xs` the value the stack effect calls `result` (Seq Int).
actual: prefix-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i sum result }` in `prefix-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ filtered:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at 0 prim <
      [ i 1 prim + xs result filter-helper ]
      [ 
        i 1 prim +
        xs
        result xs i prim seq-int.at prim seq-int.push
        filter-helper
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  0 prim seq-int.empty filter-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: filter-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result i xs }` in `filter-helper` gives `result` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `result` (Seq Int).
actual: filter-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i result }` in `filter-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ i 1 prim + xs check-sorted ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 check-sorted;

```
On the example, the run failed:
code: firth.name.locals-order
word: check-sorted
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs }` in `check-sorted` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int).
actual: check-sorted
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i }` in `check-sorted`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { acc i ys xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      acc prim +
      locals { new-acc } {
        i 1 prim +
        xs ys new-acc dot-helper
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: dot-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { acc i ys xs }` in `dot-helper` gives `acc` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `ys` (Seq Int), `ys` the value the stack effect calls `i` (Int), `xs` the value the stack effect calls `acc` (Int).
actual: dot-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys i acc }` in `dot-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { i flags } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        i 1 prim + flags check-all
      ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 check-all;

```
On the example, the run failed:
code: firth.name.locals-order
word: check-all
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i flags }` in `check-all` gives `i` the value the stack effect calls `flags` (Seq Bool), `flags` the value the stack effect calls `i` (Int).
actual: check-all
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { flags i }` in `check-all`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many run-len:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { max-run run-len i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
      [
        run-len 1 prim + locals { new-run } {
          i 1 prim + xs new-run max-run run-helper
        }
      ]
      [
        run-len max-run prim <
        [ max-run ]
        [ run-len ]
        if
        locals { new-max } {
          i 1 prim + xs 1 new-max run-helper
        }
      ]
      if
    ]
    [
      run-len max-run prim <
      [ max-run ]
      [ run-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ 0 1 0 run-helper ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: run-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { max-run run-len i xs }` in `run-helper` gives `max-run` the value the stack effect calls `xs` (Seq Int), `run-len` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `run-len` (Int), `xs` the value the stack effect calls `max-run` (Int).
actual: run-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i run-len max-run }` in `run-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 34, column 3
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
: check-pairs
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { i target xs } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      [ 
        xs prim seq-int.len prim <
        [
          xs i prim seq-int.at xs prim seq-int.at prim + target prim =
          [
            true
          ]
          [
            prim seq-int.at 1 prim + check-inner
          ]
          if
        ]
        [ false ]
        if
      ] call
      [
        i 1 prim + xs target check-pairs
      ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 check-pairs;

```
On the example, the run failed:
code: firth.name.unresolved
word: check-pairs
at: line 15, column 38
message: `check-inner` is not a defined word, primitive or local.
actual: check-inner
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-unique
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many count:Int^many -- ρ result:Int^many)
  locals { count j i xs } {
    i xs prim seq-int.len prim <
    [
      j xs prim seq-int.len prim <
      [
        xs i prim seq-int.at xs j prim seq-int.at prim =
        [ j 1 prim + i xs count count-unique ]
        [ 
          j 1 prim + i xs count count-unique
        ]
        if
      ]
      [
        i 1 prim + i 1 prim + xs count 1 prim + count-unique
      ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 0 count-unique;

```
On the example, the run failed:
code: firth.name.locals-order
word: count-unique
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { count j i xs }` in `count-unique` gives `count` the value the stack effect calls `xs` (Seq Int), `j` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `j` (Int), `xs` the value the stack effect calls `count` (Int).
actual: count-unique
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i j count }` in `count-unique`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result j i ys xs } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        i 1 prim + j xs ys result xs i prim seq-int.at prim seq-int.push merge-helper
      ]
      [
        i j 1 prim + xs ys result ys j prim seq-int.at prim seq-int.push merge-helper
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + j xs ys result xs i prim seq-int.at prim seq-int.push merge-helper
      ]
      [
        j ys prim seq-int.len prim <
        [
          i j 1 prim + xs ys result ys j prim seq-int.at prim seq-int.push merge-helper
        ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  0 0 prim seq-int.empty merge-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: merge-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result j i ys xs }` in `merge-helper` gives `result` the value the stack effect calls `xs` (Seq Int), `j` the value the stack effect calls `ys` (Seq Int), `i` the value named `i` (Int), `ys` the value the stack effect calls `j` (Int), `xs` the value the stack effect calls `result` (Seq Int).
actual: merge-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys i j result }` in `merge-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result swap prim seq-int.push
      locals { new-result } {
        n 10 prim div new-result digits-helper
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  prim seq-int.empty digits-helper;

```
On the example, the run failed:
code: firth.name.locals-order
word: digits-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result n }` in `digits-helper` gives `result` the value the stack effect calls `n` (Int), `n` the value the stack effect calls `result` (Seq Int).
actual: digits-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { n result }` in `digits-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { divisor candidate } {
    divisor divisor prim * candidate prim <
    [ true ]
    [
      candidate divisor prim mod 0 prim =
      [ false ]
      [ candidate divisor 1 prim + is-prime ]
      if
    ]
    if
  };

: collect-primes
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim < i 2 prim <
    prim or prim not
    [
      i 2 is-prime
      [ i 1 prim + i result i prim seq-int.push collect-primes ]
      [ i 1 prim + i result collect-primes ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  2 prim seq-int.empty collect-primes;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: is-prime
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { divisor candidate }` in `is-prime` gives `divisor` the value the stack effect calls `candidate` (Int), `candidate` the value the stack effect calls `divisor` (Int).
actual: is-prime
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { candidate divisor }` in `is-prime`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.locals-order
word: collect-primes
at: line 17, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result i n }` in `collect-primes` gives `result` the value the stack effect calls `n` (Int), `i` the value named `i` (Int), `n` the value the stack effect calls `result` (Seq Int).
actual: collect-primes
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { n i result }` in `collect-primes`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `is-prime`, which has an error of its own, keeps its stack effect.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { counts i k xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        val counts prim seq-int.at
        counts val swap 1 prim + prim seq-int.set
        locals { new-counts } {
          i 1 prim + xs k new-counts histogram-helper
        }
      }
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k } {
    prim seq-int.empty
    0
    [ k 1 prim + dup prim seq-int.push swap 1 prim + dup k prim < [ ] [ drop ] if ]
    call
    locals { init-counts } {
      0 xs k init-counts histogram-helper
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: histogram-helper
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { counts i k xs }` in `histogram-helper` gives `counts` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `k` (Int), `k` the value the stack effect calls `i` (Int), `xs` the value the stack effect calls `counts` (Seq Int).
actual: histogram-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k i counts }` in `histogram-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 27, column 9
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ result:Seq Int^many x:Int^many -- ρ sorted:Seq Int^many)
  locals { x result } {
    0
    [ 
      result prim seq-int.len prim <
      result swap prim seq-int.at x prim <
      prim and
      [ 
        result swap prim seq-int.at
        1 prim +
      ]
      [ false ]
      if
    ]
    call
    locals { idx } {
      result idx x prim seq-int.set
    }
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result insert-sorted
      locals { new-result } {
        i 1 prim + xs new-result sort-helper
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  0 prim seq-int.empty sort-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: insert-sorted
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x result }` in `insert-sorted` gives `x` the value the stack effect calls `result` (Seq Int), `result` the value the stack effect calls `x` (Int).
actual: insert-sorted
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result x }` in `insert-sorted`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.name.locals-order
word: sort-helper
at: line 24, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result i xs }` in `sort-helper` gives `result` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `result` (Seq Int).
actual: sort-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i result }` in `sort-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `insert-sorted`, which has an error of its own, keeps its stack effect.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: apply-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { txs i rejected balance } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim <
        [ 
          i 1 prim + txs balance rejected 1 prim + apply-transactions
        ]
        [
          i 1 prim + txs balance tx prim + rejected apply-transactions
        ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 apply-transactions;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: apply-transactions
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { txs i rejected balance }` in `apply-transactions` gives `txs` the value the stack effect calls `balance` (Int), `i` the value the stack effect calls `rejected` (Int), `rejected` the value the stack effect calls `i` (Int), `balance` the value the stack effect calls `txs` (Seq Int).
actual: apply-transactions
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { balance rejected i txs }` in `apply-transactions`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 24, column 5
message: `apply-transactions` in `main` needs Int Int Int Seq Int on top of the stack, but the stack before it is ρ Int Seq Int Int. `main` calls `apply-transactions`, which has an error of its own; this report assumes `apply-transactions` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Int Seq Int Int
hint: `apply-transactions` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { reasons allocated i whole qtys items stock } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim < qty r prim = prim or
            [
              qty r prim <
              [
                stock item qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push
                locals { new-stock new-allocated new-reasons } {
                  i 1 prim + new-stock items qtys whole new-allocated new-reasons allocate-one
                }
              ]
              [
                stock item 0 prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push
                locals { new-stock new-allocated new-reasons } {
                  i 1 prim + new-stock items qtys whole new-allocated new-reasons allocate-one
                }
              ]
              if
            ]
            [
              whole i prim seq-bool.at
              [
                allocated 0 prim seq-int.push reasons 3 prim seq-int.push
                locals { new-allocated new-reasons } {
                  i 1 prim + stock items qtys whole new-allocated new-reasons allocate-one
                }
              ]
              [
                stock item r prim seq-int.set allocated r prim seq-int.push reasons 1 prim seq-int.push
                locals { new-stock new-allocated new-reasons } {
                  i 1 prim + new-stock items qtys whole new-allocated new-reasons allocate-one
                }
              ]
              if
            ]
            if
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  0 prim seq-int.empty prim seq-int.empty allocate-one;

```
On the example, the run failed:
code: firth.name.locals-order
word: allocate-one
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { reasons allocated i whole qtys items stock }` in `allocate-one` gives `reasons` the value the stack effect calls `stock` (Seq Int), `allocated` the value the stack effect calls `items` (Seq Int), `i` the value the stack effect calls `qtys` (Seq Int), `whole` the value named `whole` (Seq Bool), `qtys` the value the stack effect calls `i` (Int), `items` the value the stack effect calls `allocated` (Seq Int), `stock` the value the stack effect calls `reasons` (Seq Int).
actual: allocate-one
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { stock items qtys whole i allocated reasons }` in `allocate-one`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.
