Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim >=
    [ xs idx 1 prim - result xs idx prim seq-int.at prim seq-int.push reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ n prim seq-int.empty digit-loop n prim seq-int.empty reverse-loop ]
    if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [5, 0, 3]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 304}}, {'kind': 'literal', 'literal': {'type': 

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
: insert-loop
  (forall ρ; ρ result:Seq Int^many val:Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result val idx } {
    idx 0 prim >=
    [ result idx prim seq-int.at val prim <=
      [ result val idx 1 prim + insert-loop ]
      [ result idx val prim seq-int.set ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [ result xs idx prim seq-int.at 0 insert-loop xs idx 1 prim + swap sort-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3, 1, 2]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type': 's

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: alloc-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many oidx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole oidx allocated reasons } {
    oidx qtys prim seq-int.len prim <
    [
      stock items oidx prim seq-int.at prim seq-int.at qtys oidx prim seq-int.at prim <=
      [
        items oidx prim seq-int.at dup
        stock swap items oidx prim seq-int.at prim seq-int.at qtys oidx prim seq-int.at prim - prim seq-int.set
        items qtys whole oidx 1 prim + allocated swap prim seq-int.push reasons 0 prim seq-int.push alloc-loop
      ]
      [
        stock items oidx prim seq-int.at prim seq-int.at 0 prim =
        [
          stock items qtys whole oidx 1 prim + allocated 0 prim seq-int.push reasons 2 prim seq-int.push alloc-loop
        ]
        [
          whole oidx prim seq-bool.at
          [
            stock items qtys whole oidx 1 prim + allocated 0 prim seq-int.push reasons 3 prim seq-int.push alloc-loop
          ]
          [
            stock items oidx prim seq-int.at swap 0 prim seq-int.set
            items qtys whole oidx 1 prim + allocated stock items oidx prim seq-int.at prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push alloc-loop
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty alloc-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: alloc-loop
at: line 30, column 7
message: The two branches of `if` in `alloc-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 3 values, and the false branch pushes 3 values. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
