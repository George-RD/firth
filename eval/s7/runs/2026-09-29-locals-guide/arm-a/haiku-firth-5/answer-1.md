### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { sum-loop xs 0 0 };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ total:Int^many)
  locals { xs i sum } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at sum prim +
      sum-loop
    ] [
      sum
    ] if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { 
    xs 0 prim seq-int.at xs 1 max-loop
  };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs i max } {
    i 1 prim + xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i 1 prim + prim seq-int.at dup max prim < [
        drop
      ] [
        swap drop
      ] if
      xs i 2 prim + max-loop
    ] [
      max
    ] if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { count-loop xs k 0 0 };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ count:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at k prim < [
        xs k i count 1 prim + count-loop
      ] [
        xs k i 1 prim + count count-loop
      ] if
    ] [
      count
    ] if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { index-loop xs x 0 };

: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        xs x i 1 prim + index-loop
      ] if
    ] [
      -1
    ] if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs rev-build
  };

: rev-build
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result xs } {
    xs prim seq-int.len 0 prim > [
      xs prim seq-int.len 1 prim - dup xs swap prim seq-int.at result prim seq-int.push
      xs result
      rev-build
    ] [
      result
    ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs ps-build
  };

: ps-build
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim +
      result i prim seq-int.push
      result swap xs i 1 prim + ps-build
    ] [
      result
    ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 keep-loop
  };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup 0 prim < [
        drop result xs i 1 prim + keep-loop
      ] [
        result prim seq-int.push xs i 1 prim + keep-loop
      ] if
    ] [
      result
    ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      xs 0 is-sorted-loop
    ] if
  };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [
        false
      ] [
        xs i 1 prim + is-sorted-loop
      ] if
    ] [
      true
    ] if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { dot-loop xs ys 0 0 };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      xs ys i 1 prim + dot-loop
    ] [
      sum
    ] if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { all-loop flags 0 };

: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim < [
      flags i prim seq-bool.at [
        flags i 1 prim + all-loop
      ] [
        false
      ] if
    ] [
      true
    ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 0 1 1 run-loop
    ] if
  };

: run-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many i:Int^many maxlen:Int^many runlen:Int^many -- ρ length:Int^many)
  locals { xs prev i maxlen runlen } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup prev prim = [
        runlen 1 prim + dup maxlen prim < [
          drop xs i 1 prim + maxlen runlen 1 prim + run-loop
        ] [
          xs i 1 prim + swap run-loop
        ] if
      ] [
        xs i 1 prim + swap 1 maxlen runlen prim < [
          runlen
        ] [
          maxlen
        ] if run-loop
      ] if
    ] [
      maxlen runlen prim < [
        runlen
      ] [
        maxlen
      ] if
    ] if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { has-pair-loop xs target 0 };

: has-pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at xs inner-pair-loop target i 1 prim + has-pair-loop
    ] [
      false
    ] if
  };

: inner-pair-loop
  (forall ρ; ρ xs:Seq Int^many j:Int^many curr:Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs j curr target i } {
    j xs prim seq-int.len prim < [
      j i prim = [
        xs j 1 prim + curr target i inner-pair-loop
      ] [
        xs j prim seq-int.at curr prim + target prim = [
          true
        ] [
          xs j 1 prim + curr target i inner-pair-loop
        ] if
      ] if
    ] [
      xs target i 1 prim + has-pair-loop
    ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 distinct-loop
  };

: distinct-loop
  (forall ρ; ρ dists:Seq Int^many xs:Seq Int^many i:Int^many -- ρ count:Int^many)
  locals { dists xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dists is-in [
        dists xs i 1 prim + distinct-loop
      ] [
        dists prim seq-int.push xs i 1 prim + distinct-loop
      ] if
    ] [
      dists prim seq-int.len
    ] if
  };

: is-in
  (forall ρ; ρ dists:Seq Int^many val:Int^many -- ρ found:Bool^many)
  locals { dists val } {
    dists 0 find-val val
  };

: find-val
  (forall ρ; ρ dists:Seq Int^many i:Int^many val:Int^many -- ρ found:Bool^many)
  locals { dists i val } {
    i dists prim seq-int.len prim < [
      dists i prim seq-int.at val prim = [
        true
      ] [
        dists i 1 prim + val find-val
      ] if
    ] [
      false
    ] if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty xs ys 0 0 merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [
          result prim seq-int.push xs ys i j 1 prim + merge-loop
        ] if
      ] [
        xs i prim seq-int.at result prim seq-int.push xs ys i 1 prim + j merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + merge-loop
      ] [
        result
      ] if
    ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n prim seq-int.empty digit-loop
    ] if
  };

: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim > [
      n 10 prim mod result prim seq-int.push n 10 prim div digit-loop
    ] [
      result reverse-seq
    ] if
  };

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - rev-seq-loop
  };

: rev-seq-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.push xs i 1 prim - rev-seq-loop
    ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 1 prim < [
      prim seq-int.empty
    ] [
      prim seq-int.empty 2 n prime-loop
    ] if
  };

: prime-loop
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { primes candidate limit } {
    candidate limit prim < [
      candidate is-prime [
        primes candidate prim seq-int.push candidate 1 prim + limit prime-loop
      ] [
        primes candidate 1 prim + limit prime-loop
      ] if
    ] [
      candidate limit prim = [
        candidate is-prime [
          primes candidate prim seq-int.push
        ] [
          primes
        ] if
      ] [
        primes
      ] if
    ] if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim < [
      false
    ] [
      num 2 prim = [
        true
      ] [
        num 2 check-divisor
      ] if
    ] if
  };

: check-divisor
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim < [
      num divisor prim mod 0 prim = [
        false
      ] [
        num divisor 2 prim + check-divisor
      ] if
    ] [
      true
    ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k init-histogram xs 0 hist-loop
  };

: init-histogram
  (forall ρ; ρ counts:Seq Int^many remaining:Int^many -- ρ counts:Seq Int^many)
  locals { counts remaining } {
    remaining 0 prim > [
      counts 0 prim seq-int.push remaining 1 prim - init-histogram
    ] [
      counts
    ] if
  };

: hist-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set
      xs i 1 prim + hist-loop
    ] [
      counts
    ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs sort-insertion
  };

: sort-insertion
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 1 insert-step
  };

: insert-step
  (forall ρ; ρ xs:Seq Int^many sorted:Int^many unsorted:Int^many -- ρ sorted:Seq Int^many)
  locals { xs sorted unsorted } {
    unsorted xs prim seq-int.len prim < [
      xs xs unsorted prim seq-int.at xs sorted 0 find-insert-pos prim seq-int.set
      xs sorted 1 prim + unsorted 1 prim + insert-step
    ] [
      xs
    ] if
  };

: find-insert-pos
  (forall ρ; ρ xs:Seq Int^many val:Int^many pos:Int^many -- ρ xs:Seq Int^many)
  locals { xs val pos } {
    pos 0 prim < [
      xs
    ] [
      xs pos prim seq-int.at val prim < [
        xs val pos find-insert-pos
      ] [
        xs
      ] if
    ] if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 txs 0 ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at balance prim + dup 0 prim < [
        drop balance rejected 1 prim + txs i 1 prim + ledger-loop
      ] [
        balance rejected txs i 1 prim + ledger-loop
      ] if
    ] [
      balance rejected
    ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 allocate-orders
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons order items qtys whole } {
    order qtys prim seq-int.len prim < [
      items order prim seq-int.at dup stock swap prim seq-int.at dup
      qtys order prim seq-int.at dup
      whole order prim seq-bool.at
      process-order
    ] [
      stock alloc reasons
    ] if
  };

: process-order
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many item:Int^many current-stock:Int^many qty:Int^many w:Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons order items qtys whole item current-stock qty w } {
    qty current-stock prim < [
      current-stock 0 prim = [
        alloc 0 prim seq-int.push reasons 2 prim seq-int.push stock item current-stock prim seq-int.set order 1 prim + items qtys whole allocate-orders
      ] [
        w [
          alloc 0 prim seq-int.push reasons 3 prim seq-int.push stock item current-stock prim seq-int.set order 1 prim + items qtys whole allocate-orders
        ] [
          alloc current-stock prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set order 1 prim + items qtys whole allocate-orders
        ] if
      ] if
    ] [
      alloc qty prim seq-int.push reasons 0 prim seq-int.push stock item current-stock qty prim - prim seq-int.set order 1 prim + items qtys whole allocate-orders
    ] if
  };
```
