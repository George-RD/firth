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
  0 0 [ prim seq-int.len prim < ] [ dup prim seq-int.at swap 1 prim + swap ] sum-loop;

: sum-loop
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ total:Int^many)
  call { dup acc prim + swap } if [ acc ] [ idx xs sum-loop ] if;

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 7, column 10
message: Unexpected `dup`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: dup
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  dup 0 prim seq-int.at swap 1 0 max-loop;

: max-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many maxval:Int^many -- ρ largest:Int^many)
  dup xs prim seq-int.len prim <
  [ xs idx prim seq-int.at dup maxval prim < [ drop ] [ swap drop ] if idx 1 prim + xs swap max-loop ]
  [ drop ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: seq-max
at: line 2, column 3
message: `seq-max` declares that it leaves ρ Int but its body leaves ρ Int Int. `seq-max` calls `max-loop`, which has an error of its own; this report assumes `max-loop` keeps its stack effect.
expected: ρ Int
actual: ρ Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.unresolved
word: max-loop
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs idx maxval } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k } { 0 0 xs k count-helper };

: count-helper
  (forall ρ; ρ xs:Seq Int^many cnt:Int^many idx:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs cnt idx k }
  idx xs prim seq-int.len prim <
  [ xs idx prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if idx 1 prim + xs k count-helper ]
  [ cnt ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `idx`, expected `{`.
expected: {
actual: idx
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x } { xs 0 x -1 find-helper };

: find-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many x:Int^many result:Int^many -- ρ index:Int^many)
  locals { xs idx x result }
  result -1 prim = idx xs prim seq-int.len prim < prim and
  [ xs idx prim seq-int.at x prim = [ idx ] [ idx 1 prim + x result xs find-helper ] if ]
  [ result ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `result`, expected `{`.
expected: {
actual: result
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty swap xs prim seq-int.len 1 prim - rev-loop;

: rev-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  dup 0 prim <
  [ result ]
  [ xs idx prim seq-int.at result prim seq-int.push idx 1 prim - xs rev-loop ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: reverse
at: line 3, column 27
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: rev-loop
at: line 8, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result xs idx } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-sums
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 xs prefix-helper;

: prefix-helper
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  idx xs prim seq-int.len prim <
  [ xs idx prim seq-int.at sum prim + dup result prim seq-int.push idx 1 prim + xs prefix-helper ]
  [ result ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: prefix-sums
at: line 3, column 26
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: prefix-helper
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result sum idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 xs filter-helper;

: filter-helper
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  idx xs prim seq-int.len prim <
  [ xs idx prim seq-int.at dup 0 prim < prim not [ result prim seq-int.push ] [ drop ] if idx 1 prim + xs filter-helper ]
  [ result ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: keep-positive
at: line 3, column 24
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: filter-helper
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  dup prim seq-int.len dup 0 prim = swap 1 prim = prim or
  [ true ]
  [ true 0 xs check-sorted ]
  if;

: check-sorted
  (forall ρ; ρ ok:Bool^many idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  ok idx 1 prim + xs prim seq-int.len prim < prim and
  [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < prim not idx 1 prim + xs check-sorted ]
  [ ok ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: is-sorted
at: line 5, column 12
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: check-sorted
at: line 10, column 3
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
: dot
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 xs ys dot-helper;

: dot-helper
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  idx xs prim seq-int.len prim <
  [ xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + idx 1 prim + xs ys dot-helper ]
  [ sum ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: dot
at: line 3, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: dot-helper
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { sum idx xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true 0 flags check-all;

: check-all
  (forall ρ; ρ acc:Bool^many idx:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  acc idx flags prim seq-bool.len prim < prim and
  [ flags idx prim seq-bool.at acc prim and idx 1 prim + flags check-all ]
  [ acc ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: all-true
at: line 3, column 10
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: check-all
at: line 7, column 3
message: `acc` is not a defined word, primitive or local.
actual: acc
hint: `acc` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { acc idx flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  dup prim seq-int.len 0 prim =
  [ 0 ]
  [ 0 1 0 xs prim seq-int.len run-helper ]
  if;

: run-helper
  (forall ρ; ρ max-len:Int^many cur-len:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ length:Int^many)
  idx 1 prim + len prim <
  [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim = [ cur-len 1 prim + ] [ 1 ] if dup max-len prim < [ max-len ] [ ] if idx 1 prim + len xs run-helper ]
  [ cur-len max-len prim < [ max-len ] [ cur-len ] if ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: longest-run
at: line 5, column 11
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: run-helper
at: line 10, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { max-len cur-len idx len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false 0 xs swap check-pairs;

: check-pairs
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  found prim not i xs prim seq-int.len 1 prim - prim < prim and
  [ i 1 prim + xs target check-inner [ true ] [ i 1 prim + xs target check-pairs ] if ]
  [ found ]
  if;

: check-inner
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  j xs prim seq-int.len prim <
  [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + xs target check-inner ] if ]
  [ false ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: has-pair-sum
at: line 3, column 11
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.name.unresolved
word: check-pairs
at: line 7, column 3
message: `found` is not a defined word, primitive or local.
actual: found
hint: `found` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { found i xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: check-inner
at: line 14, column 3
message: `j` is not a defined word, primitive or local.
actual: j
hint: `j` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i j xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 xs count-dist;

: count-dist
  (forall ρ; ρ cnt:Int^many idx:Int^many xs:Seq Int^many -- ρ count:Int^many)
  idx xs prim seq-int.len prim <
  [ xs idx prim seq-int.at 0 idx count-check-dup [ cnt 1 prim + ] [ cnt ] if idx 1 prim + xs count-dist ]
  [ cnt ]
  if;

: count-check-dup
  (forall ρ; ρ val:Int^many chk-idx:Int^many idx:Int^many xs:Seq Int^many -- ρ is-dup:Bool^many)
  chk-idx idx prim <
  [ xs chk-idx prim seq-int.at val prim = [ true ] [ chk-idx 1 prim + idx xs count-check-dup ] if ]
  [ false ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: count-distinct
at: line 3, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.name.unresolved
word: count-dist
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { cnt idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: count-check-dup
at: line 14, column 3
message: `chk-idx` is not a defined word, primitive or local.
actual: chk-idx
hint: `chk-idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { val chk-idx idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-sorted
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 xs ys merge-loop;

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
  [ xs i prim seq-int.at ys j prim seq-int.at prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j ] [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + ] if xs ys merge-loop ]
  [ i xs prim seq-int.len prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys merge-loop ] [ j ys prim seq-int.len prim < [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys merge-loop ] [ result ] if ] if ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: merge-sorted
at: line 3, column 26
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: merge-loop
at: line 7, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result i j xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim =
  [ { 0 } ]
  [ prim seq-int.empty swap digits-helper ]
  if;

: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim >
  [ n 10 prim mod result prim seq-int.push n 10 prim div digits-helper ]
  [ result ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: digits
at: line 6, column 3
message: The two branches of the `if` in `digits` whose true branch is `[ { 0 } ]` leave different numbers of values. The true branch leaves `a literal`; the false branch takes the input `n` from below the `if` and leaves the result of `digits-helper`. `digits` calls `digits-helper`, which has an error of its own; this report assumes `digits-helper` keeps its stack effect.
hint: The false branch takes the input `n` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: digits-helper
at: line 10, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: primes-up-to
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 n prime-loop;

: prime-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  i n prim <
  [ i 2 i prime-check [ result i prim seq-int.push ] [ result ] if i 1 prim + n prime-loop ]
  [ result ]
  if;

: prime-check
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ is-prime:Bool^many)
  divisor divisor prim * candidate prim < prim not
  [ true ]
  [ candidate divisor prim mod 0 prim = [ false ] [ divisor 1 prim + prime-check ] if ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: primes-up-to
at: line 3, column 24
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.name.unresolved
word: prime-loop
at: line 7, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result i n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: prime-check
at: line 14, column 3
message: `divisor` is not a defined word, primitive or local.
actual: divisor
hint: `divisor` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { candidate divisor } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty swap 0 hist-init;

: hist-init
  (forall ρ; ρ init:Seq Int^many idx:Int^many k:Int^many -- ρ counts:Seq Int^many)
  idx k prim <
  [ init 0 prim seq-int.push idx 1 prim + k hist-init ]
  [ ]
  if;

: hist-loop
  (forall ρ; ρ counts:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  idx xs prim seq-int.len prim <
  [ xs idx prim seq-int.at dup counts swap prim seq-int.at 1 prim + prim seq-int.set idx 1 prim + xs hist-loop ]
  [ counts ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.declared-effect-mismatch
word: histogram
at: line 2, column 3
message: `histogram` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int. `histogram` calls `hist-init`, which has an error of its own; this report assumes `hist-init` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.name.unresolved
word: hist-init
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { init idx k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: hist-loop
at: line 14, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { counts idx xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty 0 xs prim seq-int.len sort-loop;

: sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  i len prim <
  [ xs i prim seq-int.at dup 0 i find-insert-pos result prim seq-int.push i 1 prim + len xs sort-loop ]
  [ result ]
  if;

: find-insert-pos
  (forall ρ; ρ val:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  j result prim seq-int.len prim > result j 1 prim - prim seq-int.at val prim > prim and
  [ result j 1 prim - dup prim seq-int.at result j prim seq-int.set j 1 prim - find-insert-pos ]
  [ result j val prim seq-int.set ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: sort
at: line 3, column 24
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.name.unresolved
word: sort-loop
at: line 7, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result i len xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: find-insert-pos
at: line 14, column 3
message: `j` is not a defined word, primitive or local.
actual: j
hint: `j` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { val j result } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 txs ledger-loop;

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  idx txs prim seq-int.len prim <
  [ txs idx prim seq-int.at dup balance prim + dup 0 prim < [ drop 1 prim + idx 1 prim + txs ledger-loop ] [ balance rejected idx 1 prim + txs ledger-loop ] if ]
  [ balance rejected ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: ledger
at: line 3, column 7
message: `txs` is not a defined word, primitive or local.
actual: txs
hint: `txs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: ledger-loop
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { balance rejected idx txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-batch
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 items qtys whole alloc-loop;

: alloc-loop
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  idx items prim seq-int.len prim <
  [ items idx prim seq-int.at stock swap prim seq-int.at qtys idx prim seq-int.at whole idx prim seq-bool.at decide-alloc idx stock items qtys whole alloc-loop ]
  [ stock alloc reasons ]
  if;

: decide-alloc
  (forall ρ; ρ item-stock:Int^many qty:Int^many whole-order:Bool^many idx:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many)
  qty item-stock prim < qty item-stock prim = prim not prim not prim and
  [ alloc qty prim seq-int.push reasons 0 prim seq-int.push items idx prim seq-int.at stock swap qty prim - prim seq-int.set ]
  [ qty item-stock prim = prim not [ item-stock 0 prim = [ alloc 0 prim seq-int.push reasons 2 prim seq-int.push stock ] [ whole-order [ alloc 0 prim seq-int.push reasons 3 prim seq-int.push stock ] [ alloc item-stock prim seq-int.push reasons 1 prim seq-int.push items idx prim seq-int.at stock swap item-stock prim - prim seq-int.set ] if ] if ] [ alloc qty prim seq-int.push reasons 0 prim seq-int.push items idx prim seq-int.at stock swap qty prim - prim seq-int.set ] if ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: allocate-batch
at: line 3, column 43
message: `items` is not a defined word, primitive or local.
actual: items
hint: `items` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.name.unresolved
word: alloc-loop
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock alloc reasons idx items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: decide-alloc
at: line 14, column 3
message: `qty` is not a defined word, primitive or local.
actual: qty
hint: `qty` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { item-stock qty whole-order idx stock items qtys whole alloc reasons } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
