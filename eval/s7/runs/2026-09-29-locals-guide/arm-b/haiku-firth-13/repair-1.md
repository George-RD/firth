Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 prim seq-int.empty xs sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many seq:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc seq i } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at acc prim + locals { new-acc } { new-acc seq i prim + sum-loop } ]
    [ acc ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 43
message: `sum-loop` in `main` takes acc:Int, seq:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `prim seq-int.empty` (Seq Int) and `xs` (Seq Int). `main` calls `sum-loop`, which has an error of its own; this report assumes `sum-loop` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Int Seq Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `sum-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: sum-loop
at: line 11, column 5
message: The two branches of `if` in `sum-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len prim > 0
    [ 0 xs prim seq-int.at xs max-loop ]
    [ xs prim seq-int.at ]
    if
  };

: max-loop
  (forall ρ; ρ max:Int^many seq:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max seq i } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        max val prim <
        [ val ]
        [ max ]
        if
        seq i prim + max-loop
      }
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved-effect
word: main
at: line 4, column 25
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

error 2 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 23, column 5
message: The two branches of `if` in `max-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { 0 0 xs k count-below-loop };

: count-below-loop
  (forall ρ; ρ count:Int^many i:Int^many seq:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i seq k } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val k prim <
        [ count prim + ]
        [ count ]
        if
        i prim + count-below-loop
      }
    ]
    [ count ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-below-loop
at: line 13, column 9
message: In the true branch `[ count prim + ]` of the `if` in `count-below-loop`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`count`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `count`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { 0 xs x index-of-loop };

: index-of-loop
  (forall ρ; ρ i:Int^many seq:Seq Int^many target:Int^many -- ρ result:Int^many)
  locals { i seq target } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val target prim =
        [ i ]
        [ i prim + index-of-loop ]
        if
      }
    ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: index-of-loop
at: line 13, column 9
message: In the false branch of the `if` in `index-of-loop` whose true branch is `[ i ]`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `i`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result seq i } {
    i prim < 0
    [ seq i prim + prim seq-int.at locals { val } {
        result val prim seq-int.push i prim - reverse-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 16, column 5
message: The two branches of `if` in `reverse-loop` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-sums-loop
  };

: prefix-sums-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many seq:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at sum prim + locals { new-sum } {
        result new-sum prim seq-int.push i prim + new-sum prefix-sums-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-sums-loop
at: line 16, column 5
message: The two branches of `if` in `prefix-sums-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs keep-positive-loop
  };

: keep-positive-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many seq:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val 0 prim <
        [ result i prim + val prim seq-int.push keep-positive-loop ]
        [ result i prim + keep-positive-loop ]
        if
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: keep-positive-loop
at: line 19, column 5
message: The two branches of `if` in `keep-positive-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <= [ true ] [ 0 xs is-sorted-loop ] if
  };

: is-sorted-loop
  (forall ρ; ρ i:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { i seq } {
    i seq prim seq-int.len prim + prim < 1
    [ i seq prim seq-int.at i prim + seq prim seq-int.at prim <= [ i prim + is-sorted-loop ] [ false ] if ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 33
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    0 0 xs ys dot-loop
  };

: dot-loop
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at i ys prim seq-int.at prim * sum prim + i prim + dot-loop ]
    [ sum ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 13, column 5
message: In the true branch `[ i xs prim seq-int.at i ys prim ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (sum:Int, i:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: sum:Int, i:Int, xs:Seq Int, ys:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } {
    0 flags all-true-loop
  };

: all-true-loop
  (forall ρ; ρ i:Int^many seq:Seq Bool^many -- ρ result:Bool^many)
  locals { i seq } {
    i seq prim seq-bool.len prim <
    [ i seq prim seq-bool.at [ i prim + all-true-loop ] [ false ] if ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-true-loop
at: line 11, column 67
message: In the true branch `[ i prim + all-true-loop ]` of the `if` in `all-true-loop`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `i`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [ 0 ] [
      0 xs prim seq-int.at 1 1 0 xs longest-run-loop
    ] if
  };

: longest-run-loop
  (forall ρ; ρ max-run:Int^many prev-val:Int^many curr-run:Int^many curr-idx:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { max-run prev-val curr-run curr-idx seq } {
    curr-idx seq prim seq-int.len prim < [ 1 prim + ]
    [ curr-idx seq prim seq-int.at locals { val } {
        val prev-val prim =
        [ curr-run prim + ]
        [ 1 ]
        if
        locals { new-run } {
          new-run max-run prim <
          [ max-run ]
          [ new-run ]
          if
          val curr-idx prim + new-run curr-idx prim + longest-run-loop
        }
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 5, column 12
message: `prim seq-int.at` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t6 Int ?t6
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs 0` in place of `0 xs`. With that edit `main` checks. That edit was checked assuming `longest-run-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.branch-mismatch
word: longest-run-loop
at: line 17, column 9
message: In the true branch `[ curr-run prim + ]` of the `if` in `longest-run-loop`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`curr-run`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `curr-run`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    0 xs target has-pair-sum-loop
  };

: has-pair-sum-loop
  (forall ρ; ρ i:Int^many seq:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i seq target } {
    i seq prim seq-int.len prim < [
      i seq prim seq-int.at locals { val } {
        i prim + seq target has-pair-sum-inner
      }
    ]
    [ false ]
    if
  };

: has-pair-sum-inner
  (forall ρ; ρ j:Int^many seq:Seq Int^many target:Int^many val:Int^many -- ρ result:Bool^many)
  locals { j seq target val } {
    j seq prim seq-int.len prim < [
      j seq prim seq-int.at val prim + target prim =
      [ true ]
      [ j prim + has-pair-sum-inner ]
      if
    ]
    [ val seq target has-pair-sum-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: has-pair-sum-loop
at: line 16, column 5
message: In the true branch `[ i seq prim seq-int.at locals { val ...` of the `if` in `has-pair-sum-loop`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `has-pair-sum-loop` calls `has-pair-sum-inner`, which has an error of its own; this report assumes `has-pair-sum-inner` keeps its stack effect.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `i`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: has-pair-sum-inner
at: line 26, column 7
message: In the false branch of the `if` in `has-pair-sum-inner` whose true branch is `[ true ]`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`j`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `j`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { seen i seq } {
    i seq prim seq-int.len prim < [
      i seq prim seq-int.at locals { val } {
        0 seen val is-in-seq
        [ seen i prim + val ]
        [ seen val prim seq-int.push ]
        if
        locals { new-seen } {
          i prim + new-seen count-distinct-loop
        }
      }
    ]
    [ seen prim seq-int.len ]
    if
  };

: is-in-seq
  (forall ρ; ρ j:Int^many seq:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j seq target } {
    j seq prim seq-int.len prim < [
      j seq prim seq-int.at target prim =
      [ true ]
      [ j prim + is-in-seq ]
      if
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 15, column 9
message: The two branches of the `if` in `count-distinct-loop` whose true branch is `[ seen i prim + val ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and `val`; the false branch leaves the result of `prim seq-int.push`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below `val`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: is-in-seq
at: line 32, column 7
message: In the false branch of the `if` in `is-in-seq` whose true branch is `[ true ]`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`j`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `j`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-sorted-loop
  };

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        i xs prim seq-int.at j ys prim seq-int.at prim <= [
          result i xs prim seq-int.at prim seq-int.push i prim + merge-sorted-loop
        ]
        [
          result j ys prim seq-int.at prim seq-int.push j prim + merge-sorted-loop
        ]
        if
      ]
      [
        i xs prim seq-int.len prim < [
          result i xs prim seq-int.at prim seq-int.push i prim + merge-sorted-loop
        ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim < [
        result j ys prim seq-int.at prim seq-int.push j prim + merge-sorted-loop
      ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 12, column 57
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim = [ 0 prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n digits-loop ] if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many num:Int^many -- ρ result:Seq Int^many)
  locals { result num } {
    num 0 prim > [
      num 10 prim mod locals { digit } {
        result digit prim seq-int.push num 10 prim div digits-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 4, column 98
message: The two branches of the `if` in `main` whose true branch is `[ 0 prim seq-int.empty 0 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `0` and the result of `prim seq-int.push`; the false branch leaves the result of `digits-loop`. `main` calls `digits-loop`, which has an error of its own; this report assumes `digits-loop` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: `0` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved-effect
word: digits-loop
at: line 10, column 11
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n sieve-loop
  };

: sieve-loop
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { primes candidate limit } {
    candidate limit prim <= [
      candidate primes is-prime-sieve [
        primes candidate prim seq-int.push candidate prim + sieve-loop
      ]
      [
        candidate prim + sieve-loop
      ]
      if
    ]
    [ primes ]
    if
  };

: is-prime-sieve
  (forall ρ; ρ candidate:Int^many primes:Seq Int^many -- ρ result:Bool^many)
  locals { candidate primes } {
    0 candidate primes test-divisors
  };

: test-divisors
  (forall ρ; ρ i:Int^many candidate:Int^many primes:Seq Int^many -- ρ result:Bool^many)
  locals { i candidate primes } {
    i primes prim seq-int.len prim < [
      i primes prim seq-int.at locals { divisor } {
        divisor divisor prim * candidate prim > [
          true
        ]
        [
          candidate divisor prim mod 0 prim = [
            false
          ]
          [
            i prim + test-divisors
          ]
          if
        ]
        if
      }
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 10, column 27
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    k prim seq-int.empty 0 prim seq-int.push 0 xs k init-histogram
  };

: init-histogram
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i xs k } {
    i k prim < [
      counts 0 prim seq-int.push i prim + init-histogram
    ]
    [ 0 xs counts histogram-loop ]
    if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at locals { val } {
        val counts prim seq-int.at prim + counts val prim seq-int.set i prim + histogram-loop
      }
    ]
    [ counts ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Int Seq Int. `main` calls `init-histogram`, which has an error of its own; this report assumes `init-histogram` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.branch-mismatch
word: init-histogram
at: line 14, column 5
message: The two branches of `if` in `init-histogram` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `init-histogram` calls `histogram-loop`, which has an error of its own; this report assumes `histogram-loop` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: histogram-loop
at: line 26, column 5
message: In the true branch `[ i xs prim seq-int.at locals { val ...` of the `if` in `histogram-loop`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes the result of `prim seq-int.at`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs 0 insertion-sort
  };

: insertion-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { arr i } {
    i arr prim seq-int.len prim < [
      i arr prim seq-int.at locals { val } {
        arr val i insert-in-sorted i prim + insertion-sort
      }
    ]
    [ arr ]
    if
  };

: insert-in-sorted
  (forall ρ; ρ arr:Seq Int^many val:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { arr val pos } {
    pos 0 prim > [
      pos prim - arr prim seq-int.at locals { prev } {
        prev val prim > [
          pos prim - arr prev prim seq-int.set pos insert-in-sorted
        ]
        [
          pos arr val prim seq-int.set
        ]
        if
      }
    ]
    [ 0 arr val prim seq-int.set ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insertion-sort
at: line 16, column 5
message: The two branches of `if` in `insertion-sort` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller. `insertion-sort` calls `insert-in-sorted`, which has an error of its own; this report assumes `insert-in-sorted` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved-effect
word: insert-in-sorted
at: line 22, column 11
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim < [
      i txs prim seq-int.at locals { tx } {
        balance tx prim + 0 prim < [
          balance rejected prim + i prim + ledger-loop
        ]
        [
          balance tx prim + rejected i prim + ledger-loop
        ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 18, column 9
message: In the true branch `[ balance rejected prim + i prim + ledger-loop ]` of the `if` in `ledger-loop`, `ledger-loop` needs 4 values (balance:Int, rejected:Int, i:Int, txs:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: balance:Int, rejected:Int, i:Int, txs:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 stock items qtys whole allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order-idx:Int^many orig-stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons order-idx orig-stock items qtys whole } {
    order-idx items prim seq-int.len prim < [
      order-idx items prim seq-int.at locals { item-idx } {
        item-idx stock prim seq-int.at locals { available } {
          order-idx qtys prim seq-int.at locals { requested } {
            requested available prim <= [
              stock requested item-idx prim seq-int.set
              allocated requested prim seq-int.push reasons 0 prim seq-int.push order-idx prim + allocate-loop
            ]
            [
              available 0 prim = [
                allocated 0 prim seq-int.push reasons 2 prim seq-int.push order-idx prim + allocate-loop
              ]
              [
                order-idx whole prim seq-bool.at [
                  allocated 0 prim seq-int.push reasons 3 prim seq-int.push order-idx prim + allocate-loop
                ]
                [
                  stock 0 item-idx prim seq-int.set
                  allocated available prim seq-int.push reasons 1 prim seq-int.push order-idx prim + allocate-loop
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
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 14, column 39
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
