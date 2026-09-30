Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs max-loop };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if i 1 prim + xs max-loop ]
    [ max ]
    if
  };

```
On the example, it returned [2] instead of [9]

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs rev-loop };

: rev-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i xs } {
    i xs prim seq-int.len prim <
    [ acc xs i prim seq-int.at prim seq-int.push i 1 prim + xs rev-loop ]
    [ acc ]
    if
  };

```
On the example, it returned [[1, 2, 3]] instead of [[3, 2, 1]]

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs ps-loop };

: ps-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sum prim + result swap prim seq-int.push i 1 prim + xs ps-loop ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ps-loop
at: line 11, column 5
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `ps-loop`, `ps-loop` needs 4 values (result:Seq Int, sum:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ps-loop`, exactly the values it takes, in this order: result:Seq Int, sum:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `ps-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs kp-loop };

: kp-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at 0 prim < [ i 1 prim + xs kp-loop acc drop ] [ acc xs i prim seq-int.at prim seq-int.push i 1 prim + xs kp-loop ] if ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: kp-loop
at: line 9, column 141
message: In the true branch `[ i 1 prim + xs kp-loop acc drop ]` of the `if` in `kp-loop`, `kp-loop` needs 3 values (acc:Seq Int, i:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `kp-loop`, exactly the values it takes, in this order: acc:Seq Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`, in the place of the last 2 (i:Int, xs:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (acc:Seq Int) before them, for example by writing the locals that hold it. If `kp-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { true 0 xs is-sort-loop };

: is-sort-loop
  (forall ρ; ρ ok:Bool^many i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { ok i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [ ok [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ i 1 prim + xs is-sort-loop false swap drop ] [ i 1 prim + xs is-sort-loop ] if ] [ ok ] if ]
    [ ok ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-sort-loop
at: line 9, column 160
message: In the true branch `[ xs i prim seq-int.at xs i 1 ...` of the `if` in `is-sort-loop`, `is-sort-loop` (inside a quotation in that branch) needs 3 values (ok:Bool, i:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-sort-loop`, exactly the values it takes, in this order: ok:Bool, i:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`, in the place of the last 2 (i:Int, xs:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (ok:Bool) before them, for example by writing the locals that hold it. If `is-sort-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 flags at-loop };

: at-loop
  (forall ρ; ρ ok:Bool^many i:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { ok i flags } {
    i flags prim seq-bool.len prim <
    [ ok [ flags i prim seq-bool.at [ i 1 prim + flags at-loop ok ] [ false ] if ] [ false ] if ]
    [ ok ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: at-loop
at: line 11, column 5
message: The true branch of `if` in `at-loop` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ, but the true branch takes .. Bool.
expected: .. Bool
actual: ρ
hint: The true branch takes more values than are there. Push them before the condition, or take them as parameters in the signature. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 0 1 xs lr-loop };

: lr-loop
  (forall ρ; ρ maxlen:Int^many curlen:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { maxlen curlen i xs } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [ curlen 1 prim + maxlen prim < [ i 1 prim + xs lr-loop curlen 1 prim + maxlen ] [ i 1 prim + xs lr-loop curlen 1 prim + maxlen ] if ] [ 1 maxlen prim < [ i 1 prim + xs lr-loop 1 maxlen ] [ i 1 prim + xs lr-loop maxlen ] if ] if ]
    [ maxlen curlen prim < [ curlen ] [ maxlen ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: lr-loop
at: line 9, column 286
message: In the true branch `[ i 1 prim + xs lr-loop 1 maxlen ]` of the `if` in `lr-loop`, `lr-loop` needs 4 values (maxlen:Int, curlen:Int, i:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `lr-loop`, exactly the values it takes, in this order: maxlen:Int, curlen:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `lr-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 xs target hps-loop };

: hps-loop
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } {
    i xs prim seq-int.len prim <
    [ found [ 0 i 1 prim + xs target hps-inner ] [ false ] if ]
    [ found ]
    if
  };

: hps-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + i xs target hps-inner ] if ]
    [ i 1 prim + xs target hps-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: hps-inner
at: line 20, column 5
message: In the false branch of the `if` in `hps-inner` whose true branch is `[ xs i prim seq-int.at xs j prim ...`, `hps-loop` needs 4 values (found:Bool, i:Int, xs:Seq Int, target:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `hps-loop`, exactly the values it takes, in this order: found:Bool, i:Int, xs:Seq Int, target:Int. The branch already pushes the result of `prim +`, `xs` and `target`, in the place of the last 3 (i:Int, xs:Seq Int, target:Int): keep each where it has that type and replace it where it does not. Then push the first one (found:Bool) before them, for example by writing the locals that hold it. If `hps-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 xs cd-loop };

: cd-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at seen contains [ i 1 prim + xs cd-loop seen ] [ seen xs i prim seq-int.at prim seq-int.push i 1 prim + xs cd-loop ] if ]
    [ seen prim seq-int.len ]
    if
  };

: contains
  (forall ρ; ρ x:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { x seq } { false 0 x seq cont-loop };

: cont-loop
  (forall ρ; ρ found:Bool^many i:Int^many x:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { found i x seq } {
    i seq prim seq-int.len prim <
    [ seq i prim seq-int.at x prim = [ true ] [ found i 1 prim + x seq cont-loop ] if ]
    [ found ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: cd-loop
at: line 9, column 143
message: In the true branch `[ i 1 prim + xs cd-loop seen ]` of the `if` in `cd-loop`, `cd-loop` needs 3 values (seen:Seq Int, i:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: Make the branch push, just before `cd-loop`, exactly the values it takes, in this order: seen:Seq Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`, in the place of the last 2 (i:Int, xs:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (seen:Seq Int) before them, for example by writing the locals that hold it. If `cd-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n dig-loop ] if };

: dig-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ result n 10 prim mod prim seq-int.push n 10 prim div dig-loop ]
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
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n prim-loop };

: prim-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result i n } {
    i n prim <
    [ i is-prime [ result i prim seq-int.push i 1 prim + n prim-loop ] [ result i 1 prim + n prim-loop ] if ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ true 2 n ip-loop ] if };

: ip-loop
  (forall ρ; ρ prime:Bool^many i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { prime i n } {
    i i prim * n prim <
    [ n i prim mod 0 prim = [ false ] [ prime i 1 prim + n ip-loop ] if ]
    [ prime ]
    if
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 k hist-init xs hist-count };

: hist-init
  (forall ρ; ρ i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i k prim <
    [ prim seq-int.empty 0 prim seq-int.push i 1 prim + k hist-init ]
    [ prim seq-int.empty ]
    if
  };

: hist-count
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts xs } {
    0 xs prim seq-int.len hc-loop counts
  };

: hc-loop
  (forall ρ; ρ i:Int^many len:Int^many counts:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i len counts xs } {
    i len prim <
    [ xs i prim seq-int.at counts swap [ counts swap 1 prim + prim seq-int.set ] dip i 1 prim + len counts xs hc-loop ]
    [ counts ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: hist-init
at: line 11, column 5
message: The two branches of the `if` in `hist-init` whose true branch is `[ prim seq-int.empty 0 prim seq-int.push i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `hist-init`; the false branch leaves the result of `prim seq-int.empty`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `hist-init`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.stack-underflow
word: hist-count
at: line 17, column 27
message: `hc-loop` needs more values than the stack holds here. `hist-count` calls `hc-loop`, which has an error of its own; this report assumes `hc-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `hc-loop` and in what order.

error 3 of 3
code: firth.type.branch-mismatch
word: hc-loop
at: line 26, column 5
message: The two branches of `if` in `hc-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 3 values, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 sort-outer };

: sort-outer
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { arr i } {
    i arr prim seq-int.len 1 prim - prim <
    [ 0 arr i sort-inner ]
    [ arr ]
    if
  };

: sort-inner
  (forall ρ; ρ j:Int^many arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { j arr i } {
    j arr prim seq-int.len i prim - 1 prim - prim <
    [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at prim < [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at arr prim seq-int.set j prim seq-int.at arr j prim seq-int.set j 1 prim + arr i sort-inner ] [ j 1 prim + arr i sort-inner ] if ]
    [ i 1 prim + arr sort-outer ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-inner
at: line 18, column 246
message: The two branches of the `if` in `sort-inner` whose true branch is `[ arr j prim seq-int.at arr j 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `sort-inner`; the false branch leaves the result of `sort-inner`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `sort-inner`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 stock items qtys whole alloc-loop };

: alloc-loop
  (forall ρ; ρ st:Seq Int^many alloc:Seq Int^many i:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ st-final:Seq Int^many alloc-final:Seq Int^many reasons:Seq Int^many)
  locals { st alloc i stock items qtys whole } {
    i qtys prim seq-int.len prim <
    [ items i prim seq-int.at stock prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at alloc-item alloc prim seq-int.push st prim seq-int.set i 1 prim + stock items qtys whole alloc-loop prim seq-int.empty ]
    [ st alloc prim seq-int.empty ]
    if
  };

: alloc-item
  (forall ρ; ρ item:Int^many r:Int^many qty:Int^many whl:Bool^many -- ρ allocated:Int^many reason:Int^many)
  locals { item r qty whl } {
    qty r prim <
    [ r 0 prim = [ 0 2 ] [ whl [ 0 3 ] [ r 1 ] if ] if ]
    [ qty 0 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `alloc-loop`, which has an error of its own; this report assumes `alloc-loop` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: alloc-loop
at: line 11, column 5
message: In the true branch `[ items i prim seq-int.at stock prim seq-int.at ...` of the `if` in `alloc-loop`, `alloc-item` needs 4 values (item:Int, r:Int, qty:Int, whl:Bool), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `alloc-item`, exactly the values it takes, in this order: item:Int, r:Int, qty:Int, whl:Bool. The branch already pushes the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `alloc-item` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
