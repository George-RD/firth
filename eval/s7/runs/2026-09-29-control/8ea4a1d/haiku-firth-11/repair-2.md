Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    xs 1 xs 0 prim seq-int.at max-loop
  };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    [ max ]
    [ xs i prim seq-int.at [ xs i 1 prim + swap max-loop ] [ xs i 1 prim + max max-loop ] xs i prim seq-int.at max prim < if ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: max-loop
at: line 11, column 28
message: `compose` in `max-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Seq Int Int ?t22 Int [ .. Seq Int -- .. Seq Int Seq Int Int ] [ .. Seq Int Int Int -- .. Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

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
    xs k 0 0 count-loop
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    [ count ]
    [ xs k i 1 prim + [ count 1 prim + ] [ count ] xs i prim seq-int.at k prim < if count-loop ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: count-loop
at: line 11, column 82
message: `if` in `count-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int Int [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    xs x 0 index-loop
  };

: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    [ i ]
    [ xs x i 1 prim + index-loop ]
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at x prim = ]
    [ prim not prim not ]
    xs i prim seq-int.len prim <
    if
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: index-loop
at: line 15, column 10
message: `prim seq-int.len` in `index-loop` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool [ .. -- .. Bool ] [ .. Bool -- .. Bool ] Seq Int Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs prim seq-int.empty 0 reverse-loop
  };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ out:Seq Int^many)
  locals { xs result i } {
    [ result ]
    [ xs result i 1 prim + xs xs prim seq-int.len i prim - 1 prim - prim seq-int.at prim seq-int.push reverse-loop ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 11, column 85
message: `prim seq-int.push` in `reverse-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int ?t24 Int Int.
expected: .. Seq Int Int
actual: .. Seq Int ?t24 Int Int
hint: The second value from the top is Int but `prim seq-int.push` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    xs prim seq-int.empty 0 0 prefix-loop
  };

: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many i:Int^many -- ρ out:Seq Int^many)
  locals { xs result sum i } {
    [ result ]
    [ xs xs i prim seq-int.at sum prim + result (xs i prim seq-int.at sum prim +) prim seq-int.push i 1 prim + prefix-loop ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 11, column 49
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    xs prim seq-int.empty 0 keep-loop
  };

: keep-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ out:Seq Int^many)
  locals { xs result i } {
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim + ]
    [ result i 1 prim + ]
    xs i prim seq-int.at 0 prim <
    if
    keep-loop-continue
  };

: keep-loop-continue
  (forall ρ; ρ result:Seq Int^many i:Int^many -- ρ out:Seq Int^many)
  locals { result i } {
    [ result ]
    [ result i 1 prim + keep-loop ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: keep-loop
at: line 13, column 5
message: `if` in `keep-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int Int ] [ .. -- .. Seq Int Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.name.unresolved
word: keep-loop-continue
at: line 22, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    [ prim not prim not ]
    [ xs 0 is-sorted-loop ]
    xs prim seq-int.len 1 prim <
    if
  };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    [ prim not prim not ]
    [ xs i 1 prim + is-sorted-loop ]
    xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
    if
    is-sorted-continue
  };

: is-sorted-continue
  (forall ρ; ρ i:Int^many -- ρ result:Bool^many)
  locals { i } {
    [ prim not prim not ]
    [ xs i 1 prim + is-sorted-loop ]
    i xs prim seq-int.len 1 prim - prim <
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-bool
word: main
at: line 7, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. Bool -- .. Bool ] [ .. -- .. Bool ] Bool. `main` calls `is-sorted-loop`, which has an error of its own; this report assumes `is-sorted-loop` keeps its stack effect.
expected: Bool
actual: [ .. Bool -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 3
code: firth.type.expected-bool
word: is-sorted-loop
at: line 16, column 5
message: `if` in `is-sorted-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. Bool -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. Bool -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 3
code: firth.name.unresolved
word: is-sorted-continue
at: line 24, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    [ prim not prim not ]
    [ flags 0 all-loop ]
    flags prim seq-bool.len 0 prim =
    if
  };

: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ out:Bool^many)
  locals { flags i } {
    [ prim not prim not ]
    [ [ flags i prim seq-bool.at ]
      [ prim not prim not ]
      flags i prim seq-bool.at prim not
      if
      i 1 prim + all-loop
    ]
    i flags prim seq-bool.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: main
at: line 7, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. Bool -- .. Bool ] [ .. -- .. Bool ] Bool. `main` calls `all-loop`, which has an error of its own; this report assumes `all-loop` keeps its stack effect.
expected: Bool
actual: [ .. Bool -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.elaboration.untracked-local
word: all-loop
at: line 18, column 7
message: The local `i` is used after `if` on line 17 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    [ 0 ]
    [ xs 0 0 1 longest-run-loop ]
    xs prim seq-int.len 0 prim =
    if
  };

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-run:Int^many current-run:Int^many -- ρ result:Int^many)
  locals { xs i max-run current-run } {
    [ max-run ]
    [ [ xs i 1 prim + max-run current-run 1 prim + longest-run-loop ]
      [ xs i 1 prim + [ current-run 1 prim + ] [ max-run ] current-run max-run prim < if longest-run-loop ]
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
      if
    ]
    i xs prim seq-int.len 1 prim - prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: main
at: line 7, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool. `main` calls `longest-run-loop`, which has an error of its own; this report assumes `longest-run-loop` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.expected-bool
word: longest-run-loop
at: line 15, column 87
message: `if` in `longest-run-loop` needs a Bool condition under its two quotations, but the stack before it is .. ?t102 Int [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    xs target 0 has-pair-loop
  };

: has-pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    [ prim not prim not ]
    [ xs target i 1 prim + has-pair-inner ]
    i xs prim seq-int.len 1 prim - prim <
    if
  };

: has-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    [ prim not prim not ]
    [ xs target i 1 prim + has-pair-inner ]
    xs i prim seq-int.at target xs i prim seq-int.at prim - prim seq-int.at prim not
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: has-pair-loop
at: line 13, column 5
message: `if` in `has-pair-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. Bool -- .. Bool ] [ .. -- .. Bool ] Bool. `has-pair-loop` calls `has-pair-inner`, which has an error of its own; this report assumes `has-pair-inner` keeps its stack effect.
expected: Bool
actual: [ .. Bool -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: has-pair-inner
at: line 21, column 61
message: `prim seq-int.at` in `has-pair-inner` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and the result of `prim -` (Int).
expected: .. Seq Int Int
actual: ρ [ .. Bool -- .. Bool ] [ .. -- .. Bool ] Int Int
hint: The second value from the top, the result of `prim seq-int.at` (Int), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs 0 0 count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    [ count ]
    [ xs i 1 prim + [ count 1 prim + ] [ count ] i 0 prim = [ prim not prim not ] [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = prim not ] if if count-distinct-loop ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 11, column 154
message: The two branches of `if` in `count-distinct-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
    xs ys prim seq-int.empty 0 0 merge-loop
  };

: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ out:Seq Int^many)
  locals { xs ys result i j } {
    [ result ]
    [ xs ys result i j merge-continue ]
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and prim not
    if
  };

: merge-continue
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ out:Seq Int^many)
  locals { xs ys result i j } {
    [ xs ys result i 1 prim + j merge-loop ]
    [ xs ys result i j 1 prim + merge-loop ]
    xs i prim seq-int.at ys j prim seq-int.at prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: merge-loop
at: line 13, column 5
message: `if` in `merge-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool. `merge-loop` calls `merge-continue`, which has an error of its own; this report assumes `merge-continue` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.expected-bool
word: merge-continue
at: line 22, column 5
message: `if` in `merge-continue` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool. `merge-continue` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ { 0 } ]
    [ n prim seq-int.empty n digits-loop ]
    n 0 prim =
    if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ out:Seq Int^many)
  locals { n result } {
    [ result ]
    [ n 10 prim div result n 10 prim mod prim seq-int.push n digits-loop ]
    n 0 prim =
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 5, column 30
message: `digits-loop` in `main` needs Int Seq Int on top of the stack, but the stack before it is .. ?t3 Seq Int ?t3. `main` calls `digits-loop`, which has an error of its own; this report assumes `digits-loop` keeps its stack effect.
expected: .. Int Seq Int
actual: .. ?t3 Seq Int ?t3
hint: The top value is ?t3 but `digits-loop` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: digits-loop
at: line 14, column 62
message: `digits-loop` in `digits-loop` needs Int Seq Int on top of the stack, but the stack before it is .. Int Seq Int Int.
expected: .. Int Seq Int
actual: .. Int Seq Int Int
hint: The top value is Int but `digits-loop` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 2 n primes-loop
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ out:Seq Int^many)
  locals { result candidate n } {
    [ result ]
    [ [ result candidate prim seq-int.push candidate 1 prim + n ] [ candidate 1 prim + n ] candidate 2 is-prime-check if primes-loop ]
    candidate n prim <
    if
  };

: is-prime-check
  (forall ρ; ρ candidate:Int^many -- ρ prime:Bool^many)
  locals { candidate } {
    [ prim not prim not ]
    [ candidate 2 2 is-prime-check-loop ]
    candidate 2 prim <
    if
  };

: is-prime-check-loop
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { candidate divisor } {
    [ prim not prim not ]
    [ [ prim not prim not ] [ divisor 1 prim + is-prime-check-loop ] divisor divisor prim * candidate prim < if ]
    candidate divisor prim mod 0 prim =
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-bool
word: primes-loop
at: line 11, column 119
message: `if` in `primes-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Seq Int Int ?t63 ] [ .. -- .. Int ?t63 ] Int Bool. `primes-loop` calls `is-prime-check`, which has an error of its own; this report assumes `is-prime-check` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Int ?t63 ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 3
code: firth.type.expected-bool
word: is-prime-check
at: line 22, column 5
message: `if` in `is-prime-check` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. Bool -- .. Bool ] [ .. -- .. Int Bool ] Bool. `is-prime-check` calls `is-prime-check-loop`, which has an error of its own; this report assumes `is-prime-check-loop` keeps its stack effect.
expected: Bool
actual: [ .. Bool -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 3
code: firth.type.expected-bool
word: is-prime-check-loop
at: line 29, column 110
message: `if` in `is-prime-check-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. Bool -- .. Bool ] [ .. Int -- .. Bool ] Bool.
expected: Bool
actual: [ .. Bool -- .. Bool ]
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
  locals { xs k } {
    k 0 prim seq-int.empty histogram-init xs 0 histogram-count
  };

: histogram-init
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ out:Seq Int^many)
  locals { k i counts } {
    [ counts ]
    [ counts 0 prim seq-int.push i 1 prim + histogram-init ]
    i k prim <
    if
  };

: histogram-count
  (forall ρ; ρ counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts i } {
    [ counts ]
    [ counts xs i prim seq-int.at counts xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set i 1 prim + histogram-count ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int. `main` calls `histogram-init` and `histogram-count`, which have errors of their own; this report assumes they keep their stack effects.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.word-input-mismatch
word: histogram-init
at: line 11, column 45
message: `histogram-init` in `histogram-init` needs Int Int Seq Int on top of the stack, but the stack before it is .. Int Seq Int Int.
expected: .. Int Int Seq Int
actual: .. Seq Int Int
hint: `histogram-init` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 3 of 3
code: firth.name.unresolved
word: histogram-count
at: line 20, column 14
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    xs prim seq-int.empty 0 sort-loop
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ out:Seq Int^many)
  locals { xs result i } {
    [ result ]
    [ xs i find-min result prim seq-int.push i 1 prim + sort-loop ]
    i xs prim seq-int.len prim <
    if
  };

: find-min
  (forall ρ; ρ xs:Seq Int^many start:Int^many -- ρ min:Int^many)
  locals { xs start } {
    xs start prim seq-int.at start find-min-loop
  };

: find-min-loop
  (forall ρ; ρ xs:Seq Int^many start:Int^many min:Int^many -- ρ result:Int^many)
  locals { xs start min } {
    [ min ]
    [ xs start 1 prim + prim seq-int.at [ xs start 1 prim + prim seq-int.at ] [ min ] xs start 1 prim + prim seq-int.at min prim < if start 1 prim + find-min-loop ]
    start xs prim seq-int.len 1 prim - prim <
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: sort-loop
at: line 11, column 28
message: `prim seq-int.push` in `sort-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t23. `sort-loop` calls `find-min`, which has an error of its own; this report assumes `find-min` keeps its stack effect.
expected: .. Seq Int Int
actual: .. Int Int ?t23
hint: The top value is ?t23 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 3
code: firth.type.word-input-mismatch
word: find-min
at: line 19, column 36
message: `find-min-loop` in `find-min` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Int Int. `find-min` calls `find-min-loop`, which has an error of its own; this report assumes `find-min-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int
hint: `find-min-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 3 of 3
code: firth.elaboration.untracked-local
word: find-min-loop
at: line 26, column 135
message: The local `start` is used after `if` on line 26 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    start 0 0 ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { balance rejected i } {
    [ balance rejected ]
    [ [ balance txs i prim seq-int.at prim + rejected i 1 prim + ] [ balance rejected 1 prim + i 1 prim + ] balance txs i prim seq-int.at prim + 0 prim < if ledger-loop ]
    i txs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: ledger-loop
at: line 11, column 17
message: `txs` is not a defined word, primitive or local.
actual: txs
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many -- ρ st:Seq Int^many al:Seq Int^many re:Seq Int^many)
  locals { stock allocated reasons i } {
    [ stock allocated reasons ]
    [ 
      stock allocated reasons i 1 prim +
      allocate-loop
    ]
    i items prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.name.unresolved
word: allocate-loop
at: line 15, column 7
message: `items` is not a defined word, primitive or local.
actual: items
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
