Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 find-pair };

: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { xi } {
        xs target xi i 1 prim + find-pair-inner
      }
    ] [
      false
    ] if
  };

: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many xi:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target xi j } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at locals { xj } {
        xi xj prim + target prim = [
          true
        ] [
          xs target xi j 1 prim + find-pair-inner
        ] if
      }
    ] [
      xs target xs prim seq-int.len find-pair
    ] if
  };

```
On the example, it returned [False] instead of [True]

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
    n 0 prim = [
      { 0 }
    ] [
      n 0 prim < [
        n 0 prim - prim seq-int.empty extract-digits
      ] [
        n prim seq-int.empty extract-digits
      ] if
    ] if
  };

: extract-digits
  (forall ρ; ρ n:Int^many acc:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n acc } {
    n 0 prim > [
      n 10 prim mod locals { digit } {
        acc digit prim seq-int.push locals { newacc } {
          n 10 prim div newacc extract-digits
        }
      }
    ] [
      acc
    ] if
  };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs 0 xs prim seq-int.len 1 prim - insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many arr:Seq Int^many start:Int^many end:Int^many -- ρ sorted:Seq Int^many)
  locals { xs arr start end } {
    start end prim <= [
      xs arr start 1 prim + end insertion-sort locals { sorted } {
        sorted start insert-element
      }
    ] [
      arr
    ] if
  };

: insert-element
  (forall ρ; ρ sorted:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { sorted i } {
    i 0 prim > [
      sorted i prim seq-int.at locals { curr } {
        sorted i 1 prim - prim seq-int.at locals { prev } {
          curr prev prim < [
            sorted i prev prim seq-int.set locals { swapped } {
              swapped i 1 prim - insert-element
            }
          ] [
            sorted
          ] if
        }
      }
    ] [
      sorted
    ] if
  };

```
On the example, it returned [[3, 3, 2]] instead of [[1, 2, 3]]

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs start 0 0 process-transactions };

: process-transactions
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many index:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs balance rejected index } {
    index txs prim seq-int.len prim < [
      txs index prim seq-int.at locals { tx } {
        balance tx prim + 0 prim >= [
          txs balance tx prim + index 1 prim + rejected process-transactions
        ] [
          txs balance index 1 prim + rejected 1 prim + process-transactions
        ] if
      }
    ] [
      balance rejected
    ] if
  };

```
On the example, it returned [4, 3] instead of [4, 1]

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
    stock items qtys whole stock prim seq-int.empty prim seq-int.empty 0 allocate-orders
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many curr-stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole curr-stock allocated reasons order } {
    order items prim seq-int.len prim < [
      items order prim seq-int.at locals { item } {
        qtys order prim seq-int.at locals { qty } {
          whole order prim seq-bool.at locals { must-fill } {
            curr-stock item prim seq-int.at locals { available } {
              qty available prim <= [
                allocated qty prim seq-int.push locals { new-allocated } {
                  curr-stock item qty prim seq-int.set locals { new-stock } {
                    stock items qtys whole new-stock new-allocated reasons 0 prim seq-int.push order 1 prim + allocate-orders
                  }
                }
              ] [
                available 0 prim = [
                  allocated 0 prim seq-int.push locals { new-allocated } {
                    stock items qtys whole curr-stock new-allocated reasons 2 prim seq-int.push order 1 prim + allocate-orders
                  }
                ] [
                  must-fill [
                    allocated 0 prim seq-int.push locals { new-allocated } {
                      stock items qtys whole curr-stock new-allocated reasons 3 prim seq-int.push order 1 prim + allocate-orders
                    }
                  ] [
                    allocated available prim seq-int.push locals { new-allocated } {
                      curr-stock item 0 prim seq-int.set locals { new-stock } {
                        stock items qtys whole new-stock new-allocated reasons 1 prim seq-int.push order 1 prim + allocate-orders
                      }
                    }
                  ] if
                ] if
              ] if
            }
          }
        }
      }
    ] [
      curr-stock allocated reasons
    ] if
  };

```
On the example, it returned [[0, 1], [4, 0, 4, 1], [0, 3, 1, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
