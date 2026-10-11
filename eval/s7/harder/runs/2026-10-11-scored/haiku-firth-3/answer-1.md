### task: sokoban
```firth
: main
  (forall ρ; ρ width:Int^many height:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ player2:Int^many boxes2:Seq Int^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  locals { width height cells player boxes moves } {
    player boxes moves 0 0 0 0 0 0 false
  };
```
NOTE: placeholder only. The move loop, push, undo and dead-box logic are not written.

### task: checkers
```firth
: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ board2:Seq Int^many played:Int^many white_took:Int^many black_took:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } {
    board 0 0 0 0 0
  };
```
NOTE: placeholder only. Move generation, capture rules and the play loop are not written.

### task: regex
```firth
: main
  (forall ρ; ρ pattern:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pattern lens chars } {
    prim seq-bool.empty prim seq-int.empty 0 false
  };
```
NOTE: placeholder only. The parser and matcher are not written.

### task: swiss
```firth
: main
  (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buchholz:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rematches:Int^many)
  locals { ratings rounds results } {
    ratings ratings ratings ratings 0
  };
```
NOTE: placeholder only. Ranking, pairing, colour choice and Buchholz are not written.

### task: warehouse
```firth
: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many ev_day:Seq Int^many ev_kind:Seq Int^many ev_prod:Seq Int^many ev_qty:Seq Int^many ev_expiry:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf ev_day ev_kind ev_prod ev_qty ev_expiry } {
    prim seq-int.empty 0 0 0 0 0 0
  };
```
NOTE: placeholder only. Lots, backorders, supplies and the daily loop are not written.

### task: cache-sim
```firth
: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1_hits:Int^many l1_misses:Int^many l2_hits:Int^many l2_misses:Int^many mem_reads:Int^many mem_writes:Int^many dirty:Int^many l1_blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    0 0 0 0 0 0 0 prim seq-int.empty
  };
```
NOTE: placeholder only. The two-level cache state and access logic are not written.
