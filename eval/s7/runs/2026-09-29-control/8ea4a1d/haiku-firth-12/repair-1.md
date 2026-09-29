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
  0 swap 0 seq-sum-loop;

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
code: firth.type.word-input-mismatch
word: main
at: line 17, column 12
message: `seq-sum-loop` in `main` takes xs:Seq Int, index:Int, acc:Int, bottom to top, but here it gets, bottom to top, `0` (Int), the input `xs` (Seq Int) and `0` (Int). `main` calls `seq-sum-loop`, which has an error of its own; this report assumes `seq-sum-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: The second value from the top, the input `xs` (Seq Int), is not what `seq-sum-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
      [ drop ]
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
code: firth.type.branch-mismatch
word: seq-max-loop
at: line 9, column 7
message: The two branches of the `if` in `seq-max-loop` whose true branch is `[ drop max-val ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves `max-val`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `max-val` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
      [ index 1 prim + xs x index-loop ]
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
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: index-loop
at: line 7, column 29
message: `index-loop` in `index-loop` takes xs:Seq Int, x:Int, index:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `x` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t57 ?t56
hint: These are the values `index-loop` takes, in another order. To push them in its order, write `xs x index 1 prim +` in place of `index 1 prim + xs x`. With that edit `index-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 15
message: `index-loop` in `main` takes xs:Seq Int, x:Int, index:Int, bottom to top, but here it gets, bottom to top, the input `x` (Int), `0` (Int) and the input `xs` (Seq Int). `main` calls `index-loop`, which has an error of its own; this report assumes `index-loop` keeps its stack effect.
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
      xs index prim seq-int.at result prim seq-int.push
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
  xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 5, column 39
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs index prim seq-int.at` in place of `xs index prim seq-int.at result`. With that edit, the next error in `reverse-loop` is at line 9, column 7.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 17, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
      dup result prim seq-int.push
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
  0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 6, column 18
message: `prim seq-int.push` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t35
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 24
message: `prefix-loop` in `main` needs Seq Int Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int Seq Int. `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: `prefix-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
      [ result prim seq-int.push ]
      [ drop result ]
      if
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
at: line 9, column 7
message: In the true branch `[ result prim seq-int.push ]` of the `if` in `filter-loop`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.
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
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many -- ρ result:Bool^many)
  locals { xs index } {
    index xs prim seq-int.len 1 prim - prim < [
      xs index prim seq-int.at
      xs index 1 prim + prim seq-int.at
      prim < prim not
      [ index 1 prim + xs sorted-loop ]
      [ false ]
      if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 sorted-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sorted-loop
at: line 8, column 27
message: `sorted-loop` in `sorted-loop` takes xs:Seq Int, index:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t33
hint: These are the values `sorted-loop` takes, in another order. To push them in its order, write `xs index 1 prim +` in place of `index 1 prim + xs`. With that edit `sorted-loop` checks.

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
  0 swap 0 dot-loop;

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
code: firth.type.word-input-mismatch
word: main
at: line 21, column 12
message: `dot-loop` in `main` takes xs:Seq Int, ys:Seq Int, index:Int, acc:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int), the input `ys` (Seq Int) and `0` (Int). `main` calls `dot-loop`, which has an error of its own; this report assumes `dot-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int
actual: ρ Seq Int Int Seq Int Int
hint: The second value from the top, the input `ys` (Seq Int), is not what `dot-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many index:Int^many -- ρ result:Bool^many)
  locals { flags index } {
    index flags prim seq-bool.len prim < [
      flags index prim seq-bool.at
      [ index 1 prim + flags all-loop ]
      [ false ]
      if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 all-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: all-loop
at: line 6, column 30
message: `all-loop` in `all-loop` takes flags:Seq Bool, index:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int ?t27
hint: These are the values `all-loop` takes, in another order. To push them in its order, write `flags index 1 prim +` in place of `index 1 prim + flags`. With that edit `all-loop` checks.

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
      xs index prim seq-int.at
      xs index 1 prim + prim seq-int.len prim < [
        [ xs index 1 prim + prim seq-int.at prim = ]
        [ true prim not ]
        if
      ] [
        false
      ] if
      [ current-run 1 prim + ]
      [ 
        current-run max-run prim < [ max-run ] [ current-run ] if
        1
      ]
      if
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
  0 1 0 run-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 9, column 9
message: The two branches of `if` in `run-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at target prim - 
      i 1 prim + xs target i pair-inner-loop
      [ true ]
      [ i 1 prim + xs target pair-outer-loop ]
      if
    ] [
      false
    ] if
  };

: pair-inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many need:Int^many -- ρ result:Bool^many)
  locals { xs target j need } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at need prim =
      [ true ]
      [ j 1 prim + xs target need pair-inner-loop ]
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
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: pair-outer-loop
at: line 12, column 7
message: The two branches of the `if` in `pair-outer-loop` whose true branch is `[ xs i prim seq-int.at target prim - ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim -` and the result of an `if`; the false branch leaves `false`. `pair-outer-loop` calls `pair-inner-loop`, which has an error of its own; this report assumes `pair-inner-loop` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: the result of `prim -` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.word-input-mismatch
word: pair-inner-loop
at: line 21, column 35
message: `pair-inner-loop` in `pair-inner-loop` takes xs:Seq Int, target:Int, j:Int, need:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `target` (Int) and `need` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int ?t74 ?t73 ?t72
hint: These are the values `pair-inner-loop` takes, in another order. To push them in its order, write `xs target j 1 prim + need` in place of `j 1 prim + xs target need`. With that edit `pair-inner-loop` checks.

error 3 of 3
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
: distinct-outer-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs index count } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      index 1 prim + xs prim seq-int.len index 1 prim + distinct-inner-loop
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

: distinct-inner-loop
  (forall ρ; ρ xs:Seq Int^many j:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs j target } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at target prim =
      [ true ]
      [ j 1 prim + xs target distinct-inner-loop ]
      if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 distinct-outer-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: distinct-outer-loop
at: line 16, column 7
message: The two branches of the `if` in `distinct-outer-loop` whose true branch is `[ xs index prim seq-int.at index 1 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `distinct-outer-loop`; the false branch leaves `count`. `distinct-outer-loop` calls `distinct-inner-loop`, which has an error of its own; this report assumes `distinct-inner-loop` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `distinct-outer-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: distinct-inner-loop
at: line 25, column 30
message: `distinct-inner-loop` in `distinct-inner-loop` takes xs:Seq Int, j:Int, target:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `target` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t53 ?t52
hint: These are the values `distinct-inner-loop` takes, in another order. To push them in its order, write `xs j 1 prim + target` in place of `j 1 prim + xs target`. With that edit `distinct-inner-loop` checks.

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
        [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys j result merge-loop ]
        [ ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + result merge-loop ]
        if
      ] [
        xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys j result merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + result merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty merge-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 18, column 9
message: The two branches of the `if` in `merge-loop` whose true branch is `[ ys j prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `merge-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 24, column 22
message: `merge-loop` needs more values than the stack holds here. `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `merge-loop` and in what order.

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
      n 10 prim mod result prim seq-int.push
      n 10 prim div
      swap
      digits-loop
    ] if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many index:Int^many -- ρ reversed:Seq Int^many)
  locals { result index } {
    index 0 prim < [
      result index prim seq-int.at prim seq-int.empty prim seq-int.push
      index 1 prim -
      swap
      reverse-digits
    ] [
      prim seq-int.empty
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  prim seq-int.empty digits-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: digits-loop
at: line 7, column 28
message: `prim seq-int.push` in `digits-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `digits-loop` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 18, column 55
message: `prim seq-int.push` in `reverse-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and the result of `prim seq-int.empty` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `prim seq-int.empty result index prim seq-int.at` in place of `result index prim seq-int.at prim seq-int.empty`. With that edit, the next error in `reverse-digits` is at line 21, column 7.

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
        divisor 1 prim + n is-prime-loop
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
        candidate result prim seq-int.push
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
  2 prim seq-int.empty sieve-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sieve-loop
at: line 20, column 26
message: `prim seq-int.push` in `sieve-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `candidate` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result candidate` in place of `candidate result`. With that edit, the next error in `sieve-loop` is at line 27, column 7.

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
  swap 0 prim seq-int.empty
  [ 0 prim seq-int.push ] [ over 1 prim - ] [ ]
  [ swap 1 prim + swap ] if
  histogram-loop;

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
code: firth.name.unresolved
word: main
at: line 20, column 29
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
        index
        drop drop min-val drop
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
      result prim seq-int.push
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
  0 prim seq-int.empty sort-outer-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-min-loop
at: line 11, column 9
message: The two branches of the `if` in `find-min-loop` whose true branch is `[ index drop drop min-val drop ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves `min-idx`.
hint: The false branch leaves 1 value more than the true branch: `min-idx` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: sort-outer-loop
at: line 27, column 14
message: The quotation run by `dip` in `sort-outer-loop` does not accept the stack below it (.. Int Int Seq Int ?t24 Int [ .. Int Seq Int ?t59 Int -- .. Int Seq Int ?t59 ]). `sort-outer-loop` calls `find-min-loop`, which has an error of its own; this report assumes `find-min-loop` keeps its stack effect.
expected: Seq Int
actual: Int
hint: Check what the quotation body consumes against the values available under it.

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
        drop rejected 1 prim + 
        index 1 prim +
        balance txs swap ledger-loop
      ] [
        balance prim + rejected
        index 1 prim +
        balance txs swap ledger-loop
      ] if
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap 0 swap ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 14, column 9
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ drop rejected 1 prim + index 1 ...` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves 2 values, bottom to top: the output `final-balance` of `ledger-loop` and the output `final-rejected` of `ledger-loop`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves 3 values, bottom to top: the result of `prim +`, the output `final-balance` of `ledger-loop` and the output `final-rejected` of `ledger-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the output `final-balance` of `ledger-loop` and the output `final-rejected` of `ledger-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 22, column 15
message: `ledger-loop` in `main` needs Int Seq Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int. `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Seq Int Int Int
actual: ρ Seq Int Int Int
hint: `ledger-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
        dup 0 prim = [
          drop 2
        ] [
          swap drop 3
        ] if
      ] [
        drop drop 1
      ] if
      order-idx 1 prim +
      stock items qtys whole swap allocate-loop
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty allocate-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 18, column 9
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 2 values, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 28, column 41
message: `allocate-loop` in `main` needs Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int. `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int
hint: `allocate-loop` takes 7 values but only 6 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.
