Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: seq-sum
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 swap locals { xs sum } { 0 sum xs prim seq-int.len sum-iter };

: sum-iter
  (forall ρ; ρ idx:Int^many sum:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  idx len prim <
  [ xs idx prim seq-int.at sum prim + idx 1 prim + sum-iter ]
  [ sum ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  seq-sum;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: seq-sum
at: line 3, column 39
message: `prim seq-int.len` in `seq-sum` takes Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Int).
expected: .. Seq Int
actual: ρ Int Seq Int Int
hint: The top value, `xs` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: sum-iter
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx sum len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs prim seq-int.len 1 max-iter };

: max-iter
  (forall ρ; ρ current:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  idx len prim <
  [ xs idx prim seq-int.at current [ dup swap prim < [ drop ] [ swap drop ] if ] dip
    idx 1 prim + max-iter ]
  [ current ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  seq-max;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: seq-max
at: line 3, column 62
message: `max-iter` in `seq-max` needs Int Int Int Seq Int on top of the stack, but the stack before it is ρ Int Int Int. `seq-max` calls `max-iter`, which has an error of its own; this report assumes `max-iter` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Int Int Int
hint: `max-iter` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.unresolved
word: max-iter
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { current idx len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap locals { xs k } { 0 xs prim seq-int.len count-loop };

: count-loop
  (forall ρ; ρ count:Int^many len:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  idx len prim <
  [ xs idx prim seq-int.at k prim < [ count 1 prim + ] [ count ] if
    idx 1 prim + count-loop ]
  [ count ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  count-below;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: count-below
at: line 3, column 48
message: `count-loop` in `count-below` takes 5 values (count:Int, len:Int, idx:Int, xs:Seq Int, k:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the result of `prim seq-int.len` (Int). `count-below` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
hint: Push the 3 missing values before `count-loop`. The locals here, `xs` and `k`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.name.unresolved
word: count-loop
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { count len idx xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap locals { xs x } { 0 xs prim seq-int.len find-loop };

: find-loop
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  idx len prim <
  [ xs idx prim seq-int.at x prim = [ idx ] [ idx 1 prim + find-loop ] if ]
  [ -1 ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  index-of;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: index-of
at: line 3, column 48
message: `find-loop` in `index-of` takes 4 values (idx:Int, len:Int, xs:Seq Int, x:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the result of `prim seq-int.len` (Int). `index-of` calls `find-loop`, which has an error of its own; this report assumes `find-loop` keeps its stack effect.
hint: Push the 2 missing values before `find-loop`. The locals here, `xs` and `x`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.name.unresolved
word: find-loop
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx len xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  idx 0 prim >=
  [ xs idx prim seq-int.at result prim seq-int.push idx 1 prim - reverse-loop ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  reverse;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: reverse
at: line 3, column 67
message: `reverse-loop` in `reverse` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int. `reverse` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Int
hint: `reverse-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.unresolved
word: reverse-loop
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-sums
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  sum prim seq-int.len len prim <
  [ xs sum prim seq-int.len prim seq-int.at sum prim + result prim seq-int.push sum 1 prim + prefix-loop ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  prefix-sums;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: prefix-sums
at: line 3, column 60
message: `prefix-loop` in `prefix-sums` needs Seq Int Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int Int. `prefix-sums` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Int Int
hint: `prefix-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.unresolved
word: prefix-loop
at: line 7, column 3
message: `sum` is not a defined word, primitive or local.
actual: sum
hint: `sum` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result sum len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len filter-pos };

: filter-pos
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  idx len prim <
  [ xs idx prim seq-int.at dup 0 prim > [ result prim seq-int.push ] [ drop ] if
    idx 1 prim + filter-pos ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  keep-positive;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: keep-positive
at: line 3, column 60
message: `filter-pos` in `keep-positive` needs Seq Int Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int Int. `keep-positive` calls `filter-pos`, which has an error of its own; this report assumes `filter-pos` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Int Int
hint: `filter-pos` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.unresolved
word: filter-pos
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len dup 1 prim <= [ drop drop true ] [ 1 prim - check-sorted ] if;

: check-sorted
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  idx len prim >=
  [ true ]
  [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <= [ idx 1 prim + check-sorted ] [ false ] if ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  is-sorted;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 100
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  swap locals { xs ys } { 0 0 xs prim seq-int.len dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  idx len prim <
  [ xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + idx 1 prim + dot-loop ]
  [ sum ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  dot;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: dot
at: line 3, column 51
message: `dot-loop` in `dot` takes 5 values (sum:Int, idx:Int, len:Int, xs:Seq Int, ys:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: `0` (Int), `0` (Int) and the result of `prim seq-int.len` (Int). `dot` calls `dot-loop`, which has an error of its own; this report assumes `dot-loop` keeps its stack effect.
hint: Push the 2 missing values before `dot-loop`. The locals here, `xs` and `ys`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.name.unresolved
word: dot-loop
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { sum idx len xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 0 flags prim seq-bool.len check-all };

: check-all
  (forall ρ; ρ idx:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  idx len prim >=
  [ true ]
  [ flags idx prim seq-bool.at [ idx 1 prim + check-all ] [ false ] if ]
  if;

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  all-true;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: all-true
at: line 3, column 48
message: `check-all` in `all-true` needs Int Int Seq Bool on top of the stack, but the stack before it is ρ Int Int. `all-true` calls `check-all`, which has an error of its own; this report assumes `check-all` keeps its stack effect.
expected: .. Int Int Seq Bool
actual: ρ Int Int
hint: `check-all` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.unresolved
word: check-all
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx len flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ 1 1 xs prim seq-int.len find-longest ] if;

: find-longest
  (forall ρ; ρ current:Int^many max:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  idx len prim >=
  [ max ]
  [ xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim = 
    [ current 1 prim + ]
    [ current ]
    if
    dup max [ swap drop ] [ max-update ] if
    idx 1 prim + find-longest ]
  if;

: max-update
  (forall ρ; ρ next:Int^many current:Int^many max:Int^many -- ρ new-max:Int^many)
  [ next [ drop ] if ] dip;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  longest-run;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 97
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap locals { xs target } { 0 xs prim seq-int.len check-pairs };

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  i len prim >=
  [ false ]
  [ i 1 prim + j-loop [ true ] [ i 1 prim + check-pairs ] if ]
  if;

: j-loop
  (forall ρ; ρ j:Int^many -- ρ found-or-continue:Bool^many)
  j len prim >=
  [ false ]
  [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + j-loop ] if ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  has-pair-sum;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: has-pair-sum
at: line 3, column 53
message: `check-pairs` in `has-pair-sum` takes 4 values (i:Int, len:Int, xs:Seq Int, target:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the result of `prim seq-int.len` (Int). `has-pair-sum` calls `check-pairs`, which has an error of its own; this report assumes `check-pairs` keeps its stack effect.
hint: Push the 2 missing values before `check-pairs`. The locals here, `xs` and `target`, are not values on the stack: writing a local's name pushes its value.

error 2 of 3
code: firth.name.unresolved
word: check-pairs
at: line 7, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: j-loop
at: line 14, column 3
message: `j` is not a defined word, primitive or local.
actual: j
hint: `j` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { j } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len count-dist };

: count-dist
  (forall ρ; ρ seen:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  idx len prim >=
  [ seen prim seq-int.len ]
  [ xs idx prim seq-int.at dup seen is-in [ drop ] [ seen prim seq-int.push ] if
    idx 1 prim + count-dist ]
  if;

: is-in
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { val seq } { 0 seq prim seq-int.len check-in };

: check-in
  (forall ρ; ρ idx:Int^many len:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  idx len prim >=
  [ false ]
  [ seq idx prim seq-int.at val prim = [ true ] [ idx 1 prim + check-in ] if ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  count-distinct;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: count-distinct
at: line 3, column 58
message: `count-dist` in `count-distinct` takes 4 values (seen:Seq Int, idx:Int, len:Int, xs:Seq Int), bottom to top, but only 2 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int) and the result of `prim seq-int.len` (Int). `count-distinct` calls `count-dist`, which has an error of its own; this report assumes `count-dist` keeps its stack effect.
hint: Push the 2 missing values before `count-dist`. The local here, `xs`, is not a value on the stack: writing a local's name pushes its value.

error 2 of 4
code: firth.name.unresolved
word: count-dist
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { seen idx len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 4
code: firth.type.stack-underflow
word: is-in
at: line 15, column 47
message: `check-in` in `is-in` takes 4 values (idx:Int, len:Int, seq:Seq Int, val:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the result of `prim seq-int.len` (Int). `is-in` calls `check-in`, which has an error of its own; this report assumes `check-in` keeps its stack effect.
hint: Push the 2 missing values before `check-in`. The locals here, `val` and `seq`, are not values on the stack: writing a local's name pushes its value.

error 4 of 4
code: firth.name.unresolved
word: check-in
at: line 19, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx len seq val } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-sorted
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  swap locals { xs ys } { prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  i xlen prim >=
  [ j ylen prim < [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-loop ] [ result ] if ]
  [ j ylen prim >= [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-loop ]
    [ xs i prim seq-int.at ys j prim seq-int.at prim <= 
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-loop ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-loop ]
      if ]
    if ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  merge-sorted;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: merge-sorted
at: line 3, column 90
message: `merge-loop` in `merge-sorted` takes 7 values (result:Seq Int, i:Int, j:Int, xlen:Int, ylen:Int, xs:Seq Int, ys:Seq Int), bottom to top, but only 5 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int), `0` (Int), `0` (Int), the result of `prim seq-int.len` (Int) and the result of `prim seq-int.len` (Int). `merge-sorted` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
hint: Push the 2 missing values before `merge-loop`. The locals here, `xs` and `ys`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.name.unresolved
word: merge-loop
at: line 7, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result i j xlen ylen xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n extract-digits ] if;

: extract-digits
  (forall ρ; ρ result:Seq Int^many num:Int^many n:Int^many -- ρ final:Seq Int^many)
  num 0 prim <=
  [ result ]
  [ num 10 prim mod result prim seq-int.push num 10 prim div extract-digits ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  digits;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 81
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: primes-up-to
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 sieve-primes };

: sieve-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  candidate n prim <=
  [ candidate is-prime [ result candidate prim seq-int.push ] [ result ] if
    candidate 1 prim + sieve-primes ]
  [ result ]
  if;

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  num 2 prim < [ false ] 
  [ num 2 prim = [ true ]
    [ num 2 prim mod 0 prim = [ false ] [ 2 check-divisors ] if ]
    if ]
  if;

: check-divisors
  (forall ρ; ρ divisor:Int^many num:Int^many -- ρ result:Bool^many)
  divisor divisor prim * num prim > [ true ]
  [ num divisor prim mod 0 prim = [ false ] [ divisor 1 prim + check-divisors ] if ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  primes-up-to;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: primes-up-to
at: line 3, column 39
message: `sieve-primes` in `primes-up-to` takes 3 values (result:Seq Int, candidate:Int, n:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int) and `2` (Int). `primes-up-to` calls `sieve-primes`, which has an error of its own; this report assumes `sieve-primes` keeps its stack effect.
hint: Push the missing value before `sieve-primes`. The local here, `n`, is not a value on the stack: writing a local's name pushes its value.

error 2 of 4
code: firth.name.unresolved
word: sieve-primes
at: line 7, column 3
message: `candidate` is not a defined word, primitive or local.
actual: candidate
hint: `candidate` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result candidate n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 4
code: firth.name.unresolved
word: is-prime
at: line 15, column 3
message: `num` is not a defined word, primitive or local.
actual: num
hint: `num` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { num } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 4 of 4
code: firth.name.unresolved
word: check-divisors
at: line 23, column 3
message: `divisor` is not a defined word, primitive or local.
actual: divisor
hint: `divisor` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { divisor num } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  swap locals { xs k } { prim seq-int.empty 0 k build-counts };

: build-counts
  (forall ρ; ρ result:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  idx k prim >=
  [ result ]
  [ 0 xs count-value-eq result prim seq-int.push idx 1 prim + build-counts ]
  if;

: count-value-eq
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx xs } { 0 xs prim seq-int.len count-matches };

: count-matches
  (forall ρ; ρ i:Int^many len:Int^many count:Int^many xs:Seq Int^many idx:Int^many -- ρ final:Int^many)
  i len prim >=
  [ count ]
  [ xs i prim seq-int.at idx prim = [ count 1 prim + ] [ count ] if
    i 1 prim + count-matches ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  histogram;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: histogram
at: line 3, column 49
message: `build-counts` in `histogram` takes 4 values (result:Seq Int, idx:Int, k:Int, xs:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `k` (Seq Int). `histogram` calls `build-counts`, which has an error of its own; this report assumes `build-counts` keeps its stack effect.
hint: Push the missing value before `build-counts`. The locals here, `xs` and `k`, are not values on the stack: writing a local's name pushes its value.

error 2 of 4
code: firth.name.unresolved
word: build-counts
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx k xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 4
code: firth.name.locals-order
word: count-value-eq
at: line 14, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { count idx xs }` in `count-value-eq` gives `count` the value the stack effect calls `idx` (Int), `idx` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int).
actual: count-value-eq
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { count idx xs k }` in `count-value-eq`: the block takes the inputs from the top of the stack, so for each name the stack effect declares to hold the value it gives that name, the block must bind every input from the deepest such name up to the top. Then start the body with `k`: the old block left 1 value on the stack for the body, and the new block binds every input, so the body pushes the input none of the old names stood for. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `count-matches`, which has an error of its own, keeps its stack effect.

error 4 of 4
code: firth.name.unresolved
word: count-matches
at: line 18, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len count xs idx } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { xs insertion-sort } };

: insertion-sort
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  i len prim >=
  [ xs ]
  [ i insert-element insertion-sort ]
  if;

: insert-element
  (forall ρ; ρ idx:Int^many xs:Seq Int^many len:Int^many -- ρ updated:Seq Int^many)
  locals { idx xs } { idx find-position xs prim seq-int.set };

: find-position
  (forall ρ; ρ j:Int^many idx:Int^many xs:Seq Int^many -- ρ final-pos:Int^many)
  j 0 prim <=
  [ j ]
  [ xs j 1 prim - prim seq-int.at xs idx prim seq-int.at prim > 
    [ xs xs j 1 prim - prim seq-int.at j prim seq-int.set j 1 prim - find-position ]
    [ j ]
    if ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  sort;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: sort
at: line 3, column 59
message: `insertion-sort` in `sort` takes 3 values (i:Int, len:Int, xs:Seq Int), bottom to top, but only 1 value is on the stack before it: `xs` (Seq Int). `sort` calls `insertion-sort`, which has an error of its own; this report assumes `insertion-sort` keeps its stack effect.
hint: Push the 2 missing values before `insertion-sort`. The locals here, `len` and `xs`, are not values on the stack: writing a local's name pushes its value.

error 2 of 4
code: firth.name.unresolved
word: insertion-sort
at: line 7, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 4
code: firth.name.locals-order
word: insert-element
at: line 14, column 12
message: A `locals` block binds the word's inputs in a different order from its stack effect: `locals { idx xs }` in `insert-element` gives `idx` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `len` (Int).
actual: insert-element
hint: A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right. Write `locals { idx xs len }` in `insert-element`: the block takes the inputs from the top of the stack, so for each name the stack effect declares to hold the value it gives that name, the block must bind every input from the deepest such name up to the top. Then start the body with `len`: the old block left 1 value on the stack for the body, and the new block binds every input, so the body pushes the input none of the old names stood for. Swapping values with `swap` would not help, because the names are what is wrong. That edit was checked assuming `find-position`, which has an error of its own, keeps its stack effect.

error 4 of 4
code: firth.name.unresolved
word: find-position
at: line 18, column 3
message: `j` is not a defined word, primitive or local.
actual: j
hint: `j` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { j idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap locals { start txs } { start 0 0 txs prim seq-int.len apply-txs };

: apply-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  idx len prim >=
  [ balance rejected ]
  [ txs idx prim seq-int.at dup balance prim + 0 prim < 
    [ drop rejected 1 prim + ]
    [ balance prim + rejected ]
    if
    idx 1 prim + apply-txs ]
  if;

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  ledger;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: ledger
at: line 3, column 62
message: `apply-txs` in `ledger` takes 6 values (balance:Int, rejected:Int, idx:Int, len:Int, start:Int, txs:Seq Int), bottom to top, but only 4 values are on the stack before it, bottom to top: `start` (Seq Int), `0` (Int), `0` (Int) and the result of `prim seq-int.len` (Int). `ledger` calls `apply-txs`, which has an error of its own; this report assumes `apply-txs` keeps its stack effect.
hint: Push the 2 missing values before `apply-txs`. The locals here, `start` and `txs`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.name.unresolved
word: apply-txs
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { balance rejected idx len start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-batch
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  swap swap swap locals { stock items qtys whole } 
  { prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len process-orders };

: process-orders
  (forall ρ; ρ stock-left:Seq Int^many alloc-left:Seq Int^many reason-left:Seq Int^many idx:Int^many len:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-alloc:Seq Int^many final-reason:Seq Int^many)
  idx len prim >=
  [ stock-left alloc-left reason-left ]
  [ items idx prim seq-int.at dup stock swap prim seq-int.at locals { item r qty whole-flag } 
    { qtys idx prim seq-int.at dup r prim <= 
      [ r prim - stock-left prim seq-int.push alloc-left qty prim seq-int.push reason-left 0 prim seq-int.push ]
      [ r 0 prim = 
        [ 0 alloc-left prim seq-int.push reason-left 2 prim seq-int.push ]
        [ whole-flag [ 0 alloc-left prim seq-int.push reason-left 3 prim seq-int.push ]
          [ r stock-left prim seq-int.push alloc-left r prim seq-int.push reason-left 1 prim seq-int.push ]
          if ]
        if ]
      if
    idx 1 prim + process-orders ] ]
  if;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  allocate-batch;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 20, column 33
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
