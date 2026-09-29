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
  locals { xs } { 0 0 xs sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { acc i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at acc prim + locals { new-acc } { new-acc i 1 prim + seq sum-loop } ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sum-loop
at: line 9, column 13
message: `prim seq-int.at` in `sum-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `seq` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `seq i` in place of `i seq`. With that edit `sum-loop` checks.

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
    xs prim seq-int.len 1 prim <=
    [ 0 xs prim seq-int.at ]
    [ 0 xs prim seq-int.at xs max-loop ]
    if
  };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { max i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val max prim <
        [ max i 1 prim + max-loop ]
        [ val i 1 prim + max-loop ]
        if
      }
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 33
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
        [ count 1 prim + i 1 prim + count-below-loop ]
        [ count i 1 prim + count-below-loop ]
        if
      }
    ]
    [ count ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-below-loop
at: line 17, column 5
message: In the true branch `[ i seq prim seq-int.at locals { val ...` of the `if` in `count-below-loop`, `count-below-loop` (inside a quotation in that branch) needs 4 values (count:Int, i:Int, seq:Seq Int, k:Int), but the branch has pushed only 2 values before it (the result of `prim +` or `count` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-below-loop`, exactly the values it takes, in this order: count:Int, i:Int, seq:Seq Int, k:Int. The branch already pushes the result of `prim +` or `count` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-below-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
        [ i 1 prim + index-of-loop ]
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
message: In the false branch of the `if` in `index-of-loop` whose true branch is `[ i ]`, `index-of-loop` needs 3 values (i:Int, seq:Seq Int, target:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `index-of-loop`, exactly the values it takes, in this order: i:Int, seq:Seq Int, target:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `index-of-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i 0 prim <
    [ 
      i prim - locals { idx } {
        idx seq prim seq-int.at locals { val } {
          result val prim seq-int.push seq i prim - reverse-loop
        }
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 19, column 5
message: In the true branch `[ i prim - locals { idx } ...` of the `if` in `reverse-loop`, `prim -` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim -`, exactly the values it takes, in this order: Int, Int. The branch already pushes `i`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim -` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
        result new-sum prim seq-int.push new-sum i 1 prim + seq prefix-sums-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-sums-loop
at: line 11, column 13
message: `prim seq-int.at` in `prefix-sums-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `seq` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `seq i` in place of `i seq`. With that edit `prefix-sums-loop` checks.

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
        [ result i 1 prim + keep-positive-loop ]
        [ val result prim seq-int.push i 1 prim + keep-positive-loop ]
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
message: In the true branch `[ i seq prim seq-int.at locals { val ...` of the `if` in `keep-positive-loop`, `keep-positive-loop` (inside a quotation in that branch) needs 3 values (result:Seq Int, i:Int, seq:Seq Int), but the branch has pushed only 2 values before it (`result` or the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `keep-positive-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, seq:Seq Int. The branch already pushes `result` or the result of `prim seq-int.push` and the result of `prim +`, in the place of the first 2 (result:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (seq:Seq Int) after them, for example by writing the locals that hold it. If `keep-positive-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i seq prim seq-int.len 1 prim - prim <
    [ i seq prim seq-int.at i 1 prim + seq prim seq-int.at prim <= 
      [ i 1 prim + is-sorted-loop ] 
      [ false ] 
      if
    ]
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
    [ i xs prim seq-int.at i ys prim seq-int.at prim * sum prim + 
      locals { new-sum } { new-sum i 1 prim + xs ys dot-loop } 
    ]
    [ sum ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: dot-loop
at: line 11, column 12
message: `prim seq-int.at` in `dot-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `dot-loop` is at line 11, column 33.

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
    [ i seq prim seq-bool.at 
      [ i 1 prim + all-true-loop ] 
      [ false ] 
      if 
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-true-loop
at: line 14, column 7
message: In the true branch `[ i 1 prim + all-true-loop ]` of the `if` in `all-true-loop`, `all-true-loop` needs 2 values (i:Int, seq:Seq Bool), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-true-loop`, exactly the values it takes, in this order: i:Int, seq:Seq Bool. The branch already pushes the result of `prim +`, in the place of the first one (i:Int): keep it where it has that type and replace it where it does not. Then push the last one (seq:Seq Bool) after it, for example by writing the locals that hold it. If `all-true-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 prim seq-int.at 1 1 0 xs longest-run-loop ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-run:Int^many prev-val:Int^many curr-run:Int^many curr-idx:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { max-run prev-val curr-run curr-idx seq } {
    curr-idx seq prim seq-int.len prim < [ 1 prim + ]
    [ curr-idx seq prim seq-int.at locals { val } {
        val prev-val prim =
        [ curr-run 1 prim + ]
        [ 1 ]
        if
        locals { new-run } {
          new-run max-run prim <
          [ new-run ]
          [ max-run ]
          if
          locals { updated-max } {
            val curr-idx 1 prim + new-run updated-max longest-run-loop
          }
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: longest-run-loop
at: line 14, column 20
message: `prim seq-int.at` in `longest-run-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `curr-idx` (Int) and `seq` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `seq curr-idx` in place of `curr-idx seq`. With that edit, the next error in `longest-run-loop` is at line 25, column 55.

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
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        i 1 prim + seq target val has-pair-sum-inner
      }
    ]
    [ false ]
    if
  };

: has-pair-sum-inner
  (forall ρ; ρ j:Int^many seq:Seq Int^many target:Int^many val:Int^many -- ρ result:Bool^many)
  locals { j seq target val } {
    j seq prim seq-int.len prim <
    [ j seq prim seq-int.at val prim + target prim =
      [ true ]
      [ j 1 prim + seq target val has-pair-sum-inner ]
      if
    ]
    [ val seq target has-pair-sum-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: has-pair-sum-loop
at: line 11, column 13
message: `prim seq-int.at` in `has-pair-sum-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `seq` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `seq i` in place of `i seq`. With that edit `has-pair-sum-loop` checks. That edit was checked assuming `has-pair-sum-inner`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: has-pair-sum-inner
at: line 23, column 13
message: `prim seq-int.at` in `has-pair-sum-inner` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `j` (Int) and `seq` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `seq j` in place of `j seq`. With that edit `has-pair-sum-inner` checks. That edit was checked assuming `has-pair-sum-loop`, which has an error of its own, keeps its stack effect.

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
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        0 seen val is-in-seq
        [ seen i 1 prim + count-distinct-loop ]
        [ seen val prim seq-int.push i 1 prim + count-distinct-loop ]
        if
      }
    ]
    [ seen prim seq-int.len ]
    if
  };

: is-in-seq
  (forall ρ; ρ j:Int^many seq:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j seq target } {
    j seq prim seq-int.len prim <
    [ j seq prim seq-int.at target prim =
      [ true ]
      [ j 1 prim + is-in-seq ]
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
at: line 19, column 5
message: In the true branch `[ i seq prim seq-int.at locals { val ...` of the `if` in `count-distinct-loop`, `count-distinct-loop` (inside a quotation in that branch) needs 3 values (seen:Seq Int, i:Int, seq:Seq Int), but the branch has pushed only 2 values before it (`seen` or the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-distinct-loop` calls `is-in-seq`, which has an error of its own; this report assumes `is-in-seq` keeps its stack effect.
hint: Make the branch push, just before `count-distinct-loop`, exactly the values it takes, in this order: seen:Seq Int, i:Int, seq:Seq Int. The branch already pushes `seen` or the result of `prim seq-int.push` and the result of `prim +`, in the place of the first 2 (seen:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (seq:Seq Int) after them, for example by writing the locals that hold it. If `count-distinct-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: is-in-seq
at: line 29, column 7
message: In the false branch of the `if` in `is-in-seq` whose true branch is `[ true ]`, `is-in-seq` needs 3 values (j:Int, seq:Seq Int, target:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-in-seq`, exactly the values it takes, in this order: j:Int, seq:Seq Int, target:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `is-in-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim <
      [ i xs prim seq-int.at j ys prim seq-int.at prim <
        [ result i xs prim seq-int.at prim seq-int.push i 1 prim + j merge-sorted-loop ]
        [ result j ys prim seq-int.at prim seq-int.push i j 1 prim + merge-sorted-loop ]
        if
      ]
      [ result i xs prim seq-int.at prim seq-int.push i 1 prim + j merge-sorted-loop ]
      if
    ]
    [ result j ys prim seq-int.len prim <
      [ result j ys prim seq-int.at prim seq-int.push i j 1 prim + merge-sorted-loop ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-sorted-loop
at: line 23, column 7
message: In the true branch `[ result j ys prim seq-int.at prim seq-int.push ...` of the `if` in `merge-sorted-loop`, `merge-sorted-loop` needs 5 values (result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `i` and the result of `prim +`). It would take `result` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-sorted-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int. The branch already pushes the result of `prim seq-int.push`, `i` and the result of `prim +`, in the place of the first 3 (result:Seq Int, i:Int, j:Int): keep each where it has that type and replace it where it does not. Then push the last 2 (xs:Seq Int, ys:Seq Int) after them, for example by writing the locals that hold them. If `merge-sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    n 0 prim =
    [ 0 prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many num:Int^many -- ρ result:Seq Int^many)
  locals { result num } {
    num 0 prim <
    [ num prim - ]
    [ num ]
    if
    locals { check-num } {
      check-num 0 prim <
      [ result ]
      [ check-num 10 prim mod locals { digit } {
          result digit prim seq-int.push check-num 10 prim div digits-loop
        }
      ]
      if
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 7, column 5
message: The two branches of the `if` in `main` whose true branch is `[ 0 prim seq-int.empty 0 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `0` and the result of `prim seq-int.push`; the false branch leaves the result of `digits-loop`. `main` calls `digits-loop`, which has an error of its own; this report assumes `digits-loop` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: `0` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: digits-loop
at: line 16, column 5
message: In the true branch `[ num prim - ]` of the `if` in `digits-loop`, `prim -` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`num`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim -`, exactly the values it takes, in this order: Int, Int. The branch already pushes `num`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim -` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    candidate limit prim <
    [ candidate primes is-prime-sieve
      [ primes candidate prim seq-int.push candidate 1 prim + sieve-loop ]
      [ candidate 1 prim + sieve-loop ]
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
    i primes prim seq-int.len prim <
    [ i primes prim seq-int.at locals { divisor } {
        divisor divisor prim * candidate prim <
        [ true ]
        [ candidate divisor prim mod 0 prim =
          [ false ]
          [ i 1 prim + test-divisors ]
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
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sieve-loop
at: line 14, column 7
message: In the true branch `[ primes candidate prim seq-int.push candidate 1 prim ...` of the `if` in `sieve-loop`, `sieve-loop` needs 3 values (primes:Seq Int, candidate:Int, limit:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sieve-loop`, exactly the values it takes, in this order: primes:Seq Int, candidate:Int, limit:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `sieve-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: test-divisors
at: line 36, column 11
message: In the false branch of the `if` in `test-divisors` whose true branch is `[ false ]`, `test-divisors` needs 3 values (i:Int, candidate:Int, primes:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `test-divisors`, exactly the values it takes, in this order: i:Int, candidate:Int, primes:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `test-divisors` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    0 k prim seq-int.empty init-histogram-counts xs histogram-loop
  };

: init-histogram-counts
  (forall ρ; ρ i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i k counts } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + init-histogram-counts ]
    [ counts ]
    if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at locals { val } {
        val counts prim seq-int.at 1 prim + counts val prim seq-int.set
        locals { new-counts } { i 1 prim + new-counts histogram-loop }
      }
    ]
    [ counts ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 4, column 53
message: `histogram-loop` in `main` needs Int Seq Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Seq Int. `main` calls `init-histogram-counts` and `histogram-loop`, which have errors of their own; this report assumes they keep their stack effects.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Seq Int
hint: `histogram-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.branch-mismatch
word: init-histogram-counts
at: line 13, column 5
message: In the true branch `[ counts 0 prim seq-int.push i 1 prim ...` of the `if` in `init-histogram-counts`, `init-histogram-counts` needs 3 values (i:Int, k:Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-histogram-counts`, exactly the values it takes, in this order: i:Int, k:Int, counts:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `init-histogram-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: histogram-loop
at: line 26, column 5
message: In the true branch `[ i xs prim seq-int.at locals { val ...` of the `if` in `histogram-loop`, `histogram-loop` needs 3 values (i:Int, xs:Seq Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `new-counts`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `histogram-loop`, exactly the values it takes, in this order: i:Int, xs:Seq Int, counts:Seq Int. The branch already pushes the result of `prim +` and `new-counts`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `histogram-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i arr prim seq-int.len prim <
    [ i arr prim seq-int.at locals { val } {
        arr val i insert-in-sorted i 1 prim + insertion-sort
      }
    ]
    [ arr ]
    if
  };

: insert-in-sorted
  (forall ρ; ρ arr:Seq Int^many val:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { arr val pos } {
    pos 0 prim <
    [ arr val pos prim seq-int.set ]
    [ pos 1 prim - arr prim seq-int.at locals { prev } {
        prev val prim <
        [ arr val pos prim seq-int.set ]
        [ arr prev pos prim seq-int.set pos 1 prim - insert-in-sorted ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: insertion-sort
at: line 11, column 13
message: `prim seq-int.at` in `insertion-sort` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `arr` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `arr i` in place of `i arr`. With that edit `insertion-sort` checks. That edit was checked assuming `insert-in-sorted`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.branch-mismatch
word: insert-in-sorted
at: line 28, column 9
message: In the false branch of the `if` in `insert-in-sorted` whose true branch is `[ arr val pos prim seq-int.set ]`, `insert-in-sorted` needs 3 values (arr:Seq Int, val:Int, pos:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-in-sorted`, exactly the values it takes, in this order: arr:Seq Int, val:Int, pos:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `insert-in-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i txs prim seq-int.len prim <
    [ i txs prim seq-int.at locals { tx } {
        balance tx prim + 0 prim <
        [ balance rejected 1 prim + i 1 prim + ledger-loop ]
        [ balance tx prim + rejected i 1 prim + ledger-loop ]
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
at: line 19, column 5
message: In the true branch `[ i txs prim seq-int.at locals { tx ...` of the `if` in `ledger-loop`, `ledger-loop` (inside a quotation in that branch) needs 4 values (balance:Int, rejected:Int, i:Int, txs:Seq Int), but the branch has pushed only 3 values before it (`balance` or the result of `prim +`, the result of `prim +` or `rejected` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: balance:Int, rejected:Int, i:Int, txs:Seq Int. The branch already pushes `balance` or the result of `prim +`, the result of `prim +` or `rejected` and the result of `prim +`, in the place of the first 3 (balance:Int, rejected:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (txs:Seq Int) after them, for example by writing the locals that hold it. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    order-idx items prim seq-int.len prim <
    [ order-idx items prim seq-int.at locals { item-idx } {
        item-idx stock prim seq-int.at locals { available } {
          order-idx qtys prim seq-int.at locals { requested } {
            requested available prim <
            [ available 0 prim =
              [ stock allocated reasons order-idx 1 prim + orig-stock items qtys whole allocate-loop-2 ]
              [ order-idx whole prim seq-bool.at
                [ stock allocated reasons order-idx 1 prim + orig-stock items qtys whole allocate-loop-2 ]
                [ stock available item-idx prim seq-int.set allocated available prim seq-int.push reasons 1 prim seq-int.push order-idx 1 prim + orig-stock allocate-loop ]
                if
              ]
              if
            ]
            [ stock requested item-idx prim seq-int.set allocated requested prim seq-int.push reasons 0 prim seq-int.push order-idx 1 prim + orig-stock allocate-loop ]
            if
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: allocate-loop-2
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order-idx:Int^many orig-stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons order-idx orig-stock items qtys whole } {
    allocated 0 prim seq-int.push reasons 2 prim seq-int.push order-idx 1 prim + orig-stock items qtys whole allocate-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.branch-mismatch
word: allocate-loop
at: line 20, column 17
message: In the false branch of the `if` in `allocate-loop` whose true branch is `[ stock allocated reasons order-idx 1 prim + ...`, `allocate-loop` needs 8 values (stock:Seq Int, allocated:Seq Int, reasons:Seq Int, order-idx:Int, orig-stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool), but the branch has pushed only 5 values before it (the result of `prim seq-int.set`, the result of `prim seq-int.push`, the result of `prim seq-int.push`, the result of `prim +` and `orig-stock`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `allocate-loop`, exactly the values it takes, in this order: stock:Seq Int, allocated:Seq Int, reasons:Seq Int, order-idx:Int, orig-stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool. The branch already pushes the result of `prim seq-int.set`, the result of `prim seq-int.push`, the result of `prim seq-int.push`, the result of `prim +` and `orig-stock`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `allocate-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.quotation-input-mismatch
word: allocate-loop-2
at: line 37, column 110
message: The quotation run by `dip` in `allocate-loop-2` does not accept the stack below it (ρ Seq Int Seq Int Int Seq Int Seq Int Seq Int Seq Bool Seq Int [ .. Seq Int Seq Int Seq Int Int Seq Int Seq Int Seq Int Seq Bool -- .. Seq Int Seq Int Seq Int ]). `allocate-loop-2` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.
