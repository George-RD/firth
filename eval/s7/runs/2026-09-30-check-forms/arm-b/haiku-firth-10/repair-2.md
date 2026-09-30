Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim >
    [
      result n 10 prim mod prim seq-int.push n 10 prim div swap digits-loop
    ]
    [
      result
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many digits:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i digits result } {
    i 0 prim >=
    [
      result digits i prim seq-int.at prim seq-int.push
      locals { result } { i 1 prim - result digits reverse-digits }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ]
    [
      n prim seq-int.empty digits-loop
      locals { digits } {
        digits prim seq-int.len 1 prim - prim seq-int.empty digits reverse-digits
      }
    ]
    if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': []}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 2}}, {'kind': 'literal', 'literal': {'type': 'seq-int'

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ i:Int^many histogram:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i histogram xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup histogram swap prim seq-int.at 1 prim +
      locals { value index } {
        histogram index value prim seq-int.set
        locals { histogram } { i 1 prim + histogram xs histogram-loop }
      }
    ]
    [
      histogram
    ]
    if
  };

: init-hist-loop
  (forall ρ; ρ k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k result } {
    k 0 prim >
    [
      result 0 prim seq-int.push
      locals { result } { k 1 prim - result init-hist-loop }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    0 k prim seq-int.empty init-hist-loop xs histogram-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [0, 2, 2, 1, 2]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'typ

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: find-min-loop
  (forall ρ; ρ j:Int^many min-idx:Int^many min-val:Int^many xs:Seq Int^many -- ρ min-idx:Int^many)
  locals { j min-idx min-val xs } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at min-val prim <
      [
        j j xs j prim seq-int.at xs find-min-loop
      ]
      [
        min-idx j 1 prim + min-val xs find-min-loop
      ]
      if
    ]
    [
      min-idx
    ]
    if
  };

: find-min
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ min-idx:Int^many)
  locals { i xs } {
    i 1 prim + i xs i prim seq-int.at xs find-min-loop
  };

: sort-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [
      i xs find-min xs swap prim seq-int.at result swap prim seq-int.push
      locals { result } { i 1 prim + result xs sort-loop }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    0 prim seq-int.empty xs sort-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3, 1, 2]}}, {'kind': 'literal', 'literal': {'type': 's

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ i:Int^many balance:Int^many rejected:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { i balance rejected txs } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + dup 0 prim >=
      [
        locals { balance } { i 1 prim + balance rejected txs ledger-loop }
      ]
      [
        drop i 1 prim + balance rejected 1 prim + swap txs ledger-loop
      ]
      if
    ]
    [
      balance rejected
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    0 start 0 txs ledger-loop
  };

```
On the example, it returned [20, 1] instead of [4, 1]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ o:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { o stock allocated reasons } {
    o 4 prim <
    [
      allocated 0 prim seq-int.push reasons 0 prim seq-int.push
      locals { allocated reasons } { o 1 prim + stock allocated reasons allocate-loop }
    ]
    [
      stock allocated reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0 stock prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, it returned [[10, 3], [0, 0, 0, 0], [0, 0, 0, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
