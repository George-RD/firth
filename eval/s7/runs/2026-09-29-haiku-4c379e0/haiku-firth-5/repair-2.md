Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim = [ acc ] [
      acc xs i prim seq-int.at prim +
      xs i 1 prim + acc prim +
      sum-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  xs 0 0 sum-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-max:Int^many -- ρ result:Int^many)
  locals { xs i current-max } {
    i xs prim seq-int.len prim = [ current-max ] [
      xs i prim seq-int.at
      current-max
      [ prim < ] dip
      [ swap ] [ ] if
      xs i 1 prim + current-max
      max-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 1 xs 0 prim seq-int.at max-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 11, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs k i acc } {
    i xs prim seq-int.len prim = [ acc ] [
      xs i prim seq-int.at k prim <
      [ acc 1 prim + ] [ acc ] if
      xs k i 1 prim + count-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  xs k 0 0 count-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim = [ -1 ] [
      xs i prim seq-int.at x prim =
      [ i ] [ xs x i 1 prim + index-helper ] if
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  xs x 0 index-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 7, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [ result ] [
      xs i prim seq-int.at result prim seq-int.push
      xs i 1 prim - result prim seq-int.push
      reverse-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim = [ result ] [
      acc xs i prim seq-int.at prim +
      xs i 1 prim + result prim seq-int.push
      prefix-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  xs 0 0 prim seq-int.empty prefix-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim = [ result ] [
      xs i prim seq-int.at
      dup 0 prim <
      [ drop xs i 1 prim + result keep-helper ]
      [ prim seq-int.push xs i 1 prim + result keep-helper ] if
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  xs 0 prim seq-int.empty keep-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 9, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim =
    [ true ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + is-sorted-helper ] if ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs prim seq-int.len 1 prim <= [ true ] [ xs 0 is-sorted-helper ] if;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 49
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim = [ acc ] [
      acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      xs ys i 1 prim + dot-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  xs ys 0 0 dot-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 7, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim = [ true ] [
      flags i prim seq-bool.at
      [ flags i 1 prim + all-helper ]
      [ false ] if
    ] if;
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  flags 0 all-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { xs i current-len max-len } {
    i xs prim seq-int.len 1 prim - prim =
    [ current-len max-len [ prim < ] dip [ ] [ swap ] if drop ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
      [ xs i 1 prim + current-len 1 prim + max-len longest-helper ]
      [ current-len max-len [ prim < ] dip [ ] [ swap ] if xs i 1 prim + 1 max-len longest-helper ] if
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim = [ 0 ] [ xs 0 1 0 longest-helper ] if;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 9, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-complement
  (forall ρ; ρ xs:Seq Int^many complement:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs complement i } {
    i xs prim seq-int.len prim = [ false ] [
      xs i prim seq-int.at complement prim = [ true ] [ xs complement i 1 prim + find-complement ] if
    ] if;
  };

: has-pair-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim = [ false ] [
      xs i prim seq-int.at target swap prim -
      xs target i 1 prim + find-complement
      [ true ] [ xs target i 1 prim + has-pair-helper ] if
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  xs target 0 has-pair-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 6, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in-seen
  (forall ρ; ρ seen:Seq Int^many x:Int^many i:Int^many -- ρ result:Bool^many)
  locals { seen x i } {
    i seen prim seq-int.len prim = [ false ] [
      seen i prim seq-int.at x prim = [ true ] [ seen x i 1 prim + is-in-seen ] if
    ] if;
  };

: count-helper
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs seen i } {
    i xs prim seq-int.len prim = [ seen prim seq-int.len ] [
      xs i prim seq-int.at
      seen xs i prim seq-int.at is-in-seen
      [ xs seen i 1 prim + count-helper ]
      [ xs i prim seq-int.at prim seq-int.push xs seen i 1 prim + count-helper ] if
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  xs prim seq-int.empty 0 count-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 6, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim = [ result prim seq-int.len j prim seq-int.len [ drop ] dip ] [
      j ys prim seq-int.len prim = [ result prim seq-int.len prim seq-int.len drop ] [
        xs i prim seq-int.at ys j prim seq-int.at [ prim < ] dip
        [ xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j result merge-helper ]
        [ ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + result merge-helper ] if
      ] if
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  xs ys 0 0 prim seq-int.empty merge-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 10, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim = [ result ] [
      n 10 prim mod prim seq-int.push
      n 10 prim div result
      digits-helper
    ] if;
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim = [ { 0 } ] [
    prim seq-int.empty n digits-helper
    dup prim seq-int.len 1 prim - [ dup prim seq-int.len 1 prim - swap prim seq-int.at swap prim seq-int.len 1 prim - dup 1 prim - prim seq-int.at swap 0 swap prim seq-int.set dup 1 prim - prim seq-int.set ] dip
  ] if;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { n divisor } {
    divisor divisor prim * n prim <
    [ n divisor prim mod 0 prim = [ false ] [ n divisor 1 prim + is-prime ] if ]
    [ true ] if;
  };

: primes-helper
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim = [ result ] [
      i 2 is-prime [ i prim seq-int.push ] [ ] if
      n i 1 prim + result
      primes-helper
    ] if;
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  n 2 prim seq-int.empty primes-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 6, column 16
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs k counts i } {
    i xs prim seq-int.len prim = [ counts ] [
      xs i prim seq-int.at
      dup counts swap prim seq-int.at 1 prim +
      swap prim seq-int.set
      xs k counts i 1 prim + histogram-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    k 0
    [ prim seq-int.push ] dip
    xs k 0 histogram-helper
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 9, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: min-index-helper
  (forall ρ; ρ xs:Seq Int^many min-idx:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs min-idx i } {
    i xs prim seq-int.len prim = [ min-idx ] [
      xs i prim seq-int.at xs min-idx prim seq-int.at [ prim < ] dip
      [ i ] [ min-idx ] if
      xs min-idx i 1 prim + min-index-helper
    ] if;
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim = [ xs ] [
      xs i min-index-helper
      dup i prim seq-int.at
      xs i dup prim seq-int.at swap swap 0 swap prim seq-int.set
      dup i prim seq-int.at 0 swap prim seq-int.set
      xs i 1 prim + sort-helper
    ] if;
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 sort-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-helper
  (forall ρ; ρ balance:Int^many txs:Seq Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { balance txs rejected i } {
    i txs prim seq-int.len prim = [ balance rejected ] [
      balance txs i prim seq-int.at prim +
      dup 0 prim <
      [ drop balance 1 prim + txs rejected 1 prim + i 1 prim + ledger-helper ]
      [ txs rejected i 1 prim + ledger-helper ] if
    ] if;
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  start txs 0 0 ledger-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 9, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
             stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many
    -- ρ sl:Seq Int^many al:Seq Int^many re:Seq Int^many)
  locals { stock items qtys whole stock-left allocated reasons i } {
    i qtys prim seq-int.len prim = [ stock-left allocated reasons ] [
      items i prim seq-int.at stock swap prim seq-int.at
      qtys i prim seq-int.at
      dup [ prim < ] dip
      [ qtys i prim seq-int.at prim seq-int.push 0 ]
      [ dup 0 prim = [ drop drop 2 ] [ whole i prim seq-bool.at [ drop drop 3 ] [ prim seq-int.push 1 ] if ] if ] if
      prim seq-int.push
      stock items qtys whole stock-left allocated reasons i 1 prim + allocate-helper
    ] if;
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
    -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock items qtys whole prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 allocate-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 14, column 9
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
