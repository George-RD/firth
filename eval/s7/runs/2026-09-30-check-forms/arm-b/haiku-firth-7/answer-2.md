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
      xs target j 1 prim + find-pair-outer
    ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n 0 prim < [
        n 0 prim - prim seq-int.empty extract-digits reverse-all
      ] [
        n prim seq-int.empty extract-digits reverse-all
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

: reverse-all
  (forall ρ; ρ acc:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { acc } {
    prim seq-int.empty acc acc prim seq-int.len 1 prim - build-reverse
  };

: build-reverse
  (forall ρ; ρ result:Seq Int^many acc:Seq Int^many index:Int^many -- ρ reversed:Seq Int^many)
  locals { result acc index } {
    index 0 prim >= [
      acc index prim seq-int.at locals { val } {
        result val prim seq-int.push locals { newresult } {
          newresult acc index 1 prim - build-reverse
        }
      }
    ] [
      result
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
      xs j xs j 1 prim + prim seq-int.at prim seq-int.set locals { shifted } {
        shifted j 1 prim - key sort-inner
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
