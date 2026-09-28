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
      xs idx prim seq-int.at result swap prim seq-int.push
      idx 1 prim -
      swap
      xs
      reverse-loop
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
      0 xs idx prim seq-int.at prim <
      [ xs idx prim seq-int.at result swap prim seq-int.push ]
      [ drop result ]
      if
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
      xs idx 1 prim + prim seq-int.at xs idx prim seq-int.at prim <
      [ idx 1 prim + xs is-sorted-loop ]
      [ false ] if
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
      [ curr-run 1 prim + ]
      [ 1 swap ]
      if
      idx 1 prim +
      xs
      longest-run-loop
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
      [ ys j prim seq-int.at result swap prim seq-int.push j 1 prim + ys xs merge-loop-y ]
      if
    ]
    [
      j ys prim seq-int.len prim =
      [ xs i prim seq-int.at result swap prim seq-int.push i 1 prim + xs ys merge-loop ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [ xs i prim seq-int.at result swap prim seq-int.push i 1 prim + xs ys merge-loop ]
        [ ys j prim seq-int.at result swap prim seq-int.push j 1 prim + xs ys merge-loop ]
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
    [ ys j prim seq-int.at result swap prim seq-int.push j 1 prim + ys xs merge-loop-y ]
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
    [ prim seq-int.empty n digits-collect prim seq-int.len dup prim seq-int.empty swap digits-reverse-final ]
    if
  };

: digits-collect
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod result swap prim seq-int.push
      n 10 prim div
      digits-collect
    ]
    if
  };

: digits-reverse-final
  (forall ρ; ρ len:Int^many result:Seq Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  locals { len result idx } {
    idx 0 prim <
    [ result ]
    [
      result idx prim seq-int.at result prim seq-int.push
      idx 1 prim -
      result
      idx
      digits-reverse-final
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
      [ candidate result swap prim seq-int.push ] [ result ] if
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
    candidate divisor prim mod 0 prim =
    [ false ]
    [
      divisor divisor prim * candidate prim <
      [ divisor 2 prim + candidate is-prime-helper ]
      [ true ]
      if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 k histogram-init 0 xs histogram-loop };

: histogram-init
  (forall ρ; ρ remaining:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { remaining counts } {
    remaining 0 prim =
    [ counts ]
    [ 0 counts prim seq-int.push remaining 1 prim - histogram-init ] if
  };

: histogram-loop
  (forall ρ; ρ idx:Int^many counts:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx counts xs } {
    idx xs prim seq-int.len prim =
    [ counts ]
    [
      xs idx prim seq-int.at counts histogram-increment
      idx 1 prim +
      xs
      histogram-loop
    ]
    if
  };

: histogram-increment
  (forall ρ; ρ elem:Int^many counts:Seq Int^many -- ρ updated:Seq Int^many)
  locals { elem counts } {
    prim seq-int.empty 0 counts elem histogram-increment-loop
  };

: histogram-increment-loop
  (forall ρ; ρ new-result:Seq Int^many j:Int^many counts:Seq Int^many elem:Int^many -- ρ final:Seq Int^many)
  locals { new-result j counts elem } {
    j counts prim seq-int.len prim =
    [ new-result ]
    [
      j elem prim =
      [ counts j prim seq-int.at 1 prim + new-result swap prim seq-int.push ]
      [ counts j prim seq-int.at new-result swap prim seq-int.push ]
      if
      j 1 prim +
      counts elem
      histogram-increment-loop
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { 0 xs prim seq-int.empty sort-insertion };

: sort-insertion
  (forall ρ; ρ idx:Int^many unsorted:Seq Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx unsorted result } {
    idx unsorted prim seq-int.len prim =
    [ result ]
    [
      unsorted idx prim seq-int.at result sort-insert-simple
      idx 1 prim +
      unsorted
      sort-insertion
    ]
    if
  };

: sort-insert-simple
  (forall ρ; ρ elem:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { elem result } {
    result prim seq-int.len 0 prim =
    [ elem result prim seq-int.push ]
    [ 0 elem result sort-insert-loop ]
    if
  };

: sort-insert-loop
  (forall ρ; ρ i:Int^many elem:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { i elem result } {
    i result prim seq-int.len prim =
    [ elem result prim seq-int.push ]
    [
      elem result i prim seq-int.at prim <
      [ prim seq-int.empty 0 result elem i sort-insert-at ]
      [ i 1 prim + elem result sort-insert-loop ]
      if
    ]
    if
  };

: sort-insert-at
  (forall ρ; ρ new-result:Seq Int^many j:Int^many result:Seq Int^many elem:Int^many idx:Int^many -- ρ final:Seq Int^many)
  locals { new-result j result elem idx } {
    j result prim seq-int.len prim =
    [ elem new-result prim seq-int.push ]
    [
      j idx prim =
      [ elem new-result prim seq-int.push ]
      [ result j prim seq-int.at new-result swap prim seq-int.push ]
      if
      j 1 prim +
      result elem idx
      sort-insert-at
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
      idx 1 prim +
      swap
      txs idx prim seq-int.at balance prim + dup 0 prim <
      [ drop rejected ]
      [ swap rejected ]
      if
      swap
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
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-loop };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons idx items qtys whole } {
    idx qtys prim seq-int.len prim =
    [ stock allocated reasons ]
    [
      idx 1 prim +
      qtys idx prim seq-int.at stock items idx prim seq-int.at prim seq-int.at 2 locals { qty curr-stock } {
        qty curr-stock prim <
        [ qty allocated prim seq-int.push 0 reasons prim seq-int.push stock items idx prim seq-int.at qty prim - items idx prim seq-int.at prim seq-int.at prim seq-int.push ]
        [ curr-stock 0 prim = [ allocated prim seq-int.push 2 reasons prim seq-int.push ] [ whole idx prim seq-bool.at [ allocated prim seq-int.push 3 reasons prim seq-int.push ] [ allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push ] if ] if ]
        if
      }
      items qtys whole
      allocate-loop
    ]
    if
  };
```
