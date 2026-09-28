### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs seq-sum-loop };

: seq-sum-loop
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc idx xs } {
    idx xs prim seq-int.len prim =
    [ acc ]
    [ xs idx prim seq-int.at acc prim + idx 1 prim + xs seq-sum-loop ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs seq-max-loop };

: seq-max-loop
  (forall ρ; ρ max:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max idx xs } {
    idx xs prim seq-int.len prim =
    [ max ]
    [
      max xs idx prim seq-int.at prim <
      [ xs idx prim seq-int.at ] [ max ] if
      idx 1 prim +
      xs
      seq-max-loop
    ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k seq-count-loop };

: seq-count-loop
  (forall ρ; ρ cnt:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { cnt idx xs k } {
    idx xs prim seq-int.len prim =
    [ cnt ]
    [
      xs idx prim seq-int.at k prim <
      [ cnt 1 prim + ] [ cnt ] if
      idx 1 prim +
      xs k
      seq-count-loop
    ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x seq-index-loop };

: seq-index-loop
  (forall ρ; ρ idx:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx xs x } {
    idx xs prim seq-int.len prim =
    [ -1 ]
    [
      xs idx prim seq-int.at x prim =
      [ idx ] [ idx 1 prim + xs x seq-index-loop ] if
    ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    xs
    reverse-loop
  };

: reverse-loop
  (forall ρ; ρ idx:Int^many result:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx result xs } {
    idx 0 prim <
    [ result ]
    [
      xs idx prim seq-int.at result prim seq-int.push
      idx 1 prim -
      xs
      reverse-loop
    ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 0 prim seq-int.empty xs prefix-loop };

: prefix-loop
  (forall ρ; ρ sum:Int^many idx:Int^many result:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { sum idx result xs } {
    idx xs prim seq-int.len prim =
    [ result ]
    [
      xs idx prim seq-int.at sum prim + dup result prim seq-int.push
      idx 1 prim +
      xs
      prefix-loop
    ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-positive-loop };

: keep-positive-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx xs } {
    idx xs prim seq-int.len prim =
    [ result ]
    [
      xs idx prim seq-int.at dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ] if
      idx 1 prim +
      xs
      keep-positive-loop
    ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 xs is-sorted-loop ] if
  };

: is-sorted-loop
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { idx xs } {
    idx xs prim seq-int.len 1 prim - prim =
    [ true ]
    [
      xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
      [ false ]
      [ idx 1 prim + xs is-sorted-loop ] if
    ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx xs ys } {
    idx xs prim seq-int.len prim =
    [ sum ]
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim +
      idx 1 prim +
      xs ys
      dot-loop
    ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 flags all-true-loop };

: all-true-loop
  (forall ρ; ρ result:Bool^many idx:Int^many flags:Seq Bool^many -- ρ final:Bool^many)
  locals { result idx flags } {
    idx flags prim seq-bool.len prim =
    [ result ]
    [
      flags idx prim seq-bool.at result prim and
      idx 1 prim +
      flags
      all-true-loop
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 prim seq-int.at 1 1 xs longest-run-loop ] if
  };

: longest-run-loop
  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { prev curr-run max-run idx xs } {
    idx xs prim seq-int.len prim =
    [ max-run curr-run prim < [ curr-run ] [ max-run ] if ]
    [
      xs idx prim seq-int.at dup prev prim =
      [ curr-run 1 prim + ] [ 1 swap ] if
      idx 1 prim +
      xs
      longest-run-loop
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 xs target has-pair-loop };

: has-pair-loop
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } {
    found
    [ true ]
    [
      i xs prim seq-int.len prim =
      [ false ]
      [
        i 1 prim + xs target has-pair-inner-loop
      ]
      if
    ]
    if
  };

: has-pair-inner-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { j xs target i } {
    j xs prim seq-int.len prim =
    [ false i 1 prim + xs target has-pair-loop ]
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + xs target i has-pair-inner-loop ] if
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 xs count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen idx xs } {
    idx xs prim seq-int.len prim =
    [ seen prim seq-int.len ]
    [
      xs idx prim seq-int.at 0 seen count-distinct-search
      idx 1 prim +
      xs
      count-distinct-loop
    ]
    if
  };

: count-distinct-search
  (forall ρ; ρ elem:Int^many j:Int^many seen:Seq Int^many -- ρ updated:Seq Int^many)
  locals { elem j seen } {
    j seen prim seq-int.len prim =
    [ elem seen prim seq-int.push ]
    [
      seen j prim seq-int.at elem prim =
      [ seen ]
      [ elem j 1 prim + seen count-distinct-search ] if
    ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { 0 0 prim seq-int.empty xs ys merge-loop };

: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { i j result xs ys } {
    i xs prim seq-int.len prim =
    [
      j ys prim seq-int.len prim =
      [ result ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + ys xs merge-loop-y ]
      if
    ]
    [
      j ys prim seq-int.len prim =
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys merge-loop ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys merge-loop ]
        [ ys j prim seq-int.at result prim seq-int.push j 1 prim + xs ys merge-loop ]
        if
      ]
      if
    ]
    if
  };

: merge-loop-y
  (forall ρ; ρ j:Int^many result:Seq Int^many ys:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { j result ys xs } {
    j ys prim seq-int.len prim =
    [ result ]
    [ ys j prim seq-int.at result prim seq-int.push j 1 prim + ys xs merge-loop-y ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digits-loop ] if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div
      digits-loop
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not
    [ result ]
    [
      candidate is-prime
      [ candidate result prim seq-int.push ] [ result ] if
      candidate 1 prim +
      n
      primes-loop
    ]
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many -- ρ result:Bool^many)
  locals { candidate } {
    candidate 2 prim <
    [ false ]
    [
      candidate 2 prim =
      [ true ]
      [
        candidate 2 prim mod 0 prim =
        [ false ]
        [ 3 candidate is-prime-helper ] if
      ]
      if
    ]
    if
  };

: is-prime-helper
  (forall ρ; ρ divisor:Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { divisor candidate } {
    divisor divisor prim * candidate prim < prim not
    [ true ]
    [
      candidate divisor prim mod 0 prim =
      [ false ]
      [ divisor 2 prim + candidate is-prime-helper ] if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 k histogram-init xs 0 xs k histogram-loop };

: histogram-init
  (forall ρ; ρ remaining:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { remaining counts } {
    remaining 0 prim =
    [ counts ]
    [ 0 counts prim seq-int.push remaining 1 prim - histogram-init ] if
  };

: histogram-loop
  (forall ρ; ρ idx:Int^many counts:Seq Int^many xs:Seq Int^many k:Int^many -- ρ final:Seq Int^many)
  locals { idx counts xs k } {
    idx xs prim seq-int.len prim =
    [ counts ]
    [
      xs idx prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + v counts histogram-update }
      idx 1 prim +
      xs k
      histogram-loop
    ]
    if
  };

: histogram-update
  (forall ρ; ρ new-val:Int^many value:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { new-val value counts } {
    prim seq-int.empty 0 counts value new-val histogram-update-loop
  };

: histogram-update-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many counts:Seq Int^many value:Int^many new-val:Int^many -- ρ final:Seq Int^many)
  locals { result i counts value new-val } {
    i counts prim seq-int.len prim =
    [ result ]
    [
      i value prim =
      [ new-val result prim seq-int.push ]
      [ counts i prim seq-int.at result prim seq-int.push ] if
      i 1 prim +
      counts value new-val
      histogram-update-loop
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs prim seq-int.empty sort-insertion };

: sort-insertion
  (forall ρ; ρ unsorted:Seq Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { unsorted result } {
    unsorted prim seq-int.len 0 prim =
    [ result ]
    [
      unsorted prim seq-int.len 1 prim -
      unsorted 0 prim seq-int.at
      unsorted
      sort-extract
      result
      sort-insert
      unsorted
      sort-insertion
    ]
    if
  };

: sort-extract
  (forall ρ; ρ idx:Int^many elem:Int^many unsorted:Seq Int^many -- ρ result:Seq Int^many elem2:Int^many)
  locals { idx elem unsorted } {
    idx 0 prim =
    [ prim seq-int.empty elem ]
    [
      unsorted 0 prim seq-int.at
      idx 1 prim -
      unsorted
      sort-extract
      prim seq-int.push
      elem
    ]
    if
  };

: sort-insert
  (forall ρ; ρ elem:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { elem result } {
    result prim seq-int.len 0 prim =
    [ elem result prim seq-int.push ]
    [
      0 result elem sort-insert-loop
    ]
    if
  };

: sort-insert-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many elem:Int^many -- ρ final:Seq Int^many)
  locals { i result elem } {
    i result prim seq-int.len prim =
    [ elem result prim seq-int.push ]
    [
      elem result i prim seq-int.at prim <
      [ elem i result sort-insert-at ]
      [ i 1 prim + result elem sort-insert-loop ] if
    ]
    if
  };

: sort-insert-at
  (forall ρ; ρ elem:Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { elem idx result } {
    prim seq-int.empty 0 result elem idx sort-insert-at-loop
  };

: sort-insert-at-loop
  (forall ρ; ρ new-result:Seq Int^many j:Int^many result:Seq Int^many elem:Int^many idx:Int^many -- ρ final:Seq Int^many)
  locals { new-result j result elem idx } {
    j result prim seq-int.len prim =
    [ elem new-result prim seq-int.push ]
    [
      j idx prim =
      [ elem new-result prim seq-int.push result j prim seq-int.at new-result prim seq-int.push ]
      [ result j prim seq-int.at new-result prim seq-int.push ] if
      j 1 prim +
      result elem idx
      sort-insert-at-loop
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected idx txs } {
    idx txs prim seq-int.len prim =
    [ balance rejected ]
    [
      txs idx prim seq-int.at balance prim + dup 0 prim <
      [ drop balance rejected 1 prim + ]
      [ balance rejected ] if
      idx 1 prim +
      txs
      ledger-loop
    ]
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
    items qtys whole
    allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons idx items qtys whole } {
    idx qtys prim seq-int.len prim =
    [ stock allocated reasons ]
    [
      qtys idx prim seq-int.at
      stock items idx prim seq-int.at prim seq-int.at
      whole idx prim seq-bool.at
      locals { qty item-stock whole-flag } {
        qty item-stock prim <
        [
          qty stock items idx prim seq-int.at prim seq-int.at prim - 
          items idx prim seq-int.at stock prim seq-int.len 1 prim - locals { new-qty item-idx } {
            0 prim seq-int.empty 0 stock new-qty item-idx allocate-update-stock
          }
          dup qty 0 prim = [ drop 0 ] [ drop 1 ] if
        ]
        [
          item-stock 0 prim =
          [ stock allocated 2 prim seq-int.push reasons ]
          [
            whole-flag
            [ stock allocated 3 prim seq-int.push reasons ]
            [ stock allocated item-stock prim seq-int.push reasons 1 prim seq-int.push ]
            if
          ]
          if
        ]
        if
      }
      idx 1 prim +
      items qtys whole
      allocate-loop
    ]
    if
  };

: allocate-update-stock
  (forall ρ; ρ j:Int^many old-stock:Seq Int^many new-qty:Int^many item-idx:Int^many -- ρ result:Seq Int^many new-qty-result:Int^many)
  locals { j old-stock new-qty item-idx } {
    j old-stock prim seq-int.len prim =
    [ old-stock new-qty ]
    [
      j item-idx prim =
      [ old-stock prim seq-int.push new-qty ]
      [ old-stock j prim seq-int.at old-stock prim seq-int.push ]
      if
      j 1 prim +
      new-qty item-idx
      allocate-update-stock
    ]
    if
  };
```
