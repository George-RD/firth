Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs idx acc } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at acc prim +
      xs idx 1 prim + sum-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 swap sum-loop;

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs idx acc }` in `sum-loop` gives `xs` the value the stack effect calls `acc` (Int), `idx` the value named `idx` (Int), `acc` the value the stack effect calls `xs` (Seq Int).
actual: sum-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { acc idx xs }` in `sum-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ max:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs idx max } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at max prim <
      [ xs idx 1 prim + max max-loop ]
      [ xs idx 1 prim + xs idx prim seq-int.at max-loop ]
      if ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at 0 swap max-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 15, column 3
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
: count-loop
  (forall ρ; ρ cnt:Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs k idx cnt } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at k prim <
      [ cnt 1 prim + xs k idx 1 prim + count-loop ]
      [ cnt xs k idx 1 prim + count-loop ]
      if ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 0 swap count-loop;

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs k idx cnt }` in `count-loop` gives `xs` the value the stack effect calls `cnt` (Int), `k` the value the stack effect calls `idx` (Int), `idx` the value the stack effect calls `k` (Int), `cnt` the value the stack effect calls `xs` (Seq Int).
actual: count-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { cnt idx k xs }` in `count-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ x:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs idx x } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at x prim =
      [ idx ]
      [ xs x idx 1 prim + find-loop ]
      if ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 swap find-loop;

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs idx x }` in `find-loop` gives `xs` the value the stack effect calls `x` (Int), `idx` the value named `idx` (Int), `x` the value the stack effect calls `xs` (Seq Int).
actual: find-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { x idx xs }` in `find-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx acc } {
    idx 0 prim <
    [ xs idx prim seq-int.at acc prim seq-int.push
      xs idx 1 prim - reverse-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty xs prim seq-int.len 1 prim - swap reverse-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 13, column 22
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
: prefix-loop
  (forall ρ; ρ acc:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx sum acc } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at sum prim +
      acc prim seq-int.push
      xs idx 1 prim + prefix-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 xs prefix-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 14, column 26
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx acc } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at 0 prim <
      [ acc xs idx prim seq-int.at prim seq-int.push xs idx 1 prim + keep-loop ]
      [ acc xs idx 1 prim + keep-loop ]
      if ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 xs keep-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 15, column 24
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim <
    [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
      [ xs idx 1 prim + check-sorted ]
      [ false ]
      if ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 xs check-sorted;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 15, column 5
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
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { ys xs idx sum } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim *
      sum prim +
      xs ys idx 1 prim + dot-loop ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 xs ys dot-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 14, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags idx } {
    idx flags prim seq-bool.len prim <
    [ flags idx prim seq-bool.at
      [ flags idx 1 prim + all-loop ]
      [ false ]
      if ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 flags all-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 15, column 5
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
: run-loop
  (forall ρ; ρ maxlen:Int^many runlen:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs idx runlen maxlen } {
    idx xs prim seq-int.len prim <
    [ idx xs prim seq-int.len 1 prim - prim <
      [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim =
        [ xs idx 1 prim + runlen 1 prim + maxlen run-loop ]
        [ runlen maxlen prim <
          [ xs idx 1 prim + 1 runlen maxlen run-loop ]
          [ xs idx 1 prim + 1 runlen run-loop ]
          if ]
        if ]
      [ runlen maxlen prim < [ runlen ] [ maxlen ] if ]
      if ]
    [ runlen maxlen prim < [ runlen ] [ maxlen ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 1 1 xs run-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 21, column 9
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
: find-pair
  (forall ρ; ρ j:Int^many i:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim +
      target prim =
      [ true ]
      [ xs target i j 1 prim + find-pair ]
      if ]
    [ xs target i 1 prim + i 2 prim + find-pair ]
    if
  };

: check-pair
  (forall ρ; ρ i:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs target i i 1 prim + find-pair ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 xs check-pair;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 25, column 10
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-inner
  (forall ρ; ρ count:Int^many j:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i j count } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim =
      [ xs i j 1 prim + count count-distinct-inner ]
      [ xs i j 1 prim + count 1 prim + count-distinct-inner ]
      if ]
    [ xs i 1 prim + count 1 prim + count-distinct-inner ]
    if
  };

: count-distinct-outer
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i i 1 prim + count count-distinct-inner ]
    [ count 1 prim + ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 xs count-distinct-outer;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 24, column 7
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
  (forall ρ; ρ acc:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { ys xs j i acc } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim <
      [ acc xs i prim seq-int.at prim seq-int.push
        xs ys i 1 prim + j merge-loop ]
      [ acc ys j prim seq-int.at prim seq-int.push
        xs ys i j 1 prim + merge-loop ]
      if ]
    [ i xs prim seq-int.len prim <
      [ acc xs i prim seq-int.at prim seq-int.push
        xs ys i 1 prim + j merge-loop ]
      [ j ys prim seq-int.len prim <
        [ acc ys j prim seq-int.at prim seq-int.push
          xs ys i j 1 prim + merge-loop ]
        [ acc ]
        if ]
      if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 xs ys merge-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 25, column 26
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { n acc } {
    n 0 prim >
    [ n 10 prim mod acc prim seq-int.push
      n 10 prim div acc digits-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n acc }` in `digits-loop` gives `n` the value the stack effect calls `acc` (Seq Int), `acc` the value the stack effect calls `n` (Int).
actual: digits-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { acc n }` in `digits-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [ n d prim mod 0 prim =
      [ false ]
      [ n d 2 prim + is-prime ]
      if ]
    [ true ]
    if
  };

: primes-loop
  (forall ρ; ρ acc:Seq Int^many n:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { limit n acc } {
    n limit prim <
    [ n 2 prim =
      [ acc n prim seq-int.push limit n 1 prim + primes-loop ]
      [ n 2 prim >
        [ n 2 is-prime
          [ acc n prim seq-int.push limit n 1 prim + primes-loop ]
          [ limit n 1 prim + primes-loop ]
          if ]
        [ limit n 1 prim + primes-loop ]
        if ]
      if ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 n primes-loop;

```
On the example, the run failed:
code: firth.name.unresolved
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
: init-histogram
  (forall ρ; ρ acc:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { k acc } {
    k 0 prim >
    [ acc 0 prim seq-int.push k 1 prim - init-histogram ]
    [ acc ]
    if
  };

: histogram-loop
  (forall ρ; ρ idx:Int^many acc:Seq Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { k xs acc idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at
      [ xs idx prim seq-int.at dup acc prim seq-int.at 1 prim + acc prim seq-int.set
        xs k idx 1 prim + histogram-loop ]
      [ xs k idx 1 prim + histogram-loop ]
      if ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  swap prim seq-int.empty k init-histogram xs swap 0 histogram-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 25, column 27
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ val:Int^many i:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i val } {
    i 0 prim >
    [ acc i 1 prim - prim seq-int.at val prim <
      [ acc i acc i 1 prim - prim seq-int.at prim seq-int.set
        acc i 1 prim - val insert-loop ]
      [ acc i val prim seq-int.set ]
      if ]
    [ acc 0 val prim seq-int.set ]
    if
  };

: sort-loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx acc } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at acc prim seq-int.len
      acc xs idx prim seq-int.at insert-loop
      xs idx 1 prim + sort-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty 0 xs sort-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 27, column 24
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
  (forall ρ; ρ rej:Int^many bal:Int^many idx:Int^many txs:Seq Int^many start:Int^many -- ρ result-bal:Int^many result-rej:Int^many)
  locals { start txs idx bal rej } {
    idx txs prim seq-int.len prim <
    [ txs idx prim seq-int.at bal prim +
      dup 0 prim <
      [ drop start txs idx 1 prim + rej 1 prim + ledger-loop ]
      [ start txs idx 1 prim + rej ledger-loop ]
      if ]
    [ bal rej ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap 0 0 swap ledger-loop;

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { start txs idx bal rej }` in `ledger-loop` gives `start` the value the stack effect calls `rej` (Int), `txs` the value the stack effect calls `bal` (Int), `idx` the value named `idx` (Int), `bal` the value the stack effect calls `txs` (Seq Int), `rej` the value the stack effect calls `start` (Int).
actual: ledger-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { rej bal idx txs start }` in `ledger-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-item
  (forall ρ; ρ reason:Int^many allocated:Int^many stock:Seq Int^many idx:Int^many whole:Seq Bool^many qtys:Seq Int^many items:Seq Int^many -- ρ new-stock:Seq Int^many new-allocated:Seq Int^many new-reason:Int^many next-idx:Int^many)
  locals { items qtys whole stock idx allocated reason } {
    idx items prim seq-int.len prim <
    [ items idx prim seq-int.at stock prim seq-int.at
      [ qtys idx prim seq-int.at prim <
        [ stock items idx prim seq-int.at stock items idx prim seq-int.at prim seq-int.at qtys idx prim seq-int.at prim - prim seq-int.set
          allocated qtys idx prim seq-int.at prim seq-int.push 0 idx 1 prim + allocate-item ]
        [ 0 prim =
          [ allocated 0 prim seq-int.push 2 idx 1 prim + allocate-item ]
          [ whole idx prim seq-bool.at
            [ allocated 0 prim seq-int.push 3 idx 1 prim + allocate-item ]
            [ stock items idx prim seq-int.at 0 prim seq-int.set
              allocated stock items idx prim seq-int.at prim seq-int.push 1 idx 1 prim + allocate-item ]
            if ]
          if ]
        if ]
      [ allocated 0 prim seq-int.push 2 idx 1 prim + allocate-item ]
      if ]
    [ stock allocated reason ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty 0 0 stock 0 swap allocate-item;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 26, column 26
message: `stock` is not a defined word, primitive or local.
actual: stock
hint: `stock` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
