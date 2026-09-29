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
  locals { xs } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap dup 1 prim - swap xs swap prim seq-int.at prim + swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 101
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves nothing, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    [ xs prim seq-int.len 1 prim - ] call
    [ dup 0 prim = [ drop ] [ dup xs swap prim seq-int.at swap 2 swap prim - [ prim > [ swap ] [ drop ] if ] dip 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 6, column 80
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap dup 1 prim - swap xs swap prim seq-int.at k prim < [ 1 prim + ] [ ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 123
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves nothing, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop -1 ] [ dup xs swap prim seq-int.at x prim = [ swap drop ] [ swap 1 prim + swap 1 prim - ] if ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 117
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The `if` takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    [ xs prim seq-int.len 1 prim - ] call
    [ dup 0 prim < [ drop ] [ swap xs swap prim seq-int.at prim seq-int.push swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 94
message: The false branch of `if` in `main` cannot run on the stack it is given. Below the condition and the two quotations the stack is .. Int, but the false branch takes .. Int Int Seq Int.
expected: .. Int Int Seq Int
actual: .. Int
hint: The top value there is Int, but the false branch expects Seq Int. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap swap xs swap prim seq-int.at prim + dup swap prim seq-int.push swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 7, column 81
message: `prim seq-int.push` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int.
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top is Int but `prim seq-int.push` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ dup xs swap prim seq-int.at dup 0 prim < [ drop drop ] [ prim seq-int.push ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 108
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves nothing, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    true
    [ xs prim seq-int.len 1 prim - ] call
    [ dup 0 prim = [ drop ] [ xs swap dup prim seq-int.at xs swap 1 prim + prim seq-int.at prim < [ drop false ] [ 1 prim - ] if ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
at: line 6, column 43
message: The quotation run by `dip` in `main` does not accept the stack below it (.. ?t21 Seq Int Seq Int ?t21 [ .. ?t21 Seq Int Int -- .. ?t21 Int ]).
expected: Int
actual: Seq Int
hint: Check what the quotation body consumes against the values available under it.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap dup 1 prim - swap xs swap prim seq-int.at ys swap prim seq-int.at prim * prim + swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.expected-quotation
at: line 6, column 137
message: `compose` in `main` needs a quotation, but the stack before it is ρ Int Int [ .. Int Int Int -- .. Int Int ].
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true
    [ flags prim seq-bool.len ] call
    [ dup 0 prim = [ drop ] [ flags swap prim seq-bool.at [ drop false ] [ ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 97
message: The two branches of `if` in `main` leave different stacks. Below the condition and the two quotations the stack is .. Int Bool Int; the true branch leaves .. Int Bool and the false branch leaves .. Bool Int.
expected: .. Int Bool
actual: .. Bool Int
hint: Both leave 2 values, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [ 0 ] [ 1 1 1 [ xs prim seq-int.len 1 prim - ] call [ dup 0 prim = [ drop ] [ xs swap dup prim seq-int.at xs swap 1 prim + prim seq-int.at prim = [ swap 1 prim + swap dup swap [ prim > [ swap ] [ drop ] if ] dip 1 prim - ] [ swap drop 1 swap 1 prim - ] if ] if ] compose [ dup 0 prim < [ drop drop drop ] call ] call ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 4, column 212
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ xs swap dup prim seq-int.at target swap prim - [ xs prim seq-int.len ] call [ dup 0 prim = [ drop ] [ xs swap prim seq-int.at prim = [ drop true ] [ 1 prim - ] if ] if ] compose [ dup 0 prim < [ drop ] call ] call [ drop true ] [ 1 prim - ] if ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 196
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves nothing, and the false branch takes 3 values from the stack below the `if` and leaves 1 value. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ xs swap prim seq-int.at dup [ dup prim seq-int.len ] call [ dup 0 prim = [ drop false ] [ dup xs swap prim seq-int.at prim = [ drop true ] [ 1 prim - ] if ] if ] compose [ dup 0 prim < [ drop ] call ] call [ prim seq-int.push ] [ drop ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
    prim seq-int.len
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 188
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0 0
    [ xs prim seq-int.len ys prim seq-int.len prim + ] call
    [ dup 0 prim = [ drop drop drop ] [ dup swap dup 0 prim = [ drop xs swap prim seq-int.at prim seq-int.push swap 1 prim + ] [ dup xs prim seq-int.len prim = [ drop ys swap prim seq-int.at prim seq-int.push 1 prim + ] [ xs swap prim seq-int.at ys swap prim seq-int.at [ prim < ] dip [ prim seq-int.push swap 1 prim + ] [ prim seq-int.push 1 prim + ] if ] if ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 7, column 358
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch takes 5 values from the stack below the `if` and leaves 2 values. The false branch takes 4 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [ { 0 } ] [ prim seq-int.empty n [ dup 0 prim = [ drop ] [ dup 10 prim mod prim seq-int.push swap 10 prim div swap ] if ] compose [ dup 0 prim < [ drop ] call ] call [ dup prim seq-int.len 1 prim - ] call [ dup 0 prim < [ drop ] [ prim seq-int.len 1 prim - swap dup prim seq-int.at swap prim seq-int.len 1 prim - prim seq-int.at swap 0 swap prim seq-int.set dup prim seq-int.len 1 prim - prim seq-int.set 1 prim - ] if ] compose [ dup 0 prim < [ drop ] call ] call ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 4, column 133
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves nothing, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    2
    [ n 1 prim + ] call
    [ dup 0 prim = [ drop ] [ dup dup 1 prim - [ 1 0 swap [ dup 1 prim = [ drop ] [ dup 2 prim < [ swap drop 1 swap 1 prim - ] [ dup 2 prim * swap prim > [ swap 1 swap 1 prim - ] [ drop 0 ] if ] if ] if ] compose [ dup 0 prim < [ drop ] call ] call ] [ prim seq-int.push ] [ drop ] if swap 1 prim + ] if ] compose [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 7, column 148
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    [ k 0 ] call [ prim seq-int.empty prim seq-int.push ] compose [ dup 0 prim < [ drop ] call ] call
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ xs swap prim seq-int.at dup prim seq-int.at 1 prim + swap prim seq-int.set swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 122
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves nothing, and the false branch takes 4 values from the stack below the `if` and leaves 2 values. The false branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
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
  locals { xs } {
    xs
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ dup 1 prim - [ 0 swap ] call [ dup 0 prim = [ drop drop ] [ dup swap dup prim seq-int.at dup 1 prim + prim seq-int.at [ prim > ] dip [ dup prim seq-int.at swap 1 prim + prim seq-int.at swap 0 swap prim seq-int.set dup 1 prim + prim seq-int.set ] [ drop ] if 1 prim + ] if ] compose [ dup 0 prim < [ drop ] call ] call 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
at: line 6, column 151
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0
    [ txs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ txs swap prim seq-int.at dup swap dup prim + 0 prim < [ drop 1 prim + ] [ prim + ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.expected-quotation
at: line 6, column 138
message: `compose` in `main` needs a quotation, but the stack before it is ρ Int Int Int [ .. Int Int Int -- .. Int Int ].
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

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
    stock prim seq-int.empty prim seq-int.empty
    [ qtys prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ dup 1 prim - items swap prim seq-int.at stock swap prim seq-int.at dup qtys swap prim seq-int.at dup [ prim < ] dip [ swap 0 prim = [ drop drop 2 ] [ whole swap prim seq-bool.at [ drop drop 3 ] [ swap prim seq-int.push swap 1 ] if ] if ] [ swap prim seq-int.push 0 ] if swap prim seq-int.push swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop drop drop ] call ] call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 6, column 259
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 3 values from the stack below the `if` and leaves 3 values. The false branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
