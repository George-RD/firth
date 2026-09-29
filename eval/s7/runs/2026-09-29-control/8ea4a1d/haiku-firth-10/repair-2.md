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
  locals { xs } { 0 0 sum-helper xs };

: sum-helper
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ total:Int^many)
  locals { acc i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at prim + locals { v } { v i 1 prim + sum-helper } ] [ acc ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 23
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Int Seq Int [ .. Int Int Seq Int -- .. Int ]). `main` calls `sum-helper`, which has an error of its own; this report assumes `sum-helper` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.branch-mismatch
word: sum-helper
at: line 7, column 135
message: In the true branch `[ xs i prim seq-int.at prim + locals ...` of the `if` in `sum-helper`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes the result of `prim seq-int.at`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 max-helper xs };

: max-helper
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { v max prim < [ v ] [ max ] if i 1 prim + max-helper } ] [ max ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 42
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Int Seq Int [ .. Int Int Seq Int -- .. Int ]). `main` calls `max-helper`, which has an error of its own; this report assumes `max-helper` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.branch-mismatch
word: max-helper
at: line 7, column 156
message: In the true branch `[ xs i prim seq-int.at locals { v ...` of the `if` in `max-helper`, `max-helper` needs 3 values (max:Int, i:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-helper`, exactly the values it takes, in this order: max:Int, i:Int, xs:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the first 2 (max:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (xs:Seq Int) after them, for example by writing the locals that hold it. If `max-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len reverse-helper xs };

: reverse-helper
  (forall ρ; ρ acc:Seq Int^many len:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { acc len xs } { len 0 prim < [ acc ] [ len 1 prim - locals { i } { xs i prim seq-int.at prim seq-int.push acc i reverse-helper } ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 58
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Seq Int [ .. Seq Int Int Seq Int -- .. Seq Int ]). `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-helper
at: line 7, column 142
message: In the false branch of the `if` in `reverse-helper` whose true branch is `[ acc ]`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes the result of `prim seq-int.at`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-helper };

: prefix-helper
  (forall ρ; ρ acc:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { acc sum i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { sum v prim + acc prim seq-int.push i 1 prim + sum v prim + xs prefix-helper } ] [ acc ] if };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-helper
at: line 7, column 113
message: `prim seq-int.push` in `prefix-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `acc` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t25 Int Int ?t25
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `acc sum v prim +` in place of `sum v prim + acc`. With that edit `prefix-helper` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-helper };

: keep-helper
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { acc i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { v 0 prim < [ acc ] [ acc v prim seq-int.push ] if i 1 prim + xs keep-helper } ] [ acc ] if };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 1 prim < [ 1 ] [ 1 1 xs len is-sorted-helper ] if } };

: is-sorted-helper
  (forall ρ; ρ ok:Bool^many i:Int^many xs:Seq Int^many len:Int^many -- ρ sorted:Bool^many)
  locals { ok i xs len } { ok prim not [ 0 ] [ i len prim < [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim < prim not [ i 1 prim + xs len is-sorted-helper ] [ 0 ] if ] [ 1 ] if ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 88
message: `is-sorted-helper` in `main` takes ok:Bool, i:Int, xs:Seq Int, len:Int, bottom to top, but here it gets, bottom to top, `1` (Int), `1` (Int), `xs` (Seq Int) and `len` (Int). `main` calls `is-sorted-helper`, which has an error of its own; this report assumes `is-sorted-helper` keeps its stack effect.
expected: .. Bool Int Seq Int Int
actual: .. Int Int ?t17 ?t16
hint: The top value, `len` (Int), is not what `is-sorted-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: is-sorted-helper
at: line 7, column 175
message: In the true branch `[ i 1 prim + xs len is-sorted-helper ]` of the `if` in `is-sorted-helper`, `is-sorted-helper` needs 4 values (ok:Bool, i:Int, xs:Seq Int, len:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-sorted-helper`, exactly the values it takes, in this order: ok:Bool, i:Int, xs:Seq Int, len:Int. The branch already pushes the result of `prim +`, `xs` and `len`, in the place of the last 3 (i:Int, xs:Seq Int, len:Int): keep each where it has that type and replace it where it does not. Then push the first one (ok:Bool) before them, for example by writing the locals that hold it. If `is-sorted-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 1 0 flags all-helper };

: all-helper
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result i flags } { result prim not [ 0 ] [ i flags prim seq-int.len prim < [ flags i prim seq-int.at result prim and i 1 prim + flags all-helper ] [ result ] if ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 32
message: `all-helper` in `main` takes result:Bool, i:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, `1` (Int), `0` (Int) and `flags` (Seq Bool). `main` calls `all-helper`, which has an error of its own; this report assumes `all-helper` keeps its stack effect.
expected: .. Bool Int Seq Bool
actual: ρ Int Int Seq Bool
hint: The third value from the top, `1` (Int), is not what `all-helper` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: all-helper
at: line 7, column 63
message: `prim seq-int.len` in `all-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: .. Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim = [ 0 ] [ 0 1 1 0 xs len longest-helper ] if } };

: longest-helper
  (forall ρ; ρ maxrun:Int^many currun:Int^many i:Int^many lastval:Int^many xs:Seq Int^many len:Int^many -- ρ length:Int^many)
  locals { maxrun currun i lastval xs len } { i len prim < [ xs i prim seq-int.at locals { v } { v lastval prim = [ currun 1 prim + maxrun prim < [ v i 1 prim + xs len longest-helper ] [ maxrun currun i 1 prim + v xs len longest-helper ] if ] [ maxrun currun prim < [ currun v i 1 prim + xs len longest-helper ] [ maxrun 1 i 1 prim + v xs len longest-helper ] if ] if } ] [ maxrun currun prim < [ currun ] [ maxrun ] if ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: longest-helper
at: line 7, column 239
message: In the true branch `[ v i 1 prim + xs len longest-helper ]` of the `if` in `longest-helper`, `longest-helper` needs 6 values (maxrun:Int, currun:Int, i:Int, lastval:Int, xs:Seq Int, len:Int), but the branch has pushed only 4 values before it (`v`, the result of `prim +`, `xs` and `len`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `longest-helper`, exactly the values it takes, in this order: maxrun:Int, currun:Int, i:Int, lastval:Int, xs:Seq Int, len:Int. The branch already pushes `v`, the result of `prim +`, `xs` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `longest-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target has-pair-helper };

: has-pair-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } { i xs prim seq-int.len prim < [ xs i prim seq-int.at target prim - locals { needed } { i 1 prim + xs needed has-pair-inner } ] [ 0 ] if };

: has-pair-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many needed:Int^many -- ρ found:Bool^many)
  locals { j xs needed } { j xs prim seq-int.len prim < [ xs j prim seq-int.at locals { y } { y needed prim = [ 1 ] [ j 1 prim + xs needed has-pair-inner ] if } ] [ 0 ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: has-pair-helper
at: line 7, column 160
message: The two branches of `if` in `has-pair-helper` leave different stacks. Below the condition and the two quotations the stack is ρ; the true branch leaves ρ Bool and the false branch leaves ρ Int. `has-pair-helper` calls `has-pair-inner`, which has an error of its own; this report assumes `has-pair-inner` keeps its stack effect.
expected: ρ Bool
actual: ρ Int
hint: Both leave 1 value, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.branch-mismatch
word: has-pair-inner
at: line 11, column 157
message: The two branches of `if` in `has-pair-inner` leave different stacks. Below the condition and the two quotations the stack is .. Seq Int Int Int; the true branch leaves .. Seq Int Int Int Int and the false branch leaves .. Seq Int Int Int Bool.
expected: .. Seq Int Int Int Int
actual: .. Seq Int Int Int Bool
hint: Both leave 4 values, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 xs count-distinct-helper };

: count-distinct-helper
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { 0 seen v is-in [ seen i 1 prim + xs count-distinct-helper ] [ seen v prim seq-int.push i 1 prim + xs count-distinct-helper ] if } ] [ seen prim seq-int.len ] if };

: is-in
  (forall ρ; ρ idx:Int^many seq:Seq Int^many val:Int^many -- ρ found:Bool^many)
  locals { idx seq val } { idx seq prim seq-int.len prim < [ seq idx prim seq-int.at val prim = [ 1 ] [ idx 1 prim + seq val is-in ] if ] [ 0 ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-in
at: line 11, column 134
message: The two branches of `if` in `is-in` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ { } n digits-helper ] if };

: digits-helper
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { acc n } { n 0 prim < prim not [ n 10 prim mod acc prim seq-int.push n 10 prim div digits-helper ] [ acc ] if };

```
On the example, the run failed:
code: firth.syntax.empty-sequence
at: line 3, column 41
message: Unexpected the end of the input, expected `at least one element`.
expected: at least one element
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-helper };

: primes-helper
  (forall ρ; ρ acc:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { acc i n } { i n prim < [ i 2 is-prime [ acc i prim seq-int.push ] [ acc ] if i 1 prim + n primes-helper ] [ acc ] if };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ isprime:Bool^many)
  locals { num } { num 2 is-prime-test };

: is-prime-test
  (forall ρ; ρ num:Int^many div:Int^many -- ρ isprime:Bool^many)
  locals { num div } { div div prim * num prim < [ 1 ] [ num div prim mod 0 prim = [ 0 ] [ num div 1 prim + is-prime-test ] if ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: primes-helper
at: line 7, column 126
message: The two branches of the `if` in `primes-helper` whose true branch is `[ i 2 is-prime [ acc i prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `i` and the result of `primes-helper`; the false branch leaves `acc`.
hint: The true branch leaves 1 value more than the false branch: `i` is left below the result of `primes-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: is-prime-test
at: line 15, column 125
message: The two branches of `if` in `is-prime-test` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { k prim seq-int.empty 0 xs k hist-init };

: hist-init
  (forall ρ; ρ counts:Seq Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts idx xs k } { idx k prim < [ counts 0 prim seq-int.push idx 1 prim + xs k hist-init ] [ counts 0 xs hist-loop ] if };

: hist-loop
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + counts v prim seq-int.set i 1 prim + xs hist-loop } ] [ counts ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Int Seq Int.
expected: ρ Seq Int
actual: ρ Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: hist-loop
at: line 11, column 138
message: `prim seq-int.set` in `hist-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `counts` (Seq Int) and `v` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Seq Int Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `counts` is for `Seq Int`. Of the values of one type, `counts v prim seq-int.at 1 prim +` and `v` are for `Int` and `Int`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 0 sort-outer };

: sort-outer
  (forall ρ; ρ arr:Seq Int^many len:Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { arr len i } { i len 1 prim - prim < [ arr i 1 prim + len sort-inner ] [ arr ] if };

: sort-inner
  (forall ρ; ρ arr:Seq Int^many j:Int^many len:Int^many -- ρ sorted:Seq Int^many)
  locals { arr j len } { j len prim < [ arr j 1 prim - prim seq-int.at arr j prim seq-int.at prim < [ arr j arr j 1 prim - prim seq-int.at prim seq-int.set arr j 1 prim - arr j prim seq-int.at prim seq-int.set ] [ arr ] if j 1 prim + len sort-inner ] [ arr ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-inner
at: line 11, column 221
message: The two branches of the `if` in `sort-inner` whose true branch is `[ arr j arr j 1 prim - ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `prim seq-int.set`; the false branch leaves `arr`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `prim seq-int.set`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock { } { } 0 stock items qtys whole stock prim seq-int.len alloc-helper };

: alloc-helper
  (forall ρ; ρ cur-stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many n:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { cur-stock allocated reasons j stock items qtys whole n } { j n prim < [ items j prim seq-int.at cur-stock prim seq-int.at qtys j prim seq-int.at locals { item-idx } { locals { cur-val } { locals { qty } { cur-val qty prim < [ cur-val 0 prim = [ cur-stock allocated reasons 2 prim seq-int.push ] [ whole j prim seq-int.at [ cur-stock allocated reasons 3 prim seq-int.push ] [ cur-stock item-idx cur-val prim seq-int.set allocated cur-val prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] [ cur-stock item-idx qty prim - prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push ] if } } } j 1 prim + stock items qtys whole n alloc-helper ] [ cur-stock allocated reasons ] if };

```
On the example, the run failed:
code: firth.syntax.empty-sequence
at: line 3, column 45
message: Unexpected the end of the input, expected `at least one element`.
expected: at least one element
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
