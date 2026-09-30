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
  locals { xs } { 0 xs sum-helper };

: sum-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc xs }
  { xs prim seq-int.len 0 prim = }
  [ acc ]
  [ xs 0 prim seq-int.at acc prim + xs sum-rest sum-helper ]
  if;

: sum-rest
  (forall ρ; ρ xs:Seq Int^many -- ρ rest:Seq Int^many)
  locals { xs }
  { prim seq-int.empty xs 1 prim seq-int.len [ xs swap prim seq-int.at ] compose dip };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: sum-helper
at: line 9, column 5
message: `acc` is not a defined word, primitive or local.
actual: acc
hint: `acc` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { acc xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: sum-rest
at: line 16, column 29
message: `prim seq-int.len` in `sum-rest` takes Seq Int, bottom to top, but here it gets, bottom to top, `1` (Int).
expected: .. Seq Int
actual: ρ Seq Int Seq Int Seq Int Int
hint: The top value, `1` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs }
  { xs 0 prim seq-int.at xs 1 xs-max-helper };

: xs-max-helper
  (forall ρ; ρ max:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max idx xs }
  { idx xs prim seq-int.len prim >= }
  [ max ]
  [ xs idx prim seq-int.at max [ prim > ] [ prim < ] if
    [ xs idx prim seq-int.at ] [ max ] if
    idx 1 prim + xs xs-max-helper ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 31
message: `xs-max-helper` in `main` takes max:Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `1` (Int). `main` calls `xs-max-helper`, which has an error of its own; this report assumes `xs-max-helper` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int Int
hint: These are the values `xs-max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `max` and `idx`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.name.unresolved
word: xs-max-helper
at: line 10, column 5
message: `max` is not a defined word, primitive or local.
actual: max
hint: `max` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { max idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k count-helper };

: count-helper
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx xs k }
  { idx xs prim seq-int.len prim >= }
  [ count ]
  [ xs idx prim seq-int.at k prim <
    [ count 1 prim + ]
    [ count ]
    if
    idx 1 prim + xs k count-helper ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: count-helper
at: line 9, column 5
message: `count` is not a defined word, primitive or local.
actual: count
hint: `count` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { count idx xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x index-helper };

: index-helper
  (forall ρ; ρ idx:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx xs x }
  { idx xs prim seq-int.len prim >= }
  [ -1 ]
  [ xs idx prim seq-int.at x prim =
    [ idx ]
    [ idx 1 prim + xs x index-helper ]
    if ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: index-helper
at: line 10, column 5
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs }
  { prim seq-int.empty xs xs prim seq-int.len reverse-helper };

: reverse-helper
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result idx xs }
  { idx 0 prim <= }
  [ result ]
  [ idx 1 prim - xs result idx reverse-helper ];

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 47
message: `reverse-helper` in `main` takes result:Seq Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int) and the result of `prim seq-int.len` (Int). `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `reverse-helper` takes, in another order. To push them in its order, write `prim seq-int.empty xs prim seq-int.len xs` in place of `prim seq-int.empty xs xs prim seq-int.len` on line 4. With that edit `main` checks.

error 2 of 2
code: firth.name.unresolved
word: reverse-helper
at: line 10, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs }
  { prim seq-int.empty 0 0 xs prefix-helper };

: prefix-helper
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum idx xs }
  { idx xs prim seq-int.len prim >= }
  [ result ]
  [ xs idx prim seq-int.at sum prim + result swap prim seq-int.push idx 1 prim + xs prefix-helper ];

```
On the example, the run failed:
code: firth.name.unresolved
word: prefix-helper
at: line 10, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result sum idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs filter-positive };

: filter-positive
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result idx xs }
  { idx xs prim seq-int.len prim >= }
  [ result ]
  [ xs idx prim seq-int.at 0 prim >
    [ result xs idx prim seq-int.at prim seq-int.push ]
    [ result ]
    if
    idx 1 prim + xs filter-positive ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: filter-positive
at: line 9, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs }
  { true 0 xs is-sorted-helper };

: is-sorted-helper
  (forall ρ; ρ ok:Bool^many idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { ok idx xs }
  { idx xs prim seq-int.len 1 prim - prim >= }
  [ ok ]
  [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <= ok prim and
    idx 1 prim + xs is-sorted-helper ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: is-sorted-helper
at: line 10, column 5
message: `ok` is not a defined word, primitive or local.
actual: ok
hint: `ok` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { ok idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-helper };

: dot-helper
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum idx xs ys }
  { idx xs prim seq-int.len prim >= }
  [ sum ]
  [ xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim +
    idx 1 prim + xs ys dot-helper ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: dot-helper
at: line 9, column 5
message: `sum` is not a defined word, primitive or local.
actual: sum
hint: `sum` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { sum idx xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags }
  { true 0 flags all-true-helper };

: all-true-helper
  (forall ρ; ρ ok:Bool^many idx:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { ok idx flags }
  { idx flags prim seq-bool.len prim >= }
  [ ok ]
  [ flags idx prim seq-bool.at ok prim and
    idx 1 prim + flags all-true-helper ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: all-true-helper
at: line 10, column 5
message: `ok` is not a defined word, primitive or local.
actual: ok
hint: `ok` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { ok idx flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs }
  { 0 0 1 xs longest-run-helper };

: longest-run-helper
  (forall ρ; ρ maxlen:Int^many runlen:Int^many idx:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { maxlen runlen idx xs }
  { idx xs prim seq-int.len prim >= }
  [ maxlen runlen prim > [ runlen ] [ maxlen ] if ]
  [ xs idx prim seq-int.at xs idx 1 prim - prim seq-int.at prim =
    [ idx 1 prim + runlen 1 prim + xs longest-run-helper ]
    [ maxlen runlen prim > [ runlen ] [ maxlen ] if idx 1 prim + 1 xs longest-run-helper ]
    if ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: longest-run-helper
at: line 10, column 5
message: `maxlen` is not a defined word, primitive or local.
actual: maxlen
hint: `maxlen` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { maxlen runlen idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target }
  { false 0 xs target has-pair-helper };

: has-pair-helper
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target }
  { found true prim = }
  [ true ]
  [ i xs prim seq-int.len prim >= ]
  [ false ]
  [ i 1 prim + xs target has-inner-loop found ]
  if
  [ i 1 prim + xs target has-pair-helper ]
  if;

: has-inner-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many found:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { j xs target found i }
  { j xs prim seq-int.len prim >= }
  [ found i 1 prim + xs target has-pair-helper ]
  [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
    [ true i 1 prim + xs target has-pair-helper ]
    [ j 1 prim + xs target found i has-inner-loop ]
    if ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: has-pair-helper
at: line 11, column 5
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { found i xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: has-inner-loop
at: line 22, column 5
message: `found` is not a defined word, primitive or local.
actual: found
hint: `found` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { j xs target found i } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs count-distinct-helper };

: count-distinct-helper
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx xs }
  { idx xs prim seq-int.len prim >= }
  [ count ]
  [ xs idx prim seq-int.at 0 idx xs is-first-occurrence
    [ count 1 prim + ]
    [ count ]
    if
    idx 1 prim + xs count-distinct-helper ]
  if;

: is-first-occurrence
  (forall ρ; ρ val:Int^many start:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val start idx xs }
  { start idx prim >= }
  [ true ]
  [ xs start prim seq-int.at val prim =
    [ false ]
    [ start 1 prim + idx xs is-first-occurrence ]
    if ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: count-distinct-helper
at: line 9, column 5
message: `count` is not a defined word, primitive or local.
actual: count
hint: `count` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { count idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: is-first-occurrence
at: line 22, column 5
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { val start idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys }
  { prim seq-int.empty 0 0 xs ys merge-helper };

: merge-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys }
  { i xs prim seq-int.len prim >= }
  [ result j ys prim seq-int.len append-rest j ys append-rest ]
  [ j ys prim seq-int.len prim >= ]
  [ result i xs append-rest ]
  [ xs i prim seq-int.at ys j prim seq-int.at prim <=
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys merge-helper ]
    [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys merge-helper ]
    if ]
  if
  [ ]
  if;

: append-rest
  (forall ρ; ρ result:Seq Int^many idx:Int^many seq:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result idx seq }
  { idx seq prim seq-int.len prim >= }
  [ result ]
  [ result seq idx prim seq-int.at prim seq-int.push idx 1 prim + seq append-rest ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: merge-helper
at: line 10, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result i j xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: append-rest
at: line 25, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx seq } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n }
  { n 0 prim = }
  [ { 0 } ]
  [ prim seq-int.empty n extract-digits ]
  if;

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n }
  { n 0 prim = }
  [ result ]
  [ n 10 prim mod result swap prim seq-int.push n 10 prim div extract-digits ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: main
at: line 6, column 24
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: extract-digits
at: line 13, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n }
  { prim seq-int.empty 2 n check-primes };

: check-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n }
  { i n prim > }
  [ result ]
  [ i is-prime-num
    [ result i prim seq-int.push ]
    [ result ]
    if
    i 1 prim + n check-primes ]
  if;

: is-prime-num
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n }
  { n 2 prim < }
  [ false ]
  [ n 2 prim = ]
  [ true ]
  [ n 2 prim mod 0 prim = ]
  [ false ]
  [ 3 n is-prime-loop ]
  if
  if
  if;

: is-prime-loop
  (forall ρ; ρ i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { i n }
  { i i prim * n prim > }
  [ true ]
  [ n i prim mod 0 prim = ]
  [ false ]
  [ i 2 prim + n is-prime-loop ]
  if
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: check-primes
at: line 10, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result i n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.name.unresolved
word: is-prime-num
at: line 23, column 5
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: is-prime-loop
at: line 37, column 5
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k }
  { 0 k build-zero-seq xs build-histogram };

: build-zero-seq
  (forall ρ; ρ i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k }
  { prim seq-int.empty }
  { i k prim >= }
  [ ]
  [ prim seq-int.empty 0 prim seq-int.push i 1 prim + k build-zero-seq ]
  if;

: build-histogram
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts xs }
  { 0 xs counts increment-counts };

: increment-counts
  (forall ρ; ρ idx:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { idx xs counts }
  { idx xs prim seq-int.len prim >= }
  [ counts ]
  [ xs idx prim seq-int.at counts xs idx prim seq-int.at
    counts xs idx prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
    idx 1 prim + xs increment-counts ]
  if;

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 10, column 5
message: Unexpected `i`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: i
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
  locals { xs } { xs insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs insert-all };

: insert-all
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result idx xs }
  { idx xs prim seq-int.len prim >= }
  [ result ]
  [ xs idx prim seq-int.at result insert-sorted idx 1 prim + xs insert-all ]
  if;

: insert-sorted
  (forall ρ; ρ val:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { val result } { 0 val result insert-at-pos };

: insert-at-pos
  (forall ρ; ρ pos:Int^many val:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { pos val result }
  { pos result prim seq-int.len prim >= }
  [ result val prim seq-int.push ]
  [ result pos prim seq-int.at val prim > ]
  [ result val prim seq-int.push ]
  [ pos 1 prim + val result insert-at-pos ]
  if
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: insert-all
at: line 13, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: insert-at-pos
at: line 25, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { pos val result } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs apply-transactions };

: apply-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected idx txs }
  { idx txs prim seq-int.len prim >= }
  [ balance rejected ]
  [ txs idx prim seq-int.at balance prim + 0 prim <
    [ idx 1 prim + txs apply-transactions ]
    [ balance txs idx prim seq-int.at prim + rejected idx 1 prim + txs apply-transactions ]
    if ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: apply-transactions
at: line 9, column 5
message: `balance` is not a defined word, primitive or local.
actual: balance
hint: `balance` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { balance rejected idx txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole }
  { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-orders };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-list:Seq Int^many reasons-list:Seq Int^many)
  locals { stock allocated reasons order items qtys whole }
  { order items prim seq-int.len prim >= }
  [ stock allocated reasons ]
  [ items order prim seq-int.at stock allocate-single-order order qtys whole stock-left-new allocated-new reason-code order 1 prim + items qtys whole allocate-orders ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: allocate-orders
at: line 10, column 5
message: `stock` is not a defined word, primitive or local.
actual: stock
hint: `stock` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock allocated reasons order items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
