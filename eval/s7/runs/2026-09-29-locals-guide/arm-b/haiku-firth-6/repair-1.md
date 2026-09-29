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
  locals { xs } { xs prim seq-int.len locals { len } { 0 0 loop-sum } };

: loop-sum
  (forall ρ; ρ acc:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs len i acc } { i len prim < [ xs i prim seq-int.at locals { val } { acc val prim + locals { new-acc } { new-acc i 1 prim + len xs loop-sum } } ] [ acc ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 60
message: `loop-sum` needs more values than the stack holds here. `main` calls `loop-sum`, which has an error of its own; this report assumes `loop-sum` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-sum` and in what order.

error 2 of 2
code: firth.name.locals-order
word: loop-sum
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs len i acc }` in `loop-sum` gives `xs` the value the stack effect calls `acc` (Int), `len` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `len` (Int), `acc` the value the stack effect calls `xs` (Seq Int).
actual: loop-sum
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { acc i len xs }` in `loop-sum`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at locals { first } { first 1 loop-max first } };

: loop-max
  (forall ρ; ρ max:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs len i max } { i len prim < [ xs i prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if locals { new-max } { new-max i 1 prim + len xs loop-max } } ] [ max ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 67
message: `loop-max` needs more values than the stack holds here. `main` calls `loop-max`, which has an error of its own; this report assumes `loop-max` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-max` and in what order.

error 2 of 2
code: firth.name.locals-order
word: loop-max
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs len i max }` in `loop-max` gives `xs` the value the stack effect calls `max` (Int), `len` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `len` (Int), `max` the value the stack effect calls `xs` (Seq Int).
actual: loop-max
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { max i len xs }` in `loop-max`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } { xs prim seq-int.len locals { len } { 0 0 loop-count-below } };

: loop-count-below
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { k xs len i count } { i len prim < [ xs i prim seq-int.at locals { val } { val k prim < [ count 1 prim + ] [ count ] if locals { new-count } { new-count i 1 prim + len xs k loop-count-below } } ] [ count ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs }` in `main` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-count-below`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: loop-count-below
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs len i count }` in `loop-count-below` gives `k` the value the stack effect calls `count` (Int), `xs` the value the stack effect calls `i` (Int), `len` the value named `len` (Int), `i` the value the stack effect calls `xs` (Seq Int), `count` the value the stack effect calls `k` (Int).
actual: loop-count-below
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count i len xs k }` in `loop-count-below`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } { xs prim seq-int.len locals { len } { 0 loop-index-of } };

: loop-index-of
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { x xs len i } { i len prim < [ xs i prim seq-int.at locals { val } { val x prim = [ i ] [ i 1 prim + len xs x loop-index-of ] if } ] [ -1 ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x xs }` in `main` gives `x` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `x` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs x }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-index-of`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: loop-index-of
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { x xs len i }` in `loop-index-of` gives `x` the value the stack effect calls `i` (Int), `xs` the value the stack effect calls `len` (Int), `len` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `x` (Int).
actual: loop-index-of
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i len xs x }` in `loop-index-of`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - loop-reverse };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } { i 0 prim < [ ] [ xs i prim seq-int.at locals { val } { result val prim seq-int.push locals { new-result } { new-result i 1 prim - xs loop-reverse } } ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 67
message: `loop-reverse` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int. `main` calls `loop-reverse`, which has an error of its own; this report assumes `loop-reverse` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Int
hint: `loop-reverse` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.locals-order
word: loop-reverse
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs i result }` in `loop-reverse` gives `xs` the value the stack effect calls `result` (Seq Int), `i` the value named `i` (Int), `result` the value the stack effect calls `xs` (Seq Int).
actual: loop-reverse
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i xs }` in `loop-reverse`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 loop-prefix };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many acc:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i acc result } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { acc val prim + locals { new-acc } { result new-acc prim seq-int.push locals { new-result } { new-result new-acc i 1 prim + xs loop-prefix } } } ] [ result ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 42
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Int Seq Int [ .. Seq Int Int Int Seq Int -- .. Seq Int ]). `main` calls `loop-prefix`, which has an error of its own; this report assumes `loop-prefix` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.name.locals-order
word: loop-prefix
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs i acc result }` in `loop-prefix` gives `xs` the value the stack effect calls `result` (Seq Int), `i` the value the stack effect calls `acc` (Int), `acc` the value the stack effect calls `i` (Int), `result` the value the stack effect calls `xs` (Seq Int).
actual: loop-prefix
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result acc i xs }` in `loop-prefix`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 loop-keep-pos };

: loop-keep-pos
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { val 0 prim < [ result ] [ result val prim seq-int.push ] if locals { new-result } { new-result i 1 prim + xs loop-keep-pos } } ] [ result ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 40
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Seq Int [ .. Seq Int Int Seq Int -- .. Seq Int ]). `main` calls `loop-keep-pos`, which has an error of its own; this report assumes `loop-keep-pos` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.name.locals-order
word: loop-keep-pos
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs i result }` in `loop-keep-pos` gives `xs` the value the stack effect calls `result` (Seq Int), `i` the value named `i` (Int), `result` the value the stack effect calls `xs` (Seq Int).
actual: loop-keep-pos
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i xs }` in `loop-keep-pos`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 1 prim < [ true ] [ 0 loop-is-sorted true ] if } };

: loop-is-sorted
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs len i } { i 1 prim - locals { prev-i } { prev-i xs prim seq-int.len 1 prim - prim < [ xs prev-i prim seq-int.at locals { prev } { xs i prim seq-int.at locals { curr } { prev curr prim < [ false ] [ i 1 prim + len xs loop-is-sorted ] if } } } [ true ] if } };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 7, column 255
message: `}` cannot start an item in a word's body.
actual: }
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
  locals { ys xs } { 0 0 loop-dot };

: loop-dot
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { ys xs i acc } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { ys i prim seq-int.at locals { y } { x y prim * locals { prod } { acc prod prim + locals { new-acc } { new-acc i 1 prim + xs ys loop-dot } } } } ] [ acc ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs }` in `main` gives `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-dot`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: loop-dot
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs i acc }` in `loop-dot` gives `ys` the value the stack effect calls `acc` (Int), `xs` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `xs` (Seq Int), `acc` the value the stack effect calls `ys` (Seq Int).
actual: loop-dot
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { acc i xs ys }` in `loop-dot`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-bool.len 0 loop-all-true true };

: loop-all-true
  (forall ρ; ρ result:Bool^many i:Int^many len:Int^many flags:Seq Bool^many -- ρ final:Bool^many)
  locals { flags len i result } { i len prim < [ flags i prim seq-bool.at locals { flag } { result flag prim and locals { new-result } { new-result i 1 prim + len flags loop-all-true } } ] [ result ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 48
message: `loop-all-true` needs more values than the stack holds here. `main` calls `loop-all-true`, which has an error of its own; this report assumes `loop-all-true` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-all-true` and in what order.

error 2 of 2
code: firth.name.locals-order
word: loop-all-true
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { flags len i result }` in `loop-all-true` gives `flags` the value the stack effect calls `result` (Bool), `len` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `len` (Int), `result` the value the stack effect calls `flags` (Seq Bool).
actual: loop-all-true
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i len flags }` in `loop-all-true`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim < [ 0 ] [ 1 1 1 loop-longest ] if };

: loop-longest
  (forall ρ; ρ max-len:Int^many curr-len:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i curr-len max-len } { i xs prim seq-int.len prim < [ xs i 1 prim - prim seq-int.at locals { prev } { xs i prim seq-int.at locals { curr } { prev curr prim = [ curr-len 1 prim + ] [ curr-len ] if locals { new-len } { max-len new-len prim < [ new-len ] [ max-len ] if locals { new-max } { new-max new-len i 1 prim + xs loop-longest } } } } ] [ max-len ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 3, column 77
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `loop-longest` needs 4 values (max-len:Int, curr-len:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (`1`, `1` and `1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `loop-longest`, which has an error of its own; this report assumes `loop-longest` keeps its stack effect.
hint: Make the branch push, just before `loop-longest`, exactly the values it takes, in this order: max-len:Int, curr-len:Int, i:Int, xs:Seq Int. The branch already pushes `1`, `1` and `1`, in the place of the first 3 (max-len:Int, curr-len:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (xs:Seq Int) after them, for example by writing the locals that hold it. If `loop-longest` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.locals-order
word: loop-longest
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs i curr-len max-len }` in `loop-longest` gives `xs` the value the stack effect calls `max-len` (Int), `i` the value the stack effect calls `curr-len` (Int), `curr-len` the value the stack effect calls `i` (Int), `max-len` the value the stack effect calls `xs` (Seq Int).
actual: loop-longest
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { max-len curr-len i xs }` in `loop-longest`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } { 0 false loop-pair };

: loop-pair
  (forall ρ; ρ i:Int^many found:Bool^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs found i } { found [ i xs prim seq-int.len loop-pair-inner false ] [ i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { i 1 prim + loop-pair-inner-j false } ] [ false ] if ] if };

: loop-pair-inner-j
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs i j } { j xs prim seq-int.len prim < [ xs j prim seq-int.at locals { y } { xs i prim seq-int.at locals { x } { x y prim + target prim = [ true ] [ j 1 prim + i xs target loop-pair-inner-j ] if } } } [ false ] if };

: loop-pair-inner
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs len i } { i len prim < [ i 1 prim + loop-pair-inner xs target ] [ false ] if };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 11, column 219
message: `}` cannot start an item in a word's body.
actual: }
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 0 loop-distinct };

: loop-distinct
  (forall ρ; ρ seen:Seq Int^many count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i count seen } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { 0 loop-find-in-seen false val seen } ] [ count ] if };

: loop-find-in-seen
  (forall ρ; ρ found:Bool^many j:Int^many val:Int^many seen:Seq Int^many i:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs count i seen val found j } { found [ i 1 prim + count xs loop-distinct ] [ j seen prim seq-int.len prim < [ seen j prim seq-int.at locals { s } { s val prim = [ i 1 prim + count 1 prim + seen val prim seq-int.push xs loop-distinct ] [ j 1 prim + val seen loop-find-in-seen ] if } ] [ i 1 prim + count xs loop-distinct ] if ] if };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 42
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Int Seq Int [ .. Seq Int Int Int Seq Int -- .. Int ]). `main` calls `loop-distinct`, which has an error of its own; this report assumes `loop-distinct` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 3
code: firth.name.locals-order
word: loop-distinct
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs i count seen }` in `loop-distinct` gives `xs` the value the stack effect calls `seen` (Seq Int), `i` the value the stack effect calls `count` (Int), `count` the value the stack effect calls `i` (Int), `seen` the value the stack effect calls `xs` (Seq Int).
actual: loop-distinct
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { seen count i xs }` in `loop-distinct`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-find-in-seen`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.name.locals-order
word: loop-find-in-seen
at: line 11, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { xs count i seen val found j }` in `loop-find-in-seen` gives `xs` the value the stack effect calls `found` (Bool), `count` the value the stack effect calls `j` (Int), `i` the value the stack effect calls `val` (Int), `seen` the value named `seen` (Seq Int), `val` the value the stack effect calls `i` (Int), `found` the value the stack effect calls `count` (Int), `j` the value the stack effect calls `xs` (Seq Int).
actual: loop-find-in-seen
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { found j val seen i count xs }` in `loop-find-in-seen`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-distinct`, which has an error of its own, keeps its stack effect.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } { prim seq-int.empty 0 0 loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { ys xs j i result } { i xs prim seq-int.len prim < [ j ys prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { ys j prim seq-int.at locals { y } { x y prim < [ result x prim seq-int.push locals { new-result } { new-result i 1 prim + j xs ys loop-merge } ] [ result y prim seq-int.push locals { new-result } { new-result i j 1 prim + xs ys loop-merge } ] if } } ] [ result xs i prim seq-int.at prim seq-int.push locals { new-result } { new-result i 1 prim + j xs ys loop-merge } ] if ] [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push locals { new-result } { new-result i j 1 prim + xs ys loop-merge } ] [ result ] if ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs }` in `main` gives `ys` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `ys` (Seq Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs ys }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-merge`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: loop-merge
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { ys xs j i result }` in `loop-merge` gives `ys` the value the stack effect calls `result` (Seq Int), `xs` the value the stack effect calls `i` (Int), `j` the value named `j` (Int), `i` the value the stack effect calls `xs` (Seq Int), `result` the value the stack effect calls `ys` (Seq Int).
actual: loop-merge
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i j xs ys }` in `loop-merge`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim < [ 0 ] [ n ] if locals { abs-n } { abs-n 0 prim = [ 0 prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty abs-n loop-digits ] if } };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { n result } { n 10 prim mod locals { digit } { result digit prim seq-int.push locals { new-result } { n 10 prim div locals { new-n } { new-n 0 prim = [ new-result ] [ new-result new-n loop-digits ] if } } } };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 3, column 164
message: The two branches of the `if` in `main` whose true branch is `[ 0 prim seq-int.empty 0 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `0` and the result of `prim seq-int.push`; the false branch leaves the result of `loop-digits`. `main` calls `loop-digits`, which has an error of its own; this report assumes `loop-digits` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: `0` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.locals-order
word: loop-digits
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n result }` in `loop-digits` gives `n` the value the stack effect calls `result` (Seq Int), `result` the value the stack effect calls `n` (Int).
actual: loop-digits
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result n }` in `loop-digits`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { n i result } { i n prim < [ i is-prime [ result i prim seq-int.push ] [ result ] if locals { new-result } { new-result i 1 prim + n loop-primes } ] [ result ] if };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ 2 loop-check-prime ] if };

: loop-check-prime
  (forall ρ; ρ i:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { n i } { i i prim * n prim < [ n i prim mod 0 prim = [ false ] [ i 1 prim + n loop-check-prime ] if ] [ true ] if };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 39
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Int [ .. Seq Int Int Int -- .. Seq Int ]). `main` calls `loop-primes`, which has an error of its own; this report assumes `loop-primes` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 4
code: firth.name.locals-order
word: loop-primes
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n i result }` in `loop-primes` gives `n` the value the stack effect calls `result` (Seq Int), `i` the value named `i` (Int), `result` the value the stack effect calls `n` (Int).
actual: loop-primes
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { result i n }` in `loop-primes`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `is-prime`, which has an error of its own, keeps its stack effect.

error 3 of 4
code: firth.type.branch-mismatch
word: is-prime
at: line 11, column 62
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `loop-check-prime` needs 2 values (i:Int, n:Int), but the branch has pushed only 1 value before it (`2`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `is-prime` calls `loop-check-prime`, which has an error of its own; this report assumes `loop-check-prime` keeps its stack effect.
hint: Make the branch push, just before `loop-check-prime`, exactly the values it takes, in this order: i:Int, n:Int. The branch already pushes `2`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-check-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 4
code: firth.name.locals-order
word: loop-check-prime
at: line 15, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { n i }` in `loop-check-prime` gives `n` the value the stack effect calls `i` (Int), `i` the value the stack effect calls `n` (Int).
actual: loop-check-prime
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i n }` in `loop-check-prime`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } { 0 loop-build-hist prim seq-int.empty };

: loop-build-hist
  (forall ρ; ρ i:Int^many k:Int^many xs:Seq Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { result xs k i } { i k prim < [ 0 result i 0 prim seq-int.push locals { new-result } { new-result i 1 prim + k xs loop-build-hist } ] [ result ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { k xs }` in `main` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { xs k }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-build-hist`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: loop-build-hist
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { result xs k i }` in `loop-build-hist` gives `result` the value the stack effect calls `i` (Int), `xs` the value the stack effect calls `k` (Int), `k` the value the stack effect calls `xs` (Seq Int), `i` the value the stack effect calls `result` (Seq Int).
actual: loop-build-hist
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i k xs result }` in `loop-build-hist`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len loop-sort };

: loop-sort
  (forall ρ; ρ arr:Seq Int^many start:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { len start arr } { start 1 prim - loop-sort-inner len arr };

: loop-sort-inner
  (forall ρ; ρ i:Int^many len:Int^many arr:Seq Int^many -- ρ result:Seq Int^many)
  locals { arr len i } { i 0 prim < [ arr ] [ arr i prim seq-int.at locals { val } { arr i 1 prim - prim seq-int.at locals { prev } { val prev prim < [ arr i prev prim seq-int.set locals { new-arr } { new-arr i 1 prim - val loop-sort-inner } ] [ arr ] if } } ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: loop-sort
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { len start arr }` in `loop-sort` gives `len` the value the stack effect calls `arr` (Seq Int), `start` the value named `start` (Int), `arr` the value the stack effect calls `len` (Int).
actual: loop-sort
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { arr start len }` in `loop-sort`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-sort-inner`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: loop-sort-inner
at: line 11, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { arr len i }` in `loop-sort-inner` gives `arr` the value the stack effect calls `i` (Int), `len` the value named `len` (Int), `i` the value the stack effect calls `arr` (Seq Int).
actual: loop-sort-inner
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { i len arr }` in `loop-sort-inner`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } { start 0 0 loop-ledger };

: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { txs start i rejected balance } { i txs prim seq-int.len prim < [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { new-bal } { new-bal 0 prim < [ balance rejected 1 prim + i 1 prim + start txs loop-ledger ] [ new-bal rejected i 1 prim + start txs loop-ledger ] if } } ] [ balance rejected ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.locals-order
word: main
at: line 3, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { txs start }` in `main` gives `txs` the value the stack effect calls `start` (Int), `start` the value the stack effect calls `txs` (Seq Int).
actual: main
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { start txs }` in `main`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `loop-ledger`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.name.locals-order
word: loop-ledger
at: line 7, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { txs start i rejected balance }` in `loop-ledger` gives `txs` the value the stack effect calls `balance` (Int), `start` the value the stack effect calls `rejected` (Int), `i` the value named `i` (Int), `rejected` the value the stack effect calls `start` (Int), `balance` the value the stack effect calls `txs` (Seq Int).
actual: loop-ledger
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { balance rejected i start txs }` in `loop-ledger`, and keep the body as it is: each name then holds the value the stack effect gives it. Swapping values with `swap` would not help, because the names are what is wrong.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } { stock prim seq-int.empty prim seq-int.empty 0 loop-alloc };

: loop-alloc
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { whole qtys items order reasons allocated stock } { order items prim seq-int.len prim < [ items order prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys order prim seq-int.at locals { q } { whole order prim seq-bool.at locals { w } { q r prim < [ stock allocated 0 prim seq-int.push reasons 0 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ r 0 prim = [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ stock item r prim seq-int.set locals { new-stock } { new-stock allocated r prim seq-int.push reasons 1 prim seq-int.push order 1 prim + items qtys whole loop-alloc } ] if ] if ] if } } } ] [ stock allocated reasons ] if };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 7, column 825
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
