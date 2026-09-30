### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1
    xs
    loop-max
  };

: loop-max
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      max
      xs i prim seq-int.at
      prim <
      [ xs i prim seq-int.at ]
      [ max ]
      if
      i 1 prim +
      xs
      loop-max
    ]
    [ max ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len
    1 prim -
    xs
    prim seq-int.empty
    loop-reverse
  };

: loop-reverse
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      xs
      loop-reverse
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 0 prim seq-int.empty xs loop-prefix };

: loop-prefix
  (forall ρ; ρ sum:Int^many i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { sum i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      sum prim +
      dup
      result
      swap
      prim seq-int.push
      i 1 prim +
      xs
      loop-prefix
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs loop-keep };

: loop-keep
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      i 1 prim +
      swap
      xs
      loop-keep
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
    xs prim seq-int.len
    1 prim -
    0 xs
    loop-is-sorted
  };

: loop-is-sorted
  (forall ρ; ρ len:Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { len i xs } {
    i len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <
      [
        i 1 prim +
        len xs
        loop-is-sorted
      ]
      [ false ]
      if
    ]
    [ true ]
    if
  };
```

### task: longest-run
```firth
: max
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim <
    [ b ]
    [ a ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len
    dup 0 prim =
    [ drop 0 ]
    [ dup 1 prim = [ drop 1 ] [ drop 1 1 1 xs loop-longest ] if ]
    if
  };

: loop-longest
  (forall ρ; ρ max-len:Int^many curr-len:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-len curr-len i xs } {
    i xs prim seq-int.len prim <
    [
      xs i 1 prim - prim seq-int.at
      xs i prim seq-int.at
      prim =
      [
        curr-len 1 prim +
        dup
        max-len
        max
        swap
        i 1 prim +
        xs
        loop-longest
      ]
      [
        curr-len
        max-len
        max
        1
        i 1 prim +
        xs
        loop-longest
      ]
      if
    ]
    [ curr-len max-len max ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs loop-count-dist };

: loop-count-dist
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      0 i xs
      [ xs prim seq-int.at i prim < loop-find-dup ]
      [
        count 1 prim +
        i 1 prim +
        xs
        loop-count-dist
      ]
      [
        i 1 prim +
        xs
        loop-count-dist
      ]
      if
    ]
    [ count ]
    if
  };

: loop-find-dup
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many -- ρ is-dup:Bool^many)
  locals { j i xs } {
    j i prim <
    [
      xs j prim seq-int.at
      xs i prim seq-int.at
      prim =
      [ true ]
      [ j 1 prim + i xs loop-find-dup ]
      if
    ]
    [ false ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { 0 0 prim seq-int.empty xs ys loop-merge };

: loop-merge
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i j result xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          xs i prim seq-int.at
          result prim seq-int.push
          i 1 prim +
          j result xs ys
          loop-merge
        ]
        [
          ys j prim seq-int.at
          result prim seq-int.push
          j 1 prim +
          i result xs ys
          loop-merge
        ]
        if
      ]
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        j result xs ys
        loop-merge
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at
        result prim seq-int.push
        j 1 prim +
        i result xs ys
        loop-merge
      ]
      [ result ]
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
    [ { 0 } ]
    [ n prim seq-int.empty loop-digits-collect ]
    if
  };

: loop-digits-collect
  (forall ρ; ρ num:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { num result } {
    num 0 prim =
    [ result loop-reverse-seq ]
    [
      num 10 prim mod
      result prim seq-int.push
      num 10 prim div
      result
      loop-digits-collect
    ]
    if
  };

: loop-reverse-seq
  (forall ρ; ρ seq:Seq Int^many -- ρ result:Seq Int^many)
  locals { seq } {
    seq prim seq-int.len
    1 prim -
    seq
    prim seq-int.empty
    loop-reverse-helper
  };

: loop-reverse-helper
  (forall ρ; ρ i:Int^many seq:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i seq result } {
    i 0 prim <
    [
      seq i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      seq result
      loop-reverse-helper
    ]
    [ result ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        2 n loop-check-prime
      ]
      if
    ]
    if
  };

: loop-check-prime
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod
      0 prim =
      [ false ]
      [ d 1 prim + n loop-check-prime ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { 2 prim seq-int.empty n loop-primes };

: loop-primes
  (forall ρ; ρ i:Int^many result:Seq Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { i result n } {
    i n prim <
    [
      i is-prime
      [
        i result prim seq-int.push
        i 1 prim +
        result
        n
        loop-primes
      ]
      [
        i 1 prim +
        result
        n
        loop-primes
      ]
      if
    ]
    [ result ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0 k prim seq-int.empty
    loop-init-hist
  };

: loop-init-hist
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      result
      loop-init-hist
    ]
    [
      result 0 xs
      loop-histogram
    ]
    if
  };

: loop-histogram
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      result
      xs i prim seq-int.at
      dup
      result prim seq-int.at
      1 prim +
      prim seq-int.set
      i 1 prim +
      xs
      loop-histogram
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 loop-sort };

: loop-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i } {
    i arr prim seq-int.len prim <
    [
      i arr loop-insert
      i 1 prim +
      loop-sort
    ]
    [ arr ]
    if
  };

: loop-insert
  (forall ρ; ρ i:Int^many arr:Seq Int^many -- ρ result:Seq Int^many)
  locals { i arr } {
    i 0 prim <
    [ arr ]
    [
      arr i 1 prim - prim seq-int.at
      arr i prim seq-int.at
      prim <
      [
        arr i prim seq-int.at
        arr i 1 prim - prim seq-int.set
        arr i 1 prim - prim seq-int.at
        arr i prim seq-int.set
        i 1 prim -
        arr
        loop-insert
      ]
      [ arr ]
      if
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs loop-ledger };

: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim +
        dup 0 prim <
        [
          drop
          balance
          rejected 1 prim +
        ]
        [
          rejected
        ]
        if
      }
      i 1 prim +
      txs
      loop-ledger
    ]
    [ balance rejected ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { 0 stock prim seq-int.empty prim seq-int.empty prim seq-int.empty items whole loop-alloc };

: loop-alloc
  (forall ρ; ρ i:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { i stock allocated reasons items whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim <
            [
              stock item qty r prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
            ]
            [
              r 0 prim =
              [
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ]
              [
                whole i prim seq-bool.at
                [
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ]
                [
                  stock item 0 r prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
      i 1 prim +
      stock
      allocated
      reasons
      items whole
      loop-alloc
    ]
    [ stock allocated reasons ]
    if
  };
```
