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
  locals { xs } { 0 0 [ xs locals { seq idx } { idx xs prim seq-int.len prim < [ seq idx xs prim seq-int.at prim + [ idx 1 prim + ] dip [ seq ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 155
message: The two branches of the `if` in `main` whose true branch is `[ seq idx xs prim seq-int.at prim + ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim +`, `seq` and the result of `prim +`; the false branch leaves nothing.
hint: The true branch leaves 3 values more than the false branch: the result of `prim +`, `seq` and the result of `prim +` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 [ xs locals { max idx } { idx xs prim seq-int.len prim < [ [ idx 1 prim + ] dip xs idx 1 prim + prim seq-int.at locals { val } { val max prim < [ val ] [ max ] if ] ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 205
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 [ xs locals { cnt idx } { idx xs prim seq-int.len prim < [ xs idx prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 171
message: The two branches of the `if` in `main` whose true branch is `[ xs idx prim seq-int.at k prim < ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of an `if` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { -1 0 [ xs locals { result idx } { idx xs prim seq-int.len prim < [ result -1 prim = [ xs idx prim seq-int.at x prim = [ idx ] [ result ] if ] [ result ] if [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 204
message: The two branches of the `if` in `main` whose true branch is `[ result -1 prim = [ xs idx ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of an `if` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 [ xs locals { result idx } { idx xs prim seq-int.len prim < [ xs idx prim seq-int.at result prim seq-int.push [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 177
message: The two branches of the `if` in `main` whose true branch is `[ xs idx prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prim seq-int.push`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of `prim seq-int.push` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 [ xs locals { result sum idx } { idx xs prim seq-int.len prim < [ xs idx prim seq-int.at sum prim + locals { newsum } { result newsum prim seq-int.push [ idx 1 prim + ] dip ] ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 215
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 [ xs locals { result idx } { idx xs prim seq-int.len prim < [ xs idx prim seq-int.at locals { val } { val 0 prim < [ result ] [ result val prim seq-int.push ] if [ idx 1 prim + ] dip ] ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 223
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { true 0 [ xs locals { issorted idx } { idx xs prim seq-int.len 1 prim - prim < issorted prim and [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < [ issorted ] [ false ] if [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 232
message: The two branches of the `if` in `main` whose true branch is `[ xs idx prim seq-int.at xs idx 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of an `if` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 [ xs ys locals { result idx } { idx xs prim seq-int.len prim < [ xs idx prim seq-int.at ys idx prim seq-int.at prim * result prim + [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 185
message: The two branches of the `if` in `main` whose true branch is `[ xs idx prim seq-int.at ys idx prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prim +`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of `prim +` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 [ flags locals { all idx } { idx flags prim seq-bool.len prim < all prim and [ flags idx prim seq-bool.at [ all ] [ false ] if [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 183
message: The two branches of the `if` in `main` whose true branch is `[ flags idx prim seq-bool.at [ all ] ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of an `if` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 1 1 [ xs locals { maxrun currun idx } { idx xs prim seq-int.len prim < [ idx 0 prim = [ [ idx 1 prim + ] dip ] [ xs idx prim seq-int.at xs idx 1 prim - prim seq-int.at prim = [ [ currun 1 prim + ] dip ] [ currun maxrun prim < [ idx 1 prim + ] [ [ maxrun ] dip currun [ idx 1 prim + ] dip 1 ] if ] if ] if ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 313
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 5 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 [ xs target locals { found idx } { idx xs prim seq-int.len prim < found prim not prim and [ idx 1 prim + [ xs locals { nextidx } { nextidx xs prim seq-int.len prim < found prim not prim and [ xs idx prim seq-int.at xs nextidx prim seq-int.at prim + target prim = [ true ] [ found ] if [ nextidx 1 prim + ] dip ] [ ] if } ] call [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 350
message: The two branches of the `if` in `main` whose true branch is `[ xs idx prim seq-int.at xs nextidx prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of an `if` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 [ xs locals { count idx } { idx xs prim seq-int.len prim < [ 0 idx 1 prim - [ xs locals { found cidx } { cidx xs prim seq-int.len prim < [ xs idx prim seq-int.at xs cidx prim seq-int.at prim = [ true ] [ found ] if [ cidx 1 prim + ] dip ] [ ] if } ] call prim not [ count 1 prim + ] [ count ] if [ idx 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 266
message: The two branches of the `if` in `main` whose true branch is `[ xs idx prim seq-int.at xs cidx prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of an `if` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 [ xs ys locals { result xi yi } { xi xs prim seq-int.len prim < yi ys prim seq-int.len prim < prim or [ xi xs prim seq-int.len prim < yi ys prim seq-int.len prim < prim and [ xs xi prim seq-int.at ys yi prim seq-int.at prim < [ result xs xi prim seq-int.at prim seq-int.push [ xi 1 prim + ] dip ] [ result ys yi prim seq-int.at prim seq-int.push [ yi 1 prim + ] dip ] if ] [ xi xs prim seq-int.len prim < [ result xs xi prim seq-int.at prim seq-int.push [ xi 1 prim + ] dip ] [ result ys yi prim seq-int.at prim seq-int.push [ yi 1 prim + ] dip ] if ] if } ] call };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 600
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n [ n locals { result num } { num 0 prim = [ result ] [ result num 10 prim mod prim seq-int.push [ num 10 prim div ] dip num 10 prim div ] if } ] call ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 199
message: The two branches of the `if` in `main` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 3 values, bottom to top: the result of `prim div`, the result of `prim seq-int.push` and the result of `prim div`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim div` and the result of `prim seq-int.push` are left below the result of `prim div`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 [ n locals { result candidate } { candidate n prim < [ 1 2 [ candidate locals { isprime divisor } { divisor candidate prim < isprime prim and [ candidate divisor prim mod 0 prim = [ false ] [ isprime ] if [ divisor 1 prim + ] dip ] [ ] if } ] call [ result candidate prim seq-int.push ] [ result ] if [ candidate 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 275
message: The two branches of the `if` in `main` whose true branch is `[ candidate divisor prim mod 0 prim = ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of an `if` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 [ k locals { counts i } { i k prim < [ counts 0 prim seq-int.push [ i 1 prim + ] dip ] [ ] if } ] call 0 [ xs locals { counts idx } { idx xs prim seq-int.len prim < [ xs idx prim seq-int.at locals { val } { counts val prim seq-int.at 1 prim + counts val prim seq-int.set [ idx 1 prim + ] dip } ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 114
message: The two branches of the `if` in `main` whose true branch is `[ counts 0 prim seq-int.push [ i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prim seq-int.push`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and the result of `prim seq-int.push` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 [ xs locals { result i } { i xs prim seq-int.len 1 prim - prim < [ i 1 prim + [ xs locals { j } { j xs prim seq-int.len prim < [ xs j prim seq-int.at xs j 1 prim - prim seq-int.at prim < [ result xs j prim seq-int.at prim seq-int.push xs j 1 prim - prim seq-int.at result prim seq-int.push ] [ ] if [ j 1 prim + ] dip ] [ ] if } ] call [ i 1 prim + ] dip ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 3, column 320
message: The two branches of the `if` in `main` whose true branch is `[ result xs j prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.push` and the result of `prim seq-int.push` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 [ txs locals { balance rejected idx } { idx txs prim seq-int.len prim < [ txs idx prim seq-int.at locals { tx } { balance tx prim + 0 prim < [ [ rejected 1 prim + ] dip ] [ balance tx prim + ] if [ idx 1 prim + ] dip } ] ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 257
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 [ items locals { stock allocated reasons idx } { idx items prim seq-int.len prim < [ items idx prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys idx prim seq-int.at locals { qty } { qty r prim < [ allocated qty prim seq-int.push [ stock item prim seq-int.set [ r qty prim - ] dip 0 reasons prim seq-int.push ] [ r 0 prim = [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] [ whole idx prim seq-bool.at [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ allocated r prim seq-int.push [ stock item prim seq-int.set [ 0 ] dip 1 reasons prim seq-int.push ] ] if ] if ] if [ idx 1 prim + ] dip } } } ] ] [ ] if } ] call };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 730
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
