Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ i:Int^many total:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i total xs } {
    xs i prim seq-int.len prim <
    [ xs i prim seq-int.at total prim + i 1 prim + swap xs sum-helper ]
    [ total ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 0 xs sum-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.len` in `sum-helper` needs Seq Int on top of the stack, but the stack before it is ρ Int Int Seq Int Seq Int Int.
expected: .. Seq Int
actual: ρ Int Int Seq Int Seq Int Int
hint: The top value is Int but `prim seq-int.len` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ i:Int^many maxval:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i maxval xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at maxval
      [ prim < ]
      [ ]
      if
      [ drop maxval ]
      [ drop ]
      if
      i 1 prim + maxval xs max-helper
    ]
    [ maxval ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1 swap xs max-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 1 fewer value than it takes, and the false branch leaves as many values as it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ i:Int^many count:Int^many k:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i count k xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim + swap k xs count-helper
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { 0 0 xs k count-helper };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `count-helper` in `main` needs Int Int Int Seq Int on top of the stack, but the stack before it is ρ Int Int Seq Int Int.
expected: .. Int Int Int Seq Int
actual: ρ Int Int Seq Int Int
hint: The top value is Int but `count-helper` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i result xs } {
    i 0 prim <
    [ result ]
    [ 
      xs i prim seq-int.at result prim seq-int.push
      i 1 prim -
      swap xs reverse-helper
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - prim seq-int.empty xs reverse-helper
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `reverse-helper` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t28.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: The top value is ?t28 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ i:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { i sum result xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at sum prim +
      dup result prim seq-int.push
      i 1 prim + swap result xs prefix-helper
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty 0 xs prefix-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 2 more values than it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-helper
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at
      dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      i 1 prim + swap xs filter-helper
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs filter-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `filter-helper` leave different stacks.
expected: Int
actual: Seq Int
hint: Both branches must leave the same number and types of values. Expected Int, found Seq Int.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [ 
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ i 1 prim + xs check-sorted ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { 0 xs check-sorted };

```
On the example, it returned [False] instead of [True]

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ i:Int^many xs:Seq Bool^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at
      [ i 1 prim + xs check-all ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { 0 flags check-all };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.len` in `check-all` needs Seq Int on top of the stack, but the stack before it is ρ Int Seq Bool Int Seq Bool.
expected: .. Seq Int
actual: ρ Int Seq Bool Int Seq Bool
hint: The top value is Seq Bool but `prim seq-int.len` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: find-longest
  (forall ρ; ρ i:Int^many count:Int^many max:Int^many prev:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i count max prev xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at dup prev prim =
      [ drop count 1 prim + ]
      [ swap drop 1 ]
      if
      dup max prim <
      [ max ]
      [ ]
      if
      i 1 prim + swap max xs find-longest
    ]
    [ max count prim < [ count ] [ max ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 1 1 0 xs 0 prim seq-int.at xs find-longest ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 1 more value than it takes, and the false branch leaves as many values as it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-pair
  (forall ρ; ρ i:Int^many j:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i j target xs } {
    j xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ i j 1 prim + target xs check-pair ]
      if
    ]
    [ false ]
    if
  };

: check-outer
  (forall ρ; ρ i:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i target xs } {
    i xs prim seq-int.len prim <
    [ 
      i 1 prim + xs prim seq-int.len prim <
      [ i 1 prim + target xs check-pair ]
      [ false ]
      if
      [ true ]
      [ i 1 prim + target xs check-outer ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { 0 target xs check-outer };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves as many values as it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in
  (forall ρ; ρ x:Int^many i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { x i xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at x prim =
      [ true ]
      [ x i 1 prim + xs is-in ]
      if
    ]
    [ false ]
    if
  };

: count-unique
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i count xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at 0 xs is-in
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim + swap xs count-unique
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 0 xs count-unique };

```
On the example, it returned [5] instead of [3]

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i j result xs ys } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j result xs ys merge-helper ]
      [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + result xs ys merge-helper ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j result xs ys merge-helper ]
      [ 
        j ys prim seq-int.len prim <
        [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + result xs ys merge-helper ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { 0 0 prim seq-int.empty xs ys merge-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 2 more values than it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div swap digit-helper
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs result reverse-digits ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ 
      prim seq-int.empty n digit-helper
      0 swap prim seq-int.empty reverse-digits
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 2 more values than it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [ 
      n d prim mod 0 prim =
      [ false ]
      [ n d 1 prim + is-prime ]
      if
    ]
    [ true ]
    if
  };

: sieve-helper
  (forall ρ; ρ i:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { i n result } {
    i n prim < i 1 prim > prim and
    [ 
      i 2 is-prime
      [ i result prim seq-int.push ]
      [ result ]
      if
      i 1 prim + n swap result sieve-helper
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { 2 n prim seq-int.empty sieve-helper };

```
On the example, the run failed:
code: firth.name.unresolved-effect
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at
      dup result prim seq-int.at prim + 
      result swap prim seq-int.set
      i 1 prim + swap xs histogram-helper
    ]
    [ result ]
    if
  };

: init-counts
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ initialized:Seq Int^many)
  locals { i k result } {
    i k prim <
    [ result 0 prim seq-int.push i 1 prim + k swap result init-counts ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { 0 k prim seq-int.empty init-counts xs histogram-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves as many values as it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ x:Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { x i sorted } {
    i 0 prim =
    [ x sorted prim seq-int.push ]
    [
      sorted i 1 prim - prim seq-int.at x prim <
      [ 
        sorted i prim seq-int.set x i 1 prim - sorted insert-sorted
      ]
      [
        x sorted i prim seq-int.at sorted prim seq-int.set
        i prim seq-int.empty insert-sorted
      ]
      if
    ]
    if
  };

: sort-helper
  (forall ρ; ρ i:Int^many sorted:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i sorted xs } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at sorted prim seq-int.len sorted insert-sorted
      i 1 prim + swap xs sort-helper
    ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs sort-helper };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
message: `compose` in `insert-sorted` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int Int Seq Int Bool [ .. -- .. Int Seq Int ] [ .. Seq Int Int -- .. Seq Int ]. Expected Int, found Seq Int.
expected: Int
actual: Seq Int

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: process-txn
  (forall ρ; ρ i:Int^many balance:Int^many rejected:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { i balance rejected txs } {
    i txs prim seq-int.len prim <
    [ 
      txs i prim seq-int.at dup balance prim + 0 prim <
      [ drop rejected 1 prim + ]
      [ balance prim + rejected ]
      if
      i 1 prim + swap rejected txs process-txn
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { 0 start 0 txs process-txn };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves as many values as it takes, and the false branch leaves 1 more value than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-order
  (forall ρ; ρ j:Int^many allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock2:Seq Int^many allocated2:Seq Int^many reasons2:Seq Int^many)
  locals { j allocated reasons stock items qtys whole } {
    j qtys prim seq-int.len prim <
    [
      items j prim seq-int.at dup stock swap prim seq-int.at
      qtys j prim seq-int.at dup
      locals { item stock-of-item qty } {
        qty stock-of-item prim <
        qty stock-of-item prim = prim or
        [
          qty stock-of-item prim <
          [ qty 0 ]
          [ stock-of-item 0 ]
          if
          dup stock item prim seq-int.set
          allocated qty prim seq-int.push 0 reasons prim seq-int.push
        ]
        [
          stock-of-item 0 prim =
          [ 0 2 ]
          [
            whole j prim seq-int.at
            [ 0 3 ]
            [ stock-of-item 1 ]
            if
          ]
          if
          dup stock item prim seq-int.set
          allocated swap prim seq-int.push reasons prim seq-int.push
        ]
        if
        j 1 prim + swap reasons allocated stock items qtys whole process-order
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { 0 prim seq-int.empty prim seq-int.empty stock items qtys whole process-order };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` leave different numbers of values: the true branch leaves 5 more values than it takes, and the false branch leaves 3 more values than it takes.
hint: Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.
