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
      xs swap swap sum-loop
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
code: firth.type.word-input-mismatch
word: sum-loop
at: line 9, column 20
message: `sum-loop` in `sum-loop` takes xs:Seq Int, i:Int, accum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at accum prim +` and `i 1 prim +` are for `i` and `accum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs swap swap max-loop
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
On the example, the run failed:
code: firth.type.word-input-mismatch
word: max-loop
at: line 17, column 20
message: `max-loop` in `max-loop` takes xs:Seq Int, i:Int, maxval:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at maxval prim < [ maxval ] [ xs i prim seq-int.at ] if` and `i 1 prim +` are for `i` and `maxval`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs k swap swap count-loop
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
code: firth.type.word-input-mismatch
word: count-loop
at: line 16, column 22
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, i:Int, accum:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `k` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: These are the values `count-loop` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ accum 1 prim + ] [ accum ] if` and `i 1 prim +` are for `i` and `accum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
        xs x swap find-loop
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
code: firth.type.word-input-mismatch
word: find-loop
at: line 13, column 19
message: `find-loop` in `find-loop` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `x` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int ?t56 ?t57
hint: These are the values `find-loop` takes, in another order. To push them in its order, write `xs x i 1 prim +` in place of `i 1 prim + xs x swap`. With that edit `find-loop` checks.

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
      xs swap swap reverse-loop
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
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 8, column 14
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `reverse-loop` checks.

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
      xs swap swap swap prefix-loop
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
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 9, column 14
message: `prim seq-int.push` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t35
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
        result
      ]
      [
        result prim seq-int.push
      ]
      if
      i 1 prim +
      xs swap filter-loop
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
at: line 16, column 7
message: In the false branch of the `if` in `filter-loop` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.
expected: .. Seq Int
actual: .. Seq Int Int Int
hint: Both branches start from the stack below the `if`, so a value `prim seq-int.push` takes from there must be the one it expects at that position. Check that it gets the values it should, in its order, and push the ones it should use inside the branch, for example by writing the locals that hold them.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 30, column 26
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
        xs swap check-sorted
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
      1 xs swap check-sorted
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
message: The two branches of `if` in `check-sorted` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 36, column 5
message: The two branches of `if` in `main` leave different stacks. Below the condition and the two quotations the stack is ρ; the true branch leaves ρ Int and the false branch leaves ρ Bool. `main` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
expected: ρ Int
actual: ρ Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
      xs ys swap swap dot-loop
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
code: firth.type.word-input-mismatch
word: dot-loop
at: line 12, column 23
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, accum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * accum prim +` and `i 1 prim +` are for `i` and `accum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
        flags swap check-all
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
message: The two branches of `if` in `check-all` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Bool and the false branch leaves .. Int.
expected: .. Bool
actual: .. Int
hint: Both leave 1 value, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
        xs swap swap current-val swap max-len find-run-length
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
        xs swap swap swap find-run-length
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
      xs swap swap swap find-run-length
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: find-run-length
at: line 12, column 47
message: `find-run-length` in `find-run-length` takes xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `current-val` (Int), `xs` (Seq Int) and `max-len` (Int).
expected: .. Seq Int Int Int Int Int
actual: .. Int Int ?t99 ?t100 ?t98
hint: These are the values `find-run-length` takes, in another order. By their names and types, `xs` is for `xs`, `current-val` is for `current-val` and `max-len` is for `max-len`. Of the values of one type, `current-len 1 prim +` and `i 1 prim +` are for `i` and `current-len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 56, column 25
message: `find-run-length` in `main` takes xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `1` (Int), `0` (Int), `xs` (Seq Int) and `0` (Int). `main` calls `find-run-length`, which has an error of its own; this report assumes `find-run-length` keeps its stack effect.
expected: .. Seq Int Int Int Int Int
actual: .. Int Int Int Seq Int Int
hint: These are the values `find-run-length` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at`, `1` and `0` are for `i`, `current-val`, `current-len` and `max-len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-for-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many len:Int^many skip-idx:Int^many -- ρ result:Bool^many)
  locals { xs val j len skip-idx }
  {
    j len prim <
    [
      j skip-idx prim =
      [
        j 1 prim +
        xs val swap len skip-idx check-for-value
      ]
      [
        xs j prim seq-int.at
        val prim =
        [
          1
        ]
        [
          j 1 prim +
          xs val swap len skip-idx check-for-value
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
        xs target swap check-pair
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
code: firth.type.word-input-mismatch
word: check-for-value
at: line 10, column 34
message: `check-for-value` in `check-for-value` takes xs:Seq Int, val:Int, j:Int, len:Int, skip-idx:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `val` (Int), `xs` (Seq Int), `len` (Int) and `skip-idx` (Int).
expected: .. Seq Int Int Int Int Int
actual: .. Int ?t87 ?t88 ?t86 ?t85
hint: These are the values `check-for-value` takes, in another order. To push them in its order, write `xs val j 1 prim + len skip-idx` in place of `j 1 prim + xs val swap len skip-idx`. With that edit, the next error in `check-for-value` is at line 19, column 36.

error 2 of 2
code: firth.type.branch-mismatch
word: check-pair
at: line 55, column 5
message: In the true branch `[ xs i prim seq-int.at target prim - ...` of the `if` in `check-pair`, `check-for-value` needs 5 values (xs:Seq Int, val:Int, j:Int, len:Int, skip-idx:Int), but the branch has pushed only 3 values before it (the result of `prim -`, the result of `prim seq-int.len` and `0`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `check-pair` calls `check-for-value`, which has an error of its own; this report assumes `check-for-value` keeps its stack effect.
hint: Make the branch push, just before `check-for-value`, exactly the values it takes, in this order: xs:Seq Int, val:Int, j:Int, len:Int, skip-idx:Int. The branch already pushes the result of `prim -`, the result of `prim seq-int.len` and `0`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-for-value` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
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
        seen val swap search-in-seq
      ]
      if
    ]
    [
      0
    ]
    if
  };

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
        i 1 prim +
        xs swap swap count-distinct-loop
      ]
      [
        i 1 prim +
        xs swap seen count count-distinct-loop
      ]
      if
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 prim seq-int.empty 0 count-distinct-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: search-in-seq
at: line 14, column 23
message: `search-in-seq` in `search-in-seq` takes seen:Seq Int, val:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `val` (Int) and `seen` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int ?t50 ?t51
hint: These are the values `search-in-seq` takes, in another order. To push them in its order, write `seen val j 1 prim +` in place of `j 1 prim + seen val swap`. With that edit, the next error in `search-in-seq` is at line 15, column 7.

error 2 of 2
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 49, column 5
message: In the true branch `[ xs i prim seq-int.at 0 search-in-seq [ ...` of the `if` in `count-distinct-loop`, `search-in-seq` needs 3 values (seen:Seq Int, val:Int, j:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and `0`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-distinct-loop` calls `search-in-seq`, which has an error of its own; this report assumes `search-in-seq` keeps its stack effect.
hint: Make the branch push, just before `search-in-seq`, exactly the values it takes, in this order: seen:Seq Int, val:Int, j:Int. The branch already pushes the result of `prim seq-int.at` and `0`, in the place of the last 2 (val:Int, j:Int): keep each where it has that type and replace it where it does not. Then push the first one (seen:Seq Int) before them, for example by writing the locals that hold it. If `search-in-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
        xs ys swap j swap result merge-loop
      ]
      [
        ys j prim seq-int.at
        result prim seq-int.push
        j 1 prim +
        xs ys i swap swap result merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        xs ys swap j swap result merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at
          result prim seq-int.push
          j 1 prim +
          xs ys i swap swap result merge-loop
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
at: line 44, column 9
message: The two branches of the `if` in `merge-loop` whose true branch is `[ ys j prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `merge-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
      result n prim seq-int.push
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
at: line 12, column 14
message: `prim seq-int.push` in `extract-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t30
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `extract-digits` checks.

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
        n swap is-prime
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
        candidate 1 prim +
        limit swap result collect-primes
      ]
      [
        candidate 1 prim +
        limit swap result collect-primes
      ]
      if
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
message: The two branches of `if` in `is-prime` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.branch-mismatch
word: collect-primes
at: line 39, column 7
message: The two branches of the `if` in `collect-primes` whose true branch is `[ candidate result prim seq-int.push candidate 1 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `collect-primes`; the false branch leaves the result of `collect-primes`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `collect-primes`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i counts }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup
      counts swap prim seq-int.at
      1 prim +
      counts swap swap prim seq-int.set
      i 1 prim +
      xs swap counts histogram-loop
    ]
    [
      counts
    ]
    if
  };

: init-counts
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i counts }
  {
    i k prim <
    [
      0 counts prim seq-int.push
      i 1 prim +
      k swap counts init-counts
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
    0 prim seq-int.empty init-counts
    0 xs swap histogram-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: histogram-loop
at: line 18, column 5
message: The two branches of the `if` in `histogram-loop` whose true branch is `[ xs i prim seq-int.at dup counts swap ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `histogram-loop`; the false branch leaves `counts`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `histogram-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.branch-mismatch
word: init-counts
at: line 34, column 5
message: The two branches of the `if` in `init-counts` whose true branch is `[ 0 counts prim seq-int.push i 1 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `init-counts`; the false branch leaves `counts`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `init-counts`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.quotation-input-mismatch
word: main
at: line 41, column 26
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Seq Int Int [ .. Int ?t5 Int Seq Int -- .. Seq Int ?t5 ]). `main` calls `init-counts`, which has an error of its own; this report assumes `init-counts` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

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
      sorted val prim seq-int.push
    ]
    [
      sorted i prim seq-int.at
      val prim <
      [
        sorted i val prim seq-int.set
        i 1 prim -
        sorted val swap insert-sorted
      ]
      [
        sorted val prim seq-int.push
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
      sorted swap swap insert-sorted
      i 1 prim +
      xs swap sorted sort-loop
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
code: firth.type.branch-mismatch
word: insert-sorted
at: line 20, column 7
message: The two branches of the `if` in `insert-sorted` whose true branch is `[ sorted i val prim seq-int.set i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-sorted`; the false branch leaves the result of `prim seq-int.push`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-sorted`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-loop
at: line 40, column 5
message: The two branches of the `if` in `sort-loop` whose true branch is `[ xs i prim seq-int.at sorted prim seq-int.len ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `insert-sorted` and the result of `sort-loop`; the false branch leaves `sorted`. `sort-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: the result of `insert-sorted` is left below the result of `sort-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
        drop
        rejected 1 prim +
      ]
      [
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
  0 0 ledger-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 18, column 7
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ drop drop rejected 1 prim + ]` leave different numbers of values. The true branch takes the result of `prim +` and the result of `prim seq-int.at` from below the `if` and leaves the result of `prim +`; the false branch takes the result of `prim +` from below the `if` and leaves the result of `prim +`.
hint: The true branch takes the result of `prim seq-int.at` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
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
      allocate-rules
      stock swap prim seq-int.set
      allocated prim seq-int.push
      reasons prim seq-int.push
      order 1 prim +
      allocate-loop
    ]
    [
      stock
      allocated
      reasons
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
at: line 59, column 5
message: In the true branch `[ items order prim seq-int.at stock swap prim ...` of the `if` in `allocate-loop`, `allocate-rules` needs 5 values (stock:Seq Int, item-idx:Int, r:Int, qtys-j:Int, whole-j:Bool), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `allocate-rules`, exactly the values it takes, in this order: stock:Seq Int, item-idx:Int, r:Int, qtys-j:Int, whole-j:Bool. The branch already pushes the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `allocate-rules` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 64, column 43
message: `allocate-loop` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, order:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `allocate-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
