Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ max-len:Int^many)
  locals { xs idx current-val current-len max-len } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at current-val prim = 
      [ xs idx 1 prim + current-val current-len 1 prim + current-len max-len prim > [ current-len 1 prim + ] [ max-len ] if run-loop ]
      [ xs idx 1 prim + xs idx prim seq-int.at current-len 1 prim + current-len max-len prim > [ current-len ] [ max-len ] if run-loop ]
      if
    ]
    [ current-len max-len prim > [ current-len ] [ max-len ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim >
    [ xs 0 xs 0 prim seq-int.at 1 0 run-loop ]
    [ 0 ]
    if
  };

```
On the example, it returned [7] instead of [3]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-count
  (forall ρ; ρ xs:Seq Int^many val:Int^many idx:Int^many -- ρ found:Bool^many)
  locals { xs val idx } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at val prim =
      [ true ]
      [ xs val idx 1 prim + inner-count ]
      if
    ]
    [ false ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many seen:Seq Int^many cnt:Int^many -- ρ cnt:Int^many)
  locals { xs idx seen cnt } {
    idx xs prim seq-int.len prim <
    [ xs xs idx prim seq-int.at 0 inner-count
      [ xs idx 1 prim + seen cnt 1 prim + count-loop ]
      [ xs idx 1 prim + seen cnt count-loop ]
      if
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty 0 count-loop
  };

```
On the example, it returned [5] instead of [3]

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many xi:Int^many yi:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys xi yi result } {
    xi xs prim seq-int.len prim < yi ys prim seq-int.len prim < prim and
    [ xs ys xi yi 1 prim + xs xi prim seq-int.at ys yi prim seq-int.at prim <= [ result xs xi prim seq-int.at prim seq-int.push ] [ result ys yi prim seq-int.at prim seq-int.push ] if merge-loop ]
    [ xi xs prim seq-int.len prim <
      [ xs ys xi 1 prim + yi result xs xi prim seq-int.at prim seq-int.push merge-loop ]
      [ yi ys prim seq-int.len prim <
        [ xs ys xi yi 1 prim + result ys yi prim seq-int.at prim seq-int.push merge-loop ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-loop
  };

```
On the example, it returned [[1, 1, 1, 1, 4, 9]] instead of [[1, 2, 3, 4, 9, 10]]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim >
    [ n 10 prim div result n 10 prim mod prim seq-int.push digit-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ n prim seq-int.empty digit-loop ]
    if
  };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: count-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many idx:Int^many cnt:Int^many -- ρ cnt:Int^many)
  locals { xs val idx cnt } {
    idx xs prim seq-int.len prim <
    [ xs val idx 1 prim + xs idx prim seq-int.at val prim = [ cnt 1 prim + ] [ cnt ] if count-value ]
    [ cnt ]
    if
  };

: hist-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k idx result } {
    idx k prim <
    [ xs idx 0 0 count-value result swap prim seq-int.push idx 1 prim + xs k swap hist-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    xs k 0 prim seq-int.empty hist-loop
  };

```
On the example, it returned [[0, 2, 2, 1, 2]] instead of [[1, 1, 3]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result val idx } {
    idx result prim seq-int.len prim <
    [ result idx prim seq-int.at val prim > [ result idx val prim seq-int.set ] [ result val prim seq-int.push ] if ]
    [ result val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [ xs idx 1 prim + result xs idx prim seq-int.at 0 insert-sorted sort-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, it returned [[1, 2]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty
  };

```
On the example, it returned [[10, 3], [], []] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
