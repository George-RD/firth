### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 find-pair-outer };

: find-pair-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { xi } {
        xs target xi i i 1 prim + find-pair-inner
      }
    ] [
      false
    ] if
  };

: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many xi:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target xi i j } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at locals { xj } {
        xi xj prim + target prim = [
          true
        ] [
          xs target xi i j 1 prim + find-pair-inner
        ] if
      }
    ] [
      xs target i 1 prim + find-pair-outer
    ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 1 sort-outer };

: sort-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { key } {
        xs i 1 prim - key sort-inner
      }
    ] [
      xs
    ] if
  };

: sort-inner
  (forall ρ; ρ xs:Seq Int^many j:Int^many key:Int^many -- ρ result:Seq Int^many)
  locals { xs j key } {
    j 0 prim >= xs j prim seq-int.at key prim > prim and [
      xs j 1 prim + prim seq-int.at locals { source-val } {
        xs j source-val prim seq-int.set locals { shifted } {
          shifted key j 1 prim - sort-inner
        }
      }
    ] [
      xs j 1 prim + key prim seq-int.set locals { inserted } {
        inserted j 2 prim + sort-outer
      }
    ] if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 process-transactions };

: process-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many index:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs index } {
    index txs prim seq-int.len prim < [
      txs index prim seq-int.at locals { tx } {
        balance tx prim + 0 prim >= [
          balance tx prim + rejected txs index 1 prim + process-transactions
        ] [
          balance rejected 1 prim + txs index 1 prim + process-transactions
        ] if
      }
    ] [
      balance rejected
    ] if
  };
```

### task: allocate-batch
```firth
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
                  curr-stock item available qty prim - prim seq-int.set locals { new-stock } {
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
