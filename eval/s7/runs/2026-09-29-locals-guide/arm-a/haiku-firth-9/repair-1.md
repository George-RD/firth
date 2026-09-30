Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs } {
    [ xs i prim seq-int.at acc prim + i 1 prim + xs sum-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: sum-loop
at: line 11, column 5
message: `if` in `sum-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if i 1 prim + xs max-loop ]
    [ max ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: max-loop
at: line 11, column 5
message: `if` in `max-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc i xs k } {
    [ xs i prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if i 1 prim + xs k count-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: count-loop
at: line 11, column 5
message: `if` in `count-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x find-loop };

: find-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    [ xs i prim seq-int.at x prim = [ i ] [ i 1 prim + xs x find-loop ] if ]
    [ -1 ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: find-loop
at: line 11, column 5
message: `if` in `find-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ xs i prim seq-int.at acc prim seq-int.push i 1 prim + xs rev-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: rev-loop
at: line 8, column 32
message: `prim seq-int.push` in `rev-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t15.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t15
hint: The top value is ?t15 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ xs i prim seq-int.at sum prim + result swap prim seq-int.push i 1 prim + xs ps-loop ]
    [ result ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ps-loop
at: line 8, column 83
message: `ps-loop` in `ps-loop` needs Seq Int Int Int Seq Int on top of the stack, but the stack before it is .. Seq Int Seq Int Int Seq Int.
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Int Seq Int
hint: `ps-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
    [ xs i prim seq-int.at 0 prim < [ acc i 1 prim + xs kp-loop ] [ xs i prim seq-int.at acc prim seq-int.push i 1 prim + xs kp-loop ] if ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: kp-loop
at: line 8, column 94
message: `prim seq-int.push` in `kp-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t71.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t71
hint: The top value is ?t71 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ ok [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [ i 1 prim + xs is-sort-loop ] if ] [ false ] if ]
    [ ok ]
    i xs prim seq-int.len 1 prim - prim <
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-sort-loop
at: line 8, column 111
message: The two branches of `if` in `is-sort-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs ys } {
    [ xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + i 1 prim + xs ys dot-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: dot-loop
at: line 11, column 5
message: `if` in `dot-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ ok [ flags i prim seq-bool.at [ i 1 prim + flags at-loop ] [ false ] if ] [ false ] if ]
    [ ok ]
    i flags prim seq-bool.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: at-loop
at: line 8, column 76
message: The two branches of `if` in `at-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [ curlen 1 prim + ] [ 1 ] if maxlen prim < [ i 1 prim + xs lr-loop ] [ maxlen i 1 prim + xs lr-loop ] if ]
    [ maxlen curlen prim < [ curlen ] [ maxlen ] if ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: lr-loop
at: line 8, column 167
message: The two branches of `if` in `lr-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
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
  locals { xs target } { false 0 xs target hps-loop };

: hps-loop
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } {
    [ found [ 0 i 1 prim + xs target hps-inner ] [ false ] if ]
    [ found ]
    i xs prim seq-int.len prim <
    if
  };

: hps-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + i xs target hps-inner ] if ]
    [ j 1 prim + i xs target hps-loop ]
    j xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: hps-loop
at: line 11, column 5
message: `if` in `hps-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.word-input-mismatch
word: hps-inner
at: line 18, column 30
message: `hps-loop` in `hps-inner` needs Bool Int Seq Int Int on top of the stack, but the stack before it is .. Int ?t122 ?t121 ?t120. `hps-inner` calls `hps-loop`, which has an error of its own; this report assumes `hps-loop` keeps its stack effect.
expected: .. Bool Int Seq Int Int
actual: .. Int ?t122 ?t121 ?t120
hint: The top value is ?t120 but `hps-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ xs i prim seq-int.at seen contains [ i 1 prim + xs cd-loop ] [ xs i prim seq-int.at seen prim seq-int.push i 1 prim + xs cd-loop ] if ]
    [ seen prim seq-int.len ]
    i xs prim seq-int.len prim <
    if
  };

: contains
  (forall ρ; ρ x:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { x seq } { false 0 x seq cont-loop };

: cont-loop
  (forall ρ; ρ found:Bool^many i:Int^many x:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { found i x seq } {
    [ seq i prim seq-int.at x prim = [ true ] [ found i 1 prim + x seq cont-loop ] if ]
    [ found ]
    i seq prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: cd-loop
at: line 8, column 138
message: The two branches of `if` in `cd-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.expected-bool
word: cont-loop
at: line 24, column 5
message: `if` in `cont-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys ms-loop };

: ms-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    [ i xs prim seq-int.len prim < [ j ys prim seq-int.len prim < [ xs i prim seq-int.at ys j prim seq-int.at prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys ms-loop ] [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys ms-loop ] if ] [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys ms-loop ] if ] [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys ms-loop ] if ]
    [ result ]
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim or prim not
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: ms-loop
at: line 8, column 148
message: `prim seq-int.push` in `ms-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t182 ?t181 Int ?t183.
expected: .. Seq Int Int
actual: .. Seq Int Int ?t182 ?t181 Int ?t183
hint: The top value is ?t183 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ n 10 prim mod result prim seq-int.push n 10 prim div dig-loop ]
    [ result ]
    n 0 prim =
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: dig-loop
at: line 8, column 28
message: `prim seq-int.push` in `dig-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t8.
expected: .. Seq Int Int
actual: .. Int Int ?t8
hint: The top value is ?t8 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ i is-prime [ i result prim seq-int.push ] [ result ] if i 1 prim + n prim-loop ]
    [ result ]
    i n prim <
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ true 2 n ip-loop ] if };

: ip-loop
  (forall ρ; ρ prime:Bool^many i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { prime i n } {
    [ n i prim mod 0 prim = [ false ] [ i 1 prim + n ip-loop ] if ]
    [ prime ]
    i i prim * n prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-compose-mismatch
word: prim-loop
at: line 8, column 18
message: `compose` in `prim-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Int ?t16 ?t15 Bool [ .. -- .. Int ?t16 ] [ .. Seq Int Int -- .. Seq Int ]. Expected Int, found Seq Int.
expected: Int
actual: Seq Int

error 2 of 2
code: firth.type.branch-mismatch
word: ip-loop
at: line 21, column 64
message: The two branches of `if` in `ip-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 prim seq-int.empty [ ] dip 0 k hist-init xs hist-count };

: hist-init
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k } {
    [ counts 0 prim seq-int.push i 1 prim + k hist-init ]
    [ counts ]
    i k prim <
    if
  };

: hist-count
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts i xs } {
    [ xs i prim seq-int.at counts swap [ counts swap 1 prim + prim seq-int.set ] dip i 1 prim + xs hist-count ]
    [ counts ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 3, column 67
message: `hist-count` in `main` takes counts:Seq Int, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `hist-init` (Seq Int) and `xs` (Seq Int). `main` calls `hist-init` and `hist-count`, which have errors of their own; this report assumes they keep their stack effects.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int Seq Int
hint: The second value from the top, the result of `hist-init` (Seq Int), is not what `hist-count` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.expected-bool
word: hist-init
at: line 11, column 5
message: `if` in `hist-init` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 3
code: firth.type.word-input-mismatch
word: hist-count
at: line 17, column 100
message: `hist-count` in `hist-count` needs Seq Int Int Seq Int on top of the stack, but the stack before it is .. Seq Int Int Int Seq Int.
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Int Int Seq Int
hint: The third value from the top is Int but `hist-count` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ 0 arr i sort-inner ]
    [ arr ]
    i arr prim seq-int.len 1 prim - prim <
    if
  };

: sort-inner
  (forall ρ; ρ j:Int^many arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { j arr i } {
    [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at prim < [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at arr prim seq-int.set j prim seq-int.at arr j prim seq-int.set j 1 prim + arr i sort-inner ] [ j 1 prim + arr i sort-inner ] if ]
    [ i 1 prim + arr sort-outer ]
    j arr prim seq-int.len i prim - 1 prim - prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: sort-outer
at: line 11, column 5
message: `if` in `sort-outer` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool. `sort-outer` calls `sort-inner`, which has an error of its own; this report assumes `sort-inner` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-inner
at: line 17, column 246
message: The two branches of `if` in `sort-inner` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs led-loop };

: led-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    [ txs i prim seq-int.at balance prim + 0 prim < [ balance rejected 1 prim + i 1 prim + txs led-loop ] [ txs i prim seq-int.at balance prim + i 1 prim + txs led-loop rejected ] if ]
    [ balance rejected ]
    i txs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: led-loop
at: line 11, column 5
message: `if` in `led-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. Int -- .. Int Int Int ] [ .. -- .. Int Int ] Bool.
expected: Bool
actual: [ .. Int -- .. Int Int Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ items i prim seq-int.at stock prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at alloc-item alloc prim seq-int.push st prim seq-int.set i 1 prim + stock items qtys whole alloc-loop ]
    [ st alloc prim seq-int.empty ]
    i qtys prim seq-int.len prim <
    if
  };

: alloc-item
  (forall ρ; ρ item:Int^many r:Int^many qty:Int^many whl:Bool^many -- ρ allocated:Int^many reason:Int^many)
  locals { item r qty whl } {
    [ qty r prim < [ whl [ 0 3 ] [ r 1 ] if ] [ qty 0 ] if ]
    [ r 0 prim = [ 0 2 ] [ qty r prim < [ 0 0 ] [ r prim < [ r 1 ] [ qty 0 ] if ] if ] if ]
    qty r prim <
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `alloc-loop`, which has an error of its own; this report assumes `alloc-loop` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: alloc-loop
at: line 8, column 37
message: `prim seq-int.at` in `alloc-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t49 ?t48 ?t47 ?t46 ?t45 Int ?t49.
expected: .. Seq Int Int
actual: .. Seq Int Int ?t49 ?t48 ?t47 ?t46 ?t45 Int ?t49
hint: The top value is ?t49 but `prim seq-int.at` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

error 3 of 3
code: firth.type.branch-mismatch
word: alloc-item
at: line 18, column 83
message: The two branches of `if` in `alloc-item` leave different numbers of values: the true branch pushes 2 values, and the false branch takes 1 value from the stack below the `if` and leaves 2 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
