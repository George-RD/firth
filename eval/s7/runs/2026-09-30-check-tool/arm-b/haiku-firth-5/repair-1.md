Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: loop-max
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup max prim <
      [ ]
      [ drop max ]
      if
      xs i 1 prim + loop-max
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at xs 1 loop-max
  };

```
On the example, it returned [2] instead of [9]

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: loop-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim <
    [ result xs i prim seq-int.at prim seq-int.push xs i 1 prim - loop-reverse ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - loop-reverse
  };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: loop-keep
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup 0 prim <
      [ drop result xs i 1 prim + loop-keep ]
      [ result swap prim seq-int.push xs i 1 prim + loop-keep ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 loop-keep
  };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: loop-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + loop-sorted ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 loop-sorted
  };

```
On the example, it returned [False] instead of [True]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: loop-run
  (forall ρ; ρ max:Int^many current:Int^many xs:Seq Int^many i:Int^many last:Int^many -- ρ length:Int^many)
  locals { max current xs i last } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup last prim =
      [ drop current 1 prim + dup max prim <
        [ drop max ]
        [ ]
        if
        current 1 prim + xs i 1 prim + last loop-run
      ]
      [ drop max 1 xs i 1 prim + dup xs swap prim seq-int.at loop-run ]
      if
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 1 xs 1 xs 0 prim seq-int.at loop-run ]
    if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'int', 'value': 3}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 1}}, {'kind': 'literal', 'literal': {'type': 'seq-int', 'va

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: collect-digits-rev
  (forall ρ; ρ seq:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { seq n } {
    n 0 prim =
    [ seq ]
    [ seq n 10 prim mod prim seq-int.push n 10 prim div collect-digits-rev ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result seq i } {
    i 0 prim <
    [ result seq i prim seq-int.at prim seq-int.push seq i 1 prim - reverse-digits ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n collect-digits-rev dup prim seq-int.len 1 prim - prim seq-int.empty swap reverse-digits ]
    if
  };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [ n d prim mod 0 prim =
      [ false ]
      [ n d 1 prim + is-prime-loop ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 is-prime-loop ]
    if
  };

: loop-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { result i limit } {
    i limit prim <
    [ i is-prime
      [ result i prim seq-int.push locals { result } { result i 1 prim + limit loop-primes } ]
      [ result i 1 prim + limit loop-primes ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n loop-primes
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-step
  (forall ρ; ρ sorted:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted xs i } {
    i xs prim seq-int.len prim <
    [ sorted xs i prim seq-int.at prim seq-int.push locals { sorted } { sorted xs i 1 prim + insert-step } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ prim seq-int.empty ]
    [ prim seq-int.empty xs 0 insert-step ]
    if
  };

```
On the example, it returned [[3, 1, 2]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-order
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock allocated reasons item qty whole } {
    stock item prim seq-int.at dup qty prim <
    [ drop allocated qty prim seq-int.push reasons 0 prim seq-int.push stock ]
    [ dup 0 prim =
      [ drop allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock ]
      [ whole
        [ drop allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock ]
        [ drop allocated stock item prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set ]
        if
      ]
      if
    ]
    if
  };

: loop-allocate
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock items qtys whole allocated reasons idx } {
    idx qtys prim seq-int.len prim <
    [ stock allocated reasons items idx prim seq-int.at qtys idx prim seq-int.at whole idx prim seq-bool.at process-order locals { stock-out allocated-out reasons-out } { stock-out items qtys whole allocated-out reasons-out idx 1 prim + loop-allocate } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole prim seq-int.empty prim seq-int.empty 0 loop-allocate
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [0, 1, 0, 1]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type':
