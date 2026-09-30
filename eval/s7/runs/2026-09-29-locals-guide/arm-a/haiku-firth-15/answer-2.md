### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      xs i prim seq-int.at acc prim +
      sum-loop
    ]
    [ acc ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max-val prim <
      [ xs i 1 prim + max-val max-loop ]
      [ xs i 1 prim + xs i prim seq-int.at max-loop ]
      if
    ]
    [ max-val ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs 0 0 k count-loop };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs i cnt k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [ xs i 1 prim + cnt 1 prim + k count-loop ]
      [ xs i 1 prim + cnt k count-loop ]
      if
    ]
    [ cnt ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { xs 0 x index-loop };

: index-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs i x } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [ i ]
      [ xs i 1 prim + x index-loop ]
      if
    ]
    [ -1 ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      result
      xs i prim seq-int.at prim seq-int.push
      xs
      i 1 prim +
      swap swap
      reverse-loop
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Seq Int^many)
  locals { result xs i sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      result
      swap prim seq-int.push
      xs
      i 1 prim +
      swap swap
      prefix-loop
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [ result xs i 1 prim + keep-loop ]
      [ result xs i prim seq-int.at prim seq-int.push xs i 1 prim + keep-loop ]
      if
    ]
    [ result ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs 0 sorted-loop };

: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not
      [ xs i 1 prim + sorted-loop ]
      [ false ]
      if
    ]
    [ true ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [
      xs
      ys
      i 1 prim +
      xs i prim seq-int.at ys i prim seq-int.at prim * acc prim +
      dot-loop
    ]
    [ acc ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 1 longest-loop };

: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-len:Int^many run-len:Int^many -- ρ result:Int^many)
  locals { xs i max-len run-len } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
      [ xs i 1 prim + max-len run-len 1 prim + longest-loop ]
      [ run-len max-len prim < [ run-len ] [ max-len ] if xs i 1 prim + 1 longest-loop ]
      if
    ]
    [ run-len max-len prim < [ run-len ] [ max-len ] if ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs 0 target find-pair };

: find-pair
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs i target } {
    i xs prim seq-int.len prim <
    [
      target xs i prim seq-int.at prim -
      xs
      swap 0 find-match
    ]
    [ false ]
    if
  };

: find-match
  (forall ρ; ρ needed:Int^many xs:Seq Int^many j:Int^many -- ρ result:Bool^many)
  locals { needed xs j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at needed prim =
      [ true ]
      [ needed xs j 1 prim + find-match ]
      if
    ]
    [ false ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs i cnt } {
    i xs prim seq-int.len prim <
    [
      xs xs i prim seq-int.at 0 is-already-seen prim not
      [ xs i 1 prim + cnt 1 prim + distinct-loop ]
      [ xs i 1 prim + cnt distinct-loop ]
      if
    ]
    [ cnt ]
    if
  };

: is-already-seen
  (forall ρ; ρ xs:Seq Int^many elem:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs elem j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at elem prim =
      [ true ]
      [ xs elem j 1 prim + is-already-seen ]
      if
    ]
    [ false ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [ result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop ]
        [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop ]
        if
      ]
      [
        result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
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
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty n collect-digits };

: collect-digits
  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { xs n } {
    n 0 prim =
    [
      xs prim seq-int.len 0 prim =
      [ prim seq-int.empty 0 prim seq-int.push ]
      [ xs ]
      if
    ]
    [
      xs n 10 prim mod prim seq-int.push
      n 10 prim div
      swap collect-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n sieve-loop };

: sieve-loop
  (forall ρ; ρ primes:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { primes i n } {
    i n prim <
    [
      primes i is-prime
      [ primes i prim seq-int.push i 1 prim + n sieve-loop ]
      [ primes i 1 prim + n sieve-loop ]
      if
    ]
    [ primes ]
    if
  };

: is-prime
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { primes candidate } { 0 primes candidate check-divisor };

: check-divisor
  (forall ρ; ρ j:Int^many primes:Seq Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { j primes candidate } {
    j primes prim seq-int.len prim <
    [
      primes j prim seq-int.at
      [ primes j prim seq-int.at primes j prim seq-int.at prim * candidate prim < ]
      [ [ false ] [ j 1 prim + primes swap candidate check-divisor ] candidate primes j prim seq-int.at prim mod 0 prim = if ]
      if
    ]
    [ true ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty k init-histogram xs 0 histogram-loop };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result k } {
    k 0 prim =
    [ result ]
    [
      result 0 prim seq-int.push
      k 1 prim -
      result swap init-histogram
    ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      xs i 1 prim +
      swap swap
      histogram-loop
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 sort-outer };

: sort-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i i sort-inner
    ]
    [ xs ]
    if
  };

: sort-inner
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs i j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at xs j 1 prim - prim seq-int.at prim <
      [
        xs j 1 prim - xs j prim seq-int.at prim seq-int.set
        xs j xs j 1 prim - prim seq-int.at prim seq-int.set
        xs i j 1 prim + sort-inner
      ]
      [ xs i j 1 prim + sort-inner ]
      if
    ]
    [
      i 1 prim +
      xs swap sort-outer
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [ balance txs i 1 prim + rejected 1 prim + ledger-loop ]
      [ balance txs i prim seq-int.at prim + txs i 1 prim + swap swap rejected ledger-loop ]
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
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-batch-loop };

: allocate-batch-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim <
    [
      stock items j prim seq-int.at prim seq-int.at
      qtys j prim seq-int.at
      prim <
      [
        stock items j prim seq-int.at qtys j prim seq-int.at prim seq-int.set
        allocated qtys j prim seq-int.at prim seq-int.push
        reasons 0 prim seq-int.push
        stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
      ]
      [
        stock items j prim seq-int.at prim seq-int.at 0 prim =
        [
          allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
        ]
        [
          whole j prim seq-bool.at
          [
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
          ]
          [
            stock items j prim seq-int.at 0 prim seq-int.set
            allocated stock items j prim seq-int.at prim seq-int.at prim seq-int.push
            reasons 1 prim seq-int.push
            stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };
```
