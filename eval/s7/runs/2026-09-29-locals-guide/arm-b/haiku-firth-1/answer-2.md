### task: seq-sum
```firth
: main
  (xs:Seq Int^many -- result:Int^many)
  locals { xs } { 0 0 xs sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ res:Int^many)
  locals { acc i xs } {
    i xs prim seq-int.len prim =
    [ acc ]
    [ acc xs i prim seq-int.at prim + i 1 prim + xs sum-loop ]
    if
  };
```

### task: seq-max
```firth
: main
  (xs:Seq Int^many -- largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 xs max-loop };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim =
    [ max ]
    [
      xs i prim seq-int.at max prim <
      [ max ]
      [ xs i prim seq-int.at ]
      if
      i 1 prim + xs max-loop
    ]
    if
  };
```

### task: count-below
```firth
: main
  (xs:Seq Int^many k:Int^many -- count:Int^many)
  locals { xs k } { 0 0 xs k count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc i xs k } {
    i xs prim seq-int.len prim =
    [ acc ]
    [
      xs i prim seq-int.at k prim <
      [ acc 1 prim + ]
      [ acc ]
      if
      i 1 prim + xs k count-loop
    ]
    if
  };
```

### task: index-of
```firth
: main
  (xs:Seq Int^many x:Int^many -- index:Int^many)
  locals { xs x } { 0 xs x index-loop };

: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim =
    [ -1 ]
    [
      xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs x index-loop ]
      if
    ]
    if
  };
```

### task: reverse
```firth
: main
  (xs:Seq Int^many -- reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      result xs i prim seq-int.at prim seq-int.push
      i 1 prim + xs reverse-loop
    ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (xs:Seq Int^many -- sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many acc:Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result acc i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      acc xs i prim seq-int.at prim + locals { sum } {
        result sum prim seq-int.push
        sum i 1 prim + xs prefix-loop
      }
    ]
    if
  };
```

### task: keep-positive
```firth
: main
  (xs:Seq Int^many -- positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      xs i prim seq-int.at 0 prim <
      [ result i 1 prim + xs keep-loop ]
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs keep-loop ]
      if
    ]
    if
  };
```

### task: is-sorted
```firth
: main
  (xs:Seq Int^many -- sorted:Bool^many)
  locals { xs } { 1 0 xs sorted-loop };

: sorted-loop
  (forall ρ; ρ flag:Bool^many i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { flag i xs } {
    flag prim not
    [ false ]
    [
      i 1 prim + xs prim seq-int.len prim =
      [ true ]
      [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
        [ flag i 1 prim + xs sorted-loop ]
        [ false ]
        if
      ]
      if
    ]
    if
  };
```

### task: dot
```firth
: main
  (xs:Seq Int^many ys:Seq Int^many -- product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs ys } {
    i xs prim seq-int.len prim =
    [ acc ]
    [
      acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      i 1 prim + xs ys dot-loop
    ]
    if
  };
```

### task: all-true
```firth
: main
  (flags:Seq Bool^many -- all:Bool^many)
  locals { flags } { 1 0 flags all-loop };

: all-loop
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ res:Bool^many)
  locals { result i flags } {
    result prim not
    [ false ]
    [
      i flags prim seq-bool.len prim =
      [ true ]
      [
        flags i prim seq-bool.at
        [ result i 1 prim + flags all-loop ]
        [ false ]
        if
      ]
      if
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (xs:Seq Int^many -- length:Int^many)
  locals { xs } { 0 0 1 xs run-loop };

: run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len prim =
    [
      max-run current-run prim <
      [ current-run ]
      [ max-run ]
      if
    ]
    [
      i 0 prim =
      [ max-run current-run i 1 prim + xs run-loop ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          max-run current-run 1 prim + prim <
          [ current-run 1 prim + i 1 prim + xs run-loop ]
          [ max-run i 1 prim + xs run-loop ]
          if
        ]
        [
          max-run current-run prim <
          [ current-run ]
          [ max-run ]
          if
          1 i 1 prim + xs run-loop
        ]
        if
      ]
      if
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (xs:Seq Int^many target:Int^many -- found:Bool^many)
  locals { xs target } { 0 xs target search-loop };

: search-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim =
    [ false ]
    [
      i 1 prim + xs target inner-search
      [ true ]
      [ i 1 prim + xs target search-loop ]
      if
    ]
    if
  };

: inner-search
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim =
    [ false ]
    [
      xs j prim seq-int.at xs 0 prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + xs target inner-search ]
      if
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (xs:Seq Int^many -- count:Int^many)
  locals { xs } { prim seq-int.empty xs distinct-loop };

: distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim =
    [ seen prim seq-int.len ]
    [
      xs i prim seq-int.at seen contains
      [ seen i 1 prim + xs distinct-loop ]
      [ seen xs i prim seq-int.at prim seq-int.push i 1 prim + xs distinct-loop ]
      if
    ]
    if
  };

: contains
  (val:Int^many seq:Seq Int^many -- found:Bool^many)
  locals { val seq } { 0 seq val check-contains };

: check-contains
  (forall ρ; ρ i:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { i seq val } {
    i seq prim seq-int.len prim =
    [ false ]
    [
      seq i prim seq-int.at val prim =
      [ true ]
      [ i 1 prim + seq val check-contains ]
      if
    ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (xs:Seq Int^many ys:Seq Int^many -- merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim = j ys prim seq-int.len prim = prim and
    [ result ]
    [
      i xs prim seq-int.len prim =
      [
        result ys j prim seq-int.at prim seq-int.push
        i j 1 prim + xs ys merge-loop
      ]
      [
        j ys prim seq-int.len prim =
        [
          result xs i prim seq-int.at prim seq-int.push
          i 1 prim + j xs ys merge-loop
        ]
        [
          xs i prim seq-int.at ys j prim seq-int.at prim <
          [
            result xs i prim seq-int.at prim seq-int.push
            i 1 prim + j xs ys merge-loop
          ]
          [
            result ys j prim seq-int.at prim seq-int.push
            i j 1 prim + xs ys merge-loop
          ]
          if
        ]
        if
      ]
      if
    ]
    if
  };
```

### task: digits
```firth
: main
  (n:Int^many -- digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digit-build ]
    if
  };

: digit-build
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div digit-build
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (n:Int^many -- primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n prime-loop };

: prime-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not
    [ result ]
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
        candidate 1 prim + n prime-loop
      ]
      [
        result
        candidate 1 prim + n prime-loop
      ]
      if
    ]
    if
  };

: is-prime
  (num:Int^many -- result:Bool^many)
  locals { num } {
    num 2 prim <
    [ false ]
    [ 2 num check-prime ]
    if
  };

: check-prime
  (forall ρ; ρ divisor:Int^many num:Int^many -- ρ result:Bool^many)
  locals { divisor num } {
    divisor divisor prim * num prim < prim not
    [ true ]
    [
      num divisor prim mod 0 prim =
      [ false ]
      [ divisor 1 prim + num check-prime ]
      if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (xs:Seq Int^many k:Int^many -- counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty k histogram-init xs histogram-fill };

: histogram-init
  (forall ρ; ρ i:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i prim seq-int.len k prim =
    [ i ]
    [ i 0 prim seq-int.push k histogram-init ]
    if
  };

: histogram-fill
  (forall ρ; ρ counts:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts idx xs } {
    idx xs prim seq-int.len prim =
    [ counts ]
    [
      counts xs idx prim seq-int.at locals { bin } { bin counts bin prim seq-int.at 1 prim + prim seq-int.set }
      idx 1 prim + xs histogram-fill
    ]
    if
  };
```

### task: sort
```firth
: main
  (xs:Seq Int^many -- sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs sort-insert };

: sort-insert
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      result xs i prim seq-int.at insert-val
      i 1 prim + xs sort-insert
    ]
    if
  };

: insert-val
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ res:Seq Int^many)
  locals { result val } { 0 result val insert-loop };

: insert-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many val:Int^many -- ρ res:Seq Int^many)
  locals { i result val } {
    i result prim seq-int.len prim =
    [ result val prim seq-int.push ]
    [
      val result i prim seq-int.at prim <
      [ result val prim seq-int.push i result shift-loop ]
      [ i 1 prim + result val insert-loop ]
      if
    ]
    if
  };

: shift-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { result i } {
    i 0 prim =
    [ result ]
    [ result i 1 prim - prim seq-int.at result i prim seq-int.set i 1 prim - shift-loop ]
    if
  };
```

### task: ledger
```firth
: main
  (start:Int^many txs:Seq Int^many -- balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ b:Int^many r:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim =
    [ balance rejected ]
    [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim <
        [ balance rejected 1 prim + ]
        [ balance tx prim + rejected ]
        if
      }
      i 1 prim + txs ledger-loop
    ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-loop };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock allocated reasons order items qtys whole } {
    order items prim seq-int.len prim =
    [ stock allocated reasons ]
    [
      items order prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { r } {
          qtys order prim seq-int.at locals { q } {
            q r prim < prim not
            [
              stock item q prim seq-int.set
              allocated q prim seq-int.push
              reasons 0 prim seq-int.push
            ]
            [
              r 0 prim =
              [
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ]
              [
                whole order prim seq-bool.at
                [
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ]
                [
                  stock item 0 prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
      order 1 prim + items qtys whole allocate-loop
    ]
    if
  };
```
