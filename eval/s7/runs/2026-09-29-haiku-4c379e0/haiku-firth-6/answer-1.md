### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs len i sum } {
    i len prim <
    [ xs i prim seq-int.at sum prim + swap drop sum-loop ]
    [ drop drop drop ]
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
  locals { xs len i max } {
    i len prim <
    [ xs i prim seq-int.at max dup prim < [ drop ] [ swap drop ] if max-loop ]
    [ drop drop drop ]
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
  locals { xs k len i count } {
    i len prim <
    [ xs i prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if swap drop count-loop ]
    [ drop drop drop ]
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
  locals { xs x len i } {
    i len prim <
    [ xs i prim seq-int.at x prim =
      [ i drop drop drop ]
      [ i 1 prim + i drop find-index ]
      if
    ]
    [ drop -1 drop drop ]
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
  locals { xs i result } {
    i 0 prim <
    [ ]
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - reverse-loop ]
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
  locals { xs len i sum result } {
    i len prim <
    [ xs i prim seq-int.at sum prim + sum 1 prim + result prim seq-int.push drop prefix-loop ]
    [ drop drop drop ]
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
  locals { xs len i result } {
    i len prim <
    [ xs i prim seq-int.at dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      i 1 prim + keep-positive-loop
    ]
    [ drop drop drop ]
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
  locals { xs i } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim < 
      [ false ]
      [ i 1 prim + check-sorted ]
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
  locals { xs ys len i sum } {
    i len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop ]
    [ drop drop drop ]
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
  locals { flags len i } {
    i len prim <
    [ flags i prim seq-bool.at
      [ i 1 prim + all-true-loop ]
      [ drop drop false ]
      if
    ]
    [ drop drop true ]
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
      [ 1 1 xs 0 prim seq-int.at longest-run-loop ]
      if
    ]
    if
  };

: longest-run-loop
  (forall ρ; ρ i:Int^many current:Int^many max:Int^many prev:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs prev max current i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at dup prev prim =
      [ current 1 prim + max dup prim < [ drop ] [ swap drop ] if i 1 prim + longest-run-loop ]
      [ swap drop 1 max i 1 prim + longest-run-loop ]
      if
    ]
    [ drop drop drop drop ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len check-pairs };

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target len i } {
    i len prim <
    [ i 1 prim + xs target find-pair-for ]
    [ drop drop false ]
    if
  };

: find-pair-for
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ drop drop drop true ]
      [ j 1 prim + find-pair-for ]
      if
    ]
    [ drop drop drop check-pairs ]
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
  locals { xs len i count } {
    i len prim <
    [ xs i prim seq-int.at xs 0 i is-new-value
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim + count-distinct-loop
    ]
    [ drop drop drop ]
    if
  };

: is-new-value
  (forall ρ; ρ val:Int^many start:Int^many end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs end start val } {
    start end prim <
    [ xs start prim seq-int.at val prim =
      [ drop drop drop false ]
      [ start 1 prim + is-new-value ]
      if
    ]
    [ drop drop drop true ]
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
  locals { xs ys j i result } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim <
    prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-sorted-loop ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-sorted-loop ]
      if
    ]
    [ i xs prim seq-int.len prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + merge-sorted-loop ]
      [ j ys prim seq-int.len prim <
        [ ys j prim seq-int.at result prim seq-int.push j 1 prim + merge-sorted-loop ]
        [ drop drop drop drop ]
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
    [ [ 0 ] ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim <
    [ drop ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digits-loop ]
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
  locals { n i result } {
    i n prim <
    [ i is-prime
      [ i result prim seq-int.push ]
      [ result ]
      if
      i 1 prim + primes-loop
    ]
    [ drop drop drop ]
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
  locals { n divisor } {
    divisor dup prim * n prim <
    [ n divisor prim mod 0 prim =
      [ false ]
      [ divisor 1 prim + check-divisor ]
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
  locals { k i counts } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + create-histogram ]
    [ drop drop ]
    if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs counts len i } {
    i len prim <
    [ xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set i 1 prim + histogram-loop ]
    [ drop drop drop ]
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
  locals { len i result } {
    i len prim <
    [ result i result i prim seq-int.at insert-into i 1 prim + insertion-sort-loop ]
    [ drop drop drop ]
    if
  };

: insert-into
  (forall ρ; ρ pos:Int^many val:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { result j val pos } {
    j 0 prim <
    [ result pos val prim seq-int.set ]
    [ result j prim seq-int.at val prim <
      [ j 1 prim + insert-into ]
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
  locals { txs start } { start 0 0 txs prim seq-int.len ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs len i rejected balance } {
    i len prim <
    [ txs i prim seq-int.at dup balance prim + dup 0 prim <
      [ drop drop rejected 1 prim + i 1 prim + ledger-loop ]
      [ balance rejected i 1 prim + ledger-loop ]
      if
    ]
    [ drop drop drop ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many len:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole len j reasons allocated stock-left } {
    j len prim <
    [ items j prim seq-int.at dup
      stock swap prim seq-int.at dup
      qtys j prim seq-int.at dup
      whole j prim seq-bool.at
      locals { w q r item_stock item } {
        q r prim <
        [ r 0 prim =
          [ 0 2 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
          [ w
            [ 0 3 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
            [ r 1 stock item r prim seq-int.set stock-left allocated reasons 1 prim + ]
            if
          ]
          if
        ]
        [ q r prim seq-int.set stock-left allocated reasons 0 ]
        if
        j 1 prim + allocate-loop
      }
    ]
    [ drop drop drop ]
    if
  };
```
