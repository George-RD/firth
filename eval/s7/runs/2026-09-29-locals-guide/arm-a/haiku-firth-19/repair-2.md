Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many sum:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs sum index } {
    index xs prim seq-int.len prim =
    [ sum ]
    [ sum xs index prim seq-int.at prim + index 1 prim + sum-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 7, column 5
message: In the false branch of the `if` in `sum-loop` whose true branch is `[ sum ]`, `sum-loop` needs 3 values (xs:Seq Int, sum:Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-loop`, exactly the values it takes, in this order: xs:Seq Int, sum:Int, index:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (sum:Int, index:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs max index } {
    index xs prim seq-int.len prim =
    [ max ]
    [ xs index prim seq-int.at dup max prim < [ max ] [ drop ] if index 1 prim + max-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs xs 0 prim seq-int.at 1 max-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 6, column 64
message: The two branches of the `if` in `max-loop` whose true branch is `[ max ]` leave different numbers of values. The true branch leaves `max`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing.
hint: The true branch leaves 2 values more than the false branch. Make both branches take and leave the same values. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many count:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs k count index } {
    index xs prim seq-int.len prim =
    [ count ]
    [ xs index prim seq-int.at k prim < [ count 1 prim + ] [ count ] if index 1 prim + count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 7, column 5
message: In the false branch of the `if` in `count-loop` whose true branch is `[ count ]`, `count-loop` needs 4 values (xs:Seq Int, k:Int, count:Int, index:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, count:Int, index:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs x index } {
    index xs prim seq-int.len prim =
    [ -1 ]
    [ xs index prim seq-int.at x prim = [ index ] [ index 1 prim + find-loop ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 find-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 6, column 80
message: In the false branch of the `if` in `find-loop` whose true branch is `[ index ]`, `find-loop` needs 3 values (xs:Seq Int, x:Int, index:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, index:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    index xs prim seq-int.len prim =
    [ result ]
    [ xs index xs prim seq-int.len 1 prim - index prim - prim seq-int.at result prim seq-int.push index 1 prim + reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 reverse-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 6, column 58
message: `prim seq-int.at` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `index` (Int) and the result of `prim -` (Int).
expected: .. Seq Int Int
actual: .. Int ?t31 Seq Int Int Int
hint: The second value from the top, `index` (Int), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many sum:Int^many result:Seq Int^many index:Int^many -- ρ sums:Seq Int^many)
  locals { xs sum result index } {
    index xs prim seq-int.len prim =
    [ result ]
    [ sum xs index prim seq-int.at prim + dup result prim seq-int.push index 1 prim + prefix-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty 0 prefix-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 7, column 5
message: In the false branch of the `if` in `prefix-loop` whose true branch is `[ result ]`, `prefix-loop` needs 4 values (xs:Seq Int, sum:Int, result:Seq Int, index:Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, sum:Int, result:Seq Int, index:Int. The branch already pushes the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`, in the place of the last 3 (sum:Int, result:Seq Int, index:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many index:Int^many -- ρ positives:Seq Int^many)
  locals { xs result index } {
    index xs prim seq-int.len prim =
    [ result ]
    [ xs index prim seq-int.at dup 0 prim < [ drop result ] [ result prim seq-int.push ] if index 1 prim + filter-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 filter-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 7, column 5
message: In the false branch of the `if` in `filter-loop` whose true branch is `[ result ]`, `filter-loop` needs 3 values (xs:Seq Int, result:Seq Int, index:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, index:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `filter-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sort-check
  (forall ρ; ρ xs:Seq Int^many index:Int^many -- ρ sorted:Bool^many)
  locals { xs index } {
    index xs prim seq-int.len 1 prim - prim =
    [ true ]
    [ xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim < [ false ] [ index 1 prim + sort-check ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs xs prim seq-int.len [ 1 prim - sort-check ] [ true ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sort-check
at: line 6, column 113
message: In the false branch of the `if` in `sort-check` whose true branch is `[ false ]`, `sort-check` needs 2 values (xs:Seq Int, index:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sort-check`, exactly the values it takes, in this order: xs:Seq Int, index:Int. The branch already pushes the result of `prim +`, in the place of the last one (index:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `sort-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 12, column 75
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller. `main` calls `sort-check`, which has an error of its own; this report assumes `sort-check` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many index:Int^many -- ρ product:Int^many)
  locals { xs ys sum index } {
    index xs prim seq-int.len prim =
    [ sum ]
    [ xs index prim seq-int.at ys index prim seq-int.at prim * sum prim + index 1 prim + dot-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 7, column 5
message: In the false branch of the `if` in `dot-loop` whose true branch is `[ sum ]`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, sum:Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, sum:Int, index:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (sum:Int, index:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many index:Int^many -- ρ all:Bool^many)
  locals { flags index } {
    index flags prim seq-bool.len prim =
    [ true ]
    [ flags index prim seq-bool.at [ index 1 prim + all-loop ] [ false ] if ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-loop
at: line 6, column 74
message: In the true branch `[ index 1 prim + all-loop ]` of the `if` in `all-loop`, `all-loop` needs 2 values (flags:Seq Bool, index:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: flags:Seq Bool, index:Int. The branch already pushes the result of `prim +`, in the place of the last one (index:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-check
  (forall ρ; ρ xs:Seq Int^many current:Int^many max-run:Int^many index:Int^many -- ρ length:Int^many)
  locals { xs current max-run index } {
    index xs prim seq-int.len prim =
    [ max-run ]
    [ xs index prim seq-int.at xs index 1 prim - prim seq-int.at prim = [ current 1 prim + max-run prim < [ current 1 prim + ] [ max-run ] if index 1 prim + run-check ] [ 1 max-run prim < [ 1 ] [ max-run ] if index 1 prim + run-check ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs xs prim seq-int.len [ xs 1 0 1 run-check ] [ 0 ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-check
at: line 7, column 5
message: In the false branch of the `if` in `run-check` whose true branch is `[ max-run ]`, `run-check` (inside a quotation in that branch) needs 4 values (xs:Seq Int, current:Int, max-run:Int, index:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-check`, exactly the values it takes, in this order: xs:Seq Int, current:Int, max-run:Int, index:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `run-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.expected-bool
word: main
at: line 12, column 71
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ Seq Int Int [ .. -- .. Int ] [ .. -- .. Int ]. `main` calls `run-check`, which has an error of its own; this report assumes `run-check` keeps its stack effect.
expected: Bool
actual: Int
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim =
    [ false ]
    [ xs i prim seq-int.at target swap prim - xs swap prim seq-int.at prim = [ true ] [ i 1 prim + pair-loop ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pair-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-loop
at: line 6, column 112
message: In the false branch of the `if` in `pair-loop` whose true branch is `[ true ]`, `pair-loop` needs 3 values (xs:Seq Int, target:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `pair-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `pair-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many count:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs seen count index } {
    index xs prim seq-int.len prim =
    [ count ]
    [ xs index prim seq-int.at dup seen [ prim = ] [ [ false ] swap [] compose call ] if [ count 1 prim + seen prim seq-int.push ] [ seen ] if index 1 prim + distinct-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs prim seq-int.empty 0 0 distinct-loop };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: distinct-loop
at: line 6, column 90
message: The local `count` is used after `call` on line 6 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim = j ys prim seq-int.len prim = prim or
    [ result ]
    [ i xs prim seq-int.len prim = [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-loop ] [ j ys prim seq-int.len prim = [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-loop ] [ xs i prim seq-int.at ys j prim seq-int.at prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-loop ] [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-loop ] if ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-loop };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 3
message: `}` cannot start an item in a word's body.
actual: }
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    [ result prim seq-int.len 0 prim = [ result 0 prim seq-int.push ] [ result ] if ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digit-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n prim seq-int.empty digit-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 6, column 28
message: `prim seq-int.push` in `digit-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t34
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit, the next error in `digit-loop` is at line 6, column 60.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many test:Int^many -- ρ prime:Bool^many)
  locals { n test } {
    test test prim * n prim < [ false ] [ test 1 prim - n swap prim mod 0 prim = [ false ] [ test 1 prim - is-prime ] if ]
    if
  };

: prime-loop
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n current result } {
    current n prim <
    [ current 2 is-prime [ result current prim seq-int.push ] [ result ] if current 1 prim + prime-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty prime-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 4, column 119
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `is-prime` needs 2 values (n:Int, test:Int), but the branch has pushed only 1 value before it (the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime`, exactly the values it takes, in this order: n:Int, test:Int. The branch already pushes the result of `prim -`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: prime-loop
at: line 14, column 5
message: In the true branch `[ current 2 is-prime [ result current prim ...` of the `if` in `prime-loop`, `prime-loop` needs 3 values (n:Int, current:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `prime-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `prime-loop`, exactly the values it takes, in this order: n:Int, current:Int, result:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prime-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: hist-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many index:Int^many -- ρ counts:Seq Int^many)
  locals { xs result index } {
    index xs prim seq-int.len prim =
    [ result ]
    [ xs index prim seq-int.at dup result swap prim seq-int.at 1 prim + result swap prim seq-int.set index 1 prim + hist-loop ]
    if
  };

: init-counts
  (forall ρ; ρ k:Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { k result } {
    k 0 prim =
    [ result ]
    [ result 0 prim seq-int.push k 1 prim - init-counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { k prim seq-int.empty init-counts xs swap 0 hist-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: hist-loop
at: line 7, column 5
message: In the false branch of the `if` in `hist-loop` whose true branch is `[ result ]`, `hist-loop` needs 3 values (xs:Seq Int, result:Seq Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `hist-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, index:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `hist-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: init-counts
at: line 15, column 45
message: `init-counts` in `init-counts` takes k:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim -` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `init-counts` takes, in another order. To push them in its order, write `k 1 prim - result 0 prim seq-int.push` in place of `result 0 prim seq-int.push k 1 prim -`. With that edit `init-counts` checks.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubble-pass
  (forall ρ; ρ arr:Seq Int^many i:Int^many changed:Bool^many -- ρ result:Seq Int^many)
  locals { arr i changed } {
    i arr prim seq-int.len 1 prim - prim =
    [ arr changed [ arr ] [ arr ] if ]
    [ arr i prim seq-int.at arr i 1 prim + prim seq-int.at prim < [ arr i 1 prim + prim seq-int.at arr i prim seq-int.set arr i prim seq-int.at arr i 1 prim + prim seq-int.set i 1 prim + true bubble-pass ] [ i 1 prim + changed bubble-pass ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 false bubble-pass };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: bubble-pass
at: line 6, column 242
message: In the false branch of the `if` in `bubble-pass` whose true branch is `[ arr i 1 prim + prim seq-int.at ...`, `bubble-pass` needs 3 values (arr:Seq Int, i:Int, changed:Bool), but the branch has pushed only 2 values before it (the result of `prim +` and `changed`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `bubble-pass`, exactly the values it takes, in this order: arr:Seq Int, i:Int, changed:Bool. The branch already pushes the result of `prim +` and `changed`, in the place of the last 2 (i:Int, changed:Bool): keep each where it has that type and replace it where it does not. Then push the first one (arr:Seq Int) before them, for example by writing the locals that hold it. If `bubble-pass` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many index:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { txs balance rejected index } {
    index txs prim seq-int.len prim =
    [ balance rejected ]
    [ txs index prim seq-int.at dup balance prim + dup 0 prim < [ drop drop rejected 1 prim + index 1 prim + ledger-loop ] [ swap drop index 1 prim + ledger-loop ] if ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs start 0 0 ledger-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 7, column 5
message: In the false branch of the `if` in `ledger-loop` whose true branch is `[ balance rejected ]`, `ledger-loop` (inside a quotation in that branch) needs 4 values (txs:Seq Int, balance:Int, rejected:Int, index:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: txs:Seq Int, balance:Int, rejected:Int, index:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many index:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole allocated reasons index } {
    index qtys prim seq-int.len prim =
    [ stock allocated reasons ]
    [ items index prim seq-int.at stock swap prim seq-int.at qtys index prim seq-int.at dup stock swap prim seq-int.at prim < [ dup allocated prim seq-int.push stock items index prim seq-int.at dup prim seq-int.at qtys index prim seq-int.at prim - stock swap prim seq-int.set 0 reasons prim seq-int.push index 1 prim + allocate-loop ] [ dup stock swap prim seq-int.at 0 prim = [ drop 2 allocated prim seq-int.push stock reasons prim seq-int.push index 1 prim + allocate-loop ] [ whole index prim seq-bool.at [ drop 3 allocated prim seq-int.push stock reasons prim seq-int.push index 1 prim + allocate-loop ] [ stock items index prim seq-int.at dup prim seq-int.at allocated prim seq-int.push 0 stock swap prim seq-int.set 1 reasons prim seq-int.push index 1 prim + allocate-loop ] if ] if ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole prim seq-int.empty prim seq-int.empty 0 allocate-loop };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 3
message: `}` cannot start an item in a word's body.
actual: }
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
