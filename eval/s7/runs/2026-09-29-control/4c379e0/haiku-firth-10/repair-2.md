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
  locals { xs } { 0 0 xs sum-helper };

: sum-helper
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs acc i } {
    i xs prim seq-int.len prim = [ acc ] [
      acc xs i prim seq-int.at prim + i 1 prim + xs sum-helper
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs acc i }` in `sum-helper` gives `xs` the value the stack effect calls `i` (Int), `acc` the value named `acc` (Int), `i` the value the stack effect calls `xs` (Seq Int).
actual: sum-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i acc xs }` in `sum-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    xs 0 prim seq-int.at 1 xs max-helper
  };

: max-helper
  (forall ρ; ρ idx:Int^many max:Int^many xs:Seq Int^many -- ρ max:Int^many)
  locals { xs max idx } {
    idx xs prim seq-int.len prim = [ max ] [
      xs idx prim seq-int.at locals { val } {
        max val prim < [ val ] [ max ] if locals { newmax } {
          idx 1 prim + newmax xs max-helper
        }
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 9, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs max idx }` in `max-helper` gives `xs` the value the stack effect calls `idx` (Int), `max` the value named `max` (Int), `idx` the value the stack effect calls `xs` (Seq Int).
actual: max-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { idx max xs }` in `max-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } { 0 0 xs k count-below-helper };

: count-below-helper
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { i count xs k } {
    i xs prim seq-int.len prim = [ count ] [
      xs i prim seq-int.at locals { val } {
        val k prim < [ count 1 prim + ] [ count ] if
        i 1 prim + swap xs k count-below-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs }` in `main` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } { 0 xs x index-of-helper };

: index-of-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ idx:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim = [ 0 1 prim - ] [
      xs i prim seq-int.at x prim = [ i ] [
        i 1 prim + xs x index-of-helper
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x xs }` in `main` gives `x` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `x` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs x }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    xs prim seq-int.len prim seq-int.empty reverse-helper
  };

: reverse-helper
  (forall ρ; ρ i:Int^many res:Seq Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { i res xs } {
    i 0 prim = [ res ] [
      i 1 prim - locals { i' } {
        xs i' prim seq-int.at res prim seq-int.push i' res xs reverse-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.overlong-character
at: line 11, column 28
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    0 0 prim seq-int.empty xs prefix-sums-helper
  };

: prefix-sums-helper
  (forall ρ; ρ i:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i sum result xs } {
    i xs prim seq-int.len prim = [ result ] [
      xs i prim seq-int.at sum prim + locals { newsum } {
        result newsum prim seq-int.push i 1 prim + newsum xs prefix-sums-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 12, column 62
message: `prefix-sums-helper` in `prefix-sums-helper` needs Int Int Seq Int Seq Int on top of the stack, but the stack before it is .. Seq Int Int Seq Int Seq Int Int Int Seq Int.
expected: .. Int Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int Seq Int Int Int Seq Int
hint: The second value from the top is Int but `prefix-sums-helper` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    0 prim seq-int.empty xs keep-positive-helper
  };

: keep-positive-helper
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim = [ result ] [
      xs i prim seq-int.at locals { val } {
        val 0 prim > [ result val prim seq-int.push ] [ result ] if
        i 1 prim + swap xs keep-positive-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 12, column 15
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

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
    xs prim seq-int.len 0 prim = [ true ] [
      xs prim seq-int.len 1 prim = [ true ] [
        1 xs is-sorted-helper
      ] if
    ] if
  };

: is-sorted-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i 1 prim + xs prim seq-int.len prim = [ true ] [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [
        i 1 prim + xs is-sorted-helper
      ] [
        false
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 15, column 64
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    0 flags all-true-helper
  };

: all-true-helper
  (forall ρ; ρ i:Int^many result:Bool^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { i result flags } {
    i flags prim seq-bool.len prim = [ result ] [
      flags i prim seq-bool.at [
        i 1 prim + true flags all-true-helper
      ] [
        false
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 4, column 13
message: `all-true-helper` in `main` needs Int Bool Seq Bool on top of the stack, but the stack before it is ρ Int Seq Bool.
expected: .. Int Bool Seq Bool
actual: ρ Int Seq Bool
hint: `all-true-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
    xs prim seq-int.len 0 prim = [ 0 ] [
      1 1 1 xs longest-run-helper
    ] if
  };

: longest-run-helper
  (forall ρ; ρ idx:Int^many maxlen:Int^many curlen:Int^many xs:Seq Int^many -- ρ maxlen:Int^many)
  locals { idx maxlen curlen xs } {
    idx xs prim seq-int.len prim = [
      curlen maxlen prim > [ curlen ] [ maxlen ] if
    ] [
      xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim = [
        curlen 1 prim +
      ] [
        1
      ] if locals { newcurlen } {
        newcurlen maxlen prim > [ newcurlen ] [ maxlen ] if
        idx 1 prim + swap curlen xs longest-run-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 13, column 21
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } {
    0 xs target has-pair-sum-helper
  };

: has-pair-sum-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim = [ false ] [
      xs i prim seq-int.at locals { xi } {
        i 1 prim + has-pair-sum-check [ true ] [
          i 1 prim + xs target has-pair-sum-helper
        ] if
      }
    ] if
  };

: has-pair-sum-check
  (forall ρ; ρ j:Int^many target:Int^many xs:Seq Int^many xi:Int^many -- ρ found:Bool^many)
  locals { j target xs xi } {
    j xs prim seq-int.len prim = [ false ] [
      xs j prim seq-int.at xi prim + target prim = [ true ] [
        j 1 prim + target xs xi has-pair-sum-check
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { target xs }` in `main` gives `target` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `target` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs target }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

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
    0 xs count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { i xs } {
    i xs prim seq-int.len prim = [ 0 ] [
      xs i prim seq-int.at [ i 1 prim + xs count-distinct-loop ] [
        1 i 1 prim + xs count-distinct-loop prim +
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
at: line 13, column 9
message: `if` in `count-distinct-loop` needs a Bool condition under its two quotations, but the stack before it is .. Int [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: Int
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
  locals { xs ys } {
    0 0 prim seq-int.empty xs ys merge-sorted-helper
  };

: merge-sorted-helper
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { i j result xs ys } {
    i xs prim seq-int.len prim = [
      j ys prim seq-int.len prim = [ result ] [
        result ys j prim seq-int.at prim seq-int.push 
        i j 1 prim + xs ys merge-sorted-helper
      ] if
    ] [
      j ys prim seq-int.len prim = [
        result xs i prim seq-int.at prim seq-int.push 
        i 1 prim + j xs ys merge-sorted-helper
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim <= [
          result xs i prim seq-int.at prim seq-int.push 
          i 1 prim + j xs ys merge-sorted-helper
        ] [
          result ys j prim seq-int.at prim seq-int.push 
          i j 1 prim + xs ys merge-sorted-helper
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 20, column 57
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    n 0 prim = [ { 0 } ] [
      prim seq-int.empty n digits-helper
    ] if
  };

: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    n 0 prim = [ result ] [
      n 10 prim mod result prim seq-int.push n 10 prim div digits-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 13, column 28
message: `prim seq-int.push` in `digits-helper` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t18.
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: The top value is ?t18 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    2 prim seq-int.empty n primes-up-to-helper
  };

: primes-up-to-helper
  (forall ρ; ρ candidate:Int^many result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { candidate result n } {
    candidate n prim > [ result ] [
      candidate is-prime-check [ result candidate prim seq-int.push ] [ result ] if
      candidate 1 prim + result n primes-up-to-helper
    ] if
  };

: is-prime-check
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [
      n 2 prim = [ true ] [
        2 n check-prime-helper
      ] if
    ] if
  };

: check-prime-helper
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { divisor n } {
    divisor divisor prim * n prim > [ true ] [
      n divisor prim mod 0 prim = [ false ] [
        divisor 1 prim + n check-prime-helper
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 10, column 17
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

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
    prim seq-int.empty 0 k histogram-init xs histogram-helper
  };

: histogram-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result i k } {
    i k prim >= [ result ] [
      result 0 prim seq-int.push i 1 prim + k histogram-init
    ] if
  };

: histogram-helper
  (forall ρ; ρ i:Int^many counts:Seq Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i counts xs } {
    i xs prim seq-int.len prim = [ counts ] [
      xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at 1 prim + counts v prim seq-int.set
        i 1 prim + counts xs histogram-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 10, column 15
message: Unexpected the end of the input.
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
  locals { xs } {
    0 xs sort-helper
  };

: sort-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ xs:Seq Int^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim >= [
      i xs sort-pass sort-helper
    ] [ xs ] if
  };

: sort-pass
  (forall ρ; ρ j:Int^many xs:Seq Int^many i:Int^many -- ρ xs:Seq Int^many)
  locals { j xs i } {
    j xs prim seq-int.len 1 prim - i prim - prim >= [
      xs j prim seq-int.at xs j 1 prim + prim seq-int.at prim > [
        xs j prim seq-int.at xs j 1 prim + prim seq-int.at 
        xs j prim seq-int.set xs j 1 prim + prim seq-int.set
      ] [ xs ] if
      j 1 prim + xs i sort-pass
    ] [ xs ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 10, column 42
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    0 0 start txs ledger-helper
  };

: ledger-helper
  (forall ρ; ρ i:Int^many rejected:Int^many balance:Int^many start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { i rejected balance start txs } {
    i txs prim seq-int.len prim = [ balance rejected ] [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim < [
          rejected 1 prim + balance start txs ledger-helper
        ] [
          balance tx prim + i 1 prim + rejected start txs ledger-helper
        ] if
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 11
message: In the true branch `[ rejected 1 prim + balance start txs ledger-helper ]` of the `if` in `ledger-helper`, `ledger-helper` needs 5 values (i:Int, rejected:Int, balance:Int, start:Int, txs:Seq Int), but the branch has pushed only 4 values before it (the result of `prim +`, `balance`, `start` and `txs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-helper`, exactly the values it takes, in this order: i:Int, rejected:Int, balance:Int, start:Int, txs:Seq Int. The branch already pushes the result of `prim +`, `balance`, `start` and `txs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `ledger-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    0 prim seq-int.empty prim seq-int.empty stock items qtys whole allocate-batch-helper
  };

: allocate-batch-helper
  (forall ρ; ρ j:Int^many reasons:Seq Int^many allocated:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { j reasons allocated stock items qtys whole } {
    j qtys prim seq-int.len prim = [ stock allocated reasons ] [
      items j prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { r } {
          qtys j prim seq-int.at locals { q } {
            q r prim <= [
              stock item prim seq-int.at q prim - stock item prim seq-int.set
              allocated q prim seq-int.push reasons 0 prim seq-int.push
              j 1 prim + reasons allocated stock items qtys whole allocate-batch-helper
            ] [
              r 0 prim = [
                allocated 0 prim seq-int.push reasons 2 prim seq-int.push
                j 1 prim + reasons allocated stock items qtys whole allocate-batch-helper
              ] [
                whole j prim seq-bool.at [
                  allocated 0 prim seq-int.push reasons 3 prim seq-int.push
                  j 1 prim + reasons allocated stock items qtys whole allocate-batch-helper
                ] [
                  stock item prim seq-int.at 0 prim seq-int.set
                  allocated r prim seq-int.push reasons 1 prim seq-int.push
                  j 1 prim + reasons allocated stock items qtys whole allocate-batch-helper
                ] if
              ] if
            ] if
          }
        }
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 14, column 23
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
