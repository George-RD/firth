Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many accum:Int^many index:Int^many -- ρ total:Int^many)
  locals { xs accum index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at accum prim + index 1 prim + sum-loop
    ] [
      accum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 8, column 7
message: In the true branch `[ xs index prim seq-int.at accum prim + ...` of the `if` in `sum-loop`, `sum-loop` needs 3 values (xs:Seq Int, accum:Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-loop`, exactly the values it takes, in this order: xs:Seq Int, accum:Int, index:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (accum:Int, index:Int). Push the first one (xs:Seq Int) before them by writing the local of that name, `xs`: write `xs xs index prim seq-int.at accum prim + index 1 prim + sum-loop` in place of `xs index prim seq-int.at accum prim + index 1 prim + sum-loop` on line 5. With that edit `sum-loop` checks. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many index:Int^many -- ρ largest:Int^many)
  locals { xs max index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      locals { current } {
        current max prim > [ current ] [ max ] if
      }
      index 1 prim + max-loop
    ] [
      max
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs xs 0 prim seq-int.at 1 max-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 12, column 7
message: In the true branch `[ xs index prim seq-int.at locals { current ...` of the `if` in `max-loop`, `max-loop` needs 3 values (xs:Seq Int, max:Int, index:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: xs:Seq Int, max:Int, index:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (max:Int, index:Int). Push the first one (xs:Seq Int) before them by writing the local of that name, `xs`: write `xs current max prim > [ current ] [ max ] if } index 1 prim + max-loop` in place of `current max prim > [ current ] [ max ] if } index 1 prim + max-loop` on line 7. With that edit `max-loop` checks. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many count:Int^many index:Int^many -- ρ count:Int^many)
  locals { xs k count index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at k prim < [ index 1 prim + count 1 prim + count-loop ] [ index 1 prim + count count-loop ] if
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 8, column 7
message: In the true branch `[ xs index prim seq-int.at k prim < ...` of the `if` in `count-loop`, `count-loop` (inside a quotation in that branch) needs 4 values (xs:Seq Int, k:Int, count:Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +` or `count`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, count:Int, index:Int. The branch already pushes the result of `prim +` and the result of `prim +` or `count`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many result:Int^many index:Int^many -- ρ index:Int^many)
  locals { xs x result index } {
    result 0 prim < prim not index xs prim seq-int.len prim < prim and [
      xs index prim seq-int.at x prim = [ index ] [ index 1 prim + result ] if index-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x -1 0 index-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: index-loop
at: line 5, column 77
message: The two branches of the `if` in `index-loop` whose true branch is `[ index ]` leave different numbers of values. The true branch leaves `index`; the false branch leaves 2 values, bottom to top: the result of `prim +` and `result`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below `result`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many index:Int^many -- ρ reversed:Seq Int^many)
  locals { xs result index } {
    index 0 prim >= [
      xs index prim seq-int.at result prim seq-int.push index 1 prim - reverse-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 8, column 7
message: In the true branch `[ xs index prim seq-int.at result prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, result:Seq Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, index:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many index:Int^many -- ρ sums:Seq Int^many)
  locals { xs result sum index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at sum prim +
      locals { new-sum } {
        result new-sum prim seq-int.push new-sum index 1 prim + prefix-loop
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 0 prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 11, column 7
message: In the true branch `[ xs index prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, result:Seq Int, sum:Int, index:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `new-sum` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, sum:Int, index:Int. The branch already pushes the result of `prim seq-int.push`, `new-sum` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many index:Int^many -- ρ positives:Seq Int^many)
  locals { xs result index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      locals { val } {
        val 0 prim > [ result val prim seq-int.push ] [ result ] if
      }
      index 1 prim + keep-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 keep-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: keep-loop
at: line 12, column 7
message: In the true branch `[ xs index prim seq-int.at locals { val ...` of the `if` in `keep-loop`, `keep-loop` needs 3 values (xs:Seq Int, result:Seq Int, index:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `keep-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, index:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `keep-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many sorted:Bool^many index:Int^many -- ρ sorted:Bool^many)
  locals { xs sorted index } {
    index xs prim seq-int.len 1 prim - prim < [
      xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim <=
      [ index 1 prim + sorted sorted-loop ] [ false ] if
    ] [
      sorted
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs true 0 sorted-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sorted-loop
at: line 6, column 55
message: In the true branch `[ index 1 prim + sorted sorted-loop ]` of the `if` in `sorted-loop`, `sorted-loop` needs 3 values (xs:Seq Int, sorted:Bool, index:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `sorted`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, sorted:Bool, index:Int. The branch already pushes, bottom to top, the result of `prim +` (from `index`) and `sorted`, which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `xs sorted index 1 prim + sorted-loop` in place of `index 1 prim + sorted sorted-loop` on line 6. With that edit `sorted-loop` checks. If `sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many product:Int^many index:Int^many -- ρ product:Int^many)
  locals { xs ys product index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at ys index prim seq-int.at prim * product prim + index 1 prim + dot-loop
    ] [
      product
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 8, column 7
message: In the true branch `[ xs index prim seq-int.at ys index prim ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, product:Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, product:Int, index:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (product:Int, index:Int). Push the first 2 (xs:Seq Int, ys:Seq Int) before them by writing the locals of those names, `xs` and `ys`: write `xs ys xs index prim seq-int.at ys index prim seq-int.at prim * product prim + index 1 prim + dot-loop` in place of `xs index prim seq-int.at ys index prim seq-int.at prim * product prim + index 1 prim + dot-loop` on line 5. With that edit `dot-loop` checks. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: true-loop
  (forall ρ; ρ flags:Seq Bool^many result:Bool^many index:Int^many -- ρ all:Bool^many)
  locals { flags result index } {
    index flags prim seq-bool.len prim < [
      flags index prim seq-bool.at result prim and index 1 prim + true-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags true 0 true-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: true-loop
at: line 8, column 7
message: In the true branch `[ flags index prim seq-bool.at result prim and ...` of the `if` in `true-loop`, `true-loop` needs 3 values (flags:Seq Bool, result:Bool, index:Int), but the branch has pushed only 2 values before it (the result of `prim and` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `true-loop`, exactly the values it takes, in this order: flags:Seq Bool, result:Bool, index:Int. The branch already pushes the result of `prim and` and the result of `prim +`, in the place of the last 2 (result:Bool, index:Int). Push the first one (flags:Seq Bool) before them by writing the local of that name, `flags`: write `flags flags index prim seq-bool.at result prim and index 1 prim + true-loop` in place of `flags index prim seq-bool.at result prim and index 1 prim + true-loop` on line 5. With that edit `true-loop` checks. If `true-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many curr-run:Int^many max-run:Int^many index:Int^many -- ρ length:Int^many)
  locals { xs prev curr-run max-run index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      locals { current } {
        current prev prim = [ curr-run 1 prim + ] [ 1 ] if
        locals { new-run } {
          new-run max-run prim > [ new-run ] [ max-run ] if
          locals { new-max } {
            current new-run index 1 prim + new-max run-loop
          }
        }
      }
    ] [
      max-run
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim > [
      xs xs 0 prim seq-int.at 1 1 1 run-loop
    ] [ 0 ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 17, column 7
message: In the true branch `[ xs index prim seq-int.at locals { current ...` of the `if` in `run-loop`, `run-loop` needs 5 values (xs:Seq Int, prev:Int, curr-run:Int, max-run:Int, index:Int), but the branch has pushed only 4 values before it (`current`, `new-run`, the result of `prim +` and `new-max`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, prev:Int, curr-run:Int, max-run:Int, index:Int. The branch already pushes `current`, `new-run`, the result of `prim +` and `new-max`, in the place of the last 4 (prev:Int, curr-run:Int, max-run:Int, index:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many inner-idx:Int^many -- ρ found:Int^many)
  locals { xs target inner-idx } {
    inner-idx xs prim seq-int.len prim < [
      xs inner-idx prim seq-int.at xs inner-idx 1 prim + prim seq-int.at prim + target prim =
      [ xs prim seq-int.len ] [ inner-idx 1 prim + inner-loop ] if
    ] [
      xs prim seq-int.len
    ] if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many index:Int^many -- ρ found:Bool^many)
  locals { xs target found index } {
    found prim not index xs prim seq-int.len prim < prim and [
      0 inner-loop drop swap outer-loop
    ] [
      found
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target false 0 outer-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: inner-loop
at: line 6, column 65
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ xs prim seq-int.len ]`, `inner-loop` needs 3 values (xs:Seq Int, target:Int, inner-idx:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, inner-idx:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: outer-loop
at: line 19, column 7
message: In the true branch `[ 0 inner-loop drop swap outer-loop ]` of the `if` in `outer-loop`, `inner-loop` needs 3 values (xs:Seq Int, target:Int, inner-idx:Int), but the branch has pushed only 1 value before it (`0`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, inner-idx:Int. The branch already pushes `0`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: seen-loop
  (forall ρ; ρ seen:Seq Int^many val:Int^many idx:Int^many -- ρ found:Int^many)
  locals { seen val idx } {
    idx seen prim seq-int.len prim < [
      seen idx prim seq-int.at val prim = [ seen prim seq-int.len ] [ idx 1 prim + seen-loop ] if
    ] [
      seen prim seq-int.len
    ] if
  };

: main-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many index:Int^many -- ρ seen:Seq Int^many)
  locals { xs seen index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      locals { val } {
        0 seen-loop drop
        locals { found } {
          found seen prim seq-int.len prim = [ seen val prim seq-int.push ] [ seen ] if
        }
      }
      index 1 prim + main-loop
    ] [
      seen
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 main-loop prim seq-int.len
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: seen-loop
at: line 5, column 96
message: In the false branch of the `if` in `seen-loop` whose true branch is `[ seen prim seq-int.len ]`, `seen-loop` needs 3 values (seen:Seq Int, val:Int, idx:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `seen-loop`, exactly the values it takes, in this order: seen:Seq Int, val:Int, idx:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `seen-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main-loop
at: line 25, column 7
message: In the true branch `[ xs index prim seq-int.at locals { val ...` of the `if` in `main-loop`, `seen-loop` needs 3 values (seen:Seq Int, val:Int, idx:Int), but the branch has pushed only 1 value before it (`0`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `main-loop` calls `seen-loop`, which has an error of its own; this report assumes `seen-loop` keeps its stack effect.
hint: Make the branch push, just before `seen-loop`, exactly the values it takes, in this order: seen:Seq Int, val:Int, idx:Int. The branch already pushes `0`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `seen-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many xi:Int^many yi:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys result xi yi } {
    xi xs prim seq-int.len prim < yi ys prim seq-int.len prim < prim and [
      xs xi prim seq-int.at ys yi prim seq-int.at prim <=
      [
        result xs xi prim seq-int.at prim seq-int.push xi 1 prim + yi merge-loop
      ]
      [
        result ys yi prim seq-int.at prim seq-int.push xi yi 1 prim + merge-loop
      ]
      if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys prim seq-int.empty 0 0 merge-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 15, column 7
message: In the true branch `[ xs xi prim seq-int.at ys yi prim ...` of the `if` in `merge-loop`, `merge-loop` (inside a quotation in that branch) needs 5 values (xs:Seq Int, ys:Seq Int, result:Seq Int, xi:Int, yi:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` or `xi` and `yi` or the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, result:Seq Int, xi:Int, yi:Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` or `xi` and `yi` or the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: extract-loop
  (forall ρ; ρ acc:Seq Int^many index:Int^many -- ρ reversed:Seq Int^many)
  locals { acc index } {
    index 0 prim >= [
      acc index prim seq-int.at prim seq-int.push index 1 prim - extract-loop
    ] [
      acc
    ] if
  };

: digit-loop
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { acc n } {
    n 0 prim > [
      acc n 10 prim mod prim seq-int.push n 10 prim div digit-loop
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      prim seq-int.empty n digit-loop
      locals { result } {
        prim seq-int.empty result prim seq-int.len 1 prim - extract-loop
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: extract-loop
at: line 8, column 7
message: In the true branch `[ acc index prim seq-int.at prim seq-int.push index ...` of the `if` in `extract-loop`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes the result of `prim seq-int.at`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { n divisor } {
    divisor divisor prim * n prim <= [
      n divisor prim mod 0 prim = [ false ] [ divisor 1 prim + is-prime ] if
    ] [
      true
    ] if
  };

: prime-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result n } {
    n n prim <= [
      n 2 is-prime [ result n prim seq-int.push ] [ result ] if
      n 1 prim + prime-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 prime-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-prime
at: line 5, column 75
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `is-prime` needs 2 values (n:Int, divisor:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime`, exactly the values it takes, in this order: n:Int, divisor:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ counts:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { counts k } {
    k prim seq-int.len k prim < [
      counts 0 prim seq-int.push k 1 prim + init-counts
    ] [
      counts
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many index:Int^many -- ρ counts:Seq Int^many)
  locals { xs counts index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at
      locals { v } {
        counts v prim seq-int.at 1 prim + v counts prim seq-int.set
      }
      index 1 prim + count-loop
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 [ dup k prim < [ swap 0 prim seq-int.push swap 1 prim + call ] [] if ]
    call drop
    locals { counts } {
      xs counts 0 count-loop
    }
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: init-counts
at: line 4, column 7
message: `prim seq-int.len` in `init-counts` takes Seq Int, bottom to top, but here it gets, bottom to top, `k` (Int).
expected: .. Seq Int
actual: ρ Seq Int Int Int
hint: The top value, `k` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: count-loop
at: line 22, column 7
message: In the true branch `[ xs index prim seq-int.at locals { v ...` of the `if` in `count-loop`, `count-loop` needs 3 values (xs:Seq Int, counts:Seq Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, counts:Seq Int, index:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.elaboration.untracked-local
word: main
at: line 31, column 7
message: The local `xs` is used after `call` on line 28 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubble-inner
  (forall ρ; ρ xs:Seq Int^many j:Int^many -- ρ xs:Seq Int^many)
  locals { xs j } {
    j 0 prim > [
      xs j prim seq-int.at xs j 1 prim + prim seq-int.at prim >
      [
        xs j prim seq-int.at xs j 1 prim + prim seq-int.at
        xs j 1 prim + prim seq-int.at xs j prim seq-int.set
        locals { temp } { xs j temp prim seq-int.set }
        j 1 prim - bubble-inner
      ]
      [
        xs
      ]
      if
    ] [
      xs
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many pass:Int^many -- ρ xs:Seq Int^many)
  locals { xs pass } {
    pass xs prim seq-int.len 1 prim - prim < [
      xs pass bubble-inner pass 1 prim + sort-loop
    ] [
      xs
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 sort-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: bubble-inner
at: line 15, column 7
message: The two branches of the `if` in `bubble-inner` whose true branch is `[ xs j prim seq-int.at xs j 1 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `bubble-inner`; the false branch leaves `xs`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and the result of `prim seq-int.at` are left below the result of `bubble-inner`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many index:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs balance rejected index } {
    index txs prim seq-int.len prim < [
      txs index prim seq-int.at
      locals { tx } {
        balance tx prim +
        locals { new-balance } {
          new-balance 0 prim < [ new-balance rejected 1 prim + ] [ new-balance rejected ] if
        }
      }
      index 1 prim + ledger-loop
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs start 0 0 ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 15, column 7
message: In the true branch `[ txs index prim seq-int.at locals { tx ...` of the `if` in `ledger-loop`, `ledger-loop` needs 4 values (txs:Seq Int, balance:Int, rejected:Int, index:Int), but the branch has pushed only 3 values before it (`new-balance`, the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: txs:Seq Int, balance:Int, rejected:Int, index:Int. The branch already pushes `new-balance`, the result of an `if` and the result of `prim +`, in the place of the last 3 (balance:Int, rejected:Int, index:Int): keep each where it has that type and replace it where it does not. Then push the first one (txs:Seq Int) before them, for example by writing the locals that hold it. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty prim seq-int.empty prim seq-int.empty
  };

```
On the example, it returned [[], [], []] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
