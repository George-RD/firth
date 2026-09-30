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
  locals { xs } { 0 0 xs call sum-helper };

: sum-helper
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      1 i prim +
      xs
      call sum-helper
    ]
    [ sum ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 3, column 26
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.expected-quotation
word: sum-helper
at: line 13, column 7
message: `call` in `sum-helper` needs a quotation, but the stack before it is .. Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

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
    xs 0 prim seq-int.at
    1
    xs
    call max-helper
  };

: max-helper
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max
      locals { elem prev-max } {
        prev-max elem prim <
        [ elem ]
        [ prev-max ]
        if
      }
      i 1 prim +
      xs
      call max-helper
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.expected-quotation
word: max-helper
at: line 24, column 7
message: `call` in `max-helper` needs a quotation, but the stack before it is .. Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0
    0
    xs
    k
    call count-loop
  };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i xs k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem k prim <
        [ count 1 prim + ]
        [ count ]
        if
      }
      i 1 prim +
      xs
      k
      call count-loop
    ]
    [ count ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 8, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Seq Int Int.
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.elaboration.untracked-local
word: count-loop
at: line 15, column 5
message: The local `count` is used after `call` on line 26 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0
    xs
    x
    call index-loop
  };

: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ final-index:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [
        i
      ]
      [
        i 1 prim +
        xs
        x
        call index-loop
      ]
      if
    ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Seq Int Int.
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.quotation-compose-mismatch
word: index-loop
at: line 19, column 7
message: `compose` in `index-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Int ] [ .. -- .. Int Seq Int Int ] [ .. Int Seq Int [ .. Int Seq Int -- .. Int Seq Int Int ] -- .. Int ]. Expected Int, found [ .. Int Seq Int -- .. Int Seq Int Int ].
expected: Int
actual: [ .. Int Seq Int -- .. Int Seq Int Int ]

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
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    call reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    prim not
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      xs
      call reverse-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 17, column 14
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t17
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 16. With that edit, the next error in `reverse-loop` is at line 19, column 7.

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
    prim seq-int.empty
    0
    0
    xs
    call prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ prefix-sums:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        new-sum
        result prim seq-int.push
        new-sum
        i 1 prim +
        xs
        call prefix-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 8, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.elaboration.untracked-local
word: prefix-loop
at: line 15, column 5
message: The local `xs` is used after `call` on line 23 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    prim seq-int.empty
    0
    xs
    call filter-loop
  };

: filter-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        0 elem prim <
        [
          elem
          result prim seq-int.push
        ]
        [ result ]
        if
      }
      i 1 prim +
      xs
      call filter-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.elaboration.untracked-local
word: filter-loop
at: line 14, column 5
message: The local `result` is used after `call` on line 27 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    1
    0
    xs
    call is-sorted-loop
  };

: is-sorted-loop
  (forall ρ; ρ is-sorted:Bool^many i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { is-sorted i xs } {
    is-sorted prim not
    [
      0
    ]
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        xs i prim seq-int.at
        xs i 1 prim + prim seq-int.at
        prim <
        prim not
        [
          1
          i 1 prim +
          xs
          call is-sorted-loop
        ]
        [ 0 ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.quotation-compose-mismatch
word: is-sorted-loop
at: line 24, column 9
message: `compose` in `is-sorted-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Int Seq Int ] [ .. Int [ .. Int Int -- .. Bool Int Seq Int ] -- .. Bool ]. Expected Seq Int, found [ .. Int Int -- .. Bool Int Seq Int ].
expected: Seq Int
actual: [ .. Int Int -- .. Bool Int Seq Int ]

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0
    0
    xs
    ys
    call dot-product
  };

: dot-product
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      xs
      ys
      call dot-product
    ]
    [ sum ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 8, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Seq Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.expected-quotation
word: dot-product
at: line 23, column 7
message: `call` in `dot-product` needs a quotation, but the stack before it is .. Int Int Seq Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    1
    0
    flags
    call all-true-loop
  };

: all-true-loop
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result i flags } {
    result prim not
    [
      0
    ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
        [
          1
          i 1 prim +
          flags
          call all-true-loop
        ]
        [ 0 ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Seq Bool.
expected: [ .. -- .. ]
actual: Seq Bool
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.quotation-compose-mismatch
word: all-true-loop
at: line 21, column 9
message: `compose` in `all-true-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Int Seq Bool ] [ .. Int [ .. Int Int -- .. Bool Int Seq Bool ] -- .. Bool ]. Expected Seq Bool, found [ .. Int Int -- .. Bool Int Seq Bool ].
expected: Seq Bool
actual: [ .. Int Int -- .. Bool Int Seq Bool ]

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
    xs prim seq-int.len
    [
      0
    ]
    [
      0
      1
      0
      xs
      call longest-run-loop
    ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim =
      [
        current-run 1 prim +
        i 1 prim +
        xs
        call longest-run-loop
      ]
      [
        max-run current-run
        locals { m r } {
          m r prim <
          [ r ]
          [ m ]
          if
        }
        1
        i 1 prim +
        xs
        call longest-run-loop
      ]
      if
    ]
    [
      max-run current-run
      locals { m r } {
        m r prim <
        [ r ]
        [ m ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-compose-mismatch
word: main
at: line 8, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int [ .. -- .. Int ] [ .. -- .. Seq Int ] [ .. [ .. Int Int Int -- .. Int Int Int Seq Int ] -- .. Int ]. Expected Seq Int, found [ .. Int Int Int -- .. Int Int Int Seq Int ]. `main` calls `longest-run-loop`, which has an error of its own; this report assumes `longest-run-loop` keeps its stack effect.
expected: Seq Int
actual: [ .. Int Int Int -- .. Int Int Int Seq Int ]

error 2 of 2
code: firth.type.quotation-compose-mismatch
word: longest-run-loop
at: line 26, column 7
message: `compose` in `longest-run-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Seq Int Int Int ?t26 Bool [ .. -- .. Int Int Seq Int ] [ .. Int Int [ .. Int Int -- .. Int Int Int Seq Int ] -- .. Int ]. Expected Seq Int, found [ .. Int Int -- .. Int Int Int Seq Int ].
expected: Seq Int
actual: [ .. Int Int -- .. Int Int Int Seq Int ]

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0
    xs
    target
    call pair-sum-loop
  };

: pair-sum-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      target
      i
      call check-pairs
    ]
    [ 0 ]
    if
  };

: check-pairs
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j xs target i } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs j prim seq-int.at
      prim +
      target prim =
      [
        1
      ]
      [
        j 1 prim +
        xs
        target
        i
        call check-pairs
      ]
      if
    ]
    [
      i 1 prim +
      xs
      target
      call pair-sum-loop
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Seq Int Int.
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 3
code: firth.type.expected-quotation
word: pair-sum-loop
at: line 19, column 7
message: `call` in `pair-sum-loop` needs a quotation, but the stack before it is .. Int ?t25 ?t24 Int.
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 3 of 3
code: firth.type.quotation-compose-mismatch
word: check-pairs
at: line 37, column 7
message: `compose` in `check-pairs` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Int ] [ .. -- .. Int Seq Int Int Int ] [ .. Int Seq Int Int [ .. Int Seq Int Int -- .. Int Seq Int Int Int ] -- .. Bool ]. Expected Int, found [ .. Int Seq Int Int -- .. Int Seq Int Int Int ].
expected: Int
actual: [ .. Int Seq Int Int -- .. Int Seq Int Int Int ]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0
    0
    xs
    call count-distinct-main
  };

: count-distinct-main
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        0
        xs
        elem
        i
        call check-if-new
      }
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      i 1 prim +
      xs
      call count-distinct-main
    ]
    [ count ]
    if
  };

: check-if-new
  (forall ρ; ρ j:Int^many xs:Seq Int^many elem:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j xs elem i } {
    j i prim <
    [
      xs j prim seq-int.at elem prim =
      [
        1
      ]
      [
        j 1 prim +
        xs
        elem
        i
        call check-if-new
      ]
      if
    ]
    [ 0 ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 3
code: firth.elaboration.untracked-local
word: count-distinct-main
at: line 23, column 7
message: The local `count` is used after `call` on line 21 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

error 3 of 3
code: firth.type.branch-mismatch
word: check-if-new
at: line 54, column 7
message: The two branches of `if` in `check-if-new` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: The two branches leave different parts of the caller's stack (ρ): one of them consumes values it should keep, or keeps values it should consume. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0
    0
    xs
    ys
    call merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          xs i prim seq-int.at
          result prim seq-int.push
          i 1 prim +
          j
        ]
        [
          ys j prim seq-int.at
          result prim seq-int.push
          i
          j 1 prim +
        ]
        if
        xs
        ys
        call merge-loop
      ]
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        j
        xs
        ys
        call merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at
        result prim seq-int.push
        i
        j 1 prim +
        xs
        ys
        call merge-loop
      ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 9, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int Int Seq Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 24, column 18
message: `prim seq-int.push` in `merge-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t138 Int ?t139
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 23. With that edit, the next error in `merge-loop` is at line 29, column 18.

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
    prim seq-int.empty
    n
    call extract-digits-reverse
    call reverse-digits
  };

: extract-digits-reverse
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      call extract-digits-reverse
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    call reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    prim not
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      xs
      call reverse-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.expected-quotation
word: main
at: line 6, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int.
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 4
code: firth.type.primitive-input-mismatch
word: extract-digits-reverse
at: line 17, column 14
message: `prim seq-int.push` in `extract-digits-reverse` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result` on line 16. With that edit, the next error in `extract-digits-reverse` is at line 18, column 7.

error 3 of 4
code: firth.type.expected-quotation
word: reverse-digits
at: line 30, column 5
message: `call` in `reverse-digits` needs a quotation, but the stack before it is ρ Seq Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 4 of 4
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 40, column 14
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t17
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 39. With that edit, the next error in `reverse-loop` is at line 42, column 7.

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
    prim seq-int.empty
    2
    n
    call find-primes-loop
  };

: find-primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <
    [
      i
      call is-prime
      [
        i
        result prim seq-int.push
      ]
      [ result ]
      if
      i 1 prim +
      n
      call find-primes-loop
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim <
    [
      0
    ]
    [
      num 2 prim =
      [
        1
      ]
      [
        num 2 prim mod 0 prim =
        [
          0
        ]
        [
          2
          num
          call check-divisors
        ]
        if
      ]
      if
    ]
    if
  };

: check-divisors
  (forall ρ; ρ i:Int^many num:Int^many -- ρ prime:Bool^many)
  locals { i num } {
    i i prim * num prim <
    [
      num i prim mod 0 prim =
      [
        0
      ]
      [
        i 2 prim +
        num
        call check-divisors
      ]
      if
    ]
    [ 1 ]
    if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int Int.
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 4
code: firth.elaboration.untracked-local
word: find-primes-loop
at: line 17, column 7
message: The local `i` is used after `call` on line 16 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

error 3 of 4
code: firth.type.quotation-compose-mismatch
word: is-prime
at: line 48, column 9
message: `compose` in `is-prime` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Int ] [ .. -- .. Int ] [ .. [ .. Int -- .. Int Int ] -- .. Bool ]. Expected Int, found [ .. Int -- .. Int Int ]. `is-prime` calls `check-divisors`, which has an error of its own; this report assumes `check-divisors` keeps its stack effect.
expected: Int
actual: [ .. Int -- .. Int Int ]

error 4 of 4
code: firth.type.quotation-compose-mismatch
word: check-divisors
at: line 69, column 7
message: `compose` in `check-divisors` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Int ] [ .. -- .. Int Int ] [ .. Int [ .. Int -- .. Int Int ] -- .. Bool ]. Expected Int, found [ .. Int -- .. Int Int ].
expected: Int
actual: [ .. Int -- .. Int Int ]

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
    prim seq-int.empty
    0
    k
    xs
    call init-and-fill-histogram
  };

: init-and-fill-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many xs:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { result i k xs } {
    i k prim <
    [
      0
      result prim seq-int.push
      i 1 prim +
      k
      xs
      call init-and-fill-histogram
    ]
    [
      result
      0
      xs
      k
      call fill-histogram
    ]
    if
  };

: fill-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { result i xs k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        result val prim seq-int.at
        1 prim +
        result val prim seq-int.set
      }
      i 1 prim +
      xs
      k
      call fill-histogram
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-quotation
word: main
at: line 8, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: init-and-fill-histogram
at: line 17, column 14
message: `prim seq-int.push` in `init-and-fill-histogram` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t36 ?t35 ?t34 Int ?t37
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 3 of 3
code: firth.elaboration.untracked-local
word: fill-histogram
at: line 37, column 5
message: The local `result` is used after `call` on line 47 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    call insertion-sort-loop
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result
      0
      call insert-into-sorted
      i 1 prim +
      xs
      call insertion-sort-loop
    ]
    [ result ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ elem:Int^many result:Seq Int^many pos:Int^many -- ρ inserted:Seq Int^many)
  locals { elem result pos } {
    pos result prim seq-int.len prim <
    [
      result pos prim seq-int.at elem prim <
      [
        elem
        result pos prim seq-int.set
      ]
      [
        pos 1 prim +
        call insert-into-sorted
      ]
      if
    ]
    [
      elem
      result prim seq-int.push
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-quotation
word: main
at: line 7, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 3
code: firth.elaboration.untracked-local
word: insertion-sort-loop
at: line 19, column 7
message: The local `i` is used after `call` on line 18 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

error 3 of 3
code: firth.type.primitive-input-mismatch
word: insert-into-sorted
at: line 35, column 20
message: `prim seq-int.set` in `insert-into-sorted` takes the sequence (Seq Int), the index (Int) and the new value (Int), bottom to top, but here it gets, bottom to top, `elem` (Int), `result` (Seq Int) and `pos` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `result` is for the sequence. Of the values of one type, `elem` and `pos` are for the index and the new value, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    0
    txs
    call ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim <
        [
          balance
          rejected 1 prim +
        ]
        [
          balance tx prim +
          rejected
        ]
        if
      }
      i 1 prim +
      txs
      call ledger-loop
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 8, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Int Int Int Seq Int.
expected: [ .. -- .. ]
actual: Seq Int
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.elaboration.untracked-local
word: ledger-loop
at: line 15, column 5
message: The local `balance` is used after `call` on line 31 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    items
    qtys
    whole
    call allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-list:Seq Int^many reason-list:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { available } {
          qtys j prim seq-int.at available prim <
          [
            available 0 prim =
            [
              0
              2
            ]
            [
              whole j prim seq-bool.at
              [
                0
                3
              ]
              [
                available
                1
              ]
              if
            ]
            if
          ]
          [
            qtys j prim seq-int.at
            0
          ]
          if
          locals { alloc-qty reason } {
            alloc-qty
            allocated prim seq-int.push
            reason
            reasons prim seq-int.push
            available alloc-qty prim -
            stock item prim seq-int.set
            j 1 prim +
            items
            qtys
            whole
            call allocate-loop
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-quotation
word: main
at: line 11, column 5
message: `call` in `main` needs a quotation, but the stack before it is ρ Seq Int Seq Int Seq Int Int Seq Int Seq Int Seq Bool.
expected: [ .. -- .. ]
actual: Seq Bool
hint: Put a `[ ... ]` quotation where the operation expects one.

error 2 of 2
code: firth.elaboration.untracked-local
word: allocate-loop
at: line 22, column 18
message: The local `available` is used after `call` on line 60 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.
