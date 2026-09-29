Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-iter
  (forall ρ; ρ xs:Seq Int^many idx:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs idx sum } {
    idx xs prim seq-int.len prim < 
    [ xs idx prim seq-int.at sum prim + idx 1 prim + sum-iter ] 
    [ sum ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 7, column 5
message: In the true branch `[ xs idx prim seq-int.at sum prim + ...` of the `if` in `sum-iter`, `sum-iter` needs 3 values (xs:Seq Int, idx:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-iter`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, sum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (idx:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sum-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-iter
  (forall ρ; ρ xs:Seq Int^many idx:Int^many current-max:Int^many -- ρ result:Int^many)
  locals { xs idx current-max } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at 
      current-max 
      prim < 
      [ xs idx prim seq-int.at idx 1 prim + max-iter ] 
      [ current-max idx 1 prim + max-iter ] 
      if 
    ] 
    [ current-max ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 5
message: In the true branch `[ xs idx prim seq-int.at current-max prim < ...` of the `if` in `max-iter`, `max-iter` (inside a quotation in that branch) needs 3 values (xs:Seq Int, idx:Int, current-max:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` or `current-max` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-iter`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, current-max:Int. The branch already pushes the result of `prim seq-int.at` or `current-max` and the result of `prim +`, in the place of the last 2 (idx:Int, current-max:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-iter
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k idx count } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at k prim < 
      [ count 1 prim + idx 1 prim + count-iter ] 
      [ count idx 1 prim + count-iter ] 
      if 
    ] 
    [ count ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 5
message: In the true branch `[ xs idx prim seq-int.at k prim < ...` of the `if` in `count-iter`, `count-iter` (inside a quotation in that branch) needs 4 values (xs:Seq Int, k:Int, idx:Int, count:Int), but the branch has pushed only 2 values before it (the result of `prim +` or `count` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-iter`, exactly the values it takes, in this order: xs:Seq Int, k:Int, idx:Int, count:Int. The branch already pushes the result of `prim +` or `count` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-iter
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many result:Int^many -- ρ answer:Int^many)
  locals { xs x idx result } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at x prim = 
      [ idx ] 
      [ idx 1 prim + find-iter ] 
      if 
    ] 
    [ result ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 -1 find-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 9, column 7
message: In the false branch of the `if` in `find-iter` whose true branch is `[ idx ]`, `find-iter` needs 4 values (xs:Seq Int, x:Int, idx:Int, result:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-iter`, exactly the values it takes, in this order: xs:Seq Int, x:Int, idx:Int, result:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `find-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: rev-iter
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ answer:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim < 
    [ result ] 
    [ xs idx prim seq-int.at result prim seq-int.push idx 1 prim - rev-iter ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty rev-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 7, column 5
message: In the false branch of the `if` in `rev-iter` whose true branch is `[ result ]`, `rev-iter` needs 3 values (xs:Seq Int, idx:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `rev-iter`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, idx:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `rev-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-iter
  (forall ρ; ρ xs:Seq Int^many idx:Int^many sum:Int^many result:Seq Int^many -- ρ answer:Seq Int^many)
  locals { xs idx sum result } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at sum prim + 
      dup result prim seq-int.push 
      idx 1 prim + prefix-iter 
    ] 
    [ result ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 11, column 5
message: In the true branch `[ xs idx prim seq-int.at sum prim + ...` of the `if` in `prefix-iter`, `prefix-iter` needs 4 values (xs:Seq Int, idx:Int, sum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-iter`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: pos-iter
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ answer:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at 
      dup 0 prim < 
      [ drop idx 1 prim + pos-iter ] 
      [ result prim seq-int.push idx 1 prim + pos-iter ] 
      if 
    ] 
    [ result ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty pos-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the true branch `[ drop idx 1 prim + pos-iter ]` of the `if` in `pos-iter`, `pos-iter` needs 3 values (xs:Seq Int, idx:Int, result:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). Earlier in the branch, the result of `prim seq-int.at` was already taken from below the `if`. The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `pos-iter`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, result:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `pos-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim < 
    [ 
      xs idx prim seq-int.at 
      xs idx 1 prim + prim seq-int.at 
      prim < 
      [ idx 1 prim + check-sorted ] 
      [ false ] 
      if 
    ] 
    [ true ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 check-sorted };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 11, column 7
message: In the true branch `[ idx 1 prim + check-sorted ]` of the `if` in `check-sorted`, `check-sorted` needs 2 values (xs:Seq Int, idx:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-sorted`, exactly the values it takes, in this order: xs:Seq Int, idx:Int. The branch already pushes the result of `prim +`, in the place of the last one (idx:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `check-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-iter
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many idx:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys idx sum } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at 
      ys idx prim seq-int.at 
      prim * sum prim + 
      idx 1 prim + dot-iter 
    ] 
    [ sum ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 5
message: In the true branch `[ xs idx prim seq-int.at ys idx prim ...` of the `if` in `dot-iter`, `dot-iter` needs 4 values (xs:Seq Int, ys:Seq Int, idx:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-iter`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, idx:Int, sum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (idx:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ answer:Bool^many)
  locals { flags idx result } {
    idx flags prim seq-bool.len prim < 
    [ 
      flags idx prim seq-bool.at 
      result 
      prim and 
      idx 1 prim + check-all 
    ] 
    [ result ] 
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 true check-all };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 5
message: In the true branch `[ flags idx prim seq-bool.at result prim and ...` of the `if` in `check-all`, `check-all` needs 3 values (flags:Seq Bool, idx:Int, result:Bool), but the branch has pushed only 2 values before it (the result of `prim and` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all`, exactly the values it takes, in this order: flags:Seq Bool, idx:Int, result:Bool. The branch already pushes the result of `prim and` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `check-all` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-iter
  (forall ρ; ρ xs:Seq Int^many idx:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs idx current-run max-run } {
    idx xs prim seq-int.len 1 prim - prim < 
    [ 
      xs idx prim seq-int.at 
      xs idx 1 prim + prim seq-int.at 
      prim = 
      [ 
        current-run 1 prim + 
        [ max-run prim < [ current-run ] [ max-run ] if ] 
        compose call 
        idx 1 prim + run-iter 
      ] 
      [ 
        [ max-run prim < [ current-run ] [ max-run ] if ] 
        compose call 
        idx 1 prim + run-iter 
      ] 
      if 
    ] 
    [ [ max-run prim < [ current-run ] [ max-run ] if ] compose call ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 1 0 run-iter };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
at: line 13, column 9
message: The local `idx` is used after `call` on line 12 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair-iter
  (forall ρ; ρ xs:Seq Int^many target:Int^many idx:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target idx found } {
    found 
    [ true ] 
    [ 
      idx xs prim seq-int.len prim < 
      [ 
        xs idx prim seq-int.at 
        target swap prim - 
        0
        [ 
          dup xs prim seq-int.len prim < 
          [ 
            xs swap prim seq-int.at 
            prim = 
            [ true ] 
            [ drop 1 prim + ] 
            if 
          ] 
          [ drop ] 
          if 
        ] 
        compose call
        [ idx 1 prim + find-pair-iter ] 
        [ drop idx 1 prim + find-pair-iter ] 
        if 
      ] 
      [ false ] 
      if 
    ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 false find-pair-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 19, column 13
message: The two branches of `if` in `find-pair-iter` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-iter
  (forall ρ; ρ xs:Seq Int^many idx:Int^many seen:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx seen } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at 
      0
      [ 
        dup seen prim seq-int.len prim < 
        [ 
          seen swap prim seq-int.at 
          prim = 
          [ true ] 
          [ drop 1 prim + ] 
          if 
        ] 
        [ drop ] 
        if 
      ] 
      compose call
      [ idx 1 prim + distinct-iter ] 
      [ seen prim seq-int.push idx 1 prim + distinct-iter ] 
      if 
    ] 
    [ seen ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty distinct-iter prim seq-int.len };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 15, column 11
message: The two branches of `if` in `distinct-iter` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-iter
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many xi:Int^many yi:Int^many result:Seq Int^many -- ρ answer:Seq Int^many)
  locals { xs ys xi yi result } {
    xi xs prim seq-int.len prim < 
    [ 
      yi ys prim seq-int.len prim < 
      [ 
        xs xi prim seq-int.at 
        ys yi prim seq-int.at 
        prim < 
        [ 
          xs xi prim seq-int.at 
          result prim seq-int.push 
          xi 1 prim + merge-iter 
        ] 
        [ 
          ys yi prim seq-int.at 
          result prim seq-int.push 
          yi 1 prim + merge-iter 
        ] 
        if 
      ] 
      [ 
        xs xi prim seq-int.at 
        result prim seq-int.push 
        xi 1 prim + merge-iter 
      ] 
      if 
    ] 
    [ 
      yi ys prim seq-int.len prim < 
      [ 
        ys yi prim seq-int.at 
        result prim seq-int.push 
        yi 1 prim + merge-iter 
      ] 
      [ result ] 
      if 
    ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 38, column 7
message: In the true branch `[ ys yi prim seq-int.at result prim seq-int.push ...` of the `if` in `merge-iter`, `merge-iter` needs 5 values (xs:Seq Int, ys:Seq Int, xi:Int, yi:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-iter`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, xi:Int, yi:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `merge-iter` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-iter
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ answer:Seq Int^many)
  locals { n result } {
    n 0 prim = 
    [ result ] 
    [ 
      n 10 prim mod 
      result prim seq-int.push 
      n 10 prim div 
      digit-iter 
    ] 
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = 
    [ { 0 } ] 
    [ 
      n 0 prim < 
      [ 0 n prim - prim seq-int.empty digit-iter ] 
      [ n prim seq-int.empty digit-iter ] 
      if 
    ] 
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 8, column 14
message: `prim seq-int.push` in `digit-iter` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t19.
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: The top value is ?t19 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { n divisor } {
    divisor dup prim * n prim < 
    [ 
      n divisor prim mod 
      0 prim = 
      [ false ] 
      [ divisor 1 prim + is-prime ] 
      if 
    ] 
    [ true ] 
    if
  };

: prime-iter
  (forall ρ; ρ candidate:Int^many n:Int^many result:Seq Int^many -- ρ answer:Seq Int^many)
  locals { candidate n result } {
    candidate n prim < 
    [ 
      candidate 2 is-prime 
      [ 
        candidate result prim seq-int.push 
        candidate 1 prim + prime-iter 
      ] 
      [ 
        candidate 1 prim + prime-iter 
      ] 
      if 
    ] 
    [ result ] 
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { 2 n prim seq-int.empty prime-iter };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `is-prime` needs 2 values (n:Int, divisor:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime`, exactly the values it takes, in this order: n:Int, divisor:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: build-counts
  (forall ρ; ρ counts:Seq Int^many idx:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts idx k } {
    idx k prim < 
    [ 
      0 counts prim seq-int.push 
      idx 1 prim + build-counts 
    ] 
    [ counts ] 
    if
  };

: count-values
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { xs counts idx } {
    idx xs prim seq-int.len prim < 
    [ 
      xs idx prim seq-int.at 
      dup counts prim seq-int.at 
      1 prim + 
      counts swap prim seq-int.set 
      idx 1 prim + count-values 
    ] 
    [ counts ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 
    0 
    k build-counts 
    xs swap 0 count-values
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 5
message: In the true branch `[ 0 counts prim seq-int.push idx 1 prim ...` of the `if` in `build-counts`, `build-counts` needs 3 values (counts:Seq Int, idx:Int, k:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `build-counts`, exactly the values it takes, in this order: counts:Seq Int, idx:Int, k:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `build-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubble-pass
  (forall ρ; ρ arr:Seq Int^many idx:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { arr idx limit } {
    idx limit prim < 
    [ 
      arr idx prim seq-int.at 
      arr idx 1 prim + prim seq-int.at 
      prim < 
      [ 
        arr idx prim seq-int.at 
        arr idx 1 prim + prim seq-int.at 
        arr idx 1 prim + prim seq-int.set 
        arr swap prim seq-int.set 
        idx 1 prim + bubble-pass 
      ] 
      [ 
        arr 
        idx 1 prim + bubble-pass 
      ] 
      if 
    ] 
    [ arr ] 
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len bubble-pass };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 23, column 5
message: The two branches of `if` in `bubble-pass` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: apply-txn
  (forall ρ; ρ balance:Int^many idx:Int^many txs:Seq Int^many rejected:Int^many -- ρ final-bal:Int^many final-rej:Int^many)
  locals { balance idx txs rejected } {
    idx txs prim seq-int.len prim < 
    [ 
      balance txs idx prim seq-int.at prim + 
      dup 0 prim < 
      [ drop balance rejected 1 prim + idx 1 prim + apply-txn ] 
      [ idx 1 prim + apply-txn ] 
      if 
    ] 
    [ balance rejected ] 
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 apply-txn };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the true branch `[ drop balance rejected 1 prim + idx ...` of the `if` in `apply-txn`, `apply-txn` needs 4 values (balance:Int, idx:Int, txs:Seq Int, rejected:Int), but the branch has pushed only 3 values before it (`balance`, the result of `prim +` and the result of `prim +`). Earlier in the branch, the result of `prim +` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `apply-txn`, exactly the values it takes, in this order: balance:Int, idx:Int, txs:Seq Int, rejected:Int. The branch already pushes `balance`, the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `apply-txn` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole idx allocated reasons } {
    idx items prim seq-int.len prim < 
    [ 
      items idx prim seq-int.at 
      stock swap prim seq-int.at 
      qtys idx prim seq-int.at 
      whole idx prim seq-bool.at
      dup 0 prim = 
      [ 
        drop drop 2 
        allocated prim seq-int.push 
        reasons prim seq-int.push 
        idx 1 prim + allocate-order 
      ] 
      [ 
        dup prim <= 
        [ 
          drop 0 
          allocated prim seq-int.push 
          reasons prim seq-int.push 
          [ items idx prim seq-int.at ] 
          compose call 
          swap prim seq-int.set 
          idx 1 prim + allocate-order 
        ] 
        [ 
          [ 
            drop 3 
            allocated prim seq-int.push 
            reasons prim seq-int.push 
            idx 1 prim + allocate-order 
          ] 
          [ 
            drop 1 
            allocated prim seq-int.push 
            reasons prim seq-int.push 
            [ items idx prim seq-int.at ] 
            compose call 
            swap 0 swap prim seq-int.set 
            idx 1 prim + allocate-order 
          ] 
          if 
        ] 
        if 
      ] 
      if 
    ] 
    [ stock allocated reasons ] 
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-order };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 18, column 19
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
