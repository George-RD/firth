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
  0 locals { xs } { xs 0 sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many idx:Int^many -- ρ total:Int^many)
  locals { acc xs idx } {
    idx xs prim seq-int.len prim =
    [ acc ]
    [ xs idx prim seq-int.at acc prim + xs idx 1 prim + sum-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 26
message: `sum-loop` in `main` takes acc:Int, xs:Seq Int, idx:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `xs` (Int) and `0` (Int).
expected: .. Int Seq Int Int
actual: ρ Seq Int Int Int
hint: The second value from the top, `xs` (Int), is not what `sum-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at locals { xs } { xs 1 max-loop };

: max-loop
  (forall ρ; ρ max-so-far:Int^many xs:Seq Int^many idx:Int^many -- ρ largest:Int^many)
  locals { max-so-far xs idx } {
    idx xs prim seq-int.len prim =
    [ max-so-far ]
    [ xs idx prim seq-int.at
      dup max-so-far prim <
      [ drop ]
      [ swap drop ]
      if
      xs idx 1 prim + max-loop
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: main
at: line 3, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 17, column 5
message: The two branches of `if` in `max-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 locals { xs k } { xs k 0 count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many k:Int^many idx:Int^many -- ρ count:Int^many)
  locals { acc xs k idx } {
    idx xs prim seq-int.len prim =
    [ acc ]
    [ xs idx prim seq-int.at dup k prim <
      [ acc 1 prim + ]
      [ drop acc ]
      if
      xs k idx 1 prim + count-loop
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 30
message: `count-loop` in `main` takes acc:Int, xs:Seq Int, k:Int, idx:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `xs` (Int), `k` (Int) and `0` (Int). `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: .. Int Seq Int Int Int
actual: ρ Seq Int Int Int Int
hint: The third value from the top, `xs` (Int), is not what `count-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 13, column 7
message: The two branches of the `if` in `count-loop` whose true branch is `[ acc 1 prim + ]` leave different numbers of values. The true branch leaves the result of `prim +`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves `acc`.
hint: The false branch takes the result of `prim seq-int.at` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty locals { xs } { xs xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs idx } {
    idx 0 prim <
    [ result ]
    [ xs idx prim seq-int.at result prim seq-int.push xs idx 1 prim - reverse-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 10, column 37
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs idx prim seq-int.at` in place of `xs idx prim seq-int.at result`. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 locals { xs } { xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many acc:Int^many xs:Seq Int^many idx:Int^many -- ρ sums:Seq Int^many)
  locals { result acc xs idx } {
    idx xs prim seq-int.len prim =
    [ result ]
    [ xs idx prim seq-int.at acc prim + dup result prim seq-int.push xs idx 1 prim + prefix-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 45
message: `prefix-loop` in `main` takes result:Seq Int, acc:Int, xs:Seq Int, idx:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `xs` (Int) and `0` (Int). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int Int
actual: ρ Seq Int Seq Int Int Int
hint: The second value from the top, `xs` (Int), is not what `prefix-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 10, column 52
message: `prim seq-int.push` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t38
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty locals { xs } { xs 0 filter-loop };

: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ positives:Seq Int^many)
  locals { result xs idx } {
    idx xs prim seq-int.len prim =
    [ result ]
    [ xs idx prim seq-int.at dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      xs idx 1 prim + filter-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 13, column 7
message: In the false branch of the `if` in `filter-loop` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.
expected: .. Seq Int
actual: .. Seq Int Int Int
hint: Both branches start from the stack below the `if`, so a value `prim seq-int.push` takes from there must be the one it expects at that position. Check that it gets the values it should, in its order, and push the ones it should use inside the branch, for example by writing the locals that hold them.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs prim seq-int.len 1 prim <
  [ true ]
  [ xs 0 check-sorted ]
  if;

: check-sorted
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim =
    [ true ]
    [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs idx 1 prim + check-sorted ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 3
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
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 locals { xs ys } { xs ys 0 dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many ys:Seq Int^many idx:Int^many -- ρ product:Int^many)
  locals { acc xs ys idx } {
    idx xs prim seq-int.len prim =
    [ acc ]
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim + xs ys idx 1 prim + dot-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 32
message: `dot-loop` in `main` takes acc:Int, xs:Seq Int, ys:Seq Int, idx:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `xs` (Seq Int), `ys` (Int) and `0` (Int).
expected: .. Int Seq Int Seq Int Int
actual: ρ Seq Int Seq Int Int Int
hint: The second value from the top, `ys` (Int), is not what `dot-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true locals { flags } { flags 0 check-all };

: check-all
  (forall ρ; ρ result:Bool^many flags:Seq Bool^many idx:Int^many -- ρ all:Bool^many)
  locals { result flags idx } {
    result prim not
    [ false ]
    [ idx flags prim seq-bool.len prim =
      [ true ]
      [ flags idx prim seq-bool.at
        [ flags idx 1 prim + check-all ]
        [ false ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 35
message: `check-all` in `main` takes result:Bool, flags:Seq Bool, idx:Int, bottom to top, but here it gets, bottom to top, the input `flags` (Seq Bool), `flags` (Bool) and `0` (Int). `main` calls `check-all`, which has an error of its own; this report assumes `check-all` keeps its stack effect.
expected: .. Bool Seq Bool Int
actual: ρ Seq Bool Bool Int
hint: The second value from the top, `flags` (Bool), is not what `check-all` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: check-all
at: line 15, column 9
message: In the true branch `[ flags idx 1 prim + check-all ]` of the `if` in `check-all`, `check-all` needs 3 values (result:Bool, flags:Seq Bool, idx:Int), but the branch has pushed only 2 values before it (`flags` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all`, exactly the values it takes, in this order: result:Bool, flags:Seq Bool, idx:Int. The branch already pushes `flags` and the result of `prim +`, in the place of the last 2 (flags:Seq Bool, idx:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Bool) before them, for example by writing the locals that hold it. If `check-all` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ xs 0 1 1 longest-run-loop ]
  if;

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many current-run:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs idx current-run max-run } {
    idx xs prim seq-int.len prim =
    [ current-run max-run prim < [ max-run ] [ current-run ] if ]
    [ xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim =
      [ xs idx 1 prim + current-run 1 prim + max-run longest-run-loop ]
      [ current-run max-run prim < 
        [ xs idx 1 prim + 1 max-run longest-run-loop ]
        [ xs idx 1 prim + 1 current-run longest-run-loop ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 3
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
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 search-pair };

: search-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim =
    [ false ]
    [ xs i prim seq-int.at target prim - xs i 1 prim + check-pair-inner ]
    if
  };

: check-pair-inner
  (forall ρ; ρ need:Int^many xs:Seq Int^many j:Int^many -- ρ found:Bool^many)
  locals { need xs j } {
    j xs prim seq-int.len prim =
    [ xs need prim - 1 prim + search-pair ]
    [ xs j prim seq-int.at need prim =
      [ true ]
      [ xs need j 1 prim + check-pair-inner ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-pair-inner
at: line 24, column 5
message: The two branches of `if` in `check-pair-inner` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty locals { xs } { xs 0 count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ count:Int^many)
  locals { seen xs idx } {
    idx xs prim seq-int.len prim =
    [ seen prim seq-int.len ]
    [ xs idx prim seq-int.at dup seen contains
      [ drop ]
      [ seen prim seq-int.push ]
      if
      xs idx 1 prim + count-distinct-loop
    ]
    if
  };

: contains
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { val seq } { seq 0 contains-loop };

: contains-loop
  (forall ρ; ρ seq:Seq Int^many idx:Int^many val:Int^many -- ρ found:Bool^many)
  locals { seq idx val } {
    idx seq prim seq-int.len prim =
    [ false ]
    [ seq idx prim seq-int.at val prim =
      [ true ]
      [ seq idx 1 prim + val contains-loop ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 13, column 7
message: The two branches of the `if` in `count-distinct-loop` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`. `count-distinct-loop` calls `contains`, which has an error of its own; this report assumes `contains` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: contains
at: line 21, column 30
message: The quotation run by `dip` in `contains` does not accept the stack below it (ρ Seq Int Int Int [ .. Seq Int Int Int -- .. Bool ]).
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty locals { xs ys } { xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim =
    [ result ys j merge-append-rest ]
    [ j ys prim seq-int.len prim =
      [ result xs i merge-append-rest ]
      [ xs i prim seq-int.at ys j prim seq-int.at prim <
        [ xs i prim seq-int.at result prim seq-int.push xs ys i 1 prim + j merge-loop ]
        [ ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + merge-loop ]
        if
      ]
      if
    ]
    if
  };

: merge-append-rest
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many idx:Int^many -- ρ merged:Seq Int^many)
  locals { result seq idx } {
    idx seq prim seq-int.len prim =
    [ result ]
    [ seq idx prim seq-int.at result prim seq-int.push seq idx 1 prim + merge-append-rest ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 13, column 39
message: `prim seq-int.push` in `merge-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t205 ?t204 Int ?t206
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit, the next error in `merge-loop` is at line 14, column 39. That edit was checked assuming `merge-append-rest`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: merge-append-rest
at: line 27, column 38
message: `prim seq-int.push` in `merge-append-rest` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t30
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result seq idx prim seq-int.at` in place of `seq idx prim seq-int.at result`. With that edit `merge-append-rest` checks.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim =
  [ drop { 0 } ]
  [ prim seq-int.empty swap extract-digits ]
  if;

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div extract-digits ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: extract-digits
at: line 13, column 28
message: `prim seq-int.push` in `extract-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `extract-digits` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 locals { n } { n 2 is-prime-loop };

: is-prime-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many candidate:Int^many -- ρ primes:Seq Int^many)
  locals { result n candidate } {
    candidate n prim <
    [ candidate is-prime
      [ result candidate prim seq-int.push n candidate 1 prim + is-prime-loop ]
      [ n candidate 1 prim + is-prime-loop ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  dup 2 prim <
  [ drop false ]
  [ dup 2 prim = [ true ] [ 2 check-divisor ] if ]
  if;

: check-divisor
  (forall ρ; ρ num:Int^many div:Int^many -- ρ prime:Bool^many)
  locals { num div } {
    div num prim * dup num prim < [ drop true ] [ num div prim mod 0 prim = [ false ] [ num div 1 prim + check-divisor ] if ] if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Int Seq Int. `main` calls `is-prime-loop`, which has an error of its own; this report assumes `is-prime-loop` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 4
code: firth.type.branch-mismatch
word: is-prime-loop
at: line 12, column 7
message: In the false branch of the `if` in `is-prime-loop` whose true branch is `[ result candidate prim seq-int.push n candidate 1 ...`, `is-prime-loop` needs 3 values (result:Seq Int, n:Int, candidate:Int), but the branch has pushed only 2 values before it (`n` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `is-prime-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `is-prime-loop`, exactly the values it takes, in this order: result:Seq Int, n:Int, candidate:Int. The branch already pushes `n` and the result of `prim +`, in the place of the last 2 (n:Int, candidate:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Seq Int) before them, for example by writing the locals that hold it. If `is-prime-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 4
code: firth.type.branch-mismatch
word: is-prime
at: line 22, column 47
message: The two branches of the `if` in `is-prime` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch takes the input `num` from below the `if` and leaves the result of `check-divisor`. `is-prime` calls `check-divisor`, which has an error of its own; this report assumes `check-divisor` keeps its stack effect.
hint: The false branch takes the input `num` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

error 4 of 4
code: firth.type.branch-mismatch
word: check-divisor
at: line 28, column 127
message: The two branches of the `if` in `check-divisor` whose true branch is `[ drop true ]` leave different numbers of values. The true branch takes the result of `prim *` from below the `if` and leaves `true`; the false branch leaves the result of an `if`.
hint: The true branch takes the result of `prim *` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  dup 0 prim seq-int.empty swap build-histogram locals { xs k } { xs k 0 histogram-loop };

: build-histogram
  (forall ρ; ρ k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k result } {
    result prim seq-int.len k prim =
    [ result ]
    [ 0 result prim seq-int.push k build-histogram ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many k:Int^many idx:Int^many -- ρ counts:Seq Int^many)
  locals { result xs k idx } {
    idx xs prim seq-int.len prim =
    [ result ]
    [ xs idx prim seq-int.at dup result prim seq-int.at 1 prim + result prim seq-int.set xs k idx 1 prim + histogram-loop ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 3, column 33
message: `build-histogram` in `main` takes k:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `build-histogram`, which has an error of its own; this report assumes `build-histogram` keeps its stack effect.
expected: .. Int Seq Int
actual: ρ Seq Int Int Int Seq Int Int
hint: These are the values `build-histogram` takes, in another order. To push them in its order, write `0 prim seq-int.empty` in place of `0 prim seq-int.empty swap`. With that edit, the next error in `main` is at line 3, column 69. That edit was checked assuming `histogram-loop`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: build-histogram
at: line 10, column 16
message: `prim seq-int.push` in `build-histogram` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t21 Int ?t22
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result 0` in place of `0 result`. With that edit, the next error in `build-histogram` is at line 10, column 36.

error 3 of 3
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 19, column 41
message: `prim seq-int.at` in `histogram-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t42 ?t41 Int Int ?t42
hint: The top value, `result` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim =
    [ xs ]
    [ xs xs i 1 prim - insert-element i 1 prim + insertion-sort ]
    if
  };

: insert-element
  (forall ρ; ρ xs:Seq Int^many j:Int^many key:Int^many -- ρ result:Seq Int^many)
  locals { xs j key } {
    j 0 prim =
    [ xs key j prim seq-int.set ]
    [ xs j 1 prim - prim seq-int.at key prim <
      [ xs j 1 prim - xs j prim seq-int.at xs prim seq-int.set xs j 1 prim - key insert-element ]
      [ xs key j prim seq-int.set ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: insertion-sort
at: line 10, column 24
message: `insert-element` in `insertion-sort` takes xs:Seq Int, j:Int, key:Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `xs` (Seq Int) and the result of `prim -` (Int). `insertion-sort` calls `insert-element`, which has an error of its own; this report assumes `insert-element` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Int ?t23 ?t23 Int
hint: The second value from the top, `xs` (Seq Int), is not what `insert-element` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: insert-element
at: line 22, column 7
message: The two branches of the `if` in `insert-element` whose true branch is `[ xs j 1 prim - xs j ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `xs`, the result of `prim seq-int.set` and the result of `insert-element`; the false branch leaves the result of `prim seq-int.set`.
hint: The true branch leaves 2 values more than the false branch: `xs` and the result of `prim seq-int.set` are left below the result of `insert-element`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 locals { start txs } { start txs 0 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many idx:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs idx rejected } {
    idx txs prim seq-int.len prim =
    [ balance rejected ]
    [ txs idx prim seq-int.at dup balance prim + dup 0 prim <
      [ drop drop balance rejected 1 prim + txs idx 1 prim + ledger-loop ]
      [ swap drop balance prim + txs idx 1 prim + ledger-loop ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 42
message: `ledger-loop` in `main` takes balance:Int, txs:Seq Int, idx:Int, rejected:Int, bottom to top, but here it gets, bottom to top, `start` (Seq Int), `txs` (Int), `0` (Int) and `0` (Int). `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Seq Int Int Int
actual: ρ Int Seq Int Int Int Int
hint: These are the values `ledger-loop` takes, in another order. By their names and types, `start` is for `txs`. Of the values of one type, `txs` and `0` are for `balance`, `idx` and `rejected`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 13, column 7
message: In the false branch of the `if` in `ledger-loop` whose true branch is `[ drop drop balance rejected 1 prim + ...`, `ledger-loop` needs 4 values (balance:Int, txs:Seq Int, idx:Int, rejected:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `txs` and the result of `prim +`). Earlier in the branch, the result of `prim +` and the result of `prim seq-int.at` were already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: balance:Int, txs:Seq Int, idx:Int, rejected:Int. The branch already pushes the result of `prim +`, `txs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty locals { stock items qtys whole } { stock items qtys whole 0 allocate-loop };

: allocate-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock-left allocated reasons stock items qtys whole idx } {
    idx qtys prim seq-int.len prim =
    [ stock-left allocated reasons ]
    [ items idx prim seq-int.at stock prim seq-int.at dup qtys idx prim seq-int.at prim <
      [ qtys idx prim seq-int.at allocated prim seq-int.push 0 reasons prim seq-int.push stock qtys idx prim seq-int.at stock prim seq-int.set items qtys whole idx 1 prim + allocate-loop ]
      [ dup 0 prim =
        [ drop allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock items qtys whole idx 1 prim + allocate-loop ]
        [ whole idx prim seq-bool.at
          [ drop allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock items qtys whole idx 1 prim + allocate-loop ]
          [ dup allocated prim seq-int.push reasons 1 prim seq-int.push 0 stock prim seq-int.set items qtys whole idx 1 prim + allocate-loop ]
          if
        ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 121
message: `allocate-loop` in `main` takes stock-left:Seq Int, allocated:Seq Int, reasons:Seq Int, stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, idx:Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), `stock` (Seq Bool), `items` (Seq Int), `qtys` (Seq Int), `whole` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Int Seq Int Seq Int Seq Bool Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int Int
hint: The second value from the top, `whole` (Seq Int), is not what `allocate-loop` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 21, column 7
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 3 values, and the false branch takes 2 values from the stack below the `if` and leaves 3 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
