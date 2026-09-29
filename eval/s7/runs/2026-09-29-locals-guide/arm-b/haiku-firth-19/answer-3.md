### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs helper-sum };

: helper-sum
  (forall ρ; ρ idx:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx acc xs } { xs prim seq-int.len idx prim = [ acc ] [ idx xs prim seq-int.at acc prim + idx 1 prim + xs helper-sum ] if };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs helper-max };

: helper-max
  (forall ρ; ρ idx:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx max xs } { xs prim seq-int.len idx prim = [ max ] [ idx xs prim seq-int.at max prim < [ idx xs prim seq-int.at ] [ max ] if idx 1 prim + xs helper-max ] if };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k helper-count };

: helper-count
  (forall ρ; ρ idx:Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { idx count xs k } { xs prim seq-int.len idx prim = [ count ] [ idx xs prim seq-int.at k prim < [ count 1 prim + ] [ count ] if idx 1 prim + xs k helper-count ] if };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x helper-find };

: helper-find
  (forall ρ; ρ idx:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx xs x } { xs prim seq-int.len idx prim = [ -1 ] [ idx xs prim seq-int.at x prim = [ idx ] [ idx 1 prim + xs x helper-find ] if ] if };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs helper-reverse };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx xs } { xs prim seq-int.len idx prim = [ result ] [ idx xs prim seq-int.at result prim seq-int.push idx 1 prim + xs helper-reverse ] if };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs helper-prefix };

: helper-prefix
  (forall ρ; ρ result:Seq Int^many idx:Int^many sum:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx sum xs } { xs prim seq-int.len idx prim = [ result ] [ idx xs prim seq-int.at sum prim + result prim seq-int.push idx 1 prim + xs helper-prefix ] if };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs helper-keep };

: helper-keep
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx xs } { xs prim seq-int.len idx prim = [ result ] [ idx xs prim seq-int.at dup 0 prim < [ result prim seq-int.push ] [ drop result ] if idx 1 prim + xs helper-keep ] if };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { true 0 xs helper-check };

: helper-check
  (forall ρ; ρ sorted:Bool^many idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { sorted idx xs } { xs prim seq-int.len 1 prim - idx prim = [ sorted ] [ idx xs prim seq-int.at idx 1 prim + xs prim seq-int.at prim < [ false ] [ true ] if sorted prim and idx 1 prim + xs helper-check ] if };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys helper-dot };

: helper-dot
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum idx xs ys } { xs prim seq-int.len idx prim = [ sum ] [ idx xs prim seq-int.at idx ys prim seq-int.at prim * sum prim + idx 1 prim + xs ys helper-dot ] if };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 flags helper-all };

: helper-all
  (forall ρ; ρ result:Bool^many idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { result idx flags } { flags prim seq-int.len idx prim = [ result ] [ idx flags prim seq-int.at result prim and idx 1 prim + flags helper-all ] if };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 1 0 xs helper-run };

: helper-run
  (forall ρ; ρ max-len:Int^many curr-len:Int^many prev-val:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-len curr-len prev-val xs } { xs prim seq-int.len prev-val prim = [ max-len curr-len prim < [ curr-len ] [ max-len ] if ] [ 0 xs prim seq-int.at prev-val prim = [ curr-len 1 prim + ] [ 1 ] if max-len prim < [ max-len 1 prim + curr-len 1 prim + xs ] [ max-len curr-len 1 prim + xs ] if helper-run ] if };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 xs target helper-pair };

: helper-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { found i xs target } { found [ false ] [ xs prim seq-int.len i prim = [ true ] [ true ] if ] if };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs helper-distinct };

: helper-distinct
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { count idx xs } { xs prim seq-int.len idx prim = [ count ] [ idx xs prim seq-int.at count 1 prim + idx 1 prim + xs helper-distinct ] if };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys helper-merge };

: helper-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } { xs prim seq-int.len i prim = [ result j ys prim seq-int.at prim seq-int.push j 1 prim + xs ys helper-merge ] [ result ] if };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n helper-digits ] if };

: helper-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } { n 0 prim = [ result ] [ result n 10 prim mod prim seq-int.push n 10 prim div helper-digits ] if };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n helper-primes };

: helper-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result candidate n } { candidate n prim < [ result candidate prim seq-int.push candidate 1 prim + n helper-primes ] [ result ] if };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 xs k helper-hist };

: helper-hist
  (forall ρ; ρ counts:Seq Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { counts idx xs k } { k idx prim = [ counts ] [ counts 0 prim seq-int.push idx 1 prim + xs k helper-hist ] if };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs helper-insertion-sort };

: helper-insertion-sort
  (forall ρ; ρ arr:Seq Int^many -- ρ sorted:Seq Int^many)
  arr;
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs helper-ledger };

: helper-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected idx txs } { txs prim seq-int.len idx prim = [ balance rejected ] [ idx txs prim seq-int.at balance prim + dup 0 prim < [ drop balance rejected 1 prim + ] [ rejected ] if idx 1 prim + txs helper-ledger ] if };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole helper-allocate };

: helper-allocate
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons idx items qtys whole } { items prim seq-int.len idx prim = [ stock allocated reasons ] [ stock allocated reasons idx 1 prim + items qtys whole helper-continue ] if };

: helper-continue
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  ;
```
