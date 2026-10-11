### task: checkers
```firth
: main
  ( board:Seq Int turn:Int plies:Int -- board:Seq Int played:Int whitetook:Int blacktook:Int crowned:Int result:Int )
  drop drop drop
  { 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }
  2
  3
  0
  0
  0
;
```

### task: warehouse
```firth
: main
  ( days:Int price:Seq Int rp:Seq Int rq:Seq Int lead:Seq Int shelf:Seq Int evday:Seq Int evkind:Seq Int evprod:Seq Int evqty:Seq Int evexpiry:Seq Int -- stock:Seq Int earned:Int shipped:Int discarded:Int cancelled:Int supplies:Int owed:Int )
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
  ( s1:Int w1:Int s2:Int w2:Int addrs:Seq Int writes:Seq Bool -- l1hits:Int l1misses:Int l2hits:Int l2misses:Int memreads:Int memwrites:Int dirty:Int l1blocks:Seq Int )
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