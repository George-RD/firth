### task: seq-sum
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many -- ρ sum:Int^many)
  locals { i xs sum } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at sum prim +
      loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 loop };
```

### task: seq-max
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ max:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at max prim <
      [ max ]
      [ xs i prim seq-int.at ]
      if
      loop
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { 
    xs 0 prim seq-int.at
    1 xs
    loop
  };
```

### task: count-below
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many k:Int^many count:Int^many -- ρ count:Int^many)
  locals { i xs k count } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      k
      xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 xs k 0 loop };
```

### task: index-of
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many found:Int^many -- ρ found:Int^many)
  locals { i xs x found } {
    found 0 prim <
    [ found ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at x prim =
        [ i ]
        [ i 1 prim + xs x -1 loop ]
        if
      ]
      [ -1 ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x -1 loop };
```

### task: reverse
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [ result ]
    [
      i 1 prim -
      xs
      xs i 1 prim - prim seq-int.at result prim seq-int.push
      loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len
    xs
    prim seq-int.empty
    loop
  };
```

### task: prefix-sums
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs sum result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      i 1 prim +
      xs
      result
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 0 xs prim seq-int.empty loop };
```

### task: keep-positive
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at 0 prim <
      [ result ]
      [ result xs i prim seq-int.at prim seq-int.push ]
      if
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { 0 xs prim seq-int.empty loop };
```

### task: is-sorted
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sorted:Bool^many -- ρ sorted:Bool^many)
  locals { i xs sorted } {
    sorted prim not
    [ false ]
    [
      i 1 prim + xs prim seq-int.len prim <
      [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
        [ false ]
        [ i 1 prim + xs true loop ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 xs true loop ]
    if
  };
```

### task: dot
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many ys:Seq Int^many sum:Int^many -- ρ sum:Int^many)
  locals { i xs ys sum } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      ys
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 xs ys 0 loop };
```

### task: all-true
```firth
: loop
  (forall ρ; ρ i:Int^many flags:Seq Bool^many result:Bool^many -- ρ result:Bool^many)
  locals { i flags result } {
    result prim not
    [ false ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at prim not
        [ false ]
        [ i 1 prim + flags true loop ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 0 flags true loop };
```

### task: longest-run
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many current:Int^many max:Int^many -- ρ max:Int^many)
  locals { i xs current max } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
      [
        i 1 prim +
        xs
        current 1 prim +
        current 1 prim + max prim <
        [ max ]
        [ current 1 prim + ]
        if
        loop
      ]
      [
        i 1 prim +
        xs
        1
        max
        loop
      ]
      if
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ 0 ]
    [ 1 xs 1 0 loop ]
    if
  };
```

### task: has-pair-sum
```firth
: inner-loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many found:Bool^many -- ρ found:Bool^many)
  locals { i j xs target found } {
    found
    [ true ]
    [
      j xs prim seq-int.len prim <
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ i j 1 prim + xs target false inner-loop ]
        if
      ]
      [ i 1 prim + xs target false outer-loop ]
      if
    ]
    if
  };

: outer-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many found:Bool^many -- ρ found:Bool^many)
  locals { i xs target found } {
    found
    [ true ]
    [
      i xs prim seq-int.len 1 prim - prim <
      [ i i 1 prim + xs target false inner-loop ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target false outer-loop };
```

### task: count-distinct
```firth
: inner-loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many found:Bool^many -- ρ found:Bool^many)
  locals { i j xs found } {
    found
    [ true ]
    [
      j i prim <
      [
        xs i prim seq-int.at xs j prim seq-int.at prim =
        [ true ]
        [ i j 1 prim + xs false inner-loop ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: outer-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many count:Int^many -- ρ count:Int^many)
  locals { i xs count } {
    i xs prim seq-int.len prim <
    [
      i 0 xs false inner-loop
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim +
      xs
      outer-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 outer-loop };
```

### task: merge-sorted
```firth
: loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i j xs ys result } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          i 1 prim +
          j
          xs
          ys
          result xs i prim seq-int.at prim seq-int.push
          loop
        ]
        [
          i
          j 1 prim +
          xs
          ys
          result ys j prim seq-int.at prim seq-int.push
          loop
        ]
        if
      ]
      [
        i xs prim seq-int.len prim <
        [
          i 1 prim +
          j
          xs
          ys
          result xs i prim seq-int.at prim seq-int.push
          loop
        ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        i
        j 1 prim +
        xs
        ys
        result ys j prim seq-int.at prim seq-int.push
        loop
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { 0 0 xs ys prim seq-int.empty loop };
```

### task: digits
```firth
: loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div
      loop
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many digits:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i digits result } {
    i 0 prim <
    [ result ]
    [
      i 1 prim -
      digits
      digits i 1 prim - prim seq-int.at result prim seq-int.push
      reverse-digits
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim <
    [ n 0 prim - prim seq-int.empty loop ]
    [
      n prim seq-int.empty loop
      prim seq-int.len
      prim seq-int.empty
      reverse-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ n:Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { n candidate } {
    candidate 2 prim <
    [ false ]
    [
      candidate 2 prim <
      [ true ]
      [
        2
        candidate
        candidate
        true
        [ locals { i candidate result } {
          result prim not
          [ true ]
          [
            i i prim * candidate prim <
            [
              candidate i prim mod 0 prim =
              [ false ]
              [ i 1 prim + candidate result ]
              if
            ]
            [ true ]
            if
          ]
          if
        } ]
        call
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { 2 n prim seq-int.empty [ locals { i n result } { i n prim < [ i n prim seq-int.empty is-prime [ result i prim seq-int.push i 1 prim + n result ] [ i 1 prim + n result ] if ] [ result ] if } ] call };
```

### task: histogram
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at
      counts xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      loop
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0
    k
    0
    [ locals { i k counts } { i k prim < [ counts 0 prim seq-int.push i 1 prim + k counts ] [ counts ] if } ]
    call
    loop
  };
```

### task: sort
```firth
: insert
  (forall ρ; ρ x:Int^many i:Int^many arr:Seq Int^many -- ρ arr:Seq Int^many)
  locals { x i arr } {
    i 0 prim <
    [ arr x prim seq-int.push ]
    [
      arr i prim seq-int.at x prim <
      [
        i 1 prim -
        arr x prim seq-int.push
        insert
      ]
      [ arr x prim seq-int.push ]
      if
    ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at
      result prim seq-int.len 1 prim -
      result
      insert
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { 0 xs prim seq-int.empty loop };
```

### task: ledger
```firth
: loop
  (forall ρ; ρ i:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { i txs balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at balance prim + 0 prim <
      [
        i 1 prim +
        txs
        balance
        rejected 1 prim +
        loop
      ]
      [
        i 1 prim +
        txs
        txs i prim seq-int.at balance prim +
        rejected
        loop
      ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { 0 txs start 0 loop };
```

### task: allocate-batch
```firth
: allocate-item
  (forall ρ; ρ item-idx:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many -- ρ allocated:Int^many reason:Int^many stock:Seq Int^many)
  locals { item-idx qty whole stock } {
    stock item-idx prim seq-int.at
    qty prim <
    [ qty prim < ]
    [ qty prim = ]
    [ 0 prim < ]
    if
    [ qty 0 stock item-idx qty prim - prim seq-int.set ]
    [
      stock item-idx prim seq-int.at 0 prim =
      [ 0 2 stock ]
      [
        whole
        [ 0 3 stock ]
        [ stock item-idx prim seq-int.at stock item-idx 0 prim seq-int.set 1 stock ]
        if
      ]
      if
    ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many)
  locals { i items qtys whole stock allocated reasons } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      stock
      allocate-item
      i 1 prim +
      items
      qtys
      whole
      loop
    ]
    [ allocated reasons stock ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0
    items
    qtys
    whole
    stock
    prim seq-int.empty
    prim seq-int.empty
    loop
  };
```

