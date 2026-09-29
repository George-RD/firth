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
      xs i prim seq-int.at acc prim +
      i 1 prim +
      xs swap swap sum-loop
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
      xs i prim seq-int.at
      locals { xs i max-val elem } {
        elem max-val prim <
        [ max-val ]
        [ elem ]
        if
        i 1 prim +
        xs swap swap max-loop
      }
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
      xs i prim seq-int.at
      locals { xs i cnt k elem } {
        elem k prim <
        [ cnt 1 prim + ]
        [ cnt ]
        if
        i 1 prim +
        xs swap swap k count-loop
      }
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
      xs i prim seq-int.at
      locals { xs i x elem } {
        elem x prim =
        [ i ]
        [
          i 1 prim +
          xs swap swap x index-loop
        ]
        if
      }
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
      xs i prim seq-int.at
      locals { result xs i elem } {
        result elem prim seq-int.push
        i 1 prim +
        xs swap swap reverse-loop
      }
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
      locals { result xs i new-sum } {
        result new-sum prim seq-int.push
        i 1 prim +
        xs swap swap new-sum prefix-loop
      }
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
      xs i prim seq-int.at
      locals { result xs i elem } {
        elem 0 prim <
        [ result ]
        [ result elem prim seq-int.push ]
        if
        i 1 prim +
        xs swap swap keep-loop
      }
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
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      locals { xs i curr next } {
        curr next prim < prim not
        [
          i 1 prim +
          xs swap sorted-loop
        ]
        [ false ]
        if
      }
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
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      acc prim +
      i 1 prim +
      xs ys swap swap dot-loop
    ]
    [ acc ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { flags 0 all-loop };

: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        i 1 prim +
        flags swap all-loop
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 1 longest-loop };

: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-len:Int^many run-len:Int^many -- ρ result:Int^many)
  locals { xs i max-len run-len } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      locals { xs i max-len run-len curr next } {
        curr next prim =
        [
          run-len 1 prim +
          locals { xs i max-len new-run } {
            new-run max-len prim <
            [ new-run ]
            [ max-len ]
            if
            i 1 prim +
            xs swap swap swap longest-loop
          }
        ]
        [
          run-len max-len prim <
          [ run-len ]
          [ max-len ]
          if
          i 1 prim +
          xs swap swap 1 longest-loop
        ]
        if
      }
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
      xs i prim seq-int.at
      locals { xs i target xi } {
        target xi prim -
        xs swap 0 find-match
      }
    ]
    [ false ]
    if
  };

: find-match
  (forall ρ; ρ xs:Seq Int^many needed:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs needed j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      locals { xs needed j elem } {
        elem needed prim =
        [ true ]
        [
          j 1 prim +
          xs swap needed find-match
        ]
        if
      }
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
      xs i prim seq-int.at
      locals { xs i cnt elem } {
        xs elem 0 is-already-seen
        [
          i 1 prim +
          xs swap cnt distinct-loop
        ]
        [
          cnt 1 prim +
          i 1 prim +
          xs swap swap distinct-loop
        ]
        if
      }
    ]
    [ cnt ]
    if
  };

: is-already-seen
  (forall ρ; ρ xs:Seq Int^many elem:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs elem j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      locals { xs elem j x } {
        x elem prim =
        [ true ]
        [
          j 1 prim +
          xs swap elem is-already-seen
        ]
        if
      }
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
        xs i prim seq-int.at
        ys j prim seq-int.at
        locals { result xs ys i j xi yj } {
          xi yj prim <
          [
            result xi prim seq-int.push
            i 1 prim +
            xs ys swap swap j merge-loop
          ]
          [
            result yj prim seq-int.push
            j 1 prim +
            xs ys swap i swap merge-loop
          ]
          if
        }
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        xs ys swap j merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        j 1 prim +
        xs ys result i swap merge-loop
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
  locals { n } { n collect-digits prim seq-int.empty reverse-digits };

: collect-digits
  (forall ρ; ρ n:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { n xs } {
    n 0 prim =
    [
      xs prim seq-int.len 0 prim =
      [ prim seq-int.empty 0 prim seq-int.push ]
      [ xs ]
      if
    ]
    [
      n 10 prim mod
      xs swap prim seq-int.push
      n 10 prim div
      swap collect-digits
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs result } {
    xs prim seq-int.len 0 prim =
    [ result ]
    [
      xs 0 prim seq-int.at
      result swap prim seq-int.push
      xs 1 xs prim seq-int.len prim seq-int.at prim seq-int.set
      swap reverse-digits
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
    i n prim < prim not
    [ primes ]
    [
      primes i is-prime
      [
        primes i prim seq-int.push
        i 1 prim +
        swap n sieve-loop
      ]
      [
        i 1 prim +
        primes swap n sieve-loop
      ]
      if
    ]
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
      locals { j primes candidate div } {
        div div prim * candidate prim <
        [
          candidate div prim mod 0 prim =
          [ false ]
          [
            j 1 prim +
            primes swap candidate check-divisor
          ]
          if
        ]
        [ true ]
        if
      }
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
      swap init-histogram
    ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { result xs i val } {
        result val prim seq-int.at 1 prim + prim seq-int.set
        i 1 prim +
        xs swap result histogram-loop
      }
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
      xs j prim seq-int.at
      xs j 1 prim - prim seq-int.at
      locals { xs i j curr prev } {
        curr prev prim <
        [
          xs j 1 prim - curr prim seq-int.set
          xs j prev prim seq-int.set
        ]
        [ xs ]
        if
        j 1 prim +
        xs i swap sort-inner
      }
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
      txs i prim seq-int.at
      locals { balance txs i rejected tx } {
        balance tx prim + 0 prim <
        [
          i 1 prim +
          txs swap balance swap rejected 1 prim + ledger-loop
        ]
        [
          balance tx prim +
          i 1 prim +
          txs swap swap rejected ledger-loop
        ]
        if
      }
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
      items j prim seq-int.at
      locals { stock allocated reasons j items qtys whole item } {
        stock item prim seq-int.at
        locals { stock allocated reasons j items qtys whole item curr-stock } {
          qtys j prim seq-int.at
          locals { stock allocated reasons j items qtys whole item curr-stock qty } {
            qty curr-stock prim <
            [
              stock item qty prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
              j 1 prim +
              swap swap items qtys whole allocate-batch-loop
            ]
            [
              curr-stock 0 prim =
              [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                j 1 prim +
                stock swap items qtys whole allocate-batch-loop
              ]
              [
                whole j prim seq-bool.at
                [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  j 1 prim +
                  stock swap items qtys whole allocate-batch-loop
                ]
                [
                  stock item 0 prim seq-int.set
                  allocated curr-stock prim seq-int.push
                  reasons 1 prim seq-int.push
                  j 1 prim +
                  swap swap items qtys whole allocate-batch-loop
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };
```
