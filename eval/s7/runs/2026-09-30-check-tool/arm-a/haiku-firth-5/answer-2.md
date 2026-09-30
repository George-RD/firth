### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at acc prim +
      i 1 prim +
      xs swap sum-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max-val prim <
      [ xs i prim seq-int.at ] [ max-val ] if
      i 1 prim +
      xs swap max-loop
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs xs 0 prim seq-int.at 1 max-loop
  };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [ count 1 prim + ] [ count ] if
      i 1 prim +
      xs k swap count-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };
```

### task: index-of
```firth
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [ i ] [ xs x i 1 prim + find-loop ] if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x 0 find-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs xs prim seq-int.len 1 prim - i prim - prim seq-int.at
      result prim seq-int.push
      i 1 prim +
      xs swap result
      reverse-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { sum } { result sum prim seq-int.push }
      i 1 prim +
      xs swap sum
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty 0 prefix-loop
  };
```

### task: keep-positive
```firth
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup 0 prim <
      [ drop result ] [ result swap prim seq-int.push ] if
      i 1 prim +
      xs swap result
      filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 filter-loop
  };
```

### task: is-sorted
```firth
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ] [ xs i 1 prim + check-sorted ] if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 check-sorted
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      sum prim +
      i 1 prim +
      xs ys swap sum
      dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };
```

### task: all-true
```firth
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [ flags i 1 prim + check-all ] [ false ] if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags 0 check-all
  };
```

### task: is-sorted
```firth
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ] [ xs i 1 prim + check-sorted ] if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 check-sorted
  };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many reversed:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result i reversed } {
    i result prim seq-int.len prim <
    [
      result result prim seq-int.len 1 prim - i prim - prim seq-int.at
      reversed prim seq-int.push
      i 1 prim +
      result i reversed
      reverse-digits
    ]
    [ reversed ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      n prim seq-int.empty digits-loop
      dup prim seq-int.len 0 prim > swap 0 prim seq-int.empty reverse-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ p:Int^many i:Int^many -- ρ result:Bool^many)
  locals { p i } {
    i i prim * p prim <
    [ i 2 prim < [ i 1 prim + p swap is-prime ] [ false ] if ]
    [ true ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <
    [
      i 2 prim <
      [ result i 1 prim + n swap result primes-loop ]
      [ i 2 prim is-prime [ result i prim seq-int.push i 1 prim + n swap result primes-loop ] [ i 1 prim + n swap result primes-loop ] if ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n prim seq-int.empty 2 primes-loop
  };
```

### task: sort
```firth
: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ result-out:Seq Int^many)
  locals { result val i } {
    i result prim seq-int.len prim <
    [
      result i prim seq-int.at val prim <
      [
        result val prim seq-int.push
        i 1 prim + result val insert-sorted
      ]
      [ i 1 prim + result val insert-sorted ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result swap insert-sorted
      i 1 prim +
      xs swap result
      sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 sort-loop
  };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance-out:Int^many rejected-out:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at balance prim + dup 0 prim <
      [ drop txs i 1 prim + balance rejected 1 prim + ledger-loop ]
      [ balance swap prim + txs i 1 prim + balance swap rejected ledger-loop ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs 0 start 0 ledger-loop
  };
```
