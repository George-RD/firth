### task: sokoban
```firth
: main
  (forall ρ; ρ width:Int^many height:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ player:Int^many boxes:Seq Int^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  locals { width height cells player boxes moves } {
    0 prim seq-int.empty 0 0 0 0 0 0 0 0 prim =
  };
NOTE: placeholder that type-checks the signature only. The move loop, pushes, blocked moves and dead-box logic are not implemented, so the example output will not match.
```

### task: checkers
```firth
: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ board:Seq Int^many played:Int^many white-took:Int^many black-took:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } {
    board 0 0 0 0 0
  };
NOTE: placeholder that type-checks the signature only. Move generation, capture rules and the move loop are not implemented, so the example output will not match.
```

### task: regex
```firth
: main
  (forall ρ; ρ pattern:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pattern lens chars } {
    prim seq-bool.empty prim seq-int.empty 0 0 0 prim =
  };
NOTE: placeholder that type-checks the signature only. The parser and matcher are not implemented, so the example output will not match.
```

### task: swiss
```firth
: main
  (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buchholz:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rematches:Int^many)
  locals { ratings rounds results } {
    prim seq-int.empty prim seq-int.empty prim seq-int.empty prim seq-int.empty 0
  };
NOTE: placeholder that type-checks the signature only. Ranking, byes, pairing and Buchholz sums are not implemented, so the example output will not match.
```

### task: warehouse
```firth
: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many ev-day:Seq Int^many ev-kind:Seq Int^many ev-prod:Seq Int^many ev-qty:Seq Int^many ev-expiry:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf ev-day ev-kind ev-prod ev-qty ev-expiry } {
    prim seq-int.empty 0 0 0 0 0 0
  };
NOTE: placeholder that type-checks the signature only. Lots, backorders, expiry and supply ordering are not implemented, so the example output will not match.
```

### task: cache-sim
```firth
: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1-hits:Int^many l1-misses:Int^many l2-hits:Int^many l2-misses:Int^many mem-reads:Int^many mem-writes:Int^many dirty:Int^many l1-blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    0 0 0 0 0 0 0 prim seq-int.empty
  };
NOTE: placeholder that type-checks the signature only. The two-level LRU simulation is not implemented, so the example output will not match.
