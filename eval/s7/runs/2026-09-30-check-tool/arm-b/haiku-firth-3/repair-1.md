Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { sum idx xs len } {
    [ idx len prim < ]
    [ xs idx prim seq-int.at sum prim + idx 1 prim + xs len sum-loop ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs xs prim seq-int.len sum-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: sum-loop
at: line 7, column 5
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
: max-loop
  (forall ρ; ρ max:Int^many idx:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { max idx xs len } {
    [ idx len prim < ]
    [
      xs idx prim seq-int.at
      [ max prim < ] [ xs idx prim seq-int.at ] [ max ] if
      idx 1 prim +
      xs len max-loop
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1
    xs
    xs prim seq-int.len
    max-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 12, column 5
message: The two branches of the `if` in `max-loop` whose true branch is `[ xs idx prim seq-int.at [ max prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `max-loop`; the false branch leaves `max`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `max-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many k:Int^many len:Int^many -- ρ result:Int^many)
  locals { count idx xs k len } {
    [ idx len prim < ]
    [
      [ xs idx prim seq-int.at k prim < ] [ count 1 prim + ] [ count ] if
      idx 1 prim +
      xs k len count-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k xs prim seq-int.len count-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: count-loop
at: line 6, column 72
message: `if` in `count-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int Int ?t49 [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: search-loop
  (forall ρ; ρ result:Int^many idx:Int^many xs:Seq Int^many x:Int^many len:Int^many -- ρ index:Int^many)
  locals { result idx xs x len } {
    [ [ idx len prim < ] [ result -1 prim = ] prim and ]
    [
      [ xs idx prim seq-int.at x prim = ] [ idx ] [ result ] if
      idx 1 prim +
      xs x len search-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { -1 0 xs x xs prim seq-int.len search-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: search-loop
at: line 4, column 47
message: `prim and` in `search-loop` needs Bool Bool on top of the stack, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: .. Bool Bool
actual: .. [ .. -- .. Bool ] [ .. -- .. Bool ]
hint: The top value is [ .. -- .. Bool ] but `prim and` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result idx xs } {
    [ idx 0 prim < prim not ]
    [ xs idx prim seq-int.at result prim seq-int.push idx 1 prim - xs reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    reverse-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 5, column 37
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs idx prim seq-int.at` in place of `xs idx prim seq-int.at result` on line 5. With that edit, the next error in `reverse-loop` is at line 7, column 5.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many len:Int^many -- ρ sums:Seq Int^many)
  locals { result sum idx xs len } {
    [ idx len prim < ]
    [
      xs idx prim seq-int.at sum prim +
      result prim seq-int.push
      idx 1 prim +
      xs len prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    0
    xs
    xs prim seq-int.len
    prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 12, column 5
message: In the true branch `[ xs idx prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 5 values (result:Seq Int, sum:Int, idx:Int, xs:Seq Int, len:Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `xs` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, sum:Int, idx:Int, xs:Seq Int, len:Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +`, `xs` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many len:Int^many -- ρ positives:Seq Int^many)
  locals { result idx xs len } {
    [ idx len prim < ]
    [
      xs idx prim seq-int.at
      [ 0 prim < prim not ] [ result prim seq-int.push ] [ drop ] if
      idx 1 prim +
      xs len filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    xs prim seq-int.len
    filter-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 7, column 67
message: The two branches of the `if` in `filter-loop` whose true branch is `[ result prim seq-int.push ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ sorted:Bool^many idx:Int^many xs:Seq Int^many len:Int^many -- ρ result:Bool^many)
  locals { sorted idx xs len } {
    [ [ idx 1 prim + len prim < ] [ sorted ] prim and ]
    [
      [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < prim not ]
      [ sorted ]
      [ false ]
      if
      idx 1 prim +
      xs len check-sorted
    ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    [ xs prim seq-int.len 1 prim < ]
    [ true ]
    [ true 0 xs xs prim seq-int.len check-sorted ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: check-sorted
at: line 4, column 46
message: `prim and` in `check-sorted` needs Bool Bool on top of the stack, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. ?t17 ].
expected: .. Bool Bool
actual: .. [ .. -- .. Bool ] [ .. -- .. ?t17 ]
hint: The top value is [ .. -- .. ?t17 ] but `prim and` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 2
code: firth.type.expected-bool
word: main
at: line 23, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ]. `main` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many len:Int^many -- ρ product:Int^many)
  locals { sum idx xs ys len } {
    [ idx len prim < ]
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim +
      idx 1 prim +
      xs ys len dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys xs prim seq-int.len dot-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: dot-loop
at: line 11, column 5
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
: all-loop
  (forall ρ; ρ all:Bool^many idx:Int^many flags:Seq Bool^many len:Int^many -- ρ result:Bool^many)
  locals { all idx flags len } {
    [ [ idx len prim < ] [ all ] prim and ]
    [ flags idx prim seq-bool.at all prim and idx 1 prim + flags len all-loop ]
    [ all ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    [ flags prim seq-bool.len 0 prim = ]
    [ true ]
    [ true 0 flags flags prim seq-bool.len all-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: all-loop
at: line 4, column 34
message: `prim and` in `all-loop` needs Bool Bool on top of the stack, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. ?t17 ].
expected: .. Bool Bool
actual: .. [ .. -- .. Bool ] [ .. -- .. ?t17 ]
hint: The top value is [ .. -- .. ?t17 ] but `prim and` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 2
code: firth.type.expected-bool
word: main
at: line 16, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ]. `main` calls `all-loop`, which has an error of its own; this report assumes `all-loop` keeps its stack effect.
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
: run-loop
  (forall ρ; ρ maxlen:Int^many curlen:Int^many idx:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { maxlen curlen idx xs len } {
    [ idx len prim < ]
    [
      [ xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim = ]
      [
        curlen 1 prim +
        [ maxlen prim < ] [ curlen 1 prim + ] [ maxlen ] if
      ]
      [ 1 ]
      if
      idx 1 prim +
      xs len run-loop
    ]
    [ maxlen ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    [ xs prim seq-int.len 0 prim = ]
    [ 0 ]
    [ 1 1 1 xs xs prim seq-int.len run-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 12, column 7
message: The two branches of the `if` in `run-loop` whose true branch is `[ curlen 1 prim + [ maxlen prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves `1`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.expected-bool
word: main
at: line 26, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ]. `main` calls `run-loop`, which has an error of its own; this report assumes `run-loop` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-loop
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many len:Int^many -- ρ result:Bool^many)
  locals { found i xs target len } {
    [ [ i 1 prim + len prim < ] [ found prim not ] prim and ]
    [
      [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim + target prim = ]
      [ true ]
      [ found ]
      if
      i 1 prim +
      xs target len pair-loop
    ]
    [ found ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    [ xs prim seq-int.len 2 prim < ]
    [ false ]
    [ false 0 xs target xs prim seq-int.len 1 prim - pair-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: pair-loop
at: line 4, column 52
message: `prim and` in `pair-loop` needs Bool Bool on top of the stack, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: .. Bool Bool
actual: .. [ .. -- .. Bool ] [ .. -- .. Bool ]
hint: The top value is [ .. -- .. Bool ] but `prim and` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 2
code: firth.type.expected-bool
word: main
at: line 23, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ]. `main` calls `pair-loop`, which has an error of its own; this report assumes `pair-loop` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-dist
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { count i xs len } {
    [ i len prim < ]
    [
      true
      0
      [ dup i prim < ]
      [ [ xs over prim seq-int.at xs i prim seq-int.at prim = ] [ drop false ] [ 1 prim + ] if ]
      [ drop [ drop count 1 prim + ] [ drop count ] if ]
      dip
      i 1 prim +
      xs len count-dist
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs xs prim seq-int.len count-dist };

```
On the example, the run failed:
code: firth.name.unresolved
word: count-dist
at: line 9, column 14
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many len-xs:Int^many len-ys:Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys len-xs len-ys } {
    [ [ i len-xs prim < ] [ j len-ys prim < ] prim and ]
    [
      [ xs i prim seq-int.at ys j prim seq-int.at prim < prim not ]
      [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys len-xs len-ys merge-loop ]
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys len-xs len-ys merge-loop ]
      if
    ]
    [
      [ i len-xs prim < ]
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys len-xs len-ys merge-loop ]
      [
        [ j len-ys prim < ]
        [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys len-xs len-ys merge-loop ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0
    0
    xs
    ys
    xs prim seq-int.len
    ys prim seq-int.len
    merge-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 4, column 47
message: `prim and` in `merge-loop` needs Bool Bool on top of the stack, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: .. Bool Bool
actual: .. [ .. -- .. Bool ] [ .. -- .. Bool ]
hint: The top value is [ .. -- .. Bool ] but `prim and` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: extract-digits
  (forall ρ; ρ seq:Seq Int^many n:Int^many -- ρ seq:Seq Int^many)
  locals { seq n } {
    [ n 0 prim < prim not ]
    [ n 10 prim mod seq prim seq-int.push n 10 prim div seq extract-digits ]
    [ seq ]
    if
  };

: reverse-loop
  (forall ρ; ρ out:Seq Int^many i:Int^many s:Seq Int^many -- ρ out:Seq Int^many)
  locals { out i s } {
    [ i 0 prim < prim not ]
    [ s i prim seq-int.at out prim seq-int.push i 1 prim - s reverse-loop ]
    [ out ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    [ n 0 prim = ]
    [ prim seq-int.empty 0 prim seq-int.push ]
    [
      prim seq-int.empty n extract-digits
      dup prim seq-int.len 1 prim - swap reverse-loop
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: extract-digits
at: line 7, column 5
message: The two branches of the `if` in `extract-digits` whose true branch is `[ n 10 prim mod seq prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `extract-digits`; the false branch leaves `seq`.
hint: The result of `prim seq-int.push` is a new value of `seq`, but `extract-digits` is then handed `seq` as it was before, so the new value is left below. If `extract-digits` should get the new value, bind it to the name `seq` for the call: write `prim seq-int.push locals { seq } { n 10 prim div seq extract-digits }` in place of `prim seq-int.push n 10 prim div seq extract-digits` on line 5. With that edit, the next error in `extract-digits` is at line 5, column 25. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 14, column 31
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `out` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `out s i prim seq-int.at` in place of `s i prim seq-int.at out` on line 14. With that edit, the next error in `reverse-loop` is at line 16, column 5.

error 3 of 3
code: firth.type.branch-mismatch
word: main
at: line 28, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ prim seq-int.empty 0 prim seq-int.push ]`, `reverse-loop` needs 3 values (out:Seq Int, i:Int, s:Seq Int), but the branch has pushed only 2 values before it (the result of `prim -` and the result of `extract-digits`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `extract-digits` and `reverse-loop`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: out:Seq Int, i:Int, s:Seq Int. The branch already pushes the result of `prim -` and the result of `extract-digits`, in the place of the last 2 (i:Int, s:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (out:Seq Int) before them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ p:Int^many d:Int^many -- ρ result:Bool^many)
  locals { p d } {
    [ d d prim * p prim < prim not ]
    [ true ]
    [
      [ p d prim mod 0 prim = ]
      [ false ]
      [ d 1 prim + p is-prime-check ]
      if
    ]
    if
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    [ i n prim < prim not [ drop result ] dip ]
    [
      [ i 2 prim < ]
      [ result i 1 prim + n primes-loop ]
      [ 2 i is-prime-check [ result i prim seq-int.push ] [ result ] if i 1 prim + n primes-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    [ n 2 prim < ]
    [ prim seq-int.empty ]
    [ prim seq-int.empty 2 n primes-loop ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-bool
word: is-prime-check
at: line 10, column 7
message: `if` in `is-prime-check` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 3
code: firth.type.stack-underflow
word: primes-loop
at: line 25, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 3 of 3
code: firth.type.expected-bool
word: main
at: line 34, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ]. `main` calls `primes-loop`, which has an error of its own; this report assumes `primes-loop` keeps its stack effect.
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
: hist-loop
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many len:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i xs len k } {
    [ i len prim < ]
    [
      xs i prim seq-int.at
      locals { v } {
        counts v prim seq-int.at 1 prim +
        counts v prim seq-int.set
      }
      i 1 prim +
      xs len k hist-loop
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ k ] [ 0 prim seq-int.push ] [ drop ] dip
    xs
    xs prim seq-int.len
    k
    hist-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: hist-loop
at: line 9, column 18
message: `prim seq-int.set` in `hist-loop` takes the sequence (Seq Int), the index (Int) and the new value (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `counts` (Seq Int) and `v` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Seq Int ?t52 ?t51 Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `counts` is for the sequence. Of the values of one type, `counts v prim seq-int.at 1 prim +` and `v` are for the index and the new value, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 27, column 5
message: `hist-loop` in `main` takes counts:Seq Int, i:Int, xs:Seq Int, len:Int, k:Int, bottom to top, but here it gets, bottom to top, `0` (Int), the quotation `[ 0 prim seq-int.push ]`, `xs` (Seq Int), the result of `prim seq-int.len` (Int) and `k` (Int). `main` calls `hist-loop`, which has an error of its own; this report assumes `hist-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int Int Int
actual: ρ Seq Int Int [ .. Seq Int -- .. Seq Int ] Seq Int Int Int
hint: Value 4 from the top, the quotation `[ 0 prim seq-int.push ]`, is not what `hist-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubble-pass
  (forall ρ; ρ xs:Seq Int^many n:Int^many pass:Int^many -- ρ xs:Seq Int^many)
  locals { xs n pass } {
    [ pass n prim < ]
    [
      0
      [ dup n 1 prim - prim < ]
      [
        [ xs over prim seq-int.at xs over 1 prim + prim seq-int.at prim < prim not ]
        [
          xs over prim seq-int.at
          xs over 1 prim + prim seq-int.at
          xs swap over prim seq-int.set
          xs swap prim seq-int.set
        ]
        [ ]
        if
        1 prim +
      ]
      [ drop ]
      dip
      xs n pass 1 prim + bubble-pass
    ]
    [ xs ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 0 bubble-pass };

```
On the example, the run failed:
code: firth.name.unresolved
word: bubble-pass
at: line 9, column 14
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many len:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs len } {
    [ i len prim < ]
    [
      txs i prim seq-int.at balance prim +
      [ dup 0 prim < ]
      [ drop balance rejected 1 prim + ]
      [ balance rejected ]
      if
      i 1 prim +
      txs len ledger-loop
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    0
    txs
    txs prim seq-int.len
    ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 10, column 7
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ drop balance rejected 1 prim + ]` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: `balance` and the result of `prim +`; the false branch leaves 2 values, bottom to top: `balance` and `rejected`.
hint: The false branch leaves 1 value more than the true branch: `balance` is left below `rejected`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many len:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole len } {
    [ i len prim < ]
    [
      items i prim seq-int.at
      stock swap prim seq-int.at
      locals { item-idx current-stock } {
        qtys i prim seq-int.at
        [ dup current-stock prim < prim not ]
        [ allocated prim seq-int.push reasons 0 prim seq-int.push stock item-idx current-stock qtys i prim seq-int.at prim - prim seq-int.set ]
        [
          [ current-stock 0 prim = ]
          [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ]
          [
            [ whole i prim seq-bool.at ]
            [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]
            [ allocated current-stock prim seq-int.push reasons 1 prim seq-int.push stock item-idx 0 prim seq-int.set ]
            if
          ]
          if
        ]
        if
      }
      i 1 prim +
      items qtys whole len allocate-loop
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    items
    qtys
    whole
    qtys prim seq-int.len
    allocate-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 19, column 13
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim seq-int.set`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `prim seq-int.push` and the result of `prim seq-int.set`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
