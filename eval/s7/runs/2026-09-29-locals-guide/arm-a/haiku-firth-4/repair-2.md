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
      acc xs i prim seq-int.at prim +
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
code: firth.type.word-input-mismatch
word: sum-helper
at: line 10, column 7
message: `sum-helper` in `sum-helper` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `acc xs i prim seq-int.at prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at
      maxval
      prim <
      [
        xs i prim seq-int.at
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
code: firth.type.word-input-mismatch
word: max-helper
at: line 19, column 7
message: `max-helper` in `max-helper` takes xs:Seq Int, i:Int, maxval:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at maxval prim < [ xs i prim seq-int.at ] [ maxval ] if` and `i 1 prim +` are for `i` and `maxval`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at k prim <
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
code: firth.type.word-input-mismatch
word: count-helper
at: line 18, column 7
message: `count-helper` in `count-helper` takes xs:Seq Int, k:Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `k` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: These are the values `count-helper` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` and `i 1 prim +` are for `i` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
        xs i prim seq-int.at x prim =
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
code: firth.type.word-input-mismatch
word: index-helper
at: line 18, column 11
message: `index-helper` in `index-helper` takes xs:Seq Int, x:Int, i:Int, found:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `x` (Int) and `found` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int ?t110 ?t109 ?t108
hint: These are the values `index-helper` takes, in another order. To push them in its order, write `xs x i 1 prim + found` in place of `i 1 prim + xs x found`. With that edit `index-helper` checks.

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
      result xs i prim seq-int.at prim seq-int.push
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
On the example, it returned [[]] instead of [[3, 2, 1]]

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
      sum xs i prim seq-int.at prim +
      result swap prim seq-int.push
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
code: firth.type.branch-mismatch
word: prefix-helper
at: line 16, column 5
message: In the true branch `[ sum xs i prim seq-int.at prim + ...` of the `if` in `prefix-helper`, `prefix-helper` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
      xs i prim seq-int.at
      0 prim <
      [
        result
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
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
On the example, it returned [[3, -1, 0, 4]] instead of [[3, 4]]

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
        xs i prim seq-int.at
        xs i 1 prim + prim seq-int.at
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
code: firth.type.word-input-mismatch
word: is-sorted-helper
at: line 19, column 11
message: `is-sorted-helper` in `is-sorted-helper` takes xs:Seq Int, i:Int, sorted:Bool, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `true` (Bool).
expected: .. Seq Int Int Bool
actual: .. Int ?t43 Bool
hint: These are the values `is-sorted-helper` takes, in another order. To push them in its order, write `xs i 1 prim + true` in place of `i 1 prim + xs true`. With that edit `is-sorted-helper` checks.

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
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
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
code: firth.type.word-input-mismatch
word: dot-helper
at: line 11, column 7
message: `dot-helper` in `dot-helper` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dot-helper` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
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
code: firth.type.word-input-mismatch
word: all-helper
at: line 17, column 11
message: `all-helper` in `all-helper` takes flags:Seq Bool, i:Int, allTrue:Bool, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `flags` (Seq Bool) and `true` (Bool).
expected: .. Seq Bool Int Bool
actual: .. Int ?t37 Bool
hint: These are the values `all-helper` takes, in another order. To push them in its order, write `flags i 1 prim + true` in place of `i 1 prim + flags true`. With that edit `all-helper` checks.

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
      xs i prim seq-int.at curVal prim =
      [
        curLen 1 prim +
        dup maxLen prim <
        [
          maxLen
        ]
        [
          dup
        ]
        if
        i 1 prim +
        xs
        xs i prim seq-int.at
        run-helper
      ]
      [
        curLen maxLen prim <
        [
          curLen
        ]
        [
          maxLen
        ]
        if
        i 1 prim +
        xs
        xs i prim seq-int.at
        1
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
code: firth.type.word-input-mismatch
word: run-helper
at: line 21, column 9
message: `run-helper` in `run-helper` takes xs:Seq Int, i:Int, curVal:Int, curLen:Int, maxLen:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int) and the result of `prim seq-int.at` (Int).
expected: .. Seq Int Int Int Int Int
actual: .. Int Int Int Seq Int Int
hint: The second value from the top, `xs` (Seq Int), is not what `run-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-search
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target j i }
  {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [
        j 1 prim +
        xs
        target
        inner-search
      ]
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [
          true
        ]
        [
          j 1 prim +
          xs
          target
          inner-search
        ]
        if
      ]
      if
    ]
    [
      false
    ]
    if
  };

: outer-search
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i }
  {
    i xs prim seq-int.len prim <
    [
      i xs target inner-search
      [
        true
      ]
      [
        i 1 prim +
        xs
        target
        outer-search
      ]
      if
    ]
    [
      false
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs target 0 outer-search };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: inner-search
at: line 25, column 9
message: In the false branch of the `if` in `inner-search` whose true branch is `[ true ]`, `inner-search` needs 4 values (xs:Seq Int, target:Int, j:Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-search`, exactly the values it takes, in this order: xs:Seq Int, target:Int, j:Int, i:Int. The branch already pushes the result of `prim +`, `xs` and `target`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `inner-search` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: outer-search
at: line 56, column 5
message: In the true branch `[ i xs target inner-search [ true ] ...` of the `if` in `outer-search`, `inner-search` needs 4 values (xs:Seq Int, target:Int, j:Int, i:Int), but the branch has pushed only 3 values before it (`i`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `outer-search` calls `inner-search`, which has an error of its own; this report assumes `inner-search` keeps its stack effect.
hint: Make the branch push, just before `inner-search`, exactly the values it takes, in this order: xs:Seq Int, target:Int, j:Int, i:Int. The branch already pushes `i`, `xs` and `target`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `inner-search` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in-sequence
  (forall ρ; ρ seq:Seq Int^many val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { seq val i }
  {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at val prim =
      [
        true
      ]
      [
        i 1 prim +
        seq
        val
        is-in-sequence
      ]
      if
    ]
    [
      false
    ]
    if
  };

: distinct-count-helper
  (forall ρ; ρ xs:Seq Int^many unique:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs unique i }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at unique 0 is-in-sequence
      [
        i 1 prim +
        xs
        unique
        distinct-count-helper
      ]
      [
        unique xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        xs
        distinct-count-helper
      ]
      if
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
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: is-in-sequence
at: line 15, column 9
message: `is-in-sequence` in `is-in-sequence` takes seq:Seq Int, val:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `seq` (Seq Int) and `val` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t51 ?t50
hint: These are the values `is-in-sequence` takes, in another order. To push them in its order, write `seq val i 1 prim +` in place of `i 1 prim + seq val`. With that edit `is-in-sequence` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: distinct-count-helper
at: line 31, column 37
message: `is-in-sequence` in `distinct-count-helper` takes seq:Seq Int, val:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `unique` (Seq Int) and `0` (Int). `distinct-count-helper` calls `is-in-sequence`, which has an error of its own; this report assumes `is-in-sequence` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t22 Int ?t22 Int
hint: These are the values `is-in-sequence` takes, in another order. By their names and types, `unique` is for `seq`. Of the values of one type, `xs i prim seq-int.at` and `0` are for `val` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        j
        ys
        xs
        merge-helper
      ]
      [
        result ys j prim seq-int.at prim seq-int.push
        i
        j 1 prim +
        xs
        ys
        merge-helper
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        j
        ys
        xs
        merge-helper
      ]
      [
        j ys prim seq-int.len prim <
        [
          result ys j prim seq-int.at prim seq-int.push
          i
          j 1 prim +
          xs
          ys
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
code: firth.type.word-input-mismatch
word: merge-helper
at: line 15, column 9
message: `merge-helper` in `merge-helper` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int), `j` (Int), `ys` (Seq Int) and `xs` (Seq Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Int ?t111 ?t110 Seq Int
hint: These are the values `merge-helper` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim + j ys xs`. With that edit, the next error in `merge-helper` is at line 18, column 9.

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
      result n 10 prim mod prim seq-int.push
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
      reversed result i prim seq-int.at prim seq-int.push
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
code: firth.type.word-input-mismatch
word: digits-helper
at: line 12, column 7
message: `digits-helper` in `digits-helper` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-helper` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div`. With that edit `digits-helper` checks.

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
        n
        i 1 prim +
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
message: `primes-helper` in `primes-helper` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), `n` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t75 Int
hint: These are the values `primes-helper` takes, in another order. To push them in its order, write `n i 1 prim + i 2 is-prime-helper [ result i prim seq-int.push ] [ result ] if` in place of `i 2 is-prime-helper [ result i prim seq-int.push ] [ result ] if n i 1 prim +`. With that edit `primes-helper` checks.

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
      xs i prim seq-int.at
      dup
      dup counts prim seq-int.at 1 prim +
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
    [ k prim < [ 0 swap prim seq-int.push ] [ drop ] if 1 prim + dup ]
    call
    drop
    xs
    k
    histogram-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-helper
at: line 19, column 5
message: The two branches of the `if` in `histogram-helper` whose true branch is `[ xs i prim seq-int.at dup dup counts ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `histogram-helper`; the false branch leaves `counts`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `histogram-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 28, column 54
message: The two branches of the `if` in `main` whose true branch is `[ 0 swap prim seq-int.push ]` leave different numbers of values. The true branch takes the result of `prim seq-int.empty` from below the `if` and leaves the result of `prim seq-int.push`; the false branch takes the result of `prim seq-int.empty` from below the `if` and leaves nothing.
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
      sorted x prim seq-int.push
    ]
    [
      i 1 prim - dup
      sorted swap prim seq-int.at
      x prim <
      [
        drop sorted i prim seq-int.at x swap prim seq-int.set
        i 1 prim -
        sorted
        x
        insert-helper
      ]
      [
        drop sorted x prim seq-int.push
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
      xs i prim seq-int.at
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
code: firth.type.word-input-mismatch
word: insert-helper
at: line 18, column 9
message: `insert-helper` in `insert-helper` takes sorted:Seq Int, i:Int, x:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `sorted` (Seq Int) and `x` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Seq Int Int
hint: These are the values `insert-helper` takes, in another order. To push them in its order, write `sorted i 1 prim - x` in place of `i 1 prim - sorted x`. With that edit, the next error in `insert-helper` is at line 22, column 5.

error 2 of 2
code: firth.type.word-input-mismatch
word: sort-helper
at: line 37, column 7
message: `insert-helper` in `sort-helper` takes sorted:Seq Int, i:Int, x:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `i` (Int) and `sorted` (Seq Int). `sort-helper` calls `insert-helper`, which has an error of its own; this report assumes `insert-helper` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Int ?t24
hint: These are the values `insert-helper` takes, in another order. To push them in its order, write `sorted i xs i prim seq-int.at` in place of `xs i prim seq-int.at i sorted`. With that edit `sort-helper` checks.

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
      balance xs i prim seq-int.at prim +
      dup 0 prim <
      [
        drop balance rejected 1 prim +
      ]
      [
        rejected
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
code: firth.name.unresolved
word: ledger-helper
at: line 7, column 15
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    stock item prim seq-int.at
    dup qty prim <
    [
      drop
      qty stock item prim seq-int.at prim <
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
        stock qty item prim seq-int.set
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
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many result-stock:Seq Int^many result-allocated:Seq Int^many result-reasons:Seq Int^many i:Int^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock items qtys whole result-stock result-allocated result-reasons i }
  {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      stock
      allocate-order
      result-reasons swap prim seq-int.push
      result-allocated swap prim seq-int.push
      i 1 prim +
      items
      qtys
      whole
      allocate-batch-helper
    ]
    [
      stock result-allocated result-reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-out:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 allocate-batch-helper };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 88
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
