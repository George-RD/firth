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
    i xs prim seq-int.len prim <
    [
      xs i 1 prim + i xs prim seq-int.at sum prim + sum-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 sum-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sum-loop
at: line 6, column 26
message: `prim seq-int.at` in `sum-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t24 ?t26 Int Int ?t26
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 6. With that edit `sum-loop` checks.

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
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at max-val prim <
      [ i xs prim seq-int.at ]
      [ max-val ]
      if
      i 1 prim +
      max-loop
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 xs prim seq-int.at 1 max-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 14, column 5
message: In the true branch `[ i xs prim seq-int.at max-val prim < ...` of the `if` in `max-loop`, `max-loop` needs 3 values (xs:Seq Int, i:Int, max-val:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, max-val:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (i:Int, max-val:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 19, column 5
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i k count } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim +
      count-loop
    ]
    [ count ]
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
at: line 14, column 5
message: In the true branch `[ i xs prim seq-int.at k prim < ...` of the `if` in `count-loop`, `count-loop` needs 4 values (xs:Seq Int, i:Int, k:Int, count:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, k:Int, count:Int. The branch already pushes, bottom to top, the result of an `if` (from `count`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `k` for the inputs it does not push: write `xs i 1 prim + k i xs prim seq-int.at k prim < [ count 1 prim + ] [ count ] if count-loop` in place of `i xs prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + count-loop` on line 6. With that edit, the next error in `count-loop` is at line 6, column 28. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 19, column 5
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
: search-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + search-loop ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  0 search-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: search-loop
at: line 9, column 7
message: In the false branch of the `if` in `search-loop` whose true branch is `[ i ]`, `search-loop` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `search-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `search-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      i xs prim seq-int.at result prim seq-int.push
      i 1 prim -
      reverse-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 11, column 5
message: In the true branch `[ i xs prim seq-int.at result prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `result`) and the result of `prim -` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `xs i 1 prim - i xs prim seq-int.at result prim seq-int.push reverse-loop` in place of `i xs prim seq-int.at result prim seq-int.push i 1 prim - reverse-loop` on line 6. With that edit, the next error in `reverse-loop` is at line 6, column 26. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at sum prim +
      [ result prim seq-int.push ] dip
      i 1 prim +
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 12, column 5
message: In the true branch `[ i xs prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prim seq-int.push` (inside a quotation in that branch) needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `result`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last one (Int) after it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at 0 prim <
      [ result ]
      [ i xs prim seq-int.at result prim seq-int.push ]
      if
      i 1 prim +
      filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty filter-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 14, column 5
message: In the true branch `[ i xs prim seq-int.at 0 prim < ...` of the `if` in `filter-loop`, `filter-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes, bottom to top, the result of an `if` (from `result`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `xs i 1 prim + i xs prim seq-int.at 0 prim < [ result ] [ i xs prim seq-int.at result prim seq-int.push ] if filter-loop` in place of `i xs prim seq-int.at 0 prim < [ result ] [ i xs prim seq-int.at result prim seq-int.push ] if i 1 prim + filter-loop` on line 6. With that edit, the next error in `filter-loop` is at line 6, column 26. If `filter-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      i xs prim seq-int.at i 1 prim + xs prim seq-int.at prim <
      [ false ]
      [ i 1 prim + check-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  0 check-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-loop
at: line 9, column 7
message: In the false branch of the `if` in `check-loop` whose true branch is `[ false ]`, `check-loop` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int). Push the first one (xs:Seq Int) before it by writing the local of that name, `xs`: write `xs i 1 prim + check-loop` in place of `i 1 prim + check-loop` on line 8. With that edit, the next error in `check-loop` is at line 6, column 12. If `check-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at i ys prim seq-int.at prim *
      sum prim +
      i 1 prim +
      dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  0 0 dot-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 12, column 5
message: In the true branch `[ i xs prim seq-int.at i ys prim ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, sum:Int. The branch already pushes, bottom to top, the result of `prim +` (from `sum`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `ys` for the inputs it does not push: write `xs ys i 1 prim + i xs prim seq-int.at i ys prim seq-int.at prim * sum prim + dot-loop` in place of `i xs prim seq-int.at i ys prim seq-int.at prim * sum prim + i 1 prim + dot-loop` on line 6. With that edit, the next error in `dot-loop` is at line 6, column 29. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      i flags prim seq-bool.at
      [ i 1 prim + check-loop ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  0 check-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-loop
at: line 9, column 7
message: In the true branch `[ i 1 prim + check-loop ]` of the `if` in `check-loop`, `check-loop` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-loop`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int). Push the first one (flags:Seq Bool) before it by writing the local of that name, `flags`: write `flags i 1 prim + check-loop` in place of `i 1 prim + check-loop` on line 7. With that edit, the next error in `check-loop` is at line 6, column 15. If `check-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-len max-len } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at current-val prim =
      [
        current-len 1 prim +
        [ current-val current-len 1 prim + max-len ] dip
      ]
      [
        current-len max-len prim <
        [ max-len ]
        [ current-len ]
        if
        [ i xs prim seq-int.at 1 ] dip
      ]
      if
      i 1 prim +
      run-loop
    ]
    [
      current-len max-len prim <
      [ max-len ]
      [ current-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ 0 xs prim seq-int.at 1 0 run-loop ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 18, column 7
message: The two branches of the `if` in `run-loop` whose true branch is `[ current-len 1 prim + [ current-val current-len ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: `current-val`, the result of `prim +`, `max-len` and the result of `prim +`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, `1` and the result of an `if`.
hint: The true branch leaves 1 value more than the false branch: `current-val` is left below the result of `prim +`, `max-len` and the result of `prim +`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 33, column 3
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
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [ j 1 prim + inner-loop ]
      [
        i xs prim seq-int.at j xs prim seq-int.at prim +
        target prim =
        [ true ]
        [ j 1 prim + inner-loop ]
        if
      ]
      if
    ]
    [ false ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [
      i 0 inner-loop
      [ true ]
      [ i 1 prim + outer-loop ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  0 outer-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: inner-loop
at: line 13, column 9
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ true ]`, `inner-loop` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: outer-loop
at: line 29, column 7
message: In the false branch of the `if` in `outer-loop` whose true branch is `[ true ]`, `outer-loop` needs 3 values (xs:Seq Int, target:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
hint: Make the branch push, just before `outer-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `outer-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ result:Int^many)
  locals { xs i counts } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at
      [ counts 0 prim seq-int.len ] dip
      [ 0 prim seq-int.empty ] dip
      [ dup counts prim seq-int.push ] dip
      i 1 prim +
      count-loop
    ]
    [ counts prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 prim seq-int.empty count-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 14, column 5
message: The two branches of the `if` in `count-loop` whose true branch is `[ i xs prim seq-int.at [ counts 0 ...` leave different numbers of values. The true branch leaves 5 values, bottom to top: `counts`, the result of `prim seq-int.len`, `0`, the result of `prim seq-int.empty` and the result of `count-loop`; the false branch leaves the result of `prim seq-int.len`.
hint: The true branch leaves 4 values more than the false branch: `counts`, the result of `prim seq-int.len`, `0` and the result of `prim seq-int.empty` are left below the result of `count-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      i xs prim seq-int.at j ys prim seq-int.at prim <
      [
        i xs prim seq-int.at result prim seq-int.push
        i 1 prim +
        merge-loop
      ]
      [
        j ys prim seq-int.at result prim seq-int.push
        j 1 prim +
        merge-loop
      ]
      if
    ]
    [
      [
        i xs prim seq-int.len prim <
        [
          i xs prim seq-int.at result prim seq-int.push
          i 1 prim +
        ]
        [ false ]
        if
      ]
      [ true ]
      compose call
      [
        j ys prim seq-int.len prim <
        [
          j ys prim seq-int.at result prim seq-int.push
          j 1 prim +
        ]
        [ false ]
        if
      ]
      [ true ]
      compose call
      result
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
at: line 28, column 9
message: The two branches of `if` in `merge-loop` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
      n 10 prim div digit-loop
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many rev:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result i rev } {
    i 0 prim <
    [
      i result prim seq-int.at rev prim seq-int.push
      i 1 prim -
      reverse-digits
    ]
    [ rev ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  n 0 prim =
  [
    prim seq-int.empty 0 prim seq-int.push
  ]
  [
    prim seq-int.empty digit-loop
    dup prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-digits
  ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 14, column 28
message: `prim seq-int.push` in `digit-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t29
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result` on line 14. With that edit, the next error in `digit-loop` is at line 15, column 21.

error 2 of 3
code: firth.type.branch-mismatch
word: reverse-digits
at: line 30, column 5
message: In the true branch `[ i result prim seq-int.at rev prim seq-int.push ...` of the `if` in `reverse-digits`, `reverse-digits` needs 3 values (result:Seq Int, i:Int, rev:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: result:Seq Int, i:Int, rev:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `rev`) and the result of `prim -` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `result` for the input it does not push: write `result i 1 prim - i result prim seq-int.at rev prim seq-int.push reverse-digits` in place of `i result prim seq-int.at rev prim seq-int.push i 1 prim - reverse-digits` on line 25. With that edit, the next error in `reverse-digits` is at line 25, column 34. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 35, column 3
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
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [ d 1 prim + is-prime-check ]
      if
    ]
    [ true ]
    if
  };

: sieve-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <
    [
      i 2 prim <
      [ i 1 prim + sieve-loop ]
      [
        i 2 is-prime-check
        [
          i result prim seq-int.push
        ]
        [ result ]
        if
        i 1 prim +
        sieve-loop
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  2 prim seq-int.empty sieve-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime-check
at: line 9, column 7
message: In the false branch of the `if` in `is-prime-check` whose true branch is `[ false ]`, `is-prime-check` needs 2 values (n:Int, d:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime-check`, exactly the values it takes, in this order: n:Int, d:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: sieve-loop
at: line 32, column 7
message: In the true branch `[ i 1 prim + sieve-loop ]` of the `if` in `sieve-loop`, `sieve-loop` needs 3 values (n:Int, i:Int, result:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `sieve-loop` calls `is-prime-check`, which has an error of its own; this report assumes `is-prime-check` keeps its stack effect.
hint: Make the branch push, just before `sieve-loop`, exactly the values it takes, in this order: n:Int, i:Int, result:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `sieve-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at
      [ counts dup prim seq-int.len ] dip
      i xs prim seq-int.at counts prim seq-int.at 1 prim + counts prim seq-int.set
      i 1 prim +
      histogram-loop
    ]
    [ counts ]
    if
  };

: init-counts
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i counts } {
    i k prim <
    [
      counts 0 prim seq-int.push
      i 1 prim +
      init-counts
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty init-counts histogram-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 6, column 12
message: `prim seq-int.at` in `histogram-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 6. With that edit, the next error in `histogram-loop` is at line 8, column 12.

error 2 of 3
code: firth.type.branch-mismatch
word: init-counts
at: line 26, column 5
message: In the true branch `[ counts 0 prim seq-int.push i 1 prim ...` of the `if` in `init-counts`, `init-counts` needs 3 values (k:Int, i:Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-counts`, exactly the values it takes, in this order: k:Int, i:Int, counts:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `counts`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `k` for the input it does not push: write `k i 1 prim + counts 0 prim seq-int.push init-counts` in place of `counts 0 prim seq-int.push i 1 prim + init-counts` on line 21. With that edit `init-counts` checks. If `init-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.stack-underflow
word: main
at: line 31, column 36
message: `histogram-loop` in `main` takes 4 values (xs:Seq Int, k:Int, i:Int, counts:Seq Int), bottom to top, but only 2 values are on the stack before it, bottom to top: the input `xs` (Seq Int) and the result of `init-counts` (Seq Int). `main` calls `init-counts` and `histogram-loop`, which have errors of their own; this report assumes they keep their stack effects.
hint: Push the 2 missing values before `histogram-loop`, or take them as inputs in the signature.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many x:Int^many -- ρ result:Seq Int^many)
  locals { result i x } {
    i 0 prim <
    i 1 prim - result prim seq-int.at x prim < prim or
    [
      i result prim seq-int.len prim <
      i 1 prim - result prim seq-int.at x prim < prim and
      [
        i 1 prim - result prim seq-int.at result i prim seq-int.set
        i 1 prim -
        insert-loop
      ]
      [ result i x prim seq-int.set ]
      if
    ]
    [ result ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at result prim seq-int.push
      [ 0 i result ] dip
      insert-loop
      i 1 prim +
      sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-loop
at: line 15, column 7
message: In the true branch `[ i 1 prim - result prim seq-int.at ...` of the `if` in `insert-loop`, `insert-loop` needs 3 values (result:Seq Int, i:Int, x:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, x:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `insert-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: sort-loop
at: line 26, column 12
message: `prim seq-int.at` in `sort-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 26. With that edit, the next error in `sort-loop` is at line 26, column 35. That edit was checked assuming `insert-loop`, which has an error of its own, keeps its stack effect.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      balance i txs prim seq-int.at prim + 0 prim <
      [
        rejected 1 prim +
      ]
      [
        balance i txs prim seq-int.at prim +
      ]
      if
      i 1 prim +
      ledger-loop
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 18, column 5
message: In the true branch `[ balance i txs prim seq-int.at prim + ...` of the `if` in `ledger-loop`, `ledger-loop` needs 4 values (txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 23, column 5
message: `ledger-loop` in `main` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int. `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Seq Int Int Int Int
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
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [
      i items prim seq-int.at
      [ stock dup prim seq-int.len ] dip
      i qtys prim seq-int.at
      i items prim seq-int.at stock prim seq-int.at
      [ i items prim seq-int.at stock prim seq-int.at ] dip
      i qtys prim seq-int.at prim <
      [
        i qtys prim seq-int.at
        [ stock i items prim seq-int.at i qtys prim seq-int.at prim seq-int.set ] dip
        [ allocated i qtys prim seq-int.at prim seq-int.push ] dip
        [ reasons 0 prim seq-int.push ] dip
      ]
      [
        0 prim =
        [
          [ allocated 0 prim seq-int.push ] dip
          [ reasons 2 prim seq-int.push ] dip
        ]
        [
          i whole prim seq-bool.at
          [
            [ allocated 0 prim seq-int.push ] dip
            [ reasons 3 prim seq-int.push ] dip
          ]
          [
            [ stock i items prim seq-int.at prim seq-int.at ] dip
            [ stock i items prim seq-int.at 0 prim seq-int.set ] dip
            [ allocated ] dip
            [ prim seq-int.push ] dip
            [ reasons 1 prim seq-int.push ] dip
          ]
          if
        ]
        if
      ]
      if
      i 1 prim +
      allocate-loop
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  0 prim seq-int.empty prim seq-int.empty allocate-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 37, column 11
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ [ allocated 0 prim seq-int.push ] dip ...` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim seq-int.at`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves 4 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim seq-int.at`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.at` is left below the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim seq-int.at`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
