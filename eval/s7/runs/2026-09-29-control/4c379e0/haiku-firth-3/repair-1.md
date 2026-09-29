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
  locals { xs } { 0 xs sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many -- ρ total:Int^many)
  locals { sum xs }
  { xs prim seq-int.len 0 prim = }
  [ sum ]
  [ xs 0 prim seq-int.at sum prim + xs drop-first sum-loop ]
  if;

: drop-first
  (forall ρ; ρ xs:Seq Int^many -- ρ rest:Seq Int^many)
  locals { xs }
  { prim seq-int.empty xs prim seq-int.len 1 prim - build-rest 0 };

: build-rest
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Seq Int^many)
  locals { result xs i max }
  { i max prim = }
  [ result ]
  [ result xs i prim 1 prim + prim seq-int.at prim seq-int.push i prim 1 prim + xs max build-rest ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 23, column 22
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs } { xs 0 prim seq-int.at xs 1 max-loop };

: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ largest:Int^many)
  locals { max xs i }
  { i xs prim seq-int.len prim = }
  [ max ]
  [ max xs i prim seq-int.at max-one xs i prim 1 prim + max-loop ]
  if;

: max-one
  (forall ρ; ρ max:Int^many next:Int^many -- ρ result:Int^many)
  locals { max next }
  { next max prim < }
  [ max ]
  [ next ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 48
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs k } { 0 xs k 0 count-loop };

: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs k i }
  { i xs prim seq-int.len prim = }
  [ count ]
  [ xs i prim seq-int.at k prim < [ count prim 1 prim + ] [ count ] if xs k i prim 1 prim + count-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 48
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs x } { xs x 0 find-index };

: find-index
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i }
  { i xs prim seq-int.len prim = }
  [ -1 ]
  [ xs i prim seq-int.at x prim = [ i ] [ xs x i prim 1 prim + find-index ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 55
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i }
  { i 0 prim < }
  [ result ]
  [ result xs i prim seq-int.at prim seq-int.push xs i prim 1 prim - reverse-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 61
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i }
  { i xs prim seq-int.len prim = }
  [ result ]
  [ sum xs i prim seq-int.at prim + result swap prim seq-int.push swap xs i prim 1 prim + prefix-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 82
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs } { prim seq-int.empty xs 0 filter-loop };

: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i }
  { i xs prim seq-int.len prim = }
  [ result ]
  [ xs i prim seq-int.at dup 0 prim < [ drop result ] [ result swap prim seq-int.push swap ] if xs i prim 1 prim + filter-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 107
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  { xs prim seq-int.len 1 prim < }
  [ true ]
  [ true xs 0 check-sorted ]
  if;

: check-sorted
  (forall ρ; ρ ok:Bool^many xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { ok xs i }
  { ok prim not }
  [ false ]
  [ { i prim 1 prim + xs prim seq-int.len prim = } [ ok ] [ xs i prim seq-int.at xs i prim 1 prim + prim seq-int.at prim < prim not ok prim and xs i prim 1 prim + check-sorted ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 14, column 7
message: Unexpected `i`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: i
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
  locals { xs ys } { 0 xs ys 0 dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ product:Int^many)
  locals { sum xs ys i }
  { i xs prim seq-int.len prim = }
  [ sum ]
  [ sum xs i prim seq-int.at ys i prim seq-int.at prim * prim + xs ys i prim 1 prim + dot-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 78
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { flags } { true flags 0 check-all };

: check-all
  (forall ρ; ρ ok:Bool^many flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { ok flags i }
  { ok prim not }
  [ false ]
  [ { i flags prim seq-bool.len prim = } [ ok ] [ ok flags i prim seq-bool.at prim and flags i prim 1 prim + check-all ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 10, column 7
message: Unexpected `i`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: i
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
  { xs prim seq-int.len 0 prim = }
  [ 0 ]
  [ 1 xs 0 prim seq-int.at 1 longest-run-loop ]
  if;

: longest-run-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many prev:Int^many i:Int^many -- ρ length:Int^many)
  locals { max xs prev i }
  { i xs prim seq-int.len prim = }
  [ max ]
  [ xs i prim seq-int.at dup prev prim = [ drop i prim 1 prim - max-one xs prev i prim 1 prim + longest-run-loop ] [ swap drop 1 xs swap i prim 1 prim + longest-run-loop ] if ]
  if;

: max-one
  (forall ρ; ρ run:Int^many max:Int^many -- ρ result:Int^many)
  locals { run max }
  { run max prim < }
  [ max ]
  [ run ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 14, column 56
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs target } { false xs target 0 search-pair };

: search-pair
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { found xs target i }
  { found }
  [ true ]
  [ { i xs prim seq-int.len prim = } [ found ] [ xs i prim seq-int.at target prim - xs i prim 1 prim + find-complement xs target search-pair ] if ]
  if;

: find-complement
  (forall ρ; ρ complement:Int^many xs:Seq Int^many start:Int^many target:Int^many -- ρ found:Bool^many)
  locals { complement xs start target }
  { start xs prim seq-int.len prim = }
  [ false ]
  [ xs start prim seq-int.at complement prim = [ true ] [ xs complement start prim 1 prim + find-complement ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 10, column 7
message: Unexpected `i`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: i
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
  locals { xs } { prim seq-int.empty xs 0 collect-distinct };

: collect-distinct
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ count:Int^many)
  locals { seen xs i }
  { i xs prim seq-int.len prim = }
  [ seen prim seq-int.len ]
  [ xs i prim seq-int.at seen is-in-seq [ seen xs i prim 1 prim + collect-distinct ] [ seen xs i prim seq-int.at prim seq-int.push xs i prim 1 prim + collect-distinct ] if ]
  if;

: is-in-seq
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { val seq }
  { seq prim seq-int.len 0 prim = }
  [ false ]
  [ val seq 0 find-in-seq ]
  if;

: find-in-seq
  (forall ρ; ρ val:Int^many seq:Seq Int^many i:Int^many -- ρ found:Bool^many)
  locals { val seq i }
  { i seq prim seq-int.len prim = }
  [ false ]
  [ seq i prim seq-int.at val prim = [ true ] [ val seq i prim 1 prim + find-in-seq ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 58
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j }
  { i xs prim seq-int.len prim = }
  [ result ys j copy-rest ]
  [ { j ys prim seq-int.len prim = } [ result xs i copy-rest ] [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push xs ys i prim 1 prim + j merge-loop ] [ result ys j prim seq-int.at prim seq-int.push xs ys i j prim 1 prim + merge-loop ] if ] if ]
  if;

: copy-rest
  (forall ρ; ρ result:Seq Int^many remaining:Seq Int^many pos:Int^many -- ρ merged:Seq Int^many)
  locals { result remaining pos }
  { pos remaining prim seq-int.len prim = }
  [ result ]
  [ result remaining pos prim seq-int.at prim seq-int.push remaining pos prim 1 prim + copy-rest ]
  if;

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 10, column 7
message: Unexpected `j`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: j
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
  { n 0 prim = }
  [ { 0 } ]
  [ prim seq-int.empty n get-digits-reverse reverse-seq ];

: get-digits-reverse
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n }
  { n 0 prim = }
  [ result ]
  [ result n prim 10 prim mod prim seq-int.push n prim 10 prim div get-digits-reverse ]
  if;

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i }
  { i 0 prim < }
  [ result ]
  [ result xs i prim seq-int.at prim seq-int.push xs i prim 1 prim - reverse-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 13, column 19
message: Unexpected `10`, expected `primitive name`.
expected: primitive name
actual: 10
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
  locals { n } { prim seq-int.empty 2 n collect-primes };

: collect-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate n }
  { candidate n prim < }
  [ { candidate prim < } [ result ] [ result candidate prim seq-int.push ] if ]
  [ { candidate is-prime-simple } [ result candidate prim seq-int.push candidate prim 1 prim + n collect-primes ] [ candidate prim 1 prim + n collect-primes ] if ]
  if;

: is-prime-simple
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n }
  { n 2 prim < }
  [ false ]
  [ { n 2 prim = } [ true ] [ n 2 check-divisor ] if ]
  if;

: check-divisor
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d }
  { d d prim * n prim < }
  [ { n d prim mod 0 prim = } [ false ] [ n d prim 1 prim + check-divisor ] if ]
  [ true ]
  if;

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 9, column 7
message: Unexpected `candidate`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: candidate
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
  locals { xs k } { 0 build-histogram k prim seq-int.empty xs 0 fill-histogram };

: build-histogram
  (forall ρ; ρ i:Int^many k:Int^many -- ρ empty:Seq Int^many)
  locals { i k }
  { i k prim = }
  [ prim seq-int.empty ]
  [ prim seq-int.empty 0 prim seq-int.push i prim 1 prim + build-histogram ]
  if;

: fill-histogram
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i }
  { i xs prim seq-int.len prim = }
  [ counts ]
  [ counts xs i prim seq-int.at increment-count xs i prim 1 prim + fill-histogram ]
  if;

: increment-count
  (forall ρ; ρ counts:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { counts idx }
  { counts idx prim seq-int.at prim 1 prim + counts idx swap prim seq-int.set };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 51
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { xs } { xs xs prim seq-int.len prim 1 prim - 0 insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many end:Int^many start:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i end start }
  { start end prim > }
  [ xs ]
  [ xs i xs i prim 1 prim - bubble-pass xs i prim 1 prim - end insertion-sort-loop ]
  if;

: bubble-pass
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs i j }
  { j 0 prim < }
  [ xs ]
  [ xs j prim seq-int.at xs j prim 1 prim + prim seq-int.at prim < [ xs j prim seq-int.at xs j prim 1 prim + swap xs j swap prim seq-int.set j prim 1 prim - prim seq-int.set xs j prim 1 prim - bubble-pass ] [ xs j prim 1 prim - bubble-pass ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 3, column 47
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { start txs } { start 0 txs 0 process-transactions };

: process-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ result:Int^many result:Int^many)
  locals { balance rejected txs i }
  { i txs prim seq-int.len prim = }
  [ balance rejected ]
  [ balance txs i prim seq-int.at dup balance prim + dup 0 prim < [ drop drop rejected prim 1 prim + txs i prim 1 prim + process-transactions ] [ swap drop prim + rejected txs i prim 1 prim + process-transactions ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 93
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
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
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-loop };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole i }
  { i items prim seq-int.len prim = }
  [ stock allocated reasons ]
  [ items i prim seq-int.at stock swap process-order stock allocated reasons items qtys whole i prim 1 prim + allocate-loop ]
  if;

: process-order
  (forall ρ; ρ stock:Seq Int^many item:Int^many allocated:Seq Int^many reasons:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ result:Seq Int^many)
  locals { stock item allocated reasons qtys whole i }
  { item stock prim seq-int.at locals { r } 
    { qtys i prim seq-int.at r prim < }
    [ { r 0 prim = } [ allocated prim seq-int.empty prim seq-int.push reasons 2 prim seq-int.push ] [ allocated qtys i prim seq-int.at prim seq-int.push reasons 3 prim seq-int.push ] if ]
    [ { qtys i prim seq-int.at r prim = } [ allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push stock item 0 prim seq-int.set ] [ allocated r prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set ] if ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 102
message: Unexpected `1`, expected `primitive name`.
expected: primitive name
actual: 1
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
