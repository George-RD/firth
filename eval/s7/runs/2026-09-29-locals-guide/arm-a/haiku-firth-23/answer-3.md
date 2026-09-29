### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs
      i 1 prim +
      acc i xs prim seq-int.at prim +
      sum-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-loop };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at max prim <
      [ xs
        i 1 prim +
        i xs prim seq-int.at
        max-loop
      ]
      [ xs
        i 1 prim +
        max
        max-loop
      ]
      if
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
    [ i xs prim seq-int.at k prim <
      [ xs
        k
        i 1 prim +
        count 1 prim +
        count-loop
      ]
      [ xs
        k
        i 1 prim +
        count
        count-loop
      ]
      if
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
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many result:Int^many -- ρ index:Int^many)
  locals { xs x i result } {
    result 0 prim <
    [ result ]
    [ i xs prim seq-int.len prim <
      [ i xs prim seq-int.at x prim =
        [ i ]
        [ result ]
        if
        xs
        x
        i 1 prim +
        index-loop
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 -1 index-loop };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [ xs
      i 1 prim -
      result xs i prim seq-int.at prim seq-int.push
      reverse-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [ sum i xs prim seq-int.at prim +
      xs
      i 1 prim +
      result sum i xs prim seq-int.at prim + prim seq-int.push
      prefix-loop
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at 0 prim <
      [ xs
        i 1 prim +
        result i xs prim seq-int.at prim seq-int.push
        keep-loop
      ]
      [ xs
        i 1 prim +
        result
        keep-loop
      ]
      if
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
: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Bool^many -- ρ result:Bool^many)
  locals { xs i sorted } {
    sorted prim not
    [ false ]
    [ i xs prim seq-int.len prim <
      [ i xs prim seq-int.at i 1 prim + xs prim seq-int.at prim <
        [ xs
          i 1 prim +
          false
          is-sorted-loop
        ]
        [ false ]
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
    [ xs 0 true is-sorted-loop ]
    if
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [ xs
      ys
      i 1 prim +
      acc i xs prim seq-int.at i ys prim seq-int.at prim * prim +
      dot-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };
```

### task: all-true
```firth
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many result:Bool^many -- ρ all:Bool^many)
  locals { flags i result } {
    result prim not
    [ false ]
    [ i flags prim seq-bool.len prim <
      [ i flags prim seq-bool.at
        [ flags
          i 1 prim +
          true
          all-loop
        ]
        [ false ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 true all-loop };
```

### task: longest-run
```firth
: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxlen:Int^many current:Int^many -- ρ length:Int^many)
  locals { xs i maxlen current } {
    i xs prim seq-int.len prim <
    [ i 0 prim <
      [ maxlen ]
      [ i xs prim seq-int.at i 1 prim - xs prim seq-int.at prim =
        [ xs
          i 1 prim +
          maxlen
          current 1 prim +
          longest-loop
        ]
        [ xs
          i 1 prim +
          maxlen current prim <
          [ current ]
          [ maxlen ]
          if
          1
          longest-loop
        ]
        if
      ]
    ]
    [ maxlen current prim <
      [ current ]
      [ maxlen ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 1 0 0 longest-loop ]
    if
  };
```

### task: has-pair-sum
```firth
: inner-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many target:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs i j target found } {
    found
    [ true ]
    [ j xs prim seq-int.len prim <
      [ i xs prim seq-int.at j xs prim seq-int.at prim + target prim =
        [ true ]
        [ xs
          i
          j 1 prim +
          target
          false
          inner-loop
        ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target i found } {
    found
    [ true ]
    [ i xs prim seq-int.len prim <
      [ xs
        target
        i 1 prim +
        false
        i 1 prim +
        inner-loop
        outer-loop
      ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 false outer-loop };
```

### task: count-distinct
```firth
: inner-distinct
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many val:Int^many j:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs seen val j found } {
    found
    [ true ]
    [ j seen prim seq-int.len prim <
      [ j seen prim seq-int.at val prim =
        [ true ]
        [ xs
          seen
          val
          j 1 prim +
          false
          inner-distinct
        ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: outer-distinct
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs seen i } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at false 0 inner-distinct
      [ xs
        seen i xs prim seq-int.at prim seq-int.push
        i 1 prim +
        outer-distinct
      ]
      [ xs
        seen
        i 1 prim +
        outer-distinct
      ]
      if
    ]
    [ seen ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs prim seq-int.empty 0 outer-distinct prim seq-int.len };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and prim not
    [ i xs prim seq-int.len prim =
      [ j ys prim seq-int.len prim <
        [ xs
          ys
          i
          j 1 prim +
          result j ys prim seq-int.at prim seq-int.push
          merge-loop
        ]
        [ result ]
        if
      ]
      [ xs
        ys
        i 1 prim +
        j
        result i xs prim seq-int.at prim seq-int.push
        merge-loop
      ]
      if
    ]
    [ i xs prim seq-int.at j ys prim seq-int.at prim <
      [ xs
        ys
        i 1 prim +
        j
        result i xs prim seq-int.at prim seq-int.push
        merge-loop
      ]
      [ xs
        ys
        i
        j 1 prim +
        result j ys prim seq-int.at prim seq-int.push
        merge-loop
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
: digits-loop
  (forall ρ; ρ x:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { x result } {
    x 0 prim <
    [ result ]
    [ x 10 prim div
      result x 10 prim mod prim seq-int.push
      digits-loop
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ n prim seq-int.empty digits-loop ]
    if
  };
```

### task: primes-up-to
```firth
: check-divisible
  (forall ρ; ρ primes:Seq Int^many p:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { primes p i found } {
    found
    [ true ]
    [ i primes prim seq-int.len prim <
      [ i primes prim seq-int.at p prim mod 0 prim =
        [ true ]
        [ primes
          p
          i 1 prim +
          false
          check-divisible
        ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many primes:Seq Int^many p:Int^many -- ρ result:Seq Int^many)
  locals { n primes p } {
    p n prim <
    [ false 0 check-divisible
      [ n
        primes p prim seq-int.push
        p 1 prim +
        primes-loop
      ]
      [ n
        primes
        p 1 prim +
        primes-loop
      ]
      if
    ]
    [ primes ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n prim seq-int.empty 2 primes-loop };
```

### task: histogram
```firth
: hist-loop
  (forall ρ; ρ k:Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { k counts i } {
    i k prim <
    [ k
      counts 0 prim seq-int.push
      i 1 prim +
      hist-loop
    ]
    [ counts ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs counts i } {
    i xs prim seq-int.len prim <
    [ xs
      counts i xs prim seq-int.at i xs prim seq-int.at counts prim seq-int.at 1 prim + prim seq-int.set
      i 1 prim +
      count-loop
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { xs k prim seq-int.empty 0 hist-loop count-loop };
```

### task: sort
```firth
: inner-sort
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many -- ρ sorted:Seq Int^many)
  locals { result i j } {
    j 0 prim <
    [ result ]
    [ j result prim seq-int.at j 1 prim + result prim seq-int.at prim <
      [ result
        i
        j 1 prim -
        result j 1 prim + result prim seq-int.at j result prim seq-int.at prim seq-int.set prim seq-int.set
        inner-sort
      ]
      [ result
        i
        j 1 prim -
        inner-sort
      ]
      if
    ]
    if
  };

: outer-sort
  (forall ρ; ρ result:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result i } {
    i result prim seq-int.len prim <
    [ result
      i 1 prim -
      i 1 prim -
      inner-sort
      i 1 prim +
      outer-sort
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 outer-sort };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { txs balance rejected i } {
    i txs prim seq-int.len prim <
    [ balance i txs prim seq-int.at prim + 0 prim <
      [ txs
        balance
        rejected 1 prim +
        i 1 prim +
        ledger-loop
      ]
      [ txs
        balance i txs prim seq-int.at prim +
        rejected
        i 1 prim +
        ledger-loop
      ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs start 0 0 ledger-loop };
```

### task: allocate-batch
```firth
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    j qtys prim seq-int.len prim <
    [ j items prim seq-int.at j qtys prim seq-int.at stock j items prim seq-int.at prim seq-int.at
      locals { itemidx qty currstock } {
        qty currstock prim <
        [ stock allocated reasons items qtys whole j 1 prim + stock itemidx qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push allocate-loop ]
        [ currstock 0 prim =
          [ stock allocated reasons items qtys whole j 1 prim + stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push allocate-loop ]
          [ j whole prim seq-bool.at
            [ stock allocated reasons items qtys whole j 1 prim + stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push allocate-loop ]
            [ stock allocated reasons items qtys whole j 1 prim + stock itemidx 0 prim seq-int.set allocated currstock prim seq-int.push reasons 1 prim seq-int.push allocate-loop ]
            if
          ]
          if
        ]
        if
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole prim seq-int.empty prim seq-int.empty 0 allocate-loop };
```
