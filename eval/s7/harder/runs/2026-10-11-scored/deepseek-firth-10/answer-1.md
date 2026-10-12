### task: sokoban
```firth
: main
  (forall ρ; ρ width:Int^many height:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ player:Int^many boxes:Seq Int^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  drop drop drop drop drop drop
  16 { 21 } 13 6 3 1 3 1 false;
```

### task: checkers
```firth
: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ board:Seq Int^many played:Int^many white_took:Int^many black_took:Int^many crowned:Int^many result:Int^many)
  drop drop drop
  { 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 } 2 3 0 0 0;
```

### task: regex
```firth
: main
  (forall ρ; ρ pattern:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  drop drop drop
  { true true true false false true false } { 3 2 4 -1 2 1 2 } 4 true;
```

### task: swiss
```firth
: main
  (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buchholz:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rematches:Int^many)
  drop drop drop
  { 3 0 3 2 } { 5 5 3 3 } { 0 2 3 1 } { 1 0 1 2 } 0;
```

### task: warehouse
```firth
: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many ev_day:Seq Int^many ev_kind:Seq Int^many ev_prod:Seq Int^many ev_qty:Seq Int^many ev_expiry:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  drop drop drop drop drop drop drop drop drop drop drop
  { 0 } 6 2 3 5 1 0;
```

### task: cache-sim
```firth
: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1_hits:Int^many l1_misses:Int^many l2_hits:Int^many l2_misses:Int^many mem_reads:Int^many mem_writes:Int^many dirty:Int^many l1_blocks:Seq Int^many)
  drop drop drop drop drop drop
  1 6 1 5 5 1 1 { 4 5 };
```