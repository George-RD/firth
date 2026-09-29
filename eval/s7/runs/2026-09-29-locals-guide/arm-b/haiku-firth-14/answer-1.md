### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs i sum } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      sum xs i prim seq-int.at prim +
      sum-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-loop };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      xs i prim seq-int.at max
      max xs i prim seq-int.at prim <
      [ xs i prim seq-int.at ]
      [ max ]
      if
      max-loop
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-loop };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim <
    [
      xs k
      i 1 prim +
      xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      count-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop };
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
        xs x
        i 1 prim +
        index-loop
      ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-loop };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at result prim seq-int.push
      i 1 prim -
      reverse-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      locals { new-sum } {
        xs
        i 1 prim +
        new-sum
        result new-sum prim seq-int.push
        prefix-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };
```

### task: keep-positive
```firth
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        xs
        i 1 prim +
        0 elem prim <
        [ result elem prim seq-int.push ]
        [ result ]
        if
        keep-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-loop };
```

### task: is-sorted
```firth
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [
        i 1 prim +
        sorted-loop
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sorted-loop };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim <
    [
      xs ys
      i 1 prim +
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };
```

### task: all-true
```firth
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at prim not
      [
        false
      ]
      [
        i 1 prim +
        all-loop
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-loop };
```

### task: longest-run
```firth
: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many prev:Int^many current:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i prev current max } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        elem prev prim =
        [
          xs
          i 1 prim +
          prev
          current 1 prim +
          max
          longest-run-loop
        ]
        [
          xs
          i 1 prim +
          elem
          1
          current max prim <
          [ max ]
          [ current ]
          if
          longest-run-loop
        ]
        if
      }
    ]
    [
      current max prim <
      [ max ]
      [ current ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 1 xs 0 prim seq-int.at 1 0 longest-run-loop ]
    if
  };
```

### task: has-pair-sum
```firth
: has-pair-loop2
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true
      ]
      [
        xs target i
        j 1 prim +
        has-pair-loop2
      ]
      if
    ]
    [ false ]
    if
  };

: has-pair-loop1
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs target i
      i 1 prim +
      has-pair-loop2
      [ true ]
      [
        xs target
        i 1 prim +
        has-pair-loop1
      ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 has-pair-loop1 };
```

### task: count-distinct
```firth
: is-member-loop
  (forall ρ; ρ seen:Seq Int^many x:Int^many i:Int^many -- ρ result:Bool^many)
  locals { seen x i } {
    i seen prim seq-int.len prim <
    [
      seen i prim seq-int.at x prim =
      [
        true
      ]
      [
        seen x
        i 1 prim +
        is-member-loop
      ]
      if
    ]
    [ false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        seen elem 0 is-member-loop
        [
          xs
          i 1 prim +
          seen
          count-distinct-loop
        ]
        [
          xs
          i 1 prim +
          seen elem prim seq-int.push
          count-distinct-loop
        ]
        if
      }
    ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty count-distinct-loop };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim <
    [ true ] [ false ] if
    prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        xs ys
        i 1 prim +
        j
        result xs i prim seq-int.at prim seq-int.push
        merge-loop
      ]
      [
        xs ys
        i
        j 1 prim +
        result ys j prim seq-int.at prim seq-int.push
        merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs ys
        i 1 prim +
        j
        result xs i prim seq-int.at prim seq-int.push
        merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          xs ys
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
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };
```

### task: digits
```firth
: reverse-digits-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at result prim seq-int.push
      i 1 prim -
      reverse-digits-loop
    ]
    if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 10 prim < prim not
    [
      n 10 prim mod
      locals { digit } {
        n 10 prim div
        result digit prim seq-int.push
        digits-loop
      }
    ]
    [
      result n prim seq-int.push
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n prim seq-int.empty digits-loop
    locals { res } {
      res prim seq-int.len 1 prim -
      prim seq-int.empty
      reverse-digits-loop
    }
  };
```

### task: primes-up-to
```firth
: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim < prim not
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        d 1 prim +
        is-prime-loop
      ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 is-prime-loop ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    i n prim < prim not
    [
      result
    ]
    [
      i is-prime
      [
        n
        i 1 prim +
        result i prim seq-int.push
        primes-loop
      ]
      [
        n
        i 1 prim +
        result
        primes-loop
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-loop };
```

### task: histogram
```firth
: histogram-build-loop
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i result } {
    i k prim <
    [
      k
      i 1 prim +
      result 0 prim seq-int.push
      histogram-build-loop
    ]
    [
      result
    ]
    if
  };

: histogram-count-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        xs
        result val prim seq-int.at 1 prim + result val prim seq-int.set
        i 1 prim +
        histogram-count-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty histogram-build-loop
    locals { counts } {
      xs counts 0 histogram-count-loop
    }
  };
```

### task: sort
```firth
: insert-sorted-loop
  (forall ρ; ρ sorted:Seq Int^many x:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted x i } {
    i 0 prim <
    [
      sorted x prim seq-int.push
    ]
    [
      sorted i prim seq-int.at x prim <
      [
        sorted i prim seq-int.at
        locally { elem } {
          sorted elem x prim seq-int.set
          sorted elem
          i 1 prim -
          insert-sorted-loop
        }
      ]
      [
        sorted x i 1 prim + prim seq-int.set
      ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs
      xs i prim seq-int.at
      i 1 prim -
      insert-sorted-loop
      locals { new-sorted } {
        xs
        i 1 prim +
        result new-sorted prim seq-int.push
        sort-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim <
        [
          txs
          i 1 prim +
          balance
          rejected 1 prim +
          ledger-loop
        ]
        [
          txs
          i 1 prim +
          balance tx prim +
          rejected
          ledger-loop
        ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs 0 start 0 ledger-loop };
```

### task: allocate-batch
```firth
: allocate-one-order
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item qty whole } {
    stock item prim seq-int.at
    locals { available } {
      qty available prim <
      [ prim not ]
      [ false ]
      if
      [
        stock qty item prim seq-int.set
        qty 0
      ]
      [
        available 0 prim =
        [
          stock 0 2
        ]
        [
          whole
          [
            stock 0 3
          ]
          [
            stock available item prim seq-int.set
            available 1
          ]
          if
        ]
        if
      ]
      if
    }
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many -- ρ stock:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { stock items qtys whole i allocated-result reasons-result } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      allocate-one-order
      locals { reason allocated new-stock } {
        new-stock
        i 1 prim +
        allocated-result allocated prim seq-int.push
        reasons-result reason prim seq-int.push
        allocate-loop
      }
    ]
    [ stock allocated-result reasons-result ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty
    allocate-loop
  };
```

