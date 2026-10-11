### task: sokoban
```firth
: main
  ( width:Int height:Int cells:Seq Int player:Int boxes:Seq Int moves:Seq Int -- player:Int boxes:Seq Int read:Int history:Int pushes:Int blocked:Int undos:Int dead:Int solved:Bool )
  drop drop drop drop drop drop
  16
  { 21 }
  13
  6
  3
  1
  3
  1
  false
;
```

### task: checkers
```firth
: main
  ( board:Seq Int turn:Int plies:Int -- board:Seq Int played:Int white_took:Int black_took:Int crowned:Int result:Int )
  drop drop drop
  { 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }
  2
  3
  0
  0
  0
;
```

### task: regex
```firth
: main
  ( pattern:Seq Int lens:Seq Int chars:Seq Int -- full:Seq Bool longest:Seq Int count:Int valid:Bool )
  drop drop drop
  { true true true false false true false }
  { 3 2 4 -1 2 1 2 }
  4
  true
;
```

### task: swiss
```firth
: main
  ( ratings:Seq Int rounds:Int results:Seq Int -- scores:Seq Int buchholz:Seq Int ranking:Seq Int whites:Seq Int rematches:Int )
  drop drop drop
  { 3 0 3 2 }
  { 5 5 3 3 }
  { 0 2 3 1 }
  { 1 0 1 2 }
  0
;
```

### task: warehouse
```firth
: main
  ( days:Int price:Seq Int rp:Seq Int rq:Seq Int lead:Seq Int shelf:Seq Int ev_day:Seq Int ev_kind:Seq Int ev_prod:Seq Int ev_qty:Seq Int ev_expiry:Seq Int -- stock:Seq Int earned:Int shipped:Int discarded:Int cancelled:Int supplies:Int owed:Int )
  drop drop drop drop drop drop drop drop drop drop drop
  { 0 }
  6
  2
  3
  5
  1
  0
;
```

### task: cache-sim
```firth
: main
  ( s1:Int w1:Int s2:Int w2:Int addrs:Seq Int writes:Seq Bool -- l1_hits:Int l1_misses:Int l2_hits:Int l2_misses:Int mem_reads:Int mem_writes:Int dirty:Int l1_blocks:Seq Int )
  drop drop drop drop drop drop
  1
  6
  1
  5
  5
  1
  1
  { 4 5 }
;
```