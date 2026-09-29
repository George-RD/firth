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
  locals { i xs acc } {
    i xs prim seq-int.len prim < [
      acc i xs prim seq-int.at prim +
      i 1 prim +
      sum-loop
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs acc }` in `sum-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `acc` the value named `acc` (Int).
actual: sum-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i acc }` in `sum-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-max:Int^many -- ρ result:Int^many)
  locals { i xs current-max } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at current-max prim < [
        i xs prim seq-int.at
      ] [
        current-max
      ] if
      i 1 prim +
      max-loop
    ] [
      current-max
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 1 xs 0 xs prim seq-int.at max-loop
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs current-max }` in `max-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `current-max` the value named `current-max` (Int).
actual: max-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i current-max }` in `max-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { i xs k count } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at k prim < [
        count 1 prim +
      ] [
        count
      ] if
      i 1 prim +
      count-loop
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs k count }` in `count-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int), `k` the value the stack effect calls `i` (Int), `count` the value named `count` (Int).
actual: count-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k i count }` in `count-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at x prim = [
        i
      ] [
        i 1 prim +
        index-loop
      ] if
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs x }` in `index-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `x` (Int), `x` the value the stack effect calls `i` (Int).
actual: index-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs x i }` in `index-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim < [
      result i xs prim seq-int.at prim seq-int.push
      i 1 prim -
      reverse-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result }` in `reverse-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `result` the value named `result` (Seq Int).
actual: reverse-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i result }` in `reverse-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { i xs sum result } {
    i xs prim seq-int.len prim < [
      sum i xs prim seq-int.at prim +
      result swap prim seq-int.push
      i 1 prim +
      prefix-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs sum result }` in `prefix-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `sum` the value named `sum` (Int), `result` the value named `result` (Seq Int).
actual: prefix-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i sum result }` in `prefix-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at locals { val } {
        val 0 prim < [
          result
        ] [
          result val prim seq-int.push
        ] if
      }
      i 1 prim +
      keep-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs result }` in `keep-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `result` the value named `result` (Seq Int).
actual: keep-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i result }` in `keep-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    i xs prim seq-int.len 1 prim - prim < [
      i xs prim seq-int.at
      i 1 prim + xs prim seq-int.at prim <
      [
        i 1 prim +
        sorted-loop
      ] [
        i xs prim seq-int.at
        i 1 prim + xs prim seq-int.at prim =
        [
          i 1 prim +
          sorted-loop
        ] [
          false
        ] if
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs prim seq-int.len 1 prim < [
    true
  ] [
    xs 0 sorted-loop
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 27, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { i xs ys sum } {
    i xs prim seq-int.len prim < [
      sum i xs prim seq-int.at i ys prim seq-int.at prim * prim +
      i 1 prim +
      dot-loop
    ] [
      sum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs ys sum }` in `dot-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int), `ys` the value the stack effect calls `i` (Int), `sum` the value named `sum` (Int).
actual: dot-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys i sum }` in `dot-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { i flags } {
    i flags prim seq-bool.len prim < [
      i flags prim seq-bool.at [
        i 1 prim +
        all-loop
      ] [
        false
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  flags prim seq-bool.len 0 prim = [
    true
  ] [
    flags 0 all-loop
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 18, column 3
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { i xs current-val current-len max-len } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at locals { val } {
        val current-val prim = [
          current-len 1 prim +
          current-len 1 prim + max-len prim < [
            max-len
          ] [
            current-len 1 prim +
          ] if
          i 1 prim +
          run-helper
        ] [
          current-len max-len prim < [
            max-len
          ] [
            current-len
          ] if
          locals { new-max } {
            val 1 i 1 prim + new-max run-helper
          }
        ] if
      }
    ] [
      current-len max-len prim < [
        max-len
      ] [
        current-len
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim = [
    0
  ] [
    xs 1 xs prim seq-int.at 1 0 run-helper
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 37, column 3
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
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { i xs target j } {
    j xs prim seq-int.len prim < [
      i j prim = [
        j 1 prim +
        inner-loop
      ] [
        i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [
          true
        ] [
          j 1 prim +
          inner-loop
        ] if
      ] if
    ] [
      false
    ] if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim < [
      xs target i 0 inner-loop [
        true
      ] [
        i 1 prim +
        outer-loop
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 outer-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs target j }` in `inner-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `target` (Int), `target` the value the stack effect calls `i` (Int), `j` the value named `j` (Int); `locals { i xs target }` in `outer-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `target` (Int), `target` the value the stack effect calls `i` (Int).
actual: inner-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs target i j }` in `inner-loop`, and `locals { xs target i }` in `outer-loop`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-seen
  (forall ρ; ρ xs:Seq Int^many val:Int^many i:Int^many -- ρ seen:Bool^many)
  locals { i xs val } {
    i val prim < [
      i xs prim seq-int.at val prim = [
        true
      ] [
        i 1 prim +
        check-seen
      ] if
    ] [
      false
    ] if
  };

: count-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { i xs count } {
    i xs prim seq-int.len prim < [
      xs i xs prim seq-int.at 0 check-seen [
        count
      ] [
        count 1 prim +
      ] if
      i 1 prim +
      count-helper
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  xs 0 0 count-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 34, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i xs ys j result } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        i xs prim seq-int.at j ys prim seq-int.at prim < [
          result i xs prim seq-int.at prim seq-int.push
          i 1 prim +
          merge-loop
        ] [
          result j ys prim seq-int.at prim seq-int.push
          j 1 prim +
          merge-loop
        ] if
      ] [
        result i xs prim seq-int.at prim seq-int.push
        i 1 prim +
        merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        result j ys prim seq-int.at prim seq-int.push
        j 1 prim +
        merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i xs ys j result }` in `merge-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int), `ys` the value the stack effect calls `i` (Int), `j` the value named `j` (Int), `result` the value named `result` (Seq Int).
actual: merge-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys i j result }` in `merge-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    n 0 prim = [
      result
    ] [
      result n 10 prim mod prim seq-int.push
      n 10 prim div result digits-loop
    ] if
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many output:Seq Int^many -- ρ digits:Seq Int^many)
  locals { i result output } {
    i 0 prim < [
      output i result prim seq-int.at prim seq-int.push
      i 1 prim -
      reverse-loop
    ] [
      output
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim = [
    prim seq-int.empty 0 prim seq-int.push
  ] [
    n prim seq-int.empty digits-loop
    locals { result } {
      result result prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
    }
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 26, column 3
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
: is-divisible
  (forall ρ; ρ n:Int^many d:Int^many -- ρ divisible:Bool^many)
  n d prim mod 0 prim =;

: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { d n } {
    d d prim * n prim < [
      n d is-divisible [
        false
      ] [
        d 1 prim +
        is-prime-check
      ] if
    ] [
      true
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  n 2 prim < [
    false
  ] [
    n 2 is-prime-check
  ] if;

: primes-loop
  (forall ρ; ρ limit:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n limit result } {
    n limit prim < [
      n is-prime [
        result n prim seq-int.push
        n 1 prim +
        primes-loop
      ] [
        n 1 prim +
        primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  n 2 prim < [
    prim seq-int.empty
  ] [
    n 2 prim seq-int.empty primes-loop
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n d } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result } {
    i k prim < [
      result 0 prim seq-int.push
      i 1 prim +
      init-counts
    ] [
      result
    ] if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at locals { val } {
        counts val prim seq-int.at 1 prim +
        val counts prim seq-int.set
        i 1 prim +
        histogram-loop
      }
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-counts
    xs 0 histogram-loop
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i k result }` in `init-counts` gives `i` the value the stack effect calls `k` (Int), `k` the value the stack effect calls `i` (Int), `result` the value named `result` (Seq Int); `locals { i xs counts }` in `histogram-loop` gives `i` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `i` (Int), `counts` the value named `counts` (Seq Int).
actual: init-counts
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { k i result }` in `init-counts`, and `locals { xs i counts }` in `histogram-loop`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { i result val } {
    i result prim seq-int.len prim < [
      i result prim seq-int.at val prim < [
        result val i prim seq-int.set
        i 1 prim +
        insert-loop
      ] [
        i 1 prim +
        insert-loop
      ] if
    ] [
      result val prim seq-int.push
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at result 0 insert-loop
      i 1 prim +
      sort-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 32, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { i balance txs rejected } {
    i txs prim seq-int.len prim < [
      balance i txs prim seq-int.at prim + 0 prim < [
        rejected 1 prim +
        i 1 prim +
        ledger-loop
      ] [
        balance i txs prim seq-int.at prim +
        i 1 prim +
        ledger-loop
      ] if
    ] [
      rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-loop };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { i balance txs rejected }` in `ledger-loop` gives `i` the value the stack effect calls `balance` (Int), `balance` the value the stack effect calls `txs` (Seq Int), `txs` the value the stack effect calls `i` (Int), `rejected` the value named `rejected` (Int).
actual: ledger-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { balance txs i rejected }` in `ledger-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order:Int^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many)
  locals { order stock items qtys whole alloc reasons } {
    order items prim seq-int.len prim < [
      order items prim seq-int.at locals { item-idx } {
        order qtys prim seq-int.at locals { qty } {
          order whole prim seq-bool.at locals { whole-flag } {
            item-idx stock prim seq-int.at locals { avail } {
              qty avail prim < [
                alloc qty prim seq-int.push
                reasons 0 prim seq-int.push
                stock item-idx avail qty prim - prim seq-int.set
              ] [
                avail 0 prim = [
                  alloc 0 prim seq-int.push
                  reasons 2 prim seq-int.push
                ] [
                  whole-flag [
                    alloc 0 prim seq-int.push
                    reasons 3 prim seq-int.push
                  ] [
                    alloc avail prim seq-int.push
                    reasons 1 prim seq-int.push
                    stock item-idx 0 prim seq-int.set
                  ] if
                ] if
              ] if
              order 1 prim +
              allocate-loop
            }
          }
        }
      }
    ] [
      reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { order stock items qtys whole alloc reasons }` in `allocate-loop` gives `order` the value the stack effect calls `stock` (Seq Int), `stock` the value the stack effect calls `items` (Seq Int), `items` the value the stack effect calls `qtys` (Seq Int), `qtys` the value the stack effect calls `whole` (Seq Bool), `whole` the value the stack effect calls `order` (Int), `alloc` the value named `alloc` (Seq Int), `reasons` the value named `reasons` (Seq Int).
actual: allocate-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { stock items qtys whole order alloc reasons }` in `allocate-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.
