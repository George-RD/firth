### task: checkers
```firth
: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ board:Seq Int^many played:Int^many whitetook:Int^many blacktook:Int^many crowned:Int^many result:Int^many)
  drop drop drop
  { 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 } 2 3 0 0 0 ;
```

### task: warehouse
```firth
: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many evday:Seq Int^many evkind:Seq Int^many evprod:Seq Int^many evqty:Seq Int^many evexpiry:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  drop drop drop drop drop drop drop drop drop drop drop
  { 0 } 6 2 3 5 1 0 ;
```

### task: cache-sim
```firth
: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1hits:Int^many l1misses:Int^many l2hits:Int^many l2misses:Int^many memreads:Int^many memwrites:Int^many dirty:Int^many l1blocks:Seq Int^many)
  drop drop drop drop drop drop
  1 6 1 5 5 1 1 { 4 5 } ;
```