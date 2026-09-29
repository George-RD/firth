Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { new_acc } { xs i 1 prim + new_acc sum-aux } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 51
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem max prim < [ max ] [ elem ] if locals { new_max } { xs i 1 prim + new_max max-aux } } ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 94
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many acc:Int^many -- ρ count:Int^many)
  locals { xs i k acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem k prim < [ acc 1 prim + ] [ acc ] if locals { new_acc } { xs i 1 prim + k new_acc count-aux } } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs 0 k 0 count-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 100
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push locals { new_result } { xs i 1 prim - new_result reverse-aux } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 65
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { new_acc } { new_acc result prim seq-int.push locals { new_result } { xs i 1 prim + new_acc new_result prefix-aux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 51
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem 0 prim < [ result ] [ result elem prim seq-int.push ] if locals { new_result } { xs i 1 prim + new_result keep-aux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 120
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ xs i 1 prim + sorted-aux ] [ 0 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sorted-aux };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sorted-aux
at: line 5, column 100
message: The two branches of `if` in `sorted-aux` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Bool and the false branch leaves .. Int.
expected: .. Bool
actual: .. Int
hint: Both leave 1 value, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-aux
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + locals { new_acc } { xs ys i 1 prim + new_acc dot-aux } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 79
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-aux
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at [ i 1 prim + flags all-aux ] [ 0 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-aux };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: all-aux
at: line 5, column 51
message: `all-aux` in `all-aux` takes flags:Seq Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int ?t27
hint: These are the values `all-aux` takes, in another order. To push them in its order, write `flags i 1 prim +` in place of `i 1 prim + flags`. With that edit, the next error in `all-aux` is at line 5, column 67.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many current:Int^many max:Int^many -- ρ length:Int^many)
  locals { xs i current max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem xs i 1 prim + prim seq-int.at prim = [ current 1 prim + locals { new_current } { xs i 1 prim + new_current max run-aux } ] [ current 1 prim + locals { new_max } { max current 1 prim + prim < [ current 1 prim + ] [ new_max ] if locals { next_max } { xs i 1 prim + 1 next_max run-aux } } ] if } ]
    [ max current prim < [ current ] [ max ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 1 0 run-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 119
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-aux
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { a } { i 1 prim + locals { j } { [ j xs prim seq-int.len prim < [ xs j prim seq-int.at a prim + target prim = [ 1 ] [ j 1 prim + ] if ] [ 0 ] if ] [ j 1 prim + ] compose call [ pair-aux ] [ 0 ] if } } ]
    [ 0 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pair-aux };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-aux
at: line 5, column 230
message: The two branches of `if` in `pair-aux` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The condition and the values the branches take from below the `if` are looked for where the locals `a`, `target`, `i` and `xs` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-count
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ count:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { 0 locals { j found } { [ j seen prim seq-int.len prim < [ seen j prim seq-int.at elem prim = [ 1 ] [ j 1 prim + ] if ] [ found ] if ] [ j 1 prim + ] compose call prim not [ seen elem prim seq-int.push locals { new_seen } { xs i 1 prim + new_seen distinct-count } ] [ xs i 1 prim + seen distinct-count ] if } } ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty distinct-count };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 259
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-aux
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim < [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push locals { new_result } { xs ys i 1 prim + j new_result merge-aux } ] [ result ys j prim seq-int.at prim seq-int.push locals { new_result } { xs ys i j 1 prim + new_result merge-aux } ] if ] [ result xs i prim seq-int.at prim seq-int.push locals { new_result } { xs ys i 1 prim + j new_result merge-aux } ] if ]
    [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push locals { new_result } { xs ys i j 1 prim + new_result merge-aux } ] [ result ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 147
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-aux
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim <
    [ n prim not locals { pos } { pos 10 prim mod result prim seq-int.push locals { new_result } { pos 10 prim div new_result digit-aux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digit-aux ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 88
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ 0 ]
    [ n 2 prim = [ 1 ] [ 2 locals { d } { [ d d prim * n prim < ] [ n d prim mod 0 prim = [ 0 ] [ d 1 prim + ] if ] compose call prim not ] if ] if
    if
  };

: primes-aux
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n current result } {
    current n prim <
    [ current is-prime [ result current prim seq-int.push locals { new_result } { n current 1 prim + new_result primes-aux } ] [ n current 1 prim + result primes-aux ] if ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-aux };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 6, column 139
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs i k counts } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { idx } { idx counts idx prim seq-int.at 1 prim + prim seq-int.set locals { new_counts } { xs i 1 prim + k new_counts histogram-aux } } ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty locals { counts } {
      [ counts prim seq-int.len k prim < ] [ counts 0 prim seq-int.push ] compose call
      xs 0 k counts histogram-aux
    }
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 114
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-aux
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i sorted prim seq-int.len prim <
    [ sorted i prim seq-int.at x prim < [ sorted i x prim seq-int.set locals { new_sorted } { x new_sorted i 1 prim + insert-aux } ] [ x sorted i insert-aux ] if ]
    [ sorted x prim seq-int.push ]
    if
  };

: sort-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sorted 0 insert-aux locals { new_sorted } { xs i 1 prim + new_sorted sort-aux } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 83
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-aux
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { new_balance } { new_balance 0 prim < [ balance i 1 prim + rejected ledger-aux ] [ new_balance i 1 prim + rejected ledger-aux ] if } } ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 75
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-aux
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at locals { item } { stock item prim seq-int.at locals { current_stock } { qtys i prim seq-int.at locals { qty } { whole i prim seq-bool.at locals { w } { qty current_stock prim < [ current_stock 0 prim = [ stock allocated qty prim seq-int.push reasons 2 prim seq-int.push locals { a r } { a r i 1 prim + allocate-aux } ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ stock item current_stock prim seq-int.set allocated current_stock prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] [ stock item current_stock qty prim - prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { s a r } { s a r i 1 prim + allocate-aux } ] if } } } } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-aux };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 5, column 92
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
