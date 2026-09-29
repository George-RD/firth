Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many s:Int^many -- ρ result:Int^many)
  locals { xs i s } {
    xs prim seq-int.len i prim < [
      xs i s prim seq-int.at prim +
      i 1 prim + swap
      sum-acc
    ] [
      s
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-acc;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-acc
at: line 10, column 7
message: The two branches of `if` in `sum-acc` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many m:Int^many -- ρ result:Int^many)
  locals { xs i m } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at m prim < [ xs i prim seq-int.at ] [ m ] if
      i 1 prim + swap
      max-acc
    ] [
      m
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1 swap
    max-acc
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-acc
at: line 10, column 7
message: In the true branch `[ xs i prim seq-int.at m prim < ...` of the `if` in `max-acc`, `max-acc` needs 3 values (xs:Seq Int, i:Int, m:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-acc`, exactly the values it takes, in this order: xs:Seq Int, i:Int, m:Int. The branch already pushes the result of `prim +` and the result of an `if`, in the place of the last 2 (i:Int, m:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-acc` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 5
message: `max-acc` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Int Int. `main` calls `max-acc`, which has an error of its own; this report assumes `max-acc` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int
hint: `max-acc` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many c:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs i c k } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at k prim < [ c 1 prim + ] [ c ] if
      i 1 prim + swap
      count-acc
    ] [
      c
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs 0 0 k count-acc
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-acc
at: line 10, column 7
message: In the true branch `[ xs i prim seq-int.at k prim < ...` of the `if` in `count-acc`, `count-acc` needs 4 values (xs:Seq Int, i:Int, c:Int, k:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-acc`, exactly the values it takes, in this order: xs:Seq Int, i:Int, c:Int, k:Int. The branch already pushes the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-acc` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs i x } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        i 1 prim +
        find-acc
      ] if
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 swap find-acc;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-acc
at: line 10, column 9
message: In the false branch of the `if` in `find-acc` whose true branch is `[ i ]`, `find-acc` needs 3 values (xs:Seq Int, i:Int, x:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-acc`, exactly the values it takes, in this order: xs:Seq Int, i:Int, x:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-acc` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 15
message: `find-acc` in `main` takes xs:Seq Int, i:Int, x:Int, bottom to top, but here it gets, bottom to top, the input `x` (Int), `0` (Int) and the input `xs` (Seq Int). `main` calls `find-acc`, which has an error of its own; this report assumes `find-acc` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value, the input `xs` (Seq Int), is not what `find-acc` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i r } {
    i 0 prim < [
      xs i prim seq-int.at r prim seq-int.push
      i -1 prim +
      reverse-loop
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    reverse-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 10, column 7
message: In the true branch `[ xs i prim seq-int.at r prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, r:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, r:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (r:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 5
message: `reverse-loop` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int. `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Int
hint: `reverse-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many s:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i s r } {
    xs prim seq-int.len i prim < [
      s xs i prim seq-int.at prim +
      r swap prim seq-int.push
      i 1 prim +
      swap
      prefix-acc
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-acc
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-acc
at: line 12, column 7
message: In the true branch `[ s xs i prim seq-int.at prim + ...` of the `if` in `prefix-acc`, `prefix-acc` needs 4 values (xs:Seq Int, i:Int, s:Int, r:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim seq-int.push`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-acc`, exactly the values it takes, in this order: xs:Seq Int, i:Int, s:Int, r:Seq Int. The branch already pushes the result of `prim +` and the result of `prim seq-int.push`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prefix-acc` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i r } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at dup 0 prim < prim not [
        r swap prim seq-int.push
      ] [
        drop
      ] if
      i 1 prim +
      filter-acc
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-acc
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-acc
at: line 9, column 9
message: The two branches of the `if` in `filter-acc` whose true branch is `[ r swap prim seq-int.push ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [
        false
      ] [
        i 1 prim +
        check-sorted
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs prim seq-int.len 1 prim < [
    true
  ] [
    0 check-sorted
  ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-sorted
at: line 10, column 9
message: In the false branch of the `if` in `check-sorted` whose true branch is `[ false ]`, `check-sorted` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-sorted`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `check-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 18, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-acc
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many s:Int^many -- ρ result:Int^many)
  locals { xs ys i s } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at ys i prim seq-int.at prim * s prim +
      i 1 prim +
      swap
      dot-acc
    ] [
      s
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  swap 0 0 dot-acc;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-acc
at: line 11, column 7
message: In the true branch `[ xs i prim seq-int.at ys i prim ...` of the `if` in `dot-acc`, `dot-acc` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, s:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-acc`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, s:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, s:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-acc` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    flags prim seq-bool.len i prim < [
      flags i prim seq-bool.at prim not [
        false
      ] [
        i 1 prim +
        check-all
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  flags prim seq-bool.len 0 prim = [
    true
  ] [
    0 check-all
  ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-all
at: line 10, column 9
message: In the false branch of the `if` in `check-all` whose true branch is `[ false ]`, `check-all` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `check-all` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 18, column 3
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cur:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i cur max } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [
        cur 1 prim + i 1 prim + run-loop
      ] [
        cur max prim < [ max ] [ cur ] if
        1 i 1 prim +
        swap
        run-loop
      ] if
    ] [
      cur max prim < [ max ] [ cur ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim = [
    0
  ] [
    xs 0 1 0 run-loop
  ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 12, column 9
message: In the true branch `[ cur 1 prim + i 1 prim ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, i:Int, cur:Int, max:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, cur:Int, max:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 20, column 3
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
: outer-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs i target } {
    xs prim seq-int.len i prim < [
      i 1 prim + inner-loop xs i target [
        true
      ] [
        i 1 prim +
        outer-loop
      ] if
    ] [
      false
    ] if
  };

: inner-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs i target } {
    xs prim seq-int.len j prim < [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [
        true
      ] [
        j 1 prim +
        inner-loop xs i target
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 swap outer-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: outer-loop
at: line 10, column 9
message: The two branches of the `if` in `outer-loop` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch takes `i` and `xs` from below the `if` and leaves the result of `outer-loop`.
hint: The false branch takes `i` and `xs` from below the `if`, and the true branch leaves them in place, so after the true branch them are still on the stack. If the true branch should use them too, use them there, for example as an input of the operation that needs them, or drop them. If not, the false branch should not take them. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.stack-underflow
word: inner-loop
at: line 28, column 7
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 33, column 15
message: `outer-loop` in `main` takes xs:Seq Int, i:Int, target:Int, bottom to top, but here it gets, bottom to top, the input `target` (Int), `0` (Int) and the input `xs` (Seq Int). `main` calls `outer-loop`, which has an error of its own; this report assumes `outer-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value, the input `xs` (Seq Int), is not what `outer-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-unique
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs i } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at is-new xs i 1 prim + [
        1 prim +
      ] [
      ] if
      count-unique
    ] [
      0
    ] if
  };

: is-new
  (forall ρ; ρ v:Int^many xs:Seq Int^many start:Int^many -- ρ result:Bool^many)
  locals { v xs start } {
    xs prim seq-int.len start prim < [
      xs start prim seq-int.at v prim = [
        false
      ] [
        start 1 prim +
        is-new
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 xs prim seq-int.len nested-count;

: nested-count
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i len xs } {
    len i prim < [
      xs i prim seq-int.at 0 is-new-from xs i [
        count 1 prim +
      ] [
        count
      ] if
      i 1 prim +
      nested-count
    ] [
      count
    ] if
  };

: is-new-from
  (forall ρ; ρ v:Int^many start:Int^many xs:Seq Int^many j:Int^many -- ρ result:Bool^many)
  locals { v start xs j } {
    j start prim < [
      xs j prim seq-int.at v prim = [
        false
      ] [
        j 1 prim +
        is-new-from
      ] if
    ] [
      true
    ] if
  };

```
On the example, the run failed:
The checker found 5 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 5
code: firth.type.branch-mismatch
word: count-unique
at: line 12, column 7
message: In the true branch `[ xs i prim seq-int.at is-new xs i ...` of the `if` in `count-unique`, `is-new` needs 3 values (v:Int, xs:Seq Int, start:Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `count-unique` calls `is-new`, which has an error of its own; this report assumes `is-new` keeps its stack effect.
hint: Make the branch push, just before `is-new`, exactly the values it takes, in this order: v:Int, xs:Seq Int, start:Int. The branch already pushes the result of `prim seq-int.at`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `is-new` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 5
code: firth.type.branch-mismatch
word: is-new
at: line 24, column 9
message: In the false branch of the `if` in `is-new` whose true branch is `[ false ]`, `is-new` needs 3 values (v:Int, xs:Seq Int, start:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-new`, exactly the values it takes, in this order: v:Int, xs:Seq Int, start:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `is-new` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 5
code: firth.name.unresolved
word: main
at: line 32, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 4 of 5
code: firth.type.branch-mismatch
word: nested-count
at: line 47, column 7
message: In the true branch `[ xs i prim seq-int.at 0 is-new-from xs ...` of the `if` in `nested-count`, `is-new-from` needs 4 values (v:Int, start:Int, xs:Seq Int, j:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and `0`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `nested-count` calls `is-new-from`, which has an error of its own; this report assumes `is-new-from` keeps its stack effect.
hint: Make the branch push, just before `is-new-from`, exactly the values it takes, in this order: v:Int, start:Int, xs:Seq Int, j:Int. The branch already pushes the result of `prim seq-int.at` and `0`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `is-new-from` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 5 of 5
code: firth.type.branch-mismatch
word: is-new-from
at: line 59, column 9
message: In the false branch of the `if` in `is-new-from` whose true branch is `[ false ]`, `is-new-from` needs 4 values (v:Int, start:Int, xs:Seq Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-new-from`, exactly the values it takes, in this order: v:Int, start:Int, xs:Seq Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `is-new-from` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j r } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [
      xs i prim seq-int.at ys j prim seq-int.at prim < [
        r xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        j
        merge-loop
      ] [
        r ys j prim seq-int.at prim seq-int.push
        i
        j 1 prim +
        merge-loop
      ] if
    ] [
      i xs prim seq-int.len prim < [
        r xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        j
        merge-loop
      ] [
        j ys prim seq-int.len prim < [
          r ys j prim seq-int.at prim seq-int.push
          i
          j 1 prim +
          merge-loop
        ] [
          r
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  swap 0 0 prim seq-int.empty merge-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 30, column 11
message: In the true branch `[ r ys j prim seq-int.at prim seq-int.push ...` of the `if` in `merge-loop`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, r:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `i` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, r:Seq Int. The branch already pushes the result of `prim seq-int.push`, `i` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { n r } {
    n 0 prim = [
      r
    ] [
      n 10 prim mod r prim seq-int.push
      n 10 prim div
      digits-loop
    ] if
  };

: reverse-digits
  (forall ρ; ρ d:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { d i r } {
    i 0 prim < [
      d i prim seq-int.at r prim seq-int.push
      i -1 prim +
      reverse-digits
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty digits-loop
      dup prim seq-int.len 1 prim -
      prim seq-int.empty
      reverse-digits
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: digits-loop
at: line 7, column 23
message: `prim seq-int.push` in `digits-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `r` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `r n 10 prim mod` in place of `n 10 prim mod r`. With that edit, the next error in `digits-loop` is at line 9, column 7.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-digits
at: line 22, column 7
message: In the true branch `[ d i prim seq-int.at r prim seq-int.push ...` of the `if` in `reverse-digits`, `reverse-digits` needs 3 values (d:Seq Int, i:Int, r:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: d:Seq Int, i:Int, r:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`, in the place of the first 2 (d:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (r:Seq Int) after them, for example by writing the locals that hold it. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    n 2 prim < [
      false
    ] [
      d d prim * n prim < [
        n d prim mod 0 prim = [
          false
        ] [
          d 1 prim +
          is-prime
        ] if
      ] [
        true
      ] if
    ] if
  };

: collect-primes
  (forall ρ; ρ n:Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i r } {
    i n prim < [
      i 2 is-prime [
        r i prim seq-int.push
      ] [
        r
      ] if
      i 1 prim +
      collect-primes
    ] [
      r
    ] if
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
at: line 13, column 11
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `is-prime` needs 2 values (n:Int, d:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime`, exactly the values it takes, in this order: n:Int, d:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: collect-primes
at: line 33, column 7
message: In the true branch `[ i 2 is-prime [ r i prim ...` of the `if` in `collect-primes`, `collect-primes` needs 3 values (n:Int, i:Int, r:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `collect-primes` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `collect-primes`, exactly the values it takes, in this order: n:Int, i:Int, r:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `collect-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ k:Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i r } {
    i k prim < [
      r 0 prim seq-int.push
      i 1 prim +
      init-counts
    ] [
      r
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i counts } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + prim seq-int.set swap drop
      i 1 prim +
      count-loop
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-counts
    xs 0 swap count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: init-counts
at: line 10, column 7
message: In the true branch `[ r 0 prim seq-int.push i 1 prim ...` of the `if` in `init-counts`, `init-counts` needs 3 values (k:Int, i:Int, r:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-counts`, exactly the values it takes, in this order: k:Int, i:Int, r:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `init-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 22, column 7
message: In the true branch `[ xs i prim seq-int.at dup counts swap ...` of the `if` in `count-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim +`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ v:Int^many r:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { v r i } {
    i r prim seq-int.len prim < [
      r i prim seq-int.at v prim < [
        insert-at r v i
      ] [
        i 1 prim +
        insert-sorted
      ] if
    ] [
      r v prim seq-int.push
    ] if
  };

: insert-at
  (forall ρ; ρ r:Seq Int^many v:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { r v i } {
    r v prim seq-int.push i r prim seq-int.len 1 prim - shift-loop
  };

: shift-loop
  (forall ρ; ρ i:Int^many r:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { i r len } {
    i len prim < [
      r i prim seq-int.at r i 1 prim - prim seq-int.set
      i 1 prim +
      shift-loop
    ] [
      r
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i r } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at r 0 insert-sorted
      i 1 prim +
      swap
      sort-loop
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
The checker found 5 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 5
code: firth.type.branch-mismatch
word: insert-sorted
at: line 10, column 9
message: In the true branch `[ insert-at r v i ]` of the `if` in `insert-sorted`, `insert-at` needs 3 values (r:Seq Int, v:Int, i:Int), but the branch has pushed nothing before it. The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `insert-sorted` calls `insert-at`, which has an error of its own; this report assumes `insert-at` keeps its stack effect.
hint: Push every value `insert-at` takes inside the branch, just before it and in this order: r:Seq Int, v:Int, i:Int, for example by writing the locals that hold them. If `insert-at` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 5
code: firth.type.word-input-mismatch
word: insert-at
at: line 19, column 57
message: `shift-loop` in `insert-at` takes i:Int, r:Seq Int, len:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `i` (Int) and the result of `prim -` (Int). `insert-at` calls `shift-loop`, which has an error of its own; this report assumes `shift-loop` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Seq Int Int Int
hint: These are the values `shift-loop` takes, in another order. To push them in its order, write `i r v prim seq-int.push r prim seq-int.len 1 prim -` in place of `r v prim seq-int.push i r prim seq-int.len 1 prim -`. With that edit `insert-at` checks.

error 3 of 5
code: firth.type.branch-mismatch
word: shift-loop
at: line 31, column 7
message: In the true branch `[ r i prim seq-int.at r i 1 ...` of the `if` in `shift-loop`, `shift-loop` needs 3 values (i:Int, r:Seq Int, len:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `shift-loop`, exactly the values it takes, in this order: i:Int, r:Seq Int, len:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`, in the place of the last 2 (r:Seq Int, len:Int): keep each where it has that type and replace it where it does not. Then push the first one (i:Int) before them, for example by writing the locals that hold it. If `shift-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 5
code: firth.type.branch-mismatch
word: sort-loop
at: line 44, column 7
message: In the true branch `[ xs i prim seq-int.at r 0 insert-sorted ...` of the `if` in `sort-loop`, `sort-loop` needs 3 values (xs:Seq Int, i:Int, r:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `insert-sorted`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `sort-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: Make the branch push, just before `sort-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, r:Seq Int. The branch already pushes the result of `prim +` and the result of `insert-sorted`, in the place of the last 2 (i:Int, r:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sort-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 5 of 5
code: firth.name.unresolved
word: main
at: line 49, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many bal:Int^many rej:Int^many -- ρ result1:Int^many result2:Int^many)
  locals { txs i bal rej } {
    txs prim seq-int.len i prim < [
      bal txs i prim seq-int.at prim + dup 0 prim < [
        drop bal rej 1 prim + i 1 prim + swap ledger-loop
      ] [
        i 1 prim + swap rej ledger-loop
      ] if
    ] [
      bal rej
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap 0 0 ledger-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 12, column 7
message: In the true branch `[ bal txs i prim seq-int.at prim + ...` of the `if` in `ledger-loop`, `ledger-loop` (inside a quotation in that branch) needs 4 values (txs:Seq Int, i:Int, bal:Int, rej:Int), but the branch has pushed only 3 values before it (`bal` or the result of `prim +`, the result of `prim +` and the result of `prim +` or `rej`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: txs:Seq Int, i:Int, bal:Int, rej:Int. The branch already pushes `bal` or the result of `prim +`, the result of `prim +` and the result of `prim +` or `rej`, in the place of the last 3 (i:Int, bal:Int, rej:Int): keep each where it has that type and replace it where it does not. Then push the first one (txs:Seq Int) before them, for example by writing the locals that hold it. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i alloc reasons } {
    items prim seq-int.len i prim < [
      items i prim seq-int.at dup
      stock swap prim seq-int.at
      locals { item_idx current_stock } {
        current_stock qtys i prim seq-int.at prim < prim not [
          alloc qtys i prim seq-int.at prim seq-int.push
          reasons 0 prim seq-int.push
          stock item_idx qtys i prim seq-int.at prim seq-int.set
        ] [
          current_stock 0 prim = [
            alloc 0 prim seq-int.push
            reasons 2 prim seq-int.push
          ] [
            whole i prim seq-bool.at [
              alloc 0 prim seq-int.push
              reasons 3 prim seq-int.push
            ] [
              alloc current_stock prim seq-int.push
              reasons 1 prim seq-int.push
              stock item_idx 0 prim seq-int.set
            ] if
          ] if
        ] if
        i 1 prim +
        allocate-loop
      }
    ] [
      stock alloc reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 153
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
