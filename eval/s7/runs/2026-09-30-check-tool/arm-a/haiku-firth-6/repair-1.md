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
  0 locals { xs } { xs [ 0 prim seq-int.len ] call sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many len:Int^many idx:Int^many -- ρ result:Int^many)
  locals { sum xs len idx }
  idx len prim < [ idx xs prim seq-int.at idx 1 prim + locals { sum xs len idx } { sum idx xs prim seq-int.at prim + swap drop xs swap drop len swap drop idx 1 prim + sum-loop } ] [ sum ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `idx`, expected `{`.
expected: {
actual: idx
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs }
  xs 0 prim seq-int.at xs 1 xs prim seq-int.len find-max;

: find-max
  (forall ρ; ρ max:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { max xs idx len }
  idx len prim < [
    idx xs prim seq-int.at
    locals { val max xs idx len }
    max val prim < [ val ] [ max ] if
    locals { max xs idx len }
    idx 1 prim + find-max
  ] [ max ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
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
  locals { xs k }
  0 0 xs prim seq-int.len count-below-loop xs k;

: count-below-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx len xs k }
  idx len prim < [
    idx xs prim seq-int.at locals { val count idx len xs k }
    val k prim < [ count 1 prim + ] [ count ] if
    locals { count idx len xs k }
    idx 1 prim + count-below-loop xs k
  ] [ count ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `0`, expected `{`.
expected: {
actual: 0
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x }
  0 xs prim seq-int.len find-index xs x;

: find-index
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx len xs x }
  idx len prim < [
    idx xs prim seq-int.at locals { val idx len xs x }
    val x prim = [ idx ] [ idx 1 prim + find-index xs x ] if
  ] [ -1 ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `0`, expected `{`.
expected: {
actual: 0
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs }
  prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop xs;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx }
  idx 0 prim < [ result ] [
    idx xs prim seq-int.at locals { val result xs idx }
    result val prim seq-int.push
    locals { result xs idx }
    idx 1 prim - reverse-loop xs
  ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `prim`, expected `{`.
expected: {
actual: prim
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs }
  prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop xs;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum idx len xs }
  idx len prim < [
    idx xs prim seq-int.at locals { val result sum idx len xs }
    sum val prim + locals { newsum result idx len xs }
    result newsum prim seq-int.push locals { result idx len xs newsum }
    idx 1 prim + prefix-loop xs
  ] [ result ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `prim`, expected `{`.
expected: {
actual: prim
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
  locals { xs }
  prim seq-int.empty 0 xs prim seq-int.len keep-pos-loop xs;

: keep-pos-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx len xs }
  idx len prim < [
    idx xs prim seq-int.at locals { val result idx len xs }
    val 0 prim < [ result ] [ result val prim seq-int.push ] if
    locals { result idx len xs }
    idx 1 prim + keep-pos-loop xs
  ] [ result ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `prim`, expected `{`.
expected: {
actual: prim
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
  locals { xs }
  xs prim seq-int.len locals { len xs }
  len 1 prim < [ true ] [ 0 check-sorted xs ] if;

: check-sorted
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { idx xs }
  idx xs prim seq-int.len 1 prim - prim < [
    idx xs prim seq-int.at locals { val idx xs }
    idx 1 prim + xs prim seq-int.at locals { next idx xs }
    val next prim < [ idx 1 prim + check-sorted xs ] [ false ] if
  ] [ true ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys }
  0 0 xs prim seq-int.len dot-product xs ys;

: dot-product
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs ys }
  idx len prim < [
    idx xs prim seq-int.at idx ys prim seq-int.at prim * locals { prod sum idx len xs ys }
    sum prod prim + locals { sum idx len xs ys }
    idx 1 prim + dot-product xs ys
  ] [ sum ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `0`, expected `{`.
expected: {
actual: 0
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags }
  flags prim seq-bool.len locals { len flags }
  len 0 prim = [ true ] [ 0 check-all flags ] if;

: check-all
  (forall ρ; ρ idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { idx flags }
  idx flags prim seq-bool.len prim < [
    idx flags prim seq-bool.at [ idx 1 prim + check-all flags ] [ false ] if
  ] [ true ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `flags`, expected `{`.
expected: {
actual: flags
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs }
  xs prim seq-int.len locals { len xs }
  len 0 prim = [ 0 ] [ 0 xs prim seq-int.at 1 0 find-longest xs ] if;

: find-longest
  (forall ρ; ρ idx:Int^many prev:Int^many current:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx prev current max xs }
  idx xs prim seq-int.len prim < [
    idx xs prim seq-int.at locals { val idx prev current max xs }
    val prev prim = [
      current 1 prim + locals { current idx prev max xs }
      current max prim < [ max ] [ current ] if
      locals { max idx prev current xs }
      idx 1 prim + find-longest xs
    ] [
      idx 1 prim + find-longest xs
    ] if
  ] [ max ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target }
  0 xs prim seq-int.len check-pair xs target;

: check-pair
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target }
  i len prim < [
    i 1 prim + check-pair-inner xs target i
  ] [ false ] if;

: check-pair-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { j xs target i }
  j xs prim seq-int.len prim < [
    i j prim = [ j 1 prim + check-pair-inner xs target i ] [
      i xs prim seq-int.at j xs prim seq-int.at prim + locals { sum xs target i j }
      sum target prim = [ true ] [ j 1 prim + check-pair-inner xs target i ] if
    ] if
  ] [ false ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `0`, expected `{`.
expected: {
actual: 0
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs }
  0 0 xs prim seq-int.len count-distinct-loop xs;

: count-distinct-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx len xs }
  idx len prim < [
    idx xs prim seq-int.at locals { val count idx len xs }
    val 0 idx check-contains xs [ count ] [ count 1 prim + ] if
    locals { count idx len xs }
    idx 1 prim + count-distinct-loop xs
  ] [ count ] if;

: check-contains
  (forall ρ; ρ val:Int^many start:Int^many end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val start end xs }
  start end prim < [
    start xs prim seq-int.at locals { x val start end xs }
    x val prim = [ true ] [ start 1 prim + check-contains xs val ] if
  ] [ false ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `0`, expected `{`.
expected: {
actual: 0
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys }
  prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge-sorted-loop xs ys;

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xlen ylen xs ys }
  i xlen prim < [
    j ylen prim < [
      i xs prim seq-int.at j ys prim seq-int.at locals { xi yj result i j xlen ylen xs ys }
      xi yj prim < [
        result xi prim seq-int.push locals { result i j xlen ylen xs ys }
        i 1 prim + merge-sorted-loop xs ys
      ] [
        result yj prim seq-int.push locals { result i j xlen ylen xs ys }
        j 1 prim + merge-sorted-loop xs ys
      ] if
    ] [
      i xs prim seq-int.at locals { xi result i j xlen ylen xs ys }
      result xi prim seq-int.push locals { result i j xlen ylen xs ys }
      i 1 prim + merge-sorted-loop xs ys
    ] if
  ] [
    j ylen prim < [
      j ys prim seq-int.at locals { yj result i j xlen ylen xs ys }
      result yj prim seq-int.push locals { result i j xlen ylen xs ys }
      j 1 prim + merge-sorted-loop xs ys
    ] [ result ] if
  ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `prim`, expected `{`.
expected: {
actual: prim
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
  locals { n }
  n 0 prim = [ { 0 } ] [
    n 0 prim < [ n 0 prim - extract-digits ] [ n extract-digits ]
  ] if;

: extract-digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n }
  prim seq-int.empty n build-digits n;

: build-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n }
  n 0 prim = [ result ] [
    n 10 prim mod locals { d result n }
    result d prim seq-int.push locals { result n }
    n 10 prim div build-digits
  ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `n`, expected `{`.
expected: {
actual: n
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
  locals { n }
  prim seq-int.empty 2 n find-primes;

: find-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { result candidate limit }
  candidate limit prim < [
    candidate is-prime [ result candidate prim seq-int.push ] [ result ] if
    locals { result candidate limit }
    candidate 1 prim + find-primes
  ] [ result ] if;

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n }
  n 2 prim < [ false ] [
    n 2 prim = [ true ] [
      n 2 prim mod 0 prim = [ false ] [ 2 check-divisors n ] if
    ] if
  ] if;

: check-divisors
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ result:Bool^many)
  locals { divisor n }
  divisor divisor prim * n prim < [
    n divisor prim mod 0 prim = [ false ] [ divisor 1 prim + check-divisors n ] if
  ] [ true ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `prim`, expected `{`.
expected: {
actual: prim
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k }
  prim seq-int.empty 0 k build-histogram xs k;

: build-histogram
  (forall ρ; ρ counts:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { counts idx k xs }
  idx k prim < [
    counts 0 prim seq-int.push locals { counts idx k xs }
    idx 1 prim + build-histogram xs k
  ] [
    0 xs prim seq-int.len count-histogram xs k counts
  ] if;

: count-histogram
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i len xs k counts }
  i len prim < [
    i xs prim seq-int.at locals { val i len xs k counts }
    val counts prim seq-int.at 1 prim + locals { newcnt i len xs k counts }
    counts val newcnt prim seq-int.set locals { counts i len xs k }
    i 1 prim + count-histogram xs k counts
  ] [ counts ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `prim`, expected `{`.
expected: {
actual: prim
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs }
  xs 0 xs prim seq-int.len 1 prim - insertion-sort;

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many start:Int^many end:Int^many -- ρ sorted:Seq Int^many)
  locals { xs start end }
  start end prim < [
    start 1 prim + locals { i xs start end }
    xs i insert-element
    locals { xs start end }
    start 1 prim + insertion-sort xs
  ] [ xs ] if;

: insert-element
  (forall ρ; ρ xs:Seq Int^many pos:Int^many -- ρ xs:Seq Int^many)
  locals { xs pos }
  pos 0 prim > [
    pos xs prim seq-int.at locals { val xs pos }
    pos 1 prim - xs prim seq-int.at locals { prev xs pos }
    prev val prim < [
      xs pos
    ] [
      xs pos prev prim seq-int.set locals { xs pos }
      pos 1 prim - insert-element xs
    ] if
  ] [ xs ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs }
  start 0 0 txs prim seq-int.len process-txs txs;

: process-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected idx len txs }
  idx len prim < [
    idx txs prim seq-int.at locals { tx balance rejected idx len txs }
    balance tx prim + 0 prim < [
      rejected 1 prim + locals { rejected idx len txs balance }
      idx 1 prim + process-txs txs
    ] [
      balance tx prim + locals { balance idx len txs rejected }
      idx 1 prim + process-txs txs
    ] if
  ] [ balance rejected ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `start`, expected `{`.
expected: {
actual: start
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
  locals { stock items qtys whole }
  stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len process-orders stock items qtys whole;

: process-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons idx len items qtys whole }
  idx len prim < [
    idx items prim seq-int.at locals { item stock allocated reasons idx len items qtys whole }
    item stock prim seq-int.at locals { qty_stock stock allocated reasons idx len items qtys whole }
    idx qtys prim seq-int.at locals { req stock allocated reasons idx len items qtys whole }
    idx whole prim seq-bool.at locals { w stock allocated reasons idx len items qtys whole }
    req qty_stock prim < [
      qty_stock 0 prim = [
        reasons 2 prim seq-int.push allocated 0 prim seq-int.push
      ] [
        w [ reasons 3 prim seq-int.push allocated 0 prim seq-int.push ] [
          reasons 1 prim seq-int.push allocated qty_stock prim seq-int.push stock item 0 prim seq-int.set
        ] if
      ] if
      locals { stock allocated reasons idx len items qtys whole }
      idx 1 prim + process-orders stock items qtys whole
    ] [
      reasons 0 prim seq-int.push allocated req prim seq-int.push stock item qty_stock req prim - prim seq-int.set
      locals { stock allocated reasons idx len items qtys whole }
      idx 1 prim + process-orders stock items qtys whole
    ] if
  ] [ stock allocated reasons ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `stock`, expected `{`.
expected: {
actual: stock
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
