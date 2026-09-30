### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs sum-helper };

: sum-helper
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      1 i prim +
      xs
      sum-helper
    ]
    [ sum ]
    if
  };
```

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
      [ max prim < [ swap ] [ ] if ] call
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
    count-loop
  };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ count prim < [ count 1 prim + ] [ count ] if ]
      call
      i 1 prim +
      xs
      count-loop
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
    0
    xs
    x
    index-loop
  };

: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ final-index:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [ i ]
      [
        i 1 prim +
        xs
        x
        index-loop
      ]
      if
    ]
    [ -1 ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    prim not
    [
      result xs i prim seq-int.at prim seq-int.push
      i 1 prim -
      xs
      reverse-loop
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
      [ result prim seq-int.push ]
      dip
      i 1 prim +
      xs
      prefix-loop
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
      [ 0 prim < [ result prim seq-int.push ] [ ] if ]
      call
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
      0
      xs
      is-sorted-loop
    ]
    if
  };

: is-sorted-loop
  (forall ρ; ρ result:Bool^many i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { result i xs } {
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
          i 1 prim +
          xs
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

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0
    0
    xs
    ys
    dot-product
  };

: dot-product
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      xs
      ys
      dot-product
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
    1
    0
    flags
    all-true-loop
  };

: all-true-loop
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result i flags } {
    result prim not
    [ 0 ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
        [ 1 i 1 prim + flags all-true-loop ]
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
    [ 0 ]
    [ 0 1 0 xs longest-run-loop ]
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
      0
      xs
      xs i prim seq-int.at
      i
      [ check-if-new-inner ]
      dip
      [ count 1 prim + count-next ]
      [ count-next ]
      if
    ]
    [ count ]
    if
  };

: check-if-new-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many elem:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j xs elem i } {
    j i prim <
    [
      xs j prim seq-int.at elem prim =
      [ 1 ]
      [
        j 1 prim +
        xs
        elem
        i
        check-if-new-inner
      ]
      if
    ]
    [ 0 ]
    if
  };

: count-next
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i 1 prim +
    xs
    count-distinct-main
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0
    0
    xs
    ys
    merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          result xs i prim seq-int.at prim seq-int.push
          i 1 prim +
          j
          xs
          ys
          merge-loop
        ]
        [
          result ys j prim seq-int.at prim seq-int.push
          i
          j 1 prim +
          xs
          ys
          merge-loop
        ]
        if
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        j
        xs
        ys
        merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        i
        j 1 prim +
        xs
        ys
        merge-loop
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
    [ prim seq-int.empty n extract-digits-reverse ]
    call
    reverse-digits
  };

: extract-digits-reverse
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      extract-digits-reverse
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    prim not
    [
      result xs i prim seq-int.at prim seq-int.push
      i 1 prim -
      xs
      reverse-loop
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
      [ i is-prime ]
      call
      [
        result i prim seq-int.push
      ]
      [ result ]
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
    [ init-histogram ]
    call
    xs
    k
    fill-histogram
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { result i k } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      init-histogram
    ]
    [ result ]
    if
  };

: fill-histogram
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { result xs k } {
    0
    xs
    result
    k
    fill-loop
  };

: fill-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { i xs result k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ result prim seq-int.at 1 prim + result prim seq-int.set ]
      dip
      i 1 prim +
      xs
      result
      k
      fill-loop
    ]
    [ result ]
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
      [ xs i prim seq-int.at result 0 insert-into-sorted ]
      call
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
      [ balance prim + 0 prim < ]
      call
      [
        rejected 1 prim +
      ]
      [
        balance prim +
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
      [ stock prim seq-int.at ]
      dip
      [ qtys j prim seq-int.at prim < ]
      call
      [
        [ 0 prim = ]
        call
        [ 0 2 ]
        [
          [ whole j prim seq-bool.at ]
          call
          [ 0 3 ]
          [
            prim seq-int.at
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
      [ allocated prim seq-int.push ]
      dip
      [ reasons prim seq-int.push ]
      dip
      [ prim - stock prim seq-int.set ]
      dip
      j 1 prim +
      items
      qtys
      whole
      allocate-loop
    ]
    [ stock allocated reasons ]
    if
  };
```
