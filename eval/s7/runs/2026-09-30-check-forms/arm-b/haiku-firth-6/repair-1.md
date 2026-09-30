Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target has-pair-helper };

: has-pair-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim >=
    [ false ]
    [
      i 1 prim + xs target check-pair
      [ true ]
      [ i 1 prim + xs target has-pair-helper ]
      if
    ]
    if
  };

: check-pair
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim >=
    [ false ]
    [
      j 2 prim - locals { idx } {
        xs idx prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ j 1 prim + xs target check-pair ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  has-pair-sum;

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 4, 6, 2]}}, {'kind': 'literal', 'literal': {'type':

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-batch
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim >=
    [ stock allocated reasons ]
    [
      items j prim seq-int.at locals { item-id } {
        stock item-id prim seq-int.at locals { current-stock } {
          qtys j prim seq-int.at locals { needed } {
            whole j prim seq-bool.at locals { must-fill } {
              needed current-stock prim <=
              [
                stock item-id needed current-stock prim - prim seq-int.set
                locals { newstock } {
                  newstock allocated needed prim seq-int.push reasons 0 prim seq-int.push j 1 prim + items qtys whole allocate-loop
                }
              ]
              [
                current-stock 0 prim =
                [ stock allocated reasons 2 prim seq-int.push j 1 prim + items qtys whole allocate-loop ]
                [
                  must-fill
                  [ stock allocated reasons 3 prim seq-int.push j 1 prim + items qtys whole allocate-loop ]
                  [
                    stock item-id 0 prim seq-int.set
                    locals { newstock } {
                      newstock allocated current-stock prim seq-int.push reasons 1 prim seq-int.push j 1 prim + items qtys whole allocate-loop
                    }
                  ]
                  if
                ]
                if
              ]
              if
            }
          }
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  allocate-batch;

```
On the example, it returned [[0, -2], [4, -6, 1], [0, 3, 1, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
