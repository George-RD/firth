### task: seq-sum
```firth
: loop-sum
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + xs i 1 prim + loop-sum ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    0 xs 0 loop-sum
  };
```

### task: seq-max
```firth
: loop-max
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup max prim <
      [ ]
      [ drop max ]
      if
      xs i 1 prim + loop-max
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at xs 1 loop-max
  };
```

### task: count-below
```firth
: loop-count-below
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ result:Int^many)
  locals { count xs i k } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at k prim <
      [ count 1 prim + xs i 1 prim + k loop-count-below ]
      [ count xs i 1 prim + k loop-count-below ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 xs 0 k loop-count-below
  };
```

### task: index-of
```firth
: loop-index
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs x loop-index ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0 xs x loop-index
  };
```

### task: reverse
```firth
: loop-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim <
    [ result xs i prim seq-int.at prim seq-int.push xs i 1 prim - loop-reverse ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - loop-reverse
  };
```

### task: prefix-sums
```firth
: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sum prim + dup result swap prim seq-int.push swap xs i 1 prim + loop-prefix ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs 0 loop-prefix
  };
```

### task: keep-positive
```firth
: loop-keep
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup 0 prim <
      [ drop result xs i 1 prim + loop-keep ]
      [ result swap prim seq-int.push xs i 1 prim + loop-keep ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 loop-keep
  };
```

### task: is-sorted
```firth
: loop-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + loop-sorted ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 loop-sorted
  };
```

### task: dot
```firth
: loop-dot
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ product:Int^many)
  locals { sum xs ys i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + xs ys i 1 prim + loop-dot ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 xs ys 0 loop-dot
  };
```

### task: all-true
```firth
: loop-all-true
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at
      [ flags i 1 prim + loop-all-true ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags 0 loop-all-true
  };
```

### task: longest-run
```firth
: loop-run
  (forall ρ; ρ max:Int^many current:Int^many xs:Seq Int^many i:Int^many last:Int^many -- ρ length:Int^many)
  locals { max current xs i last } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup last prim =
      [ drop current 1 prim + dup max prim <
        [ drop max ]
        [ ]
        if
        current 1 prim + xs i 1 prim + last loop-run
      ]
      [ drop max 1 xs i 1 prim + dup xs swap prim seq-int.at loop-run ]
      if
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 1 xs 1 xs 0 prim seq-int.at loop-run ]
    if
  };
```

### task: has-pair-sum
```firth
: loop-inner
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many j:Int^many -- ρ found:Bool^many)
  locals { i xs target j } {
    j xs prim seq-int.len prim <
    [ i j prim =
      [ i xs target j 1 prim + loop-inner ]
      [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ i xs target j 1 prim + loop-inner ]
        if
      ]
      if
    ]
    [ false ]
    if
  };

: loop-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [ i xs target 0 loop-inner
      [ true ]
      [ xs target i 1 prim + loop-outer ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 loop-outer
  };
```

### task: count-distinct
```firth
: contains
  (forall ρ; ρ x:Int^many seq:Seq Int^many i:Int^many -- ρ found:Bool^many)
  locals { x seq i } {
    i seq prim seq-int.len prim <
    [ seq i prim seq-int.at x prim =
      [ true ]
      [ x seq i 1 prim + contains ]
      if
    ]
    [ false ]
    if
  };

: loop-count-distinct
  (forall ρ; ρ count:Int^many seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count seen xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup seen 0 contains
      [ drop count seen xs i 1 prim + loop-count-distinct ]
      [ seen swap prim seq-int.push count 1 prim + swap xs i 1 prim + loop-count-distinct ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 prim seq-int.empty xs 0 loop-count-distinct
  };
```

### task: merge-sorted
```firth
: loop-merge
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim <
      [ result xs i prim seq-int.at prim seq-int.push locals { result } { result xs ys i 1 prim + j loop-merge } ]
      [ result ys j prim seq-int.at prim seq-int.push locals { result } { result xs ys i j 1 prim + loop-merge } ]
      if
    ]
    [ i xs prim seq-int.len prim <
      [ result xs i prim seq-int.at prim seq-int.push locals { result } { result xs ys i 1 prim + j loop-merge } ]
      [ j ys prim seq-int.len prim <
        [ result ys j prim seq-int.at prim seq-int.push locals { result } { result xs ys i j 1 prim + loop-merge } ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty xs ys 0 0 loop-merge
  };
```

### task: digits
```firth
: collect-digits-rev
  (forall ρ; ρ seq:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { seq n } {
    n 0 prim =
    [ seq ]
    [ seq n 10 prim mod prim seq-int.push n 10 prim div collect-digits-rev ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result seq i } {
    i 0 prim <
    [ result seq i prim seq-int.at prim seq-int.push seq i 1 prim - reverse-digits ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n collect-digits-rev dup prim seq-int.len 1 prim - prim seq-int.empty swap reverse-digits ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [ n d prim mod 0 prim =
      [ false ]
      [ n d 1 prim + is-prime-loop ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 is-prime-loop ]
    if
  };

: loop-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { result i limit } {
    i limit prim <
    [ i is-prime
      [ result i prim seq-int.push locals { result } { result i 1 prim + limit loop-primes } ]
      [ result i 1 prim + limit loop-primes ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n loop-primes
  };
```

### task: histogram
```firth
: make-zero-seq
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ zeros:Seq Int^many)
  locals { result k } {
    k 0 prim =
    [ result ]
    [ result 0 prim seq-int.push k 1 prim - make-zero-seq ]
    if
  };

: loop-histogram
  (forall ρ; ρ hist:Seq Int^many xs:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { hist xs i } {
    i xs prim seq-int.len prim <
    [ hist xs i prim seq-int.at dup hist swap prim seq-int.at 1 prim + prim seq-int.set xs i 1 prim + loop-histogram ]
    [ hist ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k make-zero-seq xs 0 loop-histogram
  };
```

### task: sort
```firth
: insert-step
  (forall ρ; ρ sorted:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted xs i } {
    i xs prim seq-int.len prim <
    [ sorted xs i prim seq-int.at prim seq-int.push locals { sorted } { sorted xs i 1 prim + insert-step } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ prim seq-int.empty ]
    [ prim seq-int.empty xs 0 insert-step ]
    if
  };
```

### task: ledger
```firth
: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ balance-out:Int^many rejected-out:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at dup balance prim + 0 prim <
      [ drop balance rejected 1 prim + txs i 1 prim + loop-ledger ]
      [ balance prim + rejected txs i 1 prim + loop-ledger ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 txs 0 loop-ledger
  };
```

### task: allocate-batch
```firth
: process-order
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock allocated reasons item qty whole } {
    stock item prim seq-int.at dup qty prim <
    [ drop allocated qty prim seq-int.push reasons 0 prim seq-int.push stock ]
    [ dup 0 prim =
      [ drop allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock ]
      [ whole
        [ drop allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock ]
        [ drop allocated stock item prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set ]
        if
      ]
      if
    ]
    if
  };

: loop-allocate
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock items qtys whole allocated reasons idx } {
    idx qtys prim seq-int.len prim <
    [ stock allocated reasons items idx prim seq-int.at qtys idx prim seq-int.at whole idx prim seq-bool.at process-order locals { stock-out allocated-out reasons-out } { stock-out items qtys whole allocated-out reasons-out idx 1 prim + loop-allocate } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole prim seq-int.empty prim seq-int.empty 0 loop-allocate
  };
```
