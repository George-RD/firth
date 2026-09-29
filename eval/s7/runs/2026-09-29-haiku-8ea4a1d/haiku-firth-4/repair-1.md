Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs i sum } {
    i xs prim seq-int.len prim = [
      sum
    ] [
      xs i prim seq-int.at sum prim +
      [ i 1 prim + ] call
      xs
      sum-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    0 0 xs sum-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: sum-loop
at: line 10, column 7
message: `sum-loop` in `sum-loop` takes xs:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `sum-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 12
message: `sum-loop` in `main` takes xs:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int) and `xs` (Seq Int). `main` calls `sum-loop`, which has an error of its own; this report assumes `sum-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: These are the values `sum-loop` takes, in another order. To push them in its order, write `xs 0 0` in place of `0 0 xs`. With that edit `main` checks.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim = [
      max-val
    ] [
      xs i prim seq-int.at max-val prim < [
        xs i prim seq-int.at
      ] [
        max-val
      ] if
      [ i 1 prim + ] call
      xs
      max-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs max-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: max-loop
at: line 14, column 7
message: `max-loop` in `max-loop` takes xs:Seq Int, i:Int, max-val:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `max-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 21, column 31
message: `max-loop` in `main` takes xs:Seq Int, i:Int, max-val:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `1` (Int) and `xs` (Seq Int). `main` calls `max-loop`, which has an error of its own; this report assumes `max-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max-val`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim = [
      count
    ] [
      xs i prim seq-int.at k prim < [
        count 1 prim +
      ] [
        count
      ] if
      [ i 1 prim + ] call
      xs k
      count-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 0 xs k count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-loop
at: line 14, column 7
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `k` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: The second value from the top, `xs` (Seq Int), is not what `count-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 21, column 14
message: `count-loop` in `main` takes xs:Seq Int, k:Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int), `xs` (Seq Int) and `k` (Int). `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: ρ Int Int Seq Int Int
hint: These are the values `count-loop` takes, in another order. To push them in its order, write `xs k 0 0` in place of `0 0 xs k`. With that edit `main` checks.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim = [
      -1
    ] [
      xs i prim seq-int.at x prim = [
        i
      ] [
        [ i 1 prim + ] call
        xs x
        index-loop
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0 xs x index-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: index-loop
at: line 12, column 9
message: `index-loop` in `index-loop` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `x` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t60 ?t59
hint: The top value, `x` (Int), is not what `index-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 20, column 12
message: `index-loop` in `main` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int) and `x` (Int). `main` calls `index-loop`, which has an error of its own; this report assumes `index-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `index-loop` takes, in another order. To push them in its order, write `xs x 0` in place of `0 xs x`. With that edit `main` checks.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-build
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim = [
      result
    ] [
      xs [ i 1 prim - ] call prim seq-int.at result prim seq-int.push
      [ i 1 prim - ] call
      xs
      reverse-build
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len xs prim seq-int.empty reverse-build
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: reverse-build
at: line 7, column 53
message: `prim seq-int.push` in `reverse-build` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 47
message: `reverse-build` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.len` (Int), `xs` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `reverse-build`, which has an error of its own; this report assumes `reverse-build` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int Seq Int
hint: These are the values `reverse-build` takes, in another order. To push them in its order, write `xs xs prim seq-int.len prim seq-int.empty` in place of `xs prim seq-int.len xs prim seq-int.empty`. With that edit `main` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-build
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim = [
      result
    ] [
      xs i prim seq-int.at sum prim +
      result swap prim seq-int.push
      [ i 1 prim + ] call
      xs
      prefix-build
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    0 0 xs prim seq-int.empty prefix-build
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-build
at: line 12, column 7
message: In the false branch of the `if` in `prefix-build` whose true branch is `[ result ]`, `prefix-build` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-build`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-build` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 31
message: `prefix-build` in `main` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int), `xs` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `prefix-build`, which has an error of its own; this report assumes `prefix-build` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Int Int Seq Int Seq Int
hint: These are the values `prefix-build` takes, in another order. To push them in its order, write `xs 0 0 prim seq-int.empty` in place of `0 0 xs prim seq-int.empty`. With that edit `main` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim = [
      result
    ] [
      xs i prim seq-int.at 0 prim < [
        result
      ] [
        result xs i prim seq-int.at prim seq-int.push
      ] if
      [ i 1 prim + ] call
      xs
      filter-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    0 xs prim seq-int.empty filter-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 21, column 29
message: `filter-loop` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int) and the result of `prim seq-int.empty` (Seq Int).
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int Seq Int
hint: These are the values `filter-loop` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `0 xs prim seq-int.empty`. With that edit `main` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim = [
      true
    ] [
      i [ i 1 prim + ] call prim seq-int.len prim < [
        xs i prim seq-int.at xs [ i 1 prim + ] call prim seq-int.at prim < [
          false
        ] [
          [ i 1 prim + ] call
          xs
          check-sorted
        ] if
      ] [
        [ i 1 prim + ] call
        xs
        check-sorted
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    0 xs check-sorted
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: check-sorted
at: line 7, column 29
message: `prim seq-int.len` in `check-sorted` takes Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int).
expected: .. Seq Int
actual: .. Int ?t15 Int Int
hint: The top value, the result of `prim +` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 26, column 10
message: `check-sorted` in `main` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int). `main` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
expected: .. Seq Int Int
actual: ρ Int Seq Int
hint: These are the values `check-sorted` takes, in another order. To push them in its order, write `xs 0` in place of `0 xs`. With that edit `main` checks.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim = [
      sum
    ] [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      [ i 1 prim + ] call
      xs ys
      dot-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0 xs ys dot-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: dot-loop
at: line 10, column 7
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: The top value, `ys` (Seq Int), is not what `dot-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 15
message: `dot-loop` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int), `xs` (Seq Int) and `ys` (Seq Int). `main` calls `dot-loop`, which has an error of its own; this report assumes `dot-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int
actual: ρ Int Int Seq Int Seq Int
hint: These are the values `dot-loop` takes, in another order. To push them in its order, write `xs ys 0 0` in place of `0 0 xs ys`. With that edit `main` checks.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim = [
      true
    ] [
      flags i prim seq-bool.at [
        [ i 1 prim + ] call
        flags
        check-all
      ] [
        false
      ] if
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    0 flags check-all
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: check-all
at: line 10, column 9
message: `check-all` in `check-all` takes flags:Seq Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int ?t29
hint: The top value, `flags` (Seq Bool), is not what `check-all` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 20, column 13
message: `check-all` in `main` takes flags:Seq Bool, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `flags` (Seq Bool). `main` calls `check-all`, which has an error of its own; this report assumes `check-all` keeps its stack effect.
expected: .. Seq Bool Int
actual: ρ Int Seq Bool
hint: These are the values `check-all` takes, in another order. To push them in its order, write `flags 0` in place of `0 flags`. With that edit `main` checks.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-count:Int^many max-count:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-count max-count } {
    i xs prim seq-int.len prim = [
      current-count max-count prim < [
        max-count
      ] [
        current-count
      ] if
    ] [
      xs i prim seq-int.at current-val prim = [
        current-count 1 prim + max-count prim < [
          max-count
        ] [
          current-count 1 prim +
        ] if
        [ i 1 prim + ] call
        xs current-val
        [ current-count 1 prim + ] call
        count-run
      ] [
        current-count max-count prim < [
          max-count
        ] [
          current-count
        ] if
        [ i 1 prim + ] call
        xs xs i prim seq-int.at 1 
        count-run
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 [
      xs 0 prim seq-int.len prim = [
        0
      ] [
        0 xs 0 prim seq-int.at 1 0 count-run
      ] if
    ] call
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-run
at: line 20, column 9
message: `count-run` in `count-run` takes xs:Seq Int, i:Int, current-val:Int, current-count:Int, max-count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int), `current-val` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int Int
actual: .. Int Int ?t134 ?t133 Int
hint: The second value from the top, `current-val` (Int), is not what `count-run` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 42, column 9
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller. `main` calls `count-run`, which has an error of its own; this report assumes `count-run` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim = [
      false
    ] [
      [ i 1 prim + ] call
      xs target
      find-pair-inner
    ] if
  };

: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target j i } {
    j xs prim seq-int.len prim = [
      [ i 1 prim + ] call
      xs target
      find-pair
    ] [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [
        true
      ] [
        [ j 1 prim + ] call
        xs target
        find-pair-inner
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0 xs target find-pair
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: find-pair
at: line 10, column 7
message: In the false branch of the `if` in `find-pair` whose true branch is `[ false ]`, `find-pair-inner` needs 4 values (xs:Seq Int, target:Int, j:Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `find-pair` calls `find-pair-inner`, which has an error of its own; this report assumes `find-pair-inner` keeps its stack effect.
hint: Make the branch push, just before `find-pair-inner`, exactly the values it takes, in this order: xs:Seq Int, target:Int, j:Int, i:Int. The branch already pushes the result of `prim +`, `xs` and `target`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-pair-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: find-pair-inner
at: line 27, column 9
message: In the false branch of the `if` in `find-pair-inner` whose true branch is `[ true ]`, `find-pair-inner` needs 4 values (xs:Seq Int, target:Int, j:Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-pair-inner`, exactly the values it takes, in this order: xs:Seq Int, target:Int, j:Int, i:Int. The branch already pushes the result of `prim +`, `xs` and `target`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-pair-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 34, column 17
message: `find-pair` in `main` takes xs:Seq Int, target:Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int) and `target` (Int). `main` calls `find-pair`, which has an error of its own; this report assumes `find-pair` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `find-pair` takes, in another order. To push them in its order, write `xs target 0` in place of `0 xs target`. With that edit `main` checks.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim = [
      count
    ] [
      xs i prim seq-int.at 0 [ 
        [ i 1 prim + ] call
      ] dip
      xs
      count-distinct-check
    ] if
  };

: count-distinct-check
  (forall ρ; ρ xs:Seq Int^many j:Int^many val:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs j val i count } {
    j i prim = [
      count 1 prim +
      [ i 1 prim + ] call
      xs
      count-distinct-loop
    ] [
      xs j prim seq-int.at val prim = [
        [ i 1 prim + ] call
        xs
        count-distinct-loop
      ] [
        [ j 1 prim + ] call
        xs val
        count-distinct-check
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 0 xs count-distinct-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 12, column 7
message: In the false branch of the `if` in `count-distinct-loop` whose true branch is `[ count ]`, `count-distinct-check` needs 5 values (xs:Seq Int, j:Int, val:Int, i:Int, count:Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.at`, the result of `prim +`, `0` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-distinct-loop` calls `count-distinct-check`, which has an error of its own; this report assumes `count-distinct-check` keeps its stack effect.
hint: Make the branch push, just before `count-distinct-check`, exactly the values it takes, in this order: xs:Seq Int, j:Int, val:Int, i:Int, count:Int. The branch already pushes the result of `prim seq-int.at`, the result of `prim +`, `0` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `count-distinct-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: count-distinct-check
at: line 32, column 9
message: In the true branch `[ [ i 1 prim + ] call ...` of the `if` in `count-distinct-check`, `count-distinct-loop` needs 3 values (xs:Seq Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-distinct-check` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
hint: Make the branch push, just before `count-distinct-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, count:Int. The branch already pushes the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `count-distinct-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 39, column 12
message: `count-distinct-loop` in `main` takes xs:Seq Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int) and `xs` (Seq Int). `main` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: These are the values `count-distinct-loop` takes, in another order. To push them in its order, write `xs 0 0` in place of `0 0 xs`. With that edit `main` checks.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim = [
      j ys prim seq-int.len prim = [
        result
      ] [
        result ys j prim seq-int.at prim seq-int.push
        [ j 1 prim + ] call
        xs ys
        merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim = [
        result xs i prim seq-int.at prim seq-int.push
        [ i 1 prim + ] call
        xs ys
        merge-loop
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result xs i prim seq-int.at prim seq-int.push
          [ i 1 prim + ] call
          xs ys
          merge-loop
        ] [
          result ys j prim seq-int.at prim seq-int.push
          [ j 1 prim + ] call
          xs ys
          merge-loop
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    0 0 xs ys prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 12, column 9
message: In the false branch of the `if` in `merge-loop` whose true branch is `[ result ]`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 38, column 34
message: `merge-loop` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: ρ Int Int Seq Int Seq Int Seq Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys 0 0 prim seq-int.empty` in place of `0 0 xs ys prim seq-int.empty`. With that edit `main` checks.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: collect-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result 0 prim seq-int.push
    ] [
      n 10 prim mod result prim seq-int.push
      [ n 10 prim div ] call
      result
      collect-digits
    ] if
  };

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim = [
      result
    ] [
      xs [ i 1 prim - ] call prim seq-int.at result prim seq-int.push
      [ i 1 prim - ] call
      xs
      reverse-seq
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim < [
      0 [ n 0 prim - ] call prim seq-int.empty collect-digits
      dup prim seq-int.len swap reverse-seq
    ] [
      n prim seq-int.empty collect-digits
      dup prim seq-int.len swap reverse-seq
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: collect-digits
at: line 11, column 7
message: The two branches of the `if` in `collect-digits` whose true branch is `[ result 0 prim seq-int.push ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.push`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `collect-digits`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `collect-digits`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: reverse-seq
at: line 20, column 53
message: `prim seq-int.push` in `reverse-seq` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 3 of 3
code: firth.type.branch-mismatch
word: main
at: line 36, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ 0 [ n 0 prim - ] ...`, `reverse-seq` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.len` and the result of `collect-digits`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `collect-digits` and `reverse-seq`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `reverse-seq`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.len` and the result of `collect-digits`, in the place of the last 2 (i:Int, result:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `reverse-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { n divisor } {
    divisor divisor prim * n prim < [
      n divisor prim mod 0 prim = [
        false
      ] [
        [ divisor 1 prim + ] call
        n
        is-prime
      ] if
    ] [
      true
    ] if
  };

: collect-primes
  (forall ρ; ρ limit:Int^many current:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { limit current result } {
    current limit prim < [
      current 2 is-prime [
        result current prim seq-int.push
      ] [
        result
      ] if
      [ current 1 prim + ] call
      limit
      collect-primes
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty collect-primes
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: collect-primes
at: line 28, column 7
message: `collect-primes` in `collect-primes` takes limit:Int, current:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), the result of `prim +` (Int) and `limit` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t23
hint: The top value, `limit` (Int), is not what `collect-primes` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs k i result } {
    i xs prim seq-int.len prim = [
      result
    ] [
      xs i prim seq-int.at result swap prim seq-int.at 1 prim + prim seq-int.set
      [ i 1 prim + ] call
      xs k
      histogram-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    [ 0 [ k 1 prim - ] call 0
      [ dup 0 prim seq-int.push [ 1 prim + ] call ] call
    ] dip
    0 xs k histogram-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 11, column 7
message: In the false branch of the `if` in `histogram-loop` whose true branch is `[ result ]`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 19, column 15
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `0` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, `0` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ val:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { val sorted i } {
    i sorted prim seq-int.len prim = [
      sorted val prim seq-int.push
    ] [
      sorted i prim seq-int.at val prim < [
        sorted i val prim seq-int.set
        [ i 1 prim + ] call
        insert-sorted
      ] [
        [ i 1 prim + ] call
        insert-sorted
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim = [
      sorted
    ] [
      xs i prim seq-int.at sorted 0 insert-sorted
      [ i 1 prim + ] call
      xs
      sort-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    0 xs prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-sorted
at: line 14, column 9
message: In the true branch `[ sorted i val prim seq-int.set [ i ...` of the `if` in `insert-sorted`, `insert-sorted` needs 3 values (val:Int, sorted:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-sorted`, exactly the values it takes, in this order: val:Int, sorted:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`, in the place of the last 2 (sorted:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (val:Int) before them, for example by writing the locals that hold it. If `insert-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 34, column 29
message: `sort-loop` in `main` takes xs:Seq Int, i:Int, sorted:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int) and the result of `prim seq-int.empty` (Seq Int).
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int Seq Int
hint: These are the values `sort-loop` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `0 xs prim seq-int.empty`. With that edit `main` checks.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs i balance rejected } {
    i txs prim seq-int.len prim = [
      balance rejected
    ] [
      txs i prim seq-int.at balance prim + 0 prim < [
        balance rejected 1 prim +
      ] [
        balance txs i prim seq-int.at prim + rejected
      ] if
      [ i 1 prim + ] call
      start txs
      ledger-loop
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 start txs ledger-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: ledger-loop
at: line 14, column 7
message: `ledger-loop` in `ledger-loop` takes start:Int, txs:Seq Int, i:Int, balance:Int, rejected:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of an `if` (Int), the result of `prim +` (Int), `start` (Int) and `txs` (Seq Int).
expected: .. Int Seq Int Int Int Int
actual: .. Int Int Int ?t62 Seq Int
hint: The top value, `txs` (Seq Int), is not what `ledger-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 21, column 23
message: `ledger-loop` in `main` needs Int Seq Int Int Int Int on top of the stack, but the stack before it is ρ Int Int Int Seq Int. `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Seq Int Int Int Int
actual: ρ Int Int Int Seq Int
hint: `ledger-loop` takes 5 values but only 4 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole order allocated reasons } {
    order items prim seq-int.len prim = [
      stock allocated reasons
    ] [
      items order prim seq-int.at stock swap prim seq-int.at 
      qtys order prim seq-int.at 
      whole order prim seq-bool.at
      [ order 1 prim + ] call
      items qtys whole
      allocate-decision
    ] if
  };

: allocate-decision
  (forall ρ; ρ item-stock:Int^many qty:Int^many whole:Bool^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole-all:Seq Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { item-stock qty whole order items qtys whole-all stock allocated reasons } {
    qty item-stock prim < [
      item-stock 0 prim = [
        stock allocated [ order 1 prim + ] call reasons 2 prim seq-int.push allocate-loop
      ] [
        whole [
          stock allocated [ order 1 prim + ] call reasons 3 prim seq-int.push allocate-loop
        ] [
          stock [ items order prim seq-int.at ] call [ item-stock prim seq-int.set ] call allocated [ order 1 prim + ] call qty prim seq-int.push reasons 1 prim seq-int.push allocate-loop
        ] if
      ] if
    ] [
      stock [ items order prim seq-int.at ] call [ [ qty item-stock prim - ] call prim seq-int.set ] call allocated [ order 1 prim + ] call qty prim seq-int.push reasons 0 prim seq-int.push allocate-loop
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0 stock items qtys whole prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: allocate-loop
at: line 13, column 7
message: In the false branch of the `if` in `allocate-loop` whose true branch is `[ stock allocated reasons ]`, `allocate-decision` needs 10 values (item-stock:Int, qty:Int, whole:Bool, order:Int, items:Seq Int, qtys:Seq Int, whole-all:Seq Bool, stock:Seq Int, allocated:Seq Int, reasons:Seq Int), but the branch has pushed only 7 values before it (the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-bool.at`, the result of `prim +`, `items`, `qtys` and `whole`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `allocate-loop` calls `allocate-decision`, which has an error of its own; this report assumes `allocate-decision` keeps its stack effect.
hint: Make the branch push, just before `allocate-decision`, exactly the values it takes, in this order: item-stock:Int, qty:Int, whole:Bool, order:Int, items:Seq Int, qtys:Seq Int, whole-all:Seq Bool, stock:Seq Int, allocated:Seq Int, reasons:Seq Int. The branch already pushes the result of `prim seq-int.at`, the result of `prim seq-int.at`, the result of `prim seq-bool.at`, the result of `prim +`, `items`, `qtys` and `whole`, in the place of the first 7 (item-stock:Int, qty:Int, whole:Bool, order:Int, items:Seq Int, qtys:Seq Int, whole-all:Seq Bool): keep each where it has that type and replace it where it does not. Then push the last 3 (stock:Seq Int, allocated:Seq Int, reasons:Seq Int) after them, for example by writing the locals that hold them. If `allocate-decision` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.stack-underflow
word: allocate-decision
at: line 31, column 7
message: `if` needs more values than the stack holds here. `allocate-decision` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 37, column 68
message: `allocate-loop` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, order:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), `stock` (Seq Int), `items` (Seq Int), `qtys` (Seq Int), `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Int Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int
hint: These are the values `allocate-loop` takes, in another order. To push them in its order, write `stock items qtys whole 0 prim seq-int.empty prim seq-int.empty` in place of `0 stock items qtys whole prim seq-int.empty prim seq-int.empty`. With that edit `main` checks.
