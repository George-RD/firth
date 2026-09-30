### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 max-loop };

: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim <
    [ max xs i prim seq-int.at prim <
      [ xs i prim seq-int.at ] [ max ] if
      xs i 1 prim + max-loop
    ]
    [ max ] if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { xs i } {
    i 0 prim <
    [ xs i prim seq-int.at [ xs i prim seq-int.at ] [ ] compose xs i 1 prim - reverse-loop ]
    [ prim seq-int.empty ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim <
    [ sum xs i prim seq-int.at prim + result swap prim seq-int.push sum xs i prim seq-int.at prim + xs i 1 prim + prefix-loop ]
    [ result ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 filter-loop };

: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ 0 xs i prim seq-int.at prim <
      [ result xs i prim seq-int.at prim seq-int.push xs i 1 prim + filter-loop ]
      [ result xs i 1 prim + filter-loop ]
      if
    ]
    [ result ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 xs check-sorted ]
    if
  };

: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + check-sorted ]
      if
    ]
    [ true ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 1 xs xs 0 prim seq-int.at 1 1 run-loop ]
    if
  };

: run-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many prev:Int^many current:Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs prev current i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at prev prim =
      [ max current prim < [ current ] [ max ] if xs xs i prim seq-int.at current 1 prim + i 1 prim + run-loop ]
      [ current max prim < [ max ] [ current ] if xs xs i prim seq-int.at 1 i 1 prim + run-loop ]
      if
    ]
    [ max current prim < [ current ] [ max ] if ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false xs target 0 pair-loop };

: pair-loop
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { found xs target i } {
    found prim not i xs prim seq-int.len prim < prim and
    [ xs i prim seq-int.at xs xs prim seq-int.len 1 prim - inner-check
      [ true xs target i 1 prim + ] 
      [ false xs target i 1 prim + pair-loop ]
      if
    ]
    [ found ]
    if
  };

: inner-check
  (forall ρ; ρ xs:Seq Int^many target:Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target val j } {
    j 0 prim <
    [ xs j prim seq-int.at val prim + target prim =
      [ true ]
      [ xs target val j 1 prim - inner-check ]
      if
    ]
    [ false ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at 0 i is-new-value
      [ count 1 prim + xs i 1 prim + distinct-loop ]
      [ count xs i 1 prim + distinct-loop ]
      if
    ]
    [ count ] if
  };

: is-new-value
  (forall ρ; ρ val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { val j } {
    j 0 prim <
    [ j 1 prim - val is-new-value ]
    [ true ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ n digits-helper ]
    if
  };

: digits-helper
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim = prim not
    [ n 10 prim div digits-helper n 10 prim mod prim seq-int.push ]
    [ prim seq-int.empty ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [ candidate is-prime
      [ result candidate prim seq-int.push candidate 1 prim + n primes-loop ]
      [ result candidate 1 prim + n primes-loop ]
      if
    ]
    [ result ] if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many -- ρ result:Bool^many)
  locals { candidate } {
    candidate 2 prim <
    [ false ]
    [ candidate 2 prim =
      [ true ]
      [ candidate 2 check-prime ]
      if
    ] if
  };

: check-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [ candidate divisor prim mod 0 prim =
      [ false ]
      [ candidate divisor 1 prim + check-prime ]
      if
    ]
    [ true ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k build-counts xs 0 histogram-loop
  };

: build-counts
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + k build-counts ]
    [ counts ] if
  };

: histogram-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim <
    [ counts xs i prim seq-int.at xs i prim seq-int.at counts prim seq-int.at 1 prim + prim seq-int.set xs i 1 prim + histogram-loop ]
    [ counts ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 sort-loop };

: sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at result insert-in-sorted xs i 1 prim + sort-loop ]
    [ result ] if
  };

: insert-in-sorted
  (forall ρ; ρ val:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { val result } {
    result result prim seq-int.len 0 insert-pos
  };

: insert-pos
  (forall ρ; ρ result:Seq Int^many len:Int^many pos:Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result len pos val } {
    pos len prim <
    [ result pos prim seq-int.at val prim <
      [ result pos val prim seq-int.set ]
      [ pos 1 prim + result len insert-pos ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim <
    [ balance txs i prim seq-int.at prim + 0 prim <
      [ balance rejected 1 prim + txs i 1 prim + ledger-loop ]
      [ balance txs i prim seq-int.at prim + rejected txs i 1 prim + ledger-loop ]
      if
    ]
    [ balance rejected ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at stock swap prim seq-int.at qtys i prim seq-int.at prim < prim not
      [ allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push stock i qtys i prim seq-int.at prim - prim seq-int.set i 1 prim + allocate-loop ]
      [ stock items i prim seq-int.at prim seq-int.at 0 prim =
        [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock i 1 prim + allocate-loop ]
        [ whole i prim seq-bool.at
          [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock i 1 prim + allocate-loop ]
          [ allocated stock items i prim seq-int.at prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push stock items i prim seq-int.at prim seq-int.at 0 prim seq-int.set i 1 prim + allocate-loop ]
          if
        ]
        if
      ]
      if
    ]
    [ stock allocated reasons ] if
  };
```
