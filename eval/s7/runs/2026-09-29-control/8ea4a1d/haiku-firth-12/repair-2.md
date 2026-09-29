Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: seq-sum-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs index acc } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at acc prim +
      index 1 prim +
      xs
      swap
      seq-sum-loop
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 xs seq-sum-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: seq-sum-loop
at: line 9, column 7
message: `seq-sum-loop` in `seq-sum-loop` takes xs:Seq Int, index:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `seq-sum-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs index prim seq-int.at acc prim +` and `index 1 prim +` are for `index` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 17, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs index max-val } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      dup max-val prim <
      [ drop max-val ]
      [ drop xs index prim seq-int.at ]
      if
      index 1 prim +
      xs
      swap
      seq-max-loop
    ] [
      max-val
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  dup 0 prim seq-int.at 1 swap seq-max-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: seq-max-loop
at: line 13, column 7
message: `seq-max-loop` in `seq-max-loop` takes xs:Seq Int, index:Int, max-val:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: The second value from the top, `xs` (Seq Int), is not what `seq-max-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k index count } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      index 1 prim +
      xs
      k
      swap
      count-loop
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  swap 0 swap 0 count-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-loop
at: line 13, column 7
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, index:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `k` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Int Seq Int
hint: These are the values `count-loop` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs index prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` and `index 1 prim +` are for `index` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 21, column 17
message: `count-loop` in `main` takes xs:Seq Int, k:Int, index:Int, count:Int, bottom to top, but here it gets, bottom to top, the input `k` (Int), `0` (Int), the input `xs` (Seq Int) and `0` (Int). `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: ρ Int Int Seq Int Int
hint: The second value from the top, the input `xs` (Seq Int), is not what `count-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs x index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at x prim =
      [ index ]
      [ xs x index 1 prim + index-loop ]
      if
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  swap 0 swap index-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 16, column 15
message: `index-loop` in `main` takes xs:Seq Int, x:Int, index:Int, bottom to top, but here it gets, bottom to top, the input `x` (Int), `0` (Int) and the input `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value, the input `xs` (Seq Int), is not what `index-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs index result } {
    index 0 prim < [
      result xs index prim seq-int.at prim seq-int.push
      index 1 prim -
      xs
      swap
      reverse-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs dup xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: reverse-loop
at: line 9, column 7
message: `reverse-loop` in `reverse-loop` takes xs:Seq Int, index:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim -` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `reverse-loop` takes, in another order. To push them in its order, write `xs index 1 prim - result xs index prim seq-int.at prim seq-int.push` in place of `result xs index prim seq-int.at prim seq-int.push index 1 prim - xs swap`. With that edit `reverse-loop` checks.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 16, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int. `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many sum:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs index sum result } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at sum prim +
      dup
      result swap prim seq-int.push
      index 1 prim +
      xs
      swap
      prefix-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  0 0 prim seq-int.empty xs prefix-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 11, column 7
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, index:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Int Seq Int Seq Int Int
hint: The top value, the result of `prim +` (Int), is not what `prefix-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 19, column 26
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs index result } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      dup 0 prim < prim not
      [ 
        dup result swap prim seq-int.push
      ] [
        drop result
      ] if
      index 1 prim +
      xs
      swap
      filter-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  0 prim seq-int.empty filter-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 11, column 9
message: The two branches of the `if` in `filter-loop` whose true branch is `[ dup result swap prim seq-int.push ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `prim seq-int.push`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves `result`.
hint: The false branch takes the result of `prim seq-int.at` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many -- ρ result:Bool^many)
  locals { xs index } {
    index xs prim seq-int.len 1 prim - prim < [
      xs index prim seq-int.at
      xs index 1 prim + prim seq-int.at
      prim < prim not
      [ xs index 1 prim + sorted-loop ]
      [ false ]
      if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 sorted-loop
  };

```
On the example, it returned [False] instead of [True]

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many index:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys index acc } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      ys index prim seq-int.at
      prim *
      acc prim +
      index 1 prim +
      xs
      ys
      swap
      dot-loop
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 xs ys dot-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: dot-loop
at: line 13, column 7
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, index:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `ys` (Seq Int) and `xs` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs index prim seq-int.at ys index prim seq-int.at prim * acc prim +` and `index 1 prim +` are for `index` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs index current-run max-run } {
    index xs prim seq-int.len prim < [
      index xs prim seq-int.len 1 prim - prim < [
        xs index prim seq-int.at
        xs index 1 prim + prim seq-int.at
        prim =
        [ current-run 1 prim + ]
        [ 
          current-run max-run prim < [ max-run ] [ current-run ] if
        ]
        if
      ] [
        current-run max-run prim < [ max-run ] [ current-run ] if
      ] if
      index 1 prim +
      xs
      swap
      run-loop
    ] [
      current-run max-run prim < [ max-run ] [ current-run ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs 0 1 0 run-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 23, column 7
message: In the true branch `[ index xs prim seq-int.len 1 prim - ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, index:Int, current-run:Int, max-run:Int), but the branch has pushed only 3 values before it (the result of an `if`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, index:Int, current-run:Int, max-run:Int. The branch already pushes the result of an `if`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many need:Int^many -- ρ result:Bool^many)
  locals { xs target j need } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at need prim =
      [ true ]
      [ xs target j 1 prim + need pair-inner-loop ]
      if
    ] [
      false
    ] if
  };

: pair-outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at target prim - 
      xs target i 1 prim + pair-inner-loop
      [ true ]
      [ xs target i 1 prim + pair-outer-loop ]
      if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 swap pair-outer-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: pair-outer-loop
at: line 19, column 28
message: `pair-inner-loop` in `pair-outer-loop` takes xs:Seq Int, target:Int, j:Int, need:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `xs` (Seq Int), `target` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Seq Int Int Int Int Seq Int Int Int
hint: These are the values `pair-inner-loop` takes, in another order. By their names and types, `xs` is for `xs` and `target` is for `target`. Of the values of one type, `xs i prim seq-int.at target prim -` and `i 1 prim +` are for `j` and `need`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 30, column 15
message: `pair-outer-loop` in `main` takes xs:Seq Int, target:Int, i:Int, bottom to top, but here it gets, bottom to top, the input `target` (Int), `0` (Int) and the input `xs` (Seq Int). `main` calls `pair-outer-loop`, which has an error of its own; this report assumes `pair-outer-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value, the input `xs` (Seq Int), is not what `pair-outer-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-inner-loop
  (forall ρ; ρ xs:Seq Int^many j:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs j target } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at target prim =
      [ true ]
      [ xs j 1 prim + target distinct-inner-loop ]
      if
    ] [
      false
    ] if
  };

: distinct-outer-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs index count } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      xs index 1 prim + xs prim seq-int.len distinct-inner-loop
      [ count 1 prim + ]
      [ count ]
      if
      index 1 prim +
      xs
      swap
      distinct-outer-loop
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 0 distinct-outer-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-outer-loop
at: line 29, column 7
message: The two branches of the `if` in `distinct-outer-loop` whose true branch is `[ xs index prim seq-int.at xs index 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `distinct-outer-loop`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `distinct-outer-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [ 
          result xs i prim seq-int.at prim seq-int.push
          xs ys i 1 prim + j result merge-loop
        ] [ 
          result ys j prim seq-int.at prim seq-int.push
          xs ys i j 1 prim + result merge-loop
        ]
        if
      ] [
        result xs i prim seq-int.at prim seq-int.push
        xs ys i 1 prim + j result merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        result ys j prim seq-int.at prim seq-int.push
        xs ys i j 1 prim + result merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 25, column 9
message: The two branches of the `if` in `merge-loop` whose true branch is `[ result ys j prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `merge-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      swap
      digits-loop
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  prim seq-int.empty digits-loop;

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-loop
  (forall ρ; ρ n:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { n divisor } {
    divisor divisor prim * n prim < [
      n divisor prim mod 0 prim = [
        false
      ] [
        n divisor 1 prim + is-prime-loop
      ] if
    ] [
      true
    ] if
  };

: sieve-loop
  (forall ρ; ρ limit:Int^many candidate:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { limit candidate result } {
    candidate limit prim < [
      candidate 2 is-prime-loop [
        result candidate prim seq-int.push
      ] [
        result
      ] if
      candidate 1 prim +
      limit
      swap
      sieve-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty sieve-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sieve-loop
at: line 27, column 7
message: `sieve-loop` in `sieve-loop` takes limit:Int, candidate:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), `limit` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t23 Int
hint: These are the values `sieve-loop` takes, in another order. To push them in its order, write `limit candidate 1 prim + candidate 2 is-prime-loop [ result candidate prim seq-int.push ] [ result ] if` in place of `candidate 2 is-prime-loop [ result candidate prim seq-int.push ] [ result ] if candidate 1 prim + limit swap`. With that edit `sieve-loop` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k index counts } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      dup counts swap prim seq-int.at 1 prim + prim seq-int.set
      index 1 prim +
      xs
      k
      swap
      histogram-loop
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    xs k 0 
    prim seq-int.empty
    [ 0 prim seq-int.push ] [ k 1 prim - ] if
    histogram-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 14, column 7
message: In the true branch `[ xs index prim seq-int.at dup counts swap ...` of the `if` in `histogram-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim +`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 22, column 44
message: The two branches of the `if` in `main` whose true branch is `[ 0 prim seq-int.push ]` leave different numbers of values. The true branch takes `0` from below the `if` and leaves the result of `prim seq-int.push`; the false branch leaves the result of `prim -`.
hint: The true branch takes `0` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: find-min-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many min-val:Int^many min-idx:Int^many -- ρ val:Int^many idx:Int^many)
  locals { xs index min-val min-idx } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      dup min-val prim < [
        drop index
      ] [
        drop min-idx
      ] if
      index 1 prim +
      xs
      swap
      swap
      find-min-loop
    ] [
      min-val min-idx
    ] if
  };

: sort-outer-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at xs prim seq-int.len i find-min-loop
      result swap prim seq-int.push
      i 1 prim +
      xs
      swap
      sort-outer-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-outer-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-min-loop
at: line 18, column 7
message: In the true branch `[ xs index prim seq-int.at dup min-val prim ...` of the `if` in `find-min-loop`, `find-min-loop` needs 4 values (xs:Seq Int, index:Int, min-val:Int, min-idx:Int), but the branch has pushed only 3 values before it (the result of an `if`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-min-loop`, exactly the values it takes, in this order: xs:Seq Int, index:Int, min-val:Int, min-idx:Int. The branch already pushes the result of an `if`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-min-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: sort-outer-loop
at: line 30, column 7
message: `sort-outer-loop` in `sort-outer-loop` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int). `sort-outer-loop` calls `find-min-loop`, which has an error of its own; this report assumes `find-min-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: .. Int Seq Int Seq Int Int
hint: The top value, the result of `prim +` (Int), is not what `sort-outer-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many index:Int^many rejected:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance txs index rejected } {
    index txs prim seq-int.len prim < [
      txs index prim seq-int.at
      dup balance prim + 0 prim < [
        drop
        balance
        rejected 1 prim +
        index 1 prim +
        balance txs swap ledger-loop
      ] [
        balance prim +
        rejected
        index 1 prim +
        balance txs swap ledger-loop
      ] if
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap 0 swap 0 ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 20, column 7
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ txs index prim seq-int.at dup balance prim ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of an `if`, the output `final-balance` of `ledger-loop` and the output `final-rejected` of `ledger-loop`; the false branch leaves 2 values, bottom to top: `balance` and `rejected`.
hint: The true branch leaves 1 value more than the false branch: the result of an `if` is left below the output `final-balance` of `ledger-loop` and the output `final-rejected` of `ledger-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 25, column 17
message: `ledger-loop` in `main` takes balance:Int, txs:Seq Int, index:Int, rejected:Int, bottom to top, but here it gets, bottom to top, the input `txs` (Seq Int), `0` (Int), the input `start` (Int) and `0` (Int). `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Seq Int Int Int
actual: ρ Seq Int Int Int Int
hint: The third value from the top, `0` (Int), is not what `ledger-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-left:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock items qtys whole order-idx allocated reasons } {
    order-idx qtys prim seq-int.len prim < [
      items order-idx prim seq-int.at
      stock swap prim seq-int.at
      qtys order-idx prim seq-int.at
      whole order-idx prim seq-bool.at
      dup 
      [ 
        drop
        0
      ] [
        drop drop 1
      ] if
      allocated reasons
      order-idx 1 prim +
      stock items qtys whole swap allocate-loop
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty allocate-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 15, column 9
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ drop 0 ]` leave different numbers of values. The true branch takes the result of `prim seq-bool.at` from below the `if` and leaves `0`; the false branch takes the result of `prim seq-bool.at` and the result of `prim seq-int.at` from below the `if` and leaves `1`.
hint: The false branch takes the result of `prim seq-int.at` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 26, column 60
message: `allocate-loop` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, order-idx:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int
hint: The third value from the top, the result of `prim seq-int.empty` (Seq Int), is not what `allocate-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
