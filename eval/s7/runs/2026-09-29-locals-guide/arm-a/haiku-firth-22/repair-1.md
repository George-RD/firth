Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs len i acc } { i len prim < [ acc xs i prim seq-int.at prim + i 1 prim + sum-loop ] [ acc ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs xs prim seq-int.len 0 0 sum-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 108
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
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs len i max } { i len prim < [ xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if i 1 prim + max-loop ] [ max ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs xs prim seq-int.len 1 xs 0 prim seq-int.at max-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 144
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
  (forall ρ; ρ xs:Seq Int^many len:Int^many k:Int^many i:Int^many cnt:Int^many -- ρ count:Int^many)
  locals { xs len k i cnt } { i len prim < [ xs i prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if i 1 prim + count-loop ] [ cnt ] if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs xs prim seq-int.len k 0 0 count-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 138
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
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many len:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x len i } { i len prim < [ xs i prim seq-int.at x prim = [ i ] [ i 1 prim + index-loop ] if ] [ -1 ] if;

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x xs prim seq-int.len 0 index-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 118
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
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs len i result } { i 0 prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim - reverse-loop ] [ result ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 130
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
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs len i sum result } { i len prim < [ xs i prim seq-int.at sum prim + result swap prim seq-int.push swap swap 1 prim + prefix-loop ] [ result ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 0 0 prim seq-int.empty prefix-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 159
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
: keep-loop
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs len i result } { i len prim < [ xs i prim seq-int.at 0 prim < [ result ] [ result xs i prim seq-int.at prim seq-int.push ] if i 1 prim + keep-loop ] [ result ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 0 prim seq-int.empty keep-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 177
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
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs len i } { i len 1 prim - prim < [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [ i 1 prim + sorted-loop ] if ] [ true ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs xs prim seq-int.len 0 sorted-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 160
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many len:Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys len i sum } { i len prim < [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop ] [ sum ] if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys xs prim seq-int.len 0 0 dot-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 139
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
: all-loop
  (forall ρ; ρ flags:Seq Bool^many len:Int^many i:Int^many result:Bool^many -- ρ all:Bool^many)
  locals { flags len i result } { i len prim < [ result flags i prim seq-bool.at prim and i 1 prim + all-loop ] [ result ] if;

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags flags prim seq-bool.len 0 true all-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 126
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
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many maxrun:Int^many currun:Int^many curval:Int^many -- ρ length:Int^many)
  locals { xs len i maxrun currun curval } { i len prim < [ xs i prim seq-int.at curval prim = [ currun 1 prim + xs i prim seq-int.at ] [ maxrun currun prim < [ currun ] [ maxrun ] if xs i prim seq-int.at 1 ] if i 1 prim + run-loop ] [ maxrun currun prim < [ currun ] [ maxrun ] if ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs xs prim seq-int.len 1 0 1 xs 0 prim seq-int.at run-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 287
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
  (forall ρ; ρ xs:Seq Int^many x:Int^many target:Int^many j:Int^many len:Int^many -- ρ found:Bool^many)
  locals { xs x target j len } { j len prim < [ xs j prim seq-int.at x prim + target prim = [ true ] [ j 1 prim + inner-loop ] if ] [ false ] if;

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many len:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target len i } { i len prim < [ xs i prim seq-int.at xs i 1 prim + target inner-loop [ true ] [ i 1 prim + outer-loop ] if ] [ false ] if;

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target xs prim seq-int.len 0 outer-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 145
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
: contains-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many len:Int^many j:Int^many val:Int^many -- ρ found:Bool^many)
  locals { xs seen len j val } { j len prim < [ seen j prim seq-int.at val prim = [ true ] [ j 1 prim + contains-loop ] if ] [ false ] if;

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many len:Int^many seen:Seq Int^many i:Int^many count:Int^many -- ρ distinct:Int^many)
  locals { xs len seen i count } { i len prim < [ xs i prim seq-int.at seen prim seq-int.len 0 contains-loop [ count ] [ seen xs i prim seq-int.at prim seq-int.push count 1 prim + ] if i 1 prim + distinct-loop ] [ count ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs xs prim seq-int.len prim seq-int.empty 0 0 distinct-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 138
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many xlen:Int^many ylen:Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys xlen ylen i j result } { i xlen prim < j ylen prim < prim and [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + merge-loop ] [ result ys j prim seq-int.at prim seq-int.push j 1 prim + merge-loop ] if ] [ i xlen prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + merge-loop ] [ j ylen prim < [ result ys j prim seq-int.at prim seq-int.push j 1 prim + merge-loop ] [ result ] if ] if ] if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys xs prim seq-int.len ys prim seq-int.len 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 479
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
: digit-loop
  (forall ρ; ρ num:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { num result } { num 0 prim = [ result ] [ result num 10 prim mod prim seq-int.push num 10 prim div digit-loop ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ n prim seq-int.empty digit-loop ] if };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 125
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
: is-prime-loop
  (forall ρ; ρ num:Int^many div:Int^many -- ρ prime:Bool^many)
  locals { num div } { div div prim * num prim < [ num div prim mod 0 prim = [ false ] [ div 1 prim + is-prime-loop ] if ] [ true ] if;

: prime-loop
  (forall ρ; ρ n:Int^many num:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n num result } { num n prim < [ num 2 is-prime-loop [ result num prim seq-int.push ] [ result ] if num 1 prim + prime-loop ] [ result ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty prime-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 135
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
: init-loop
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { k i result } { i k prim < [ result 0 prim seq-int.push i 1 prim + init-loop ] [ result ] if;

: count-loop
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many counts:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { xs len i counts } { i len prim < [ xs i prim seq-int.at counts xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set i 1 prim + count-loop ] [ counts ] if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { k 0 prim seq-int.empty init-loop xs xs prim seq-int.len count-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 103
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
: pass-loop
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs len i } { i len 1 prim - prim < [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ xs i xs i 1 prim + prim seq-int.at prim seq-int.set i 1 prim + prim seq-int.set ] [ xs i 1 prim + pass-loop ] if ] [ xs ] if;

: sort-loop
  (forall ρ; ρ xs:Seq Int^many len:Int^many p:Int^many -- ρ sorted:Seq Int^many)
  locals { xs len p } { p len prim < [ xs 0 pass-loop p 1 prim + sort-loop ] [ xs ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 sort-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 233
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
: txn-loop
  (forall ρ; ρ txs:Seq Int^many len:Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs len i balance rejected } { i len prim < [ balance txs i prim seq-int.at prim + 0 prim < [ balance rejected 1 prim + ] [ balance txs i prim seq-int.at prim + rejected ] if i 1 prim + txn-loop ] [ balance rejected ] if;

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs txs prim seq-int.len 0 start 0 txn-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 232
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
: alloc-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many len:Int^many i:Int^many s:Seq Int^many a:Seq Int^many r:Seq Int^many -- ρ stock:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole len i s a r } { i len prim < [ items i prim seq-int.at s prim seq-int.at stock items i prim seq-int.at qtys i prim seq-int.at prim < [ a qtys i prim seq-int.at prim seq-int.push r 0 prim seq-int.push stock items i prim seq-int.at qtys i prim seq-int.at prim seq-int.set ] [ qtys i prim seq-int.at 0 prim = [ r 2 prim seq-int.push a 0 prim seq-int.push ] [ whole i prim seq-bool.at [ r 3 prim seq-int.push a 0 prim seq-int.push ] [ r 1 prim seq-int.push a s prim seq-int.at prim seq-int.push stock items i prim seq-int.at s prim seq-int.at 0 prim seq-int.set ] if ] if ] if i 1 prim + alloc-loop ] [ s a r ] if;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole items prim seq-int.len stock prim seq-int.empty prim seq-int.empty alloc-loop };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 644
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.
