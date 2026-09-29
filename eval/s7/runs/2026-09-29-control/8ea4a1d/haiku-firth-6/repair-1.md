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
  0 swap loop-max;

: loop-max
  (forall ρ; ρ max:Int^many index:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at max
      [ xs index prim seq-int.at ] [ max ] if
      index 1 prim +
      xs
      loop-max
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
at: line 3, column 10
message: `loop-max` in `main` needs Int Int Seq Int on top of the stack, but the stack before it is ρ Int Seq Int. `main` calls `loop-max`, which has an error of its own; this report assumes `loop-max` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int
hint: `loop-max` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: loop-max
at: line 17, column 5
message: The two branches of the `if` in `loop-max` whose true branch is `[ xs index prim seq-int.at max [ xs ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `loop-max`; the false branch leaves `max`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `loop-max`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 swap 0 swap loop-count;

: loop-count
  (forall ρ; ρ count:Int^many index:Int^many xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { count index xs k } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      index 1 prim +
      xs k
      loop-count
    ]
    [ count ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 17
message: `loop-count` in `main` takes count:Int, index:Int, xs:Seq Int, k:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int), `0` (Int) and the input `k` (Int).
expected: .. Int Int Seq Int Int
actual: ρ Seq Int Int Int Int
hint: The second value from the top, `0` (Int), is not what `loop-count` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  0 swap loop-index-of;

: loop-index-of
  (forall ρ; ρ found:Int^many index:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { found index xs x } {
    found 0 prim <
    [
      index xs prim seq-int.len prim <
      [
        xs index prim seq-int.at x prim =
        [
          index
          index 1 prim +
          xs x
          loop-index-of
        ]
        [
          -1
          index 1 prim +
          xs x
          loop-index-of
        ]
        if
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 10
message: `loop-index-of` in `main` needs Int Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int.
expected: .. Int Int Seq Int Int
actual: ρ Seq Int Int Int
hint: `loop-index-of` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty 0 swap loop-reverse;

: loop-reverse
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at result prim seq-int.push
      index 1 prim +
      xs
      loop-reverse
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-reverse
at: line 10, column 39
message: `prim seq-int.push` in `loop-reverse` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs index prim seq-int.at` in place of `xs index prim seq-int.at result`. With that edit `loop-reverse` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 swap 0 swap loop-prefix;

: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many index:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at sum prim +
      result swap prim seq-int.push
      index 1 prim +
      xs
      loop-prefix
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-prefix
at: line 17, column 5
message: In the true branch `[ xs index prim seq-int.at sum prim + ...` of the `if` in `loop-prefix`, `loop-prefix` needs 4 values (result:Seq Int, sum:Int, index:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-prefix`, exactly the values it takes, in this order: result:Seq Int, sum:Int, index:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-prefix` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 swap loop-keep-positive;

: loop-keep-positive
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      dup 0 prim <
      [
        drop result
      ]
      [
        result swap prim seq-int.push
      ]
      if
      index 1 prim +
      xs
      loop-keep-positive
    ]
    [ result ]
    if
  };

```
On the example, it returned [[3, -1, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  true 0 swap loop-is-sorted;

: loop-is-sorted
  (forall ρ; ρ is-sorted:Bool^many index:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { is-sorted index xs } {
    is-sorted
    [
      index 1 prim + xs prim seq-int.len prim < 
      [
        xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim <
        [ false ]
        [ true ]
        if
        index 1 prim +
        xs
        loop-is-sorted
      ]
      [ is-sorted ]
      if
    ]
    [ is-sorted ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 15
message: `loop-is-sorted` in `main` takes is-sorted:Bool, index:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and `true` (Bool).
expected: .. Bool Int Seq Int
actual: ρ Seq Int Int Bool
hint: The top value, `true` (Bool), is not what `loop-is-sorted` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 swap 0 swap loop-dot;

: loop-dot
  (forall ρ; ρ sum:Int^many index:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum index xs ys } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at ys index prim seq-int.at prim * sum prim +
      index 1 prim +
      xs ys
      loop-dot
    ]
    [ sum ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 17
message: `loop-dot` in `main` takes sum:Int, index:Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int), `0` (Int) and the input `ys` (Seq Int).
expected: .. Int Int Seq Int Seq Int
actual: ρ Seq Int Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `loop-dot` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true 0 swap loop-all-true;

: loop-all-true
  (forall ρ; ρ result:Bool^many index:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result index flags } {
    index flags prim seq-bool.len prim <
    [
      result
      [
        flags index prim seq-bool.at
        [
          true
          index 1 prim +
          flags
          loop-all-true
        ]
        [ false ]
        if
      ]
      [ false ]
      if
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 15
message: `loop-all-true` in `main` takes result:Bool, index:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, the input `flags` (Seq Bool), `0` (Int) and `true` (Bool).
expected: .. Bool Int Seq Bool
actual: ρ Seq Bool Int Bool
hint: The top value, `true` (Bool), is not what `loop-all-true` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 0 1 swap 0 swap loop-longest-run;

: loop-longest-run
  (forall ρ; ρ max-len:Int^many current-len:Int^many index:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-len current-len index xs } {
    index xs prim seq-int.len prim <
    [
      index 0 prim =
      [
        index 1 prim +
        xs
        loop-longest-run
      ]
      [
        xs index prim seq-int.at xs index 1 prim - prim seq-int.at prim =
        [
          current-len 1 prim + 
          current-len 1 prim + max-len prim <
          [ current-len 1 prim + ]
          [ max-len ]
          if
          index 1 prim +
          xs
          loop-longest-run
        ]
        [
          max-len current-len prim <
          [ current-len ]
          [ max-len ]
          if
          1 index 1 prim +
          xs
          loop-longest-run
        ]
        if
      ]
      if
    ]
    [ max-len current-len prim < [ current-len ] [ max-len ] if ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 21
message: `loop-longest-run` in `main` takes max-len:Int, current-len:Int, index:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), `1` (Int), `0` (Int) and `0` (Int). `main` calls `loop-longest-run`, which has an error of its own; this report assumes `loop-longest-run` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Seq Int Int Int Int Int
hint: The top value, `0` (Int), is not what `loop-longest-run` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: loop-longest-run
at: line 39, column 7
message: In the true branch `[ index 1 prim + xs loop-longest-run ]` of the `if` in `loop-longest-run`, `loop-longest-run` needs 4 values (max-len:Int, current-len:Int, index:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-longest-run`, exactly the values it takes, in this order: max-len:Int, current-len:Int, index:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `loop-longest-run` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false 0 swap loop-has-pair;

: loop-has-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { found i xs target } {
    found prim not
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + 0 swap loop-inner-pair
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: loop-inner-pair
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true
        i 1 prim +
        xs target
        loop-has-pair
      ]
      [
        j 1 prim +
        i xs target
        loop-inner-pair
      ]
      if
    ]
    [
      i 1 prim +
      xs target
      loop-has-pair
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 3, column 16
message: `loop-has-pair` in `main` takes found:Bool, i:Int, xs:Seq Int, target:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `target` (Int), `0` (Int) and `false` (Bool). `main` calls `loop-has-pair`, which has an error of its own; this report assumes `loop-has-pair` keeps its stack effect.
expected: .. Bool Int Seq Int Int
actual: ρ Seq Int Int Int Bool
hint: The top value, `false` (Bool), is not what `loop-has-pair` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: loop-has-pair
at: line 15, column 7
message: In the true branch `[ i 1 prim + 0 swap loop-inner-pair ]` of the `if` in `loop-has-pair`, `loop-inner-pair` needs 4 values (j:Int, i:Int, xs:Seq Int, target:Int), but the branch has pushed only 2 values before it (`0` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `loop-has-pair` calls `loop-inner-pair`, which has an error of its own; this report assumes `loop-inner-pair` keeps its stack effect.
hint: Make the branch push, just before `loop-inner-pair`, exactly the values it takes, in this order: j:Int, i:Int, xs:Seq Int, target:Int. The branch already pushes `0` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `loop-inner-pair` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: loop-inner-pair
at: line 45, column 5
message: In the false branch of the `if` in `loop-inner-pair` whose true branch is `[ xs i prim seq-int.at xs j prim ...`, `loop-has-pair` needs 4 values (found:Bool, i:Int, xs:Seq Int, target:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `loop-inner-pair` calls `loop-has-pair`, which has an error of its own; this report assumes `loop-has-pair` keeps its stack effect.
hint: Make the branch push, just before `loop-has-pair`, exactly the values it takes, in this order: found:Bool, i:Int, xs:Seq Int, target:Int. The branch already pushes the result of `prim +`, `xs` and `target`, in the place of the last 3 (i:Int, xs:Seq Int, target:Int): keep each where it has that type and replace it where it does not. Then push the first one (found:Bool) before them, for example by writing the locals that hold it. If `loop-has-pair` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 swap loop-count-distinct;

: loop-count-distinct
  (forall ρ; ρ seen:Seq Int^many index:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at 0 swap find-in-seq
      [
        seen
      ]
      [
        seen xs index prim seq-int.at prim seq-int.push
      ]
      if
      index 1 prim +
      xs
      loop-count-distinct
    ]
    [ seen prim seq-int.len ]
    if
  };

: find-in-seq
  (forall ρ; ρ target:Int^many i:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { target i seq } {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at target prim =
      [
        true
      ]
      [
        target i 1 prim + seq find-in-seq
      ]
      if
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-count-distinct
at: line 23, column 5
message: In the true branch `[ xs index prim seq-int.at 0 swap find-in-seq ...` of the `if` in `loop-count-distinct`, `find-in-seq` needs 3 values (target:Int, i:Int, seq:Seq Int), but the branch has pushed only 2 values before it (`0` and the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-in-seq`, exactly the values it takes, in this order: target:Int, i:Int, seq:Seq Int. The branch already pushes `0` and the result of `prim seq-int.at`, in the place of the first 2 (target:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (seq:Seq Int) after them, for example by writing the locals that hold it. If `find-in-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 swap 0 swap loop-merge;

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys loop-merge
        ]
        [
          result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys loop-merge
        ]
        if
      ]
      [
        i xs prim seq-int.len prim <
        [
          result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys loop-merge
        ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys loop-merge
      ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 36
message: `loop-merge` in `main` takes result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), `0` (Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int).
expected: .. Seq Int Int Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `loop-merge` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  prim seq-int.empty swap 0 swap loop-digits;

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many index:Int^many -- ρ digits:Seq Int^many)
  locals { result n index } {
    n 0 prim =
    [
      result prim seq-int.len 0 prim =
      [
        prim seq-int.empty 0 prim seq-int.push
      ]
      [ result ]
      if
    ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div index 1 prim +
      loop-digits-helper
    ]
    if
  };

: loop-digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many index:Int^many -- ρ digits:Seq Int^many)
  locals { result n index } {
    n 0 prim =
    [
      result prim seq-int.empty 0 swap loop-reverse
    ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div index 1 prim +
      loop-digits-helper
    ]
    if
  };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at result prim seq-int.push
      index 1 prim +
      xs
      loop-reverse
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: loop-digits
at: line 18, column 28
message: `prim seq-int.push` in `loop-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t39 Int ?t40
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `loop-digits` checks. That edit was checked assuming `loop-digits-helper`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: loop-digits-helper
at: line 33, column 28
message: `prim seq-int.push` in `loop-digits-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t31 Int ?t32
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `loop-digits-helper` checks. That edit was checked assuming `loop-reverse`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.type.primitive-input-mismatch
word: loop-reverse
at: line 45, column 39
message: `prim seq-int.push` in `loop-reverse` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs index prim seq-int.at` in place of `xs index prim seq-int.at result`. With that edit `loop-reverse` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 swap loop-primes;

: loop-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not
    [
      candidate n prim <
      [
        candidate 2 swap is-prime
        [
          result candidate prim seq-int.push candidate 1 prim + n loop-primes
        ]
        [
          candidate 1 prim + n loop-primes
        ]
        if
      ]
      [ result ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [
      candidate divisor prim mod 0 prim =
      [
        false divisor 1 prim + swap is-prime
      ]
      [
        divisor 1 prim + candidate is-prime
      ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 3, column 29
message: `loop-primes` in `main` takes result:Seq Int, candidate:Int, n:Int, bottom to top, but here it gets, bottom to top, the input `n` (Int), `2` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `loop-primes`, which has an error of its own; this report assumes `loop-primes` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value, the result of `prim seq-int.empty` (Seq Int), is not what `loop-primes` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: loop-primes
at: line 19, column 9
message: In the false branch of the `if` in `loop-primes` whose true branch is `[ result candidate prim seq-int.push candidate 1 prim ...`, `loop-primes` needs 3 values (result:Seq Int, candidate:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `loop-primes` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `loop-primes`, exactly the values it takes, in this order: result:Seq Int, candidate:Int, n:Int. The branch already pushes the result of `prim +` and `n`, in the place of the last 2 (candidate:Int, n:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Seq Int) before them, for example by writing the locals that hold it. If `loop-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: is-prime
at: line 35, column 37
message: `is-prime` in `is-prime` takes candidate:Int, divisor:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `false` (Bool).
expected: .. Int Int
actual: .. Int Bool
hint: The top value, `false` (Bool), is not what `is-prime` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  0 swap loop-histogram;

: loop-histogram
  (forall ρ; ρ result:Seq Int^many v:Int^many xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { result v xs k } {
    v k prim <
    [
      0 0 swap xs v count-value
      result swap prim seq-int.push v 1 prim + xs k loop-histogram
    ]
    [ result ]
    if
  };

: count-value
  (forall ρ; ρ count:Int^many index:Int^many xs:Seq Int^many v:Int^many -- ρ total:Int^many)
  locals { count index xs v } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at v prim =
      [ count 1 prim + ]
      [ count ]
      if
      index 1 prim +
      xs v
      count-value
    ]
    [ count ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 10
message: `loop-histogram` in `main` needs Seq Int Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int.
expected: .. Seq Int Int Seq Int Int
actual: ρ Seq Int Int Int
hint: `loop-histogram` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 swap loop-sort;

: loop-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      i 0 swap find-min-from
      xs swap i prim seq-int.set i 1 prim + loop-sort
    ]
    [ xs ]
    if
  };

: find-min-from
  (forall ρ; ρ min-idx:Int^many j:Int^many xs:Seq Int^many -- ρ min-val:Int^many)
  locals { min-idx j xs } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at xs min-idx prim seq-int.at prim <
      [ j ]
      [ min-idx ]
      if
      j 1 prim +
      xs
      find-min-from
    ]
    [ xs min-idx prim seq-int.at ]
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
word: loop-sort
at: line 14, column 5
message: In the true branch `[ i 0 swap find-min-from xs swap i ...` of the `if` in `loop-sort`, `find-min-from` needs 3 values (min-idx:Int, j:Int, xs:Seq Int), but the branch has pushed only 2 values before it (`0` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-min-from`, exactly the values it takes, in this order: min-idx:Int, j:Int, xs:Seq Int. The branch already pushes `0` and `i`, in the place of the first 2 (min-idx:Int, j:Int): keep each where it has that type and replace it where it does not. Then push the last one (xs:Seq Int) after them, for example by writing the locals that hold it. If `find-min-from` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ final:Int^many rejected:Int^many)
  0 swap 0 swap loop-ledger;

: loop-ledger
  (forall ρ; ρ current:Int^many index:Int^many balance:Int^many rejected:Int^many txs:Seq Int^many -- ρ final:Int^many rejected:Int^many)
  locals { current index balance rejected txs } {
    index txs prim seq-int.len prim <
    [
      txs index prim seq-int.at current prim + 0 prim <
      [
        current index 1 prim + balance rejected 1 prim + txs loop-ledger
      ]
      [
        txs index prim seq-int.at current prim + index 1 prim + balance rejected txs loop-ledger
      ]
      if
    ]
    [ current rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 17
message: `loop-ledger` in `main` needs Int Int Int Int Seq Int on top of the stack, but the stack before it is ρ Int Int Int Seq Int.
expected: .. Int Int Int Int Seq Int
actual: ρ Int Int Int Seq Int
hint: `loop-ledger` takes 5 values but only 4 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 swap loop-allocate;

: loop-allocate
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock-left allocated reasons order stock items qtys whole } {
    order qtys prim seq-int.len prim <
    [
      items order prim seq-int.at stock prim seq-int.at
      qtys order prim seq-int.at
      dup swap prim <
      [
        allocated swap prim seq-int.push
        reasons 0 prim seq-int.push
        items order prim seq-int.at swap stock-left prim seq-int.set
      ]
      [
        drop dup 0 prim =
        [
          drop allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
        ]
        [
          whole order prim seq-bool.at
          [
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
          ]
          [
            allocated swap prim seq-int.push
            reasons 1 prim seq-int.push
            items order prim seq-int.at 0 stock-left prim seq-int.set
          ]
          if
        ]
        if
      ]
      if
      order 1 prim + stock items qtys whole loop-allocate
    ]
    [ stock-left allocated reasons ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 67
message: `loop-allocate` in `main` takes stock-left:Seq Int, allocated:Seq Int, reasons:Seq Int, order:Int, stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `loop-allocate`, which has an error of its own; this report assumes `loop-allocate` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Int Seq Int Seq Int Seq Int Seq Bool
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int Seq Int
hint: The top value, the result of `prim seq-int.empty` (Seq Int), is not what `loop-allocate` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: loop-allocate
at: line 37, column 9
message: The two branches of `if` in `loop-allocate` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 2 values, and the false branch takes 1 value from the stack below the `if` and leaves 3 values. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.
