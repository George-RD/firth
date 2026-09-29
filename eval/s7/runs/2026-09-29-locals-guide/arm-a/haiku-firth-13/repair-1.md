Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many accum:Int^many -- ρ result:Int^many)
  locals { xs i accum }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at accum prim +
      i 1 prim +
      sum-loop
    ]
    [
      accum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 sum-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 14, column 5
message: In the true branch `[ xs i prim seq-int.at accum prim + ...` of the `if` in `sum-loop`, `sum-loop` needs 3 values (xs:Seq Int, i:Int, accum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, accum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, accum:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxval:Int^many -- ρ result:Int^many)
  locals { xs i maxval }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      maxval prim <
      [
        maxval
      ]
      [
        xs i prim seq-int.at
      ]
      if
      i 1 prim +
      [ xs swap ] dip
      max-loop
    ]
    [
      maxval
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-loop };

```
On the example, it returned [1] instead of [9]

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many accum:Int^many -- ρ result:Int^many)
  locals { xs k i accum }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        accum 1 prim +
      ]
      [
        accum
      ]
      if
      i 1 prim +
      count-loop
    ]
    [
      accum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 0 count-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 21, column 5
message: In the true branch `[ xs i prim seq-int.at k prim < ...` of the `if` in `count-loop`, `count-loop` needs 4 values (xs:Seq Int, k:Int, i:Int, accum:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, accum:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [
        i
      ]
      [
        i 1 prim +
        find-loop
      ]
      if
    ]
    [
      -1
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  0 find-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 15, column 7
message: In the false branch of the `if` in `find-loop` whose true branch is `[ i ]`, `find-loop` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result }
  {
    i 0 prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      reverse-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs }
  {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 15, column 5
message: In the true branch `[ xs i prim seq-int.at result prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 24, column 5
message: `reverse-loop` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Int Seq Int. `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int
hint: `reverse-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many accum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i accum result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at accum prim +
      dup
      result prim seq-int.push
      i 1 prim +
      prefix-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs }
  {
    0 0 prim seq-int.empty prefix-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-loop
at: line 16, column 5
message: In the true branch `[ xs i prim seq-int.at accum prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, i:Int, accum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, accum:Int, result:Seq Int. The branch already pushes the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 23, column 28
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Int Seq Int Seq Int [ .. Seq Int Int Int Seq Int -- .. Seq Int ]). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 prim <
      [
        drop
      ]
      [
        result prim seq-int.push
      ]
      if
      i 1 prim +
      filter-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs }
  {
    0 prim seq-int.empty filter-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: filter-loop
at: line 15, column 7
message: The two branches of the `if` in `filter-loop` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 29, column 26
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Seq Int Seq Int [ .. Seq Int Int Seq Int -- .. Seq Int ]). `main` calls `filter-loop`, which has an error of its own; this report assumes `filter-loop` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i }
  {
    i 1 prim - xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim - prim seq-int.at
      prim <
      [
        0
      ]
      [
        i 1 prim +
        check-sorted
      ]
      if
    ]
    [
      1
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs }
  {
    xs prim seq-int.len 1 prim <
    [
      1
    ]
    [
      1 check-sorted
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-sorted
at: line 17, column 7
message: In the false branch of the `if` in `check-sorted` whose true branch is `[ 0 ]`, `check-sorted` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-sorted`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `check-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 36, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ 1 ]`, `check-sorted` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
hint: Make the branch push, just before `check-sorted`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes `1`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `check-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many accum:Int^many -- ρ product:Int^many)
  locals { xs ys i accum }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      accum prim +
      i 1 prim +
      dot-loop
    ]
    [
      accum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 17, column 5
message: In the true branch `[ xs i prim seq-int.at ys i prim ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, accum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, accum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, accum:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i }
  {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        i 1 prim +
        check-all
      ]
      [
        0
      ]
      if
    ]
    [
      1
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 check-all;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-all
at: line 15, column 7
message: In the true branch `[ i 1 prim + check-all ]` of the `if` in `check-all`, `check-all` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `check-all` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: find-run-length
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-len max-len }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      current-val prim =
      [
        current-len 1 prim +
        i 1 prim +
        find-run-length
      ]
      [
        current-len max-len prim <
        [
          current-len
        ]
        [
          max-len
        ]
        if
        xs i prim seq-int.at
        1
        i 1 prim +
        find-run-length
      ]
      if
    ]
    [
      current-len max-len prim <
      [
        current-len
      ]
      [
        max-len
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs }
  {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      xs 0 prim seq-int.at
      1
      0
      0
      find-run-length
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-run-length
at: line 28, column 7
message: In the true branch `[ current-len 1 prim + i 1 prim ...` of the `if` in `find-run-length`, `find-run-length` needs 5 values (xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-run-length`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `find-run-length` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 58, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `find-run-length` needs 5 values (xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.at`, `1`, `0` and `0`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `find-run-length`, which has an error of its own; this report assumes `find-run-length` keeps its stack effect.
hint: Make the branch push, just before `find-run-length`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int. The branch already pushes the result of `prim seq-int.at`, `1`, `0` and `0`, in the place of the last 4 (i:Int, current-val:Int, current-len:Int, max-len:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `find-run-length` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      target prim -
      xs prim seq-int.len
      0
      check-for-value
      [
        1
      ]
      [
        i 1 prim +
        check-pair
      ]
      if
    ]
    [
      0
    ]
    if
  };

: check-for-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many len:Int^many skip-idx:Int^many -- ρ result:Bool^many)
  locals { xs val j len skip-idx }
  {
    j len prim <
    [
      j skip-idx prim =
      [
        j 1 prim +
        check-for-value
      ]
      [
        xs j prim seq-int.at
        val prim =
        [
          1
        ]
        [
          j 1 prim +
          check-for-value
        ]
        if
      ]
      if
    ]
    [
      0
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 check-pair;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-pair
at: line 19, column 7
message: In the false branch of the `if` in `check-pair` whose true branch is `[ 1 ]`, `check-pair` needs 3 values (xs:Seq Int, target:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `check-pair` calls `check-for-value`, which has an error of its own; this report assumes `check-for-value` keeps its stack effect.
hint: Make the branch push, just before `check-pair`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-pair` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: check-for-value
at: line 48, column 9
message: In the false branch of the `if` in `check-for-value` whose true branch is `[ 1 ]`, `check-for-value` needs 5 values (xs:Seq Int, val:Int, j:Int, len:Int, skip-idx:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-for-value`, exactly the values it takes, in this order: xs:Seq Int, val:Int, j:Int, len:Int, skip-idx:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 4 in their places, for example by writing the locals that hold them. If `check-for-value` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i seen count }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0
      search-in-seq
      [
        count 1 prim +
        xs i prim seq-int.at
        seen prim seq-int.push
      ]
      [
        count
      ]
      if
      i 1 prim +
      count-distinct-loop
    ]
    [
      count
    ]
    if
  };

: search-in-seq
  (forall ρ; ρ seen:Seq Int^many val:Int^many j:Int^many -- ρ found:Bool^many)
  locals { seen val j }
  {
    j seen prim seq-int.len prim <
    [
      seen j prim seq-int.at
      val prim =
      [
        1
      ]
      [
        j 1 prim +
        search-in-seq
      ]
      if
    ]
    [
      0
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 prim seq-int.empty 0 count-distinct-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 18, column 7
message: The two branches of the `if` in `count-distinct-loop` whose true branch is `[ count 1 prim + xs i prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prim seq-int.push`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.branch-mismatch
word: search-in-seq
at: line 43, column 7
message: In the false branch of the `if` in `search-in-seq` whose true branch is `[ 1 ]`, `search-in-seq` needs 3 values (seen:Seq Int, val:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `search-in-seq`, exactly the values it takes, in this order: seen:Seq Int, val:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `search-in-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 53, column 28
message: `count-distinct-loop` in `main` takes xs:Seq Int, i:Int, seen:Seq Int, count:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int Int
actual: ρ Seq Int Int Int Seq Int Int
hint: Value 4 from the top, `0` (Int), is not what `count-distinct-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result }
  {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at
      ys j prim seq-int.at
      prim <
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
      ]
      [
        ys j prim seq-int.at
        result prim seq-int.push
        j 1 prim +
      ]
      if
      merge-loop
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at
          result prim seq-int.push
          j 1 prim +
          merge-loop
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  0 0 prim seq-int.empty merge-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 43, column 9
message: In the true branch `[ ys j prim seq-int.at result prim seq-int.push ...` of the `if` in `merge-loop`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: extract-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result }
  {
    n 10 prim <
    [
      n result prim seq-int.push
    ]
    [
      n 10 prim div
      n 10 prim mod
      result prim seq-int.push
      extract-digits
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n }
  {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n prim seq-int.empty extract-digits
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: extract-digits
at: line 7, column 16
message: `prim seq-int.push` in `extract-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `n` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n` in place of `n result`. With that edit, the next error in `extract-digits` is at line 12, column 14.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d }
  {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        0
      ]
      [
        d 1 prim +
        is-prime
      ]
      if
    ]
    [
      1
    ]
    if
  };

: collect-primes
  (forall ρ; ρ limit:Int^many candidate:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { limit candidate result }
  {
    candidate limit prim <
    [
      candidate 2 is-prime
      [
        candidate result prim seq-int.push
      ]
      [
        result
      ]
      if
      candidate 1 prim +
      collect-primes
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  2 prim seq-int.empty collect-primes;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 15, column 7
message: In the false branch of the `if` in `is-prime` whose true branch is `[ 0 ]`, `is-prime` needs 2 values (n:Int, d:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime`, exactly the values it takes, in this order: n:Int, d:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: collect-primes
at: line 43, column 5
message: In the true branch `[ candidate 2 is-prime [ candidate result prim ...` of the `if` in `collect-primes`, `collect-primes` needs 3 values (limit:Int, candidate:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `collect-primes` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `collect-primes`, exactly the values it takes, in this order: limit:Int, candidate:Int, result:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `collect-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i counts }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup
      counts swap prim seq-int.at
      1 prim +
      counts swap rot prim seq-int.set
      i 1 prim +
      histogram-loop
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k }
  {
    prim seq-int.empty
    0
    loop-k
    0
    histogram-loop
  };

: loop-k
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i counts }
  {
    i k prim <
    [
      0 counts prim seq-int.push
      i 1 prim +
      loop-k
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
code: firth.name.unresolved
word: histogram-loop
at: line 11, column 19
message: `rot` is not a defined word, primitive or local.
actual: rot
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

error 2 of 3
code: firth.type.stack-underflow
word: main
at: line 29, column 5
message: `histogram-loop` needs more values than the stack holds here. `main` calls `loop-k` and `histogram-loop`, which have errors of their own; this report assumes they keep their stack effects.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `histogram-loop` and in what order.

error 3 of 3
code: firth.type.branch-mismatch
word: loop-k
at: line 45, column 5
message: In the true branch `[ 0 counts prim seq-int.push i 1 prim ...` of the `if` in `loop-k`, `loop-k` needs 3 values (k:Int, i:Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-k`, exactly the values it takes, in this order: k:Int, i:Int, counts:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-k` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int^many val:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted val i }
  {
    i 0 prim <
    [
      val sorted prim seq-int.push
    ]
    [
      sorted i prim seq-int.at
      val prim <
      [
        sorted i prim seq-int.at
        sorted i val prim seq-int.set
        i 1 prim -
        insert-sorted
      ]
      [
        val sorted prim seq-int.push
      ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      sorted prim seq-int.len 1 prim -
      insert-sorted
      i 1 prim +
      sort-loop
    ]
    [
      sorted
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: insert-sorted
at: line 7, column 18
message: `prim seq-int.push` in `insert-sorted` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `val` (Int) and `sorted` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `sorted val` in place of `val sorted`. With that edit, the next error in `insert-sorted` is at line 16, column 9.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-loop
at: line 41, column 5
message: In the true branch `[ xs i prim seq-int.at sorted prim seq-int.len ...` of the `if` in `sort-loop`, `insert-sorted` needs 3 values (sorted:Seq Int, val:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `sort-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: Make the branch push, just before `insert-sorted`, exactly the values it takes, in this order: sorted:Seq Int, val:Int, i:Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim -`, in the place of the last 2 (val:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (sorted:Seq Int) before them, for example by writing the locals that hold it. If `insert-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance txs i rejected }
  {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      dup
      balance prim + dup 0 prim <
      [
        drop
        rejected 1 prim +
      ]
      [
        drop
        balance prim +
      ]
      if
      i 1 prim +
      ledger-loop
    ]
    [
      balance
      rejected
    ]
    if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  0 ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 18, column 7
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ drop rejected 1 prim + ]` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves the result of `prim +`; the false branch takes the result of `prim +` and the result of `prim seq-int.at` from below the `if` and leaves the result of `prim +`.
hint: The false branch takes the result of `prim seq-int.at` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 31, column 5
message: `ledger-loop` in `main` needs Int Seq Int Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int. `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Seq Int Int Int
actual: ρ Int Seq Int Int
hint: `ledger-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-final:Seq Int^many allocated-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock items qtys whole order allocated reasons }
  {
    order qtys prim seq-int.len prim <
    [
      items order prim seq-int.at
      stock swap prim seq-int.at
      qtys order prim seq-int.at
      whole order prim seq-bool.at
      dup
      dup
      stock swap swap dup dup
      allocate-rules
      allocate-loop
    ]
    [
      stock
      allocated
      reasons
    ]
    if
  };

: allocate-rules
  (forall ρ; ρ stock:Seq Int^many item-idx:Int^many r:Int^many qtys-j:Int^many whole-j:Bool^many -- ρ stock-updated:Seq Int^many alloc:Int^many reason:Int^many)
  locals { stock item-idx r qtys-j whole-j }
  {
    qtys-j r prim <
    [
      stock
      qtys-j
      0
    ]
    [
      r 0 prim =
      [
        stock
        0
        2
      ]
      [
        whole-j
        [
          stock
          0
          3
        ]
        [
          stock
          r
          1
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 allocate-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 22, column 5
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 3 values, and the false branch pushes 3 values. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 63, column 43
message: `allocate-loop` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, order:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `allocate-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
