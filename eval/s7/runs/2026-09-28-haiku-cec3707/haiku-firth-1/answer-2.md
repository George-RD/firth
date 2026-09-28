### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 swap 0 sum-loop;

: sum-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many -- ρ result:Int^many)
  locals { i xs sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      i 1 prim + xs swap sum-loop
    ]
    [
      sum
    ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs max-loop
  };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup max prim <
      [ drop max ]
      [ swap drop ]
      if
      i 1 prim + xs swap max-loop
    ]
    [
      max
    ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 swap 0 count-loop;

: count-loop
  (forall ρ; ρ i:Int^many k:Int^many xs:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { i k xs count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup k prim <
      [ drop count 1 prim + ]
      [ drop count ]
      if
      i 1 prim + k xs swap count-loop
    ]
    [
      count
    ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty swap 0 reverse-loop;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim + xs swap reverse-loop
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 swap prefix-loop;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      dup result prim seq-int.push
      i 1 prim + xs swap result swap prefix-loop
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty swap 0 filter-positive;

: filter-positive
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup 0 prim <
      [
        drop
        i 1 prim + xs result filter-positive
      ]
      [
        result prim seq-int.push
        i 1 prim + xs swap filter-positive
      ]
      if
    ]
    [ result ]
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
    [
      1 xs true check-sorted
    ]
    if
  };

: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many ok:Bool^many -- ρ result:Bool^many)
  locals { i xs ok } {
    ok prim not
    [ false ]
    [
      i xs prim seq-int.len prim <
      [
        xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim <
        [
          false
          i 1 prim + xs false check-sorted
        ]
        [
          i 1 prim + xs true check-sorted
        ]
        if
      ]
      [ true ]
      if
    ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 swap true check-all-true;

: check-all-true
  (forall ρ; ρ i:Int^many flags:Seq Bool^many ok:Bool^many -- ρ result:Bool^many)
  locals { i flags ok } {
    ok prim not
    [ false ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at prim not
        [
          false
          i 1 prim + flags false check-all-true
        ]
        [
          i 1 prim + flags true check-all-true
        ]
        if
      ]
      [ true ]
      if
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [
    xs 0 prim seq-int.at 1 0 1 longest-run-loop
  ]
  if;

: longest-run-loop
  (forall ρ; ρ prev:Int^many current:Int^many max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { prev current max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup prev prim =
      [ drop current 1 prim + ]
      [ swap drop 1 ]
      if
      dup max [ prim < ] dip
      [ ]
      [ swap drop ]
      if
      i 1 prim + xs swap swap swap longest-run-loop
    ]
    [ max ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 swap false check-pair-sum;

: check-pair-sum
  (forall ρ; ρ i:Int^many target:Int^many xs:Seq Int^many found:Bool^many -- ρ result:Bool^many)
  locals { i target xs found } {
    found prim not
    [
      i xs prim seq-int.len prim <
      [
        0 i target xs check-j-loop
      ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: check-j-loop
  (forall ρ; ρ j:Int^many i:Int^many target:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { j i target xs } {
    j xs prim seq-int.len prim <
    [
      j i prim =
      [
        j 1 prim + i target xs check-j-loop
      ]
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [
          j 1 prim + i target xs check-j-loop
        ]
        if
      ]
      if
    ]
    [
      i 1 prim + target xs check-pair-sum
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty swap 0 count-distinct-loop;

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { seen xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 seen find-in-seq
      0 prim <
      [
        seen prim seq-int.push
        i 1 prim + xs swap count-distinct-loop
      ]
      [
        drop
        i 1 prim + xs swap count-distinct-loop
      ]
      if
    ]
    [ seen prim seq-int.len ]
    if
  };

: find-in-seq
  (forall ρ; ρ x:Int^many j:Int^many seen:Seq Int^many -- ρ index:Int^many)
  locals { x j seen } {
    j seen prim seq-int.len prim <
    [
      seen j prim seq-int.at x prim =
      [ j ]
      [ x j 1 prim + seen find-in-seq ]
      if
    ]
    [ -1 ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty swap 0 0 swap merge-loop;

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many j:Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result xs i j ys } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim + j ys xs swap merge-loop
      ]
      [
        ys j prim seq-int.at result prim seq-int.push
        i j 1 prim + ys xs swap merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim + j ys xs swap merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at result prim seq-int.push
          i j 1 prim + ys xs swap merge-loop
        ]
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
    [ { 0 } ]
    [
      prim seq-int.empty n extract-digits
    ]
    if
  };

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      swap extract-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 collect-primes;

: collect-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
        candidate 1 prim + n collect-primes
      ]
      [
        candidate 1 prim + n collect-primes
      ]
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
    [
      n 2 prim =
      [ true ]
      [
        2 n check-divisor
      ]
      if
    ]
    if
  };

: check-divisor
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [
        d 1 prim + n check-divisor
      ]
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
    prim seq-int.empty 0 k 0 xs init-and-build
  };

: init-and-build
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many j:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i k j xs } {
    i k prim <
    [
      0 result prim seq-int.push
      i 1 prim + k j xs init-and-build
    ]
    [
      j xs prim seq-int.len prim <
      [
        xs j prim seq-int.at
        dup result swap prim seq-int.at 1 prim + swap prim seq-int.push
        j 1 prim + xs init-and-build
      ]
      [ result ]
      if
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty swap 0 insertion-sort;

: insertion-sort
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0 result insert-at-pos
      i 1 prim + xs swap insertion-sort
    ]
    [ result ]
    if
  };

: insert-at-pos
  (forall ρ; ρ pos:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { pos result val } {
    pos result prim seq-int.len prim <
    [
      result pos prim seq-int.at val prim <
      [
        val result prim seq-int.push
        pos result insert-at-pos
      ]
      [
        pos 1 prim + result val insert-at-pos
      ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 swap start 0 process-ledger;

: process-ledger
  (forall ρ; ρ i:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { i txs balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      dup balance prim + 0 prim <
      [
        drop
        rejected 1 prim + i txs balance process-ledger
      ]
      [
        balance prim + rejected
        i 1 prim + txs swap process-ledger
      ]
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
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 process-orders;

: process-orders
  (forall ρ; ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { allocated reasons stock i items qtys whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      stock over prim seq-int.at
      qtys i prim seq-int.at
      dup2 prim <
      [
        whole i prim seq-bool.at prim not
        [
          allocated prim seq-int.push
          reasons 1 prim seq-int.push
          stock swap prim -
        ]
        [
          drop drop
          0 allocated prim seq-int.push
          reasons 3 prim seq-int.push
        ]
        if
        swap stock swap prim seq-int.push
        i 1 prim + items qtys whole process-orders
      ]
      [
        0 prim =
        [
          0 allocated prim seq-int.push
          reasons 2 prim seq-int.push
          stock
        ]
        [
          prim seq-int.push allocated prim seq-int.push
          reasons 0 prim seq-int.push
        ]
        if
        i 1 prim + items qtys whole process-orders
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };
```
