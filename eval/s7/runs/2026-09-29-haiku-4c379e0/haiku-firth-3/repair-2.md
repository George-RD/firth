Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim < [
      acc i xs prim seq-int.at prim +
      i 1 prim +
      sum-loop
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the true branch `[ acc i xs prim seq-int.at prim + ...` of the `if` in `sum-loop`, `sum-loop` needs 3 values (xs:Seq Int, i:Int, acc:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, acc:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, acc:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-max:Int^many -- ρ result:Int^many)
  locals { xs i current-max } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at current-max prim < [
        i xs prim seq-int.at
      ] [
        current-max
      ] if
      i 1 prim +
      max-loop
    ] [
      current-max
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 1 xs 0 xs prim seq-int.at max-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 7
message: In the true branch `[ i xs prim seq-int.at current-max prim < ...` of the `if` in `max-loop`, `max-loop` needs 3 values (xs:Seq Int, i:Int, current-max:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current-max:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (i:Int, current-max:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at k prim < [
        count 1 prim +
      ] [
        count
      ] if
      i 1 prim +
      count-loop
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 7
message: In the true branch `[ i xs prim seq-int.at k prim < ...` of the `if` in `count-loop`, `count-loop` needs 4 values (xs:Seq Int, k:Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, count:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at x prim = [
        i
      ] [
        i 1 prim +
        index-loop
      ] if
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 9
message: In the false branch of the `if` in `index-loop` whose true branch is `[ i ]`, `index-loop` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `index-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `index-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i 0 prim < [
      result i xs prim seq-int.at prim seq-int.push
      i 1 prim -
      reverse-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the true branch `[ result i xs prim seq-int.at prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim < [
      sum i xs prim seq-int.at prim +
      result swap prim seq-int.push
      i 1 prim +
      prefix-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 11, column 7
message: In the true branch `[ sum i xs prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at locals { val } {
        val 0 prim < [
          result
        ] [
          result val prim seq-int.push
        ] if
      }
      i 1 prim +
      keep-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 7
message: In the true branch `[ i xs prim seq-int.at locals { val ...` of the `if` in `keep-loop`, `keep-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `keep-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `keep-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len 1 prim - prim < [
      i xs prim seq-int.at
      i 1 prim + xs prim seq-int.at prim <
      [
        i 1 prim +
        sorted-loop
      ] [
        i xs prim seq-int.at
        i 1 prim + xs prim seq-int.at prim =
        [
          i 1 prim +
          sorted-loop
        ] [
          false
        ] if
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      xs 0 sorted-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 18, column 11
message: In the true branch `[ i 1 prim + sorted-loop ]` of the `if` in `sorted-loop`, `sorted-loop` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim < [
      sum i xs prim seq-int.at i ys prim seq-int.at prim * prim +
      i 1 prim +
      dot-loop
    ] [
      sum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the true branch `[ sum i xs prim seq-int.at i ys ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, sum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i flags prim seq-bool.len prim < [
      i flags prim seq-bool.at [
        i 1 prim +
        all-loop
      ] [
        false
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-bool.len 0 prim = [
      true
    ] [
      flags 0 all-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 9
message: In the true branch `[ i 1 prim + all-loop ]` of the `if` in `all-loop`, `all-loop` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { xs i current-val current-len max-len } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at locals { val } {
        val current-val prim = [
          current-len 1 prim +
          current-len 1 prim + max-len prim < [
            max-len
          ] [
            current-len 1 prim +
          ] if
          i 1 prim +
          run-helper
        ] [
          current-len max-len prim < [
            max-len
          ] [
            current-len
          ] if
          locals { new-max } {
            val 1 i 1 prim + new-max run-helper
          }
        ] if
      }
    ] [
      current-len max-len prim < [
        max-len
      ] [
        current-len
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 1 xs prim seq-int.at 1 0 run-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 24, column 11
message: In the true branch `[ current-len 1 prim + current-len 1 prim ...` of the `if` in `run-helper`, `run-helper` needs 5 values (xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current-val:Int, current-len:Int, max-len:Int. The branch already pushes the result of `prim +`, the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim < [
      i j prim = [
        j 1 prim +
        inner-loop
      ] [
        i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [
          true
        ] [
          j 1 prim +
          inner-loop
        ] if
      ] if
    ] [
      false
    ] if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs target i 0 inner-loop [
        true
      ] [
        i 1 prim +
        outer-loop
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 outer-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 11
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ true ]`, `inner-loop` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-seen
  (forall ρ; ρ xs:Seq Int^many val:Int^many i:Int^many -- ρ seen:Bool^many)
  locals { xs val i } {
    i val prim < [
      i xs prim seq-int.at val prim = [
        true
      ] [
        i 1 prim +
        check-seen
      ] if
    ] [
      false
    ] if
  };

: count-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim < [
      xs i xs prim seq-int.at 0 check-seen [
        count
      ] [
        count 1 prim +
      ] if
      i 1 prim +
      count-helper
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 count-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 9
message: In the false branch of the `if` in `check-seen` whose true branch is `[ true ]`, `check-seen` needs 3 values (xs:Seq Int, val:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-seen`, exactly the values it takes, in this order: xs:Seq Int, val:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-seen` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
        i xs prim seq-int.at j ys prim seq-int.at prim < [
          result i xs prim seq-int.at prim seq-int.push
          i 1 prim +
          merge-loop
        ] [
          result j ys prim seq-int.at prim seq-int.push
          j 1 prim +
          merge-loop
        ] if
      ] [
        result i xs prim seq-int.at prim seq-int.push
        i 1 prim +
        merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        result j ys prim seq-int.at prim seq-int.push
        j 1 prim +
        merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 27, column 9
message: In the true branch `[ result j ys prim seq-int.at prim seq-int.push ...` of the `if` in `merge-loop`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      result n 10 prim mod prim seq-int.push
      n 10 prim div result digits-loop
    ] if
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many output:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result i output } {
    i 0 prim < [
      output i result prim seq-int.at prim seq-int.push
      i 1 prim -
      reverse-loop
    ] [
      output
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty digits-loop
      locals { result } {
        result result prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 9, column 7
message: The two branches of the `if` in `digits-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `digits-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `digits-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-divisible
  (forall ρ; ρ n:Int^many d:Int^many -- ρ divisible:Bool^many)
  locals { n d } {
    n d prim mod 0 prim =
  };

: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim < [
      n d is-divisible [
        false
      ] [
        d 1 prim +
        is-prime-check
      ] if
    ] [
      true
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [
      false
    ] [
      n 2 is-prime-check
    ] if
  };

: primes-loop
  (forall ρ; ρ limit:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { limit n result } {
    n limit prim < [
      n is-prime [
        result n prim seq-int.push
        n 1 prim +
        primes-loop
      ] [
        n 1 prim +
        primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim < [
      prim seq-int.empty
    ] [
      n 2 prim seq-int.empty primes-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 9
message: In the false branch of the `if` in `is-prime-check` whose true branch is `[ false ]`, `is-prime-check` needs 2 values (n:Int, d:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime-check`, exactly the values it takes, in this order: n:Int, d:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i result } {
    i k prim < [
      result 0 prim seq-int.push
      i 1 prim +
      init-counts
    ] [
      result
    ] if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs i counts } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at locals { val } {
        counts val prim seq-int.at 1 prim +
        val counts prim seq-int.set
        i 1 prim +
        histogram-loop
      }
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-counts
    xs 0 histogram-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the true branch `[ result 0 prim seq-int.push i 1 prim ...` of the `if` in `init-counts`, `init-counts` needs 3 values (k:Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-counts`, exactly the values it takes, in this order: k:Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `init-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result val i } {
    i result prim seq-int.len prim < [
      i result prim seq-int.at val prim < [
        result val i prim seq-int.set
        i 1 prim +
        insert-loop
      ] [
        i 1 prim +
        insert-loop
      ] if
    ] [
      result val prim seq-int.push
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      i xs prim seq-int.at result 0 insert-loop
      i 1 prim +
      sort-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 9
message: In the true branch `[ result val i prim seq-int.set i 1 ...` of the `if` in `insert-loop`, `insert-loop` needs 3 values (result:Seq Int, val:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-loop`, exactly the values it takes, in this order: result:Seq Int, val:Int, i:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `insert-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim < [
      balance i txs prim seq-int.at prim + 0 prim < [
        rejected 1 prim +
        i 1 prim +
        ledger-loop
      ] [
        balance i txs prim seq-int.at prim +
        i 1 prim +
        ledger-loop
      ] if
    ] [
      rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 7
message: In the true branch `[ balance i txs prim seq-int.at prim + ...` of the `if` in `ledger-loop`, `ledger-loop` (inside a quotation in that branch) needs 4 values (balance:Int, txs:Seq Int, i:Int, rejected:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: balance:Int, txs:Seq Int, i:Int, rejected:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order:Int^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole order alloc reasons } {
    order items prim seq-int.len prim < [
      order items prim seq-int.at locals { item-idx } {
        order qtys prim seq-int.at locals { qty } {
          order whole prim seq-bool.at locals { whole-flag } {
            item-idx stock prim seq-int.at locals { avail } {
              qty avail prim < [
                alloc qty prim seq-int.push
                reasons 0 prim seq-int.push
                stock item-idx avail qty prim - prim seq-int.set
              ] [
                avail 0 prim = [
                  alloc 0 prim seq-int.push
                  reasons 2 prim seq-int.push
                ] [
                  whole-flag [
                    alloc 0 prim seq-int.push
                    reasons 3 prim seq-int.push
                  ] [
                    alloc avail prim seq-int.push
                    reasons 1 prim seq-int.push
                    stock item-idx 0 prim seq-int.set
                  ] if
                ] if
              ] if
              order 1 prim +
              allocate-loop
            }
          }
        }
      }
    ] [
      reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 25, column 21
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ alloc 0 prim seq-int.push reasons 3 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim seq-int.set`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `prim seq-int.push` and the result of `prim seq-int.set`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
