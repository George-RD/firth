Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ r:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup max prim < [ ] [ drop max ] if i 1 prim + xs [ swap ] dip max-loop ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)
  dup 0 prim seq-int.at 1 swap max-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 90
message: `max-loop` in `max-loop` needs Seq Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int.
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: The top value is Seq Int but `max-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ r:Int^many)
  locals { xs k i cnt } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if i 1 prim + xs k [ swap swap ] dip count-loop ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ r:Int^many)
  swap 0 0 swap count-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 99
message: `count-loop` in `count-loop` needs Seq Int Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int Int.
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: The second value from the top is Seq Int but `count-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ r:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at x prim = [ i ] [ i 1 prim + xs x find-loop ] if ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ r:Int^many)
  swap 0 swap find-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 61
message: `find-loop` in `find-loop` needs Seq Int Int Int on top of the stack, but the stack before it is .. Int ?t57 ?t56.
expected: .. Seq Int Int Int
actual: .. Int ?t57 ?t56
hint: The top value is ?t56 but `find-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: rev-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - xs [ swap ] dip rev-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Seq Int^many)
  dup prim seq-int.len 1 prim - prim seq-int.empty rev-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 5, column 35
message: `prim seq-int.push` in `rev-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t20.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: The top value is ?t20 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + dup result prim seq-int.push i 1 prim + xs [ swap swap ] dip prefix-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Seq Int^many)
  dup 0 0 prim seq-int.empty [ swap swap swap ] dip prefix-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 5, column 50
message: `prim seq-int.push` in `prefix-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int Int ?t35.
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t35
hint: The top value is ?t35 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup 0 prim < [ drop ] [ result prim seq-int.push ] if i 1 prim + xs [ swap ] dip filter-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Seq Int^many)
  dup 0 prim seq-int.empty [ swap ] dip filter-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 5, column 79
message: The two branches of the `if` in `filter-loop` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ r:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [ i 1 prim + xs check-loop ] if ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Bool^many)
  dup 0 swap check-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 91
message: `check-loop` in `check-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Int ?t35.
expected: .. Seq Int Int
actual: .. Int ?t35
hint: The top value is ?t35 but `check-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + i 1 prim + xs ys [ swap swap ] dip dot-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ r:Int^many)
  swap 0 0 swap dot-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 102
message: `dot-loop` in `dot-loop` needs Seq Int Seq Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int Seq Int.
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: The top value is Seq Int but `dot-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ r:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at [ i 1 prim + flags all-loop ] [ false ] if ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ r:Bool^many)
  dup 0 swap all-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 51
message: `all-loop` in `all-loop` needs Seq Bool Int on top of the stack, but the stack before it is .. Int ?t27.
expected: .. Seq Bool Int
actual: .. Int ?t27
hint: The top value is ?t27 but `all-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many cur:Int^many last:Int^many -- ρ r:Int^many)
  locals { xs i max cur last } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup last prim = [ cur 1 prim + dup max prim < [ max ] [ ] if ] [ 1 ] if
      i 1 prim + xs [ swap swap swap ] dip run-loop ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)
  dup prim seq-int.len 0 prim = [ drop 0 ] [ dup 0 prim seq-int.at dup 1 0 0 swap run-loop ] if;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 5, column 86
message: The two branches of the `if` in `run-loop` whose true branch is `[ max ]` leave different numbers of values. The true branch leaves `max`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `max` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ r:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at target prim - i 1 prim + xs target has-inner ] [ false ] if
  };

: has-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many needed:Int^many i:Int^many -- ρ r:Bool^many)
  locals { xs target needed i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at needed prim = [ true ] [ i 1 prim + xs target needed has-inner ] if ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ r:Bool^many)
  swap 0 swap outer-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 5, column 63
message: `has-inner` in `outer-loop` needs Seq Int Int Int Int on top of the stack, but the stack before it is .. Int Int Seq Int Int.
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: The second value from the top is Seq Int but `has-inner` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-in
  (forall ρ; ρ x:Int^many seen:Seq Int^many j:Int^many -- ρ r:Bool^many)
  locals { x seen j } {
    j seen prim seq-int.len prim <
    [ seen j prim seq-int.at x prim = [ true ] [ j 1 prim + x seen count-in ] if ]
    [ false ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ r:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup 0 seen count-in [ seen prim seq-int.push ] [ drop ] if i 1 prim + xs [ swap ] dip count-loop ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)
  dup 0 prim seq-int.empty count-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 84
message: The two branches of the `if` in `count-loop` whose true branch is `[ seen prim seq-int.push ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim < 
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys j [ swap swap ] dip merge-loop ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + xs ys i [ swap swap ] dip merge-loop ]
      if ]
    [ i xs prim seq-int.len prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys j [ swap swap ] dip merge-loop ]
      [ j ys prim seq-int.len prim < [ ys j prim seq-int.at result prim seq-int.push j 1 prim + xs ys i [ swap swap ] dip merge-loop ]
        [ result ] if ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ r:Seq Int^many)
  swap 0 0 prim seq-int.empty [ swap swap swap ] dip merge-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 6, column 37
message: `prim seq-int.push` in `merge-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t111 ?t110 Int ?t112.
expected: .. Seq Int Int
actual: .. Seq Int Int ?t111 ?t110 Int ?t112
hint: The top value is ?t112 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ r:Seq Int^many)
  locals { n result } {
    n 0 prim = [ result ] [ n 10 prim mod result prim seq-int.push n 10 prim div digit-loop ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  dup 0 prim = [ drop { 0 } ] [ prim seq-int.empty digit-loop ] if;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 4, column 50
message: `prim seq-int.push` in `digit-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t19.
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
  (forall ρ; ρ n:Int^many d:Int^many -- ρ r:Bool^many)
  locals { n d } {
    d d prim * n prim < [ n d prim mod 0 prim = [ false ] [ d 1 prim + n is-prime ] if ] [ true ] if
  };

: collect-primes
  (forall ρ; ρ limit:Int^many n:Int^many result:Seq Int^many -- ρ r:Seq Int^many)
  locals { limit n result } {
    n limit prim < [ n 2 prim < [ n 1 prim + limit n [ swap swap ] dip collect-primes ]
      [ n 2 is-prime [ result prim seq-int.push n 1 prim + limit n [ swap swap ] dip collect-primes ]
        [ n 1 prim + limit n [ swap swap ] dip collect-primes ] if ] if ]
    [ result ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  2 prim seq-int.empty collect-primes;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 10, column 72
message: `collect-primes` in `collect-primes` needs Int Int Seq Int on top of the stack, but the stack before it is .. Int Int Int.
expected: .. Int Int Seq Int
actual: .. Int ?t38 Int
hint: The top value is Int but `collect-primes` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-hist
  (forall ρ; ρ k:Int^many j:Int^many hist:Seq Int^many -- ρ r:Seq Int^many)
  locals { k j hist } {
    j k prim < [ 0 hist prim seq-int.push j 1 prim + k [ swap ] dip init-hist ] [ hist ] if
  };

: hist-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many hist:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs k i hist } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup hist swap prim seq-int.at 1 prim + [ swap ] dip prim seq-int.set i 1 prim + xs k [ swap ] dip hist-loop ]
    [ hist ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  swap prim seq-int.empty 0 [ swap swap ] dip init-hist swap 0 swap hist-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 5
message: In the true branch `[ xs i prim seq-int.at dup hist swap ...` of the `if` in `hist-loop`, `swap` (inside a quotation in that branch) needs 2 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ x:Int^many result:Seq Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { x result j } {
    j result prim seq-int.len prim < x result j prim seq-int.at prim < prim and
    [ result j prim seq-int.at insert-sorted x prim drop j 1 prim + result [ swap ] dip insert-sorted ]
    [ x result j prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at result 0 insert-sorted i 1 prim + xs [ swap ] dip sort-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Seq Int^many)
  dup 0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 5, column 53
message: Unexpected `drop`, expected `primitive name`.
expected: primitive name
actual: drop
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ b:Int^many r:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at dup balance prim + 0 prim < 
      [ drop rejected 1 prim + i 1 prim + balance txs [ swap swap ] dip ledger-loop ]
      [ balance prim + i 1 prim + balance txs [ swap swap ] dip ledger-loop ]
      if ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ b:Int^many r:Int^many)
  swap 0 swap ledger-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 6, column 73
message: `ledger-loop` in `ledger-loop` needs Int Seq Int Int Int on top of the stack, but the stack before it is .. Int Int ?t78 ?t80.
expected: .. Int Seq Int Int Int
actual: .. Int Int ?t78 ?t80
hint: The top value is ?t80 but `ledger-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: alloc-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many res:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at stock swap prim seq-int.at dup qtys i prim seq-int.at prim < 
      [ qtys i prim seq-int.at stock [ swap ] dip prim seq-int.set allocated prim seq-int.push 0 reasons prim seq-int.push ]
      [ dup 0 prim = [ 2 reasons prim seq-int.push ] 
        [ whole i prim seq-int.at [ 3 reasons prim seq-int.push ] [ dup allocated prim seq-int.push 1 reasons prim seq-int.push ] if ] 
        if ]
      if 
      i 1 prim + [ swap swap swap ] dip alloc-loop ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ s:Seq Int^many a:Seq Int^many res:Seq Int^many)
  swap swap prim seq-int.empty prim seq-int.empty 0 [ swap swap swap swap ] dip alloc-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 8, column 131
message: The two branches of `if` in `alloc-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 3 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
