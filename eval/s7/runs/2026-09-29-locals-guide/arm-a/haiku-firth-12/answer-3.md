### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs xs 0 prim seq-int.at 0 max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i 1 prim + xs prim seq-int.len prim <
    [
      xs i 1 prim + prim seq-int.at max prim <
      [
        xs i 1 prim + prim seq-int.at locals { new-max } { xs i 1 prim + new-max max-loop }
      ]
      [
        xs i 1 prim + max max-loop
      ]
      if
    ]
    [
      max
    ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty locals { xs rev } { xs rev xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many rev:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs rev i } {
    0 i prim <
    [
      rev xs i prim seq-int.at prim seq-int.push locals { new-rev } { xs new-rev i 1 prim - reverse-loop }
    ]
    [
      rev
    ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 locals { xs result sum } { xs result sum 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs result sum i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim + locals { new-sum } { result new-sum prim seq-int.push locals { new-result } { xs new-result new-sum i 1 prim + prefix-loop } }
    ]
    [
      result
    ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty locals { xs result } { xs result 0 filter-loop };

: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        result xs i prim seq-int.at prim seq-int.push locals { new-result } { xs new-result i 1 prim + filter-loop }
      ]
      [
        xs result i 1 prim + filter-loop
      ]
      if
    ]
    [
      result
    ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  true locals { xs sorted } { xs sorted 0 check-sorted };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many sorted:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { xs sorted i } {
    sorted
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
        [
          xs sorted i 1 prim + check-sorted
        ]
        [
          false
        ]
        if
      ]
      [
        true
      ]
      if
    ]
    [
      false
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 locals { xs maxlen } { xs maxlen 0 1 run-loop };

: run-loop
  (forall ρ; ρ xs:Seq Int^many maxlen:Int^many i:Int^many runlen:Int^many -- ρ result:Int^many)
  locals { xs maxlen i runlen } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        1
      ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          runlen 1 prim +
        ]
        [
          1
        ]
        if
      ]
      if locals { cur-len } { cur-len maxlen prim < [ cur-len ] [ maxlen ] if locals { new-max } { xs new-max i 1 prim + cur-len run-loop } }
    ]
    [
      maxlen
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false locals { xs target found } { xs target found 0 pair-search };

: pair-search
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { xs target found i } {
    found
    [
      true
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs target false i i 1 prim + pair-inner
      ]
      [
        false
      ]
      if
    ]
    if
  };

: pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target found i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true
      ]
      [
        xs target found i j 1 prim + pair-inner
      ]
      if
    ]
    [
      xs target found i 1 prim + pair-search
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 locals { xs count } { xs count 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs count i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 0 is-new-value
      [
        count 1 prim + locals { new-count } { xs new-count i 1 prim + distinct-loop }
      ]
      [
        xs count i 1 prim + distinct-loop
      ]
      if
    ]
    [
      count
    ]
    if
  };

: is-new-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many start:Int^many -- ρ result:Bool^many)
  locals { xs val start } { xs val start start check-new };

: check-new
  (forall ρ; ρ xs:Seq Int^many val:Int^many start:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs val start i } {
    i start prim <
    [
      xs i prim seq-int.at val prim =
      [
        false
      ]
      [
        xs val start i 1 prim + check-new
      ]
      if
    ]
    [
      true
    ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ res:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push locals { new-result } { xs ys new-result i 1 prim + j merge-loop }
        ]
        [
          result ys j prim seq-int.at prim seq-int.push locals { new-result } { xs ys new-result i j 1 prim + merge-loop }
        ]
        if
      ]
      [
        result xs i prim seq-int.at prim seq-int.push locals { new-result } { xs ys new-result i 1 prim + j merge-loop }
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push locals { new-result } { xs ys new-result i j 1 prim + merge-loop }
      ]
      [
        result
      ]
      if
    ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      prim seq-int.empty n digits-loop
    ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [
      result
    ]
    [
      result n 10 prim mod prim seq-int.push locals { new-result } { new-result n 10 prim div digits-loop }
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty locals { n primes } { n primes 2 prime-loop };

: prime-loop
  (forall ρ; ρ n:Int^many primes:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { n primes i } {
    i n prim < prim not
    [
      n primes i prime-loop
    ]
    [
      i locals { check-i } { check-i 2 is-prime [ i primes prim seq-int.push locals { new-primes } { n new-primes i 1 prim + prime-loop } ] [ n primes i 1 prim + prime-loop ] if }
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [
      false
    ]
    [
      n 2 check-prime-divisor
    ]
    if
  };

: check-prime-divisor
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        n d 1 prim + check-prime-divisor
      ]
      if
    ]
    [
      true
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { xs k prim seq-int.empty 0 init-hist };

: init-hist
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs k counts i } {
    i k prim <
    [
      counts 0 prim seq-int.push locals { new-counts } { xs k new-counts i 1 prim + init-hist }
    ]
    [
      xs k counts 0 count-hist
    ]
    if
  };

: count-hist
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs k counts i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { val } { counts val prim seq-int.at 1 prim + counts val prim seq-int.set locals { new-counts } { xs k new-counts i 1 prim + count-hist } }
    ]
    [
      counts
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs sort-step };

: sort-step
  (forall ρ; ρ xs:Seq Int^many sorted:Seq Int^many -- ρ res:Seq Int^many)
  locals { xs sorted } {
    sorted prim seq-int.len 0 prim =
    [
      prim seq-int.empty
    ]
    [
      sorted 0 prim seq-int.at locals { min-val } { sorted 1 sorted prim seq-int.len min-val find-min-remove locals { new-sorted } { new-sorted min-val prim seq-int.push locals { added-sorted } { xs added-sorted sort-step } } }
    ]
    if
  };

: find-min-remove
  (forall ρ; ρ sorted:Seq Int^many i:Int^many min:Int^many -- ρ result:Int^many)
  locals { sorted i min } {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at min prim <
      [
        sorted i prim seq-int.at
      ]
      [
        min
      ]
      if locals { cur-min } { sorted i 1 prim + cur-min find-min-remove }
    ]
    [
      min
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs start 0 0 apply-tx };

: apply-tx
  (forall ρ; ρ start:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { start txs balance rejected i } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at balance prim + 0 prim < 
      [
        start txs balance rejected 1 prim + i 1 prim + apply-tx
      ]
      [
        txs i prim seq-int.at balance prim + locals { new-balance } { start txs new-balance rejected i 1 prim + apply-tx }
      ]
      if
    ]
    [
      balance rejected
    ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 
  locals { stock items qtys whole alloc reasons idx } 
  { stock items qtys whole alloc reasons idx process-order };

: process-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole alloc reasons idx } {
    idx qtys prim seq-int.len prim <
    [
      items idx prim seq-int.at locals { item-idx } { stock item-idx prim seq-int.at } locals { available } { stock items qtys whole alloc reasons available qtys idx prim seq-int.at whole idx prim seq-bool.at determine-allocation }
    ]
    [
      stock alloc reasons
    ]
    if
  };

: determine-allocation
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many available:Int^many qty:Int^many full:Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole alloc reasons available qty full } {
    qty available prim <
    [
      alloc qty prim seq-int.push locals { new-alloc } { reasons 0 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons 0 continue-process } }
    ]
    [
      available 0 prim =
      [
        alloc 0 prim seq-int.push locals { new-alloc } { reasons 2 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons 0 continue-process } }
      ]
      [
        full
        [
          alloc 0 prim seq-int.push locals { new-alloc } { reasons 3 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons 0 continue-process } }
        ]
        [
          alloc available prim seq-int.push locals { new-alloc } { reasons 1 prim seq-int.push locals { new-reasons } { stock new-alloc new-reasons available continue-process } }
        ]
        if
      ]
      if
    ]
    if
  };

: continue-process
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many deduct:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock alloc reasons deduct } { stock alloc reasons };
```
