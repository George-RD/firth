### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 locals { xs } { xs [ 0 prim seq-int.len ] call sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many len:Int^many idx:Int^many -- ρ result:Int^many)
  locals { sum xs len idx }
  idx len prim < [ idx xs prim seq-int.at idx 1 prim + locals { sum xs len idx } { sum idx xs prim seq-int.at prim + swap drop xs swap drop len swap drop idx 1 prim + sum-loop } ] [ sum ] if;
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs }
  xs 0 prim seq-int.at xs 1 xs prim seq-int.len find-max;

: find-max
  (forall ρ; ρ max:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { max xs idx len }
  idx len prim < [
    idx xs prim seq-int.at
    locals { val max xs idx len }
    max val prim < [ val ] [ max ] if
    locals { max xs idx len }
    idx 1 prim + find-max
  ] [ max ] if;
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k }
  0 0 xs prim seq-int.len count-below-loop xs k;

: count-below-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx len xs k }
  idx len prim < [
    idx xs prim seq-int.at locals { val count idx len xs k }
    val k prim < [ count 1 prim + ] [ count ] if
    locals { count idx len xs k }
    idx 1 prim + count-below-loop xs k
  ] [ count ] if;
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x }
  0 xs prim seq-int.len find-index xs x;

: find-index
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx len xs x }
  idx len prim < [
    idx xs prim seq-int.at locals { val idx len xs x }
    val x prim = [ idx ] [ idx 1 prim + find-index xs x ] if
  ] [ -1 ] if;
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs }
  prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop xs;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx }
  idx 0 prim < [ result ] [
    idx xs prim seq-int.at locals { val result xs idx }
    result val prim seq-int.push
    locals { result xs idx }
    idx 1 prim - reverse-loop xs
  ] if;
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs }
  prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop xs;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum idx len xs }
  idx len prim < [
    idx xs prim seq-int.at locals { val result sum idx len xs }
    sum val prim + locals { newsum result idx len xs }
    result newsum prim seq-int.push locals { result idx len xs newsum }
    idx 1 prim + prefix-loop xs
  ] [ result ] if;
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs }
  prim seq-int.empty 0 xs prim seq-int.len keep-pos-loop xs;

: keep-pos-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result idx len xs }
  idx len prim < [
    idx xs prim seq-int.at locals { val result idx len xs }
    val 0 prim < [ result ] [ result val prim seq-int.push ] if
    locals { result idx len xs }
    idx 1 prim + keep-pos-loop xs
  ] [ result ] if;
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs }
  xs prim seq-int.len locals { len xs }
  len 1 prim < [ true ] [ 0 check-sorted xs ] if;

: check-sorted
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { idx xs }
  idx xs prim seq-int.len 1 prim - prim < [
    idx xs prim seq-int.at locals { val idx xs }
    idx 1 prim + xs prim seq-int.at locals { next idx xs }
    val next prim < [ idx 1 prim + check-sorted xs ] [ false ] if
  ] [ true ] if;
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys }
  0 0 xs prim seq-int.len dot-product xs ys;

: dot-product
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs ys }
  idx len prim < [
    idx xs prim seq-int.at idx ys prim seq-int.at prim * locals { prod sum idx len xs ys }
    sum prod prim + locals { sum idx len xs ys }
    idx 1 prim + dot-product xs ys
  ] [ sum ] if;
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags }
  flags prim seq-bool.len locals { len flags }
  len 0 prim = [ true ] [ 0 check-all flags ] if;

: check-all
  (forall ρ; ρ idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { idx flags }
  idx flags prim seq-bool.len prim < [
    idx flags prim seq-bool.at [ idx 1 prim + check-all flags ] [ false ] if
  ] [ true ] if;
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs }
  xs prim seq-int.len locals { len xs }
  len 0 prim = [ 0 ] [ 0 xs prim seq-int.at 1 0 find-longest xs ] if;

: find-longest
  (forall ρ; ρ idx:Int^many prev:Int^many current:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx prev current max xs }
  idx xs prim seq-int.len prim < [
    idx xs prim seq-int.at locals { val idx prev current max xs }
    val prev prim = [
      current 1 prim + locals { current idx prev max xs }
      current max prim < [ max ] [ current ] if
      locals { max idx prev current xs }
      idx 1 prim + find-longest xs
    ] [
      idx 1 prim + find-longest xs
    ] if
  ] [ max ] if;
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target }
  0 xs prim seq-int.len check-pair xs target;

: check-pair
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target }
  i len prim < [
    i 1 prim + check-pair-inner xs target i
  ] [ false ] if;

: check-pair-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { j xs target i }
  j xs prim seq-int.len prim < [
    i j prim = [ j 1 prim + check-pair-inner xs target i ] [
      i xs prim seq-int.at j xs prim seq-int.at prim + locals { sum xs target i j }
      sum target prim = [ true ] [ j 1 prim + check-pair-inner xs target i ] if
    ] if
  ] [ false ] if;
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs }
  0 0 xs prim seq-int.len count-distinct-loop xs;

: count-distinct-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx len xs }
  idx len prim < [
    idx xs prim seq-int.at locals { val count idx len xs }
    val 0 idx check-contains xs [ count ] [ count 1 prim + ] if
    locals { count idx len xs }
    idx 1 prim + count-distinct-loop xs
  ] [ count ] if;

: check-contains
  (forall ρ; ρ val:Int^many start:Int^many end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val start end xs }
  start end prim < [
    start xs prim seq-int.at locals { x val start end xs }
    x val prim = [ true ] [ start 1 prim + check-contains xs val ] if
  ] [ false ] if;
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys }
  prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge-sorted-loop xs ys;

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xlen ylen xs ys }
  i xlen prim < [
    j ylen prim < [
      i xs prim seq-int.at j ys prim seq-int.at locals { xi yj result i j xlen ylen xs ys }
      xi yj prim < [
        result xi prim seq-int.push locals { result i j xlen ylen xs ys }
        i 1 prim + merge-sorted-loop xs ys
      ] [
        result yj prim seq-int.push locals { result i j xlen ylen xs ys }
        j 1 prim + merge-sorted-loop xs ys
      ] if
    ] [
      i xs prim seq-int.at locals { xi result i j xlen ylen xs ys }
      result xi prim seq-int.push locals { result i j xlen ylen xs ys }
      i 1 prim + merge-sorted-loop xs ys
    ] if
  ] [
    j ylen prim < [
      j ys prim seq-int.at locals { yj result i j xlen ylen xs ys }
      result yj prim seq-int.push locals { result i j xlen ylen xs ys }
      j 1 prim + merge-sorted-loop xs ys
    ] [ result ] if
  ] if;
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n }
  n 0 prim = [ { 0 } ] [
    n 0 prim < [ n 0 prim - extract-digits ] [ n extract-digits ]
  ] if;

: extract-digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n }
  prim seq-int.empty n build-digits n;

: build-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n }
  n 0 prim = [ result ] [
    n 10 prim mod locals { d result n }
    result d prim seq-int.push locals { result n }
    n 10 prim div build-digits
  ] if;
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n }
  prim seq-int.empty 2 n find-primes;

: find-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { result candidate limit }
  candidate limit prim < [
    candidate is-prime [ result candidate prim seq-int.push ] [ result ] if
    locals { result candidate limit }
    candidate 1 prim + find-primes
  ] [ result ] if;

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n }
  n 2 prim < [ false ] [
    n 2 prim = [ true ] [
      n 2 prim mod 0 prim = [ false ] [ 2 check-divisors n ] if
    ] if
  ] if;

: check-divisors
  (forall ρ; ρ divisor:Int^many n:Int^many -- ρ result:Bool^many)
  locals { divisor n }
  divisor divisor prim * n prim < [
    n divisor prim mod 0 prim = [ false ] [ divisor 1 prim + check-divisors n ] if
  ] [ true ] if;
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k }
  prim seq-int.empty 0 k build-histogram xs k;

: build-histogram
  (forall ρ; ρ counts:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { counts idx k xs }
  idx k prim < [
    counts 0 prim seq-int.push locals { counts idx k xs }
    idx 1 prim + build-histogram xs k
  ] [
    0 xs prim seq-int.len count-histogram xs k counts
  ] if;

: count-histogram
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i len xs k counts }
  i len prim < [
    i xs prim seq-int.at locals { val i len xs k counts }
    val counts prim seq-int.at 1 prim + locals { newcnt i len xs k counts }
    counts val newcnt prim seq-int.set locals { counts i len xs k }
    i 1 prim + count-histogram xs k counts
  ] [ counts ] if;
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs }
  xs 0 xs prim seq-int.len 1 prim - insertion-sort;

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many start:Int^many end:Int^many -- ρ sorted:Seq Int^many)
  locals { xs start end }
  start end prim < [
    start 1 prim + locals { i xs start end }
    xs i insert-element
    locals { xs start end }
    start 1 prim + insertion-sort xs
  ] [ xs ] if;

: insert-element
  (forall ρ; ρ xs:Seq Int^many pos:Int^many -- ρ xs:Seq Int^many)
  locals { xs pos }
  pos 0 prim > [
    pos xs prim seq-int.at locals { val xs pos }
    pos 1 prim - xs prim seq-int.at locals { prev xs pos }
    prev val prim < [
      xs pos
    ] [
      xs pos prev prim seq-int.set locals { xs pos }
      pos 1 prim - insert-element xs
    ] if
  ] [ xs ] if;
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs }
  start 0 0 txs prim seq-int.len process-txs txs;

: process-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected idx len txs }
  idx len prim < [
    idx txs prim seq-int.at locals { tx balance rejected idx len txs }
    balance tx prim + 0 prim < [
      rejected 1 prim + locals { rejected idx len txs balance }
      idx 1 prim + process-txs txs
    ] [
      balance tx prim + locals { balance idx len txs rejected }
      idx 1 prim + process-txs txs
    ] if
  ] [ balance rejected ] if;
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole }
  stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len process-orders stock items qtys whole;

: process-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons idx len items qtys whole }
  idx len prim < [
    idx items prim seq-int.at locals { item stock allocated reasons idx len items qtys whole }
    item stock prim seq-int.at locals { qty_stock stock allocated reasons idx len items qtys whole }
    idx qtys prim seq-int.at locals { req stock allocated reasons idx len items qtys whole }
    idx whole prim seq-bool.at locals { w stock allocated reasons idx len items qtys whole }
    req qty_stock prim < [
      qty_stock 0 prim = [
        reasons 2 prim seq-int.push allocated 0 prim seq-int.push
      ] [
        w [ reasons 3 prim seq-int.push allocated 0 prim seq-int.push ] [
          reasons 1 prim seq-int.push allocated qty_stock prim seq-int.push stock item 0 prim seq-int.set
        ] if
      ] if
      locals { stock allocated reasons idx len items qtys whole }
      idx 1 prim + process-orders stock items qtys whole
    ] [
      reasons 0 prim seq-int.push allocated req prim seq-int.push stock item qty_stock req prim - prim seq-int.set
      locals { stock allocated reasons idx len items qtys whole }
      idx 1 prim + process-orders stock items qtys whole
    ] if
  ] [ stock allocated reasons ] if;
```
