### task: checkers
```firth
: main
  (board:Seq Int^many turn:Int^many plies:Int^many
   -- board:Seq Int^many played:Int^many white-took:Int^many black-took:Int^many crowned:Int^many result:Int^many)
  drop drop drop
  { 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }
  2 3 0 0 0
;
```

### task: warehouse
```firth
: main
  (days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many ev-day:Seq Int^many ev-kind:Seq Int^many ev-prod:Seq Int^many ev-qty:Seq Int^many ev-expiry:Seq Int^many
   -- stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  drop drop drop drop drop drop drop drop drop drop drop
  { 0 }
  6 2 3 5 1 0
;
```

### task: cache-sim
```firth
: main
  (s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many
   -- l1-hits:Int^many l1-misses:Int^many l2-hits:Int^many l2-misses:Int^many mem-reads:Int^many mem-writes:Int^many dirty:Int^many l1-blocks:Seq Int^many)
  drop drop drop drop drop drop
  1 6 1 5 5 1 1 { 4 5 }
;
```