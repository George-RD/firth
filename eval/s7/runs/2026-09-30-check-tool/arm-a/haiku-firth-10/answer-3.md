### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1
    xs
    max-helper
  };

: max-helper
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ max prim < ]
      call
      [
        xs i prim seq-int.at
      ]
      [
        max
      ]
      if
      i 1 prim +
      xs
      max-helper
    ]
    [ max ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0
    0
    xs
    k
    count-loop
  };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i xs k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim +
      xs
      k
      count-loop
    ]
    [ count ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    0
    xs
    prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ prefix-sums:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        result new-sum prim seq-int.push
        new-sum
        i 1 prim +
        xs
        prefix-loop
      }
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    filter-loop
  };

: filter-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ 0 prim < ]
      call
      [
        xs i prim seq-int.at result prim seq-int.push
      ]
      [
        result
      ]
      if
      i 1 prim +
      xs
      filter-loop
    ]
    [ result ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    0 prim < prim not
    [ 1 ]
    [
      1
      xs
      0
      is-sorted-loop
    ]
    if
  };

: is-sorted-loop
  (forall ρ; ρ result:Bool^many xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { result xs i } {
    result prim not
    [ 0 ]
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        xs i prim seq-int.at
        xs i 1 prim + prim seq-int.at
        prim <
        [ 0 ]
        [
          1
          xs
          i 1 prim +
          is-sorted-loop
        ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    1
    flags
    0
    all-true-loop
  };

: all-true-loop
  (forall ρ; ρ result:Bool^many flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { result flags i } {
    result prim not
    [ 0 ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
        [ 1 flags i 1 prim + all-true-loop ]
        [ 0 ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len
    [
      0
    ]
    [
      0
      1
      0
      xs
      longest-run-loop
    ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim =
      [
        current-run 1 prim +
        max-run
        i 1 prim +
        xs
        longest-run-loop
      ]
      [
        max-run current-run prim < [ current-run ] [ max-run ] if
        1
        i 1 prim +
        xs
        longest-run-loop
      ]
      if
    ]
    [
      max-run current-run prim < [ current-run ] [ max-run ] if
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0
    xs
    target
    pair-sum-outer
  };

: pair-sum-outer
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      i
      xs
      target
      pair-sum-inner
    ]
    [ 0 ]
    if
  };

: pair-sum-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs j prim seq-int.at
      prim +
      target prim =
      [ 1 ]
      [
        j 1 prim +
        i
        xs
        target
        pair-sum-inner
      ]
      if
    ]
    [
      i 1 prim +
      xs
      target
      pair-sum-outer
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0
    0
    xs
    count-distinct-main
  };

: count-distinct-main
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0
      xs
      i
      check-if-new
      [
        count 1 prim +
        i 1 prim +
        xs
        count-distinct-main
      ]
      [
        i 1 prim +
        xs
        count-distinct-main
      ]
      if
    ]
    [ count ]
    if
  };

: check-if-new
  (forall ρ; ρ elem:Int^many j:Int^many xs:Seq Int^many i:Int^many -- ρ found:Bool^many)
  locals { elem j xs i } {
    j i prim <
    [
      xs j prim seq-int.at elem prim =
      [ 1 ]
      [
        j 1 prim +
        xs
        elem
        i
        check-if-new
      ]
      if
    ]
    [ 0 ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    2
    n
    find-primes-loop
  };

: find-primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <
    [
      i
      is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      i 1 prim +
      n
      find-primes-loop
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim <
    [ 0 ]
    [
      num 2 prim =
      [ 1 ]
      [
        num 2 prim mod 0 prim =
        [ 0 ]
        [ 2 num check-divisors ]
        if
      ]
      if
    ]
    if
  };

: check-divisors
  (forall ρ; ρ i:Int^many num:Int^many -- ρ prime:Bool^many)
  locals { i num } {
    i i prim * num prim <
    [
      num i prim mod 0 prim =
      [ 0 ]
      [
        i 2 prim +
        num
        check-divisors
      ]
      if
    ]
    [ 1 ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    k
    0
    xs
    init-and-fill
  };

: init-and-fill
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many j:Int^many xs:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { result i k j xs } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      j
      xs
      init-and-fill
    ]
    [
      j xs prim seq-int.len prim <
      [
        xs j prim seq-int.at
        [ result prim seq-int.at 1 prim + ]
        dip
        [ result prim seq-int.set ]
        dip
        j 1 prim +
        xs
        result
        k
        update-histogram
      ]
      [
        result
      ]
      if
    ]
    if
  };

: update-histogram
  (forall ρ; ρ j:Int^many xs:Seq Int^many result:Seq Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { j xs result k } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      [ result prim seq-int.at 1 prim + ]
      dip
      [ result prim seq-int.set ]
      dip
      j 1 prim +
      xs
      result
      k
      update-histogram
    ]
    [
      result
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    insertion-sort-loop
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result
      0
      insert-into-sorted
      i 1 prim +
      xs
      insertion-sort-loop
    ]
    [ result ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ elem:Int^many result:Seq Int^many pos:Int^many -- ρ inserted:Seq Int^many)
  locals { elem result pos } {
    pos result prim seq-int.len prim <
    [
      result pos prim seq-int.at elem prim <
      [
        result pos elem prim seq-int.set
      ]
      [
        elem
        result
        pos 1 prim +
        insert-into-sorted
      ]
      if
    ]
    [
      result elem prim seq-int.push
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    0
    txs
    ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      balance prim + 0 prim <
      [
        balance
        rejected 1 prim +
      ]
      [
        balance txs i prim seq-int.at prim +
        rejected
      ]
      if
      i 1 prim +
      txs
      ledger-loop
    ]
    [ balance rejected ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    items
    qtys
    whole
    allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-list:Seq Int^many reason-list:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      stock
      [ prim seq-int.at ]
      call
      locals { available } {
        qtys j prim seq-int.at available prim <
        [
          available 0 prim =
          [
            0
            2
          ]
          [
            whole j prim seq-bool.at
            [
              0
              3
            ]
            [
              available
              1
            ]
            if
          ]
          if
        ]
        [
          qtys j prim seq-int.at
          0
        ]
        if
        locals { alloc reason } {
          allocated alloc prim seq-int.push
          reasons reason prim seq-int.push
          stock items j prim seq-int.at available alloc prim - prim seq-int.set
          j 1 prim +
          items
          qtys
          whole
          allocate-loop
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };
```
