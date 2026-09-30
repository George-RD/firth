Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 xs prim seq-int.len loop-sum };

: loop-sum
  (forall ρ; ρ xs:Seq Int^many acc:Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs acc idx len } {
    idx len prim < [
      idx xs prim seq-int.at locals { val xs acc idx len } {
        acc val prim + locals { xs acc idx len newacc } {
          xs newacc idx 1 prim + xs prim seq-int.len loop-sum
        }
      }
    ] [ acc ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-sum
at: line 14, column 15
message: In the true branch `[ idx xs prim seq-int.at locals { val ...` of the `if` in `loop-sum`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs prim seq-int.len find-max xs };

: find-max
  (forall ρ; ρ max:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max idx len xs } {
    idx len prim < [
      idx xs prim seq-int.at locals { val max idx len xs } {
        max val prim < [ val ] [ max ] if
        locals { max idx len xs } { idx 1 prim + find-max xs }
      }
    ] [ max ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 62
message: `find-max` in `main` takes 4 values (max:Int, idx:Int, len:Int, xs:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: the result of `prim seq-int.at` (Int), `1` (Int) and the result of `prim seq-int.len` (Int). `main` calls `find-max`, which has an error of its own; this report assumes `find-max` keeps its stack effect.
hint: The values `find-max` takes are pushed before it, and `xs` is written after it. Write `xs find-max` in place of `find-max xs` on line 3. With that edit `main` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: find-max
at: line 13, column 15
message: In the true branch `[ idx xs prim seq-int.at locals { val ...` of the `if` in `find-max`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs 0 0 xs prim seq-int.len count-below-loop xs k };

: count-below-loop
  (forall ρ; ρ xs:Seq Int^many count:Int^many idx:Int^many len:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs count idx len k } {
    idx len prim < [
      idx xs prim seq-int.at locals { val xs count idx len k } {
        val k prim < [ count 1 prim + ] [ count ] if
        locals { xs count idx len k } { xs count idx 1 prim + len count-below-loop xs k }
      }
    ] [ count ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 48
message: `count-below-loop` in `main` takes 5 values (xs:Seq Int, count:Int, idx:Int, len:Int, k:Int), bottom to top, but only 4 values are on the stack before it, bottom to top: `xs` (Seq Int), `0` (Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `count-below-loop`, which has an error of its own; this report assumes `count-below-loop` keeps its stack effect.
hint: Push the missing value before `count-below-loop`. The locals here, `xs` and `k`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.branch-mismatch
word: count-below-loop
at: line 13, column 17
message: In the true branch `[ idx xs prim seq-int.at locals { val ...` of the `if` in `count-below-loop`, `locals` needs 6 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs 0 xs prim seq-int.len find-index xs x };

: find-index
  (forall ρ; ρ xs:Seq Int^many idx:Int^many len:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs idx len x } {
    idx len prim < [
      idx xs prim seq-int.at locals { val xs idx len x } {
        val x prim = [ idx ] [ xs idx 1 prim + len find-index xs x ] if
      }
    ] [ -1 ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 46
message: `find-index` in `main` takes 4 values (xs:Seq Int, idx:Int, len:Int, x:Int), bottom to top, but only 3 values are on the stack before it, bottom to top: `xs` (Seq Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `find-index`, which has an error of its own; this report assumes `find-index` keeps its stack effect.
hint: Push the missing value before `find-index`. The locals here, `xs` and `x`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.branch-mismatch
word: find-index
at: line 10, column 70
message: In the false branch of the `if` in `find-index` whose true branch is `[ idx ]`, `find-index` needs 4 values (xs:Seq Int, idx:Int, len:Int, x:Int), but the branch has pushed only 3 values before it (`xs`, the result of `prim +` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-index`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, len:Int, x:Int. The branch already pushes `xs`, the result of `prim +` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-index` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop xs };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx } {
    idx 0 prim < [ result ] [
      idx xs prim seq-int.at locals { val result xs idx } {
        result val prim seq-int.push
        locals { result xs idx } { result xs idx 1 prim - reverse-loop xs }
      }
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int. `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 13, column 7
message: In the false branch of the `if` in `reverse-loop` whose true branch is `[ result ]`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop xs };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum idx len xs } {
    idx len prim < [
      idx xs prim seq-int.at locals { val result sum idx len xs } {
        sum val prim + locals { result sum idx len xs newsum } {
          result newsum prim seq-int.push
          locals { result sum idx len xs } { result newsum idx 1 prim + len prefix-loop xs }
        }
      }
    ] [ result ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 62
message: `prefix-loop` in `main` takes 5 values (result:Seq Int, sum:Int, idx:Int, len:Int, xs:Seq Int), bottom to top, but only 4 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int), `0` (Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
hint: The values `prefix-loop` takes are pushed before it, and `xs` is written after it. Write `xs prefix-loop` in place of `prefix-loop xs` on line 3. With that edit `main` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: prefix-loop
at: line 15, column 18
message: In the true branch `[ idx xs prim seq-int.at locals { val ...` of the `if` in `prefix-loop`, `locals` needs 6 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len keep-pos-loop xs };

: keep-pos-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx len xs } {
    idx len prim < [
      idx xs prim seq-int.at locals { val result idx len xs } {
        val 0 prim < [ result ] [ result val prim seq-int.push ] if
        locals { result idx len xs } { result idx 1 prim + len keep-pos-loop xs }
      }
    ] [ result ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 60
message: `keep-pos-loop` in `main` takes 4 values (result:Seq Int, idx:Int, len:Int, xs:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `keep-pos-loop`, which has an error of its own; this report assumes `keep-pos-loop` keeps its stack effect.
hint: The values `keep-pos-loop` takes are pushed before it, and `xs` is written after it. Write `xs keep-pos-loop` in place of `keep-pos-loop xs` on line 3. With that edit `main` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: keep-pos-loop
at: line 13, column 18
message: In the true branch `[ idx xs prim seq-int.at locals { val ...` of the `if` in `keep-pos-loop`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len xs } {
    len 1 prim < [ true ] [ 0 check-sorted xs ] if
  } };

: check-sorted
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { idx xs } {
    idx xs prim seq-int.len 1 prim - prim < [
      idx xs prim seq-int.at locals { val idx xs } {
        idx 1 prim + xs prim seq-int.at locals { next idx xs } {
          val next prim < [ idx 1 prim + check-sorted xs ] [ false ] if
        }
      }
    ] [ true ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 4, column 49
message: `if` needs more values than the stack holds here. `main` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 2 of 2
code: firth.type.branch-mismatch
word: check-sorted
at: line 16, column 16
message: The two branches of `if` in `check-sorted` leave different numbers of values: the true branch takes 5 values from the stack below the `if` and leaves 2 values, and the false branch pushes 1 value. The true branch takes 5 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs prim seq-int.len dot-product xs ys };

: dot-product
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs ys } {
    idx len prim < [
      idx xs prim seq-int.at idx ys prim seq-int.at prim * locals { prod sum idx len xs ys } {
        sum prod prim + locals { sum idx len xs ys } { sum idx 1 prim + len dot-product xs ys }
      }
    ] [ sum ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 46
message: `dot-product` in `main` takes 5 values (sum:Int, idx:Int, len:Int, xs:Seq Int, ys:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: `0` (Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `dot-product`, which has an error of its own; this report assumes `dot-product` keeps its stack effect.
hint: The values `dot-product` takes are pushed before it, and `xs` and `ys` are written after it. Write `xs ys dot-product` in place of `dot-product xs ys` on line 3. With that edit `main` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: dot-product
at: line 12, column 15
message: In the true branch `[ idx xs prim seq-int.at idx ys prim ...` of the `if` in `dot-product`, `locals` needs 6 values, but the branch has pushed only 1 value before it (the result of `prim *`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-bool.len locals { len flags } {
    len 0 prim = [ true ] [ 0 check-all flags ] if
  } };

: check-all
  (forall ρ; ρ idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { idx flags } {
    idx flags prim seq-bool.len prim < [
      idx flags prim seq-bool.at [ idx 1 prim + check-all flags ] [ false ] if
    ] [ true ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 4, column 49
message: `if` needs more values than the stack holds here. `main` calls `check-all`, which has an error of its own; this report assumes `check-all` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: check-all
at: line 11, column 17
message: `prim seq-bool.at` in `check-all` takes the sequence (Seq Bool) and the index (Int), bottom to top, but here it gets, bottom to top, `idx` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int Seq Bool
hint: These are the values `prim seq-bool.at` takes, in another order. To push them in its order, write `flags idx` in place of `idx flags` on line 11. With that edit, the next error in `check-all` is at line 11, column 49.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len xs } {
    len 0 prim = [ 0 ] [ 0 xs prim seq-int.at 1 0 find-longest xs ] if
  } };

: find-longest
  (forall ρ; ρ idx:Int^many prev:Int^many current:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx prev current max xs } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at locals { val idx prev current max xs } {
        val prev prim = [
          current 1 prim + locals { current idx prev max xs } {
            current max prim < [ max ] [ current ] if
            locals { max idx prev current xs } { idx 1 prim + find-longest xs }
          }
        ] [
          idx 1 prim + find-longest xs
        ] if
      }
    ] [ max ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 4, column 69
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `main` calls `find-longest`, which has an error of its own; this report assumes `find-longest` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: find-longest
at: line 19, column 11
message: In the true branch `[ current 1 prim + locals { current ...` of the `if` in `find-longest`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len check-pair xs target };

: check-pair
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target } {
    i len prim < [
      i 1 prim + check-pair-inner xs target i
    ] [ false ] if
  };

: check-pair-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { j xs target i } {
    j xs prim seq-int.len prim < [
      i j prim = [ j 1 prim + check-pair-inner xs target i ] [
        i xs prim seq-int.at j xs prim seq-int.at prim + locals { sum xs target i j } {
          sum target prim = [ true ] [ j 1 prim + check-pair-inner xs target i ] if
        }
      ] if
    ] [ false ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 48
message: `check-pair` in `main` takes 4 values (i:Int, len:Int, xs:Seq Int, target:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `check-pair`, which has an error of its own; this report assumes `check-pair` keeps its stack effect.
hint: The values `check-pair` takes are pushed before it, and `xs` and `target` are written after it. Write `xs target check-pair` in place of `check-pair xs target` on line 3. With that edit `main` checks.

error 2 of 3
code: firth.type.stack-underflow
word: check-pair
at: line 10, column 17
message: `if` needs more values than the stack holds here. `check-pair` calls `check-pair-inner`, which has an error of its own; this report assumes `check-pair-inner` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 3 of 3
code: firth.type.branch-mismatch
word: check-pair-inner
at: line 21, column 9
message: The two branches of `if` in `check-pair-inner` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 4 values, and the false branch takes 7 values from the stack below the `if` and leaves 4 values. The false branch takes 7 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len count-distinct-loop xs };

: count-distinct-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx len xs } {
    idx len prim < [
      idx xs prim seq-int.at locals { val count idx len xs } {
        val 0 idx check-contains xs [ count ] [ count 1 prim + ] if
        locals { count idx len xs } { count idx 1 prim + len count-distinct-loop xs }
      }
    ] [ count ] if
  };

: check-contains
  (forall ρ; ρ val:Int^many start:Int^many end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val start end xs } {
    start end prim < [
      start xs prim seq-int.at locals { x val start end xs } {
        x val prim = [ true ] [ val start 1 prim + end check-contains xs ] if
      }
    ] [ false ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 43
message: `count-distinct-loop` in `main` takes 4 values (count:Int, idx:Int, len:Int, xs:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: `0` (Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
hint: The values `count-distinct-loop` takes are pushed before it, and `xs` is written after it. Write `xs count-distinct-loop` in place of `count-distinct-loop xs` on line 3. With that edit `main` checks.

error 2 of 3
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 13, column 17
message: In the true branch `[ idx xs prim seq-int.at locals { val ...` of the `if` in `count-distinct-loop`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: check-contains
at: line 23, column 17
message: The two branches of `if` in `check-contains` leave different numbers of values: the true branch takes 5 values from the stack below the `if` and leaves 2 values, and the false branch pushes 1 value. The condition and the values the branches take from below the `if` are looked for where the local `val` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge-sorted-loop xs ys };

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xlen ylen xs ys } {
    i xlen prim < [
      j ylen prim < [
        i xs prim seq-int.at j ys prim seq-int.at locals { xi yj result i j xlen ylen xs ys } {
          xi yj prim < [
            result xi prim seq-int.push locals { result i j xlen ylen xs ys } { result i 1 prim + j xlen ylen merge-sorted-loop xs ys }
          ] [
            result yj prim seq-int.push locals { result i j xlen ylen xs ys } { result i j 1 prim + xlen ylen merge-sorted-loop xs ys }
          ] if
        }
      ] [
        i xs prim seq-int.at locals { xi result i j xlen ylen xs ys } {
          result xi prim seq-int.push locals { result i j xlen ylen xs ys } { result i 1 prim + j xlen ylen merge-sorted-loop xs ys }
        }
      ] if
    ] [
      j ylen prim < [
        j ys prim seq-int.at locals { yj result i j xlen ylen xs ys } {
          result yj prim seq-int.push locals { result i j xlen ylen xs ys } { result i j 1 prim + xlen ylen merge-sorted-loop xs ys }
        }
      ] [ result ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 85
message: `merge-sorted-loop` in `main` takes 7 values (result:Seq Int, i:Int, j:Int, xlen:Int, ylen:Int, xs:Seq Int, ys:Seq Int), bottom to top, but only 5 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int), `0` (Int), `0` (Int), the result of `prim seq-int.len` (Int) and the result of `prim seq-int.len` (Int). `main` calls `merge-sorted-loop`, which has an error of its own; this report assumes `merge-sorted-loop` keeps its stack effect.
hint: The values `merge-sorted-loop` takes are pushed before it, and `xs` and `ys` are written after it. Write `xs ys merge-sorted-loop` in place of `merge-sorted-loop xs ys` on line 3. With that edit `main` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: merge-sorted-loop
at: line 27, column 20
message: In the true branch `[ j ys prim seq-int.at locals { yj ...` of the `if` in `merge-sorted-loop`, `locals` needs 8 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 7 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [
    n 0 prim < [ n 0 prim - extract-digits ] [ n extract-digits ]
  ] if };

: extract-digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { prim seq-int.empty n build-digits n };

: build-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    n 0 prim = [ result ] [
      n 10 prim mod locals { d result n } {
        result d prim seq-int.push locals { result n } { result n 10 prim div build-digits }
      }
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: main
at: line 5, column 5
message: The two branches of the `if` in `main` whose true branch is `[ { 0 } ]` leave different numbers of values. The true branch leaves `a literal`; the false branch leaves 3 values, bottom to top: the result of `prim <`, the quotation `[ n 0 prim - extract-digits ]` and the quotation `[ n extract-digits ]`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim <` and the quotation `[ n 0 prim - extract-digits ]` are left below the quotation `[ n extract-digits ]`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.declared-effect-mismatch
word: extract-digits
at: line 8, column 3
message: `extract-digits` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Int. `extract-digits` calls `build-digits`, which has an error of its own; this report assumes `build-digits` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Seq Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 3 of 3
code: firth.type.branch-mismatch
word: build-digits
at: line 18, column 7
message: In the false branch of the `if` in `build-digits` whose true branch is `[ result ]`, `locals` needs 3 values, but the branch has pushed only 1 value before it (the result of `prim mod`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n find-primes };

: find-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { result candidate limit } {
    candidate limit prim < [
      candidate is-prime [ result candidate prim seq-int.push ] [ result ] if
      locals { result candidate limit } { result candidate 1 prim + limit find-primes }
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } { n 2 prim < [ false ] [
    n 2 prim = [ true ] [
      n 2 prim mod 0 prim = [ false ] [ 2 check-divisors n ] if
    ] if
  ] if };

: check-divisors
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ result:Bool^many)
  locals { divisor n } {
    divisor divisor prim * n prim < [
      n divisor prim mod 0 prim = [ false ] [ divisor 1 prim + check-divisors n ] if
    ] [ true ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: find-primes
at: line 11, column 18
message: In the true branch `[ candidate is-prime [ result candidate prim seq-int.push ...` of the `if` in `find-primes`, `locals` needs 3 values, but the branch has pushed only 1 value before it (the result of an `if`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `find-primes` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: is-prime
at: line 18, column 62
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `check-divisors` needs 2 values (divisor:Int, n:Int), but the branch has pushed only 1 value before it (`2`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `is-prime` calls `check-divisors`, which has an error of its own; this report assumes `check-divisors` keeps its stack effect.
expected: .. Int Bool
actual: .. Bool Int
hint: Make the branch push, just before `check-divisors`, exactly the values it takes, in this order: divisor:Int, n:Int. The branch already pushes `2`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `check-divisors` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: check-divisors
at: line 26, column 83
message: In the false branch of the `if` in `check-divisors` whose true branch is `[ false ]`, `check-divisors` needs 2 values (divisor:Int, n:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
expected: .. Int Bool
actual: .. Bool Int
hint: Make the branch push, just before `check-divisors`, exactly the values it takes, in this order: divisor:Int, n:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `check-divisors` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k build-histogram xs k };

: build-histogram
  (forall ρ; ρ counts:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { counts idx k xs } {
    idx k prim < [
      counts 0 prim seq-int.push locals { counts idx k xs } { counts idx 1 prim + k build-histogram xs k }
    ] [
      0 xs prim seq-int.len count-histogram xs k counts
    ] if
  };

: count-histogram
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i len xs k counts } {
    i len prim < [
      i xs prim seq-int.at locals { val i len xs k counts } {
        val counts prim seq-int.at 1 prim + locals { newcnt i len xs k counts } {
          counts val newcnt prim seq-int.set locals { counts i len xs k } { counts i 1 prim + len count-histogram xs k counts }
        }
      }
    ] [ counts ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 44
message: `build-histogram` in `main` takes 4 values (counts:Seq Int, idx:Int, k:Int, xs:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `k` (Int). `main` calls `build-histogram`, which has an error of its own; this report assumes `build-histogram` keeps its stack effect.
hint: Push the missing value before `build-histogram`. The locals here, `xs` and `k`, are not values on the stack: writing a local's name pushes its value.

error 2 of 3
code: firth.type.branch-mismatch
word: build-histogram
at: line 12, column 7
message: In the true branch `[ counts 0 prim seq-int.push locals { counts ...` of the `if` in `build-histogram`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.push`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: count-histogram
at: line 24, column 18
message: In the true branch `[ i xs prim seq-int.at locals { val ...` of the `if` in `count-histogram`, `locals` needs 6 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len 1 prim - insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many start:Int^many end:Int^many -- ρ sorted:Seq Int^many)
  locals { xs start end } {
    start end prim < [
      start 1 prim + locals { i xs start end } {
        xs i insert-element
        locals { xs start end } { xs start 1 prim + end insertion-sort }
      }
    ] [ xs ] if
  };

: insert-element
  (forall ρ; ρ xs:Seq Int^many pos:Int^many -- ρ xs:Seq Int^many)
  locals { xs pos } {
    pos 0 prim > [
      pos xs prim seq-int.at locals { val xs pos } {
        pos 1 prim - xs prim seq-int.at locals { prev xs pos } {
          prev val prim < [
            xs pos
          ] [
            xs pos prev prim seq-int.set locals { xs pos } { xs pos 1 prim - insert-element }
          ] if
        }
      }
    ] [ xs ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insertion-sort
at: line 13, column 14
message: In the true branch `[ start 1 prim + locals { i ...` of the `if` in `insertion-sort`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved-effect
word: insert-element
at: line 19, column 11
message: `prim >` in `insert-element` is not a primitive: numbers are compared with `prim <` and `prim =`.
hint: `a b prim >`, `a` greater than `b`, is `a b swap prim <`: `a` is greater than `b` exactly when `b < a`. Write `swap prim <` in place of `prim >` on line 19. With that edit, the next error in `insert-element` is at line 26, column 13.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs prim seq-int.len process-txs txs };

: process-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected idx len txs } {
    idx len prim < [
      idx txs prim seq-int.at locals { tx balance rejected idx len txs } {
        balance tx prim + 0 prim < [
          rejected 1 prim + locals { rejected idx len txs balance } { balance rejected idx 1 prim + len process-txs txs }
        ] [
          balance tx prim + locals { balance idx len txs rejected } { balance rejected idx 1 prim + len process-txs txs }
        ] if
      }
    ] [ balance rejected ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 57
message: `process-txs` in `main` takes 5 values (balance:Int, rejected:Int, idx:Int, len:Int, txs:Seq Int), bottom to top, but only 4 values are on the stack before it, bottom to top: `start` (Int), `0` (Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `process-txs`, which has an error of its own; this report assumes `process-txs` keeps its stack effect.
hint: The values `process-txs` takes are pushed before it, and `txs` is written after it. Write `txs process-txs` in place of `process-txs txs` on line 3. With that edit `main` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: process-txs
at: line 16, column 28
message: In the true branch `[ idx txs prim seq-int.at locals { tx ...` of the `if` in `process-txs`, `locals` needs 6 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len process-orders stock items qtys whole };

: process-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons idx len items qtys whole } {
    idx len prim < [
      idx items prim seq-int.at locals { item stock allocated reasons idx len items qtys whole } {
        item stock prim seq-int.at locals { qty_stock stock allocated reasons idx len items qtys whole } {
          idx qtys prim seq-int.at locals { req stock allocated reasons idx len items qtys whole } {
            idx whole prim seq-bool.at locals { w stock allocated reasons idx len items qtys whole } {
              req qty_stock prim < [
                qty_stock 0 prim = [
                  reasons 2 prim seq-int.push allocated 0 prim seq-int.push locals { stock allocated reasons idx len items qtys whole } { stock allocated reasons idx 1 prim + len process-orders stock items qtys whole }
                ] [
                  w [ reasons 3 prim seq-int.push allocated 0 prim seq-int.push ] [ reasons 1 prim seq-int.push allocated qty_stock prim seq-int.push stock item 0 prim seq-int.set ] if
                  locals { stock allocated reasons idx len items qtys whole } { stock allocated reasons idx 1 prim + len process-orders stock items qtys whole }
                ] if
              ] [
                reasons 0 prim seq-int.push allocated req prim seq-int.push stock item qty_stock req prim - prim seq-int.set
                locals { stock allocated reasons idx len items qtys whole } { stock allocated reasons idx 1 prim + len process-orders stock items qtys whole }
              ] if
            }
          }
        }
      }
    ] [ stock allocated reasons ] if
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 48
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
