### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs sum-helper };

: sum-helper
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc idx xs } {
    idx xs prim seq-int.len prim >=
    [ acc ]
    [ xs idx prim seq-int.at acc prim + idx 1 prim + xs sum-helper ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs xs-max-helper };

: xs-max-helper
  (forall ρ; ρ max:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max idx xs } {
    idx xs prim seq-int.len prim >=
    [ max ]
    [ xs idx prim seq-int.at max prim >
      [ xs idx prim seq-int.at idx 1 prim + xs xs-max-helper ]
      [ max idx 1 prim + xs xs-max-helper ]
      if ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k count-helper };

: count-helper
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx xs k } {
    idx xs prim seq-int.len prim >=
    [ count ]
    [ xs idx prim seq-int.at k prim <
      [ count 1 prim + idx 1 prim + xs k count-helper ]
      [ count idx 1 prim + xs k count-helper ]
      if ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x index-helper };

: index-helper
  (forall ρ; ρ idx:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx xs x } {
    idx xs prim seq-int.len prim >=
    [ -1 ]
    [ xs idx prim seq-int.at x prim =
      [ idx ]
      [ idx 1 prim + xs x index-helper ]
      if ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-helper };

: reverse-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs idx } {
    idx 0 prim <=
    [ result ]
    [ idx 1 prim - xs result idx reverse-helper ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-helper };

: prefix-helper
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum idx xs } {
    idx xs prim seq-int.len prim >=
    [ result ]
    [ xs idx prim seq-int.at sum prim + result swap prim seq-int.push idx 1 prim + xs prefix-helper ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs filter-positive };

: filter-positive
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result idx xs } {
    idx xs prim seq-int.len prim >=
    [ result ]
    [ xs idx prim seq-int.at 0 prim >
      [ result xs idx prim seq-int.at prim seq-int.push idx 1 prim + xs filter-positive ]
      [ result idx 1 prim + xs filter-positive ]
      if ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { true 0 xs is-sorted-helper };

: is-sorted-helper
  (forall ρ; ρ ok:Bool^many idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { ok idx xs } {
    ok prim not
    [ false ]
    [ idx xs prim seq-int.len 1 prim - prim >=
      [ ok ]
      [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <= ok prim and idx 1 prim + xs is-sorted-helper ]
      if ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-helper };

: dot-helper
  (forall ρ; ρ sum:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum idx xs ys } {
    idx xs prim seq-int.len prim >=
    [ sum ]
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + idx 1 prim + xs ys dot-helper ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 flags all-true-helper };

: all-true-helper
  (forall ρ; ρ ok:Bool^many idx:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { ok idx flags } {
    ok prim not
    [ false ]
    [ idx flags prim seq-bool.len prim >=
      [ ok ]
      [ flags idx prim seq-bool.at ok prim and idx 1 prim + flags all-true-helper ]
      if ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 0 1 xs longest-run-helper ]
    if
  };

: longest-run-helper
  (forall ρ; ρ maxlen:Int^many runlen:Int^many idx:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { maxlen runlen idx xs } {
    idx xs prim seq-int.len prim >=
    [ maxlen runlen prim > [ runlen ] [ maxlen ] if ]
    [ idx 0 prim =
      [ 1 idx 1 prim + xs longest-run-helper ]
      [ xs idx prim seq-int.at xs idx 1 prim - prim seq-int.at prim =
        [ idx 1 prim + runlen 1 prim + xs longest-run-helper ]
        [ maxlen runlen prim > [ runlen ] [ maxlen ] if idx 1 prim + 1 xs longest-run-helper ]
        if ]
      if ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target has-pair-helper };

: has-pair-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim >=
    [ false ]
    [ i 1 prim + xs target has-inner-loop ]
    if
  };

: has-inner-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim >=
    [ false ]
    [ xs 0 prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + xs target has-inner-loop ]
      if ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs count-distinct-helper };

: count-distinct-helper
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx xs } {
    idx xs prim seq-int.len prim >=
    [ count ]
    [ xs idx prim seq-int.at 0 idx xs is-first-occurrence
      [ count 1 prim + idx 1 prim + xs count-distinct-helper ]
      [ count idx 1 prim + xs count-distinct-helper ]
      if ]
    if
  };

: is-first-occurrence
  (forall ρ; ρ val:Int^many start:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val start idx xs } {
    start idx prim >=
    [ true ]
    [ xs start prim seq-int.at val prim =
      [ false ]
      [ start 1 prim + idx xs is-first-occurrence ]
      if ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-helper };

: merge-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim >=
    [ result j ys prim seq-int.len append-rest j ys ]
    [ j ys prim seq-int.len prim >=
      [ result i xs append-rest ]
      [ xs i prim seq-int.at ys j prim seq-int.at prim <=
        [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys merge-helper ]
        [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys merge-helper ]
        if ]
      if ]
    if
  };

: append-rest
  (forall ρ; ρ result:Seq Int^many idx:Int^many seq:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result idx seq } {
    idx seq prim seq-int.len prim >=
    [ result ]
    [ result seq idx prim seq-int.at prim seq-int.push idx 1 prim + seq append-rest ]
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
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod result swap prim seq-int.push n 10 prim div extract-digits ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n check-primes };

: check-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim >
    [ result ]
    [ i is-prime-num
      [ result i prim seq-int.push i 1 prim + n check-primes ]
      [ result i 1 prim + n check-primes ]
      if ]
    if
  };

: is-prime-num
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 prim =
      [ true ]
      [ n 2 prim mod 0 prim =
        [ false ]
        [ 3 n is-prime-loop ]
        if ]
      if ]
    if
  };

: is-prime-loop
  (forall ρ; ρ i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { i n } {
    i i prim * n prim >
    [ true ]
    [ n i prim mod 0 prim =
      [ false ]
      [ i 2 prim + n is-prime-loop ]
      if ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty k build-zero-seq xs build-histogram };

: build-zero-seq
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ filled:Seq Int^many)
  locals { result k } {
    result prim seq-int.len k prim >=
    [ result ]
    [ result 0 prim seq-int.push k build-zero-seq ]
    if
  };

: build-histogram
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts xs } { counts 0 xs increment-counts };

: increment-counts
  (forall ρ; ρ counts:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts idx xs } {
    idx xs prim seq-int.len prim >=
    [ counts ]
    [ xs idx prim seq-int.at counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set idx 1 prim + xs increment-counts ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs insert-all };

: insert-all
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result idx xs } {
    idx xs prim seq-int.len prim >=
    [ result ]
    [ xs idx prim seq-int.at result insert-sorted idx 1 prim + xs insert-all ]
    if
  };

: insert-sorted
  (forall ρ; ρ val:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { val result } { 0 val result insert-at-pos };

: insert-at-pos
  (forall ρ; ρ pos:Int^many val:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { pos val result } {
    pos result prim seq-int.len prim >=
    [ result val prim seq-int.push ]
    [ result pos prim seq-int.at val prim >
      [ result val prim seq-int.push ]
      [ pos 1 prim + val result insert-at-pos ]
      if ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs apply-transactions };

: apply-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected idx txs } {
    idx txs prim seq-int.len prim >=
    [ balance rejected ]
    [ txs idx prim seq-int.at balance prim + 0 prim <
      [ balance rejected 1 prim + idx 1 prim + txs apply-transactions ]
      [ balance txs idx prim seq-int.at prim + rejected idx 1 prim + txs apply-transactions ]
      if ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-orders };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-list:Seq Int^many reasons-list:Seq Int^many)
  locals { stock allocated reasons order items qtys whole } {
    order items prim seq-int.len prim >=
    [ stock allocated reasons ]
    [ items order prim seq-int.at stock swap prim seq-int.at qtys order prim seq-int.at whole order prim seq-bool.at allocate-single stock allocated reasons order 1 prim + items qtys whole allocate-orders ]
    if
  };

: allocate-single
  (forall ρ; ρ item:Int^many cur-stock:Int^many qty:Int^many is-whole:Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ new-stock:Seq Int^many new-allocated:Seq Int^many new-reasons:Seq Int^many)
  locals { item cur-stock qty is-whole stock allocated reasons } {
    qty cur-stock prim <=
    [ stock item qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push ]
    [ cur-stock 0 prim =
      [ stock allocated reasons 2 prim seq-int.push ]
      [ is-whole
        [ stock allocated reasons 3 prim seq-int.push ]
        [ stock item cur-stock prim seq-int.set allocated cur-stock prim seq-int.push reasons 1 prim seq-int.push ]
        if ]
      if ]
    if
  };
```
