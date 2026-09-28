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
  0 swap 0 sum-loop;

: sum-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many -- ρ result:Int^many)
  locals { i xs sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      i 1 prim + xs swap sum-loop
    ]
    [
      sum
    ]
    if
  };

```
On the example, it returned [1] instead of [15]

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs max-loop
  };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup max prim <
      [ drop max ]
      [ swap drop ]
      if
      i 1 prim + xs swap max-loop
    ]
    [
      max
    ]
    if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.untracked-local', 'severity': 'error', 'message_key': 'diagnostic.u

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 swap 0 count-loop;

: count-loop
  (forall ρ; ρ i:Int^many k:Int^many xs:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { i k xs count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup k prim <
      [ drop count 1 prim + ]
      [ drop count ]
      if
      i 1 prim + k xs swap count-loop
    ]
    [
      count
    ]
    if
  };

```
On the example, it returned [0] instead of [2]

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty swap 0 reverse-loop;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim + xs swap reverse-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `reverse-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t20.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: The top value is ?t20 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 swap prefix-loop;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      dup result prim seq-int.push
      i 1 prim + xs swap result swap prefix-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `prefix-loop` in `main` needs Seq Int Int Int Seq Int on top of the stack, but the stack before it is \u03c1 Seq Int Seq Int Int Int.
expected: .. Seq Int Int Int Seq Int
actual: \u03c1 Seq Int Seq Int Int Int
hint: The top value is Int but `prefix-loop` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty swap 0 filter-positive;

: filter-positive
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup 0 prim <
      [
        drop
        i 1 prim + xs result filter-positive
      ]
      [
        result prim seq-int.push
        i 1 prim + xs swap filter-positive
      ]
      if
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `filter-positive` in `filter-positive` needs Seq Int Seq Int Int on top of the stack, but the stack before it is .. Int ?t52 ?t54.
expected: .. Seq Int Seq Int Int
actual: .. Int ?t52 ?t54
hint: The top value is ?t54 but `filter-positive` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    xs prim seq-int.len 1 prim <
    [ true ]
    [
      1 xs true check-sorted
    ]
    if
  };

: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many ok:Bool^many -- ρ result:Bool^many)
  locals { i xs ok } {
    ok prim not
    [ false ]
    [
      i xs prim seq-int.len prim <
      [
        xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim <
        [
          false
          i 1 prim + xs false check-sorted
        ]
        [
          i 1 prim + xs true check-sorted
        ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.occurs-check
message: `if` in `check-sorted` failed the check firth.type.occurs-check; the stack before it is .. Bool [ .. -- .. Bool Bool ] [ .. -- .. Bool ]. Expected .. Bool, found ...
expected: .. Bool
actual: ..

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 swap true check-all-true;

: check-all-true
  (forall ρ; ρ i:Int^many flags:Seq Bool^many ok:Bool^many -- ρ result:Bool^many)
  locals { i flags ok } {
    ok prim not
    [ false ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at prim not
        [
          false
          i 1 prim + flags false check-all-true
        ]
        [
          i 1 prim + flags true check-all-true
        ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.occurs-check
message: `if` in `check-all-true` failed the check firth.type.occurs-check; the stack before it is .. Bool [ .. -- .. Bool Bool ] [ .. -- .. Bool ]. Expected .. Bool, found ...
expected: .. Bool
actual: ..

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [
    xs 0 prim seq-int.at 1 0 1 longest-run-loop
  ]
  if;

: longest-run-loop
  (forall ρ; ρ prev:Int^many current:Int^many max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { prev current max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup prev prim =
      [ drop current 1 prim + ]
      [ swap drop 1 ]
      if
      dup max [ prim < ] dip
      [ ]
      [ swap drop ]
      if
      i 1 prim + xs swap swap swap longest-run-loop
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 swap false check-pair-sum;

: check-pair-sum
  (forall ρ; ρ i:Int^many target:Int^many xs:Seq Int^many found:Bool^many -- ρ result:Bool^many)
  locals { i target xs found } {
    found prim not
    [
      i xs prim seq-int.len prim <
      [
        0 i target xs check-j-loop
      ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: check-j-loop
  (forall ρ; ρ j:Int^many i:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { j i target xs } {
    j xs prim seq-int.len prim <
    [
      j i prim =
      [
        j 1 prim + i target xs check-j-loop
      ]
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [
          j 1 prim + i target xs check-j-loop
        ]
        if
      ]
      if
    ]
    [
      i 1 prim + target xs check-pair-sum
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
message: `compose` in `check-j-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is \u03c1 Bool [ .. -- .. Bool ] [ .. Int -- .. Int Int Int Seq Int ] [ .. Int Int Seq Int Bool -- .. Bool ]. Expected Int, found Seq Int.
expected: Int
actual: Seq Int

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty swap 0 count-distinct-loop;

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { seen xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 seen find-in-seq
      0 prim <
      [
        seen prim seq-int.push
        i 1 prim + xs swap count-distinct-loop
      ]
      [
        drop
        i 1 prim + xs swap count-distinct-loop
      ]
      if
    ]
    [ seen prim seq-int.len ]
    if
  };

: find-in-seq
  (forall ρ; ρ x:Int^many j:Int^many seen:Seq Int^many -- ρ index:Int^many)
  locals { x j seen } {
    j seen prim seq-int.len prim <
    [
      seen j prim seq-int.at x prim =
      [ j ]
      [ x j 1 prim + seen find-in-seq ]
      if
    ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
message: `compose` in `count-distinct-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Seq Int Int Int Bool [ .. Seq Int -- .. Seq Int Seq Int Int Seq Int ] [ .. Seq Int Int Int Seq Int -- .. Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty swap 0 0 swap merge-loop;

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many j:Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result xs i j ys } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim + j ys xs swap merge-loop
      ]
      [
        ys j prim seq-int.at result prim seq-int.push
        i j 1 prim + ys xs swap merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim + j ys xs swap merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at result prim seq-int.push
          i j 1 prim + ys xs swap merge-loop
        ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `merge-loop` in `main` needs Seq Int Seq Int Int Int Seq Int on top of the stack, but the stack before it is \u03c1 Seq Int Seq Int Seq Int Int Int.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: \u03c1 Seq Int Seq Int Seq Int Int Int
hint: The top value is Int but `merge-loop` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty n extract-digits
    ]
    if
  };

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      swap extract-digits
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `extract-digits` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t18.
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: The top value is ?t18 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 collect-primes;

: collect-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
        candidate 1 prim + n collect-primes
      ]
      [
        candidate 1 prim + n collect-primes
      ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        2 n check-divisor
      ]
      if
    ]
    if
  };

: check-divisor
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [
        d 1 prim + n check-divisor
      ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `collect-primes` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is \u03c1 Int Seq Int Int.
expected: .. Seq Int Int Int
actual: \u03c1 Int Seq Int Int
hint: The second value from the top is Seq Int but `collect-primes` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 0 k 0 xs init-and-build
  };

: init-and-build
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many j:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i k j xs } {
    i k prim <
    [
      0 result prim seq-int.push
      i 1 prim + k j xs init-and-build
    ]
    [
      j xs prim seq-int.len prim <
      [
        xs j prim seq-int.at
        dup result swap prim seq-int.at 1 prim + swap prim seq-int.push
        j 1 prim + xs init-and-build
      ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `init-and-build` needs Seq Int Int on top of the stack, but the stack before it is .. ?t49 ?t48 ?t47 ?t46 Int ?t50.
expected: .. Seq Int Int
actual: .. ?t49 ?t48 ?t47 ?t46 Int ?t50
hint: The top value is ?t50 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty swap 0 insertion-sort;

: insertion-sort
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0 result insert-at-pos
      i 1 prim + xs swap insertion-sort
    ]
    [ result ]
    if
  };

: insert-at-pos
  (forall ρ; ρ pos:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { pos result val } {
    pos result prim seq-int.len prim <
    [
      result pos prim seq-int.at val prim <
      [
        val result prim seq-int.push
        pos result insert-at-pos
      ]
      [
        pos 1 prim + result val insert-at-pos
      ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `insert-at-pos` in `insertion-sort` needs Int Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int Int ?t20.
expected: .. Int Seq Int Int
actual: .. Seq Int Int Int Int ?t20
hint: The top value is ?t20 but `insert-at-pos` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 swap start 0 process-ledger;

: process-ledger
  (forall ρ; ρ i:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { i txs balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      dup balance prim + 0 prim <
      [
        drop
        rejected 1 prim + i txs balance process-ledger
      ]
      [
        balance prim + rejected
        i 1 prim + txs swap process-ledger
      ]
      if
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `start` is not a defined word, primitive or local.
actual: start

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 process-orders;

: process-orders
  (forall ρ; ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { allocated reasons stock i items qtys whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      stock over prim seq-int.at
      qtys i prim seq-int.at
      dup2 prim <
      [
        whole i prim seq-bool.at prim not
        [
          allocated prim seq-int.push
          reasons 1 prim seq-int.push
          stock swap prim -
        ]
        [
          drop drop
          0 allocated prim seq-int.push
          reasons 3 prim seq-int.push
        ]
        if
        swap stock swap prim seq-int.push
        i 1 prim + items qtys whole process-orders
      ]
      [
        0 prim =
        [
          0 allocated prim seq-int.push
          reasons 2 prim seq-int.push
          stock
        ]
        [
          prim seq-int.push allocated prim seq-int.push
          reasons 0 prim seq-int.push
        ]
        if
        i 1 prim + items qtys whole process-orders
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim send`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.
