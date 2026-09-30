### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    i xs prim seq-int.len prim >= [
      acc
    ] [
      xs i prim seq-int.at acc prim + xs i 1 prim + sum-loop
    ] if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 max-loop };

: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim >= [
      max
    ] [
      xs i prim seq-int.at max prim > [
        xs i prim seq-int.at xs i 1 prim + max-loop
      ] [
        max xs i 1 prim + max-loop
      ] if
    ] if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 xs k 0 count-loop };

: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs k i } {
    i xs prim seq-int.len prim >= [
      count
    ] [
      xs i prim seq-int.at k prim < [
        count 1 prim + xs k i 1 prim + count-loop
      ] [
        count xs k i 1 prim + count-loop
      ] if
    ] if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-loop };

: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim >= [
      -1
    ] [
      xs i prim seq-int.at x prim = [
        i
      ] [
        xs x i 1 prim + index-loop
      ] if
    ] if
  };
```

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
      xs i prim seq-int.at result prim seq-int.push xs i 1 prim + reverse-loop
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
      xs i prim seq-int.at sum prim + dup result prim seq-int.push xs i 1 prim + prefix-loop
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
      xs i prim seq-int.at [ xs i prim seq-int.at result prim seq-int.push ] [ result ] if xs i 1 prim + keep-loop
    ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 is-sorted-loop };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >= [
      true
    ] [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [
        xs i 1 prim + is-sorted-loop
      ] [
        false
      ] if
    ] if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 xs ys 0 dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { sum xs ys i } {
    i xs prim seq-int.len prim >= [
      sum
    ] [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + xs ys i 1 prim + dot-loop
    ] if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-true-loop };

: all-true-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim >= [
      true
    ] [
      flags i prim seq-bool.at [
        flags i 1 prim + all-true-loop
      ] [
        false
      ] if
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

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 0 pair-loop };

: pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    i xs prim seq-int.len prim >= [
      false
    ] [
      j xs prim seq-int.len prim >= [
        xs target i 1 prim + 0 pair-loop
      ] [
        i j prim = [
          xs target i j 1 prim + pair-loop
        ] [
          xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [
            true
          ] [
            xs target i j 1 prim + pair-loop
          ] if
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
      xs i prim seq-int.at seen check-seen [
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

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ final:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim >= [
      j ys prim seq-int.len prim >= [
        result
      ] [
        result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim >= [
        result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim <= [
          result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [
          result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
        ] if
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
      result n 10 prim mod prim seq-int.push n 10 prim div digits-loop
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
      sieve i true prim seq-bool.set i 1 prim + make-sieve
    ] if
  };

: sieve-loop
  (forall ρ; ρ sieve:Seq Bool^many n:Int^many p:Int^many -- ρ result:Seq Bool^many)
  locals { sieve n p } {
    p p prim * n prim > [
      sieve
    ] [
      sieve p prim seq-bool.at [
        sieve p p p prim * mark-loop n p 1 prim + sieve-loop
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
      xs i prim seq-int.at result prim seq-int.at 1 prim + result xs i prim seq-int.at prim seq-int.set xs k i 1 prim + fill-histogram
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
        sorted j 1 prim + insert-value
      ] if
    ] if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim >= [
      balance rejected
    ] [
      balance txs i prim seq-int.at prim + 0 prim < [
        balance rejected 1 prim + txs i 1 prim + ledger-loop
      ] [
        balance txs i prim seq-int.at prim + rejected txs i 1 prim + ledger-loop
      ] if
    ] if
  };
```
