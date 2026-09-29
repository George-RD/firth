### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    [ i xs prim seq-int.len prim < ] [
      acc xs i prim seq-int.at prim +
      xs
      i 1 prim +
      sum-loop
    ] [ acc ] if
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
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ max prim < ] [ ] if
      [ max swap ] [ ] if
      xs
      i 1 prim +
      max-loop
    ] [ max ] if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } { 0 xs 0 count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ swap prim < ] [ ] if
      xs
      i 1 prim +
      count-loop
    ] [ acc ] if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } { xs 0 x find-loop };

: find-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ result:Int^many)
  locals { x i xs } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at x prim =
      [ i ] [ xs i 1 prim + x find-loop ] if
    ] [ -1 ] if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    [ i 0 prim < ] [
      xs i prim seq-int.at
      result swap prim seq-int.push
      i 1 prim -
      reverse-loop
    ] [ result ] if
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
    [ i xs prim seq-int.len prim < ] [
      sum xs i prim seq-int.at prim +
      result swap prim seq-int.push
      xs
      i 1 prim +
      prefix-loop
    ] [ result ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 filter-loop };

: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ result swap prim seq-int.push ] [ drop ] if
      xs
      i 1 prim +
      filter-loop
    ] [ result ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    [ xs prim seq-int.len 1 prim < ] [ true ] [
      xs 0 xs 1 check-sorted
    ] if
  };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      [ prim < prim not ] [ true ] if
      [ xs i 1 prim + check-sorted ] [ false ] if
    ] [ true ] if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs } { 0 xs ys 0 dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs ys i } {
    [ i xs prim seq-int.len prim < ] [
      acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      xs
      ys
      i 1 prim +
      dot-loop
    ] [ acc ] if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true flags 0 all-loop };

: all-loop
  (forall ρ; ρ acc:Bool^many flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { acc flags i } {
    [ i flags prim seq-bool.len prim < ] [
      acc flags i prim seq-bool.at prim and
      flags
      i 1 prim +
      all-loop
    ] [ acc ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    [ xs prim seq-int.len 0 prim = ] [ 0 ] [
      1 xs 0 prim seq-int.at 1 1 run-loop
    ] if
  };

: run-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many prev:Int^many current:Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs prev current i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      [ prev prim = ] [
        current 1 prim +
        xs
        xs i prim seq-int.at
        [ current 1 prim + max prim < ] [ max ] [ current 1 prim + ] if
        i 1 prim +
        run-loop
      ] [
        xs
        xs i prim seq-int.at
        1
        [ current max prim < ] [ max ] [ current ] if
        i 1 prim +
        run-loop
      ] if
    ] [ [ current max prim < ] [ max ] [ current ] if ] if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } { false xs target 0 pair-loop };

: pair-loop
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { found xs target i } {
    [ found prim not i xs prim seq-int.len prim < prim and ] [
      xs i prim seq-int.at
      xs xs prim seq-int.len 1 prim - inner-check
      xs
      target
      [ true ] [ i 1 prim + pair-loop ] if
    ] [ found ] if
  };

: inner-check
  (forall ρ; ρ xs:Seq Int^many target:Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target val j } {
    [ j 0 prim < prim not ] [
      xs j prim seq-int.at val prim + target prim =
      [ true ] [ j 1 prim - inner-check ] if
    ] [ false ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      xs i 1 prim + is-new-value
      [ count 1 prim + ] [ count ] if
      xs
      i 1 prim +
      distinct-loop
    ] [ count ] if
  };

: is-new-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs val j } {
    [ j 0 prim < ] [
      j 1 prim -
      xs swap prim seq-int.at val prim =
      [ false ] [ j 2 prim - is-new-value ] if
    ] [ true ] if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ final:Seq Int^many)
  locals { result xs ys i j } {
    [ i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and ] [
      xs i prim seq-int.at
      ys j prim seq-int.at
      [ prim < ] [ ] if
      [ result swap prim seq-int.push xs ys i 1 prim + j merge-loop ] [
        result swap prim seq-int.push xs ys i j 1 prim + merge-loop
      ] if
    ] [
      [ i xs prim seq-int.len prim < ] [
        result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
      ] [
        [ j ys prim seq-int.len prim < ] [
          result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
        ] [ result ] if
      ] if
    ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    [ n 0 prim = ] [ { 0 } ] [
      n digits-helper
    ] if
  };

: digits-helper
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  [ n 0 prim = prim not ] [
    n 10 prim mod
    n 10 prim div
    digits-helper
    prim seq-int.push
  ] [ prim seq-int.empty ] if;
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    [ candidate n prim < ] [
      candidate is-prime
      [ result candidate prim seq-int.push ] [ result ] if
      candidate 1 prim +
      n
      primes-loop
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many -- ρ result:Bool^many)
  locals { candidate } {
    [ candidate 2 prim < ] [ false ] [
      [ candidate 2 prim = ] [ true ] [
        candidate 2 check-prime
      ] if
    ] if
  };

: check-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { candidate divisor } {
    [ divisor divisor prim * candidate prim < ] [
      candidate divisor prim mod 0 prim =
      [ false ] [ candidate divisor 1 prim + check-prime ] if
    ] [ true ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } {
    prim seq-int.empty 0 build-counts
    xs 0 histogram-loop
  };

: build-counts
  (forall ρ; ρ counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts i } {
    [ i 3 prim < ] [
      counts 0 prim seq-int.push
      i 1 prim +
      build-counts
    ] [ counts ] if
  };

: histogram-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at
      counts swap prim seq-int.at 1 prim +
      counts swap prim seq-int.set
      xs
      i 1 prim +
      histogram-loop
    ] [ counts ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 sort-loop
  };

: sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    [ i xs prim seq-int.len prim < ] [
      result xs i prim seq-int.at insert-sorted
      xs
      i 1 prim +
      sort-loop
    ] [ result ] if
  };

: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ sorted:Seq Int^many)
  locals { result val } {
    result result prim seq-int.len val insert-position
  };

: insert-position
  (forall ρ; ρ result:Seq Int^many pos:Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result pos val } {
    result val prim seq-int.push
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    [ i txs prim seq-int.len prim < ] [
      balance txs i prim seq-int.at
      [ prim < ] [ ] if
      [ balance rejected txs i 1 prim + ledger-loop ] [
        balance txs i prim seq-int.at prim +
        rejected
        txs
        i 1 prim +
        ledger-loop
      ] if
    ] [ balance rejected ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } {
    stock prim seq-int.empty prim seq-int.empty 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i } {
    [ i items prim seq-int.len prim < ] [
      items i prim seq-int.at
      stock swap prim seq-int.at
      qtys i prim seq-int.at
      [ prim < ] [ ] if
      [ allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push stock i prim seq-int.at qtys i prim seq-int.at prim - stock swap prim seq-int.set items qtys whole i 1 prim + allocate-loop ] [
        allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
      ] if
    ] [ stock allocated reasons ] if
  };
```
