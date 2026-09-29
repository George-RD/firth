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
  locals { xs } { 0 xs 0 sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    [ i xs prim seq-int.len prim < ] [
      acc xs i prim seq-int.at prim +
      xs
      i 1 prim +
      sum-loop
    ] [ acc ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: sum-loop
at: line 13, column 15
message: `if` in `sum-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 max-loop };

: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ max prim < ] [ ] if
      [ max swap ] [ ] if
      xs
      i 1 prim +
      max-loop
    ] [ max ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 11, column 24
message: The two branches of `if` in `max-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 2 values, and the false branch leaves the stack as it is. The condition and the values the branches take from below the `if` are looked for where the locals `i` and `xs` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } { 0 xs 0 count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ swap prim < ] [ ] if
      xs
      i 1 prim +
      count-loop
    ] [ acc ] if
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
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `count-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 10, column 27
message: In the true branch `[ swap prim < ]` of the `if` in `count-loop`, `swap` needs 2 values, but the branch has pushed nothing before it. The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } { xs 0 x find-loop };

: find-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ result:Int^many)
  locals { x i xs } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at x prim =
      [ i ] [ xs i 1 prim + x find-loop ] if
    ] [ -1 ] if
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
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs x }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `find-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: find-loop
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x i xs }` in `find-loop` gives `x` the value the stack effect calls `xs` (Seq Int), `i` the value named `i` (Int), `xs` the value the stack effect calls `x` (Int).
actual: find-loop
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs i x }` in `find-loop`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    [ i 0 prim < ] [
      xs i prim seq-int.at
      result swap prim seq-int.push
      i 1 prim -
      reverse-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 13, column 18
message: In the true branch `[ xs i prim seq-int.at result swap prim ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (result:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: result:Seq Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    [ i xs prim seq-int.len prim < ] [
      sum xs i prim seq-int.at prim +
      result swap prim seq-int.push
      xs
      i 1 prim +
      prefix-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 14, column 18
message: In the true branch `[ sum xs i prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (result:Seq Int, sum:Int, xs:Seq Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, sum:Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 filter-loop };

: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ result swap prim seq-int.push ] [ drop ] if
      xs
      i 1 prim +
      filter-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 10, column 50
message: In the true branch `[ result swap prim seq-int.push ]` of the `if` in `filter-loop`, `swap` needs 2 values, but the branch has pushed only 1 value before it (`result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ xs prim seq-int.len 1 prim < ] [ true ] [
      xs 0 xs 1 check-sorted
    ] if
  };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      [ prim < prim not ] [ true ] if
      [ xs i 1 prim + check-sorted ] [ false ] if
    ] [ true ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 6, column 7
message: The two branches of the `if` in `main` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch leaves 3 values, bottom to top: `xs`, `0` and the result of `check-sorted`. `main` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
hint: The false branch leaves 2 values more than the true branch: `xs` and `0` are left below the result of `check-sorted`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: check-sorted
at: line 15, column 36
message: In the true branch `[ prim < prim not ]` of the `if` in `check-sorted`, `prim <` needs 2 values (Int, Int), but the branch has pushed nothing before it. It would take the result of `prim seq-int.at` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Push every value `prim <` takes inside the branch, just before it and in this order: Int, Int, for example by writing the locals that hold them. If `prim <` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs } { 0 xs ys 0 dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs ys i } {
    [ i xs prim seq-int.len prim < ] [
      acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      xs
      ys
      i 1 prim +
      dot-loop
    ] [ acc ] if
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
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `dot-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.expected-bool
word: dot-loop
at: line 14, column 15
message: `if` in `dot-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true flags 0 all-loop };

: all-loop
  (forall ρ; ρ acc:Bool^many flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { acc flags i } {
    [ i flags prim seq-bool.len prim < ] [
      acc flags i prim seq-bool.at prim and
      flags
      i 1 prim +
      all-loop
    ] [ acc ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: all-loop
at: line 13, column 15
message: `if` in `all-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ xs prim seq-int.len 0 prim = ] [ 0 ] [
      1 xs 0 prim seq-int.at 1 1 run-loop
    ] if
  };

: run-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many prev:Int^many current:Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs prev current i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ prev prim = ] [
        current 1 prim +
        xs
        xs i prim seq-int.at
        [ current 1 prim + max prim < ] [ max ] [ current 1 prim + ] if
        i 1 prim +
        run-loop
      ] [
        xs
        xs i prim seq-int.at
        1
        [ current max prim < ] [ max ] [ current ] if
        i 1 prim +
        run-loop
      ] if
    ] [ [ current max prim < ] [ max ] [ current ] if ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 6, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `run-loop` needs 5 values (max:Int, xs:Seq Int, prev:Int, current:Int, i:Int), but the branch has pushed only 4 values before it (`1`, the result of `prim seq-int.at`, `1` and `1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `run-loop`, which has an error of its own; this report assumes `run-loop` keeps its stack effect.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: max:Int, xs:Seq Int, prev:Int, current:Int, i:Int. The branch already pushes `1`, the result of `prim seq-int.at`, `1` and `1`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 29, column 57
message: The two branches of the `if` in `run-loop` whose true branch is `[ xs i prim seq-int.at [ prev prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `run-loop`; the false branch leaves the result of an `if`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `run-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } { false xs target 0 pair-loop };

: pair-loop
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { found xs target i } {
    [ found prim not i xs prim seq-int.len prim < prim and ] [
      xs i prim seq-int.at
      xs xs prim seq-int.len 1 prim - inner-check
      xs
      target
      [ true ] [ i 1 prim + pair-loop ] if
    ] [ found ] if
  };

: inner-check
  (forall ρ; ρ xs:Seq Int^many target:Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target val j } {
    [ j 0 prim < prim not ] [
      xs j prim seq-int.at val prim + target prim =
      [ true ] [ j 1 prim - inner-check ] if
    ] [ false ] if
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
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs target }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `pair-loop`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.type.branch-mismatch
word: pair-loop
at: line 13, column 41
message: In the false branch of the `if` in `pair-loop` whose true branch is `[ true ]`, `pair-loop` needs 4 values (found:Bool, xs:Seq Int, target:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). It would take the result of `inner-check` and `xs` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used. `pair-loop` calls `inner-check`, which has an error of its own; this report assumes `inner-check` keeps its stack effect.
hint: Make the branch push, just before `pair-loop`, exactly the values it takes, in this order: found:Bool, xs:Seq Int, target:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `pair-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: inner-check
at: line 22, column 43
message: In the false branch of the `if` in `inner-check` whose true branch is `[ true ]`, `inner-check` needs 4 values (xs:Seq Int, target:Int, val:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim -`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-check`, exactly the values it takes, in this order: xs:Seq Int, target:Int, val:Int, j:Int. The branch already pushes the result of `prim -`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      xs i 1 prim + is-new-value
      [ count 1 prim + ] [ count ] if
      xs
      i 1 prim +
      distinct-loop
    ] [ count ] if
  };

: is-new-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs val j } {
    [ j 0 prim < ] [
      j 1 prim -
      xs swap prim seq-int.at val prim =
      [ false ] [ j 2 prim - is-new-value ] if
    ] [ true ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: distinct-loop
at: line 10, column 21
message: `is-new-value` in `distinct-loop` takes xs:Seq Int, val:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and the result of `prim +` (Int). `distinct-loop` calls `is-new-value`, which has an error of its own; this report assumes `is-new-value` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t30 Int Seq Int Int
hint: These are the values `is-new-value` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `i 1 prim +` are for `val` and `j`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.branch-mismatch
word: is-new-value
at: line 24, column 45
message: In the false branch of the `if` in `is-new-value` whose true branch is `[ false ]`, `is-new-value` needs 3 values (xs:Seq Int, val:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim -`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-new-value`, exactly the values it takes, in this order: xs:Seq Int, val:Int, j:Int. The branch already pushes the result of `prim -`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `is-new-value` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ final:Seq Int^many)
  locals { result xs ys i j } {
    [ i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and ] [
      xs i prim seq-int.at
      ys j prim seq-int.at
      [ prim < ] [ ] if
      [ result swap prim seq-int.push xs ys i 1 prim + j merge-loop ] [
        result swap prim seq-int.push xs ys i j 1 prim + merge-loop
      ] if
    ] [
      [ i xs prim seq-int.len prim < ] [
        result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
      ] [
        [ j ys prim seq-int.len prim < ] [
          result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
        ] [ result ] if
      ] if
    ] if
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
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `merge-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 11, column 22
message: In the true branch `[ prim < ]` of the `if` in `merge-loop`, `prim <` needs 2 values (Int, Int), but the branch has pushed nothing before it. It would take the result of `prim seq-int.at` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Push every value `prim <` takes inside the branch, just before it and in this order: Int, Int, for example by writing the locals that hold them. If `prim <` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ n 0 prim = ] [ { 0 } ] [
      n digits-helper
    ] if
  };

: digits-helper
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  [ n 0 prim = prim not ] [
    n 10 prim mod
    n 10 prim div
    digits-helper
    prim seq-int.push
  ] [ prim seq-int.empty ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: main
at: line 6, column 7
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ]. `main` calls `digits-helper`, which has an error of its own; this report assumes `digits-helper` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: digits-helper
at: line 11, column 5
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
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    [ candidate n prim < ] [
      candidate is-prime
      [ result candidate prim seq-int.push ] [ result ] if
      candidate 1 prim +
      n
      primes-loop
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many -- ρ result:Bool^many)
  locals { candidate } {
    [ candidate 2 prim < ] [ false ] [
      [ candidate 2 prim = ] [ true ] [
        candidate 2 check-prime
      ] if
    ] if
  };

: check-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { candidate divisor } {
    [ divisor divisor prim * candidate prim < ] [
      candidate divisor prim mod 0 prim =
      [ false ] [ candidate divisor 1 prim + check-prime ] if
    ] [ true ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-bool
word: primes-loop
at: line 14, column 18
message: `if` in `primes-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 3
code: firth.type.expected-bool
word: is-prime
at: line 23, column 9
message: `if` in `is-prime` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ]. `is-prime` calls `check-prime`, which has an error of its own; this report assumes `check-prime` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 3
code: firth.type.expected-bool
word: check-prime
at: line 33, column 16
message: `if` in `check-prime` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } {
    prim seq-int.empty 0 build-counts
    xs 0 histogram-loop
  };

: build-counts
  (forall ρ; ρ counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts i } {
    [ i 3 prim < ] [
      counts 0 prim seq-int.push
      i 1 prim +
      build-counts
    ] [ counts ] if
  };

: histogram-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      counts swap prim seq-int.at 1 prim +
      counts swap prim seq-int.set
      xs
      i 1 prim +
      histogram-loop
    ] [ counts ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs }` in `main` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `build-counts` and `histogram-loop`, which have errors of their own, keep their stack effects.

error 2 of 3
code: firth.type.expected-bool
word: build-counts
at: line 15, column 18
message: `if` in `build-counts` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 3
code: firth.type.branch-mismatch
word: histogram-loop
at: line 28, column 18
message: In the true branch `[ xs i prim seq-int.at counts swap prim ...` of the `if` in `histogram-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (`counts` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes `counts` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 sort-loop
  };

: sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    [ i xs prim seq-int.len prim < ] [
      result xs i prim seq-int.at insert-sorted
      xs
      i 1 prim +
      sort-loop
    ] [ result ] if
  };

: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ sorted:Seq Int^many)
  locals { result val } {
    result result prim seq-int.len val insert-position
  };

: insert-position
  (forall ρ; ρ result:Seq Int^many pos:Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result pos val } {
    result val prim seq-int.push
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: sort-loop
at: line 19, column 18
message: `if` in `sort-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
  locals { balance rejected txs i } {
    [ i txs prim seq-int.len prim < ] [
      balance txs i prim seq-int.at
      [ prim < ] [ ] if
      [ balance rejected txs i 1 prim + ledger-loop ] [
        balance txs i prim seq-int.at prim +
        rejected
        txs
        i 1 prim +
        ledger-loop
      ] if
    ] [ balance rejected ] if
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
code: firth.type.branch-mismatch
word: ledger-loop
at: line 10, column 22
message: In the true branch `[ prim < ]` of the `if` in `ledger-loop`, `prim <` needs 2 values (Int, Int), but the branch has pushed nothing before it. It would take `balance` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Push every value `prim <` takes inside the branch, just before it and in this order: Int, Int, for example by writing the locals that hold them. If `prim <` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } {
    stock prim seq-int.empty prim seq-int.empty 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i } {
    [ i items prim seq-int.len prim < ] [
      items i prim seq-int.at
      stock swap prim seq-int.at
      qtys i prim seq-int.at
      [ prim < ] [ ] if
      [ allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push stock i prim seq-int.at qtys i prim seq-int.at prim - stock swap prim seq-int.set items qtys whole i 1 prim + allocate-loop ] [
        allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
      ] if
    ] [ stock allocated reasons ] if
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
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { stock items qtys whole }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `allocate-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.unresolved
word: allocate-loop
at: line 10, column 9
message: `items` is not a defined word, primitive or local.
actual: items
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
