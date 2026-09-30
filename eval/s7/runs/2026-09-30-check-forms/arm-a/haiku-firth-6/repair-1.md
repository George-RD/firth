Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs i sum } {
    i xs prim seq-int.len prim >=
    [ sum ]
    [ xs i prim seq-int.at sum prim + i 1 prim + xs [ swap swap ] dip sum-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 sum-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-helper
at: line 6, column 71
message: `sum-helper` in `sum-helper` takes xs:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `sum-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxval:Int^many -- ρ result:Int^many)
  locals { xs i maxval } {
    i xs prim seq-int.len prim >=
    [ maxval ]
    [ xs i prim seq-int.at dup maxval prim > [ drop ] [ swap drop ] if i 1 prim + xs [ swap swap ] dip max-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 xs 0 prim seq-int.at max-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-helper
at: line 7, column 5
message: The two branches of `if` in `max-helper` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 5
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
    i xs prim seq-int.len prim >=
    [ count ]
    [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 count-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 7, column 5
message: In the false branch of the `if` in `count-loop` whose true branch is `[ count ]`, `count-loop` needs 4 values (xs:Seq Int, k:Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, count:Int. The branch already pushes, bottom to top, the result of an `if` (from `count`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `k` for the inputs it does not push: write `xs k i 1 prim + xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if count-loop` in place of `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + count-loop` on line 6. With that edit `count-loop` checks. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 5
message: `count-loop` in `main` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int. `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: ρ Seq Int Int Int
hint: `count-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many found:Bool^many -- ρ result:Int^many)
  locals { xs x i found } {
    found
    [ i ]
    [
      i xs prim seq-int.len prim >=
      [ -1 ]
      [ xs i prim seq-int.at x prim = [ true i ] [ false i 1 prim + find-loop ] if ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  false 0 find-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-loop
at: line 9, column 81
message: In the false branch of the `if` in `find-loop` whose true branch is `[ true i ]`, `find-loop` needs 4 values (xs:Seq Int, x:Int, i:Int, found:Bool), but the branch has pushed only 2 values before it (`false` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int, found:Bool. The branch already pushes `false` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 11
message: `find-loop` in `main` takes xs:Seq Int, x:Int, i:Int, found:Bool, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `x` (Int), `false` (Bool) and `0` (Int). `main` calls `find-loop`, which has an error of its own; this report assumes `find-loop` keeps its stack effect.
expected: .. Seq Int Int Int Bool
actual: ρ Seq Int Int Bool Int
hint: The top value, `0` (Int), is not what `find-loop` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs result i } {
    i 0 prim <
    [ result ]
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 7, column 5
message: In the false branch of the `if` in `reverse-loop` whose true branch is `[ result ]`, `reverse-loop` needs 3 values (xs:Seq Int, result:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 22
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
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many sum:Int^many -- ρ sums:Seq Int^many)
  locals { xs result i sum } {
    i xs prim seq-int.len prim >=
    [ result ]
    [ xs i prim seq-int.at sum prim + [ result swap prim seq-int.push ] dip i 1 prim + prefix-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 prefix-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 7, column 5
message: In the false branch of the `if` in `prefix-loop` whose true branch is `[ result ]`, `swap` (inside a quotation in that branch) needs 2 values, but the branch has pushed only 1 value before it (`result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim >=
    [ result ]
    [ xs i prim seq-int.at dup 0 prim > [ result swap prim seq-int.push ] [ drop result ] if i 1 prim + filter-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 filter-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 7, column 5
message: In the false branch of the `if` in `filter-loop` whose true branch is `[ result ]`, `filter-loop` needs 3 values (xs:Seq Int, result:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, i:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `filter-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [ i 1 prim + sorted-loop ] [ false ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 sorted-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sorted-loop
at: line 6, column 103
message: In the true branch `[ i 1 prim + sorted-loop ]` of the `if` in `sorted-loop`, `sorted-loop` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int). Push the first one (xs:Seq Int) before it by writing the local of that name, `xs`: write `xs i 1 prim + sorted-loop` in place of `i 1 prim + sorted-loop` on line 6. With that edit `sorted-loop` checks. If `sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim >=
    [ sum ]
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 7, column 5
message: In the false branch of the `if` in `dot-loop` whose true branch is `[ sum ]`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, sum:Int. The branch already pushes, bottom to top, the result of `prim +` (from `sum`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `ys` for the inputs it does not push: write `xs ys i 1 prim + xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + dot-loop` in place of `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop` on line 6. With that edit `dot-loop` checks. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim >=
    [ true ]
    [ flags i prim seq-bool.at [ i 1 prim + all-loop ] [ false ] if ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 all-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-loop
at: line 6, column 66
message: In the true branch `[ i 1 prim + all-loop ]` of the `if` in `all-loop`, `all-loop` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int). Push the first one (flags:Seq Bool) before it by writing the local of that name, `flags`: write `flags i 1 prim + all-loop` in place of `i 1 prim + all-loop` on line 6. With that edit `all-loop` checks. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many currun:Int^many maxrun:Int^many lastval:Int^many -- ρ length:Int^many)
  locals { xs i currun maxrun lastval } {
    i xs prim seq-int.len prim >=
    [ currun maxrun prim > [ currun ] [ maxrun ] if ]
    [ xs i prim seq-int.at dup lastval prim = 
      [ drop currun 1 prim + i 1 prim + run-loop ]
      [ swap swap prim > [ currun 1 prim + ] [ 1 ] if i 1 prim + run-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim <= [ 0 ] [ 0 0 xs 0 prim seq-int.at run-loop ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 9, column 7
message: In the true branch `[ drop currun 1 prim + i 1 ...` of the `if` in `run-loop`, `run-loop` needs 5 values (xs:Seq Int, i:Int, currun:Int, maxrun:Int, lastval:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). Earlier in the branch, the result of `prim seq-int.at` was already taken from below the `if`. The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, currun:Int, maxrun:Int, lastval:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim >=
    [ i 1 prim + xs prim seq-int.len 1 prim - prim <= [ 0 pair-loop ] [ false ] if ]
    [ i j prim = [ j 1 prim + pair-loop ] [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + pair-loop ] if ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 1 pair-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-loop
at: line 5, column 81
message: In the true branch `[ 0 pair-loop ]` of the `if` in `pair-loop`, `pair-loop` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (`0`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `pair-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes `0`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `pair-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ count:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim >=
    [ count ]
    [ xs i prim seq-int.at 0 xs prim seq-int.len 1 prim - [ xs swap prim seq-int.at prim = ] dip i 1 prim + distinct-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 distinct-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: distinct-loop
at: line 6, column 109
message: `distinct-loop` in `distinct-loop` takes xs:Seq Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of `prim =` (Bool), the result of `prim -` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Bool Int Int
hint: The third value from the top, the result of `prim =` (Bool), is not what `distinct-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    i xs prim seq-int.len prim >= [ j ys prim seq-int.len prim >= ]
    [ result ]
    [ xs i prim seq-int.at ys j prim seq-int.at prim <= 
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j merge-loop ]
      [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + merge-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 merge-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 11, column 5
message: In the false branch of the `if` in `merge-loop` whose true branch is `[ result ]`, `merge-loop` (inside a quotation in that branch) needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` or `i` and `j` or the result of `prim +`). It would take the result of `prim >=` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` or `i` and `j` or the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 26
message: `merge-loop` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `merge-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digit-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim = [ { 0 } ] [ prim seq-int.empty n digit-loop ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 6, column 28
message: `prim seq-int.push` in `digit-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result` on line 6. With that edit, the next error in `digit-loop` is at line 6, column 60.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-helper
  (forall ρ; ρ n:Int^many i:Int^many -- ρ isprime:Bool^many)
  locals { n i } {
    i i prim * n prim >
    [ true ]
    [ n i prim mod 0 prim = [ false ] [ i 1 prim + is-prime-helper ] if ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ isprime:Bool^many)
  n 2 prim < [ false ] [ 2 is-prime-helper ] if;

: prime-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim >
    [ result ]
    [ i is-prime [ i result prim seq-int.push ] [ result ] if i 1 prim + prime-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 prime-loop;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.branch-mismatch
word: is-prime-helper
at: line 6, column 70
message: In the false branch of the `if` in `is-prime-helper` whose true branch is `[ false ]`, `is-prime-helper` needs 2 values (n:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime-helper`, exactly the values it takes, in this order: n:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 4
code: firth.name.unresolved
word: is-prime
at: line 12, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 4
code: firth.type.branch-mismatch
word: prime-loop
at: line 20, column 5
message: In the false branch of the `if` in `prime-loop` whose true branch is `[ result ]`, `prime-loop` needs 3 values (n:Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `prime-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `prime-loop`, exactly the values it takes, in this order: n:Int, i:Int, result:Seq Int. The branch already pushes, bottom to top, the result of an `if` (from `result`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `n` for the input it does not push: write `n i 1 prim + i is-prime [ i result prim seq-int.push ] [ result ] if prime-loop` in place of `i is-prime [ i result prim seq-int.push ] [ result ] if i 1 prim + prime-loop` on line 19. With that edit, the next error in `prime-loop` is at line 19, column 42. If `prime-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 4
code: firth.type.word-input-mismatch
word: main
at: line 25, column 24
message: `prime-loop` in `main` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `n` (Int), the result of `prim seq-int.empty` (Seq Int) and `2` (Int). `main` calls `prime-loop`, which has an error of its own; this report assumes `prime-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int Int
hint: The top value, `2` (Int), is not what `prime-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: hist-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim >=
    [ counts ]
    [ xs i prim seq-int.at [ counts swap ] dip dup 1 prim + prim seq-int.set i 1 prim + hist-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  0 prim seq-int.empty k [ prim seq-int.push ] dip 0 hist-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: hist-loop
at: line 7, column 5
message: In the false branch of the `if` in `hist-loop` whose true branch is `[ counts ]`, `swap` (inside a quotation in that branch) needs 2 values, but the branch has pushed only 1 value before it (`counts`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 24
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sorted-check
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [ i 1 prim + sorted-check ] [ false ] if ]
    if
  };

: swap-once
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ xs:Seq Int^many swapped:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ xs false ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim > 
      [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at xs i prim seq-int.set xs i 1 prim + swap prim seq-int.set true ]
      [ xs false ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 sorted-check [ xs ] [ xs 0 swap-once sort-loop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  sort-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: sorted-check
at: line 6, column 104
message: In the true branch `[ i 1 prim + sorted-check ]` of the `if` in `sorted-check`, `sorted-check` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sorted-check`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int). Push the first one (xs:Seq Int) before it by writing the local of that name, `xs`: write `xs i 1 prim + sorted-check` in place of `i 1 prim + sorted-check` on line 6. With that edit `sorted-check` checks. If `sorted-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: swap-once
at: line 18, column 7
message: The two branches of the `if` in `swap-once` whose true branch is `[ xs i prim seq-int.at xs i 1 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.set` and `true`; the false branch leaves 2 values, bottom to top: `xs` and `false`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `prim seq-int.set` and `true`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.branch-mismatch
word: sort-loop
at: line 26, column 59
message: The two branches of the `if` in `sort-loop` whose true branch is `[ xs ]` leave different numbers of values. The true branch leaves `xs`; the false branch leaves 2 values, bottom to top: the output `xs` of `swap-once` and the result of `sort-loop`. `sort-loop` calls `swap-once`, which has an error of its own; this report assumes `swap-once` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the output `xs` of `swap-once` is left below the result of `sort-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ final:Int^many count:Int^many)
  locals { start txs i balance rejected } {
    i txs prim seq-int.len prim >=
    [ balance rejected ]
    [ txs i prim seq-int.at balance prim + dup 0 prim < 
      [ drop rejected 1 prim + i 1 prim + ledger-loop ]
      [ balance swap prim drop rejected i 1 prim + ledger-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 ledger-loop;

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 8, column 27
message: Unexpected `drop`, expected `primitive name`.
expected: primitive name
actual: drop
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i qtys prim seq-int.len prim >=
    [ stock allocated reasons ]
    [ items i prim seq-int.at stock swap prim seq-int.at [ qtys i prim seq-int.at stock swap prim seq-int.at prim <= ]
      [ qtys i prim seq-int.at allocated prim seq-int.push 0 reasons prim seq-int.push ]
      [ stock swap prim seq-int.at 0 prim = 
        [ 0 allocated prim seq-int.push 2 reasons prim seq-int.push ]
        [ whole i prim seq-bool.at 
          [ 0 allocated prim seq-int.push 3 reasons prim seq-int.push ]
          [ stock swap prim seq-int.at allocated prim seq-int.push 1 reasons prim seq-int.push ]
          if
        ]
        if
      ]
      if
      i 1 prim + allocate-loop
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
at: line 13, column 11
message: In the false branch of the `if` in `allocate-loop` whose true branch is `[ 0 allocated prim seq-int.push 3 reasons prim seq-int.push ]`, `swap` needs 2 values, but the branch has pushed only 1 value before it (`stock`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 25, column 43
message: `allocate-loop` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `allocate-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
