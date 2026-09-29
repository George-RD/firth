### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i len xs } {
    i len prim <
    [ xs i prim seq-int.at sum prim + i 1 prim + xs len sum-loop ]
    [ ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 xs prim seq-int.len max-loop };

: max-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i len xs max } {
    i len prim <
    [ xs i prim seq-int.at dup max prim < [ drop max ] [ swap drop ] if i 1 prim + xs len max-loop ]
    [ ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs prim seq-int.len count-loop };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i len xs k } {
    i len prim <
    [ xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim + count-loop ]
    [ ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs prim seq-int.len x xs find-index };

: find-index
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i len xs x } {
    i len prim <
    [ xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs len x find-index ]
      if
    ]
    [ -1 ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    [ result ]
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - result xs reverse-loop ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i len xs } {
    i len prim <
    [ xs i prim seq-int.at sum prim + dup result prim seq-int.push i 1 prim + result xs len prefix-loop ]
    [ ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len keep-positive-loop };

: keep-positive-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [ xs i prim seq-int.at dup 0 prim <
      [ drop result i 1 prim + xs len keep-positive-loop ]
      [ result prim seq-int.push i 1 prim + result xs len keep-positive-loop ]
      if
    ]
    [ ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len dup 1 prim <
    [ drop true ]
    [ xs 0 1 check-sorted ]
    if
  };

: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim < 
      [ false ]
      [ i 1 prim + xs check-sorted ]
      if
    ]
    [ true ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs prim seq-int.len dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i len xs ys } {
    i len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + sum xs ys len dot-loop ]
    [ ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 0 flags prim seq-bool.len all-true-loop };

: all-true-loop
  (forall ρ; ρ i:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { i len flags } {
    i len prim <
    [ flags i prim seq-bool.at
      [ i 1 prim + i len flags all-true-loop ]
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
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len dup 0 prim <
    [ drop 0 ]
    [ dup 1 prim <
      [ drop 1 ]
      [ 1 1 xs 0 prim seq-int.at xs longest-run-loop ]
      if
    ]
    if
  };

: longest-run-loop
  (forall ρ; ρ i:Int^many current:Int^many max:Int^many prev:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i current max prev xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup prev prim =
      [ current 1 prim + max dup prim < [ drop max ] [ swap drop ] if i 1 prim + xs longest-run-loop ]
      [ swap drop 1 max i 1 prim + xs longest-run-loop ]
      if
    ]
    [ max ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len xs target check-pairs };

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target } {
    i len prim <
    [ i 1 prim + xs target find-pair-for ]
    [ false ]
    if
  };

: find-pair-for
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + i xs target find-pair-for ]
      if
    ]
    [ i xs len xs target check-pairs ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i len xs } {
    i len prim <
    [ xs i prim seq-int.at xs 0 i is-new-value
      [ count 1 prim + i 1 prim + count xs len count-distinct-loop ]
      [ i 1 prim + count xs len count-distinct-loop ]
      if
    ]
    [ ]
    if
  };

: is-new-value
  (forall ρ; ρ val:Int^many start:Int^many end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val start end xs } {
    start end prim <
    [ xs start prim seq-int.at val prim =
      [ false ]
      [ start 1 prim + val xs end is-new-value ]
      if
    ]
    [ true ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-sorted-loop };

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim <
    prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + result xs ys j merge-sorted-loop ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + result i xs ys merge-sorted-loop ]
      if
    ]
    [ i xs prim seq-int.len prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + result xs ys j merge-sorted-loop ]
      [ j ys prim seq-int.len prim <
        [ ys j prim seq-int.at result prim seq-int.push j 1 prim + result i xs ys merge-sorted-loop ]
        [ result ]
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
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    n 0 prim <
    [ result ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div result digits-loop ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result i n } {
    i n prim <
    [ i is-prime
      [ i result prim seq-int.push i 1 prim + result n primes-loop ]
      [ i 1 prim + result n primes-loop ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 prim = [ true ] [ 2 n check-divisor ] if ]
    if
  };

: check-divisor
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ result:Bool^many)
  locals { divisor n } {
    divisor dup prim * n prim <
    [ n divisor prim mod 0 prim =
      [ false ]
      [ divisor 1 prim + n check-divisor ]
      if
    ]
    [ true ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k create-histogram 0 xs prim seq-int.len histogram-loop
  };

: create-histogram
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { counts i k } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + counts k create-histogram ]
    [ counts ]
    if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i len xs counts } {
    i len prim <
    [ xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set i 1 prim + counts xs len histogram-loop ]
    [ counts ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len 1 prim - insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { result i len } {
    i len prim <
    [ result i result i prim seq-int.at i insert-into i 1 prim + result len insertion-sort-loop ]
    [ result ]
    if
  };

: insert-into
  (forall ρ; ρ pos:Int^many val:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { pos val j result } {
    j 0 prim <
    [ result pos val prim seq-int.set ]
    [ result j prim seq-int.at val prim <
      [ j 1 prim + pos val result insert-into ]
      [ result pos val prim seq-int.set ]
      if
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs prim seq-int.len ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i len txs } {
    i len prim <
    [ txs i prim seq-int.at dup balance prim + dup 0 prim <
      [ drop drop balance rejected 1 prim + i 1 prim + txs len ledger-loop ]
      [ swap drop balance i 1 prim + balance rejected txs len ledger-loop ]
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
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len stock items qtys whole allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many len:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock-left allocated reasons j len stock items qtys whole } {
    j len prim <
    [ items j prim seq-int.at stock swap prim seq-int.at qtys j prim seq-int.at whole j prim seq-bool.at
      locals { w q r item } {
        q r prim <
        [ r 0 prim =
          [ 0 prim seq-int.empty prim seq-int.push stock item 0 prim seq-int.push prim seq-int.set allocated 0 prim seq-int.push reasons 2 prim seq-int.push ]
          [ w
            [ 0 prim seq-int.empty prim seq-int.push stock item 0 prim seq-int.empty prim seq-int.push prim seq-int.set allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]
            [ r prim seq-int.empty prim seq-int.push stock item r prim seq-int.empty prim seq-int.push prim seq-int.set allocated r prim seq-int.push reasons 1 prim seq-int.push ]
            if
          ]
          if
        ]
        [ q prim seq-int.empty prim seq-int.push stock item q prim seq-int.empty prim seq-int.push prim seq-int.set allocated q prim seq-int.push reasons 0 prim seq-int.push ]
        if
        j 1 prim + stock items qtys whole allocate-loop
      }
    ]
    [ stock-left allocated reasons ]
    if
  };
```
