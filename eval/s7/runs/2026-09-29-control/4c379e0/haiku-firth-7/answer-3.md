### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      dup result prim seq-int.push
      swap
      xs
      i 1 prim +
      prefix-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    0
    prefix-loop
  };
```

### task: keep-positive
```firth
: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 prim <
      [
        drop
        result
      ]
      [
        result swap prim seq-int.push
      ]
      if
      xs
      i 1 prim +
      filter-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    0
    filter-loop
  };
```

### task: is-sorted
```firth
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i 1 prim + prim seq-int.at xs i prim seq-int.at prim <
      [
        false
      ]
      [
        xs
        i 1 prim +
        sorted-loop
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [
      xs
      0
      sorted-loop
    ]
    if
  };
```

### task: longest-run
```firth
: run-loop
  (forall ρ; ρ max:Int^many curr-len:Int^many xs:Seq Int^many i:Int^many -- ρ length:Int^many)
  locals { max curr-len xs i } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        xs
        1
        1
        i 1 prim +
        run-loop
      ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          curr-len 1 prim +
          dup max prim <
          [ drop max ]
          [ ]
          if
          xs
          swap
          i 1 prim +
          run-loop
        ]
        [
          curr-len max prim <
          [ max ]
          [ curr-len ]
          if
          xs
          i 1 prim +
          1
          run-loop
        ]
        if
      ]
      if
    ]
    [
      curr-len max prim <
      [ max ]
      [ curr-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [
      xs
      0
      0
      0
      run-loop
    ]
    if
  };
```

### task: count-distinct
```firth
: contains
  (forall ρ; ρ val:Int^many seen:Seq Int^many i:Int^many -- ρ is-present:Bool^many)
  locals { val seen i } {
    i seen prim seq-int.len prim <
    [
      seen i prim seq-int.at val prim =
      [ true ]
      [
        val
        seen
        i 1 prim +
        contains
      ]
      if
    ]
    [ false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ count:Int^many seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ distinct:Int^many)
  locals { count seen xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { curr } {
        curr
        seen
        0
        contains
        [
          count
          seen
          xs
          i 1 prim +
          count-distinct-loop
        ]
        [
          seen curr prim seq-int.push
          count 1 prim +
          xs
          i 1 prim +
          count-distinct-loop
        ]
        if
      }
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0
    prim seq-int.empty
    xs
    0
    count-distinct-loop
  };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ]
    if
  };

: reverse-seq
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result seq i } {
    i 0 prim <
    [
      result
    ]
    [
      result seq i prim seq-int.at prim seq-int.push
      seq
      i 1 prim -
      reverse-seq
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty
      n
      digits-loop
      prim seq-int.empty
      swap
      swap prim seq-int.len 1 prim -
      swap
      reverse-seq
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime-helper
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [
        n
        d 1 prim +
        is-prime-helper
      ]
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
    [
      n 2 is-prime-helper
    ]
    if
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many i:Int^many -- ρ primes:Seq Int^many)
  locals { result n i } {
    i n prim <
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      n
      i 1 prim +
      primes-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    n
    2
    primes-loop
  };
```

### task: histogram
```firth
: hist-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ histogram:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup
      counts prim seq-int.at 1 prim +
      counts prim seq-int.set
      drop
      counts
      xs
      i 1 prim +
      hist-loop
    ]
    [
      counts
    ]
    if
  };

: init-counts
  (forall ρ; ρ counts:Seq Int^many k:Int^many j:Int^many -- ρ initialized:Seq Int^many)
  locals { counts k j } {
    j k prim <
    [
      counts 0 prim seq-int.push
      k
      j 1 prim +
      init-counts
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    k
    0
    init-counts
    xs
    0
    hist-loop
  };
```

### task: sort
```firth
: insert-loop
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ inserted:Seq Int^many)
  locals { result val i } {
    i 0 prim <
    [
      result
    ]
    [
      result i prim seq-int.at val prim <
      [
        result i val prim seq-int.set
        val
        result
        i 1 prim -
        insert-loop
      ]
      [
        result i val prim seq-int.set
      ]
      if
    ]
    if
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup
      result prim seq-int.push
      drop
      result
      xs i prim seq-int.at
      result prim seq-int.len 2 prim -
      insert-loop
      xs
      i 1 prim +
      insertion-sort-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    0
    insertion-sort-loop
  };
```

### task: allocate-batch
```firth
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole i } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      dup
      stock prim seq-int.at
      dup
      qtys i prim seq-int.at
      prim <
      [
        drop
        dup 0 prim =
        [
          drop
          0 prim seq-int.push
          stock prim seq-int.set
          allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          stock
          allocated
          reasons
          items
          qtys
          whole
          i 1 prim +
          allocate-loop
        ]
        [
          whole i prim seq-bool.at
          [
            0 prim seq-int.push
            stock prim seq-int.set
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            stock
            allocated
            reasons
            items
            qtys
            whole
            i 1 prim +
            allocate-loop
          ]
          [
            dup
            stock swap prim seq-int.push
            swap
            prim seq-int.set
            allocated prim seq-int.push
            reasons 1 prim seq-int.push
            stock
            allocated
            reasons
            items
            qtys
            whole
            i 1 prim +
            allocate-loop
          ]
          if
        ]
        if
      ]
      [
        drop
        drop
        qtys i prim seq-int.at
        dup
        stock swap prim seq-int.push
        swap
        prim seq-int.set
        allocated prim seq-int.push
        reasons 0 prim seq-int.push
        stock
        allocated
        reasons
        items
        qtys
        whole
        i 1 prim +
        allocate-loop
      ]
      if
    ]
    [
      stock
      allocated
      reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    items
    qtys
    whole
    0
    allocate-loop
  };
```
