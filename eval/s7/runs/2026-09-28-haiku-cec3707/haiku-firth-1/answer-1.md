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
      i 1 prim + xs swap swap sum-loop
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
    1 xs xs 0 prim seq-int.at max-loop
  };

: max-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup max prim <
      [ drop max ]
      [ swap drop ]
      if
      i 1 prim + xs swap swap max-loop
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
  locals { xs k } {
    0 xs 0 count-loop k
  };

: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many k:Int^many)
  locals { count xs i k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup k prim <
      [ drop count 1 prim + ]
      [ drop count ]
      if
      i 1 prim + xs swap swap count-loop k
    ]
    [
      count k
    ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0 xs x -1 find-loop
  };

: find-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many result:Int^many -- ρ final:Int^many)
  locals { i xs x result } {
    result 0 prim < 
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at x prim =
        [ i ] [ i 1 prim + xs x result find-loop ] if
      ]
      [ result ]
      if
    ]
    [ result ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim + swap xs reverse-loop
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      dup result prim seq-int.push
      i 1 prim + swap swap xs prefix-loop
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs filter-positive
  };

: filter-positive
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup 0 prim <
      [ drop ]
      [ result prim seq-int.push ]
      if
      i 1 prim + swap xs filter-positive
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
    [ 1 xs true check-sorted ]
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
        [ false i 1 prim + xs check-sorted ]
        [ i 1 prim + xs true check-sorted ]
        if
      ]
      [ true ]
      if
    ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0 xs ys dot-product
  };

: dot-product
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      sum prim +
      i 1 prim + xs swap swap ys dot-product
    ]
    [ sum ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    0 flags true check-all-true
  };

: check-all-true
  (forall ρ; ρ i:Int^many flags:Seq Bool^many ok:Bool^many -- ρ result:Bool^many)
  locals { i flags ok } {
    ok prim not
    [ false ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at prim not
        [ false i 1 prim + flags check-all-true ]
        [ i 1 prim + flags true check-all-true ]
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
    locals { xs } {
      xs 0 prim seq-int.at 1 0 1 xs longest-run-loop
    }
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
  locals { xs target } {
    0 xs target false check-pair-sum
  };

: check-pair-sum
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { i xs target found } {
    found prim not
    [ i 1 prim + xs target check-pair-sum-j ]
    [ true ]
    if
  };

: check-pair-sum-j
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      0 xs target i false check-j-loop
    ]
    [ false ]
    if
  };

: check-j-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { j xs target i found } {
    found prim not
    [
      j xs prim seq-int.len prim <
      [
        j i prim =
        [ j 1 prim + xs target i found check-j-loop ]
        [
          xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
          [ true j 1 prim + xs target i check-pair-sum ]
          [ j 1 prim + xs target i false check-j-loop ]
          if
        ]
        if
      ]
      [ i 1 prim + xs target check-pair-sum ]
      if
    ]
    [ true ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0 seen find-in-seq
      0 prim <
      [
        seen prim seq-int.push
        i 1 prim + xs count-distinct-loop
      ]
      [
        i 1 prim + xs count-distinct-loop
      ]
      if
    ]
    [ seen prim seq-int.len ]
    if
  };

: find-in-seq
  (forall ρ; ρ j:Int^many seen:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { j seen x } {
    j seen prim seq-int.len prim <
    [
      seen j prim seq-int.at x prim =
      [ j ]
      [ j 1 prim + seen x find-in-seq ]
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
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys merge-loop ]
      [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys merge-loop ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim + j xs ys merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at result prim seq-int.push
          i j 1 prim + xs ys merge-loop
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
    [ prim seq-int.empty n extract-digits ]
    if
  };

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div swap extract-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n collect-primes
  };

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
    prim seq-int.empty 0 k init-histogram xs 0 build-histogram
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ final:Seq Int^many xs:Seq Int^many x:Int^many)
  locals { result i k xs x } {
    i k prim <
    [ 0 result prim seq-int.push i 1 prim + k init-histogram xs x ]
    [ result xs x ]
    if
  };

: build-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0 result increment-histogram
      i 1 prim + xs build-histogram
    ]
    [ result ]
    if
  };

: increment-histogram
  (forall ρ; ρ idx:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { idx result val } {
    idx result prim seq-int.len prim <
    [
      idx val prim =
      [ result idx prim seq-int.at 1 prim + result idx prim seq-int.at 1 prim + swap-at-idx val ]
      [ idx 1 prim + result val increment-histogram ]
      if
    ]
    [ result ]
    if
  };

: swap-at-idx
  (forall ρ; ρ result:Seq Int^many idx:Int^many new-val:Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result idx new-val val } {
    idx 0 prim =
    [
      new-val result prim seq-int.push
      1 result val build-rest
    ]
    [
      result 0 prim seq-int.at prim seq-int.empty prim seq-int.push
      idx 1 prim - result new-val val swap-at-idx
    ]
    if
  };

: build-rest
  (forall ρ; ρ i:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { i result val } {
    i val prim seq-int.len prim <
    [
      result val i prim seq-int.at prim seq-int.push
      i 1 prim + result val build-rest
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 insertion-sort
  };

: insertion-sort
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result insert-into-sorted
      i 1 prim + xs sort-next
    ]
    [ result ]
    if
  };

: sort-next
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result insert-into-sorted
      i 1 prim + xs insertion-sort
    ]
    [ result ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result val } {
    result prim seq-int.len 0 prim =
    [
      result val prim seq-int.push
    ]
    [
      0 val result 0 insert-find-position
    ]
    if
  };

: insert-find-position
  (forall ρ; ρ j:Int^many val:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { j val result } {
    j result prim seq-int.len prim <
    [
      result j prim seq-int.at val prim <
      [
        0 result prim seq-int.empty j insert-copy-until val result insert-copy-rest
      ]
      [
        j 1 prim + val result insert-find-position
      ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };

: insert-copy-until
  (forall ρ; ρ i:Int^many result:Seq Int^many new-result:Seq Int^many j:Int^many -- ρ final:Seq Int^many val:Int^many)
  locals { i result new-result j val } {
    i j prim <
    [
      result i prim seq-int.at new-result prim seq-int.push
      i 1 prim + result new-result j insert-copy-until val
    ]
    [ new-result val ]
    if
  };

: insert-copy-rest
  (forall ρ; ρ new-result:Seq Int^many j:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { new-result j result val } {
    j result prim seq-int.len prim <
    [
      new-result val prim seq-int.push
      new-result j result insert-copy-rest val
    ]
    [ new-result val prim seq-int.push ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs process-ledger
  };

: process-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      dup balance prim + 0 prim <
      [ drop rejected 1 prim + ]
      [ balance prim + rejected ]
      if
      i 1 prim + txs process-ledger
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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole process-batch
  };

: process-batch
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      stock allocated reasons allocate-item
      i 1 prim + items qtys whole process-batch
    ]
    [ stock allocated reasons ]
    if
  };

: allocate-item
  (forall ρ; ρ item:Int^many qty:Int^many fill-whole:Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ new-stock:Seq Int^many new-allocated:Seq Int^many new-reasons:Seq Int^many)
  locals { item qty fill-whole stock allocated reasons } {
    stock item prim seq-int.at
    dup qty prim <
    [
      0 prim =
      [ 0 allocated prim seq-int.push reasons 2 prim seq-int.push ]
      [
        fill-whole
        [ 0 allocated prim seq-int.push reasons 3 prim seq-int.push ]
        [ dup allocated prim seq-int.push reasons 1 prim seq-int.push ]
        if
      ]
      if
    ]
    [ qty allocated prim seq-int.push reasons 0 prim seq-int.push ]
    if
    stock item prim seq-int.at qty prim - item update-stock
  };

: update-stock
  (forall ρ; ρ new-val:Int^many item:Int^many stock:Seq Int^many -- ρ updated:Seq Int^many)
  locals { new-val item stock } {
    item 0 prim =
    [ prim seq-int.empty new-val prim seq-int.push 1 stock copy-rest-stock ]
    [ stock 0 prim seq-int.at prim seq-int.empty prim seq-int.push item 1 prim - new-val stock update-stock ]
    if
  };

: copy-rest-stock
  (forall ρ; ρ i:Int^many stock:Seq Int^many new-stock:Seq Int^many -- ρ final:Seq Int^many)
  locals { i stock new-stock } {
    i stock prim seq-int.len prim <
    [
      new-stock stock i prim seq-int.at prim seq-int.push
      i 1 prim + stock new-stock copy-rest-stock
    ]
    [ new-stock ]
    if
  };
```
