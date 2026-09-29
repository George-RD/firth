### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 loop-sum };

: loop-sum
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i }
  i xs prim seq-int.len prim <
  [
    acc i xs prim seq-int.at prim + locals { acc2 }
    { acc2 xs i 1 prim + loop-sum }
  ]
  [ acc ]
  if;
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs }
  0 xs prim seq-int.at xs 1 loop-max-inner;

: loop-max-inner
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { val }
    val max prim <
    [ max ]
    [ val ]
    if
    locals { new-max }
    { new-max xs i 1 prim + loop-max-inner }
  ]
  [ max ]
  if;
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 xs k 0 loop-count-below };

: loop-count-below
  (forall ρ; ρ acc:Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs k i }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { val }
    val k prim <
    [ acc 1 prim + ]
    [ acc ]
    if
    locals { new-acc }
    { new-acc xs k i 1 prim + loop-count-below }
  ]
  [ acc ]
  if;
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 loop-index-of };

: loop-index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { val }
    val x prim =
    [ i ]
    [ xs x i 1 prim + loop-index-of ]
    if
  ]
  [ -1 ]
  if;
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs }
  prim seq-int.empty xs xs prim seq-int.len 1 prim - loop-reverse;

: loop-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i }
  i 0 prim <
  []
  [
    result xs i prim seq-int.at prim seq-int.push locals { new-result }
    { new-result xs i 1 prim - loop-reverse }
  ]
  if;
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 loop-prefix };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result acc xs i }
  i xs prim seq-int.len prim <
  [
    acc i xs prim seq-int.at prim + locals { new-acc }
    result new-acc prim seq-int.push locals { new-result }
    { new-result new-acc xs i 1 prim + loop-prefix }
  ]
  [ result ]
  if;
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 loop-keep-positive };

: loop-keep-positive
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { val }
    val 0 prim <
    [ result ]
    [ result val prim seq-int.push ]
    if
    locals { new-result }
    { new-result xs i 1 prim + loop-keep-positive }
  ]
  [ result ]
  if;
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs }
  xs prim seq-int.len 1 prim <
  [ true ]
  [ xs 0 true loop-is-sorted ]
  if;

: loop-is-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Bool^many -- ρ result:Bool^many)
  locals { xs i result }
  result prim not
  [ false ]
  [
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { curr }
      i 1 prim - xs prim seq-int.at locals { prev }
      prev curr prim <
      [ prev curr prim = ]
      [ false ]
      if
      locals { next-result }
      { xs i 1 prim + next-result loop-is-sorted }
    ]
    [ true ]
    if
  ]
  if;
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 xs ys 0 loop-dot };

: loop-dot
  (forall ρ; ρ acc:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs ys i }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { x }
    i ys prim seq-int.at locals { y }
    acc x y prim * prim + locals { new-acc }
    { new-acc xs ys i 1 prim + loop-dot }
  ]
  [ acc ]
  if;
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 true loop-all-true };

: loop-all-true
  (forall ρ; ρ flags:Seq Bool^many i:Int^many result:Bool^many -- ρ result:Bool^many)
  locals { flags i result }
  result prim not
  [ false ]
  [
    i flags prim seq-bool.len prim <
    [
      i flags prim seq-bool.at locals { val }
      val
      [ flags i 1 prim + true loop-all-true ]
      [ false ]
      if
    ]
    [ true ]
    if
  ]
  if;
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs }
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ xs 0 xs prim seq-int.at 1 1 loop-longest ]
  if;

: loop-longest
  (forall ρ; ρ xs:Seq Int^many i:Int^many curr-val:Int^many curr-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i curr-val curr-run max-run }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { next-val }
    next-val curr-val prim =
    [
      curr-run 1 prim + max-run prim <
      [ xs i 1 prim + next-val curr-run 1 prim + curr-run 1 prim + loop-longest ]
      [ xs i 1 prim + next-val curr-run 1 prim + max-run loop-longest ]
      if
    ]
    [
      curr-run max-run prim <
      [ xs i 1 prim + next-val 1 max-run loop-longest ]
      [ xs i 1 prim + next-val 1 curr-run loop-longest ]
      if
    ]
    if
  ]
  [
    curr-run max-run prim <
    [ max-run ]
    [ curr-run ]
    if
  ]
  if;
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 false loop-has-pair };

: loop-has-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target i found }
  found
  [ true ]
  [
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { xi }
      { xi xs target i 1 prim + 0 loop-has-pair-inner }
    ]
    [ false ]
    if
  ]
  if;

: loop-has-pair-inner
  (forall ρ; ρ xi:Int^many xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xi xs target i j }
  j xs prim seq-int.len prim <
  [
    j xs prim seq-int.at locals { xj }
    j i prim =
    [ xi xs target i j 1 prim + loop-has-pair-inner ]
    [
      xi xj prim + target prim =
      [ true ]
      [ xi xs target i j 1 prim + loop-has-pair-inner ]
      if
    ]
    if
  ]
  [ xs target i 1 prim + false loop-has-pair ]
  if;
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 loop-count-distinct };

: loop-count-distinct
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { val }
    xs val 0 i loop-count-distinct-found
    [ xs i 1 prim + count 1 prim + loop-count-distinct ]
    [ xs i 1 prim + count loop-count-distinct ]
    if
  ]
  [ count ]
  if;

: loop-count-distinct-found
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs val j i }
  j i prim <
  [
    j xs prim seq-int.at locals { curr }
    curr val prim =
    [ true ]
    [ xs val j 1 prim + i loop-count-distinct-found ]
    if
  ]
  [ false ]
  if;
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { result xs ys i j }
  i xs prim seq-int.len prim <
  [
    j ys prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { xi }
      j ys prim seq-int.at locals { yj }
      xi yj prim <
      [ result xi prim seq-int.push locals { new-result } { new-result xs ys i 1 prim + j loop-merge } ]
      [ result yj prim seq-int.push locals { new-result } { new-result xs ys i j 1 prim + loop-merge } ]
      if
    ]
    [
      i xs prim seq-int.at prim seq-int.push locals { new-result }
      { new-result xs ys i 1 prim + j loop-merge }
    ]
    if
  ]
  [
    j ys prim seq-int.len prim <
    [
      j ys prim seq-int.at prim seq-int.push locals { new-result }
      { new-result xs ys i j 1 prim + loop-merge }
    ]
    [ result ]
    if
  ]
  if;
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n }
  n 0 prim =
  [ { 0 } ]
  [ n loop-digits-build prim seq-int.empty swap loop-digits-reverse ]
  if;

: loop-digits-build
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result }
  n 0 prim =
  [ result ]
  [
    n 10 prim mod locals { digit }
    result digit prim seq-int.push locals { new-result }
    { n 10 prim div new-result loop-digits-build }
  ]
  if;

: loop-digits-reverse
  (forall ρ; ρ result:Seq Int^many reversed:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result reversed i }
  i 0 prim <
  [ reversed ]
  [
    i result prim seq-int.at prim seq-int.push locals { new-reversed }
    { new-reversed i 1 prim - loop-digits-reverse }
  ]
  if;
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many p:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result p n }
  p n prim <
  [
    p is-prime
    [ result p prim seq-int.push locals { new-result } { new-result p 1 prim + n loop-primes } ]
    [ result p 1 prim + n loop-primes ]
    if
  ]
  [ result ]
  if;

: is-prime
  (forall ρ; ρ p:Int^many -- ρ result:Bool^many)
  locals { p }
  p 2 prim <
  [ false ]
  [
    p 2 prim =
    [ true ]
    [ p 2 loop-is-prime-check ]
    if
  ]
  if;

: loop-is-prime-check
  (forall ρ; ρ p:Int^many d:Int^many -- ρ result:Bool^many)
  locals { p d }
  d d prim * p prim <
  [
    p d prim mod 0 prim =
    [ false ]
    [ p d 1 prim + loop-is-prime-check ]
    if
  ]
  [ true ]
  if;
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k loop-histogram-init locals { counts } { counts xs k 0 loop-histogram-fill } };

: loop-histogram-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result i k }
  i k prim <
  [ result 0 prim seq-int.push locals { new-result } { new-result i 1 prim + k loop-histogram-init } ]
  [ result ]
  if;

: loop-histogram-fill
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs k i }
  i xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { v }
    v counts prim seq-int.at 1 prim + locals { new-count }
    counts v new-count prim seq-int.set locals { new-counts }
    { new-counts xs k i 1 prim + loop-histogram-fill }
  ]
  [ counts ]
  if;
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 loop-sort };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i }
  i xs prim seq-int.len prim <
  [
    xs i loop-sort-inner
  ]
  [ xs ]
  if;

: loop-sort-inner
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i }
  i 1 prim + xs prim seq-int.len prim <
  [
    i xs prim seq-int.at locals { xi }
    i 1 prim + xs prim seq-int.at locals { xj }
    xi xj prim <
    [ xs i loop-sort-inner ]
    [
      i xj prim seq-int.set locals { swapped1 }
      i 1 prim + xi prim seq-int.set locals { xs2 }
      { xs2 i loop-sort-inner }
    ]
    if
  ]
  [ xs ]
  if;
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 loop-ledger };

: loop-ledger
  (forall ρ; ρ balance:Int^many txs:Seq Int^many rejected:Int^many i:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs rejected i }
  i txs prim seq-int.len prim <
  [
    i txs prim seq-int.at locals { tx }
    balance tx prim + locals { new-bal }
    new-bal 0 prim <
    [ balance txs rejected 1 prim + i 1 prim + loop-ledger ]
    [ new-bal txs rejected i 1 prim + loop-ledger ]
    if
  ]
  [ balance rejected ]
  if;
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty items qtys whole 0 loop-allocate };

: loop-allocate
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole j }
  j items prim seq-int.len prim <
  [
    j items prim seq-int.at locals { item }
    j qtys prim seq-int.at locals { qty }
    j whole prim seq-bool.at locals { whole-flag }
    item stock prim seq-int.at locals { stock-qty }
    qty stock-qty prim <
    [
      stock qty prim seq-int.set locals { new-stock }
      allocated qty prim seq-int.push locals { new-allocated }
      reasons 0 prim seq-int.push locals { new-reasons }
      { new-stock new-allocated new-reasons items qtys whole j 1 prim + loop-allocate }
    ]
    [
      stock-qty 0 prim =
      [
        allocated 0 prim seq-int.push locals { new-allocated }
        reasons 2 prim seq-int.push locals { new-reasons }
        { stock new-allocated new-reasons items qtys whole j 1 prim + loop-allocate }
      ]
      [
        whole-flag
        [
          allocated 0 prim seq-int.push locals { new-allocated }
          reasons 3 prim seq-int.push locals { new-reasons }
          { stock new-allocated new-reasons items qtys whole j 1 prim + loop-allocate }
        ]
        [
          stock stock-qty prim seq-int.set locals { new-stock }
          allocated stock-qty prim seq-int.push locals { new-allocated }
          reasons 1 prim seq-int.push locals { new-reasons }
          { new-stock new-allocated new-reasons items qtys whole j 1 prim + loop-allocate }
        ]
        if
      ]
      if
    ]
    if
  ]
  [ stock allocated reasons ]
  if;
```
