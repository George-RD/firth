Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: runloop (forall ρ; ρ xs:Seq Int^many i:Int^many cr:Int^many mr:Int^many -- ρ length:Int^many) locals { xs i cr mr } { i xs prim seq-int.len prim >= [ mr cr prim > [ cr ] [ mr ] if ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [ xs i 1 prim + cr 1 prim + mr runloop ] [ mr cr prim > [ xs i 1 prim + 1 cr runloop ] [ xs i 1 prim + 1 mr runloop ] if ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many) locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 1 1 0 runloop ] if };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 1, 2, 2, 2, 1]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 5}}, {'kind': 'literal', 'literal': {'

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: seenloop (forall ρ; ρ xs:Seq Int^many v:Int^many j:Int^many -- ρ found:Bool^many) locals { xs v j } { j xs prim seq-int.len prim >= [ false ] [ xs j prim seq-int.at v prim = [ true ] [ xs v j 1 prim + seenloop ] if ] if };

: uniqloop (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many -- ρ result:Int^many) locals { xs i cnt } { i xs prim seq-int.len prim >= [ cnt ] [ xs xs i prim seq-int.at 0 seenloop [ xs i 1 prim + cnt 1 prim + uniqloop ] [ xs i 1 prim + cnt uniqloop ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many) locals { xs } { xs 0 0 uniqloop };

```
On the example, it returned [5] instead of [3]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: dgtloop (forall ρ; ρ n:Int^many d:Seq Int^many -- ρ result:Seq Int^many) locals { n d } { n 0 prim = [ d ] [ d n 10 prim mod prim seq-int.push locals { nd } { n 10 prim div nd dgtloop } ] if };

: main (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many) locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ n prim seq-int.empty dgtloop ] if };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertloop (forall ρ; ρ a:Seq Int^many j:Int^many -- ρ sorted:Seq Int^many) locals { a j } { j 0 prim <= [ a ] [ a j prim seq-int.at a j 1 prim - prim seq-int.at prim <= [ a ] [ a j 1 prim - prim seq-int.at locals { pv } { a j prim seq-int.at locals { cv } { a j pv prim seq-int.set locals { a1 } { a1 j 1 prim - cv prim seq-int.set locals { a2 } { a2 j 1 prim - insertloop } } } } ] if ] if };

: sortloop (forall ρ; ρ a:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many) locals { a i } { i a prim seq-int.len prim >= [ a ] [ a i insertloop locals { asrt } { asrt i 1 prim + sortloop } ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many) locals { xs } { xs 1 sortloop };

```
On the example, it returned [[3, 2, 1]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocloop (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stkl:Seq Int^many allcd:Seq Int^many rsns:Seq Int^many) locals { stock items qtys whole idx alloc reasons } { idx qtys prim seq-int.len prim >= [ stock alloc reasons ] [ items idx prim seq-int.at locals { item } { qtys idx prim seq-int.at locals { qty } { stock item prim seq-int.at locals { avail } { whole idx prim seq-bool.at locals { mf } { qty avail prim <= [ stock item qty prim seq-int.set locals { ns } { ns items qtys whole idx 1 prim + alloc qty prim seq-int.push reasons 0 prim seq-int.push allocloop } ] [ avail 0 prim = [ stock items qtys whole idx 1 prim + alloc 0 prim seq-int.push reasons 2 prim seq-int.push allocloop ] [ mf [ stock items qtys whole idx 1 prim + alloc 0 prim seq-int.push reasons 3 prim seq-int.push allocloop ] [ stock item 0 prim seq-int.set locals { ns } { ns items qtys whole idx 1 prim + alloc avail prim seq-int.push reasons 1 prim seq-int.push allocloop } ] if ] if ] if } } } } ] if };

: main (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stockleft:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many) locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocloop };

```
On the example, it returned [[0, 1], [4, 0, 4, 1], [0, 3, 1, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
