### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 0 xs loop-sum };

: loop-sum
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum idx xs } { idx xs prim seq-int.len prim = [ sum ] [ idx xs swap prim seq-int.at sum prim + idx 1 prim + xs loop-sum ] if };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs loop-max };

: loop-max
  (forall ρ; ρ max:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max idx xs } { idx xs prim seq-int.len prim = [ max ] [ idx xs swap prim seq-int.at locals { elem } { elem max prim > [ elem idx 1 prim + xs loop-max ] [ max idx 1 prim + xs loop-max ] if } ] if };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { 0 0 xs k loop-count };

: loop-count
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx xs k } { idx xs prim seq-int.len prim = [ count ] [ idx xs swap prim seq-int.at k prim < [ count 1 prim + ] [ count ] if idx 1 prim + xs k loop-count ] if };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { 0 xs x loop-index };

: loop-index
  (forall ρ; ρ idx:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx xs x } { idx xs prim seq-int.len prim = [ -1 ] [ idx xs swap prim seq-int.at x prim = [ idx ] [ idx 1 prim + xs x loop-index ] if ] if };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - xs loop-reverse };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx xs } { idx 0 prim < [ result ] [ idx xs swap prim seq-int.at locals { elem } { result elem prim seq-int.push idx 1 prim - xs loop-reverse } ] if };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs loop-prefix };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum idx xs } { idx xs prim seq-int.len prim = [ result ] [ idx xs swap prim seq-int.at locals { elem } { sum elem prim + locals { newsum } { result newsum prim seq-int.push newsum idx 1 prim + xs loop-prefix } } ] if };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs loop-keep };

: loop-keep
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx xs } { idx xs prim seq-int.len prim = [ result ] [ idx xs swap prim seq-int.at locals { elem } { elem 0 prim > [ result elem prim seq-int.push idx 1 prim + xs loop-keep ] [ result idx 1 prim + xs loop-keep ] if } ] if };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs prim seq-int.len 1 prim <= [ true ] [ 0 xs loop-check-sorted ] if };

: loop-check-sorted
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { idx xs } { idx xs prim seq-int.len 1 prim - prim = [ true ] [ idx xs swap prim seq-int.at idx 1 prim + xs swap prim seq-int.at prim <= [ idx 1 prim + xs loop-check-sorted ] [ false ] if ] if };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { 0 0 xs ys loop-dot };

: loop-dot
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx xs ys } { idx xs prim seq-int.len prim = [ sum ] [ idx xs swap prim seq-int.at idx ys swap prim seq-int.at prim * sum prim + idx 1 prim + xs ys loop-dot ] if };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { true 0 flags loop-all };

: loop-all
  (forall ρ; ρ all:Bool^many idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { all idx flags } { idx flags prim seq-bool.len prim = [ all ] [ idx flags swap prim seq-bool.at locals { flag } { flag all prim and idx 1 prim + flags loop-all } ] if };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 0 prim seq-int.at 1 1 1 xs loop-run ] if };

: loop-run
  (forall ρ; ρ max:Int^many curr:Int^many prev:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max curr prev idx xs } { idx xs prim seq-int.len prim = [ max ] [ idx xs swap prim seq-int.at dup prev prim = [ curr 1 prim + dup max prim > [ swap drop ] [ ] if idx 1 prim + xs loop-run ] [ drop 1 idx 1 prim + xs loop-run ] if ] if };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { 0 xs target loop-pair };

: loop-pair
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } { i xs prim seq-int.len prim = [ false ] [ i 1 prim + i xs target loop-pair-inner ] if };

: loop-pair-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } { j xs prim seq-int.len prim = [ i xs target loop-pair ] [ i xs swap prim seq-int.at j xs swap prim seq-int.at prim + target prim = [ true ] [ j 1 prim + i xs target loop-pair-inner ] if ] if };
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
  locals { check-idx val idx xs count } { check-idx idx prim = [ count 1 prim + idx 1 prim + xs loop-distinct ] [ check-idx xs swap prim seq-int.at val prim = [ idx 1 prim + xs loop-distinct ] [ check-idx 1 prim + val idx xs count loop-check-distinct ] if ] if };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } { i xs prim seq-int.len prim = [ j ys prim seq-int.len prim = [ result ] [ j ys swap prim seq-int.at result prim seq-int.push j 1 prim + result xs ys loop-merge ] if ] [ j ys prim seq-int.len prim = [ i xs swap prim seq-int.at result prim seq-int.push i 1 prim + result xs ys loop-merge ] [ i xs swap prim seq-int.at j ys swap prim seq-int.at prim <= [ i xs swap prim seq-int.at result prim seq-int.push i 1 prim + result xs ys loop-merge ] [ j ys swap prim seq-int.at result prim seq-int.push j 1 prim + result xs ys loop-merge ] if ] if ] if };
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
  locals { div cand result n } { div div prim * cand prim > [ cand result prim seq-int.push cand 1 prim + n loop-primes ] [ cand div prim mod 0 prim = [ cand 1 prim + n loop-primes ] [ div 1 prim + cand result n check-prime ] if ] if };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty k 0 xs loop-fill-hist };

: loop-fill-hist
  (forall ρ; ρ result:Seq Int^many remaining:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result remaining idx xs } { remaining 0 prim = [ idx 0 xs loop-count-values ] [ 0 result prim seq-int.push remaining 1 prim - idx 1 prim + xs loop-fill-hist ] if };

: loop-count-values
  (forall ρ; ρ idx:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { idx xs result } { idx xs prim seq-int.len prim = [ result ] [ idx xs swap prim seq-int.at idx prim = [ idx result swap prim seq-int.at 1 prim + result swap prim seq-int.set ] [ ] if idx 1 prim + xs result loop-count-values ] if };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 1 loop-sort };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { xs idx } { idx xs prim seq-int.len prim >= [ xs ] [ idx xs swap prim seq-int.at idx 1 prim - xs swap prim seq-int.at prim > [ idx xs swap prim seq-int.at idx 1 prim - xs swap prim seq-int.at xs idx prim seq-int.set xs idx 1 prim - prim seq-int.set idx 1 prim - xs loop-sort ] [ idx 1 prim + xs loop-sort ] if ] if };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs loop-ledger };

: loop-ledger
  (forall ρ; ρ bal:Int^many rej:Int^many idx:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { bal rej idx txs } { idx txs prim seq-int.len prim = [ bal rej ] [ idx txs swap prim seq-int.at locals { tx } { tx bal prim + 0 prim >= [ tx bal prim + rej idx 1 prim + txs loop-ledger ] [ bal rej 1 prim + idx 1 prim + txs loop-ledger ] if } ] if };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole stock loop-orders };

: loop-orders
  (forall ρ; ρ alloc:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock:Seq Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { alloc reasons idx items qtys whole stock } { idx qtys prim seq-int.len prim = [ stock alloc reasons ] [ idx items swap prim seq-int.at idx qtys swap prim seq-int.at idx whole swap prim seq-int.at stock alloc reasons idx items qtys whole stock loop-do-alloc ] if };

: loop-do-alloc
  (forall ρ; ρ item:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole2:Seq Bool^many stock2:Seq Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { item qty whole stock alloc reasons idx items qtys whole2 stock2 } { item stock swap prim seq-int.at dup qty prim <= [ qty alloc prim seq-int.push 0 reasons prim seq-int.push stock item qty prim - prim seq-int.set idx 1 prim + items qtys whole2 stock loop-orders ] [ dup 0 prim = [ 0 alloc prim seq-int.push 2 reasons prim seq-int.push idx 1 prim + items qtys whole2 stock loop-orders ] [ whole [ 0 alloc prim seq-int.push 3 reasons prim seq-int.push idx 1 prim + items qtys whole2 stock loop-orders ] [ dup alloc prim seq-int.push 1 reasons prim seq-int.push stock item 0 prim seq-int.set idx 1 prim + items qtys whole2 stock loop-orders ] if ] if ] if };
```

