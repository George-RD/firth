### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 locals { xs sum } { xs sum 0 sum-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many sum:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs sum i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      xs sum i 1 prim + sum-loop
    ]
    [
      sum
    ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at locals { xs max } { xs max 1 max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs max i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max prim <
      [
        xs i prim seq-int.at
      ]
      [
        max
      ]
      if
      xs i 1 prim + max-loop
    ]
    [
      max
    ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 locals { xs k count } { xs k count 0 count-loop };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k count i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      xs k count i 1 prim + count-loop
    ]
    [
      count
    ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  -1 locals { xs x idx } { xs x idx 0 search-loop };

: search-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x idx i } {
    idx -1 prim =
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at x prim =
        [
          i
        ]
        [
          -1
        ]
        if
        xs x i 1 prim + search-loop
      ]
      [
        -1
      ]
      if
    ]
    [
      idx
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
      xs i prim seq-int.at rev prim seq-int.push
      xs rev i 1 prim - reverse-loop
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
      xs i prim seq-int.at sum prim +
      result swap prim seq-int.push
      xs result i 1 prim + prefix-loop
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
        xs i prim seq-int.at result prim seq-int.push
      ]
      [
        result
      ]
      if
      xs i 1 prim + filter-loop
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
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not
        [
          false
        ]
        [
          true
        ]
        if
        xs i 1 prim + check-sorted
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

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 locals { xs ys acc } { xs ys acc 0 dot-loop };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs ys acc i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      acc prim +
      xs ys acc i 1 prim + dot-loop
    ]
    [
      acc
    ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true locals { flags all } { flags all 0 check-all };

: check-all
  (forall ρ; ρ flags:Seq Bool^many all:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags all i } {
    all
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at prim not
        [
          false
        ]
        [
          true
        ]
        if
        flags i 1 prim + check-all
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
      if
      runlen prim swap maxlen prim <
      [
        runlen
      ]
      [
        maxlen
      ]
      if
      xs maxlen i 1 prim + run-loop
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
        i 1 prim + locals { j } { j i 1 prim + pair-inner }
      ]
      [
        false
      ]
      if
    ]
    if
  };

: pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true
      ]
      [
        xs target i j 1 prim + pair-inner
      ]
      if
    ]
    [
      xs target i 1 prim + pair-search
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
      xs i prim seq-int.at 0 i is-new-value
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      xs count i 1 prim + distinct-loop
    ]
    [
      count
    ]
    if
  };

: is-new-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many start:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs val start i } {
    i start prim <
    [
      xs i prim seq-int.at val prim =
      [
        false
      ]
      [
        xs val start i 1 prim + is-new-value
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
  prim seq-int.empty 0 0 locals { xs ys result } { xs ys result 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ res:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          xs i prim seq-int.at result prim seq-int.push
          xs ys result i 1 prim + j merge-loop
        ]
        [
          ys j prim seq-int.at result prim seq-int.push
          xs ys result i j 1 prim + merge-loop
        ]
        if
      ]
      [
        xs i prim seq-int.at result prim seq-int.push
        xs ys result i 1 prim + j merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at result prim seq-int.push
        xs ys result i j 1 prim + merge-loop
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
  n 0 prim =
  [
    prim seq-int.empty 0 prim seq-int.push
  ]
  [
    prim seq-int.empty 0 locals { n result } { n result digits-loop }
  ]
  if;

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ res:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      result digits-loop
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 locals { n primes } { n primes 2 prime-loop };

: prime-loop
  (forall ρ; ρ n:Int^many primes:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { n primes i } {
    i n prim < prim not
    [
      i n prim <
    ]
    [
      true
    ]
    if
    [
      n primes i prime-loop
    ]
    [
      i 2 is-prime
      [
        i primes prim seq-int.push
      ]
      [
        primes
      ]
      if
      n primes i 1 prim + prime-loop
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  n 2 prim <
  [
    false
  ]
  [
    n 2 check-prime-divisor
  ]
  if;

: check-prime-divisor
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
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
  if;
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty 0 locals { xs k counts } { xs k counts 0 init-hist };

: init-hist
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { xs k counts i } {
    i k prim <
    [
      counts 0 prim seq-int.push
      xs k counts i 1 prim + init-hist
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
      xs i prim seq-int.at
      counts swap prim seq-int.at 1 prim +
      counts swap prim seq-int.set
      xs k counts i 1 prim + count-hist
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
  xs locals { xs sorted } { xs sorted sort-step };

: sort-step
  (forall ρ; ρ xs:Seq Int^many sorted:Seq Int^many -- ρ res:Seq Int^many)
  locals { xs sorted } {
    sorted prim seq-int.len 0 prim =
    [
      prim seq-int.empty
    ]
    [
      sorted 0 prim seq-int.at
      sorted 1 sorted prim seq-int.len find-min-and-remove
      prim seq-int.push
      xs sorted sort-step
    ]
    if
  };

: find-min-and-remove
  (forall ρ; ρ sorted:Seq Int^many i:Int^many min:Int^many -- ρ result:Seq Int^many)
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
      if
      sorted i 1 prim + find-min-and-remove
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
  0 locals { start txs balance rejected } { start txs balance rejected 0 apply-tx };

: apply-tx
  (forall ρ; ρ start:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { start txs balance rejected i } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      balance prim + 0 prim <
      [
        rejected 1 prim +
      ]
      [
        balance prim +
      ]
      if
      start txs i 1 prim + apply-tx
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
      items idx prim seq-int.at
      stock swap prim seq-int.at
      qtys idx prim seq-int.at
      whole idx prim seq-bool.at
      determine-allocation
      stock items qtys whole alloc reasons idx 1 prim + process-order
    ]
    [
      stock alloc reasons
    ]
    if
  };

: determine-allocation
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reasons:Seq Int^many available:Int^many qty:Int^many full:Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  qty available prim <
  [
    available 0 prim =
    [
      alloc 0 prim seq-int.push reasons 2 prim seq-int.push
    ]
    [
      full
      [
        alloc 0 prim seq-int.push reasons 3 prim seq-int.push
      ]
      [
        alloc available prim seq-int.push reasons 1 prim seq-int.push
        stock swap available prim seq-int.set
      ]
      if
    ]
    if
  ]
  [
    alloc qty prim seq-int.push reasons 0 prim seq-int.push
    stock swap qty prim seq-int.set
  ]
  if;
```
