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
  locals { xs } { xs 0 0 sum-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ total:Int^many)
  locals { xs i acc }
  xs prim seq-int.len
  locals { len } { i len prim < }
  [ xs i prim seq-int.at locals { x } { acc x prim + locals { nacc } { xs i 1 prim + nacc sum-loop } } ]
  [ acc ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
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
  locals { xs } { xs 0 xs 0 prim seq-int.at max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs i max }
  xs prim seq-int.len
  locals { len } { i 1 prim + locals { ni } { ni len prim < } }
  [ xs ni prim seq-int.at locals { x } { max x prim < [ x ] [ max ] if locals { newmax } { xs ni newmax max-loop } } ]
  [ max ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
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
  locals { xs k } { xs k 0 0 count-loop };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ count:Int^many)
  locals { xs k i cnt }
  xs prim seq-int.len
  locals { len } { i len prim < }
  [ xs i prim seq-int.at locals { x } { x k prim < [ cnt 1 prim + ] [ cnt ] if locals { newcnt } { xs k i 1 prim + newcnt count-loop } } ]
  [ cnt ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
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
  locals { xs x } { xs x 0 index-loop };

: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i }
  xs prim seq-int.len
  locals { len } { i len prim < }
  [ xs i prim seq-int.at locals { v } { v x prim = [ i ] [ xs x i 1 prim + index-loop ] if } ]
  [ -1 ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
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
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { acc xs i }
  i 0 prim < prim not
  [ xs i prim seq-int.at locals { v } { acc v prim seq-int.push locals { nacc } { nacc xs i 1 prim - reverse-loop } } ]
  [ acc ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { xs } { prim seq-int.empty 0 0 xs xs prim seq-int.len prefix-loop };

: prefix-loop
  (forall ρ; ρ acc:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ sums:Seq Int^many)
  locals { acc sum i xs len }
  i len prim <
  [ xs i prim seq-int.at locals { v } { sum v prim + locals { nsum } { acc nsum prim seq-int.push locals { nacc } { nacc nsum i 1 prim + xs len prefix-loop } } } ]
  [ acc ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { xs } { prim seq-int.empty 0 xs xs prim seq-int.len keep-loop };

: keep-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ positives:Seq Int^many)
  locals { acc i xs len }
  i len prim <
  [ xs i prim seq-int.at locals { v } { v 0 prim < prim not [ acc v prim seq-int.push ] [ acc ] if locals { nacc } { nacc i 1 prim + xs len keep-loop } } ]
  [ acc ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { xs } { xs prim seq-int.len locals { len } { len 1 prim < [ 1 ] [ 0 1 xs len is-sorted-loop ] if } };

: is-sorted-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many len:Int^many -- ρ sorted:Bool^many)
  locals { i xs len }
  i len prim <
  [ xs i 1 prim - prim seq-int.at locals { prev } { xs i prim seq-int.at locals { curr } { prev curr prim < prim not [ curr curr prim = prim or [ i 1 prim + xs len is-sorted-loop ] [ 0 ] if ] [ 0 ] if } } ]
  [ 1 ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
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
  locals { xs ys } { 0 0 xs ys xs prim seq-int.len dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many len:Int^many -- ρ product:Int^many)
  locals { acc i xs ys len }
  i len prim <
  [ xs i prim seq-int.at locals { x } { ys i prim seq-int.at locals { y } { x y prim * locals { prod } { acc prod prim + locals { nacc } { nacc i 1 prim + xs ys len dot-loop } } } } ]
  [ acc ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { flags } { 1 0 flags flags prim seq-int.len all-loop };

: all-loop
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many len:Int^many -- ρ all:Bool^many)
  locals { result i flags len }
  i len prim <
  result prim and
  [ flags i prim seq-int.at locals { b } { b i 1 prim + flags len all-loop } ]
  [ result ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
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
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim = [ 0 ] [ 0 1 1 0 xs len longest-loop ] if } };

: longest-loop
  (forall ρ; ρ maxrun:Int^many currun:Int^many i:Int^many lastval:Int^many xs:Seq Int^many len:Int^many -- ρ length:Int^many)
  locals { maxrun currun i lastval xs len }
  i len prim <
  [ xs i prim seq-int.at locals { v } { v lastval prim = [ currun 1 prim + locals { ncr } { maxrun ncr prim < [ ncr ] [ maxrun ] if locals { nmr } { nmr ncr i 1 prim + v xs len longest-loop } } ] [ maxrun currun prim < [ currun ] [ maxrun ] if locals { nmr } { nmr 1 i 1 prim + v xs len longest-loop } } ] if } ]
  [ maxrun currun prim < [ currun ] [ maxrun ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { xs target } { 0 xs target xs prim seq-int.len has-pair-loop };

: has-pair-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many len:Int^many -- ρ found:Bool^many)
  locals { i xs target len }
  i len prim <
  [ xs i prim seq-int.at locals { x } { target x prim - locals { needed } { i 1 prim + xs needed has-inner-loop } } ]
  [ 0 ]
  if;

: has-inner-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many needed:Int^many -- ρ found:Bool^many)
  locals { j xs needed }
  xs prim seq-int.len
  locals { len } { j len prim < }
  [ xs j prim seq-int.at locals { y } { y needed prim = [ 1 ] [ j 1 prim + xs needed has-inner-loop ] if } ]
  [ 0 ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
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
  locals { xs } { prim seq-int.empty 0 xs count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen i xs }
  xs prim seq-int.len
  locals { len } { i len prim < }
  [ xs i prim seq-int.at locals { v } { seen 0 v is-in-seq [ seen i 1 prim + xs count-distinct-loop ] [ seen v prim seq-int.push i 1 prim + xs count-distinct-loop ] if } ]
  [ seen prim seq-int.len ]
  if;

: is-in-seq
  (forall ρ; ρ seq:Seq Int^many searchval:Int^many -- ρ found:Bool^many)
  locals { seq searchval } { 0 seq searchval seq prim seq-int.len is-in-loop };

: is-in-loop
  (forall ρ; ρ j:Int^many seq:Seq Int^many searchval:Int^many len:Int^many -- ρ found:Bool^many)
  locals { j seq searchval len }
  j len prim <
  [ seq j prim seq-int.at locals { v } { v searchval prim = [ 1 ] [ j 1 prim + seq searchval len is-in-loop ] if } ]
  [ 0 ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `xs`, expected `{`.
expected: {
actual: xs
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
  locals { xs ys } { prim seq-int.empty 0 0 xs ys xs prim seq-int.len ys prim seq-int.len merge-loop };

: merge-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many xlen:Int^many ylen:Int^many -- ρ merged:Seq Int^many)
  locals { acc i j xs ys xlen ylen }
  i xlen prim <
  [ j ylen prim < [ xs i prim seq-int.at locals { x } { ys j prim seq-int.at locals { y } { x y prim < [ acc x prim seq-int.push i 1 prim + j xs ys xlen ylen merge-loop ] [ acc y prim seq-int.push i j 1 prim + xs ys xlen ylen merge-loop ] if } } ] [ acc xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys xlen ylen merge-loop ] if ]
  [ j ylen prim < [ acc ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys xlen ylen merge-loop ] [ acc ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n 0 0 digits-loop ] if };

: digits-loop
  (forall ρ; ρ acc:Seq Int^many n:Int^many dcount:Int^many -- ρ digits:Seq Int^many)
  locals { acc n dcount }
  n 0 prim < prim not
  [ n 10 prim mod locals { d } { d 0 prim = [ acc d prim seq-int.push ] [ acc d prim seq-int.push ] if locals { nacc } { n 10 prim div locals { nv } { nacc nv 1 prim + digits-loop } } } ]
  [ acc ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
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
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { acc i n }
  i n prim < prim or i n prim =
  [ i 2 is-prime-check [ acc i prim seq-int.push i 1 prim + n primes-loop ] [ i 1 prim + n primes-loop ] if ]
  [ acc ]
  if;

: is-prime-check
  (forall ρ; ρ num:Int^many -- ρ isprime:Bool^many)
  locals { num } { num 2 num is-prime-inner };

: is-prime-inner
  (forall ρ; ρ num:Int^many div:Int^many -- ρ isprime:Bool^many)
  locals { num div }
  div div prim * num prim < prim not
  [ 1 ]
  [ num div prim mod 0 prim = [ 0 ] [ num div 1 prim + is-prime-inner ] if ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { xs k } { 0 prim seq-int.empty k 0 histogram-init };

: histogram-init
  (forall ρ; ρ idx:Int^many counts:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { idx counts k }
  idx k prim <
  [ counts 0 prim seq-int.push idx 1 prim + xs k histogram-init ]
  [ xs counts 0 histogram-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `idx`, expected `{`.
expected: {
actual: idx
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
  locals { xs } { xs 0 xs prim seq-int.len sort-outer };

: sort-outer
  (forall ρ; ρ arr:Seq Int^many i:Int^many len:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i len }
  i len prim < prim not [ arr ] [ arr i i 1 prim + len sort-inner ] if;

: sort-inner
  (forall ρ; ρ arr:Seq Int^many i:Int^many j:Int^many len:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i j len }
  j len prim <
  [ arr j prim seq-int.at locals { x } { arr j 1 prim - prim seq-int.at locals { y } { x y prim < [ arr j y prim seq-int.set locals { narr1 } { narr1 j 1 prim - x prim seq-int.set i 1 prim + len narr1 sort-outer } ] [ arr i 1 prim + j 1 prim + len sort-inner ] if } } ]
  [ arr i 1 prim + len sort-outer ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  locals { start txs } { start 0 0 txs txs prim seq-int.len ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many len:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs len }
  i len prim <
  [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { newbal } { newbal 0 prim < [ balance rejected 1 prim + i 1 prim + txs len ledger-loop ] [ newbal rejected i 1 prim + txs len ledger-loop ] if } } ]
  [ balance rejected ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
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
  { } { } { } 0 stock items qtys whole stock prim seq-int.len allocate-loop;

: allocate-loop
  (forall ρ; ρ allocd:Seq Int^many reasons:Seq Int^many used:Seq Int^many j:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many n:Int^many
    -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { allocd reasons used j stock items qtys whole n }
  j n prim <
  [
    items j prim seq-int.at locals { item-idx } {
      stock item-idx prim seq-int.at locals { cur-stock } {
        qtys j prim seq-int.at locals { qty } {
          cur-stock qty prim < 
          [
            cur-stock 0 prim = 
            [
              used allocd 0 prim seq-int.push reasons 2 prim seq-int.push
              j 1 prim + stock items qtys whole n allocate-loop
            ]
            [
              whole j prim seq-int.at locals { w } {
                w
                [
                  used allocd 0 prim seq-int.push reasons 3 prim seq-int.push
                  j 1 prim + stock items qtys whole n allocate-loop
                ]
                [
                  stock item-idx cur-stock prim seq-int.set locals { nstock } {
                    used allocd cur-stock prim seq-int.push reasons 1 prim seq-int.push
                    j 1 prim + nstock items qtys whole n allocate-loop
                  }
                ]
                if
              }
            ]
            if
          ]
          [
            stock item-idx qty prim - locals { nstock } {
              used allocd qty prim seq-int.push reasons 0 prim seq-int.push
              j 1 prim + nstock items qtys whole n allocate-loop
            }
          ]
          if
        }
      }
    }
  ]
  [ stock used allocated reasons ]
  if;

```
On the example, the run failed:
code: firth.syntax.empty-sequence
at: line 4, column 7
message: Unexpected the end of the input, expected `at least one element`.
expected: at least one element
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
