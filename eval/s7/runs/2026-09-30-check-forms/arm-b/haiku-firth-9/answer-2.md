### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 0 prim seq-int.at 1 1 1 xs loop-run ] if };

: loop-run
  (forall ρ; ρ max:Int^many curr:Int^many prev:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max curr prev idx xs } { idx xs prim seq-int.len prim = [ max ] [ idx xs swap prim seq-int.at locals { elem } { elem prev prim = [ curr 1 prim + dup max prim > [ swap drop ] [ ] if idx 1 prim + xs loop-run ] [ 1 max prim > [ max idx 1 prim + xs loop-run ] [ 1 idx 1 prim + xs loop-run ] if ] if } ] if };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { false 0 xs target loop-pair };

: loop-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } { found [ i xs prim seq-int.len prim < ] prim and [ i 1 prim + i xs target loop-pair-inner ] [ found ] if };

: loop-pair-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } { j xs prim seq-int.len prim < [ i xs swap prim seq-int.at j xs swap prim seq-int.at prim + target prim = [ true ] [ j 1 prim + i xs target loop-pair-inner ] if ] [ false i xs target loop-pair ] if };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 0 xs loop-distinct };

: loop-distinct
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx xs } { idx xs prim seq-int.len prim = [ count ] [ idx xs swap prim seq-int.at 0 idx xs count loop-check-distinct ] if };

: loop-check-distinct
  (forall ρ; ρ check-idx:Int^many val:Int^many idx:Int^many xs:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { check-idx val idx xs count } { check-idx idx prim = [ count 1 prim + locals { newcount } { idx 1 prim + newcount xs loop-distinct } ] [ check-idx xs swap prim seq-int.at val prim = [ idx 1 prim + count xs loop-distinct ] [ check-idx 1 prim + val idx xs count loop-check-distinct ] if ] if };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } { i xs prim seq-int.len prim = [ j ys prim seq-int.len prim = [ result ] [ j ys swap prim seq-int.at locals { yv } { result yv prim seq-int.push locals { newres } { newres j 1 prim + xs ys loop-merge } } ] if ] [ j ys prim seq-int.len prim = [ i xs swap prim seq-int.at locals { xv } { result xv prim seq-int.push locals { newres } { newres i 1 prim + xs ys loop-merge } } ] [ i xs swap prim seq-int.at j ys swap prim seq-int.at prim <= [ i xs swap prim seq-int.at locals { xv } { result xv prim seq-int.push locals { newres } { newres i 1 prim + xs ys loop-merge } } ] [ j ys swap prim seq-int.at locals { yv } { result yv prim seq-int.push locals { newres } { newres j 1 prim + xs ys loop-merge } } ] if ] if ] if };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n loop-digits ] if };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } { n 0 prim <= [ result ] [ result n 10 prim mod prim seq-int.push n 10 prim div loop-digits ] if };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many cand:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result cand n } { cand n prim > [ result ] [ cand 2 result cand n check-prime ] if };

: check-prime
  (forall ρ; ρ div:Int^many cand:Int^many result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { div cand result n } { div div prim * cand prim > [ cand result prim seq-int.push locals { newres } { cand 1 prim + newres n loop-primes } ] [ cand div prim mod 0 prim = [ cand 1 prim + result n loop-primes ] [ div 1 prim + cand result n check-prime ] if ] if };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 xs k loop-create-hist };

: loop-create-hist
  (forall ρ; ρ result:Seq Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result count xs k } { count k prim = [ 0 xs result loop-count-values ] [ result 0 prim seq-int.push count 1 prim + xs k loop-create-hist ] if };

: loop-count-values
  (forall ρ; ρ idx:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { idx xs result } { idx xs prim seq-int.len prim = [ result ] [ idx xs swap prim seq-int.at locals { elem } { elem idx prim = [ result elem prim seq-int.at 1 prim + elem prim seq-int.set ] [ result ] if idx 1 prim + xs result loop-count-values ] if };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 1 loop-sort };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { xs idx } { idx xs prim seq-int.len prim >= [ xs ] [ idx xs swap prim seq-int.at locals { curr } { idx 1 prim - 0 prim >= [ idx 1 prim - xs swap prim seq-int.at curr prim > [ curr idx 1 prim - xs swap prim seq-int.at xs idx prim seq-int.set xs idx 1 prim - prim seq-int.set locals { newxs } { newxs idx 1 prim - loop-sort } ] [ idx 1 prim + xs loop-sort ] if ] [ idx 1 prim + xs loop-sort ] if } ] if };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole loop-orders };

: loop-orders
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons idx items qtys whole } { idx qtys prim seq-int.len prim = [ stock alloc reasons ] [ idx items swap prim seq-int.at idx qtys swap prim seq-int.at idx whole swap prim seq-int.at stock alloc reasons idx items qtys whole loop-do-alloc ] if };

: loop-do-alloc
  (forall ρ; ρ item:Int^many qty:Int^many wholefl:Bool^many stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { item qty wholefl stock alloc reasons idx items qtys whole } { item stock swap prim seq-int.at locals { avail } { avail qty prim <= [ qty alloc prim seq-int.push 0 reasons prim seq-int.push stock item qty prim - prim seq-int.set idx 1 prim + items qtys whole loop-orders ] [ avail 0 prim = [ 0 alloc prim seq-int.push 2 reasons prim seq-int.push idx 1 prim + items qtys whole loop-orders ] [ wholefl [ 0 alloc prim seq-int.push 3 reasons prim seq-int.push idx 1 prim + items qtys whole loop-orders ] [ avail alloc prim seq-int.push 1 reasons prim seq-int.push stock item 0 prim seq-int.set idx 1 prim + items qtys whole loop-orders ] if ] if ] if } };
```

