Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      acc i xs prim seq-int.at prim +
      i 1 prim + acc
      sum-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 [ sum-loop ] [ ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: sum-loop
at: line 5, column 16
message: `prim seq-int.at` in `sum-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 5. With that edit, the next error in `sum-loop` is at line 7, column 7.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 13, column 24
message: In the true branch `[ sum-loop ]` of the `if` in `main`, `sum-loop` needs 3 values (i:Int, acc:Int, xs:Seq Int), but the branch has pushed nothing before it. It would take the input `xs` and `0` from below the `if`, and 1 value more that is not there: the word's inputs are used up, and what lies below them belongs to the caller. `main` calls `sum-loop`, which has an error of its own; this report assumes `sum-loop` keeps its stack effect.
hint: Push every value `sum-loop` takes inside the branch, just before it and in this order: i:Int, acc:Int, xs:Seq Int, for example by writing the locals that hold them. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ i:Int^many max-val:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i max-val xs } {
    i xs prim seq-int.len prim >= [ max-val ] [
      i xs prim seq-int.at
      locals { curr } {
        curr max-val prim > [ curr ] [ max-val ] if
      }
      i 1 prim + [ max-loop ] [ ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 xs prim seq-int.at 1
    max-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 9, column 35
message: In the true branch `[ max-loop ]` of the `if` in `max-loop`, `max-loop` needs 3 values (i:Int, max-val:Int, xs:Seq Int), but the branch has pushed nothing before it. It would take the result of an `if` from below the `if`, and 2 values more that are not there: everything the word was given is bound to locals or already used.
hint: Push every value `max-loop` takes inside the branch, just before it and in this order: i:Int, max-val:Int, xs:Seq Int, for example by writing the locals that hold them. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 16, column 10
message: `prim seq-int.at` in `main` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: ρ Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs 0` in place of `0 xs` on line 16. With that edit, the next error in `main` is at line 17, column 5. That edit was checked assuming `max-loop`, which has an error of its own, keeps its stack effect.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ i:Int^many acc:Int^many k:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i acc k xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      i xs prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if
      i 1 prim +
      count-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 0 [ count-loop ] [ ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 8, column 7
message: In the false branch of the `if` in `count-loop` whose true branch is `[ acc ]`, `count-loop` needs 4 values (i:Int, acc:Int, k:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: i:Int, acc:Int, k:Int, xs:Seq Int. The branch already pushes, bottom to top, the result of an `if` (from `acc`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `k` and `xs` for the inputs it does not push: write `i 1 prim + i xs prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if k xs count-loop` in place of `i xs prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if i 1 prim + count-loop` on line 5. With that edit, the next error in `count-loop` is at line 5, column 23. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 13, column 26
message: In the true branch `[ count-loop ]` of the `if` in `main`, `count-loop` needs 4 values (i:Int, acc:Int, k:Int, xs:Seq Int), but the branch has pushed nothing before it. It would take the input `xs`, the input `k` and `0` from below the `if`, and 1 value more that is not there: the word's inputs are used up, and what lies below them belongs to the caller. `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
hint: Push every value `count-loop` takes inside the branch, just before it and in this order: i:Int, acc:Int, k:Int, xs:Seq Int, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ i:Int^many x:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i x xs } {
    i xs prim seq-int.len prim >= [ 0 1 prim - ] [
      i xs prim seq-int.at x prim = [ i ] [
        i 1 prim + index-loop
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  0 index-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: index-loop
at: line 7, column 9
message: In the false branch of the `if` in `index-loop` whose true branch is `[ i ]`, `index-loop` needs 3 values (i:Int, x:Int, xs:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `index-loop`, exactly the values it takes, in this order: i:Int, x:Int, xs:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `index-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 13, column 5
message: `index-loop` in `main` takes i:Int, x:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `x` (Int) and `0` (Int). `main` calls `index-loop`, which has an error of its own; this report assumes `index-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Seq Int Int Int
hint: The top value, `0` (Int), is not what `index-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i 0 prim < [ acc ] [
      i xs prim seq-int.at acc prim seq-int.push
      i 1 prim -
      reverse-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
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
at: line 8, column 7
message: In the false branch of the `if` in `reverse-loop` whose true branch is `[ acc ]`, `reverse-loop` needs 3 values (i:Int, acc:Seq Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: i:Int, acc:Seq Int, xs:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `acc`) and the result of `prim -` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `i 1 prim - i xs prim seq-int.at acc prim seq-int.push xs reverse-loop` in place of `i xs prim seq-int.at acc prim seq-int.push i 1 prim - reverse-loop` on line 5. With that edit, the next error in `reverse-loop` is at line 5, column 23. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 5
message: `reverse-loop` in `main` needs Int Seq Int Seq Int on top of the stack, but the stack before it is ρ Int Seq Int. `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
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
  (forall ρ; ρ i:Int^many sum:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i sum acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      sum i xs prim seq-int.at prim + locals { new-sum } {
        acc new-sum prim seq-int.push
        i 1 prim +
        new-sum
        prefix-loop
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 0 prim seq-int.empty
  prefix-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-loop
at: line 11, column 7
message: In the false branch of the `if` in `prefix-loop` whose true branch is `[ acc ]`, `prefix-loop` needs 4 values (i:Int, sum:Int, acc:Seq Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `new-sum`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: i:Int, sum:Int, acc:Seq Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `new-sum`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 3
message: `prefix-loop` in `main` takes i:Int, sum:Int, acc:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int
actual: ρ Seq Int Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `prefix-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      i xs prim seq-int.at
      locals { val } {
        val 0 prim > [ acc val prim seq-int.push ] [ acc ] if
      }
      i 1 prim +
      keep-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty
  keep-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: keep-loop
at: line 11, column 7
message: In the false branch of the `if` in `keep-loop` whose true branch is `[ acc ]`, `keep-loop` needs 3 values (i:Int, acc:Seq Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `keep-loop`, exactly the values it takes, in this order: i:Int, acc:Seq Int, xs:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `keep-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 3
message: `keep-loop` in `main` takes i:Int, acc:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `keep-loop`, which has an error of its own; this report assumes `keep-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `keep-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i 1 prim - xs prim seq-int.len prim >= [ true ] [
      i 1 prim - xs prim seq-int.at
      i xs prim seq-int.at
      prim <= [ i 1 prim + check-loop ] [ false ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  xs prim seq-int.len 1 prim <= [ true ] [
    1 check-loop
  ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-loop
at: line 7, column 51
message: In the true branch `[ i 1 prim + check-loop ]` of the `if` in `check-loop`, `check-loop` needs 2 values (i:Int, xs:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-loop`, exactly the values it takes, in this order: i:Int, xs:Seq Int. The branch already pushes the result of `prim +`, in the place of the first one (i:Int). Push the last one (xs:Seq Int) after it by writing the local of that name, `xs`: write `i 1 prim + xs check-loop` in place of `i 1 prim + check-loop` on line 7. With that edit, the next error in `check-loop` is at line 5, column 21. If `check-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 13, column 3
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
: dot-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { i acc xs ys } {
    i xs prim seq-int.len prim >= [ acc ] [
      i xs prim seq-int.at
      i ys prim seq-int.at
      prim *
      acc prim +
      i 1 prim +
      dot-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  0 0
  dot-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: dot-loop
at: line 11, column 7
message: In the false branch of the `if` in `dot-loop` whose true branch is `[ acc ]`, `dot-loop` needs 4 values (i:Int, acc:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: i:Int, acc:Int, xs:Seq Int, ys:Seq Int. The branch already pushes, bottom to top, the result of `prim +` (from `acc`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `ys` for the inputs it does not push: write `i 1 prim + i xs prim seq-int.at i ys prim seq-int.at prim * acc prim + xs ys dot-loop` in place of `i xs prim seq-int.at i ys prim seq-int.at prim * acc prim + i 1 prim + dot-loop` on line 5. With that edit, the next error in `dot-loop` is at line 5, column 23. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 3
message: `dot-loop` in `main` takes i:Int, acc:Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), `0` (Int) and `0` (Int). `main` calls `dot-loop`, which has an error of its own; this report assumes `dot-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `dot-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all-loop
  (forall ρ; ρ i:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { i flags } {
    i flags prim seq-bool.len prim >= [ true ] [
      i flags prim seq-bool.at [ i 1 prim + check-all-loop ] [ false ] if
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  0 check-all-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-all-loop
at: line 5, column 72
message: In the true branch `[ i 1 prim + check-all-loop ]` of the `if` in `check-all-loop`, `check-all-loop` needs 2 values (i:Int, flags:Seq Bool), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all-loop`, exactly the values it takes, in this order: i:Int, flags:Seq Bool. The branch already pushes the result of `prim +`, in the place of the first one (i:Int). Push the last one (flags:Seq Bool) after it by writing the local of that name, `flags`: write `i 1 prim + flags check-all-loop` in place of `i 1 prim + check-all-loop` on line 5. With that edit, the next error in `check-all-loop` is at line 5, column 15. If `check-all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 11, column 5
message: `check-all-loop` in `main` takes i:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, the input `flags` (Seq Bool) and `0` (Int). `main` calls `check-all-loop`, which has an error of its own; this report assumes `check-all-loop` keeps its stack effect.
expected: .. Int Seq Bool
actual: ρ Seq Bool Int
hint: The top value, `0` (Int), is not what `check-all-loop` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ i:Int^many curr-val:Int^many curr-run:Int^many max-run:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i curr-val curr-run max-run xs } {
    i xs prim seq-int.len prim >= [
      curr-run max-run prim > [ curr-run ] [ max-run ] if
    ] [
      i xs prim seq-int.at
      locals { val } {
        val curr-val prim = [
          i 1 prim +
          curr-val
          curr-run 1 prim +
          max-run
          run-loop
        ] [
          curr-run max-run prim > [ curr-run ] [ max-run ] if
          locals { new-max } {
            i 1 prim +
            val
            1
            new-max
            run-loop
          }
        ] if
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs prim seq-int.len 0 prim = [ 0 ] [
    1
    0 xs prim seq-int.at
    1
    0
    run-loop
  ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 26, column 7
message: In the false branch of the `if` in `run-loop` whose true branch is `[ curr-run max-run prim > [ curr-run ] ...`, `run-loop` (inside a quotation in that branch) needs 5 values (i:Int, curr-val:Int, curr-run:Int, max-run:Int, xs:Seq Int), but the branch has pushed only 4 values before it (the result of `prim +`, `curr-val` or `val`, the result of `prim +` or `1` and `max-run` or `new-max`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: i:Int, curr-val:Int, curr-run:Int, max-run:Int, xs:Seq Int. The branch already pushes the result of `prim +`, `curr-val` or `val`, the result of `prim +` or `1` and `max-run` or `new-max`, in the place of the first 4 (i:Int, curr-val:Int, curr-run:Int, max-run:Int): keep each where it has that type and replace it where it does not. Then push the last one (xs:Seq Int) after them, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 31, column 3
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
  (forall ρ; ρ i:Int^many j:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i j target xs } {
    j xs prim seq-int.len prim >= [ false ] [
      i j prim = [ i 1 prim + inner-loop ] [
        i xs prim seq-int.at
        j xs prim seq-int.at
        prim +
        target prim = [ true ] [
          j 1 prim +
          inner-loop
        ] if
      ] if
    ] if
  };

: outer-loop
  (forall ρ; ρ i:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i target xs } {
    i xs prim seq-int.len prim >= [ false ] [
      i 0 inner-loop [ true ] [ i 1 prim + outer-loop ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  0 outer-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: inner-loop
at: line 12, column 11
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ true ]`, `inner-loop` needs 4 values (i:Int, j:Int, target:Int, xs:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: i:Int, j:Int, target:Int, xs:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: outer-loop
at: line 21, column 57
message: In the false branch of the `if` in `outer-loop` whose true branch is `[ true ]`, `outer-loop` needs 3 values (i:Int, target:Int, xs:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
hint: Make the branch push, just before `outer-loop`, exactly the values it takes, in this order: i:Int, target:Int, xs:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `outer-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 27, column 5
message: `outer-loop` in `main` takes i:Int, target:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `target` (Int) and `0` (Int). `main` calls `outer-loop`, which has an error of its own; this report assumes `outer-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Seq Int Int Int
hint: The top value, `0` (Int), is not what `outer-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-inner
  (forall ρ; ρ i:Int^many j:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i j count xs } {
    j xs prim seq-int.len prim >= [
      i 1 prim +
      0
      count-outer
    ] [
      i xs prim seq-int.at
      j xs prim seq-int.at
      prim = [ i 1 prim + 0 count-outer ] [
        j 1 prim +
        count-inner
      ] if
    ] if
  };

: count-outer
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i count xs } {
    i xs prim seq-int.len prim >= [ count ] [
      i i 1 prim +
      count 1 prim +
      count-inner
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 count-outer;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: count-inner
at: line 14, column 9
message: In the true branch `[ i 1 prim + 0 count-outer ]` of the `if` in `count-inner`, `count-outer` needs 3 values (i:Int, count:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `0`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-inner` calls `count-outer`, which has an error of its own; this report assumes `count-outer` keeps its stack effect.
hint: Make the branch push, just before `count-outer`, exactly the values it takes, in this order: i:Int, count:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `0`, in the place of the first 2 (i:Int, count:Int): keep each where it has that type and replace it where it does not. Then push the last one (xs:Seq Int) after them, for example by writing the locals that hold it. If `count-outer` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: count-outer
at: line 25, column 7
message: In the false branch of the `if` in `count-outer` whose true branch is `[ count ]`, `count-inner` needs 4 values (i:Int, j:Int, count:Int, xs:Seq Int), but the branch has pushed only 3 values before it (`i`, the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-outer` calls `count-inner`, which has an error of its own; this report assumes `count-inner` keeps its stack effect.
hint: Make the branch push, just before `count-inner`, exactly the values it takes, in this order: i:Int, j:Int, count:Int, xs:Seq Int. The branch already pushes `i`, the result of `prim +` and the result of `prim +`, in the place of the first 3 (i:Int, j:Int, count:Int): keep each where it has that type and replace it where it does not. Then push the last one (xs:Seq Int) after them, for example by writing the locals that hold it. If `count-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 30, column 7
message: `count-outer` in `main` takes i:Int, count:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `count-outer`, which has an error of its own; this report assumes `count-outer` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Seq Int Int Int
hint: The top value, `0` (Int), is not what `count-outer` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many acc:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { i j acc xs ys } {
    i xs prim seq-int.len prim >= [
      j ys prim seq-int.len prim >= [ acc ] [
        j ys prim seq-int.at acc prim seq-int.push
        j 1 prim +
        merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim >= [
        i xs prim seq-int.at acc prim seq-int.push
        i 1 prim +
        merge-loop
      ] [
        i xs prim seq-int.at
        j ys prim seq-int.at
        prim <= [
          i xs prim seq-int.at acc prim seq-int.push
          i 1 prim +
          merge-loop
        ] [
          j ys prim seq-int.at acc prim seq-int.push
          j 1 prim +
          merge-loop
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  0 0 prim seq-int.empty
  merge-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 9, column 9
message: In the false branch of the `if` in `merge-loop` whose true branch is `[ acc ]`, `merge-loop` needs 5 values (i:Int, j:Int, acc:Seq Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: i:Int, j:Int, acc:Seq Int, xs:Seq Int, ys:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `acc`) and the result of `prim +` (from `j`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `i`, `xs` and `ys` for the inputs it does not push: write `i j 1 prim + j ys prim seq-int.at acc prim seq-int.push xs ys merge-loop` in place of `j ys prim seq-int.at acc prim seq-int.push j 1 prim + merge-loop` on line 6. With that edit, the next error in `merge-loop` is at line 26, column 7. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 34, column 3
message: `merge-loop` in `main` takes i:Int, j:Int, acc:Seq Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), `0` (Int), `0` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `merge-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { n acc } {
    n 0 prim = [ acc ] [
      n 10 prim mod
      acc prim seq-int.push
      n 10 prim div
      digit-loop
    ] if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i 0 prim < [ acc ] [
      i xs prim seq-int.at acc prim seq-int.push
      i 1 prim -
      reverse-digits
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  n 0 prim = [ { 0 } ] [
    prim seq-int.empty digit-loop
    locals { digits } {
      digits prim seq-int.len 1 prim -
      prim seq-int.empty
      reverse-digits
    }
  ] if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 6, column 11
message: `prim seq-int.push` in `digit-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `acc` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `acc n 10 prim mod` in place of `n 10 prim mod acc` on line 5. With that edit, the next error in `digit-loop` is at line 7, column 7.

error 2 of 3
code: firth.type.branch-mismatch
word: reverse-digits
at: line 19, column 7
message: In the false branch of the `if` in `reverse-digits` whose true branch is `[ acc ]`, `reverse-digits` needs 3 values (i:Int, acc:Seq Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: i:Int, acc:Seq Int, xs:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `acc`) and the result of `prim -` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `i 1 prim - i xs prim seq-int.at acc prim seq-int.push xs reverse-digits` in place of `i xs prim seq-int.at acc prim seq-int.push i 1 prim - reverse-digits` on line 16. With that edit, the next error in `reverse-digits` is at line 16, column 23. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 24, column 3
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
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim > [ true ] [
      n d prim mod 0 prim = [ false ] [
        d 1 prim +
        is-prime-check
      ] if
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  n 1 prim <= [ false ] [
    n 2 prim = [ true ] [
      2 is-prime-check
    ] if
  ] if;

: primes-loop
  (forall ρ; ρ i:Int^many limit:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { i limit acc } {
    i limit prim > [ acc ] [
      i is-prime [ acc i prim seq-int.push ] [ acc ] if
      i 1 prim +
      primes-loop
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  2 n prim seq-int.empty
  primes-loop;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.branch-mismatch
word: is-prime-check
at: line 8, column 9
message: In the false branch of the `if` in `is-prime-check` whose true branch is `[ false ]`, `is-prime-check` needs 2 values (d:Int, n:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime-check`, exactly the values it takes, in this order: d:Int, n:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 4
code: firth.name.unresolved
word: is-prime
at: line 14, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 4
code: firth.type.branch-mismatch
word: primes-loop
at: line 27, column 7
message: In the false branch of the `if` in `primes-loop` whose true branch is `[ acc ]`, `primes-loop` needs 3 values (i:Int, limit:Int, acc:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `primes-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `primes-loop`, exactly the values it takes, in this order: i:Int, limit:Int, acc:Seq Int. The branch already pushes, bottom to top, the result of an `if` (from `acc`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `limit` for the input it does not push: write `i 1 prim + limit i is-prime [ acc i prim seq-int.push ] [ acc ] if primes-loop` in place of `i is-prime [ acc i prim seq-int.push ] [ acc ] if i 1 prim + primes-loop` on line 24. With that edit `primes-loop` checks. If `primes-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 4
code: firth.name.unresolved
word: main
at: line 32, column 5
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      i xs prim seq-int.at
      locals { val } {
        val acc prim seq-int.at 1 prim +
        locals { new-count } {
          acc val new-count prim seq-int.set
          i 1 prim +
          histogram-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { k } {
    prim seq-int.empty
    locals { init } {
      0 init prim seq-int.push
      locals { counts } {
        1 k [ counts 0 prim seq-int.push locals { c } { c } [ counts ] if ] [ counts ] if
        0 histogram-loop
      }
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 14, column 7
message: In the false branch of the `if` in `histogram-loop` whose true branch is `[ acc ]`, `histogram-loop` needs 3 values (i:Int, acc:Seq Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `histogram-loop`, exactly the values it takes, in this order: i:Int, acc:Seq Int, xs:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.set` (from `acc`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `i 1 prim + acc val new-count prim seq-int.set xs histogram-loop` in place of `acc val new-count prim seq-int.set i 1 prim + histogram-loop` on line 9. With that edit, the next error in `histogram-loop` is at line 5, column 12. If `histogram-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.elaboration.untracked-local
word: main
at: line 19, column 12
message: The local `k` is used after `if` on line 24 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: partition-loop
  (forall ρ; ρ i:Int^many j:Int^many pivot:Int^many low:Seq Int^many high:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i j pivot low high xs } {
    i xs prim seq-int.len prim >= [
      low high low prim seq-int.push
    ] [
      i xs prim seq-int.at pivot prim <= [
        i xs prim seq-int.at low prim seq-int.push
        i 1 prim +
        partition-loop
      ] [
        i xs prim seq-int.at high prim seq-int.push
        i 1 prim +
        partition-loop
      ] if
    ] if
  };

: sort-inner
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  xs prim seq-int.len 1 prim <= [ xs ] [
    0 xs prim seq-int.at
    locals { pivot } {
      1 0 prim seq-int.empty prim seq-int.empty
      partition-loop
      locals { left right } {
        left sort-inner
        right sort-inner
        locals { sorted-left sorted-right } {
          sorted-left sorted-right prim seq-int.push
        }
      }
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  sort-inner;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: partition-loop
at: line 16, column 7
message: In the false branch of the `if` in `partition-loop` whose true branch is `[ low high low prim seq-int.push ]`, `partition-loop` (inside a quotation in that branch) needs 6 values (i:Int, j:Int, pivot:Int, low:Seq Int, high:Seq Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `partition-loop`, exactly the values it takes, in this order: i:Int, j:Int, pivot:Int, low:Seq Int, high:Seq Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 4 in their places, for example by writing the locals that hold them. If `partition-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: sort-inner
at: line 21, column 3
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
  (forall ρ; ρ i:Int^many balance:Int^many rejected:Int^many txs:Seq Int^many -- ρ result:Int^many)
  locals { i balance rejected txs } {
    i txs prim seq-int.len prim >= [ balance rejected ] [
      i txs prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim < [
          i 1 prim +
          balance
          rejected 1 prim +
          ledger-loop
        ] [
          i 1 prim +
          balance tx prim +
          rejected
          ledger-loop
        ] if
      }
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 start 0
  ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 19, column 7
message: In the false branch of the `if` in `ledger-loop` whose true branch is `[ balance rejected ]`, `ledger-loop` (inside a quotation in that branch) needs 4 values (i:Int, balance:Int, rejected:Int, txs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, `balance` or the result of `prim +` and the result of `prim +` or `rejected`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: i:Int, balance:Int, rejected:Int, txs:Seq Int. The branch already pushes the result of `prim +`, `balance` or the result of `prim +` and the result of `prim +` or `rejected`, in the place of the first 3 (i:Int, balance:Int, rejected:Int): keep each where it has that type and replace it where it does not. Then push the last one (txs:Seq Int) after them, for example by writing the locals that hold it. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 24, column 5
message: `start` is not a defined word, primitive or local.
actual: start
hint: `start` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ j:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock2:Seq Int^many allocated2:Seq Int^many reasons2:Seq Int^many)
  locals { j stock items qtys whole allocated reasons } {
    j qtys prim seq-int.len prim >= [
      stock allocated reasons
    ] [
      j items prim seq-int.at
      locals { item } {
        item stock prim seq-int.at
        locals { curr-stock } {
          j qtys prim seq-int.at
          locals { qty } {
            qty curr-stock prim <= [
              qty stock item qty prim seq-int.set
              j 1 prim +
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
              allocate-loop
            ] [
              curr-stock 0 prim = [
                j 1 prim +
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                allocate-loop
              ] [
                j whole prim seq-bool.at [
                  j 1 prim +
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  allocate-loop
                ] [
                  curr-stock stock item 0 prim seq-int.set
                  j 1 prim +
                  allocated curr-stock prim seq-int.push
                  reasons 1 prim seq-int.push
                  allocate-loop
                ] if
              ] if
            ] if
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock2:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  0 prim seq-int.empty prim seq-int.empty
  allocate-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 39, column 19
message: In the true branch `[ j 1 prim + stock allocated 0 ...` of the `if` in `allocate-loop`, `allocate-loop` needs 7 values (j:Int, stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, allocated:Seq Int, reasons:Seq Int), but the branch has pushed only 4 values before it (the result of `prim +`, `stock`, the result of `prim seq-int.push` and the result of `prim seq-int.push`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `allocate-loop`, exactly the values it takes, in this order: j:Int, stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, allocated:Seq Int, reasons:Seq Int. The branch already pushes the result of `prim +`, `stock`, the result of `prim seq-int.push` and the result of `prim seq-int.push`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `allocate-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 51, column 3
message: `allocate-loop` in `main` takes j:Int, stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), `0` (Int), the result of `prim seq-int.empty` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
hint: The third value from the top, `0` (Int), is not what `allocate-loop` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
