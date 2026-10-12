### task: checkers
```firth
: main
  (forall ρ; ρ board:Seq Int turn:Int plies:Int -- ρ board:Seq Int played:Int white-took:Int black-took:Int crowned:Int result:Int)
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
  (forall ρ; ρ days:Int price:Seq Int rp:Seq Int rq:Seq Int lead:Seq Int shelf:Seq Int ev-day:Seq Int ev-kind:Seq Int ev-prod:Seq Int ev-qty:Seq Int ev-expiry:Seq Int -- ρ stock:Seq Int earned:Int shipped:Int discarded:Int cancelled:Int supplies:Int owed:Int)
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
  (forall ρ; ρ s1:Int w1:Int s2:Int w2:Int addrs:Seq Int writes:Seq Bool -- ρ l1-hits:Int l1-misses:Int l2-hits:Int l2-misses:Int mem-reads:Int mem-writes:Int dirty:Int l1-blocks:Seq Int)
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