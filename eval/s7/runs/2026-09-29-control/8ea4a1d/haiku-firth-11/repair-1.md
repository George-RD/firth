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
    xs 0 prim seq-int.at xs 1 max-loop
  };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      [ xs i prim seq-int.at ]
      [ max ]
      xs i prim seq-int.at max prim <
      if
      max-loop
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 31
message: `max-loop` in `main` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `1` (Int). `main` calls `max-loop`, which has an error of its own; this report assumes `max-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.expected-bool
word: max-loop
at: line 17, column 7
message: `if` in `max-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    i xs prim seq-int.len prim <
    [
      xs
      k
      i 1 prim +
      [ count 1 prim + ]
      [ count ]
      xs i prim seq-int.at k prim <
      if
      count-loop
    ]
    [ count ]
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: count-loop
at: line 18, column 7
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
    i xs prim seq-int.len prim <
    [
      [ i ]
      [ xs x i 1 prim + index-loop ]
      xs i prim seq-int.at x prim =
      if
    ]
    [ 0 prim - 1 prim + ]
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: index-loop
at: line 15, column 7
message: `if` in `index-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    xs prim seq-int.empty xs 0 reverse-loop
  };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ out:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs
      xs i prim seq-int.len 1 prim - i prim - prim seq-int.at result prim seq-int.push
      i 1 prim +
      reverse-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int. `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 13, column 12
message: `prim seq-int.len` in `reverse-loop` takes Seq Int, bottom to top, but here it gets, bottom to top, `i` (Int).
expected: .. Seq Int
actual: .. Int
hint: The top value, `i` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    i xs prim seq-int.len prim <
    [
      xs
      xs i prim seq-int.at sum prim +
      result (xs i prim seq-int.at sum prim +) prim seq-int.push
      i 1 prim +
      prefix-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 14, column 14
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
    i xs prim seq-int.len prim <
    [
      xs
      [ result xs i prim seq-int.at prim seq-int.push ]
      [ result ]
      xs i prim seq-int.at 0 prim <
      if
      i 1 prim +
      keep-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: keep-loop
at: line 17, column 7
message: The local `i` is used after `if` on line 16 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    xs 0 is-sorted-loop
  };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      [ xs i prim seq-int.len 1 prim - prim seq-int.at i 1 prim + is-sorted-loop ]
      [ prim not ]
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      if
    ]
    [ prim not prim not ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: is-sorted-loop
at: line 12, column 60
message: `prim +` in `is-sorted-loop` needs Int Int on top of the stack, but the stack before it is .. Int Seq Int Int.
expected: .. Int Int
actual: .. Int Seq Int Int
hint: The second value from the top is Seq Int but `prim +` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    flags 0 prim not prim not all-loop
  };

: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many result:Bool^many -- ρ out:Bool^many)
  locals { flags i result } {
    i flags prim seq-bool.len prim <
    [ result prim not ]
    [ flags i prim seq-bool.at result prim and i 1 prim + all-loop ]
    result prim not
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 4, column 13
message: `prim not` in `main` takes Bool, bottom to top, but here it gets, bottom to top, `0` (Int).
expected: .. Bool
actual: ρ Seq Bool Int
hint: The top value, `0` (Int), is not what `prim not` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: all-loop
at: line 12, column 59
message: `all-loop` in `all-loop` needs Seq Bool Int Bool on top of the stack, but the stack before it is .. Seq Bool Bool Int.
expected: .. Seq Bool Int Bool
actual: .. Bool Int
hint: `all-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
    i xs prim seq-int.len prim <
    [
      xs
      [
        i 1 prim +
        [ xs i 1 prim + prim seq-int.at max-run current-run prim + prim < [ current-run 1 prim + ] [ max-run ] if ]
        [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = ]
        if
        longest-run-loop
      ]
      [ i 1 prim + max-run [ current-run max-run prim < [ max-run ] [ current-run ] if ] dip prim seq-int.len prim < ]
      i xs prim seq-int.len 1 prim - prim <
      if
    ]
    [ max-run ]
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
at: line 20, column 9
message: `if` in `longest-run-loop` needs a Bool condition under its two quotations, but the stack before it is .. Int [ .. -- .. Int ] [ .. -- .. Bool ].
expected: Bool
actual: Int
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
    i xs prim seq-int.len 1 prim - prim <
    [
      xs
      target
      i 1 prim +
      [ prim not prim not ]
      [ xs i prim seq-int.len xs target xs i prim seq-int.at prim - prim seq-int.at i 2 prim + has-pair-loop ]
      xs i prim seq-int.at target xs i prim seq-int.at prim - prim seq-int.len [ ] prim seq-int.at prim not
      if
    ]
    [ prim not prim not ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: has-pair-loop
at: line 16, column 46
message: `prim seq-int.at` in `has-pair-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Seq Int Int Seq Int ?t59 Seq Int Seq Int.
expected: .. Seq Int Int
actual: .. Seq Int ?t61 Int ?t61 ?t59 ?t61 Seq Int
hint: The top value is Seq Int but `prim seq-int.at` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    xs prim seq-int.sort 0 0 count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim <
    [
      xs
      [ i 1 prim + count 1 prim + ]
      [ i 1 prim + count ]
      i 0 prim =
      [ prim not prim not ]
      [ i prim not prim not xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = ]
      if
      if
      count-distinct-loop
    ]
    [ count ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved-effect
word: main
at: line 4, column 8
message: `prim seq-int.sort` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

error 2 of 2
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 18, column 7
message: The two branches of the `if` in `count-distinct-loop` whose true branch is `[ prim not prim not ]` leave different numbers of values. The true branch takes the quotation `[ i 1 prim + count ]` from below the `if` and leaves the result of `prim not`; the false branch leaves 2 values, bottom to top: the result of `prim not` and the result of `prim =`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim not` and the result of `prim =` are left by the false branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    [ i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and ]
    [ xs ys result i j prim seq-int.len prim + prim seq-int.len merge-end ]
    [ [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j ] 
      [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + ]
      xs i prim seq-int.at ys j prim seq-int.at prim <
      if
      merge-loop
    ]
    i xs prim seq-int.len prim <
    if
  };

: merge-end
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ out:Seq Int^many)
  locals { xs ys result i j } {
    [ i xs prim seq-int.len prim < ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j merge-end ]
    [ 0 prim not prim not ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 11, column 48
message: `prim seq-int.len` in `merge-loop` needs Seq Int on top of the stack, but the stack before it is .. ?t82 ?t81 ?t80 Int.
expected: .. Seq Int
actual: .. ?t82 ?t81 ?t80 Int
hint: The top value is Int but `prim seq-int.len` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: merge-end
at: line 28, column 5
message: In the true branch `[ result xs i prim seq-int.at prim seq-int.push ...` of the `if` in `merge-end`, `merge-end` needs 5 values (xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `j`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-end`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `j`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `merge-end` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ n 10 prim mod result prim seq-int.push n 10 prim div digits-loop ]
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
code: firth.type.primitive-input-mismatch
word: digits-loop
at: line 14, column 28
message: `prim seq-int.push` in `digits-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t14.
expected: .. Seq Int Int
actual: .. Int Int ?t14
hint: The top value is ?t14 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 2 primes-loop
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many -- ρ out:Seq Int^many)
  locals { result candidate } {
    [ candidate 10 prim < ]
    [ [ result candidate prim seq-int.push candidate 1 prim + ] [ candidate 1 prim + ] is-prime if primes-loop ]
    [ 0 prim not prim not ]
    candidate 10 prim <
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many -- ρ prime:Bool^many)
  locals { candidate } {
    [ prim not prim not ]
    [ candidate 2 2 is-prime-check ]
    candidate 2 prim <
    if
  };

: is-prime-check
  (forall ρ; ρ candidate:Int^many divisor:Int^many limit:Int^many -- ρ prime:Bool^many)
  locals { candidate divisor limit } {
    [ candidate divisor prim mod 0 prim = prim not ]
    [ [ prim not prim not ] [ divisor 1 prim + limit is-prime-check ] divisor limit prim < if ]
    [ 0 prim not prim not ]
    divisor divisor prim * candidate prim <
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: primes-loop
at: line 11, column 88
message: `is-prime` in `primes-loop` needs Int on top of the stack, but the stack before it is .. [ .. -- .. Seq Int Int ] [ .. -- .. Int ]. `primes-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
expected: .. Int
actual: .. [ .. -- .. Seq Int Int ] [ .. -- .. Int ]
hint: The top value is [ .. -- .. Int ] but `is-prime` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 3
code: firth.type.expected-bool
word: is-prime
at: line 23, column 5
message: `if` in `is-prime` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. Bool -- .. Bool ] [ .. -- .. Bool ] Bool. `is-prime` calls `is-prime-check`, which has an error of its own; this report assumes `is-prime-check` keeps its stack effect.
expected: Bool
actual: [ .. Bool -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 3
code: firth.type.expected-bool
word: is-prime-check
at: line 30, column 92
message: `if` in `is-prime-check` needs a Bool condition under its two quotations, but the stack before it is .. [ .. Bool -- .. Bool ] [ .. Int -- .. Bool ] Bool.
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
    k 0 prim seq-int.empty 0 histogram-init
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
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs counts i } {
    [ counts ]
    [ xs i prim seq-int.at counts xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set i 1 prim + histogram-count ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 4, column 30
message: `histogram-init` in `main` takes k:Int, i:Int, counts:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `histogram-init`, which has an error of its own; this report assumes `histogram-init` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Seq Int Int Int Seq Int Int
hint: The top value, `0` (Int), is not what `histogram-init` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.word-input-mismatch
word: histogram-init
at: line 11, column 45
message: `histogram-init` in `histogram-init` needs Int Int Seq Int on top of the stack, but the stack before it is .. Int Seq Int Int.
expected: .. Int Int Seq Int
actual: .. Seq Int Int
hint: `histogram-init` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 3 of 3
code: firth.type.expected-bool
word: histogram-count
at: line 22, column 5
message: `if` in `histogram-count` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. Seq Int Seq Int -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ result (find-min xs i) prim seq-int.push i 1 prim + sort-loop ]
    i xs prim seq-int.len prim <
    if
  };

: find-min
  (forall ρ; ρ xs:Seq Int^many start:Int^many -- ρ min:Int^many)
  locals { xs start } {
    xs start prim seq-int.at start 0 find-min-loop
  };

: find-min-loop
  (forall ρ; ρ xs:Seq Int^many start:Int^many min:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs start min i } {
    [ min ]
    [ [ xs i prim seq-int.at ] [ min ] xs i prim seq-int.at min prim < if i 1 prim + find-min-loop ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 11, column 14
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
    start 0 0 ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { balance rejected i } {
    [ balance rejected ]
    [ [ balance rejected i 1 prim + ] [ balance 1 prim + rejected i 1 prim + ] balance 0 prim < if ledger-loop ]
    i txs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: ledger-loop
at: line 12, column 7
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
