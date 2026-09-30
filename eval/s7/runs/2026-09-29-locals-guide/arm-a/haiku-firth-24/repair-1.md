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
  locals { xs } { 0 0 [ xs swap prim seq-int.at swap prim + swap 1 prim + dup xs prim seq-int.len prim < ] dip };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 108
message: `dip` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `dip` and in what order.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 [ locals { max i } { i xs prim seq-int.at max [ max ] [ i xs prim seq-int.at ] if swap 1 prim + dup xs prim seq-int.len prim < ] dip ];

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 169
message: `]` cannot start an item in a word's body.
actual: ]
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
  locals { xs k } { 0 0 [ xs swap prim seq-int.at k prim < [ 1 prim + ] [ ] if swap 1 prim + dup xs prim seq-int.len prim < ] dip };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 127
message: `dip` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `dip` and in what order.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { -1 0 [ dup xs prim seq-int.len prim < [ xs over prim seq-int.at x prim = [ drop swap drop ] [ swap 1 prim + ] if ] [ drop drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 64
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 0 [ dup prim < [ 1 xs prim seq-int.len prim - swap prim - xs over prim seq-int.at prim seq-int.push swap ] [ drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 119
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 [ dup xs prim seq-int.len prim < [ xs over prim seq-int.at prim + dup rot prim seq-int.push swap swap 1 prim + ] [ drop drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 80
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 [ dup xs prim seq-int.len prim < [ xs over prim seq-int.at dup 0 prim < [ drop ] [ prim seq-int.push ] if swap 1 prim + ] [ drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 78
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { true 0 [ dup xs prim seq-int.len 1 prim - prim < [ xs over prim seq-int.at xs over 1 prim + prim seq-int.at prim < [ ] [ drop false ] if swap 1 prim + ] [ drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 73
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 [ dup xs prim seq-int.len prim < [ xs over prim seq-int.at ys over prim seq-int.at prim * prim + swap 1 prim + ] [ drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 64
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 [ dup flags prim seq-bool.len prim < [ flags over prim seq-bool.at prim and swap 1 prim + ] [ drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 74
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 1 1 [ dup xs prim seq-int.len prim < [ xs over prim seq-int.at xs over 1 prim - prim seq-int.at prim = [ 1 prim + ] [ [ ] ] if swap ] [ drop drop ] if ] };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 63
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 [ dup xs prim seq-int.len prim < [ 0 [ dup xs prim seq-int.len prim < [ dup over prim = prim not [ xs over prim seq-int.at xs 2 rot prim - prim seq-int.at prim + target prim = ] [ drop false ] if ] [ drop false ] if ] swap 1 prim + ] [ drop ] if swap 1 prim + ] [ drop ] if ] };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 308
message: `]` cannot start an item in a word's body.
actual: ]
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
  0 xs prim seq-int.len 0 [ dup swap prim < [ rot xs over prim seq-int.at rot 0 [ dup xs prim seq-int.len prim < [ swap xs over prim seq-int.at prim = [ drop drop 1 ] [ swap 1 prim + ] if ] [ drop ] if ] rot prim + rot swap 1 prim + swap ] [ drop drop ] if ] ;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 5
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 [ dup xs prim seq-int.len dup ys prim seq-int.len prim + prim < [ dup xs prim seq-int.len prim < [ dup ys prim seq-int.len prim < [ xs over prim seq-int.at ys over prim seq-int.at prim < [ xs rot prim seq-int.at prim seq-int.push ] [ ys rot prim seq-int.at prim seq-int.push ] if ] [ xs rot prim seq-int.at prim seq-int.push ] if ] [ ys rot prim seq-int.at prim seq-int.push ] if ] [ drop ] if ] ;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 441
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
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n prim not n 0 prim < [ n 0 prim - ] [ n ] if [ dup 0 prim = prim not [ dup 10 prim mod prim seq-int.push swap 10 prim div ] [ drop ] if ] ] if ;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 204
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
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 [ dup n prim < [ 2 1 [ dup over prim * over prim < [ 1 ] [ 0 ] if prim and ] 1 prim = [ rot prim seq-int.push swap 1 prim + ] [ 1 prim + ] if ] ] [ drop ] if ] ;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 197
message: `]` cannot start an item in a word's body.
actual: ]
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
  locals { xs k } { k 0 [ dup 0 prim = [ drop prim seq-int.empty xs prim seq-int.len 0 [ dup xs prim seq-int.len prim < [ xs over prim seq-int.at rot 0 [ dup k prim < [ swap xs 2 rot prim seq-int.at prim = [ 1 prim + ] [ ] if swap 1 prim + ] [ drop ] if ] rot rot 1 prim + swap ] [ drop ] if ] ] [ rot 0 [ dup xs prim seq-int.len prim < [ xs over prim seq-int.at rot prim + swap 1 prim + ] [ drop ] if ] rot prim seq-int.push swap 1 prim - ] if ] ;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 448
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs prim seq-int.len 0 [ dup swap prim < [ 0 [ dup xs prim seq-int.len 1 prim - prim < [ xs over prim seq-int.at xs over 1 prim + prim seq-int.at prim < [ swap xs over prim seq-int.at xs 2 rot prim seq-int.at prim seq-int.set swap xs over 1 prim + prim seq-int.at prim seq-int.set swap ] [ ] if 1 prim + ] [ drop ] if ] rot 1 prim + rot ] [ drop ] if ] ;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 371
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
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 [ dup txs prim seq-int.len prim < [ txs over prim seq-int.at rot over prim + swap 0 prim < [ drop 1 prim + ] [ rot prim + swap ] if swap 1 prim + ] [ drop ] if ] ;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 198
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
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 [ dup qtys prim seq-int.len prim < [ items over prim seq-int.at rot items over prim seq-int.at prim seq-int.at 2 rot stock prim seq-int.len [ ] [ ] ] [ drop drop drop ] if ] ;

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 3, column 278
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `}`.
