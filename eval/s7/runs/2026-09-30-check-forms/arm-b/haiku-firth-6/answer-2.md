### task: has-pair-sum
```firth
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target check-all-pairs };

: check-all-pairs
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim >= 
    [ false ]
    [
      i 1 prim + xs target check-pair-from
      [ true ]
      [ i 1 prim + xs target check-all-pairs ]
      if
    ]
    if
  };

: check-pair-from
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim >=
    [ false ]
    [
      j 2 prim - locals { i } {
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ j 1 prim + xs target check-pair-from ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  has-pair-sum;
```

### task: allocate-batch
```firth
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
                current-stock needed prim - locals { new-val } {
                  stock item-id new-val prim seq-int.set
                  locals { newstock } {
                    newstock allocated needed prim seq-int.push reasons 0 prim seq-int.push j 1 prim + items qtys whole allocate-loop
                  }
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
