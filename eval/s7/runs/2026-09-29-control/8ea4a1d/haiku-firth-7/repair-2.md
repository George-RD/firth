Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many acc:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs acc idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at acc prim + [ idx 1 prim + ] dip sum-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 7, column 5
message: In the true branch `[ xs idx prim seq-int.at acc prim + ...` of the `if` in `sum-loop`, `sum-loop` needs 3 values (xs:Seq Int, acc:Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-loop`, exactly the values it takes, in this order: xs:Seq Int, acc:Int, idx:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (acc:Int, idx:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs max idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if [ idx 1 prim + ] dip max-loop } ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs xs 0 prim seq-int.at 1 max-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 7, column 5
message: In the true branch `[ xs idx prim seq-int.at locals { val ...` of the `if` in `max-loop`, `max-loop` needs 3 values (xs:Seq Int, max:Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: xs:Seq Int, max:Int, idx:Int. The branch already pushes the result of `prim +` and the result of an `if`, in the place of the last 2 (max:Int, idx:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many cnt:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs k cnt idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if [ idx 1 prim + ] dip count-loop ]
    [ cnt ]
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
message: In the true branch `[ xs idx prim seq-int.at k prim < ...` of the `if` in `count-loop`, `count-loop` needs 4 values (xs:Seq Int, k:Int, cnt:Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, cnt:Int, idx:Int. The branch already pushes the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many result:Int^many idx:Int^many -- ρ index:Int^many)
  locals { xs x result idx } {
    idx xs prim seq-int.len prim <
    [ result -1 prim = [ xs idx prim seq-int.at x prim = [ idx ] [ result ] if ] [ result ] if [ idx 1 prim + ] dip find-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x -1 0 find-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 7, column 5
message: In the true branch `[ result -1 prim = [ xs idx ...` of the `if` in `find-loop`, `find-loop` needs 4 values (xs:Seq Int, x:Int, result:Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, result:Int, idx:Int. The branch already pushes the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  locals { xs result idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at result prim seq-int.push [ idx 1 prim + ] dip reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 reverse-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 7, column 5
message: In the true branch `[ xs idx prim seq-int.at result prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, result:Seq Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim seq-int.push`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, idx:Int. The branch already pushes the result of `prim +` and the result of `prim seq-int.push`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many idx:Int^many -- ρ sums:Seq Int^many)
  locals { xs result sum idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at sum prim + locals { newsum } { result newsum prim seq-int.push [ idx 1 prim + ] dip newsum [ xs ] dip prefix-loop } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 0 prefix-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 5, column 132
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, result:Seq Int, sum:Int, idx:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and `newsum` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Seq Int Int Seq Int Int Seq Int Seq Int Int
hint: The second value from the top, `xs` (Seq Int), is not what `prefix-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: positive-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many idx:Int^many -- ρ positives:Seq Int^many)
  locals { xs result idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at locals { val } { val 0 prim < [ result ] [ result val prim seq-int.push ] if [ idx 1 prim + ] dip positive-loop } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 positive-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: positive-loop
at: line 7, column 5
message: In the true branch `[ xs idx prim seq-int.at locals { val ...` of the `if` in `positive-loop`, `positive-loop` needs 3 values (xs:Seq Int, result:Seq Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `positive-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, idx:Int. The branch already pushes the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `positive-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many issorted:Bool^many idx:Int^many -- ρ sorted:Bool^many)
  locals { xs issorted idx } {
    idx xs prim seq-int.len 1 prim - prim <
    [ issorted prim and [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < [ issorted ] [ false ] if ] [ false ] if [ idx 1 prim + ] dip sorted-loop ]
    [ issorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs true 0 sorted-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sorted-loop
at: line 7, column 5
message: In the true branch `[ issorted prim and [ xs idx prim ...` of the `if` in `sorted-loop`, `prim and` needs 2 values (Bool, Bool), but the branch has pushed only 1 value before it (`issorted`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim and`, exactly the values it takes, in this order: Bool, Bool. The branch already pushes `issorted`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim and` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Int^many idx:Int^many -- ρ product:Int^many)
  locals { xs ys result idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * result prim + [ idx 1 prim + ] dip dot-loop ]
    [ result ]
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
message: In the true branch `[ xs idx prim seq-int.at ys idx prim ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, result:Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, result:Int, idx:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (result:Int, idx:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many all:Bool^many idx:Int^many -- ρ all:Bool^many)
  locals { flags all idx } {
    idx flags prim seq-bool.len prim <
    [ all prim and [ flags idx prim seq-bool.at [ all ] [ false ] if ] [ false ] if [ idx 1 prim + ] dip all-loop ]
    [ all ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags true 0 all-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-loop
at: line 7, column 5
message: In the true branch `[ all prim and [ flags idx prim ...` of the `if` in `all-loop`, `prim and` needs 2 values (Bool, Bool), but the branch has pushed only 1 value before it (`all`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim and`, exactly the values it takes, in this order: Bool, Bool. The branch already pushes `all`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim and` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many maxrun:Int^many currun:Int^many idx:Int^many -- ρ length:Int^many)
  locals { xs maxrun currun idx } {
    idx xs prim seq-int.len prim <
    [ idx 0 prim = [ [ idx 1 prim + ] dip currun [ xs ] dip run-loop ] [ xs idx prim seq-int.at xs idx 1 prim - prim seq-int.at prim = [ [ currun 1 prim + ] dip [ xs ] dip run-loop ] [ currun maxrun prim < [ [ idx 1 prim + ] dip 1 [ xs ] dip run-loop ] [ [ maxrun ] dip 1 [ xs ] dip run-loop ] if ] if ] if ]
    [ maxrun ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 1 0 run-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 5, column 300
message: In the true branch `[ [ currun 1 prim + ] dip ...` of the `if` in `run-loop`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ currun 1 prim + ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many idx:Int^many nextidx:Int^many -- ρ found:Bool^many)
  locals { xs target found idx nextidx } {
    nextidx xs prim seq-int.len prim <
    [ found prim not [ xs idx prim seq-int.at xs nextidx prim seq-int.at prim + target prim = [ true ] [ found ] if ] [ found ] if [ nextidx 1 prim + ] dip inner-loop ]
    [ found ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many idx:Int^many -- ρ found:Bool^many)
  locals { xs target found idx } {
    idx xs prim seq-int.len prim <
    [ found prim not [ idx 1 prim + xs target found idx inner-loop ] [ found ] if [ idx 1 prim + ] dip outer-loop ]
    [ found ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target false 0 outer-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: inner-loop
at: line 7, column 5
message: In the true branch `[ found prim not [ xs idx prim ...` of the `if` in `inner-loop`, `inner-loop` needs 5 values (xs:Seq Int, target:Int, found:Bool, idx:Int, nextidx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, found:Bool, idx:Int, nextidx:Int. The branch already pushes the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: outer-loop
at: line 16, column 5
message: In the true branch `[ found prim not [ idx 1 prim ...` of the `if` in `outer-loop`, `outer-loop` needs 4 values (xs:Seq Int, target:Int, found:Bool, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
hint: Make the branch push, just before `outer-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, found:Bool, idx:Int. The branch already pushes the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `outer-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-seen
  (forall ρ; ρ xs:Seq Int^many found:Bool^many idx:Int^many cidx:Int^many -- ρ found:Bool^many)
  locals { xs found idx cidx } {
    cidx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at xs cidx prim seq-int.at prim = [ true ] [ found ] if [ cidx 1 prim + ] dip check-seen ]
    [ found ]
    if
  };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many count:Int^many idx:Int^many -- ρ count:Int^many)
  locals { xs count idx } {
    idx xs prim seq-int.len prim <
    [ false 0 xs count idx check-seen [ count 1 prim + ] [ count ] if [ idx 1 prim + ] dip distinct-loop ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 distinct-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-seen
at: line 7, column 5
message: In the true branch `[ xs idx prim seq-int.at xs cidx prim ...` of the `if` in `check-seen`, `check-seen` needs 4 values (xs:Seq Int, found:Bool, idx:Int, cidx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-seen`, exactly the values it takes, in this order: xs:Seq Int, found:Bool, idx:Int, cidx:Int. The branch already pushes the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-seen` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: distinct-loop
at: line 14, column 28
message: `check-seen` in `distinct-loop` takes xs:Seq Int, found:Bool, idx:Int, cidx:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `xs` (Seq Int), `count` (Int) and `idx` (Int). `distinct-loop` calls `check-seen`, which has an error of its own; this report assumes `check-seen` keeps its stack effect.
expected: .. Seq Int Bool Int Int
actual: .. ?t26 ?t25 Bool Int ?t27 ?t26 ?t25
hint: The top value, `idx` (Int), is not what `check-seen` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xi xs prim seq-int.len prim <
    yi ys prim seq-int.len prim < prim or
    [ xi xs prim seq-int.len prim <
      yi ys prim seq-int.len prim < prim and
      [ xs xi prim seq-int.at ys yi prim seq-int.at prim < [ result xs xi prim seq-int.at prim seq-int.push [ xi 1 prim + ] dip yi [ xs ys ] dip merge-loop ] [ result ys yi prim seq-int.at prim seq-int.push [ yi 1 prim + ] dip xi [ xs ys ] dip merge-loop ] if ]
      [ xi xs prim seq-int.len prim < [ result xs xi prim seq-int.at prim seq-int.push [ xi 1 prim + ] dip yi [ xs ys ] dip merge-loop ] [ result ys yi prim seq-int.at prim seq-int.push [ yi 1 prim + ] dip xi [ xs ys ] dip merge-loop ] if ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-loop
at: line 8, column 146
message: `merge-loop` in `merge-loop` takes xs:Seq Int, ys:Seq Int, result:Seq Int, xi:Int, yi:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int) and `yi` (Int).
expected: .. Seq Int Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int ?t200 ?t159
hint: The top value, `yi` (Int), is not what `merge-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ num:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { num result } {
    num 0 prim =
    [ result ]
    [ result num 10 prim mod prim seq-int.push [ num 10 prim div ] dip digit-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ n prim seq-int.empty digit-loop ]
    if
  };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: check-prime
  (forall ρ; ρ candidate:Int^many isprime:Bool^many divisor:Int^many -- ρ isprime:Bool^many)
  locals { candidate isprime divisor } {
    divisor candidate prim <
    [ isprime prim and [ candidate divisor prim mod 0 prim = [ false ] [ isprime ] if [ divisor 1 prim + ] dip check-prime ] [ false ] if ]
    [ isprime ]
    if
  };

: prime-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many candidate:Int^many -- ρ result:Seq Int^many)
  locals { n result candidate } {
    candidate n prim <
    [ true 2 candidate check-prime [ result candidate prim seq-int.push ] [ result ] if [ candidate 1 prim + ] dip prime-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n prim seq-int.empty 2 prime-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-prime
at: line 5, column 136
message: In the true branch `[ candidate divisor prim mod 0 prim = ...` of the `if` in `check-prime`, `check-prime` needs 3 values (candidate:Int, isprime:Bool, divisor:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-prime`, exactly the values it takes, in this order: candidate:Int, isprime:Bool, divisor:Int. The branch already pushes the result of `prim +` and the result of an `if`, in the place of the first 2 (candidate:Int, isprime:Bool): keep each where it has that type and replace it where it does not. Then push the last one (divisor:Int) after them, for example by writing the locals that hold it. If `check-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: prime-loop
at: line 16, column 5
message: In the true branch `[ true 2 candidate check-prime [ result candidate ...` of the `if` in `prime-loop`, `prime-loop` needs 3 values (n:Int, result:Seq Int, candidate:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `prime-loop` calls `check-prime`, which has an error of its own; this report assumes `check-prime` keeps its stack effect.
hint: Make the branch push, just before `prime-loop`, exactly the values it takes, in this order: n:Int, result:Seq Int, candidate:Int. The branch already pushes the result of `prim +` and the result of an `if`, in the place of the first 2 (n:Int, result:Seq Int): keep each where it has that type and replace it where it does not. Then push the last one (candidate:Int) after them, for example by writing the locals that hold it. If `prime-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ k:Int^many counts:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { k counts i } {
    i k prim <
    [ counts 0 prim seq-int.push [ i 1 prim + ] dip init-counts ]
    [ counts ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many idx:Int^many -- ρ counts:Seq Int^many)
  locals { xs counts idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at locals { val } { counts val prim seq-int.at 1 prim + counts val prim seq-int.set [ idx 1 prim + ] dip count-loop } ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { k prim seq-int.empty 0 init-counts xs count-loop };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: init-counts
at: line 7, column 5
message: In the true branch `[ counts 0 prim seq-int.push [ i 1 ...` of the `if` in `init-counts`, `init-counts` needs 3 values (k:Int, counts:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim seq-int.push`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-counts`, exactly the values it takes, in this order: k:Int, counts:Seq Int, i:Int. The branch already pushes the result of `prim +` and the result of `prim seq-int.push`, in the place of the first 2 (k:Int, counts:Seq Int): keep each where it has that type and replace it where it does not. Then push the last one (i:Int) after them, for example by writing the locals that hold it. If `init-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: count-loop
at: line 16, column 5
message: In the true branch `[ xs idx prim seq-int.at locals { val ...` of the `if` in `count-loop`, `count-loop` needs 3 values (xs:Seq Int, counts:Seq Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim seq-int.set`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, counts:Seq Int, idx:Int. The branch already pushes the result of `prim +` and the result of `prim seq-int.set`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 21, column 59
message: `count-loop` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Seq Int. `main` calls `init-counts` and `count-loop`, which have errors of their own; this report assumes they keep their stack effects.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Seq Int
hint: `count-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ i 1 prim + [ xs locals { j } { j xs prim seq-int.len prim < [ xs j prim seq-int.at xs j 1 prim - prim seq-int.at prim < [ result xs j prim seq-int.at prim seq-int.push xs j 1 prim - prim seq-int.at result prim seq-int.push ] [ result ] if [ j 1 prim + ] dip ] [ ] if } ] call [ i 1 prim + ] dip insertion-sort ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs prim seq-int.empty xs 0 insertion-sort };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insertion-sort
at: line 5, column 243
message: The two branches of the `if` in `insertion-sort` whose true branch is `[ result xs j prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 11, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int. `main` calls `insertion-sort`, which has an error of its own; this report assumes `insertion-sort` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many idx:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs balance rejected idx } {
    idx txs prim seq-int.len prim <
    [ txs idx prim seq-int.at locals { tx } { balance tx prim + 0 prim < [ rejected 1 prim + [ balance ] dip [ idx 1 prim + ] dip ledger-loop ] [ [ balance tx prim + ] dip rejected [ idx 1 prim + ] dip ledger-loop ] if } ]
    [ balance rejected ]
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
message: The two branches of `if` in `ledger-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 2 values, and the false branch pushes 2 values. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole allocated reasons idx } {
    idx items prim seq-int.len prim <
    [ items idx prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys idx prim seq-int.at locals { qty } { qty r prim < [ allocated qty prim seq-int.push [ stock item prim seq-int.set [ r qty prim - ] dip 0 reasons prim seq-int.push [ idx 1 prim + ] dip allocate-order ] [ r 0 prim = [ allocated 0 prim seq-int.push [ reasons 2 prim seq-int.push ] dip [ idx 1 prim + ] dip allocate-order ] [ whole idx prim seq-bool.at [ allocated 0 prim seq-int.push [ reasons 3 prim seq-int.push ] dip [ idx 1 prim + ] dip allocate-order ] [ allocated r prim seq-int.push [ stock item prim seq-int.set [ 0 ] dip 1 reasons prim seq-int.push [ idx 1 prim + ] dip allocate-order ] ] if ] if ] if } } } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole prim seq-int.empty prim seq-int.empty 0 allocate-order };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 5, column 706
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
