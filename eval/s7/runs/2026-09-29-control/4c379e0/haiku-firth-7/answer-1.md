### task: seq-sum
```firth
: seq-sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    i xs prim seq-int.len prim <
    [
      acc xs i prim seq-int.at prim +
      xs
      i 1 prim +
      seq-sum-loop
    ]
    [
      acc
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0
    xs
    0
    seq-sum-loop
  };
```

### task: seq-max
```firth
: seq-max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { max xs i curr } {
        curr max prim <
        [ max ]
        [ curr ]
        if
      }
      xs
      i 1 prim +
      seq-max-loop
    ]
    [
      max
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    xs
    0
    seq-max-loop
  };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs k i } {
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
      xs
      k
      i 1 prim +
      count-loop
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    0
    xs
    k
    0
    count-loop
  };
```

### task: index-of
```firth
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [
        i
      ]
      [
        xs
        x
        i 1 prim +
        index-loop
      ]
      if
    ]
    [
      -1
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } {
    xs
    x
    0
    index-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      xs
      i 1 prim -
      reverse-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    xs prim seq-int.len 1 prim -
    reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      result prim seq-int.push
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
      locals { result xs i curr } {
        curr 0 prim <
        [ result ]
        [ result curr prim seq-int.push ]
        if
      }
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
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        prim seq-bool.false
      ]
      [
        xs
        i 1 prim +
        sorted-loop
      ]
      if
    ]
    [
      prim seq-bool.true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ prim seq-bool.true ]
    [
      xs
      0
      sorted-loop
    ]
    if
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ product:Int^many)
  locals { sum xs ys i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      sum prim +
      xs
      ys
      i 1 prim +
      dot-loop
    ]
    [
      sum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0
    xs
    ys
    0
    dot-loop
  };
```

### task: all-true
```firth
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        flags
        i 1 prim +
        all-loop
      ]
      [ prim seq-bool.false ]
      if
    ]
    [ prim seq-bool.true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags
    0
    all-loop
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
        i 1 prim +
        max
        1
        run-loop
      ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          curr-len 1 prim +
          locals { max curr-len xs i new-len } {
            new-len max prim <
            [ max ]
            [ new-len ]
            if
          }
          xs
          i 1 prim +
          new-len
          run-loop
        ]
        [
          xs
          i 1 prim +
          max
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
      1
      0
      0
      run-loop
    ]
    if
  };
```

### task: has-pair-sum
```firth
: pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [
        xs
        target
        i
        j 1 prim +
        pair-inner
      ]
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ prim seq-bool.true ]
        [
          xs
          target
          i
          j 1 prim +
          pair-inner
        ]
        if
      ]
      if
    ]
    [
      xs
      target
      i 1 prim +
      i 2 prim +
      pair-inner
    ]
    if
  };

: pair-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs
      target
      i
      i 1 prim +
      pair-inner
    ]
    [ prim seq-bool.false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs
    target
    0
    pair-outer
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
      [ prim seq-bool.true ]
      [
        val
        seen
        i 1 prim +
        contains
      ]
      if
    ]
    [ prim seq-bool.false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ count:Int^many seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ distinct:Int^many)
  locals { count seen xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { count seen xs i curr } {
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
          count 1 prim +
          seen curr prim seq-int.push
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

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push
          xs
          ys
          i 1 prim +
          j
          merge-loop
        ]
        [
          result ys j prim seq-int.at prim seq-int.push
          xs
          ys
          i
          j 1 prim +
          merge-loop
        ]
        if
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        xs
        ys
        i 1 prim +
        j
        merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        xs
        ys
        i
        j 1 prim +
        merge-loop
      ]
      [
        result
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    xs
    ys
    0
    0
    merge-loop
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
      result seq i prim seq-int.at prim seq-int.push
      seq
      i 1 prim -
      reverse-seq
    ]
    [
      result
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
      [ prim seq-bool.false ]
      [
        n
        d 1 prim +
        is-prime-helper
      ]
      if
    ]
    [ prim seq-bool.true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ prim seq-bool.false ]
    [ n 2 is-prime-helper ]
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
      locals { counts xs i v } {
        counts v prim seq-int.at 1 prim + 
        counts v prim seq-int.set
      }
      xs
      i 1 prim +
      hist-loop
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
    0
    [ k prim seq-int.push 0 prim seq-int.push ] call
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
      result i 1 prim + prim seq-int.at val prim <
      [
        result i val prim seq-int.set
        val
        result
        i 1 prim -
        insert-loop
      ]
      [
        result
      ]
      if
    ]
    [
      result val prim seq-int.set
    ]
    if
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { result xs i v } {
        result v prim seq-int.push
        result
        v
        result prim seq-int.len 2 prim -
        insert-loop
      }
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

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim +
      locals { balance rejected txs i new-bal } {
        new-bal 0 prim <
        [
          balance
          rejected 1 prim +
          txs
          i 1 prim +
          ledger-loop
        ]
        [
          new-bal
          rejected
          txs
          i 1 prim +
          ledger-loop
        ]
        if
      }
    ]
    [
      balance
      rejected
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    txs
    0
    ledger-loop
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
      locals { stock allocated reasons items qtys whole i item } {
        stock item prim seq-int.at
        locals { stock allocated reasons items qtys whole i item curr-stock } {
          qtys i prim seq-int.at curr-stock prim <
          [
            curr-stock 0 prim =
            [
              stock item 0 prim seq-int.set
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
                stock item 0 prim seq-int.set
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
                stock item 0 prim seq-int.set
                allocated curr-stock prim seq-int.push
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
            stock item qtys i prim seq-int.at prim seq-int.set
            allocated qtys i prim seq-int.at prim seq-int.push
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
        }
      }
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
