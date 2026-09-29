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
  0 swap sum-helper;

: sum-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  dup prim seq-int.len 0 prim = [ drop ] [ 
    dup prim seq-int.len 1 prim - 
    swap dup 0 prim swap-at
    locals { i xs acc } { acc xs i prim seq-int.at prim + xs i sum-helper }
  ] if;

: swap-at
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ xs:Seq Int^many i:Int^many)
  swap;

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 9, column 16
message: `prim swap-at` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  dup 0 prim seq-int.at swap 1 max-helper;

: max-helper
  (forall ρ; ρ idx:Int^many max:Int^many xs:Seq Int^many -- ρ max:Int^many)
  dup prim seq-int.len locals { idx max xs } {
    idx xs prim seq-int.len prim = [ max ] [
      xs idx prim seq-int.at locals { val } {
        max val prim < [ val ] [ max ] if 
        idx 1 prim + max xs max-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 7
message: The two branches of the `if` in `max-helper` whose true branch is `[ max ]` leave different numbers of values. The true branch leaves `max`; the false branch leaves 2 values, bottom to top: the result of an `if` and the result of `max-helper`.
hint: The false branch leaves 1 value more than the true branch: the result of an `if` is left below the result of `max-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 swap count-below-helper;

: count-below-helper
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs count i } {
    i xs prim seq-int.len prim = [ count ] [
      xs i prim seq-int.at locals { val } {
        val k prim < [ count 1 prim + ] [ count ] if
        i 1 prim + swap count xs k count-below-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs count i }` in `count-below-helper` gives `k` the value the stack effect calls `i` (Int), `xs` the value the stack effect calls `count` (Int), `count` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `k` (Int).
actual: count-below-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i count xs k }` in `count-below-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 swap index-of-helper;

: index-of-helper
  (forall ρ; ρ i:Int^many idx:Int^many xs:Seq Int^many x:Int^many -- ρ idx:Int^many)
  dup prim seq-int.len locals { x xs i idx } {
    i xs prim seq-int.len prim = [ 0 prim - ] [
      xs i prim seq-int.at x prim = [ i ] [
        i 1 prim + idx xs x index-of-helper
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 7
message: The two branches of `if` in `index-of-helper` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  dup prim seq-int.len prim seq-int.empty reverse-helper;

: reverse-helper
  (forall ρ; ρ i:Int^many res:Seq Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { xs res i } {
    i 0 prim = [ res ] [
      i 1 prim - locals { i' } {
        xs i' prim seq-int.at res prim seq-int.push i' res xs reverse-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.overlong-character
at: line 9, column 28
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
  dup 0 prim seq-int.empty 0 prefix-sums-helper;

: prefix-sums-helper
  (forall ρ; ρ i:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs result sum i } {
    i xs prim seq-int.len prim = [ result ] [
      xs i prim seq-int.at sum prim + locals { newsum } {
        result newsum prim seq-int.push i 1 prim + newsum xs prefix-sums-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs result sum i }` in `prefix-sums-helper` gives `xs` the value the stack effect calls `i` (Int), `result` the value the stack effect calls `sum` (Int), `sum` the value the stack effect calls `result` (Seq Int), `i` the value the stack effect calls `xs` (Seq Int).
actual: prefix-sums-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i sum result xs }` in `prefix-sums-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  0 prim seq-int.empty keep-positive-helper;

: keep-positive-helper
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim = [ result ] [
      xs i prim seq-int.at locals { val } {
        val 0 prim < [ result ] [
          result val prim seq-int.push
        ] if
        i 1 prim + swap xs keep-positive-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs result i }` in `keep-positive-helper` gives `xs` the value the stack effect calls `i` (Int), `result` the value named `result` (Seq Int), `i` the value the stack effect calls `xs` (Seq Int).
actual: keep-positive-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i result xs }` in `keep-positive-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 [ true ] is-sorted-helper;

: is-sorted-helper
  (forall ρ; ρ i:Int^many result:Bool^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs result i } {
    result [ true ] [ false ] if [ 
      i 1 prim + xs prim seq-int.len prim = [ true ] [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= locals { check } {
          check [ i 1 prim + true xs is-sorted-helper ] [ false ] if
        }
      ] if
    ] [ false ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 10, column 66
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-helper;

: dot-helper
  (forall ρ; ρ i:Int^many sum:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ sum:Int^many)
  locals { ys xs sum i } {
    i xs prim seq-int.len prim = [ sum ] [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + 
      i 1 prim + swap xs ys dot-helper
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs sum i }` in `dot-helper` gives `ys` the value the stack effect calls `i` (Int), `xs` the value the stack effect calls `sum` (Int), `sum` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `ys` (Seq Int).
actual: dot-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i sum xs ys }` in `dot-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 [ true ] all-true-helper;

: all-true-helper
  (forall ρ; ρ i:Int^many result:Bool^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags result i } {
    result [ true ] [ false ] if [
      i flags prim seq-bool.len prim = [ true ] [
        flags i prim seq-bool.at [ i 1 prim + true flags all-true-helper ] [ false ] if
      ] if
    ] [ false ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { flags result i }` in `all-true-helper` gives `flags` the value the stack effect calls `i` (Int), `result` the value named `result` (Bool), `i` the value the stack effect calls `flags` (Seq Bool).
actual: all-true-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i result flags }` in `all-true-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim = [ 0 ] [ 
    1 1 0 longest-run-helper
  ] if;

: longest-run-helper
  (forall ρ; ρ idx:Int^many maxlen:Int^many curlen:Int^many xs:Seq Int^many -- ρ maxlen:Int^many)
  locals { xs curlen maxlen idx } {
    idx xs prim seq-int.len prim = [
      curlen maxlen prim < [ maxlen ] [ curlen ] if
    ] [
      xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim = [
        curlen 1 prim +
      ] [
        1
      ] if locals { newcurlen } {
        newcurlen maxlen prim > [ newcurlen ] [ maxlen ] if
        idx 1 prim + newcurlen xs longest-run-helper
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 3
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
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 has-pair-sum-helper;

: has-pair-sum-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs i } {
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
  locals { xi xs target j } {
    j xs prim seq-int.len prim = [ false ] [
      xs j prim seq-int.at xi prim + target prim = [ true ] [
        j 1 prim + target xs xi has-pair-sum-check
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { target xs i }` in `has-pair-sum-helper` gives `target` the value the stack effect calls `i` (Int), `xs` the value named `xs` (Seq Int), `i` the value the stack effect calls `target` (Int); `locals { xi xs target j }` in `has-pair-sum-check` gives `xi` the value the stack effect calls `j` (Int), `xs` the value the stack effect calls `target` (Int), `target` the value the stack effect calls `xs` (Seq Int), `j` the value the stack effect calls `xi` (Int).
actual: has-pair-sum-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i xs target }` in `has-pair-sum-helper`, and `locals { j target xs xi }` in `has-pair-sum-check`, and keep the bodies as they are: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 count-distinct-helper;

: count-distinct-helper
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { xs count i } {
    i xs prim seq-int.len prim = [ count ] [
      xs i prim seq-int.at count 1 prim + 
      i 1 prim + 0 count-distinct-search [ drop ] [ ] if
      xs count-distinct-helper
    ] if
  };

: count-distinct-search
  (forall ρ; ρ j:Int^many val:Int^many xs:Seq Int^many -- ρ found:Bool^many)
  locals { xs val j } {
    j i prim = [ true ] [
      xs j prim seq-int.at val prim = [ true ] [
        j 1 prim + val xs count-distinct-search
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 18, column 7
message: `i` is not a defined word, primitive or local.
actual: i
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  0 0 prim seq-int.empty merge-sorted-helper;

: merge-sorted-helper
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { ys xs result j i } {
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
at: line 18, column 57
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
  n 0 prim = [ { 0 } ] [
    prim seq-int.empty n digits-helper
  ] if;

: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim = [ result ] [
      n 10 prim mod result prim seq-int.push n 10 prim div digits-helper
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 3
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
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  2 prim seq-int.empty primes-up-to-helper;

: primes-up-to-helper
  (forall ρ; ρ candidate:Int^many result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { n result candidate } {
    candidate n prim > [ result ] [
      candidate is-prime [ result candidate prim seq-int.push ] [ result ] if
      candidate 1 prim + result n primes-up-to-helper
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  n 2 prim < [ false ] [
    n 2 prim = [ true ] [
      2 check-prime-helper
    ] if
  ] if;

: check-prime-helper
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { n divisor } {
    divisor divisor prim * n prim > [ true ] [
      n divisor prim mod 0 prim = [ false ] [
        divisor 1 prim + n check-prime-helper
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 16, column 3
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
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  0 prim seq-int.empty 0 1 prim -
  [ 0 prim seq-int.empty ] histogram-init-helper
  xs histogram-helper;

: histogram-init-helper
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { result k i } {
    i k prim >= [ result ] [
      result 0 prim seq-int.push i 1 prim + k result histogram-init-helper
    ] if
  };

: histogram-helper
  (forall ρ; ρ i:Int^many counts:Seq Int^many xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs counts i } {
    i xs prim seq-int.len prim = [ counts ] [
      xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at counts v prim seq-int.at 1 prim + prim seq-int.set
        i 1 prim + counts xs k histogram-helper
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
  0 xs sort-helper;

: sort-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ xs:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >= [ xs ] [
      i xs sort-pass [ sort-helper ] [ xs ] if
    ] if
  };

: sort-pass
  (forall ρ; ρ j:Int^many xs:Seq Int^many i:Int^many -- ρ xs:Seq Int^many)
  locals { i xs j } {
    j xs prim seq-int.len 1 prim - i prim - prim >= [ xs ] [
      xs j prim seq-int.at xs j 1 prim + prim seq-int.at prim > [
        xs j prim seq-int.at xs j 1 prim + prim seq-int.at 
        xs j prim seq-int.set xs j 1 prim + prim seq-int.set
      ] [ xs ] if
      j 1 prim + xs i sort-pass
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 42
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
  0 0 ledger-helper;

: ledger-helper
  (forall ρ; ρ i:Int^many rejected:Int^many balance:Int^many start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start balance rejected i } {
    i txs prim seq-int.len prim = [ balance rejected ] [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim < [
          rejected 1 prim + balance txs start ledger-helper
        ] [
          balance tx prim + i 1 prim + rejected txs start ledger-helper
        ] if
      }
    ] if
  };

```
On the example, the run failed:
code: firth.name.locals-order
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { txs start balance rejected i }` in `ledger-helper` gives `txs` the value the stack effect calls `i` (Int), `start` the value the stack effect calls `rejected` (Int), `balance` the value named `balance` (Int), `rejected` the value the stack effect calls `start` (Int), `i` the value the stack effect calls `txs` (Seq Int).
actual: ledger-helper
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i rejected balance start txs }` in `ledger-helper`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  0 prim seq-int.empty prim seq-int.empty allocate-batch-helper;

: allocate-batch-helper
  (forall ρ; ρ j:Int^many reasons:Seq Int^many allocated:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock allocated reasons j } {
    j qtys prim seq-int.len prim = [ stock allocated reasons ] [
      items j prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { r } {
          qtys j prim seq-int.at locals { q } {
            q r prim <= [
              stock item prim seq-int.at q prim - stock item prim seq-int.set
              allocated q prim seq-int.push reasons 0 prim seq-int.push
            ] [
              r 0 prim = [
                allocated 0 prim seq-int.push reasons 2 prim seq-int.push
              ] [
                whole j prim seq-bool.at [
                  allocated 0 prim seq-int.push reasons 3 prim seq-int.push
                ] [
                  stock item prim seq-int.at 0 prim seq-int.set
                  allocated r prim seq-int.push reasons 1 prim seq-int.push
                ] if
              ] if
            ] if
            j 1 prim + stock items qtys whole allocate-batch-helper
          }
        }
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 12, column 23
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
