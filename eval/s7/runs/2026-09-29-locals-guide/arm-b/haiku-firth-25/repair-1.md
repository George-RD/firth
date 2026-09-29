Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sum:Int^many)
  locals { xs } { 0 [ xs locals { s } { s xs prim seq-int.len 0 xs_loop } ] };

: xs_loop
  (forall ρ; ρ idx:Int^many len:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx len acc xs } {
    [ acc ] [ xs prim seq-int.at idx prim + locals { acc2 } { idx 1 prim + len acc2 xs_loop } ] 
    idx len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 67
message: `_` cannot start an item in a word's body.
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ max:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1 xs prim seq-int.len
    [ xs prim seq-int.at locals { v } { [ v ] [ ] v prim < if } ] dip
    prim call
  };

: loop_max
  (forall ρ; ρ idx:Int^many len:Int^many cur_max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx len cur_max xs } {
    [ cur_max ] 
    [ xs idx prim seq-int.at locals { v } { [ v ] [ cur_max ] v cur_max prim < if } locals { new_max } { idx 1 prim + len new_max xs loop_max } ]
    idx len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 7, column 10
message: Unexpected `call`, expected `primitive name`.
expected: primitive name
actual: call
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
  locals { xs k } { 0 0 xs prim seq-int.len [ xs k count_loop ] };

: count_loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc idx len xs k } {
    [ acc ] [ xs idx prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if locals { new_acc } { idx 1 prim + len new_acc xs k count_loop } ] idx len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 57
message: `_` cannot start an item in a word's body.
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ idx:Int^many)
  locals { xs x } { 0 xs prim seq-int.len x find_index };

: find_index
  (forall ρ; ρ idx:Int^many len:Int^many x:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx len x xs } {
    [ -1 ] [ xs idx prim seq-int.at x prim = [ idx ] [ idx 1 prim + len x xs find_index ] if ] idx len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 49
message: `_` cannot start an item in a word's body.
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ rev:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - [ xs reverse_loop ] };

: reverse_loop
  (forall ρ; ρ idx:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { idx acc xs } {
    [ acc ] [ xs idx prim seq-int.at acc prim seq-int.push locals { new_acc } { idx 1 prim - new_acc xs reverse_loop } ]
    idx 0 prim < if [ acc ] swap if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 79
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs } { prim seq-int.empty 0 0 [ xs prim seq-int.len prefix_loop ] };

: prefix_loop
  (forall ρ; ρ acc:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc sum idx xs } {
    [ acc ] [ xs idx prim seq-int.at sum prim + locals { new_sum } { acc new_sum prim seq-int.push idx 1 prim + new_sum idx xs prefix_loop } ]
    idx xs prim seq-int.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 70
message: `_` cannot start an item in a word's body.
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 [ xs keep_positive_loop ] };

: keep_positive_loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc idx xs } {
    [ acc ] [ xs idx prim seq-int.at locals { v } { [ acc v prim seq-int.push ] [ acc ] v 0 prim < if locals { new_acc } { new_acc idx 1 prim + xs keep_positive_loop } } ]
    idx xs prim seq-int.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 49
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs } {
    [ true ] [ 0 check_sorted ] xs prim seq-int.len 1 prim <= if
  };

: check_sorted
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { idx xs } {
    [ true ]
    [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < [ false ] [ idx 1 prim + xs check_sorted ] if ]
    idx xs prim seq-int.len 1 prim - prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 23
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs ys } { 0 0 [ xs ys dot_loop ] };

: dot_loop
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc idx xs ys } {
    [ acc ]
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim + locals { new_acc } { new_acc idx 1 prim + xs ys dot_loop } ]
    idx xs prim seq-int.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 37
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { flags } { true 0 [ flags all_true_loop ] };

: all_true_loop
  (forall ρ; ρ acc:Bool^many idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { acc idx flags } {
    [ acc ] [ flags idx prim seq-bool.at prim and locals { new_acc } { new_acc idx 1 prim + flags all_true_loop } ]
    idx flags prim seq-bool.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 40
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs } {
    [ 0 ] [ xs 0 prim seq-int.at 1 1 longest_run_loop ] xs prim seq-int.len 1 prim > if
  };

: longest_run_loop
  (forall ρ; ρ max_len:Int^many prev_val:Int^many cur_len:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max_len prev_val cur_len idx xs } {
    [ [ max_len ] [ cur_len max_len prim < [ cur_len ] [ max_len ] if ] cur_len max_len prim < if ]
    [ xs idx prim seq-int.at locals { v } {
      [ [ [ max_len ] [ cur_len max_len prim < [ cur_len ] [ max_len ] if ] cur_len max_len prim < if prev_val 1 prim + idx 1 prim + xs longest_run_loop ] ]
      [ [ max_len ] [ cur_len max_len prim < [ cur_len ] [ max_len ] if ] cur_len max_len prim < if 1 idx 1 prim + xs longest_run_loop ]
      v prev_val prim = if
    } ]
    idx xs prim seq-int.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 45
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs target } { false 0 0 [ xs target find_pair_sum ] };

: find_pair_sum
  (forall ρ; ρ found:Bool^many i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i j xs target } {
    [ found ]
    [ [ j xs prim seq-int.len prim < [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ true found i j 1 prim + xs target find_pair_sum ] if ] [ i 1 prim + 0 xs target find_pair_sum ] if ] [ true ] found if ]
    i xs prim seq-int.len 1 prim - prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 52
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs } { prim seq-int.empty 0 [ xs count_distinct_loop ] };

: count_distinct_loop
  (forall ρ; ρ seen:Seq Int^many count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen count idx xs } {
    [ [ count ] [ count 1 prim + ] seen xs idx prim seq-int.at contains_in_seq if ]
    [ xs idx prim seq-int.at seen prim seq-int.push locals { new_seen } { new_seen count idx 1 prim + xs count_distinct_loop } ]
    if
  };

: contains_in_seq
  (forall ρ; ρ acc:Bool^many i:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { acc i val seen } {
    [ acc ] [ seen i prim seq-int.at val prim = [ true ] [ i 1 prim + val seen check_contains ] if ] i seen prim seq-int.len prim < if
  };

: check_contains
  (forall ρ; ρ i:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { i val seen } {
    false i [ seen check_contains_inner ]
  };

: check_contains_inner
  (forall ρ; ρ idx:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { idx val seen } {
    [ false ] [ seen idx prim seq-int.at val prim = [ true ] [ idx 1 prim + val seen check_contains_inner ] if ] idx seen prim seq-int.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 50
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs ys } { prim seq-int.empty 0 0 [ xs ys merge_loop ] };

: merge_loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    [ [ [ result xs i prim seq-int.at prim seq-int.push ] [ result ys j prim seq-int.at prim seq-int.push ] xs i prim seq-int.at ys j prim seq-int.at prim < if locals { new_result } { [ [ new_result i 1 prim + j xs ys merge_loop ] [ new_result i j 1 prim + xs ys merge_loop ] j ys prim seq-int.len prim = if ] [ [ result ] [ new_result i 1 prim + j xs ys merge_loop ] i xs prim seq-int.len prim = if ] i xs prim seq-int.len prim = if ] ]
    [ [ result xs i prim seq-int.at prim seq-int.push locals { r } { r i 1 prim + j xs ys merge_loop } ] ]
    [ [ result ] [ i xs prim seq-int.len prim = ] if ]
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 58
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { n } {
    [ prim seq-int.empty 0 ] [ prim seq-int.empty [ n digits_loop ] ]
    n 0 prim = if
  };

: digits_loop
  (forall ρ; ρ digits:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { digits n } {
    [ digits ] [ n 10 prim mod digits prim seq-int.push n 10 prim div [ digits prim seq-int.len digits digits_rev ] ]
    n 0 prim > if
  };

: digits_rev
  (forall ρ; ρ rev:Seq Int^many orig:Seq Int^many -- ρ result:Seq Int^many)
  locals { rev orig } {
    prim seq-int.empty orig prim seq-int.len 1 prim - [ orig rev reverse_digits ]
  };

: reverse_digits
  (forall ρ; ρ idx:Int^many result:Seq Int^many orig:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx result orig } {
    [ result ] [ orig idx prim seq-int.at result prim seq-int.push idx 1 prim - [ orig reverse_digits ] ]
    idx 0 prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 61
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { n } {
    [ prim seq-int.empty ] [ 2 n prim seq-int.empty sieve_loop ]
    n 2 prim < if
  };

: sieve_loop
  (forall ρ; ρ current:Int^many n:Int^many primes:Seq Int^many -- ρ result:Seq Int^many)
  locals { current n primes } {
    [ primes current prim seq-int.push ] [ current 1 prim + n primes sieve_loop ]
    current n prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 58
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs k } {
    [ 0 prim seq-int.empty [ prim seq-int.empty [ k histogram_init ] ] ]
  };

: histogram_init
  (forall ρ; ρ acc:Seq Int^many i:Int^many k:Int^many -- ρ initialized:Seq Int^many)
  locals { acc i k } {
    [ acc ] [ acc 0 prim seq-int.push i 1 prim + k histogram_init ] i k prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 62
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { xs } { xs 0 xs prim seq-int.len [ xs insertion_sort ] };

: insertion_sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { xs i n } {
    [ xs ] [ xs i [ xs sort_insert ] ] i n prim < if
  };

: sort_insert
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    [ xs ] [ xs i 1 prim - locals { j } { xs i prim seq-int.at xs j prim seq-int.at prim < [ xs i xs j prim seq-int.at prim seq-int.set j xs prim seq-int.at prim seq-int.set j [ xs sort_insert ] ] [ xs ] if } ]
    i 0 prim > if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 58
message: `_` cannot start an item in a word's body.
actual: _
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
  locals { start txs } { start 0 0 [ txs apply_transactions ] };

: apply_transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many txs:Seq Int^many -- ρ final_balance:Int^many final_rejected:Int^many)
  locals { balance rejected idx txs } {
    [ balance rejected ] [ txs idx prim seq-int.at locals { tx } { [ balance tx prim + rejected idx 1 prim + txs apply_transactions ] [ balance rejected 1 prim + idx 1 prim + txs apply_transactions ] balance tx prim + 0 prim < if } ]
    idx txs prim seq-int.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 47
message: `_` cannot start an item in a word's body.
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 [ items qtys whole allocate_orders ]
  };

: allocate_orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final_stock:Seq Int^many final_allocated:Seq Int^many final_reasons:Seq Int^many)
  locals { stock allocated reasons idx items qtys whole } {
    [ stock allocated reasons ]
    [ items idx prim seq-int.at locals { item } { qtys idx prim seq-int.at stock item prim seq-int.at locals { qty r } { [ [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item r qty prim - prim seq-int.set idx 1 prim + items qtys whole allocate_orders ] ] [ [ [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push idx 1 prim + items qtys whole allocate_orders ] ] [ [ allocated r prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set idx 1 prim + items qtys whole allocate_orders ] [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push idx 1 prim + items qtys whole allocate_orders ] whole idx prim seq-bool.at if ] ] r 0 prim = if ] qty r prim < if } } ]
    idx items prim seq-int.len prim < if
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 102
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
