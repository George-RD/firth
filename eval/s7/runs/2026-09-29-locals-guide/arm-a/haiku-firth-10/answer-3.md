### task: reverse
```firth
: reverse-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim <
    [
      result
    ]
    [
      xs
      idx 1 prim -
      result xs idx prim seq-int.at prim seq-int.push
      reverse-from
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-from
  };
```

### task: prefix-sums
```firth
: prefix-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many acc:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx acc result } {
    idx xs prim seq-int.len prim <
    [
      xs
      idx 1 prim +
      xs idx prim seq-int.at
      acc prim +
      dup
      result swap prim seq-int.push
      prefix-from
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-from
  };
```

### task: keep-positive
```firth
: filter-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [
      0 xs idx prim seq-int.at prim <
      [
        result xs idx prim seq-int.at prim seq-int.push
        xs
        idx 1 prim +
        swap
        filter-from
      ]
      [
        xs
        idx 1 prim +
        result
        filter-from
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-from
  };
```

### task: is-sorted
```firth
: check-sorted
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim <
    [
      xs idx 1 prim + prim seq-int.at
      xs idx prim seq-int.at
      prim <
      [
        false
      ]
      [
        xs
        idx 1 prim +
        check-sorted
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
    [
      true
    ]
    [
      xs 0 check-sorted
    ]
    if
  };
```

### task: dot
```firth
: dot-from
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many idx:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys idx acc } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      ys idx prim seq-int.at
      prim *
      acc prim +
      xs
      ys
      idx 1 prim +
      swap
      swap
      dot-from
    ]
    [
      acc
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-from
  };
```

### task: longest-run
```firth
: max-run
  (forall ρ; ρ xs:Seq Int^many idx:Int^many cur-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs idx cur-run max-run } {
    idx xs prim seq-int.len 1 prim - prim <
    [
      xs idx prim seq-int.at
      xs idx 1 prim + prim seq-int.at
      prim =
      [
        xs
        idx 1 prim +
        cur-run 1 prim +
        cur-run 1 prim + max-run prim <
        [
          cur-run 1 prim +
        ]
        [
          max-run
        ]
        if
        max-run
      ]
      [
        xs
        idx 1 prim +
        1
        cur-run 1 prim + max-run prim <
        [
          cur-run 1 prim +
        ]
        [
          max-run
        ]
        if
      ]
      if
    ]
    [
      cur-run 1 prim +
      max-run prim <
      [
        cur-run 1 prim +
      ]
      [
        max-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim <
    [
      0
    ]
    [
      xs 0 1 0 max-run
    ]
    if
  };
```

### task: count-distinct
```firth
: count-distinct
  (forall ρ; ρ xs:Seq Int^many idx:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs idx seen } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      0
      0
      [ dup seen swap prim seq-int.at prim = ]
      [
        true
      ]
      [
        false
      ]
      if
      [
        drop
        xs
        idx 1 prim +
        seen
        count-distinct
      ]
      [
        drop
        xs
        idx 1 prim +
        seen xs idx prim seq-int.at prim seq-int.push
        count-distinct
      ]
      if
    ]
    [
      seen prim seq-int.len
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty count-distinct
  };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          xs
          ys
          i 1 prim +
          j
          result xs i prim seq-int.at prim seq-int.push
          merge-loop
        ]
        [
          xs
          ys
          i
          j 1 prim +
          result ys j prim seq-int.at prim seq-int.push
          merge-loop
        ]
        if
      ]
      [
        xs
        ys
        i 1 prim +
        j
        result xs i prim seq-int.at prim seq-int.push
        merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        xs
        ys
        i
        j 1 prim +
        result ys j prim seq-int.at prim seq-int.push
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
    xs ys 0 0 prim seq-int.empty merge-loop
  };
```

### task: digits
```firth
: digits-reverse
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim <
    [
      result
    ]
    [
      xs
      idx 1 prim -
      result xs idx prim seq-int.at prim seq-int.push
      digits-reverse
    ]
    if
  };

: digits-from
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      swap
      digits-from
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n prim seq-int.empty digits-from
      dup prim seq-int.len 1 prim -
      prim seq-int.empty
      digits-reverse
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim <
    [
      num divisor prim mod 0 prim =
      [
        false
      ]
      [
        num
        divisor 1 prim +
        is-prime
      ]
      if
    ]
    [
      true
    ]
    if
  };

: primes-from
  (forall ρ; ρ current:Int^many limit:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { current limit result } {
    current limit prim <
    [
      current 2 prim <
      [
        current
        limit
        result
        primes-from
      ]
      [
        current 2 is-prime
        [
          current
          limit
          result current prim seq-int.push
          primes-from
        ]
        [
          current
          limit
          result
          primes-from
        ]
        if
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty primes-from
  };
```

### task: histogram
```firth
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k idx counts } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      dup
      counts swap prim seq-int.at
      1 prim +
      counts
      swap
      swap
      prim seq-int.set
      xs
      k
      idx 1 prim +
      swap
      histogram-loop
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
    [ dup k prim < ]
    [
      swap prim seq-int.push swap
      1 prim +
      swap
    ]
    [ drop drop ]
    if
    xs k 0 swap histogram-loop
  };
```

### task: sort
```firth
: dup-below
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  locals { a b } {
    a b a
  };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      i 1 prim -
      [ dup 0 prim < ]
      [
        xs swap prim seq-int.at
        dup-below prim <
      ]
      [ drop false ]
      if
      [
        dup
        1 prim +
        xs
        swap
        prim seq-int.at
        xs
        swap
        prim seq-int.set
        1 prim -
      ]
      [
        drop
      ]
      if
      xs
      i 1 prim +
      insertion-sort
    ]
    [
      xs
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 1 insertion-sort
  };
```

### task: ledger
```firth
: apply-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs idx } {
    idx txs prim seq-int.len prim <
    [
      txs idx prim seq-int.at
      balance prim +
      dup 0 prim <
      [
        drop
        balance
        rejected 1 prim +
        txs
        idx 1 prim +
        apply-transactions
      ]
      [
        balance
        rejected
        txs
        idx 1 prim +
        apply-transactions
      ]
      if
    ]
    [
      balance
      rejected
    ]
    if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ final-balance:Int^many rejected:Int^many)
  locals { balance txs } {
    balance 0 txs 0 apply-transactions
  };
```

### task: allocate-batch
```firth
: dup-below
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  locals { a b } {
    a b a
  };

: allocate-item
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole order-idx allocated reasons } {
    order-idx qtys prim seq-int.len prim <
    [
      items order-idx prim seq-int.at
      dup
      stock swap prim seq-int.at
      dup
      qtys order-idx prim seq-int.at
      dup-below prim <
      [
        stock
        items
        qtys
        whole
        order-idx 1 prim +
        allocated qtys order-idx prim seq-int.at prim seq-int.push
        reasons 0 prim seq-int.push
        allocate-item
      ]
      [
        swap
        0 prim =
        [
          stock
          items
          qtys
          whole
          order-idx 1 prim +
          allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          allocate-item
        ]
        [
          whole order-idx prim seq-bool.at
          [
            stock
            items
            qtys
            whole
            order-idx 1 prim +
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            allocate-item
          ]
          [
            dup
            stock
            swap
            prim seq-int.set
            items
            qtys
            whole
            order-idx 1 prim +
            swap
            allocated prim seq-int.push
            reasons 1 prim seq-int.push
            allocate-item
          ]
          if
        ]
        if
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
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-item
  };
```

