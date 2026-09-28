### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-loop
  ;

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ total:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim + xs i prim seq-int.at acc prim + sum-loop ]
    [ acc ]
    if
  }
  ;
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs xs 0 prim seq-int.at 1 max-loop }
  ;

: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } {
    a b prim <
    [ b ]
    [ a ]
    if
  }
  ;

: max-loop
  (forall ρ; ρ xs:Seq Int^many acc:Int^many i:Int^many -- ρ largest:Int^many)
  locals { xs acc i } {
    i xs prim seq-int.len prim <
    [ xs acc xs i prim seq-int.at max2 i 1 prim + max-loop ]
    [ acc ]
    if
  }
  ;
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-below-loop }
  ;

: count-below-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many acc:Int^many -- ρ count:Int^many)
  locals { xs k i acc } {
    i xs prim seq-int.len prim <
    [ xs k i 1 prim +
      xs i prim seq-int.at k prim <
      [ acc 1 prim + ]
      [ acc ]
      if
      count-below-loop
    ]
    [ acc ]
    if
  }
  ;
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-of-loop }
  ;

: index-of-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at x prim =
      [ i ]
      [ xs x i 1 prim + index-of-loop ]
      if
    ]
    [ -1 ]
    if
  }
  ;
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  }
  ;

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i acc } {
    i 0 prim <
    [ acc ]
    [ xs i 1 prim - acc xs i prim seq-int.at prim seq-int.push reverse-loop ]
    if
  }
  ;
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop }
  ;

: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many running:Int^many acc:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i running acc } {
    i xs prim seq-int.len prim <
    [ xs
      i 1 prim +
      running xs i prim seq-int.at prim +
      acc running xs i prim seq-int.at prim + prim seq-int.push
      prefix-loop
    ]
    [ acc ]
    if
  }
  ;
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-positive-loop }
  ;

: keep-positive-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim +
      0 xs i prim seq-int.at prim <
      [ acc xs i prim seq-int.at prim seq-int.push ]
      [ acc ]
      if
      keep-positive-loop
    ]
    [ acc ]
    if
  }
  ;
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 is-sorted-loop }
  ;

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i 1 prim + xs prim seq-int.len prim <
    [ xs i 1 prim + prim seq-int.at xs i prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + is-sorted-loop ]
      if
    ]
    [ true ]
    if
  }
  ;
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop }
  ;

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [ xs ys i 1 prim +
      acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      dot-loop
    ]
    [ acc ]
    if
  }
  ;
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-true-loop }
  ;

: all-true-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at
      [ flags i 1 prim + all-true-loop ]
      [ false ]
      if
    ]
    [ true ]
    if
  }
  ;
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 1 1 1 longest-run-loop ]
    if
  }
  ;

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many curr:Int^many best:Int^many -- ρ length:Int^many)
  locals { xs i curr best } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
      [ xs i 1 prim + curr 1 prim +
        best curr 1 prim + prim < [ curr 1 prim + ] [ best ] if
        longest-run-loop
      ]
      [ xs i 1 prim + 1
        best 1 prim < [ 1 ] [ best ] if
        longest-run-loop
      ]
      if
    ]
    [ best ]
    if
  }
  ;
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 has-pair-outer }
  ;

: has-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ xs target i j 1 prim + has-pair-inner ]
      if
    ]
    [ false ]
    if
  }
  ;

: has-pair-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [ xs target i i 1 prim + has-pair-inner
      [ true ]
      [ xs target i 1 prim + has-pair-outer ]
      if
    ]
    [ false ]
    if
  }
  ;
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 count-distinct-loop }
  ;

: seen-before
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs i j } {
    j i prim <
    [ xs j prim seq-int.at xs i prim seq-int.at prim =
      [ true ]
      [ xs i j 1 prim + seen-before ]
      if
    ]
    [ false ]
    if
  }
  ;

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ count:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs
      i 1 prim +
      xs i 0 seen-before
      [ acc ]
      [ acc 1 prim + ]
      if
      count-distinct-loop
    ]
    [ acc ]
    if
  }
  ;
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop }
  ;

: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many acc:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j acc } {
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim <
      [ xs i prim seq-int.at ys j prim seq-int.at prim <
        [ xs ys i 1 prim + j acc xs i prim seq-int.at prim seq-int.push merge-loop ]
        [ xs ys i j 1 prim + acc ys j prim seq-int.at prim seq-int.push merge-loop ]
        if
      ]
      [ xs ys i 1 prim + j acc xs i prim seq-int.at prim seq-int.push merge-loop ]
      if
    ]
    [ j ys prim seq-int.len prim <
      [ xs ys i j 1 prim + acc ys j prim seq-int.at prim seq-int.push merge-loop ]
      [ acc ]
      if
    ]
    if
  }
  ;
```

### task: digits
```firth
: div10-loop
  (forall ρ; ρ n:Int^many q:Int^many -- ρ q:Int^many)
  locals { n q } {
    n 10 prim <
    [ q ]
    [ n 10 prim - q 1 prim + div10-loop ]
    if
  }
  ;

: div10
  (forall ρ; ρ n:Int^many -- ρ q:Int^many)
  0 div10-loop
  ;

: mod10
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  locals { n } {
    n 10 prim <
    [ n ]
    [ n 10 prim - mod10 ]
    if
  }
  ;

: digits-collect
  (forall ρ; ρ n:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { n acc } {
    n 0 prim =
    [ acc ]
    [ n div10 acc n mod10 prim seq-int.push digits-collect ]
    if
  }
  ;

: reverse-seq-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i acc } {
    i 0 prim <
    [ acc ]
    [ xs i 1 prim - acc xs i prim seq-int.at prim seq-int.push reverse-seq-loop ]
    if
  }
  ;

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-seq-loop }
  ;

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digits-collect reverse-seq ]
    if
  }
  ;
```

### task: primes-up-to
```firth
: modulo
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    a b prim <
    [ a ]
    [ a b prim - b modulo ]
    if
  }
  ;

: is-prime-loop
  (forall ρ; ρ k:Int^many d:Int^many -- ρ result:Bool^many)
  locals { k d } {
    k d d prim * prim < prim not
    [ k d modulo 0 prim =
      [ false ]
      [ k d 1 prim + is-prime-loop ]
      if
    ]
    [ true ]
    if
  }
  ;

: is-prime
  (forall ρ; ρ k:Int^many -- ρ result:Bool^many)
  locals { k } {
    k 2 prim <
    [ false ]
    [ k 2 is-prime-loop ]
    if
  }
  ;

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many acc:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i acc } {
    n i prim < prim not
    [ i is-prime
      [ n i 1 prim + acc i prim seq-int.push primes-loop ]
      [ n i 1 prim + acc primes-loop ]
      if
    ]
    [ acc ]
    if
  }
  ;

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-loop }
  ;
```

### task: histogram
```firth
: count-equal
  (forall ρ; ρ xs:Seq Int^many v:Int^many j:Int^many acc:Int^many -- ρ count:Int^many)
  locals { xs v j acc } {
    j xs prim seq-int.len prim <
    [ xs v j 1 prim +
      xs j prim seq-int.at v prim =
      [ acc 1 prim + ]
      [ acc ]
      if
      count-equal
    ]
    [ acc ]
    if
  }
  ;

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many v:Int^many acc:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs k v acc } {
    v k prim <
    [ xs k v 1 prim + acc xs v 0 0 count-equal prim seq-int.push histogram-loop ]
    [ acc ]
    if
  }
  ;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { xs k 0 prim seq-int.empty histogram-loop }
  ;
```

### task: sort
```firth
: seq-insert-loop
  (forall ρ; ρ sorted:Seq Int^many x:Int^many i:Int^many acc:Seq Int^many done:Bool^many -- ρ result:Seq Int^many)
  locals { sorted x i acc done } {
    i sorted prim seq-int.len prim <
    [ done
      [ sorted x i 1 prim + acc sorted i prim seq-int.at prim seq-int.push done seq-insert-loop ]
      [ sorted i prim seq-int.at x prim <
        [ sorted x i 1 prim + acc sorted i prim seq-int.at prim seq-int.push false seq-insert-loop ]
        [ sorted x i acc x prim seq-int.push true seq-insert-loop ]
        if
      ]
      if
    ]
    [ done
      [ acc ]
      [ acc x prim seq-int.push ]
      if
    ]
    if
  }
  ;

: seq-insert
  (forall ρ; ρ sorted:Seq Int^many x:Int^many -- ρ result:Seq Int^many)
  locals { sorted x } { sorted x 0 prim seq-int.empty false seq-insert-loop }
  ;

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim + acc xs i prim seq-int.at seq-insert sort-loop ]
    [ acc ]
    if
  }
  ;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop }
  ;
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs start 0 0 ledger-loop }
  ;

: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [ balance txs i prim seq-int.at prim + 0 prim <
      [ txs i 1 prim + balance rejected 1 prim + ]
      [ txs i 1 prim + balance txs i prim seq-int.at prim + rejected ]
      if
      ledger-loop
    ]
    [ balance rejected ]
    if
  }
  ;
```

### task: allocate-batch
```firth
: seq-set-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many val:Int^many k:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx val k acc } {
    k xs prim seq-int.len prim <
    [ k idx prim =
      [ xs idx val k 1 prim + acc val prim seq-int.push seq-set-loop ]
      [ xs idx val k 1 prim + acc xs k prim seq-int.at prim seq-int.push seq-set-loop ]
      if
    ]
    [ acc ]
    if
  }
  ;

: seq-set
  (forall ρ; ρ xs:Seq Int^many idx:Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { xs idx val } { xs idx val 0 prim seq-int.empty seq-set-loop }
  ;

: order-step
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many wh:Bool^many -- ρ newstock:Seq Int^many alloc:Int^many reason:Int^many)
  locals { stock item qty wh } {
    stock item prim seq-int.at qty prim < prim not
    [ stock item stock item prim seq-int.at qty prim - seq-set
      qty
      0
    ]
    [ stock item prim seq-int.at 0 prim =
      [ stock
        0
        2
      ]
      [ wh
        [ stock
          0
          3
        ]
        [ stock item 0 seq-set
          stock item prim seq-int.at
          1
        ]
        if
      ]
      if
    ]
    if
  }
  ;

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many alloc-acc:Seq Int^many reason-acc:Seq Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole j alloc-acc reason-acc } {
    j items prim seq-int.len prim <
    [ stock items j prim seq-int.at qtys j prim seq-int.at whole j prim seq-bool.at order-step
      locals { newstock alloc reason } {
        newstock items qtys whole j 1 prim + alloc-acc alloc prim seq-int.push reason-acc reason prim seq-int.push allocate-loop
      }
    ]
    [ stock alloc-acc reason-acc ]
    if
  }
  ;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  }
  ;
```
