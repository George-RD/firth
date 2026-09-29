### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs loop-max
  };

: loop-max
  (forall ρ; ρ max:Int^many index:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at dup max prim <
      [ drop max ]
      [ max drop ]
      if
      index 1 prim +
      xs
      loop-max
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
    0 0 xs k loop-count
  };

: loop-count
  (forall ρ; ρ count:Int^many index:Int^many xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { count index xs k } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      index 1 prim +
      xs k
      loop-count
    ]
    [ count ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    -1 0 xs x loop-index-of
  };

: loop-index-of
  (forall ρ; ρ found:Int^many index:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { found index xs x } {
    found 0 prim <
    [
      index xs prim seq-int.len prim <
      [
        xs index prim seq-int.at x prim =
        [
          index index 1 prim + xs x loop-index-of
        ]
        [
          -1 index 1 prim + xs x loop-index-of
        ]
        if
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs loop-reverse
  };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      result xs index prim seq-int.at prim seq-int.push
      index 1 prim +
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
  locals { xs } {
    prim seq-int.empty 0 0 xs loop-prefix
  };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many index:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at sum prim +
      result swap prim seq-int.push
      index 1 prim +
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
  locals { xs } {
    prim seq-int.empty 0 xs loop-keep-positive
  };

: loop-keep-positive
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      dup 0 prim <
      [
        drop result
      ]
      [
        result swap prim seq-int.push
      ]
      if
      index 1 prim +
      xs
      loop-keep-positive
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
    true 0 xs loop-is-sorted
  };

: loop-is-sorted
  (forall ρ; ρ is-sorted:Bool^many index:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { is-sorted index xs } {
    is-sorted
    [
      index 1 prim + xs prim seq-int.len prim < 
      [
        xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim <
        [ false ]
        [ true ]
        if
        index 1 prim +
        xs
        loop-is-sorted
      ]
      [ is-sorted ]
      if
    ]
    [ is-sorted ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0 xs ys loop-dot
  };

: loop-dot
  (forall ρ; ρ sum:Int^many index:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum index xs ys } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at ys index prim seq-int.at prim * sum prim +
      index 1 prim +
      xs ys
      loop-dot
    ]
    [ sum ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true 0 flags loop-all-true
  };

: loop-all-true
  (forall ρ; ρ result:Bool^many index:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result index flags } {
    index flags prim seq-bool.len prim <
    [
      result
      [
        flags index prim seq-bool.at
        [
          true
          index 1 prim +
          flags
          loop-all-true
        ]
        [ false ]
        if
      ]
      [ false ]
      if
    ]
    [ result ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    0 1 0 xs loop-longest-run
  };

: loop-longest-run
  (forall ρ; ρ max-len:Int^many current-len:Int^many index:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-len current-len index xs } {
    index xs prim seq-int.len prim <
    [
      index 0 prim =
      [
        max-len current-len 1 xs loop-longest-run
      ]
      [
        xs index prim seq-int.at xs index 1 prim - prim seq-int.at prim =
        [
          max-len current-len 1 prim + 
          index 1 prim +
          xs
          loop-longest-run
        ]
        [
          max-len current-len prim < [ current-len ] [ max-len ] if
          1 index 1 prim +
          xs
          loop-longest-run
        ]
        if
      ]
      if
    ]
    [ max-len current-len prim < [ current-len ] [ max-len ] if ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false 0 xs target loop-has-pair
  };

: loop-has-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { found i xs target } {
    found prim not
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + i xs target loop-inner-pair
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: loop-inner-pair
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true i xs target loop-has-pair
      ]
      [
        j 1 prim +
        i xs target
        loop-inner-pair
      ]
      if
    ]
    [
      i 1 prim +
      xs target
      loop-has-pair
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs loop-count-distinct
  };

: loop-count-distinct
  (forall ρ; ρ seen:Seq Int^many index:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at 0 seen find-in-seq
      [
        seen
      ]
      [
        seen xs index prim seq-int.at prim seq-int.push
      ]
      if
      index 1 prim +
      xs
      loop-count-distinct
    ]
    [ seen prim seq-int.len ]
    if
  };

: find-in-seq
  (forall ρ; ρ target:Int^many i:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { target i seq } {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at target prim =
      [
        true
      ]
      [
        target i 1 prim + seq find-in-seq
      ]
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
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys loop-merge
  };

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys loop-merge
        ]
        [
          result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys loop-merge
        ]
        if
      ]
      [
        i xs prim seq-int.len prim <
        [
          result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys loop-merge
        ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys loop-merge
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
    prim seq-int.empty n 0 loop-digits
  };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many index:Int^many -- ρ digits:Seq Int^many)
  locals { result n index } {
    n 0 prim =
    [
      result prim seq-int.len 0 prim =
      [
        prim seq-int.empty 0 prim seq-int.push
      ]
      [ result prim seq-int.empty 0 swap loop-reverse ]
      if
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div index 1 prim +
      loop-digits
    ]
    if
  };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      result xs index prim seq-int.at prim seq-int.push
      index 1 prim +
      xs
      loop-reverse
    ]
    [ result ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n loop-primes
  };

: loop-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [
      candidate 2 swap is-prime
      [
        result candidate prim seq-int.push candidate 1 prim + n loop-primes
      ]
      [
        candidate 1 prim + n loop-primes
      ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [
      candidate divisor prim mod 0 prim =
      [
        false
      ]
      [
        candidate divisor 1 prim + is-prime
      ]
      if
    ]
    [ true ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 xs k loop-histogram
  };

: loop-histogram
  (forall ρ; ρ result:Seq Int^many v:Int^many xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { result v xs k } {
    v k prim <
    [
      0 0 xs v count-value
      result swap prim seq-int.push v 1 prim + xs k loop-histogram
    ]
    [ result ]
    if
  };

: count-value
  (forall ρ; ρ count:Int^many index:Int^many xs:Seq Int^many v:Int^many -- ρ total:Int^many)
  locals { count index xs v } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at v prim =
      [ count 1 prim + ]
      [ count ]
      if
      index 1 prim +
      xs v
      count-value
    ]
    [ count ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 loop-sort
  };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      i 0 i xs find-min-from
      xs swap i prim seq-int.set i 1 prim + loop-sort
    ]
    [ xs ]
    if
  };

: find-min-from
  (forall ρ; ρ min-idx:Int^many j:Int^many xs:Seq Int^many -- ρ min-val:Int^many)
  locals { min-idx j xs } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at xs min-idx prim seq-int.at prim <
      [ j ]
      [ min-idx ]
      if
      j 1 prim +
      xs
      find-min-from
    ]
    [ xs min-idx prim seq-int.at ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ final:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs loop-ledger
  };

: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many index:Int^many txs:Seq Int^many -- ρ final:Int^many rejected:Int^many)
  locals { balance rejected index txs } {
    index txs prim seq-int.len prim <
    [
      txs index prim seq-int.at balance prim + 0 prim <
      [
        balance rejected 1 prim + index 1 prim + txs loop-ledger
      ]
      [
        txs index prim seq-int.at balance prim + rejected index 1 prim + txs loop-ledger
      ]
      if
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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole loop-allocate
  };

: loop-allocate
  (forall ρ; ρ stock:Seq Int^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock stock-left allocated reasons order items qtys whole } {
    order qtys prim seq-int.len prim <
    [
      items order prim seq-int.at stock prim seq-int.at
      qtys order prim seq-int.at
      dup swap prim <
      [
        allocated swap prim seq-int.push
        reasons 0 prim seq-int.push
        items order prim seq-int.at swap stock prim seq-int.set stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
      ]
      [
        drop dup 0 prim =
        [
          drop allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
        ]
        [
          whole order prim seq-bool.at
          [
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
          ]
          [
            allocated swap prim seq-int.push
            reasons 1 prim seq-int.push
            items order prim seq-int.at 0 stock prim seq-int.set stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock-left allocated reasons ]
    if
  };
```
