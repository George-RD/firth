### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  i len prim <
  [ locals { acc i xs len } {
      acc xs i prim seq-int.at prim +
      i 1 prim +
      xs len
      sum-loop
    } ]
  [ drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 0 xs xs prim seq-int.len
    sum-loop
  };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  i len prim <
  [ locals { max i xs len } {
      xs i prim seq-int.at
      max prim <
      [ locals { xs i len } { xs i prim seq-int.at } ]
      [ max ]
      if
      i 1 prim +
      xs len
      max-loop
    } ]
  [ drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1 xs xs prim seq-int.len
    max-loop
  };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many k:Int^many len:Int^many -- ρ result:Int^many)
  i len prim <
  [ locals { count i xs k len } {
      xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim +
      xs k len
      count-loop
    } ]
  [ drop drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    0 0 xs k xs prim seq-int.len
    count-loop
  };
```

### task: index-of
```firth
: search-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many len:Int^many -- ρ result:Int^many)
  i len prim <
  [ locals { i xs x len } {
      xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs x len search-loop ]
      if
    } ]
  [ drop drop drop -1 ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } {
    0 xs x xs prim seq-int.len
    search-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  i len prim <
  [ locals { result i xs len } {
      len i prim - 1 prim - xs prim seq-int.at result prim seq-int.push
      i 1 prim +
      xs len
      reverse-loop
    } ]
  [ drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs xs prim seq-int.len
    reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  i len prim <
  [ locals { result sum i xs len } {
      sum xs i prim seq-int.at prim +
      result swap prim seq-int.push
      i 1 prim +
      xs len
      prefix-loop
    } ]
  [ drop drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs xs prim seq-int.len
    prefix-loop
  };
```

### task: keep-positive
```firth
: filter-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  i len prim <
  [ locals { result i xs len } {
      xs i prim seq-int.at
      dup 0 prim <
      [ drop result ]
      [ result swap prim seq-int.push ]
      if
      i 1 prim +
      xs len
      filter-loop
    } ]
  [ drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs xs prim seq-int.len
    filter-loop
  };
```

### task: is-sorted
```firth
: sorted-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Bool^many)
  i len 1 prim - prim <
  [ locals { i xs len } {
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ i 1 prim + xs len sorted-loop ]
      [ prim not [ drop drop drop false ] ]
      if
    } ]
  [ drop drop drop true ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    0 xs xs prim seq-int.len
    sorted-loop
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many len:Int^many -- ρ result:Int^many)
  i len prim <
  [ locals { sum i xs ys len } {
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      i 1 prim +
      xs ys len
      dot-loop
    } ]
  [ drop drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    0 0 xs ys xs prim seq-int.len
    dot-loop
  };
```

### task: all-true
```firth
: all-loop
  (forall ρ; ρ i:Int^many flags:Seq Bool^many len:Int^many -- ρ result:Bool^many)
  i len prim <
  [ locals { i flags len } {
      flags i prim seq-bool.at
      [ i 1 prim + flags len all-loop ]
      [ drop drop drop false ]
      if
    } ]
  [ drop drop drop true ]
  if;

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } {
    0 flags flags prim seq-bool.len
    all-loop
  };
```

### task: longest-run
```firth
: run-loop
  (forall ρ; ρ maxlen:Int^many curlen:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  i len prim <
  [ locals { maxlen curlen i xs len } {
      i 0 prim =
      [ 1 0 i 1 prim + xs len run-loop ]
      [ xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [ curlen 1 prim + dup maxlen prim < [ drop maxlen ] [ nip ] if i 1 prim + xs len run-loop ]
        [ 1 maxlen curlen prim < [ drop 1 ] [ nip ] if i 1 prim + xs len run-loop ]
        if
      ]
      if
    } ]
  [ drop drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len
    dup 0 prim =
    [ drop 0 ]
    [ 0 0 0 xs swap run-loop ]
    if
  };
```

### task: has-pair-sum
```firth
: pair-inner
  (forall ρ; ρ found:Bool^many j:Int^many i:Int^many xs:Seq Int^many target:Int^many len:Int^many -- ρ result:Bool^many)
  j len prim <
  [ locals { found j i xs target len } {
      i j prim =
      [ j 1 prim + i xs target len pair-inner ]
      [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ drop drop drop drop drop true ]
        [ j 1 prim + i xs target len pair-inner ]
        if
      ]
      if
    } ]
  [ drop drop drop drop drop false ]
  if;

: pair-outer
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many len:Int^many -- ρ result:Bool^many)
  found [ drop drop drop drop true ]
  [ i len 1 prim - prim <
    [ locals { i xs target len } {
        false i 1 prim + i xs target len pair-inner
        [ drop drop drop false ]
        [ true drop drop drop ]
        if
        [ drop drop drop true ]
        [ i 1 prim + xs target len pair-outer ]
        if
      } ]
    [ drop drop drop drop false ]
    if
  ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    false 0 xs target xs prim seq-int.len
    pair-outer
  };
```

### task: count-distinct
```firth
: distinct-inner
  (forall ρ; ρ j:Int^many i:Int^many val:Int^many xs:Seq Int^many len:Int^many -- ρ result:Bool^many)
  j len prim <
  [ locals { j i val xs len } {
      xs j prim seq-int.at val prim =
      [ drop drop drop drop true ]
      [ j 1 prim + i val xs len distinct-inner ]
      if
    } ]
  [ drop drop drop drop false ]
  if;

: distinct-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  i len prim <
  [ locals { count i xs len } {
      xs i prim seq-int.at
      i 1 prim + i xs len distinct-inner
      [ count ]
      [ count 1 prim + ]
      if
      i 1 prim +
      xs len
      distinct-loop
    } ]
  [ drop drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 0 xs xs prim seq-int.len
    distinct-loop
  };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many lenx:Int^many leny:Int^many -- ρ result:Seq Int^many)
  i lenx prim <
  [ j leny prim <
    [ locals { result i j xs ys lenx leny } {
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys lenx leny merge-loop ]
        [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys lenx leny merge-loop ]
        if
      } ]
    [ locals { result i j xs ys lenx leny } {
        i lenx prim <
        [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys lenx leny merge-loop ]
        [ result ]
        if
        drop drop drop drop drop
      }
    ]
    if
  ]
  [ j leny prim <
    [ locals { result i j xs ys lenx leny } {
        j leny prim <
        [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys lenx leny merge-loop ]
        [ result ]
        if
        drop drop drop drop drop
      } ]
    [ result drop drop drop drop drop drop drop ]
    if
  ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys xs prim seq-int.len ys prim seq-int.len
    merge-loop
  };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  n 0 prim =
  [ result ]
  [ locals { result n } {
      n 10 prim mod
      result swap prim seq-int.push
      n 10 prim div
      digits-loop
    } ]
  if;

: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many rev:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  i len prim <
  [ locals { result i rev len } {
      len i prim - 1 prim - rev prim seq-int.at result prim seq-int.push
      i 1 prim +
      rev len
      reverse-digits
    } ]
  [ drop drop drop ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-loop
      dup prim seq-int.len
      dup 0 swap
      reverse-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime-loop
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  d d prim * n prim < prim not
  [ d n prim mod 0 prim = [ drop drop false ] [ d 1 prim + n is-prime-loop ] if ]
  [ drop drop true ]
  if;

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ 2 n is-prime-loop ]
    if
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  i n prim < prim not
  [ drop drop ]
  [ i is-prime
    [ i result prim seq-int.push ]
    [ result ]
    if
    i 1 prim +
    n
    primes-loop
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n
    primes-loop
  };
```

### task: histogram
```firth
: histogram-loop
  (forall ρ; ρ hist:Seq Int^many i:Int^many xs:Seq Int^many k:Int^many len:Int^many -- ρ result:Seq Int^many)
  i len prim <
  [ locals { hist i xs k len } {
      xs i prim seq-int.at
      dup hist swap prim seq-int.at 1 prim + swap hist swap prim seq-int.push drop
      i 1 prim +
      xs k len
      histogram-loop
    } ]
  [ drop drop drop drop ]
  if;

: init-histogram
  (forall ρ; ρ hist:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  i k prim <
  [ 0 hist prim seq-int.push i 1 prim + k init-histogram ]
  [ drop drop ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k init-histogram
    0 xs k xs prim seq-int.len
    histogram-loop
  };
```

### task: sort
```firth
: bubble-pass
  (forall ρ; ρ arr:Seq Int^many i:Int^many len:Int^many swapped:Bool^many -- ρ arr:Seq Int^many swapped:Bool^many)
  i len 1 prim - prim <
  [ locals { arr i len swapped } {
      arr i prim seq-int.at arr i 1 prim + prim seq-int.at prim <
      [ arr i 1 prim + prim seq-int.at arr i prim seq-int.at swap
        arr i prim seq-int.push drop
        arr i 1 prim + prim seq-int.push drop
        i 1 prim +
        len
        true
        bubble-pass
      ]
      [ i 1 prim + len swapped bubble-pass ]
      if
    } ]
  [ drop drop swapped ]
  if;

: bubble-sort-outer
  (forall ρ; ρ arr:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  n 1 prim <
  [ drop ]
  [ locals { arr n } {
      arr 0 n false bubble-pass
      [ arr n 1 prim - bubble-sort-outer ]
      [ drop drop drop arr ]
      if
    } ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len
    bubble-sort-outer
  };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many len:Int^many -- ρ balance:Int^many rejected:Int^many)
  i len prim <
  [ locals { balance rejected i txs len } {
      txs i prim seq-int.at
      balance swap prim + dup 0 prim <
      [ drop rejected 1 prim + i 1 prim + txs len ledger-loop ]
      [ swap drop i 1 prim + txs len ledger-loop ]
      if
    } ]
  [ drop drop drop ]
  if;

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs txs prim seq-int.len
    ledger-loop
  };
```

### task: allocate-batch
```firth
: allocate-inner-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many item-stock:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many len:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  j len prim <
  [ locals { stock-left allocated reasons j item-stock items qtys whole len } {
      items j prim seq-int.at
      dup stock-left swap prim seq-int.at
      qtys j prim seq-int.at
      dup2 prim < prim not
      [ locals { stock-left allocated reasons j item-stock items qtys whole len cur-stock qty } {
          cur-stock qty prim <
          [ qty cur-stock prim =
            [ allocated qty prim seq-int.push reasons 0 prim seq-int.push j 1 prim + item-stock items qtys whole len allocate-inner-loop ]
            [ whole j prim seq-bool.at
              [ reasons 3 prim seq-int.push allocated 0 prim seq-int.push j 1 prim + item-stock items qtys whole len allocate-inner-loop ]
              [ reasons 1 prim seq-int.push allocated cur-stock prim seq-int.push cur-stock item-stock prim - j 1 prim + items qtys whole len allocate-inner-loop ]
              if
            ]
            if
          ]
          if
        } ]
      [ allocated qty prim seq-int.push reasons 0 prim seq-int.push qty item-stock prim - j 1 prim + items qtys whole len allocate-inner-loop ]
      if
    } ]
  [ drop drop drop drop drop drop drop drop ]
  if;

: allocate-outer-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many len:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  i len prim <
  [ locals { stock-left allocated reasons i stock items qtys whole len } {
      stock i prim seq-int.at
      0 items qtys whole len
      allocate-inner-loop
      i 1 prim +
      stock items qtys whole len
      allocate-outer-loop
    } ]
  [ drop drop drop drop drop drop drop drop ]
  if;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 stock items qtys whole stock prim seq-int.len
    allocate-outer-loop
  };
```
