Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc }
  {
    i xs prim seq-int.len prim <
    [
      acc i xs prim seq-int.at prim +
      i 1 prim +
      xs
      sum-helper
    ]
    [
      acc
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sum-helper
at: line 7, column 16
message: `prim seq-int.at` in `sum-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `sum-helper` is at line 10, column 7.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxval:Int^many -- ρ result:Int^many)
  locals { xs i maxval }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at
      maxval
      prim <
      [
        i xs prim seq-int.at
      ]
      [
        maxval
      ]
      if
      i 1 prim +
      xs
      max-helper
    ]
    [
      maxval
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: max-helper
at: line 7, column 12
message: `prim seq-int.at` in `max-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `max-helper` is at line 11, column 14.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at k prim <
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      i 1 prim +
      xs
      k
      count-helper
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs k 0 0 count-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: count-helper
at: line 7, column 12
message: `prim seq-int.at` in `count-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `count-helper` is at line 18, column 7.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many found:Int^many -- ρ result:Int^many)
  locals { xs x i found }
  {
    found -1 prim =
    [
      i xs prim seq-int.len prim <
      [
        i xs prim seq-int.at x prim =
        [
          i
        ]
        [
          i 1 prim +
          xs
          x
          found
          index-helper
        ]
        if
      ]
      [
        -1
      ]
      if
    ]
    [
      found
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { xs x 0 -1 index-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: index-helper
at: line 9, column 14
message: `prim seq-int.at` in `index-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `index-helper` is at line 18, column 11.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result }
  {
    i 0 prim <
    [
      i xs prim seq-int.at result prim seq-int.push
      i 1 prim -
      xs
      reverse-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 7, column 12
message: `prim seq-int.at` in `reverse-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `reverse-helper` is at line 7, column 35.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result }
  {
    i xs prim seq-int.len prim <
    [
      sum i xs prim seq-int.at prim +
      result sum prim seq-int.push
      i 1 prim +
      xs
      prefix-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-helper
at: line 7, column 16
message: `prim seq-int.at` in `prefix-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `prefix-helper` is at line 11, column 7.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at
      0 prim <
      [
        result
      ]
      [
        result i xs prim seq-int.at prim seq-int.push
      ]
      if
      i 1 prim +
      xs
      keep-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: keep-helper
at: line 7, column 12
message: `prim seq-int.at` in `keep-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `keep-helper` is at line 13, column 21.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Bool^many -- ρ result:Bool^many)
  locals { xs i sorted }
  {
    sorted prim not
    [
      false
    ]
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        i xs prim seq-int.at
        i 1 prim + xs prim seq-int.at
        prim <
        [
          i 1 prim +
          xs
          true
          is-sorted-helper
        ]
        [
          false
        ]
        if
      ]
      [
        true
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs 0 true is-sorted-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: is-sorted-helper
at: line 12, column 14
message: `prim seq-int.at` in `is-sorted-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `is-sorted-helper` is at line 13, column 23.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at i ys prim seq-int.at prim * sum prim +
      i 1 prim +
      xs
      ys
      dot-helper
    ]
    [
      sum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { xs ys 0 0 dot-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: dot-helper
at: line 7, column 12
message: `prim seq-int.at` in `dot-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `dot-helper` is at line 7, column 33.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many allTrue:Bool^many -- ρ result:Bool^many)
  locals { flags i allTrue }
  {
    allTrue prim not
    [
      false
    ]
    [
      i flags prim seq-int.len prim <
      [
        i flags prim seq-int.at
        [
          i 1 prim +
          flags
          true
          all-helper
        ]
        [
          false
        ]
        if
      ]
      [
        true
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { flags 0 true all-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: all-helper
at: line 10, column 15
message: `prim seq-int.len` in `all-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: .. Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many curVal:Int^many curLen:Int^many maxLen:Int^many -- ρ result:Int^many)
  locals { xs i curVal curLen maxLen }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at curVal prim =
      [
        curLen 1 prim +
        curLen 1 prim + maxLen prim <
        [
          curLen 1 prim +
        ]
        [
          maxLen
        ]
        if
        i 1 prim +
        xs
        i xs prim seq-int.at
        run-helper
      ]
      [
        1 maxLen prim <
        [
          1
        ]
        [
          maxLen
        ]
        if
        i 1 prim +
        xs
        i xs prim seq-int.at
        run-helper
      ]
      if
    ]
    [
      maxLen
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs }
  {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      xs 1 xs 0 prim seq-int.at 1 0 run-helper
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-helper
at: line 37, column 7
message: In the false branch of the `if` in `run-helper` whose true branch is `[ curLen 1 prim + curLen 1 prim ...`, `run-helper` needs 5 values (xs:Seq Int, i:Int, curVal:Int, curLen:Int, maxLen:Int), but the branch has pushed only 4 values before it (the result of an `if`, the result of `prim +`, `xs` and the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, curVal:Int, curLen:Int, maxLen:Int. The branch already pushes the result of an `if`, the result of `prim +`, `xs` and the result of `prim seq-int.at`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target i found }
  {
    found
    [
      true
    ]
    [
      i xs prim seq-int.len prim <
      [
        target i xs prim seq-int.at prim -
        1 prim +
        xs prim seq-int.len
        1 prim +
        [ swap prim = ]
        [
          i 1 prim +
        ]
        [ ]
        call
        i 1 prim +
        xs
        target
        pair-helper
      ]
      [
        false
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs target 0 false pair-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-helper
at: line 30, column 7
message: The two branches of the `if` in `pair-helper` whose true branch is `[ target i xs prim seq-int.at prim - ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: the result of `prim +`, the result of `prim +`, the quotation `[ swap prim = ]` and the result of `pair-helper`; the false branch leaves `false`.
hint: The true branch leaves 3 values more than the false branch: the result of `prim +`, the result of `prim +` and the quotation `[ swap prim = ]` are left below the result of `pair-helper`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-count-helper
  (forall ρ; ρ xs:Seq Int^many unique:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs unique i }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at
      [ prim = ]
      [ unique prim seq-int.len ]
      [ ]
      call
      unique prim seq-int.len prim <
      [
        unique i xs prim seq-int.at prim seq-int.push
      ]
      [
        unique
      ]
      if
      i 1 prim +
      xs
      distinct-count-helper
    ]
    [
      unique prim seq-int.len
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.empty 0 distinct-count-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-count-helper
at: line 27, column 5
message: The two branches of the `if` in `distinct-count-helper` whose true branch is `[ i xs prim seq-int.at [ prim = ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, the quotation `[ prim = ]` and the result of `distinct-count-helper`; the false branch leaves the result of `prim seq-int.len`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and the quotation `[ prim = ]` are left below the result of `distinct-count-helper`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j result }
  {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      i xs prim seq-int.at j ys prim seq-int.at prim <
      [
        result i xs prim seq-int.at prim seq-int.push
        i 1 prim +
        ys
        xs
        merge-helper
      ]
      [
        result j ys prim seq-int.at prim seq-int.push
        i
        ys
        j 1 prim +
        xs
        merge-helper
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        result i xs prim seq-int.at prim seq-int.push
        i 1 prim +
        ys
        xs
        merge-helper
      ]
      [
        j ys prim seq-int.len prim <
        [
          result j ys prim seq-int.at prim seq-int.push
          i
          ys
          j 1 prim +
          xs
          merge-helper
        ]
        [
          result
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-helper
at: line 24, column 7
message: In the true branch `[ result i xs prim seq-int.at prim seq-int.push ...` of the `if` in `merge-helper`, `merge-helper` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `ys` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-helper`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +`, `ys` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `merge-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result }
  {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div
      digits-helper
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many reversed:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i reversed }
  {
    i 0 prim <
    [
      i result prim seq-int.at reversed prim seq-int.push
      i 1 prim -
      result
      reverse-digits
    ]
    [
      reversed
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n }
  {
    n 0 prim =
    [
      { 0 }
    ]
    [
      n prim seq-int.empty digits-helper
      dup prim seq-int.len 1 prim -
      prim seq-int.empty
      reverse-digits
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: digits-helper
at: line 10, column 28
message: `prim seq-int.push` in `digits-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit, the next error in `digits-helper` is at line 12, column 7.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 23, column 16
message: `prim seq-int.at` in `reverse-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `result i` in place of `i result`. With that edit, the next error in `reverse-digits` is at line 23, column 41.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-helper
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i }
  {
    i i prim * n prim <
    [
      n i prim mod 0 prim =
      [
        false
      ]
      [
        i 1 prim +
        n
        is-prime-helper
      ]
      if
    ]
    [
      true
    ]
    if
  };

: primes-helper
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result }
  {
    i n prim <
    [
      i 2 prim <
      [
        i 1 prim +
        n
        result
        primes-helper
      ]
      [
        i 2 is-prime-helper
        [
          result i prim seq-int.push
        ]
        [
          result
        ]
        if
        i 1 prim +
        n
        primes-helper
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-helper };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: primes-helper
at: line 48, column 9
message: `primes-helper` in `primes-helper` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), the result of `prim +` (Int) and `n` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t75
hint: These are the values `primes-helper` takes, in another order. To push them in its order, write `n i 1 prim + i 2 is-prime-helper [ result i prim seq-int.push ] [ result ] if` in place of `i 2 is-prime-helper [ result i prim seq-int.push ] [ result ] if i 1 prim + n`. With that edit `primes-helper` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i counts }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at
      dup
      counts prim seq-int.at
      1 prim +
      counts swap prim seq-int.set
      i 1 prim +
      xs
      k
      histogram-helper
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k }
  {
    prim seq-int.empty
    0
    [ 1 prim + dup k prim < [ 0 swap prim seq-int.push ] [ drop ] if ]
    call
    xs
    k
    histogram-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-helper
at: line 7, column 12
message: `prim seq-int.at` in `histogram-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `histogram-helper` is at line 9, column 14.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 29, column 67
message: The two branches of the `if` in `main` whose true branch is `[ 0 swap prim seq-int.push ]` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves the result of `prim seq-int.push`; the false branch takes the result of `prim +` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-helper
  (forall ρ; ρ sorted:Seq Int^many i:Int^many x:Int^many -- ρ result:Seq Int^many)
  locals { sorted i x }
  {
    i 0 prim =
    [
      x sorted prim seq-int.push
    ]
    [
      i 1 prim - dup
      sorted prim seq-int.at
      x prim <
      [
        drop sorted i prim seq-int.at x swap prim seq-int.set
        i 1 prim -
        sorted
        x
        insert-helper
      ]
      [
        drop x sorted prim seq-int.push
      ]
      if
    ]
    if
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted }
  {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at
      i
      sorted
      insert-helper
      i 1 prim +
      xs
      sort-helper
    ]
    [
      sorted
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: insert-helper
at: line 7, column 16
message: `prim seq-int.push` in `insert-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `x` (Int) and `sorted` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `sorted x` in place of `x sorted`. With that edit, the next error in `insert-helper` is at line 11, column 14.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: sort-helper
at: line 34, column 12
message: `prim seq-int.at` in `sort-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `sort-helper` is at line 37, column 7. That edit was checked assuming `insert-helper`, which has an error of its own, keeps its stack effect.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-helper
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ result1:Int^many result2:Int^many)
  locals { balance rejected txs i }
  {
    i txs prim seq-int.len prim <
    [
      balance i txs prim seq-int.at prim +
      dup 0 prim <
      [
        drop balance rejected 1 prim +
      ]
      [
        swap drop rejected
      ]
      if
      i 1 prim +
      txs
      ledger-helper
    ]
    [
      balance rejected
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ result1:Int^many result2:Int^many)
  locals { start txs } { start 0 txs 0 ledger-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-helper
at: line 15, column 7
message: In the false branch of the `if` in `ledger-helper` whose true branch is `[ drop balance rejected 1 prim + ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim +` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock_out:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item qty whole }
  {
    item stock prim seq-int.at
    dup qty prim <
    [
      drop
      qty stock prim seq-int.at prim <
      [
        drop stock qty item prim seq-int.set qty 0
      ]
      [
        whole
        [
          stock 0 3
        ]
        [
          dup
          stock item swap prim seq-int.set
          1
        ]
        if
      ]
      if
    ]
    [
      qty prim =
      [
        qty item stock prim seq-int.set
        qty 0
      ]
      [
        stock qty item prim seq-int.set qty 2
      ]
      if
    ]
    if
  };

: allocate-batch-helper
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many result_stock:Seq Int^many result_allocated:Seq Int^many result_reasons:Seq Int^many i:Int^many -- ρ stock_out:Seq Int^many allocated_out:Seq Int^many reasons_out:Seq Int^many)
  locals { stock items qtys whole result_stock result_allocated result_reasons i }
  {
    i items prim seq-int.len prim <
    [
      i items prim seq-int.at
      i qtys prim seq-int.at
      i whole prim seq-int.at
      stock
      allocate-order
      result_reasons swap prim seq-int.push
      result_allocated swap prim seq-int.push
      i 1 prim +
      items
      qtys
      whole
      allocate-batch-helper
    ]
    [
      stock result_allocated result_reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_out:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 allocate-batch-helper };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 88
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
