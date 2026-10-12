### task: sokoban
```firth
: main
  (forall ρ; ρ width:Int^many height:Int^many cells:Seq^many player:Int^many boxes:Seq^many moves:Seq^many -- ρ player:Int^many boxes:Seq^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  locals { width height cells player boxes moves } {
    0 0 0 0 0 0 0 0 0 prim seq-int.empty
  };
NOTE: skeleton only, not compiled or run. The move loop, push and dead-box logic are not implemented, so the outputs above are placeholders and do not follow the task.
```

### task: checkers
```firth
: main
  (forall ρ; ρ board:Seq^many turn:Int^many plies:Int^many -- ρ board:Seq^many played:Int^many white_took:Int^many black_took:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } {
    board 0 0 0 0 0
  };
NOTE: skeleton only, not compiled or run. Move generation, capture rules and the move loop are not implemented, so the outputs are placeholders.
```

### task: regex
```firth
: main
  (forall ρ; ρ pattern:Seq^many lens:Seq^many chars:Seq^many -- ρ full:Seq^many longest:Seq^many count:Int^many valid:Bool^many)
  locals { pattern lens chars } {
    lens { 0 0 0 0 0 0 0 0 } prim seq-int.empty
    false 0
  };
NOTE: skeleton only, not compiled or run. The parser and matcher are not implemented, so the outputs are placeholders.
```

### task: swiss
```firth
: main
  (forall ρ; ρ ratings:Seq^many rounds:Int^many results:Seq^many -- ρ scores:Seq^many buchholz:Seq^many ranking:Seq^many whites:Seq^many rematches:Int^many)
  locals { ratings rounds results } {
    ratings ratings ratings ratings 0
  };
NOTE: skeleton only, not compiled or run. Ranking, bye, pairing and the Buchholz sums are not implemented, so the outputs are placeholders.
```

### task: warehouse
```firth
: main
  (forall ρ; ρ days:Int^many price:Seq^many rp:Seq^many rq:Seq^many lead:Seq^many shelf:Seq^many ev_day:Seq^many ev_kind:Seq^many ev_prod:Seq^many ev_qty:Seq^many ev_expiry:Seq^many -- ρ stock:Seq^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf ev_day ev_kind ev_prod ev_qty ev_expiry } {
    price prim seq-int.empty 0 0 0 0 0 0
  };
NOTE: skeleton only, not compiled or run. Lots, backorders, expiry and supply ordering are not implemented, so the outputs are placeholders.
```

### task: cache-sim
```firth
: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq^many writes:Seq^many -- ρ l1_hits:Int^many l1_misses:Int^many l2_hits:Int^many l2_misses:Int^many mem_reads:Int^many mem_writes:Int^many dirty:Int^many l1_blocks:Seq^many)
  locals { s1 w1 s2 w2 addrs writes } {
    0 0 0 0 0 0 0 addrs
  };
NOTE: skeleton only, not compiled or run. The two-level LRU simulation is not implemented, so the outputs are placeholders.
