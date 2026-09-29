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
  0 locals { xs sum } { xs sum 0 sum-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many sum:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs sum i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      xs sum i 1 prim + sum-loop
    ]
    [
      sum
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 16, column 5
message: The two branches of the `if` in `sum-loop` whose true branch is `[ xs i prim seq-int.at sum prim + ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `sum-loop`; the false branch leaves `sum`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `sum-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at locals { xs max } { xs max 1 max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs max i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max prim <
      [
        xs i prim seq-int.at
      ]
      [
        max
      ]
      if
      xs i 1 prim + max-loop
    ]
    [
      max
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
code: firth.type.word-input-mismatch
word: max-loop
at: line 18, column 21
message: `max-loop` in `max-loop` takes xs:Seq Int, max:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if` and `i 1 prim +` are for `max` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 locals { xs k count } { xs k count 0 count-loop };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k count i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      xs k count i 1 prim + count-loop
    ]
    [
      count
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 23, column 5
message: The two branches of the `if` in `count-loop` whose true branch is `[ xs i prim seq-int.at k prim < ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of an `if` and the result of `count-loop`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: the result of an `if` is left below the result of `count-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  -1 locals { xs x idx } { xs x idx 0 search-loop };

: search-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x idx i } {
    idx -1 prim =
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at x prim =
        [
          i
        ]
        [
          -1
        ]
        if
        xs x i 1 prim + search-loop
      ]
      [
        -1
      ]
      if
    ]
    [
      idx
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: search-loop
at: line 20, column 25
message: `search-loop` in `search-loop` takes xs:Seq Int, x:Int, idx:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), `x` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: These are the values `search-loop` takes, in another order. By their names and types, `xs` is for `xs` and `x` is for `x`. Of the values of one type, `xs i prim seq-int.at x prim = [ i ] [ -1 ] if` and `i 1 prim +` are for `idx` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty locals { xs rev } { xs rev xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many rev:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs rev i } {
    0 i prim <
    [
      xs i prim seq-int.at rev prim seq-int.push
      xs rev i 1 prim - reverse-loop
    ]
    [
      rev
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 16, column 5
message: The two branches of the `if` in `reverse-loop` whose true branch is `[ xs i prim seq-int.at rev prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-loop`; the false branch leaves `rev`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `reverse-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 locals { xs result sum } { xs result sum 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs result sum i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      result swap prim seq-int.push
      xs result i 1 prim + prefix-loop
    ]
    [
      result
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 12, column 28
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, result:Seq Int, sum:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `result` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Seq Int Seq Int Seq Int Int
hint: The second value from the top, `result` (Seq Int), is not what `prefix-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty locals { xs result } { xs result 0 filter-loop };

: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        xs i prim seq-int.at result prim seq-int.push
      ]
      [
        result
      ]
      if
      xs i 1 prim + filter-loop
    ]
    [
      result
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: filter-loop
at: line 12, column 37
message: `prim seq-int.push` in `filter-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t46
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `filter-loop` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  true locals { xs sorted } { xs sorted 0 check-sorted };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many sorted:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { xs sorted i } {
    sorted
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not
        [
          false
        ]
        [
          true
        ]
        if
        xs i 1 prim + check-sorted
      ]
      [
        true
      ]
      if
    ]
    [
      false
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-sorted
at: line 20, column 23
message: `check-sorted` in `check-sorted` takes xs:Seq Int, sorted:Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Bool), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Bool Int
actual: .. Bool Seq Int Int
hint: These are the values `check-sorted` takes, in another order. To push them in its order, write `xs xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not [ false ] [ true ] if i 1 prim +` in place of `xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not [ false ] [ true ] if xs i 1 prim +`. With that edit `check-sorted` checks.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 locals { xs ys acc } { xs ys acc 0 dot-loop };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs ys acc i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      acc prim +
      xs ys acc i 1 prim + dot-loop
    ]
    [
      acc
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 17, column 5
message: The two branches of the `if` in `dot-loop` whose true branch is `[ xs i prim seq-int.at ys i prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `dot-loop`; the false branch leaves `acc`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `dot-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true locals { flags all } { flags all 0 check-all };

: check-all
  (forall ρ; ρ flags:Seq Bool^many all:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags all i } {
    all
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at prim not
        [
          false
        ]
        [
          true
        ]
        if
        flags i 1 prim + check-all
      ]
      [
        true
      ]
      if
    ]
    [
      false
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-all
at: line 20, column 26
message: `check-all` in `check-all` takes flags:Seq Bool, all:Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Bool), `flags` (Seq Bool) and the result of `prim +` (Int).
expected: .. Seq Bool Bool Int
actual: .. Bool Seq Bool Int
hint: These are the values `check-all` takes, in another order. To push them in its order, write `flags flags i prim seq-bool.at prim not [ false ] [ true ] if i 1 prim +` in place of `flags i prim seq-bool.at prim not [ false ] [ true ] if flags i 1 prim +`. With that edit `check-all` checks.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 locals { xs maxlen } { xs maxlen 0 1 run-loop };

: run-loop
  (forall ρ; ρ xs:Seq Int^many maxlen:Int^many i:Int^many runlen:Int^many -- ρ result:Int^many)
  locals { xs maxlen i runlen } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        1
      ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          runlen 1 prim +
        ]
        [
          1
        ]
        if
      ]
      if
      runlen prim swap maxlen prim <
      [
        runlen
      ]
      [
        maxlen
      ]
      if
      xs maxlen i 1 prim + run-loop
    ]
    [
      maxlen
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 25, column 19
message: Unexpected `swap`, expected `primitive name`.
expected: primitive name
actual: swap
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
  false locals { xs target found } { xs target found 0 pair-search };

: pair-search
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { xs target found i } {
    found
    [
      true
    ]
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + locals { j } { j i 1 prim + pair-inner }
      ]
      [
        false
      ]
      if
    ]
    if
  };

: pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true
      ]
      [
        xs target i j 1 prim + pair-inner
      ]
      if
    ]
    [
      xs target i 1 prim + pair-search
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: pair-search
at: line 20, column 7
message: In the true branch `[ i 1 prim + locals { j ...` of the `if` in `pair-search`, `pair-inner` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 2 values before it (`j` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `pair-search` calls `pair-inner`, which has an error of its own; this report assumes `pair-inner` keeps its stack effect.
hint: Make the branch push, just before `pair-inner`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes `j` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `pair-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: pair-inner
at: line 42, column 5
message: In the false branch of the `if` in `pair-inner` whose true branch is `[ xs i prim seq-int.at xs j prim ...`, `pair-search` needs 4 values (xs:Seq Int, target:Int, found:Bool, i:Int), but the branch has pushed only 3 values before it (`xs`, `target` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `pair-inner` calls `pair-search`, which has an error of its own; this report assumes `pair-search` keeps its stack effect.
hint: Make the branch push, just before `pair-search`, exactly the values it takes, in this order: xs:Seq Int, target:Int, found:Bool, i:Int. The branch already pushes `xs`, `target` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `pair-search` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 locals { xs count } { xs count 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs count i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 i is-new-value
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      xs count i 1 prim + distinct-loop
    ]
    [
      count
    ]
    if
  };

: is-new-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many start:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs val start i } {
    i start prim <
    [
      xs i prim seq-int.at val prim =
      [
        false
      ]
      [
        xs val start i 1 prim + is-new-value
      ]
      if
    ]
    [
      true
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-loop
at: line 23, column 5
message: In the true branch `[ xs i prim seq-int.at 0 i is-new-value ...` of the `if` in `distinct-loop`, `is-new-value` needs 4 values (xs:Seq Int, val:Int, start:Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, `0` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
expected: .. Seq Int
actual: ρ
hint: Make the branch push, just before `is-new-value`, exactly the values it takes, in this order: xs:Seq Int, val:Int, start:Int, i:Int. The branch already pushes the result of `prim seq-int.at`, `0` and `i`, in the place of the last 3 (val:Int, start:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `is-new-value` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 locals { xs ys result } { xs ys result 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ res:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          xs i prim seq-int.at result prim seq-int.push
          xs ys result i 1 prim + j merge-loop
        ]
        [
          ys j prim seq-int.at result prim seq-int.push
          xs ys result i j 1 prim + merge-loop
        ]
        if
      ]
      [
        xs i prim seq-int.at result prim seq-int.push
        xs ys result i 1 prim + j merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at result prim seq-int.push
        xs ys result i j 1 prim + merge-loop
      ]
      [
        result
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
at: line 3, column 69
message: `merge-loop` in `main` takes xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `ys` (Int), `result` (Int), `0` (Int) and `0` (Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Int Int
actual: ρ Seq Int Seq Int Seq Int Int Int Int Int
hint: The third value from the top, `result` (Int), is not what `merge-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 38, column 7
message: The two branches of the `if` in `merge-loop` whose true branch is `[ ys j prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `merge-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim =
  [
    prim seq-int.empty 0 prim seq-int.push
  ]
  [
    prim seq-int.empty 0 locals { n result } { n result digits-loop }
  ]
  if;

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ res:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      result digits-loop
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
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: digits-loop
at: line 25, column 5
message: The two branches of the `if` in `digits-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `digits-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `digits-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 locals { n primes } { n primes 2 prime-loop };

: prime-loop
  (forall ρ; ρ n:Int^many primes:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { n primes i } {
    i n prim < prim not
    [
      i n prim <
    ]
    [
      true
    ]
    if
    [
      n primes i prime-loop
    ]
    [
      i 2 is-prime
      [
        i primes prim seq-int.push
      ]
      [
        primes
      ]
      if
      n primes i 1 prim + prime-loop
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  n 2 prim <
  [
    false
  ]
  [
    n 2 check-prime-divisor
  ]
  if;

: check-prime-divisor
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  d d prim * n prim <
  [
    n d prim mod 0 prim =
    [
      false
    ]
    [
      n d 1 prim + check-prime-divisor
    ]
    if
  ]
  [
    true
  ]
  if;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.word-input-mismatch
word: main
at: line 3, column 57
message: `prime-loop` in `main` takes n:Int, primes:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `n` (Seq Int), `primes` (Int) and `2` (Int). `main` calls `prime-loop`, which has an error of its own; this report assumes `prime-loop` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Int Seq Int Int Int
hint: These are the values `prime-loop` takes, in another order. By their names and types, `n` is for `primes`. Of the values of one type, `primes` and `2` are for `n` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 4
code: firth.type.branch-mismatch
word: prime-loop
at: line 30, column 5
message: The two branches of the `if` in `prime-loop` whose true branch is `[ n primes i prime-loop ]` leave different numbers of values. The true branch leaves the result of `prime-loop`; the false branch leaves 3 values, bottom to top: `i`, the result of an `if` and the result of `prime-loop`. `prime-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: The false branch leaves 2 values more than the true branch: `i` and the result of an `if` are left below the result of `prime-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 4
code: firth.name.unresolved
word: is-prime
at: line 35, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 4 of 4
code: firth.name.unresolved
word: check-prime-divisor
at: line 46, column 3
message: `d` is not a defined word, primitive or local.
actual: d
hint: `d` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n d } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty 0 locals { xs k counts } { xs k counts 0 init-hist };

: init-hist
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs k counts i } {
    i k prim <
    [
      counts 0 prim seq-int.push
      xs k counts i 1 prim + init-hist
    ]
    [
      xs k counts 0 count-hist
    ]
    if
  };

: count-hist
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs k counts i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      counts swap prim seq-int.at 1 prim +
      counts swap prim seq-int.set
      xs k counts i 1 prim + count-hist
    ]
    [
      counts
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 3, column 63
message: `init-hist` in `main` takes xs:Seq Int, k:Int, counts:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `xs` (Int), `k` (Seq Int), `counts` (Int) and `0` (Int). `main` calls `init-hist`, which has an error of its own; this report assumes `init-hist` keeps its stack effect.
expected: .. Seq Int Int Seq Int Int
actual: ρ Seq Int Int Seq Int Int Int
hint: The second value from the top, `counts` (Int), is not what `init-hist` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: init-hist
at: line 16, column 5
message: The two branches of the `if` in `init-hist` whose true branch is `[ counts 0 prim seq-int.push xs k counts ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `init-hist`; the false branch leaves the result of `count-hist`. `init-hist` calls `count-hist`, which has an error of its own; this report assumes `count-hist` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `init-hist`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.quotation-input-mismatch
word: count-hist
at: line 26, column 19
message: The quotation run by `dip` in `count-hist` does not accept the stack below it (.. Seq Int Seq Int Int Seq Int Seq Int Int ?t31 [ .. Seq Int Seq Int Int Seq Int Int Int -- .. Seq Int Seq Int Int Seq Int ]).
expected: Int
actual: Seq Int
hint: Check what the quotation body consumes against the values available under it.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs locals { xs sorted } { xs sorted sort-step };

: sort-step
  (forall ρ; ρ xs:Seq Int^many sorted:Seq Int^many -- ρ res:Seq Int^many)
  locals { xs sorted } {
    sorted prim seq-int.len 0 prim =
    [
      prim seq-int.empty
    ]
    [
      sorted 0 prim seq-int.at
      sorted 1 sorted prim seq-int.len find-min-and-remove
      prim seq-int.push
      xs sorted sort-step
    ]
    if
  };

: find-min-and-remove
  (forall ρ; ρ sorted:Seq Int^many i:Int^many min:Int^many -- ρ result:Seq Int^many)
  locals { sorted i min } {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at min prim <
      [
        sorted i prim seq-int.at
      ]
      [
        min
      ]
      if
      sorted i 1 prim + find-min-and-remove
    ]
    [
      min
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: main
at: line 3, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.type.branch-mismatch
word: sort-step
at: line 18, column 5
message: The two branches of the `if` in `sort-step` whose true branch is `[ prim seq-int.empty ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.empty`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `sort-step`. `sort-step` calls `find-min-and-remove`, which has an error of its own; this report assumes `find-min-and-remove` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `sort-step`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.word-input-mismatch
word: find-min-and-remove
at: line 34, column 25
message: `find-min-and-remove` in `find-min-and-remove` takes sorted:Seq Int, i:Int, min:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `sorted` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `find-min-and-remove` takes, in another order. By their names and types, `sorted` is for `sorted`. Of the values of one type, `sorted i prim seq-int.at min prim < [ sorted i prim seq-int.at ] [ min ] if` and `i 1 prim +` are for `i` and `min`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 locals { start txs balance rejected } { start txs balance rejected 0 apply-tx };

: apply-tx
  (forall ρ; ρ start:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { start txs balance rejected i } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      balance prim + 0 prim <
      [
        rejected 1 prim +
      ]
      [
        balance prim +
      ]
      if
      start txs i 1 prim + apply-tx
    ]
    [
      balance rejected
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 45
message: `roll 3` in `main` ran out of values: the stack before it is ρ Int Seq Int Int.
expected: .. ?t3
actual: ρ
hint: A word can only use values declared as inputs in its signature or pushed earlier in its body. Add the missing input to the signature or push it first. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: apply-tx
at: line 18, column 7
message: In the false branch of the `if` in `apply-tx` whose true branch is `[ rejected 1 prim + ]`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`balance`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `balance`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 
  locals { stock items qtys whole alloc reasons idx } 
  { stock items qtys whole alloc reasons idx process-order };

: process-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole alloc reasons idx } {
    idx qtys prim seq-int.len prim <
    [
      items idx prim seq-int.at
      stock swap prim seq-int.at
      qtys idx prim seq-int.at
      whole idx prim seq-bool.at
      determine-allocation
      stock items qtys whole alloc reasons idx 1 prim + process-order
    ]
    [
      stock alloc reasons
    ]
    if
  };

: determine-allocation
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many available:Int^many qty:Int^many full:Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  qty available prim <
  [
    available 0 prim =
    [
      alloc 0 prim seq-int.push reasons 2 prim seq-int.push
    ]
    [
      full
      [
        alloc 0 prim seq-int.push reasons 3 prim seq-int.push
      ]
      [
        alloc available prim seq-int.push reasons 1 prim seq-int.push
        stock swap available prim seq-int.set
      ]
      if
    ]
    if
  ]
  [
    alloc qty prim seq-int.push reasons 0 prim seq-int.push
    stock swap qty prim seq-int.set
  ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 5, column 46
message: `process-order` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, alloc:Seq Int, reasons:Seq Int, idx:Int, bottom to top, but here it gets, bottom to top, `stock` (Seq Int), `items` (Seq Int), `qtys` (Seq Bool), `whole` (Seq Int), `alloc` (Seq Int), `reasons` (Seq Int) and `idx` (Int). `main` calls `process-order`, which has an error of its own; this report assumes `process-order` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int Int
hint: Value 4 from the top, `whole` (Seq Int), is not what `process-order` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: process-order
at: line 22, column 5
message: In the true branch `[ items idx prim seq-int.at stock swap prim ...` of the `if` in `process-order`, `determine-allocation` needs 9 values (stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, alloc:Seq Int, reasons:Seq Int, available:Int, qty:Int, full:Bool), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`). The remaining 6 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `process-order` calls `determine-allocation`, which has an error of its own; this report assumes `determine-allocation` keeps its stack effect.
hint: Make the branch push, just before `determine-allocation`, exactly the values it takes, in this order: stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, alloc:Seq Int, reasons:Seq Int, available:Int, qty:Int, full:Bool. The branch already pushes the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`, in the place of the last 3 (available:Int, qty:Int, full:Bool): keep each where it has that type and replace it where it does not. Then push the first 6 (stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, alloc:Seq Int, reasons:Seq Int) before them, for example by writing the locals that hold them. If `determine-allocation` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.name.unresolved
word: determine-allocation
at: line 27, column 3
message: `qty` is not a defined word, primitive or local.
actual: qty
hint: `qty` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock items qtys whole alloc reasons available qty full } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
