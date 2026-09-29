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
  locals { xs i acc } { i xs prim seq-int.len prim < [ xs i prim seq-int.at acc prim + i 1 prim + [ sum-loop ] ] [ acc ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 125
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } { i xs prim seq-int.len prim < [ xs i prim seq-int.at max [ max ] [ xs i prim seq-int.at ] if i 1 prim + [ max-loop ] ] [ max ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 154
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k i cnt } { i xs prim seq-int.len prim < [ xs i prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if i 1 prim + [ count-loop ] ] [ cnt ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 155
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many found:Int^many -- ρ result:Int^many)
  locals { xs x i found } { found -1 prim = i xs prim seq-int.len prim < prim and [ xs i prim seq-int.at x prim = [ i ] [ found i 1 prim + [ find-loop ] ] if ] [ found ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 -1 find-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 174
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs result i } { i xs prim seq-int.len prim < [ xs i xs prim seq-int.len 1 prim - i prim - prim seq-int.at prim seq-int.push i 1 prim + [ reverse-loop ] ] [ result ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 reverse-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 180
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many sum:Int^many -- ρ sums:Seq Int^many)
  locals { xs result i sum } { i xs prim seq-int.len prim < [ xs i prim seq-int.at sum prim + result swap prim seq-int.push i 1 prim + [ prefix-loop ] ] [ result ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 0 prefix-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 168
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { xs result i } { i xs prim seq-int.len prim < [ xs i prim seq-int.at dup 0 prim < [ drop result ] [ result swap prim seq-int.push ] if i 1 prim + [ filter-loop ] ] [ result ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 filter-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 189
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Bool^many -- ρ result:Bool^many)
  locals { xs i sorted } { sorted i xs prim seq-int.len 1 prim - prim < prim and [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ true i 1 prim + [ check-sorted ] ] [ false ] if ] [ sorted ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 true check-sorted };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 208
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } { i xs prim seq-int.len prim < [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + [ dot-loop ] ] [ sum ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 156
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many result:Bool^many -- ρ all:Bool^many)
  locals { flags i result } { result i flags prim seq-bool.len prim < prim and [ flags i prim seq-bool.at result prim and i 1 prim + [ check-all ] ] [ result ] if ;

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 true check-all };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 164
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-run:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs i current-run max-run } { i xs prim seq-int.len 1 prim - prim < [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [ current-run 1 prim + [ max-run ] ] [ max-run current-run prim < [ current-run ] [ max-run ] if 1 ] if i 1 prim + [ run-loop ] ] [ max-run current-run dup prim < [ ] [ drop current-run ] if ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 > [ xs 0 1 0 run-loop ] [ 0 ] if };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 335
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target i j found } { found prim not j xs prim seq-int.len prim < prim and [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + [ inner-loop ] ] if ] [ found ] if ;

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target i found } { found prim not i xs prim seq-int.len 1 prim - prim < prim and [ xs i prim seq-int.at i 1 prim + [ inner-loop ] ] [ found ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 false outer-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 211
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-value
  (forall ρ; ρ xs:Seq Int^many value:Int^many j:Int^many is-new:Bool^many -- ρ result:Bool^many)
  locals { xs value j is-new } { j xs prim seq-int.len prim < [ xs j prim seq-int.at value prim = [ false ] [ j 1 prim + [ check-value ] ] if ] [ is-new ] if ;

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } { i xs prim seq-int.len prim < [ xs i prim seq-int.at i [ check-value ] count [ 1 prim + ] [ ] if i 1 prim + [ count-loop ] ] [ count ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 count-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 159
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys result i j } { i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j [ merge-loop ] ] [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + [ merge-loop ] ] if ] [ i xs prim seq-int.len prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j [ merge-loop ] ] [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + [ merge-loop ] ] [ result ] if ] if ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 554
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } { n 0 prim = [ result ] [ result n 10 prim mod prim seq-int.push n 10 prim div [ digits-loop ] ] if ;

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n [ digits-loop ] ] if };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 123
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many result:Bool^many -- ρ is-prime:Bool^many)
  locals { n d result } { d d prim * n prim < [ n d prim mod 0 prim = [ false ] [ d 1 prim + [ is-prime ] ] if ] [ result ] if ;

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate limit } { candidate limit prim < [ candidate 2 [ is-prime ] [ result candidate prim seq-int.push ] [ result ] if candidate 1 prim + [ primes-loop ] ] [ result ] if ;

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 128
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: count-occurrences
  (forall ρ; ρ xs:Seq Int^many v:Int^many j:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs v j count } { j xs prim seq-int.len prim < [ xs j prim seq-int.at v prim = [ count 1 prim + j 1 prim + [ count-occurrences ] ] [ j 1 prim + [ count-occurrences ] ] if ] [ count ] if ;

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many v:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs result v k } { v k prim < [ xs v 0 [ count-occurrences ] result swap prim seq-int.push v 1 prim + [ histogram-loop ] ] [ result ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { xs prim seq-int.empty 0 k histogram-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 197
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubble-pass
  (forall ρ; ρ xs:Seq Int^many i:Int^many length:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i length } { i length 1 prim - prim < [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ xs i 1 prim + prim seq-int.at xs i prim seq-int.set xs i prim seq-int.at prim seq-int.set i 1 prim + [ bubble-pass ] ] [ i 1 prim + [ bubble-pass ] ] if ] [ xs ] if ;

: bubble-sort
  (forall ρ; ρ xs:Seq Int^many pass:Int^many length:Int^many -- ρ sorted:Seq Int^many)
  locals { xs pass length } { pass length prim < [ xs pass [ bubble-pass ] pass 1 prim + [ bubble-sort ] ] [ xs ] if ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len bubble-sort };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 280
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs balance rejected i } { i txs prim seq-int.len prim < [ txs i prim seq-int.at balance prim + dup 0 prim < [ drop balance rejected 1 prim + ] [ balance swap rejected ] if i 1 prim + [ ledger-loop ] ] [ balance rejected ] if ;

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs start 0 0 ledger-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 238
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole allocated reasons order } { items order prim seq-int.at stock swap prim seq-int.at qtys order prim seq-int.at dup rot prim < [ allocated qtys order prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push stock swap qtys order prim seq-int.at prim seq-int.set ] [ dup 0 prim = [ drop drop allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] [ whole order prim seq-bool.at [ drop drop allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ allocated swap prim seq-int.push reasons 1 prim seq-int.push stock swap 0 prim seq-int.set ] if ] if ] if ;

: batch-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole allocated reasons order } { order qtys prim seq-int.len prim < [ stock items qtys whole allocated reasons order [ allocate-order ] order 1 prim + [ batch-loop ] ] [ stock allocated reasons ] if ;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 batch-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 600
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.
