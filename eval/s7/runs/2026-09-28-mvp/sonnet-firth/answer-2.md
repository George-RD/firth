### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs 0 start 0 ledger-loop }
  ;

: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [ balance txs i prim seq-int.at prim + 0 prim <
      [ txs i 1 prim + balance rejected 1 prim + ]
      [ txs i 1 prim + balance txs i prim seq-int.at prim + rejected ]
      if
      ledger-loop
    ]
    [ balance rejected ]
    if
  }
  ;
```
