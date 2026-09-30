Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs index max-val } {
    index xs prim seq-int.len prim >=
    [ max-val ]
    [ xs index 1 prim + max-val xs index prim seq-int.at [ max-val prim < ] [ xs index prim seq-int.at ] [ max-val ] if max-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs 0 prim seq-int.at 1 max-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 7, column 5
message: The two branches of the `if` in `max-loop` whose true branch is `[ max-val ]` leave different numbers of values. The true branch leaves `max-val`; the false branch leaves 3 values, bottom to top: `xs`, the result of `prim +` and the result of `max-loop`.
hint: The false branch leaves 2 values more than the true branch: `xs` and the result of `prim +` are left below the result of `max-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
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
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k index count } {
    index xs prim seq-int.len prim >=
    [ count ]
    [ xs k index 1 prim + [ xs index prim seq-int.at k prim < ] [ count 1 prim + ] [ count ] if count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  xs k 0 0 count-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: count-loop
at: line 6, column 94
message: `if` in `count-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int Int [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: search-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs x index } {
    index xs prim seq-int.len prim >=
    [ -1 ]
    [ [ xs index prim seq-int.at x prim = ] [ index ] [ xs x index 1 prim + search-loop ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  xs x 0 search-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: search-loop
at: line 6, column 91
message: `if` in `search-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs index result } {
    index 0 prim <
    [ result ]
    [ xs index 1 prim - result xs index prim seq-int.at prim seq-int.push reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  xs xs prim seq-int.len prim seq-int.empty reverse-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 12, column 3
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
  (forall ρ; ρ xs:Seq Int^many index:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs index sum result } {
    index xs prim seq-int.len prim >=
    [ result ]
    [ xs index 1 prim + sum xs index prim seq-int.at prim + result sum prim seq-int.push prefix-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  xs 0 0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 12, column 3
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
: filter-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs index result } {
    index xs prim seq-int.len prim >=
    [ result ]
    [ [ xs index prim seq-int.at 0 prim > ] [ xs index prim seq-int.at prim seq-int.push ] [ ] if xs index 1 prim + result filter-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  xs 0 prim seq-int.empty filter-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: filter-loop
at: line 6, column 72
message: `prim seq-int.push` in `filter-loop` takes 2 values (the sequence (Seq Int) and the value pushed (Int)), bottom to top, but only 1 value is on the stack before it: the result of `prim seq-int.at` (Int).
hint: Push the missing value before `prim seq-int.push`. The locals here, `xs`, `index` and `result`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
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
: check-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many -- ρ sorted:Bool^many)
  locals { xs index } {
    index xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [ [ xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim > ] [ false ] [ xs index 1 prim + check-loop ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs 0 check-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: check-loop
at: line 6, column 120
message: `if` in `check-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many index:Int^many product:Int^many -- ρ result:Int^many)
  locals { xs ys index product } {
    index xs prim seq-int.len prim >=
    [ product ]
    [ xs ys index 1 prim + product xs index prim seq-int.at ys index prim seq-int.at prim * prim + dot-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  xs ys 0 0 dot-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 12, column 3
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
: check-all-loop
  (forall ρ; ρ flags:Seq Bool^many index:Int^many -- ρ all:Bool^many)
  locals { flags index } {
    index flags prim seq-bool.len prim >=
    [ true ]
    [ [ flags index prim seq-bool.at prim not ] [ false ] [ flags index 1 prim + check-all-loop ] if ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  flags 0 check-all-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: check-all-loop
at: line 6, column 99
message: `if` in `check-all-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
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
  (forall ρ; ρ xs:Seq Int^many index:Int^many current-run:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs index current-run max-run } {
    index xs prim seq-int.len prim >=
    [ [ current-run max-run prim > ] [ current-run ] [ max-run ] if ]
    [ [ xs index prim seq-int.at xs index 1 prim - prim seq-int.at prim = ] [ xs index 1 prim + current-run 1 prim + max-run run-loop ] [ xs index 1 prim + 1 [ current-run max-run prim > ] [ current-run ] [ max-run ] if run-loop ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs 1 1 0 run-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: run-loop
at: line 5, column 66
message: `if` in `run-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
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
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim >=
    [ xs i 1 prim + target inner-loop2 ]
    [ [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = ] [ true ] [ xs target i j 1 prim + inner-loop ] if ]
    if
  };

: inner-loop2
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim >=
    [ false ]
    [ xs target i i 1 prim + inner-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  xs target 0 inner-loop2;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: inner-loop
at: line 6, column 121
message: `if` in `inner-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 3
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
: count-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs index count } {
    index xs prim seq-int.len prim >=
    [ count ]
    [ xs index 1 prim + [ xs index prim seq-int.at count-contains ] [ count 1 prim + ] [ count ] if count-loop ]
    if
  };

: count-contains
  (forall ρ; ρ val:Int^many -- ρ result:Bool^many)
  false;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  xs 0 0 count-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-bool
word: count-loop
at: line 6, column 98
message: `if` in `count-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ]. `count-loop` calls `count-contains`, which has an error of its own; this report assumes `count-contains` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 3
code: firth.type.declared-effect-mismatch
word: count-contains
at: line 11, column 3
message: `count-contains` declares that it leaves ρ Bool but its body leaves ρ Int Bool.
expected: ρ Bool
actual: ρ Int Bool
hint: The body leaves 1 extra value on top (Bool). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 16, column 3
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    [ i xs prim seq-int.len prim >= ] [ j ys prim seq-int.len prim >= ] if
    [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop ]
    [ i xs prim seq-int.len prim >= [ result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop ] [ [ xs i prim seq-int.at ys j prim seq-int.at prim <= ] [ result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop ] [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop ] if ] if ]
    if;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 7, column 7
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many digits:Seq Int^many -- ρ result:Seq Int^many)
  locals { n digits } {
    n 0 prim =
    [ digits ]
    [ n 10 prim mod digits swap prim seq-int.push n 10 prim div digit-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n prim seq-int.empty digit-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digit-loop
at: line 6, column 65
message: `digit-loop` in `digit-loop` takes n:Int, digits:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: The top value, the result of `prim div` (Int), is not what `digit-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
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
: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  num 2 prim <
  [ false ]
  [ num 2 prim = [ true ] [ check-prime-loop num 2 ] if ]
  if;

: check-prime-loop
  (forall ρ; ρ num:Int^many div:Int^many -- ρ result:Bool^many)
  locals { num div } {
    div div prim * num prim >
    [ true ]
    [ [ num div prim mod 0 prim = ] [ false ] [ num div 1 prim + check-prime-loop ] if ]
    if
  };

: collect-loop
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n current result } {
    current n prim > 
    [ result ]
    [ [ current is-prime ] [ result current prim seq-int.push n current 1 prim + collect-loop ] [ n current 1 prim + collect-loop ] if ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  n 2 prim seq-int.empty collect-loop;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.name.unresolved
word: is-prime
at: line 3, column 3
message: `num` is not a defined word, primitive or local.
actual: num
hint: `num` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { num } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 4
code: firth.type.expected-bool
word: check-prime-loop
at: line 13, column 85
message: `if` in `check-prime-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 4
code: firth.type.branch-mismatch
word: collect-loop
at: line 22, column 133
message: In the false branch of the `if` in `collect-loop` whose true branch is `[ result current prim seq-int.push n current 1 ...`, `collect-loop` needs 3 values (n:Int, current:Int, result:Seq Int), but the branch has pushed only 2 values before it (`n` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `collect-loop`, exactly the values it takes, in this order: n:Int, current:Int, result:Seq Int. The branch already pushes `n` and the result of `prim +`, in the place of the first 2 (n:Int, current:Int). Push the last one (result:Seq Int) after them by writing the local of that name, `result`: write `n current 1 prim + result collect-loop` in place of `n current 1 prim + collect-loop` on line 22, column 99. With that edit, the next error in `collect-loop` is at line 22, column 82. If `collect-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake. That edit was checked assuming `is-prime`, which has an error of its own, keeps its stack effect.

error 4 of 4
code: firth.name.unresolved
word: main
at: line 28, column 3
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
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k index counts } {
    index xs prim seq-int.len prim >=
    [ counts ]
    [ xs k index 1 prim + counts xs index prim seq-int.at prim dup xs index prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  xs k 0 prim seq-int.empty count-loop;

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 6, column 64
message: Unexpected `dup`, expected `primitive name`.
expected: primitive name
actual: dup
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ val:Int^many sorted:Seq Int^many index:Int^many -- ρ result:Seq Int^many)
  locals { val sorted index } {
    index sorted prim seq-int.len prim >= [ sorted val prim seq-int.push ] [ [ sorted index prim seq-int.at val prim > ] [ sorted index val prim seq-int.set val index 1 prim + insert-loop ] [ sorted val prim seq-int.push ] if ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs index sorted } {
    index xs prim seq-int.len prim >=
    [ sorted ]
    [ xs index 1 prim + xs index prim seq-int.at sorted 0 insert-loop sort-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: insert-loop
at: line 4, column 177
message: `insert-loop` in `insert-loop` takes val:Int, sorted:Seq Int, index:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), `val` (Int) and the result of `prim +` (Int).
expected: .. Int Seq Int Int
actual: .. Seq Int Int Int
hint: These are the values `insert-loop` takes, in another order. To push them in its order, write `val sorted index val prim seq-int.set index 1 prim +` in place of `sorted index val prim seq-int.set val index 1 prim +` on line 4. With that edit, the next error in `insert-loop` is at line 4, column 224.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 18, column 3
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
: apply-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many index:Int^many balance:Int^many rejected:Int^many -- ρ final-balance:Int^many rejected-count:Int^many)
  locals { start txs index balance rejected } {
    index txs prim seq-int.len prim >=
    [ balance rejected ]
    [ [ balance txs index prim seq-int.at prim + 0 prim < ] [ txs index 1 prim + balance rejected 1 prim + apply-loop ] [ txs index 1 prim + balance txs index prim seq-int.at prim + rejected apply-loop ] if ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  start txs 0 start 0 apply-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: apply-loop
at: line 7, column 5
message: In the false branch of the `if` in `apply-loop` whose true branch is `[ balance rejected ]`, `apply-loop` (inside a quotation in that branch) needs 5 values (start:Int, txs:Seq Int, index:Int, balance:Int, rejected:Int), but the branch has pushed only 4 values before it (`txs`, the result of `prim +`, `balance` or the result of `prim +` and the result of `prim +` or `rejected`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `apply-loop`, exactly the values it takes, in this order: start:Int, txs:Seq Int, index:Int, balance:Int, rejected:Int. The branch already pushes `txs`, the result of `prim +`, `balance` or the result of `prim +` and the result of `prim +` or `rejected`, in the place of the last 4 (txs:Seq Int, index:Int, balance:Int, rejected:Int): keep each where it has that type and replace it where it does not. Then push the first one (start:Int) before them, for example by writing the locals that hold it. If `apply-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `start` is not a defined word, primitive or local.
actual: start
hint: `start` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many item-idx:Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many order-allocated:Int^many order-reason:Int^many result-stock:Seq Int^many result-allocated:Seq Int^many result-reasons:Seq Int^many -- ρ out-stock:Seq Int^many out-allocated:Seq Int^many out-reasons:Seq Int^many)
  locals { stock items item-idx qtys whole order-idx order-allocated order-reason result-stock result-allocated result-reasons } {
    order-idx qtys prim seq-int.len prim >=
    [ result-stock result-allocated result-reasons ]
    [ items order-idx prim seq-int.at [ stock items order-idx prim seq-int.at prim seq-int.at qtys order-idx prim seq-int.at prim > ] [ stock items order-idx prim seq-int.at qtys order-idx prim seq-int.at prim seq-int.set result-stock qtys order-idx prim seq-int.at prim seq-int.push result-reasons 0 prim seq-int.push process-order ] [ stock items order-idx prim seq-int.at prim seq-int.at 0 prim = [ result-stock result-allocated result-reasons 0 prim seq-int.push ] [ whole order-idx prim seq-bool.at [ result-stock result-allocated result-reasons 3 prim seq-int.push ] [ stock items order-idx prim seq-int.at stock items order-idx prim seq-int.at prim seq-int.at prim seq-int.set result-stock stock items order-idx prim seq-int.at prim seq-int.at prim seq-int.push result-reasons 1 prim seq-int.push ] if ] if ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock items 0 qtys whole 0 0 0 stock prim seq-int.empty prim seq-int.empty process-order;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 3
message: `}` cannot start an item in a word's body.
actual: }
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
