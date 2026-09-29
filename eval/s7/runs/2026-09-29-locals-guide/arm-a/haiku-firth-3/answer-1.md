### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0
    [ xs prim seq-int.len 0 prim = prim not ]
    [
      0 0
      [ dup xs prim seq-int.len prim < ]
      [
        swap
        swap dup xs swap prim seq-int.at prim +
        swap
        1 prim +
        swap
      ]
      [ drop swap drop ]
      if
    ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      [ prim < ]
      [ swap drop swap ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    0 0
    [ dup xs prim seq-int.len prim < ]
    [
      swap
      dup xs swap prim seq-int.at k prim <
      [ 1 prim + ] [ ] if
      swap
      1 prim +
      swap
    ]
    [ drop swap drop ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } {
    -1 0
    [ dup xs prim seq-int.len prim < dup -1 prim = prim not prim and ]
    [
      dup xs swap prim seq-int.at x prim =
      [ swap drop dup ] [ swap drop ] if
      1 prim +
    ]
    [ drop ]
    if
    swap drop
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    [ dup 0 prim < prim not ]
    [
      dup xs swap prim seq-int.at prim seq-int.push
      1 prim -
    ]
    [ drop ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0 0
    [ dup xs prim seq-int.len prim < ]
    [
      swap
      swap
      dup xs swap prim seq-int.at prim +
      dup
      swap prim seq-int.push
      swap
      swap
      1 prim +
      swap
    ]
    [ drop swap drop ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      [ prim < prim not ]
      [ prim seq-int.push ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    true
    0
    [ dup xs prim seq-int.len 1 prim - prim < ]
    [
      dup xs swap prim seq-int.at
      dup 1 prim + xs swap prim seq-int.at
      prim <
      [ drop ] [ swap drop false swap ] if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    0 0
    [ dup xs prim seq-int.len prim < ]
    [
      swap
      swap
      dup xs swap prim seq-int.at
      dup ys swap prim seq-int.at
      prim *
      prim +
      swap
      1 prim +
      swap
    ]
    [ drop swap drop ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } {
    true
    0
    [ dup flags prim seq-bool.len prim < ]
    [
      dup flags swap prim seq-bool.at
      [ ] [ swap drop false swap ] if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ] [
      0
      xs 0 prim seq-int.at
      1
      1
      [ dup xs prim seq-int.len prim < ]
      [
        dup xs swap prim seq-int.at
        swap
        [ prim = ]
        [ swap 1 prim + swap swap prim + swap ]
        [ swap drop 1 swap swap drop swap prim + swap ]
        if
        1 prim +
      ]
      [ drop swap drop swap drop ]
      if
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    false
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      target swap prim -
      1
      [ dup xs prim seq-int.len prim < ]
      [
        dup xs swap prim seq-int.at
        swap
        [ prim = swap drop true swap ] [ drop ] if
        1 prim +
      ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      dup swap
      0
      [ dup swap prim seq-int.len prim < ]
      [
        dup swap prim seq-int.at
        swap
        [ prim = ] [ drop false ] if
        1 prim +
      ]
      [ drop drop ]
      if
      [ prim seq-int.push ] [ drop ] if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0 0
    [ dup xs prim seq-int.len prim < dup ys prim seq-int.len prim < prim or ]
    [
      swap swap
      dup xs prim seq-int.len prim <
      dup ys prim seq-int.len prim <
      [ prim < ]
      [ drop false ] if
      swap swap
      [ drop dup xs swap prim seq-int.at prim seq-int.push swap 1 prim + swap drop ]
      [ drop dup ys swap prim seq-int.at prim seq-int.push drop swap 1 prim + ]
      if
    ]
    [ drop drop ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ] [
      prim seq-int.empty
      n
      [ dup 0 prim < prim not ]
      [
        dup 10 prim mod
        swap prim seq-int.push
        10 prim div
      ]
      [ drop ]
      if
      dup prim seq-int.len 1 prim -
      [ dup 0 prim < prim not ]
      [
        dup swap prim seq-int.at
        swap swap
        1 prim -
        dup prim seq-int.len prim <
        [ dup swap 1 prim + swap prim seq-int.at prim seq-int.set ]
        [ drop drop ]
        if
      ]
      [ drop drop ]
      if
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-bool.empty
    0
    [ dup n 1 prim + prim < ]
    [ true prim seq-bool.push 1 prim + ]
    [ drop ]
    if
    prim seq-int.empty
    2
    [ dup n prim < ]
    [
      dup 0 prim seq-int.at
      [ dup prim seq-int.push ] [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ dup k prim < ]
    [ 0 prim seq-int.push 1 prim + ]
    [ drop ]
    if
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      dup 0 prim seq-int.at 1 prim + prim seq-int.set
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs
    0
    [ dup xs prim seq-int.len 1 prim - prim < ]
    [
      dup 1 prim +
      [ dup xs prim seq-int.len prim < ]
      [
        dup xs swap prim seq-int.at
        swap dup 1 prim - xs swap prim seq-int.at
        [ prim < ]
        [ swap prim seq-int.set ] [ drop swap ] if
        1 prim +
      ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0 0
    [ dup txs prim seq-int.len prim < ]
    [
      dup txs swap prim seq-int.at
      swap
      dup rot prim +
      dup 0 prim <
      [ drop swap 1 prim + swap ] [ swap drop swap ] if
      swap 1 prim +
      swap
    ]
    [ drop swap drop ]
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
    [ dup qtys prim seq-int.len prim < ]
    [
      dup items swap prim seq-int.at
      dup stock swap prim seq-int.at
      dup qtys swap prim seq-int.at
      dup whole swap prim seq-int.at
      swap
      [ prim < prim not ]
      [ swap prim seq-int.push 0 prim seq-int.push ]
      [
        dup 0 prim =
        [ drop drop 0 prim seq-int.push 2 prim seq-int.push ]
        [
          swap
          [ drop drop 0 prim seq-int.push 3 prim seq-int.push ]
          [ drop prim seq-int.push 1 prim seq-int.push ]
          if
        ]
        if
      ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };
```
