Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc }
  [ i xs prim seq-int.len prim < ]
  [ acc xs i prim seq-int.at prim + i 1 prim + xs sum-loop ]
  [ acc ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  xs 0 0 sum-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-max:Int^many -- ρ max:Int^many)
  locals { xs i mx }
  [ i xs prim seq-int.len prim < ]
  [
    xs i prim seq-int.at
    [ mx prim < ] [ xs i prim seq-int.at ] [ mx ] if
    i 1 prim + xs max-loop
  ]
  [ mx ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 xs 0 prim seq-int.at max-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ count:Int^many)
  locals { xs k i cnt }
  [ i xs prim seq-int.len prim < ]
  [
    [ xs i prim seq-int.at k prim < ] [ cnt 1 prim + ] [ cnt ] if
    i 1 prim + xs k count-loop
  ]
  [ cnt ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k }
  xs k xs k 0 count-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i }
  [ i xs prim seq-int.len prim < ]
  [
    [ xs i prim seq-int.at x prim = ] [ i ] [ i 1 prim + xs x index-loop ] if
  ]
  [ -1 ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x }
  xs x xs x 0 index-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result }
  [ i 0 prim < ]
  [ result xs i prim seq-int.at prim seq-int.push i 1 prim - xs reverse-loop ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i acc result }
  [ i xs prim seq-int.len prim < ]
  [
    acc xs i prim seq-int.at prim +
    dup result swap prim seq-int.push
    i 1 prim + xs prefix-loop
  ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  xs 0 0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result }
  [ i xs prim seq-int.len prim < ]
  [
    [ xs i prim seq-int.at 0 prim < prim not ]
    [ result xs i prim seq-int.at prim seq-int.push ]
    [ result ]
    if
    i 1 prim + xs keep-loop
  ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  xs 0 prim seq-int.empty keep-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i }
  [ i xs prim seq-int.len 1 prim - prim < ]
  [
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not ]
    [ i 1 prim + xs sorted-loop ]
    [ false ]
    if
  ]
  [ true ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  [ xs prim seq-int.len 1 prim <= ] [ true ] [ xs 0 sorted-loop ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc }
  [ i xs prim seq-int.len prim < ]
  [
    acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
    i 1 prim + xs ys dot-loop
  ]
  [ acc ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys }
  xs ys xs ys 0 0 dot-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i }
  [ i flags prim seq-bool.len prim < ]
  [
    [ flags i prim seq-bool.at prim not ]
    [ false ]
    [ i 1 prim + flags all-loop ]
    if
  ]
  [ true ]
  if;

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  [ flags prim seq-bool.len 0 prim = ] [ true ] [ flags 0 all-loop ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many run-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { xs i run-len max-len }
  [ i xs prim seq-int.len prim < ]
  [
    [ xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim = ]
    [ run-len 1 prim + ]
    [ 1 ]
    if
    dup [ run-len prim < ] [ max-len ] [ run-len ] if
    i 1 prim + xs run-loop
  ]
  [ max-len ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  [ xs prim seq-int.len 0 prim <= ] [ 0 ] [ xs 1 1 0 run-loop ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j }
  [ j xs prim seq-int.len prim < ]
  [
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = ]
    [ true ]
    [ j 1 prim + xs target i has-pair-sum ]
    if
  ]
  [ false ]
  if;

: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i }
  [ i xs prim seq-int.len 1 prim - prim < ]
  [
    [ i 1 prim + xs target i inner-loop ]
    [ true ]
    [ i 1 prim + xs target has-pair-sum ]
    if
  ]
  [ false ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target }
  xs target xs target 0 has-pair-sum;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-count
  (forall ρ; ρ xs:Seq Int^many val:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs val i }
  [ i xs prim seq-int.len prim < ]
  [
    [ xs i prim seq-int.at val prim = ]
    [ true ]
    [ i 1 prim + xs val inner-count ]
    if
  ]
  [ false ]
  if;

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ cnt:Int^many)
  locals { xs i count }
  [ i xs prim seq-int.len prim < ]
  [
    [ i 1 prim + xs xs i prim seq-int.at inner-count ]
    [ count 1 prim + ]
    [ count ]
    if
    i 1 prim + xs distinct-loop
  ]
  [ count ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  [ xs prim seq-int.len 0 prim = ] [ 0 ] [ xs 0 0 distinct-loop ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result }
  [ i xs prim seq-int.len prim < ] [ j ys prim seq-int.len prim < ] prim and
  [
    [ xs i prim seq-int.at ys j prim seq-int.at prim < ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim + ys xs merge-loop ]
    [ result ys j prim seq-int.at prim seq-int.push j 1 prim + xs ys merge-loop ]
    if
  ]
  [
    [ i xs prim seq-int.len prim < ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim + ys xs merge-loop ]
    [
      [ j ys prim seq-int.len prim < ]
      [ result ys j prim seq-int.at prim seq-int.push j 1 prim + xs ys merge-loop ]
      [ result ]
      if
    ]
    if
  ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys }
  prim seq-int.empty xs ys xs ys 0 0 merge-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result }
  [ n 0 prim < prim not ]
  [ n 10 prim mod result swap prim seq-int.push n 10 prim div digits-loop ]
  [ result ]
  if;

: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many rev:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result i rev }
  [ i 0 prim < ]
  [ rev result i prim seq-int.at prim seq-int.push i 1 prim - result reverse-digits ]
  [ rev ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  [ n 0 prim = ] [ prim seq-int.empty 0 prim seq-int.push ] [ n prim seq-int.empty digits-loop ] if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d }
  [ d d prim * n prim < ]
  [
    [ n d prim mod 0 prim = ]
    [ false ]
    [ d 1 prim + n is-prime-check ]
    if
  ]
  [ true ]
  if;

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  [ n 2 prim < ]
  [ false ]
  [ n 2 is-prime-check ]
  if;

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result }
  [ i n prim < ]
  [
    [ i is-prime ]
    [ result i prim seq-int.push ]
    [ result ]
    if
    i 1 prim + n primes-loop
  ]
  [ result ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  n 2 prim seq-int.empty primes-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs k i counts }
  [ i xs prim seq-int.len prim < ]
  [
    xs i prim seq-int.at
    dup
    counts swap prim seq-int.at 1 prim +
    counts swap swap prim seq-int.set
    i 1 prim + xs k histogram-loop
  ]
  [ counts ]
  if;

: make-zeros
  (forall ρ; ρ k:Int^many i:Int^many zeros:Seq Int^many -- ρ zeros:Seq Int^many)
  locals { k i zeros }
  [ i k prim < ]
  [ zeros 0 prim seq-int.push i 1 prim + k make-zeros ]
  [ zeros ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k }
  k 0 prim seq-int.empty make-zeros xs k 0 histogram-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int^many x:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted x i }
  [ i sorted prim seq-int.len prim < ]
  [
    [ sorted i prim seq-int.at x prim < ]
    [ sorted i x prim seq-int.set i 1 prim + sorted x insert-sorted ]
    [ sorted i prim - prim seq-int.empty prim seq-int.empty ]
    if
  ]
  [ sorted x prim seq-int.push ]
  if;

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i sorted }
  [ i xs prim seq-int.len prim < ]
  [
    sorted xs i prim seq-int.at i sorted insert-sorted
    i 1 prim + xs sort-loop
  ]
  [ sorted ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs i balance rejected }
  [ i txs prim seq-int.len prim < ]
  [
    [ balance txs i prim seq-int.at prim + 0 prim < ]
    [ rejected 1 prim + ]
    [ balance txs i prim seq-int.at prim + ]
    if
    i 1 prim + start txs ledger-loop
  ]
  [ balance rejected ]
  if;

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs }
  start txs start txs 0 0 ledger-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons }
  [ i qtys prim seq-int.len prim < ]
  [
    items i prim seq-int.at
    stock swap prim seq-int.at
    qtys i prim seq-int.at
    locals { item-idx current-stock qty }
    [
      [ qty current-stock prim < ]
      [ allocated qty prim seq-int.push reasons 0 prim seq-int.push ]
      [
        [ current-stock 0 prim = ]
        [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ]
        [
          [ whole i prim seq-bool.at ]
          [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]
          [ allocated current-stock prim seq-int.push reasons 1 prim seq-int.push ]
          if
        ]
        if
      ]
      if
      stock item-idx current-stock qty prim - prim seq-int.set
    ]
    i 1 prim + stock items qtys whole allocate-loop
  ]
  [ allocated reasons ]
  if;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole }
  stock items qtys whole stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  stock;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `[`, expected `{`.
expected: {
actual: [
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
