Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sumloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    [ i xs prim seq-int.len prim < ]
    [ xs i prim seq-int.at acc prim + locals { xs i newacc } { xs i 1 prim + newacc sumloop } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sumloop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sumloop
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at acc prim + ...` of the `if` in `sumloop`, `locals` needs 3 values, but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: maxloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    [ i xs prim seq-int.len prim < prim not ] [ max ] [ xs i prim seq-int.at max prim < [ max ] [ xs i prim seq-int.at ] if locals { xs i newm } { xs i 1 prim + newm maxloop } ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at maxloop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: maxloop
at: line 4, column 179
message: In the false branch of the `if` in `maxloop` whose true branch is `[ max ]`, `locals` needs 3 values, but the branch has pushed only 1 value before it (the result of an `if`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: countloop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    [ i xs prim seq-int.len prim < prim not ] [ count ] [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if locals { xs k i c } { xs k i 1 prim + c countloop } ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 countloop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: countloop
at: line 4, column 175
message: In the false branch of the `if` in `countloop` whose true branch is `[ count ]`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of an `if`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: indexloop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many found:Int^many -- ρ result:Int^many)
  locals { xs x i found } {
    [ found 0 prim < prim not ] [ found ] [ xs i prim seq-int.at x prim = [ i ] [ xs x i 1 prim + found indexloop ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 -1 indexloop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: indexloop
at: line 4, column 122
message: `if` in `indexloop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: revloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ rev:Seq Int^many)
  locals { xs i result } {
    [ i 0 prim < prim not ] [ result ] [ xs i prim seq-int.at prim seq-int.push i 1 prim - xs revloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty revloop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: revloop
at: line 4, column 105
message: In the false branch of the `if` in `revloop` whose true branch is `[ result ]`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes the result of `prim seq-int.at`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefixloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    [ i xs prim seq-int.len prim < prim not ] [ result ] [ xs i prim seq-int.at sum prim + dup locals { xs i ns } { result ns prim seq-int.push i 1 prim + xs prefixloop } ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty 0 prefixloop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefixloop
at: line 4, column 174
message: In the false branch of the `if` in `prefixloop` whose true branch is `[ result ]`, `locals` needs 3 values, but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 9, column 45
message: `prefixloop` in `main` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `0` (Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `prefixloop`, which has an error of its own; this report assumes `prefixloop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Int Seq Int Int
hint: These are the values `prefixloop` takes, in another order. To push them in its order, write `xs 0 0 prim seq-int.empty` in place of `xs 0 prim seq-int.empty 0` on line 9. With that edit `main` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: posloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim < prim not ] [ result ] [ xs i prim seq-int.at dup 0 prim < [ drop result ] [ prim seq-int.push ] if i 1 prim + xs posloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty posloop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: posloop
at: line 4, column 132
message: In the false branch of the `if` in `posloop` whose true branch is `[ drop result ]`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed nothing before it. It would take the result of `prim seq-int.at` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Push every value `prim seq-int.push` takes inside the branch, just before it and in this order: Seq Int, Int, for example by writing the locals that hold them. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sortloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    [ i xs prim seq-int.len 1 prim - prim < prim not ] [ true ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not [ i 1 prim + xs sortloop ] [ false ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { [ xs prim seq-int.len 1 prim < ] [ true ] [ 0 xs sortloop ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: sortloop
at: line 4, column 150
message: `sortloop` in `sortloop` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t45
hint: These are the values `sortloop` takes, in another order. To push them in its order, write `xs i 1 prim +` in place of `i 1 prim + xs` on line 4. With that edit, the next error in `sortloop` is at line 4, column 176.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 9, column 68
message: `sortloop` in `main` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int). `main` calls `sortloop`, which has an error of its own; this report assumes `sortloop` keeps its stack effect.
expected: .. Seq Int Int
actual: .. Int ?t9
hint: These are the values `sortloop` takes, in another order. To push them in its order, write `xs 0` in place of `0 xs` on line 9. With that edit, the next error in `main` is at line 9, column 79.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dotloop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    [ i xs prim seq-int.len prim < prim not ] [ sum ] [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + xs ys dotloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dotloop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dotloop
at: line 4, column 134
message: `dotloop` in `dotloop` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dotloop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: allloop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many result:Bool^many -- ρ all:Bool^many)
  locals { flags i result } {
    [ result prim not ] [ false ] [ [ i flags prim seq-int.len prim < prim not ] [ result ] [ flags i prim seq-int.at result prim and i 1 prim + flags allloop ] if ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { [ flags prim seq-int.len 0 prim = ] [ true ] [ flags 0 true allloop ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: allloop
at: line 4, column 103
message: `prim seq-int.at` in `allloop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `flags` (Seq Bool) and `i` (Int).
expected: .. Seq Int Int
actual: .. Seq Bool Int
hint: The second value from the top, `flags` (Seq Bool), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.quotation-compose-mismatch
word: main
at: line 9, column 22
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Bool [ .. -- .. Seq Bool ] [ .. Seq Int -- .. Bool ]. Expected Seq Bool, found Seq Int.
expected: Seq Bool
actual: Seq Int

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: runloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many curval:Int^many curlen:Int^many maxlen:Int^many -- ρ length:Int^many)
  locals { xs i curval curlen maxlen } {
    [ i xs prim seq-int.len 1 prim - prim < prim not ] [ [ curlen maxlen prim < ] [ maxlen ] [ curlen ] if ] [ xs i 1 prim + prim seq-int.at dup curval prim = [ drop curval curlen 1 prim + i 1 prim + xs runloop ] [ [ curlen maxlen prim < ] [ maxlen ] [ curlen ] if locals { xs i nm } { i 1 prim + xs nm runloop } ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { [ xs prim seq-int.len 0 prim = ] [ 0 ] [ xs 1 xs 0 prim seq-int.at 1 1 runloop ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: runloop
at: line 4, column 316
message: In the true branch `[ drop curval curlen 1 prim + i ...` of the `if` in `runloop`, `runloop` needs 5 values (xs:Seq Int, i:Int, curval:Int, curlen:Int, maxlen:Int), but the branch has pushed only 4 values before it (`curval`, the result of `prim +`, the result of `prim +` and `xs`). Earlier in the branch, the result of `prim seq-int.at` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `runloop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, curval:Int, curlen:Int, maxlen:Int. The branch already pushes `curval`, the result of `prim +`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `runloop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.expected-bool
word: main
at: line 9, column 100
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ]. `main` calls `runloop`, which has an error of its own; this report assumes `runloop` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: innerloop
  (forall ρ; ρ xs:Seq Int^many needed:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs needed j } {
    [ j xs prim seq-int.len prim < prim not ] [ false ] [ xs j prim seq-int.at needed prim = [ true ] [ j 1 prim + xs needed innerloop ] if ] if
  };

: outerloop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    [ i xs prim seq-int.len prim < prim not ] [ false ] [ xs i prim seq-int.at target prim - i 1 prim + xs innerloop [ true ] [ i 1 prim + xs target outerloop ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 outerloop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: innerloop
at: line 4, column 126
message: `innerloop` in `innerloop` takes xs:Seq Int, needed:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `needed` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t64 ?t63
hint: These are the values `innerloop` takes, in another order. To push them in its order, write `xs needed j 1 prim +` in place of `j 1 prim + xs needed` on line 4. With that edit, the next error in `innerloop` is at line 4, column 143.

error 2 of 2
code: firth.type.word-input-mismatch
word: outerloop
at: line 10, column 108
message: `innerloop` in `outerloop` takes xs:Seq Int, needed:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), the result of `prim +` (Int) and `xs` (Seq Int). `outerloop` calls `innerloop`, which has an error of its own; this report assumes `innerloop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Int Int Seq Int
hint: These are the values `innerloop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at target prim -` and `i 1 prim +` are for `needed` and `j`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: checkloop
  (forall ρ; ρ xs:Seq Int^many v:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs v j } {
    [ j xs prim seq-int.len prim < prim not ] [ false ] [ xs j prim seq-int.at v prim = [ true ] [ j 1 prim + xs v checkloop ] if ] if
  };

: distinctloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    [ i xs prim seq-int.len prim < prim not ] [ count ] [ xs i prim seq-int.at 0 xs checkloop [ count 1 prim + ] [ count ] if i 1 prim + xs distinctloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 distinctloop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: checkloop
at: line 4, column 116
message: `checkloop` in `checkloop` takes xs:Seq Int, v:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `v` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t64 ?t63
hint: These are the values `checkloop` takes, in another order. To push them in its order, write `xs v j 1 prim +` in place of `j 1 prim + xs v` on line 4. With that edit, the next error in `checkloop` is at line 4, column 133.

error 2 of 2
code: firth.type.word-input-mismatch
word: distinctloop
at: line 10, column 85
message: `checkloop` in `distinctloop` takes xs:Seq Int, v:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `0` (Int) and `xs` (Seq Int). `distinctloop` calls `checkloop`, which has an error of its own; this report assumes `checkloop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t42 Int Int Seq Int
hint: These are the values `checkloop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `0` are for `v` and `j`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: appendloop
  (forall ρ; ρ src:Seq Int^many idx:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { src idx result } {
    [ idx src prim seq-int.len prim < prim not ] [ result ] [ src idx prim seq-int.at prim seq-int.push idx 1 prim + src appendloop ] if
  };

: mergeloop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    [ i xs prim seq-int.len prim < prim not ] [ result j ys appendloop ] [ [ j ys prim seq-int.len prim < prim not ] [ result i xs appendloop ] [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys mergeloop ] [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys mergeloop ] if ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty mergeloop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: appendloop
at: line 4, column 135
message: In the false branch of the `if` in `appendloop` whose true branch is `[ result ]`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes the result of `prim seq-int.at`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: mergeloop
at: line 10, column 263
message: `mergeloop` in `mergeloop` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int), `j` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Int ?t223 Seq Int ?t222
hint: These are the values `mergeloop` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys` on line 10. With that edit, the next error in `mergeloop` is at line 10, column 342. That edit was checked assuming `appendloop`, which has an error of its own, keeps its stack effect.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digitloop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    [ n 0 prim = ] [ result ] [ n 10 prim mod result swap prim seq-int.push n 10 prim div digitloop ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { [ n 0 prim = ] [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n digitloop ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digitloop
at: line 4, column 91
message: `digitloop` in `digitloop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: The top value, the result of `prim div` (Int), is not what `digitloop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 9, column 99
message: `digitloop` in `main` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int) and `n` (Int). `main` calls `digitloop`, which has an error of its own; this report assumes `digitloop` keeps its stack effect.
expected: .. Int Seq Int
actual: .. Seq Int ?t9
hint: These are the values `digitloop` takes, in another order. To push them in its order, write `n prim seq-int.empty` in place of `prim seq-int.empty n` on line 9. With that edit, the next error in `main` is at line 9, column 111.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: checkprime
  (forall ρ; ρ c:Int^many d:Int^many -- ρ result:Bool^many)
  locals { c d } {
    [ d c prim < prim not ] [ true ] [ [ c d prim mod 0 prim = ] [ false ] [ d 1 prim + c checkprime ] if ] if
  };

: primeloop
  (forall ρ; ρ cand:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { cand n result } {
    [ cand n prim < prim not ] [ result ] [ 2 cand checkprime [ result cand prim seq-int.push ] [ result ] if cand 1 prim + n result primeloop ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { [ n 2 prim < ] [ prim seq-int.empty ] [ 2 n prim seq-int.empty primeloop ] if };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-bool
word: checkprime
at: line 4, column 104
message: `if` in `checkprime` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 3
code: firth.type.branch-mismatch
word: primeloop
at: line 10, column 146
message: The two branches of the `if` in `primeloop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of an `if` and the result of `primeloop`. `primeloop` calls `checkprime`, which has an error of its own; this report assumes `checkprime` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of an `if` is left below the result of `primeloop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.expected-bool
word: main
at: line 15, column 93
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ]. `main` calls `primeloop`, which has an error of its own; this report assumes `primeloop` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: initloop
  (forall ρ; ρ v:Int^many k:Int^many result:Seq Int^many -- ρ inited:Seq Int^many)
  locals { v k result } {
    [ v k prim < prim not ] [ result ] [ result 0 prim seq-int.push v 1 prim + k result initloop ] if
  };

: countloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ counted:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim < prim not ] [ result ] [ xs i prim seq-int.at dup result swap prim seq-int.at 1 prim + prim seq-int.set i 1 prim + xs result countloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 k prim seq-int.empty initloop 0 xs countloop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: initloop
at: line 4, column 100
message: The two branches of the `if` in `initloop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `initloop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `initloop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.stack-underflow
word: countloop
at: line 10, column 122
message: `prim seq-int.set` in `countloop` takes 3 values (the sequence (Seq Int), the index (Int) and the new value (Int)), bottom to top, but only 2 values are on the stack before it, bottom to top: the result of `prim seq-int.at` (Int) and the result of `prim +` (Int).
hint: Push the missing value before `prim seq-int.set`. The locals here, `xs`, `i` and `result`, are not values on the stack: writing a local's name pushes its value.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubbleinner
  (forall ρ; ρ sorted:Seq Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { sorted j } {
    [ j 0 prim < prim not ] [ sorted ] [ sorted j prim seq-int.at sorted j 1 prim - prim seq-int.at prim < [ sorted j 1 prim - prim seq-int.at sorted j prim seq-int.set j 1 prim - sorted swap prim seq-int.set j 1 prim - bubbleinner ] [ j 1 prim - bubbleinner ] if ] if
  };

: bubbleouter
  (forall ρ; ρ sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted i } {
    [ i 0 prim < prim not ] [ sorted ] [ sorted i 1 prim + bubbleinner i 1 prim - bubbleouter ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - bubbleouter };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: bubbleinner
at: line 4, column 262
message: In the false branch of the `if` in `bubbleinner` whose true branch is `[ sorted j 1 prim - prim seq-int.at ...`, `bubbleinner` needs 2 values (sorted:Seq Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `bubbleinner`, exactly the values it takes, in this order: sorted:Seq Int, j:Int. The branch already pushes the result of `prim -`, in the place of the last one (j:Int). Push the first one (sorted:Seq Int) before it by writing the local of that name, `sorted`: write `sorted j 1 prim - bubbleinner` in place of `j 1 prim - bubbleinner` on line 4, column 237. With that edit, the next error in `bubbleinner` is at line 4, column 153. If `bubbleinner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.expected-bool
word: bubbleouter
at: line 10, column 97
message: `if` in `bubbleouter` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledgerloop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance2:Int^many rejected2:Int^many)
  locals { txs i balance rejected } {
    [ i txs prim seq-int.len prim < prim not ] [ balance rejected ] [ txs i prim seq-int.at balance prim + 0 prim < [ balance rejected 1 prim + i 1 prim + txs ledgerloop ] [ balance txs i prim seq-int.at prim + rejected i 1 prim + txs ledgerloop ] if ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs 0 start 0 ledgerloop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ledgerloop
at: line 4, column 160
message: `ledgerloop` in `ledgerloop` takes txs:Seq Int, i:Int, balance:Int, rejected:Int, bottom to top, but here it gets, bottom to top, `balance` (Int), the result of `prim +` (Int), the result of `prim +` (Int) and `txs` (Seq Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Int Seq Int
hint: These are the values `ledgerloop` takes, in another order. By their names and types, `txs` is for `txs` and `balance` is for `balance`. Of the values of one type, `rejected 1 prim +` and `i 1 prim +` are for `i` and `rejected`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocloop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
             j:Int^many sleft:Seq Int^many alloc:Seq Int^many reas:Seq Int^many
             -- ρ sl:Seq Int^many al:Seq Int^many re:Seq Int^many)
  locals { stock items qtys whole j sleft alloc reas } {
    [ j qtys prim seq-int.len prim < prim not ] 
    [ sleft alloc reas ] 
    [ items j prim seq-int.at sleft swap prim seq-int.at qtys j prim seq-int.at locals { stock items qtys whole j sleft alloc reas item r qty } {
        [ qty r prim < ]
        [ sleft item r qty prim - prim seq-int.set alloc qty prim seq-int.push reas 0 prim seq-int.push ]
        [ [ r 0 prim = ]
          [ alloc 0 prim seq-int.push reas 2 prim seq-int.push ]
          [ [ whole j prim seq-int.at ]
            [ alloc 0 prim seq-int.push reas 3 prim seq-int.push ]
            [ sleft item 0 prim seq-int.set alloc r prim seq-int.push reas 1 prim seq-int.push ]
            if
          ]
          if
        ]
        if
        j 1 prim + stock items qtys whole allocloop
      }
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
             -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0 prim seq-int.empty prim seq-int.empty prim seq-int.empty stock items qtys whole allocloop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocloop
at: line 16, column 13
message: The two branches of the `if` in `allocloop` whose true branch is `[ alloc 0 prim seq-int.push reas 3 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.set`, the result of `prim seq-int.push` and the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the result of `prim seq-int.push` and the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 31, column 87
message: `allocloop` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, j:Int, sleft:Seq Int, alloc:Seq Int, reas:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `stock` (Seq Int), `items` (Seq Int), `qtys` (Seq Int) and `whole` (Seq Bool). `main` calls `allocloop`, which has an error of its own; this report assumes `allocloop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int Seq Int
actual: ρ Int Seq Int Seq Int Seq Int Seq Int Seq Int Seq Int Seq Bool
hint: These are the values `allocloop` takes, in another order. To push them in its order, write `stock items qtys whole 0 prim seq-int.empty prim seq-int.empty prim seq-int.empty` in place of `0 prim seq-int.empty prim seq-int.empty prim seq-int.empty stock items qtys whole` on line 31. With that edit `main` checks.
