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
  locals { xs } { 0 helper-seq-sum };

: helper-seq-sum
  (forall ρ; ρ acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  dup prim seq-int.len locals { len acc xs } {
    [ drop ] [ len prim seq-int.at acc prim + locals { new-acc len acc xs } { new-acc helper-continue } call ] if
  };

: helper-continue
  (forall ρ; ρ i:Int^many -- ρ)
  ;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 21
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Seq Int [ .. Int Seq Int -- .. Int ]). `main` calls `helper-seq-sum`, which has an error of its own; this report assumes `helper-seq-sum` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 3
code: firth.elaboration.untracked-local
word: helper-seq-sum
at: line 7, column 41
message: The local `xs` is used after `call` on line 8 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

error 3 of 3
code: firth.type.declared-effect-mismatch
word: helper-continue
at: line 12, column 3
message: `helper-continue` declares that it leaves ρ but its body leaves ρ Int.
expected: ρ
actual: ρ Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { 0 xs prim seq-int.at helper-max-loop };

: helper-max-loop
  (forall ρ; ρ idx:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  dup prim seq-int.len locals { len idx max xs } {
    [ max ] [ idx 1 prim + dup prim seq-int.at locals { next-val idx max xs len } { next-val max prim > [ next-val ] [ max ] if helper-max-loop } call ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 40
message: `helper-max-loop` needs more values than the stack holds here. `main` calls `helper-max-loop`, which has an error of its own; this report assumes `helper-max-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-max-loop` and in what order.

error 2 of 2
code: firth.name.unresolved-effect
word: helper-max-loop
at: line 8, column 98
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 helper-count-loop };

: helper-count-loop
  (forall ρ; ρ idx:Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  dup xs prim seq-int.len locals { len idx count xs k } {
    [ count ] [ idx xs prim seq-int.at locals { val idx count xs k len } { val k prim < [ count 1 prim + ] [ count ] if idx 1 prim + helper-count-loop } ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 23
message: `helper-count-loop` needs more values than the stack holds here. `main` calls `helper-count-loop`, which has an error of its own; this report assumes `helper-count-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-count-loop` and in what order.

error 2 of 2
code: firth.name.unresolved
word: helper-count-loop
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx count xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 helper-find-index };

: helper-find-index
  (forall ρ; ρ idx:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  dup xs prim seq-int.len locals { len idx xs x } {
    [ idx xs prim seq-int.len prim = [ -1 ] [ idx xs prim seq-int.at x prim = [ idx ] [ idx 1 prim + helper-find-index ] if ] if ] [ idx ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 23
message: `helper-find-index` needs more values than the stack holds here. `main` calls `helper-find-index`, which has an error of its own; this report assumes `helper-find-index` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-find-index` and in what order.

error 2 of 2
code: firth.name.unresolved
word: helper-find-index
at: line 7, column 7
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
  locals { xs } { prim seq-int.empty 0 helper-reverse };

: helper-reverse
  (forall ρ; ρ idx:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  dup xs prim seq-int.len locals { len idx result xs } {
    [ result ] [ idx xs prim seq-int.at result prim seq-int.push idx 1 prim + helper-reverse ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 40
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Seq Int [ .. Int Seq Int Seq Int -- .. Seq Int ]). `main` calls `helper-reverse`, which has an error of its own; this report assumes `helper-reverse` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.name.unresolved
word: helper-reverse
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx result xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 helper-prefix };

: helper-prefix
  (forall ρ; ρ idx:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  dup xs prim seq-int.len locals { len idx sum result xs } {
    [ result ] [ idx xs prim seq-int.at sum prim + locals { new-sum idx result xs len } { new-sum result prim seq-int.push idx 1 prim + helper-prefix } ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 42
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Int Seq Int [ .. Int Int Seq Int Seq Int -- .. Seq Int ]). `main` calls `helper-prefix`, which has an error of its own; this report assumes `helper-prefix` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.name.unresolved
word: helper-prefix
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx sum result xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 helper-keep-pos };

: helper-keep-pos
  (forall ρ; ρ idx:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  dup xs prim seq-int.len locals { len idx result xs } {
    [ result ] [ idx xs prim seq-int.at locals { val idx result xs len } { val 0 prim > [ val result prim seq-int.push ] [ result ] if idx 1 prim + helper-keep-pos } ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 40
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Seq Int [ .. Int Seq Int Seq Int -- .. Seq Int ]). `main` calls `helper-keep-pos`, which has an error of its own; this report assumes `helper-keep-pos` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.name.unresolved
word: helper-keep-pos
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx result xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { true 0 helper-is-sorted };

: helper-is-sorted
  (forall ρ; ρ idx:Int^many sorted:Bool^many xs:Seq Int^many -- ρ sorted:Bool^many)
  dup xs prim seq-int.len 1 prim - locals { max-idx idx sorted xs } {
    [ sorted ] [ idx xs prim seq-int.at idx 1 prim + xs prim seq-int.at locals { next curr idx sorted xs max-idx } { curr next prim < [ false ] [ true ] if sorted prim and idx 1 prim + helper-is-sorted } ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 26
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Bool Int Seq Int [ .. Int Bool Seq Int -- .. Bool ]). `main` calls `helper-is-sorted`, which has an error of its own; this report assumes `helper-is-sorted` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.name.unresolved
word: helper-is-sorted
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx sorted xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 helper-dot };

: helper-dot
  (forall ρ; ρ idx:Int^many sum:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  dup xs prim seq-int.len locals { len idx sum xs ys } {
    [ sum ] [ idx xs prim seq-int.at idx ys prim seq-int.at prim * sum prim + idx 1 prim + helper-dot ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 26
message: `helper-dot` needs more values than the stack holds here. `main` calls `helper-dot`, which has an error of its own; this report assumes `helper-dot` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-dot` and in what order.

error 2 of 2
code: firth.name.unresolved
word: helper-dot
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx sum xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 helper-all-true };

: helper-all-true
  (forall ρ; ρ idx:Int^many result:Bool^many flags:Seq Bool^many -- ρ result:Bool^many)
  dup flags prim seq-int.len locals { len idx result flags } {
    [ result ] [ idx flags prim seq-int.at result prim and idx 1 prim + helper-all-true ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 29
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Bool Int Seq Bool [ .. Int Bool Seq Bool -- .. Bool ]). `main` calls `helper-all-true`, which has an error of its own; this report assumes `helper-all-true` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.name.unresolved
word: helper-all-true
at: line 7, column 7
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx result flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 0 1 0 helper-longest-run };

: helper-longest-run
  (forall ρ; ρ idx:Int^many max-run:Int^many curr-run:Int^many prev:Int^many xs:Seq Int^many -- ρ length:Int^many)
  dup xs prim seq-int.len locals { len idx max-run curr-run prev xs } {
    [ max-run curr-run prim > [ curr-run ] [ max-run ] if ] [ idx xs prim seq-int.at locals { curr idx max-run curr-run prev xs len } { curr prev prim = [ curr-run 1 prim + ] [ 1 ] if locals { new-run idx max-run prev xs len } { new-run max-run prim > [ new-run ] [ max-run ] if idx 1 prim + helper-longest-run } ] if ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 314
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 helper-has-pair };

: helper-has-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  [ found ] [ helper-has-pair-inner ] if;

: helper-has-pair-inner
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  i 1 prim + 0 helper-check-j;

: helper-check-j
  (forall ρ; ρ j:Int^many i:Int^many found:Bool^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  ;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: main
at: line 3, column 34
message: `helper-has-pair` needs more values than the stack holds here. `main` calls `helper-has-pair`, which has an error of its own; this report assumes `helper-has-pair` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-has-pair` and in what order.

error 2 of 4
code: firth.name.unresolved
word: helper-has-pair
at: line 7, column 5
message: `found` is not a defined word, primitive or local.
actual: found
hint: `found` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { found i xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 4
code: firth.name.unresolved
word: helper-has-pair-inner
at: line 11, column 3
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { found i xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 4 of 4
code: firth.type.declared-effect-mismatch
word: helper-check-j
at: line 14, column 3
message: `helper-check-j` declares that it leaves ρ Bool but its body leaves ρ Int Int Bool Seq Int Int.
expected: ρ Bool
actual: ρ Int Int Bool Seq Int Int
hint: The body leaves 4 extra values on top (Int Bool Seq Int Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty helper-distinct };

: helper-distinct
  (forall ρ; ρ unique:Seq Int^many xs:Seq Int^many -- ρ count:Int^many)
  0 helper-count-distinct;

: helper-count-distinct
  (forall ρ; ρ idx:Int^many unique:Seq Int^many xs:Seq Int^many -- ρ count:Int^many)
  dup xs prim seq-int.len locals { len idx unique xs } {
    [ unique prim seq-int.len ] [ idx xs prim seq-int.at locals { val idx unique xs len } { val helper-is-in-unique } ] if
  };

: helper-is-in-unique
  (forall ρ; ρ val:Int^many idx:Int^many unique:Seq Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  ;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 38
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Seq Int [ .. Seq Int Seq Int -- .. Int ]). `main` calls `helper-distinct`, which has an error of its own; this report assumes `helper-distinct` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 4
code: firth.type.word-input-mismatch
word: helper-distinct
at: line 7, column 5
message: `helper-count-distinct` in `helper-distinct` takes idx:Int, unique:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `unique` (Seq Int), the input `xs` (Seq Int) and `0` (Int). `helper-distinct` calls `helper-count-distinct`, which has an error of its own; this report assumes `helper-count-distinct` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `helper-count-distinct` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 3 of 4
code: firth.name.unresolved
word: helper-count-distinct
at: line 11, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx unique xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 4 of 4
code: firth.type.declared-effect-mismatch
word: helper-is-in-unique
at: line 16, column 3
message: `helper-is-in-unique` declares that it leaves ρ Int but its body leaves ρ Int Int Seq Int Seq Int Int.
expected: ρ Int
actual: ρ Int Int Seq Int Seq Int Int
hint: The body leaves 4 extra values on top (Int Seq Int Seq Int Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 helper-merge };

: helper-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  dup xs prim seq-int.len dup ys prim seq-int.len locals { len-y len-x result i j xs ys } {
    [ i len-x prim = [ result j ys prim seq-int.at prim seq-int.push j 1 prim + helper-merge ] [ j len-y prim = [ result i xs prim seq-int.at prim seq-int.push i 1 prim + helper-merge ] [ i xs prim seq-int.at j ys prim seq-int.at prim < [ result i xs prim seq-int.at prim seq-int.push i 1 prim + helper-merge ] [ result j ys prim seq-int.at prim seq-int.push j 1 prim + helper-merge ] if ] if ] if ] [ result ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 45
message: `helper-merge` needs more values than the stack holds here. `main` calls `helper-merge`, which has an error of its own; this report assumes `helper-merge` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-merge` and in what order.

error 2 of 2
code: firth.name.unresolved
word: helper-merge
at: line 7, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result i j xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n helper-get-digits };

: helper-get-digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  [ n prim seq-int.empty ] [ n helper-digits-loop ] if;

: helper-digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  dup 0 prim = [ drop ] [ n 10 prim mod result prim seq-int.push n 10 prim div helper-digits-loop ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: helper-get-digits
at: line 7, column 5
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.name.unresolved
word: helper-digits-loop
at: line 11, column 27
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n result } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 helper-find-primes };

: helper-find-primes
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)
  candidate n prim > [ primes ] [ candidate helper-is-prime-check ] if;

: helper-is-prime-check
  (forall ρ; ρ candidate:Int^many primes:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  ;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 39
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Int [ .. Seq Int Int Int -- .. Seq Int ]). `main` calls `helper-find-primes`, which has an error of its own; this report assumes `helper-find-primes` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 3
code: firth.name.unresolved
word: helper-find-primes
at: line 7, column 3
message: `candidate` is not a defined word, primitive or local.
actual: candidate
hint: `candidate` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { primes candidate n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.type.declared-effect-mismatch
word: helper-is-prime-check
at: line 10, column 3
message: `helper-is-prime-check` declares that it leaves ρ Seq Int but its body leaves ρ Int Seq Int Int.
expected: ρ Seq Int
actual: ρ Int Seq Int Int
hint: The body leaves 2 extra values on top (Seq Int Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 prim seq-int.empty helper-init-histogram };

: helper-init-histogram
  (forall ρ; ρ idx:Int^many counts:Seq Int^many xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  idx k prim = [ helper-fill-histogram 0 counts xs ] [ counts 0 prim seq-int.push idx 1 prim + helper-init-histogram ] if;

: helper-fill-histogram
  (forall ρ; ρ idx:Int^many counts:Seq Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  dup xs prim seq-int.len locals { len idx counts xs } {
    [ counts ] [ idx xs prim seq-int.at locals { val idx counts xs len } { val counts prim seq-int.at 1 prim + dup val prim seq-int.set idx 1 prim + helper-fill-histogram } ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 42
message: `helper-init-histogram` needs more values than the stack holds here. `main` calls `helper-init-histogram`, which has an error of its own; this report assumes `helper-init-histogram` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-init-histogram` and in what order.

error 2 of 3
code: firth.name.unresolved
word: helper-init-histogram
at: line 7, column 3
message: `idx` is not a defined word, primitive or local.
actual: idx
hint: `idx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx counts xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.name.unresolved
word: helper-fill-histogram
at: line 11, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { idx counts xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs helper-insertion-sort };

: helper-insertion-sort
  (forall ρ; ρ arr:Seq Int^many -- ρ sorted:Seq Int^many)
  1 arr prim seq-int.len helper-sort-loop;

: helper-sort-loop
  (forall ρ; ρ i:Int^many arr:Seq Int^many -- ρ sorted:Seq Int^many)
  dup arr prim seq-int.len locals { len i arr } {
    [ arr ] [ i arr prim seq-int.at i 1 prim - helper-find-insert-pos ] if
  };

: helper-find-insert-pos
  (forall ρ; ρ j:Int^many key:Int^many i:Int^many arr:Seq Int^many len:Int^many -- ρ sorted:Seq Int^many)
  ;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: helper-insertion-sort
at: line 7, column 5
message: `arr` is not a defined word, primitive or local.
actual: arr
hint: `arr` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { arr } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.name.unresolved
word: helper-sort-loop
at: line 11, column 7
message: `arr` is not a defined word, primitive or local.
actual: arr
hint: `arr` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i arr } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.type.declared-effect-mismatch
word: helper-find-insert-pos
at: line 16, column 3
message: `helper-find-insert-pos` declares that it leaves ρ Seq Int but its body leaves ρ Int Int Int Seq Int Int.
expected: ρ Seq Int
actual: ρ Int Int Int Seq Int Int
hint: The body leaves 4 extra values on top (Int Int Seq Int Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 helper-process-txs };

: helper-process-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  dup txs prim seq-int.len locals { len balance rejected idx start txs } {
    [ balance rejected ] [ idx txs prim seq-int.at locals { tx balance rejected idx start txs len } { balance tx prim + dup 0 prim < [ drop balance rejected 1 prim + ] [ rejected ] if idx 1 prim + helper-process-txs } ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 36
message: `helper-process-txs` needs more values than the stack holds here. `main` calls `helper-process-txs`, which has an error of its own; this report assumes `helper-process-txs` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `helper-process-txs` and in what order.

error 2 of 2
code: firth.name.unresolved
word: helper-process-txs
at: line 7, column 7
message: `txs` is not a defined word, primitive or local.
actual: txs
hint: `txs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { balance rejected idx start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 helper-allocate };

: helper-allocate
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  dup items prim seq-int.len locals { len stock allocated reasons idx items qtys whole } {
    [ stock allocated reasons ] [ idx items prim seq-int.at locals { item-idx stock allocated reasons idx items qtys whole len } { item-idx stock prim seq-int.at locals { current-stock stock allocated reasons idx items qtys whole len item-idx } { idx qtys prim seq-int.at locals { qty stock allocated reasons idx items qtys whole len item-idx current-stock } { idx whole prim seq-int.at locals { whole-flag stock allocated reasons idx items qtys whole len item-idx current-stock qty } { qty current-stock prim <= [ current-stock qty prim - item-idx stock prim seq-int.set qty allocated prim seq-int.push reasons 0 prim seq-int.push ] [ current-stock 0 prim = [ stock qty allocated prim seq-int.push reasons 2 prim seq-int.push ] [ whole-flag [ stock qty allocated prim seq-int.push reasons 3 prim seq-int.push ] [ current-stock item-idx stock prim seq-int.set current-stock allocated prim seq-int.push reasons 1 prim seq-int.push 0 item-idx stock prim seq-int.set ] if ] if ] if idx 1 prim + helper-allocate } ] if } ] if } ] if } ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 512
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
