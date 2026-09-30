### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.push xs i 1 prim + reverse-loop
    ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at sum prim + dup [ result ] dip prim seq-int.push xs i 1 prim + prefix-loop
    ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at [ result xs i prim seq-int.at prim seq-int.push ] [ result ] if xs i 1 prim + keep-loop
    ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim <= [
      0
    ] [
      xs 0 prim seq-int.at 1 1 xs 1 longest-loop
    ] if
  };

: longest-loop
  (forall ρ; ρ max-len:Int^many curr-len:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max-len curr-len xs i } {
    i xs prim seq-int.len prim >= [
      curr-len max-len prim > [ curr-len ] [ max-len ] if
    ] [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [
        max-len curr-len 1 prim + xs i 1 prim + longest-loop
      ] [
        curr-len max-len prim > [
          curr-len 1 1 xs i 1 prim + longest-loop
        ] [
          max-len 1 1 xs i 1 prim + longest-loop
        ] if
      ] if
    ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim >= [
      seen prim seq-int.len
    ] [
      xs i prim seq-int.at seen 0 check-seen [
        xs i 1 prim + seen distinct-loop
      ] [
        xs i prim seq-int.at seen prim seq-int.push xs i 1 prim + distinct-loop
      ] if
    ] if
  };

: check-seen
  (forall ρ; ρ val:Int^many seen:Seq Int^many j:Int^many -- ρ result:Bool^many)
  locals { val seen j } {
    j seen prim seq-int.len prim >= [
      false
    ] [
      seen j prim seq-int.at val prim = [
        true
      ] [
        val seen j 1 prim + check-seen
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
      n 0 prim < [ n 0 prim - ] [ n ] if prim seq-int.empty digits-loop
    ] if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim div result n 10 prim mod prim seq-int.push digits-loop
    ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim < [
      prim seq-int.empty
    ] [
      n 1 prim + prim seq-bool.empty n 0 make-sieve sieve-loop prim seq-int.empty n 2 collect-primes
    ] if
  };

: make-sieve
  (forall ρ; ρ sieve:Seq Bool^many n:Int^many i:Int^many -- ρ result:Seq Bool^many)
  locals { sieve n i } {
    i n prim >= [
      sieve
    ] [
      sieve i true prim seq-bool.set n i 1 prim + make-sieve
    ] if
  };

: sieve-loop
  (forall ρ; ρ sieve:Seq Bool^many n:Int^many p:Int^many -- ρ result:Seq Bool^many)
  locals { sieve n p } {
    p p prim * n prim > [
      sieve
    ] [
      sieve p prim seq-bool.at [
        sieve p p p prim * n mark-loop n p 1 prim + sieve-loop
      ] [
        sieve n p 1 prim + sieve-loop
      ] if
    ] if
  };

: mark-loop
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many multiple:Int^many n:Int^many -- ρ result:Seq Bool^many)
  locals { sieve p multiple n } {
    multiple n prim > [
      sieve
    ] [
      sieve multiple false prim seq-bool.set p multiple prim + mark-loop
    ] if
  };

: collect-primes
  (forall ρ; ρ result:Seq Int^many sieve:Seq Bool^many n:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sieve n i } {
    i n prim > [
      result
    ] [
      sieve i prim seq-bool.at [
        result i prim seq-int.push sieve n i 1 prim + collect-primes
      ] [
        result sieve n i 1 prim + collect-primes
      ] if
    ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty k 0 init-histogram xs k 0 fill-histogram };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result k i } {
    i k prim >= [
      result
    ] [
      result 0 prim seq-int.push k i 1 prim + init-histogram
    ] if
  };

: fill-histogram
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs k i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.at 1 prim + result xs i prim seq-int.at prim seq-int.set xs k i 1 prim + fill-histogram
    ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ sorted:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted xs i } {
    i xs prim seq-int.len prim >= [
      sorted
    ] [
      xs i prim seq-int.at sorted 0 insert-value xs i 1 prim + insertion-sort-loop
    ] if
  };

: insert-value
  (forall ρ; ρ val:Int^many sorted:Seq Int^many j:Int^many -- ρ result2:Seq Int^many)
  locals { val sorted j } {
    j sorted prim seq-int.len prim >= [
      sorted val prim seq-int.push
    ] [
      sorted j prim seq-int.at val prim > [
        sorted j val prim seq-int.set
      ] [
        val sorted j 1 prim + insert-value
      ] if
    ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty items qtys whole 0 process-orders };

: process-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole i } {
    i items prim seq-int.len prim >= [
      stock allocated reasons
    ] [
      items i prim seq-int.at stock qtys i prim seq-int.at whole i prim seq-bool.at stock items i prim seq-int.at prim seq-int.at allocate-one stock items i prim seq-int.at prim seq-int.set allocated prim seq-int.push reasons prim seq-int.push items qtys whole i 1 prim + process-orders
    ] if
  };

: allocate-one
  (forall ρ; ρ item-idx:Int^many qty:Int^many whole:Bool^many curr-stock:Int^many -- ρ alloc-qty:Int^many reason:Int^many)
  locals { item-idx qty whole curr-stock } {
    qty curr-stock prim <= [
      qty 0
    ] [
      curr-stock 0 prim = [
        0 2
      ] [
        whole [
          0 3
        ] [
          curr-stock 1
        ] if
      ] if
    ] if
  };
```
