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
      xs i 1 prim + sum-helper
    ]
    [
      acc
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs }
  {
    0 0 xs sum-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: sum-helper
at: line 8, column 21
message: `sum-helper` in `sum-helper` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `sum-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `acc xs i prim seq-int.at prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 20, column 12
message: `sum-helper` in `main` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int) and `xs` (Seq Int). `main` calls `sum-helper`, which has an error of its own; this report assumes `sum-helper` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: These are the values `sum-helper` takes, in another order. To push them in its order, write `xs 0 0` in place of `0 0 xs`. With that edit `main` checks.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem }
      {
        elem max prim <
        [ max ]
        [ elem ]
        if
        xs i 1 prim + max-helper
      }
    ]
    [
      max
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs }
  {
    xs 0 prim seq-int.at
    xs 1 max-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: max-helper
at: line 14, column 23
message: `max-helper` in `max-helper` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Int Seq Int Int
hint: These are the values `max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `elem max prim < [ max ] [ elem ] if` and `i 1 prim +` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 28, column 10
message: `max-helper` in `main` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `1` (Int). `main` calls `max-helper`, which has an error of its own; this report assumes `max-helper` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i k count }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem }
      {
        elem k prim <
        [ count 1 prim + ]
        [ count ]
        if
        xs i 1 prim + k count-helper
      }
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k }
  {
    0 xs 0 k count-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-helper
at: line 14, column 25
message: `count-helper` in `count-helper` takes xs:Seq Int, i:Int, k:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), the result of `prim +` (Int) and `k` (Int).
expected: .. Seq Int Int Int Int
actual: .. Seq Int Int Int Int Int Seq Int Int Int
hint: These are the values `count-helper` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `elem k prim < [ count 1 prim + ] [ count ] if` and `i 1 prim +` are for `i` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 27, column 14
message: `count-helper` in `main` takes xs:Seq Int, i:Int, k:Int, count:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int), `0` (Int) and `k` (Int). `main` calls `count-helper`, which has an error of its own; this report assumes `count-helper` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: ρ Int Seq Int Int Int
hint: These are the values `count-helper` takes, in another order. To push them in its order, write `xs 0 k 0` in place of `0 xs 0 k`. With that edit `main` checks.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result }
  {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      xs i 1 prim - result reverse-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs }
  {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-helper
at: line 13, column 5
message: The two branches of the `if` in `reverse-helper` whose true branch is `[ result xs i prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-helper`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `reverse-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 22, column 5
message: `reverse-helper` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Int Seq Int. `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int
hint: `reverse-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i sum result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem }
      {
        sum elem prim +
        locals { new-sum }
        {
          result new-sum prim seq-int.push
          xs i 1 prim + new-sum result prefix-helper
        }
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs }
  {
    0 prim seq-int.empty
    xs 0 0 prefix-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-helper
at: line 21, column 5
message: The two branches of the `if` in `prefix-helper` whose true branch is `[ xs i prim seq-int.at locals { elem ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prefix-helper`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `prefix-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 29, column 12
message: `prefix-helper` in `main` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `prefix-helper`, which has an error of its own; this report assumes `prefix-helper` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Int Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `prefix-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem }
      {
        elem 0 prim <
        [ result ]
        [ result elem prim seq-int.push ]
        if
        xs i 1 prim + filter-helper
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs }
  {
    prim seq-int.empty
    xs 0 filter-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: filter-helper
at: line 14, column 23
message: `filter-helper` in `filter-helper` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Int Seq Int Seq Int Seq Int Int
hint: These are the values `filter-helper` takes, in another order. To push them in its order, write `xs i 1 prim + elem 0 prim < [ result ] [ result elem prim seq-int.push ] if` in place of `elem 0 prim < [ result ] [ result elem prim seq-int.push ] if xs i 1 prim +`. With that edit `filter-helper` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 28, column 10
message: `filter-helper` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int) and `0` (Int). `main` calls `filter-helper`, which has an error of its own; this report assumes `filter-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `filter-helper` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `prim seq-int.empty xs 0`. With that edit `main` checks.

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
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      xs ys i 1 prim + sum dot-helper
    ]
    [
      sum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys }
  {
    0 xs ys 0 dot-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: dot-helper
at: line 16, column 5
message: The two branches of the `if` in `dot-helper` whose true branch is `[ xs i prim seq-int.at ys i prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `dot-helper`; the false branch leaves `sum`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `dot-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 23, column 15
message: `dot-helper` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int), `ys` (Seq Int) and `0` (Int). `main` calls `dot-helper`, which has an error of its own; this report assumes `dot-helper` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int
actual: ρ Int Seq Int Seq Int Int
hint: These are the values `dot-helper` takes, in another order. To push them in its order, write `xs ys 0 0` in place of `0 xs ys 0`. With that edit `main` checks.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many curr-val:Int^many curr-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i curr-val curr-len max-len }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem }
      {
        elem curr-val prim =
        [
          curr-len 1 prim +
          locals { new-len }
          {
            new-len max-len prim <
            [ max-len ]
            [ new-len ]
            if
            xs i 1 prim + elem new-len run-helper
          }
        ]
        [
          curr-len max-len prim <
          [ max-len ]
          [ curr-len ]
          if
          xs i 1 prim + elem 1 run-helper
        ]
        if
      }
    ]
    [
      curr-len max-len prim <
      [ max-len ]
      [ curr-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs }
  {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 prim seq-int.at 1 0 run-helper ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: run-helper
at: line 19, column 40
message: `run-helper` in `run-helper` takes xs:Seq Int, i:Int, curr-val:Int, curr-len:Int, max-len:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), the result of `prim +` (Int), `elem` (Int) and `new-len` (Int).
expected: .. Seq Int Int Int Int Int
actual: .. Int ?t104 Int ?t102 Int ?t104 Int ?t102 Int
hint: These are the values `run-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `new-len max-len prim < [ max-len ] [ new-len ] if`, `i 1 prim +`, `elem` and `new-len` are for `i`, `curr-val`, `curr-len` and `max-len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 48, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `run-helper` needs 5 values (xs:Seq Int, i:Int, curr-val:Int, curr-len:Int, max-len:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, `1` and `0`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `main` calls `run-helper`, which has an error of its own; this report assumes `run-helper` keeps its stack effect.
hint: Make the branch push, just before `run-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, curr-val:Int, curr-len:Int, max-len:Int. The branch already pushes the result of `prim seq-int.at`, `1` and `0`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-complement
  (forall ρ; ρ xs:Seq Int^many j:Int^many x:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs j x target }
  {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      locals { y }
      {
        x y prim + target prim =
        [ true ]
        [ xs j 1 prim + x target find-complement ]
        if
      }
    ]
    [
      false
    ]
    if
  };

: search-pairs
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs i target }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + xs target find-complement
      [
        true
      ]
      [
        xs i 1 prim + target search-pairs
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
  locals { xs target }
  {
    xs 0 target search-pairs
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: search-pairs
at: line 41, column 5
message: The two branches of the `if` in `search-pairs` whose true branch is `[ xs i prim seq-int.at xs i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of an `if`; the false branch leaves `false`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-new
  (forall ρ; ρ xs:Seq Int^many j:Int^many elem:Int^many -- ρ result:Bool^many)
  locals { xs j elem }
  {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      locals { val }
      {
        elem val prim =
        [ false ]
        [ xs j 1 prim + elem count-new ]
        if
      }
    ]
    [
      true
    ]
    if
  };

: count-distinct-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + count-new
      [ count 1 prim + ]
      [ count ]
      if
      xs i 1 prim + count-distinct-helper
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs }
  {
    0 xs 0 count-distinct-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-distinct-helper
at: line 29, column 21
message: `count-new` in `count-distinct-helper` takes xs:Seq Int, j:Int, elem:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t24 Int Seq Int Int
hint: These are the values `count-new` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `i 1 prim +` are for `j` and `elem`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 45, column 12
message: `count-distinct-helper` in `main` takes xs:Seq Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int) and `0` (Int). `main` calls `count-distinct-helper`, which has an error of its own; this report assumes `count-distinct-helper` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `count-distinct-helper` takes, in another order. To push them in its order, write `xs 0 0` in place of `0 xs 0`. With that edit `main` checks.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result }
  {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        locals { x y }
        {
          x y prim <
          [
            result x prim seq-int.push
            xs ys i 1 prim + j result merge-helper
          ]
          [
            result y prim seq-int.push
            xs ys i j 1 prim + result merge-helper
          ]
          if
        }
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        xs ys i 1 prim + j result merge-helper
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        xs ys i j 1 prim + result merge-helper
      ]
      [
        result
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys }
  {
    prim seq-int.empty
    xs ys 0 0 merge-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-helper
at: line 40, column 7
message: The two branches of the `if` in `merge-helper` whose true branch is `[ result ys j prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-helper`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `merge-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 50, column 15
message: `merge-helper` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-helper`, which has an error of its own; this report assumes `merge-helper` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Int Int
hint: These are the values `merge-helper` takes, in another order. To push them in its order, write `xs ys 0 0 prim seq-int.empty` in place of `prim seq-int.empty xs ys 0 0`. With that edit `main` checks.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-helper
  (forall ρ; ρ n:Int^many digits:Seq Int^many -- ρ result:Seq Int^many)
  locals { n digits }
  {
    n 0 prim <
    [ digits ]
    [
      n 10 prim mod
      digits prim seq-int.push
      n 10 prim div digit-helper
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n }
  {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digit-helper ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digit-helper
at: line 9, column 14
message: `prim seq-int.push` in `digit-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `digits` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `digits n 10 prim mod` in place of `n 10 prim mod digits`. With that edit, the next error in `digit-helper` is at line 9, column 21.

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
      [ false ]
      [ n d 1 prim + is-prime ]
      if
    ]
    [
      true
    ]
    if
  };

: sieve-helper
  (forall ρ; ρ k:Int^many limit:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { k limit result }
  {
    k limit prim <
    [
      k 2 prim <
      [ false ]
      [ k 2 is-prime ]
      if
      [
        result k prim seq-int.push
      ]
      [
        result
      ]
      if
      k 1 prim + limit result sieve-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n }
  {
    prim seq-int.empty
    2 n 1 prim + sieve-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sieve-helper
at: line 40, column 5
message: The two branches of the `if` in `sieve-helper` whose true branch is `[ k 2 prim < [ false ] ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of an `if` and the result of `sieve-helper`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of an `if` is left below the result of `sieve-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 48, column 18
message: `sieve-helper` in `main` takes k:Int, limit:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `2` (Int) and the result of `prim +` (Int). `main` calls `sieve-helper`, which has an error of its own; this report assumes `sieve-helper` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Seq Int Int Int
hint: These are the values `sieve-helper` takes, in another order. By their names and types, `prim seq-int.empty` is for `result`. Of the values of one type, `2` and `n 1 prim +` are for `k` and `limit`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i counts }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { v }
      {
        counts v prim seq-int.at
        locals { curr }
        {
          counts v curr 1 prim + prim seq-int.set
          xs i 1 prim + counts histogram-helper
        }
      }
    ]
    [
      counts
    ]
    if
  };

: init-histogram
  (forall ρ; ρ k:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { k result }
  {
    k 0 prim <
    [
      result
    ]
    [
      result 0 prim seq-int.push
      k 1 prim - result init-histogram
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k }
  {
    k 0 prim <
    [ prim seq-int.empty ]
    [
      prim seq-int.empty
      k init-histogram
      xs 0 histogram-helper
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: histogram-helper
at: line 21, column 5
message: The two branches of the `if` in `histogram-helper` whose true branch is `[ xs i prim seq-int.at locals { v ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `histogram-helper`; the false branch leaves `counts`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `histogram-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.branch-mismatch
word: init-histogram
at: line 36, column 5
message: The two branches of the `if` in `init-histogram` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `init-histogram`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `init-histogram`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.quotation-input-mismatch
word: main
at: line 47, column 9
message: The quotation run by `dip` in `main` does not accept the stack below it (.. Seq Int ?t13 ?t15 [ .. Int Seq Int -- .. Seq Int ]). `main` calls `init-histogram`, which has an error of its own; this report assumes `init-histogram` keeps its stack effect.
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
: insert-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many elem:Int^many -- ρ result:Seq Int^many)
  locals { xs i elem }
  {
    i 0 prim <
    [
      xs elem prim seq-int.push
    ]
    [
      xs i prim seq-int.at
      locals { curr }
      {
        elem curr prim <
        [
          xs i elem prim seq-int.set
          xs i 1 prim - curr insert-sorted
        ]
        [
          xs i 1 prim - elem insert-sorted
        ]
        if
      }
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
      sorted i insert-sorted
      xs i 1 prim + sorted sort-helper
    ]
    [
      sorted
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs }
  {
    prim seq-int.empty
    xs 0 sort-helper
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: insert-sorted
at: line 21, column 9
message: The two branches of the `if` in `insert-sorted` whose true branch is `[ xs i elem prim seq-int.set xs i ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-sorted`; the false branch leaves the result of `insert-sorted`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-sorted`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.branch-mismatch
word: sort-helper
at: line 40, column 5
message: The two branches of the `if` in `sort-helper` whose true branch is `[ xs i prim seq-int.at sorted i insert-sorted ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `insert-sorted` and the result of `sort-helper`; the false branch leaves `sorted`. `sort-helper` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: the result of `insert-sorted` is left below the result of `sort-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 48, column 10
message: `sort-helper` in `main` takes xs:Seq Int, i:Int, sorted:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int) and `0` (Int). `main` calls `sort-helper`, which has an error of its own; this report assumes `sort-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `sort-helper` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `prim seq-int.empty xs 0`. With that edit `main` checks.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-alloc:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons }
  {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item }
      {
        stock item prim seq-int.at
        locals { avail }
        {
          qtys i prim seq-int.at
          locals { req }
          {
            req avail prim <
            [
              stock item req prim seq-int.set
              allocated req prim seq-int.push
              reasons 0 prim seq-int.push
              stock items qtys whole i 1 prim + allocated reasons allocate-order
            ]
            [
              avail 0 prim =
              [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                stock items qtys whole i 1 prim + allocated reasons allocate-order
              ]
              [
                whole i prim seq-bool.at
                [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  stock items qtys whole i 1 prim + allocated reasons allocate-order
                ]
                [
                  stock item 0 prim seq-int.set
                  allocated avail prim seq-int.push
                  reasons 1 prim seq-int.push
                  stock items qtys whole i 1 prim + allocated reasons allocate-order
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
    ]
    [
      stock allocated reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole }
  {
    prim seq-int.empty prim seq-int.empty
    stock items qtys whole 0 allocate-order
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-order
at: line 43, column 17
message: The two branches of the `if` in `allocate-order` whose true branch is `[ allocated 0 prim seq-int.push reasons 3 prim ...` leave different numbers of values. The true branch leaves 5 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `final-stock` of `allocate-order`, the output `final-alloc` of `allocate-order` and the output `final-reasons` of `allocate-order`; the false branch leaves 6 values, bottom to top: the result of `prim seq-int.set`, the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `final-stock` of `allocate-order`, the output `final-alloc` of `allocate-order` and the output `final-reasons` of `allocate-order`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `final-stock` of `allocate-order`, the output `final-alloc` of `allocate-order` and the output `final-reasons` of `allocate-order`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 63, column 30
message: `allocate-order` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `stock` (Seq Int), `items` (Seq Int), `qtys` (Seq Int), `whole` (Seq Bool) and `0` (Int). `main` calls `allocate-order`, which has an error of its own; this report assumes `allocate-order` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int Seq Int Seq Bool Int
hint: These are the values `allocate-order` takes, in another order. To push them in its order, write `stock items qtys whole 0 prim seq-int.empty prim seq-int.empty` in place of `prim seq-int.empty prim seq-int.empty stock items qtys whole 0`. With that edit `main` checks.
