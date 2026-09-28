### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ xs:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs acc i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at acc prim +
      xs swap
      i 1 prim +
      sum-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 0 xs sum-loop
  };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ xs:Seq Int^many max-val:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs max-val i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max-val prim <
      [
        xs i prim seq-int.at
        xs
        i 1 prim +
        max-loop
      ]
      [
        max-val
        xs
        i 1 prim +
        max-loop
      ]
      if
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 0 xs max-loop
  };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many cnt:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k cnt i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        cnt 1 prim +
      ]
      [
        cnt
      ]
      if
      xs k swap
      i 1 prim +
      count-loop
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      xs result
      i 1 prim -
      reverse-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result sum i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      result swap prim seq-int.push
      xs result sum
      i 1 prim +
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-loop
  };
```

### task: keep-positive
```firth
: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        result
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
      ]
      if
      xs swap
      i 1 prim +
      filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs filter-loop
  };
```

### task: is-sorted
```firth
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        false
      ]
      [
        xs
        i 1 prim +
        check-sorted
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs 0 check-sorted
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs ys sum i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      xs ys swap
      i 1 prim +
      dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };
```

### task: longest-run
```firth
: count-run
  (forall ρ; ρ xs:Seq Int^many prev:Int^many current-len:Int^many max-len:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs prev current-len max-len i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at prev prim =
      [
        current-len 1 prim +
        xs
        xs i prim seq-int.at
        current-len 1 prim + max-len prim <
        [
          max-len
        ]
        [
          current-len 1 prim +
        ]
        if
        i 1 prim +
        count-run
      ]
      [
        1
        xs
        xs i prim seq-int.at
        current-len max-len prim <
        [
          max-len
        ]
        [
          current-len
        ]
        if
        i 1 prim +
        count-run
      ]
      if
    ]
    [
      current-len max-len prim <
      [
        max-len
      ]
      [
        current-len
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      xs 0 prim seq-int.at 1 0 1 xs count-run
    ]
    if
  };
```

### task: count-distinct
```firth
: is-duplicate
  (forall ρ; ρ xs:Seq Int^many val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs val i } {
    i 0 prim <
    [
      xs i prim seq-int.at val prim =
      [
        true
      ]
      [
        xs val
        i 1 prim -
        is-duplicate
      ]
      if
    ]
    [ false ]
    if
  };

: count-dist-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs xs i prim seq-int.at
      i 1 prim -
      is-duplicate
      [
        result
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
      ]
      if
      xs swap
      i 1 prim +
      count-dist-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs count-dist-loop prim seq-int.len
  };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ result-final:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        xs ys swap
        i 1 prim +
        j
        merge-loop
      ]
      [
        result ys j prim seq-int.at prim seq-int.push
        xs ys swap
        i
        j 1 prim +
        merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        xs ys swap
        i 1 prim +
        j
        merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          result ys j prim seq-int.at prim seq-int.push
          xs ys swap
          i
          j 1 prim +
          merge-loop
        ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-loop
  };
```

### task: digits
```firth
: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result-final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [
      result
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      extract-digits
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ]
    [
      prim seq-int.empty n extract-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        n
        d 1 prim +
        is-prime-check
      ]
      if
    ]
    [ true ]
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
      n
      2
      is-prime-check
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ result:Seq Int^many limit:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { result limit i } {
    i limit prim < prim not prim not
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      limit
      i 1 prim +
      sieve-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-int.empty n 2 sieve-loop
  };
```

### task: histogram
```firth
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many k:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at result xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      xs swap
      i 1 prim +
      k
      histogram-loop
    ]
    [ result ]
    if
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { result k i } {
    i k prim <
    [
      result 0 prim seq-int.push
      k
      i 1 prim +
      init-histogram
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k 0 init-histogram xs 0 k histogram-loop
  };
```

### task: sort
```firth
: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { result val i } {
    i result prim seq-int.len prim <
    [
      result i prim seq-int.at val prim <
      [
        result i val prim seq-int.set
      ]
      [
        result
        val
        i 1 prim +
        insert-sorted
      ]
      if
    ]
    [
      result val prim seq-int.push
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at 0 insert-sorted
      xs swap
      i 1 prim +
      sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs sort-loop
  };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ result-balance:Int^many result-rejected:Int^many)
  locals { start txs balance rejected i } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [
        balance
        rejected 1 prim +
        txs
        i 1 prim +
        ledger-loop
      ]
      [
        balance txs i prim seq-int.at prim +
        rejected
        txs
        i 1 prim +
        ledger-loop
      ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ result-balance:Int^many result-rejected:Int^many)
  locals { start txs } {
    start txs 0 0 txs ledger-loop
  };
```

### task: allocate-batch
```firth
: process-order
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    j allocated prim seq-int.len prim =
    [
      stock allocated reasons
    ]
    [
      items j prim seq-int.at stock qtys j prim seq-int.at stock items j prim seq-int.at prim seq-int.at prim <
      [
        stock items j prim seq-int.at qtys j prim seq-int.at prim seq-int.set
        allocated qtys j prim seq-int.at prim seq-int.push
        reasons 0 prim seq-int.push
        stock allocated reasons items qtys whole j 1 prim + process-order
      ]
      [
        stock items j prim seq-int.at prim seq-int.at 0 prim =
        [
          stock
          allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          items qtys whole
          j 1 prim +
          process-order
        ]
        [
          whole j prim seq-bool.at
          [
            stock
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            items qtys whole
            j 1 prim +
            process-order
          ]
          [
            stock items j prim seq-int.at stock items j prim seq-int.at prim seq-int.at prim seq-int.set
            allocated stock items j prim seq-int.at prim seq-int.at prim seq-int.push
            reasons 1 prim seq-int.push
            stock allocated reasons items qtys whole j 1 prim + process-order
          ]
          if
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty prim seq-int.empty stock items qtys whole 0 process-order
  };
```
