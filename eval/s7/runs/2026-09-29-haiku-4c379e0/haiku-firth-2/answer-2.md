### task: seq-sum
```firth
: sum-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at acc prim +
      sum-acc
    ] [
      acc
    ] if
  };

: main
  ( -- result:Int^many)
  locals { xs } {
    xs 0 0
    sum-acc
  };
```

### task: seq-max
```firth
: max-val
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [ b ] [ a ] if
  };

: max-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at max max-val
      max-acc
    ] [
      max
    ] if
  };

: main
  ( -- result:Int^many)
  locals { xs } {
    xs 0 xs 0 prim seq-int.at
    max-acc
  };
```

### task: count-below
```firth
: count-acc
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim < [
      xs
      k
      i 1 prim +
      xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if
      count-acc
    ] [
      count
    ] if
  };

: main
  (-- result:Int^many)
  locals { k xs } {
    xs k 0 0
    count-acc
  };
```

### task: index-of
```firth
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        xs
        x
        i 1 prim +
        index-loop
      ] if
    ] [
      -1
    ] if
  };

: main
  (-- result:Int^many)
  locals { x xs } {
    xs x 0
    index-loop
  };
```

### task: reverse
```firth
: reverse-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [
      result
    ] [
      xs
      i -1 prim +
      xs i prim seq-int.at result prim seq-int.push
      reverse-acc
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len -1 prim + prim seq-int.empty
    reverse-acc
  };
```

### task: prefix-sums
```firth
: prefix-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at sum prim +
      dup
      result prim seq-int.push
      prefix-acc
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty
    prefix-acc
  };
```

### task: keep-positive
```firth
: keep-positive-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at dup 0 prim < prim not [
        result prim seq-int.push
      ] [
        drop result
      ] if
      keep-positive-acc
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty
    keep-positive-acc
  };
```

### task: is-sorted
```firth
: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len -1 prim + prim < [
      xs i -1 prim + prim seq-int.at xs i prim seq-int.at prim < [
        false
      ] [
        xs
        i 1 prim +
        is-sorted-loop
      ] if
    ] [
      true
    ] if
  };

: main
  (-- result:Bool^many)
  locals { xs } {
    xs 0
    is-sorted-loop
  };
```

### task: dot
```firth
: max-val
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [ b ] [ a ] if
  };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim < [
      xs
      ys
      i 1 prim +
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      dot-loop
    ] [
      sum
    ] if
  };

: main
  (-- result:Int^many)
  locals { ys xs } {
    xs ys 0 0
    dot-loop
  };
```

### task: all-true
```firth
: all-true-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim < [
      flags i prim seq-bool.at prim not [
        false
      ] [
        flags
        i 1 prim +
        all-true-loop
      ] if
    ] [
      true
    ] if
  };

: main
  (-- result:Bool^many)
  locals { flags } {
    flags 0
    all-true-loop
  };
```

### task: longest-run
```firth
: max-val
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [ b ] [ a ] if
  };

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i current-run max-run } {
    i xs prim seq-int.len prim < [
      i 0 prim = [
        xs
        i 1 prim +
        1
        0
        longest-run-loop
      ] [
        xs i -1 prim + prim seq-int.at xs i prim seq-int.at prim = [
          xs
          i 1 prim +
          current-run 1 prim +
          max-run
          longest-run-loop
        ] [
          xs
          i 1 prim +
          1
          current-run max-run max-val
          longest-run-loop
        ] if
      ] if
    ] [
      current-run max-run max-val
    ] if
  };

: main
  (-- result:Int^many)
  locals { xs } {
    xs 0 0 0
    longest-run-loop
  };
```

### task: has-pair-sum
```firth
: has-pair-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs target i -1 prim +
      has-pair-inner [
        true
      ] [
        xs
        target
        i 1 prim +
        has-pair-outer
      ] if
    ] [
      false
    ] if
  };

: has-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target j } {
    j 0 prim < [
      false
    ] [
      xs j prim seq-int.at xs j -1 prim + prim seq-int.at prim + target prim = [
        true
      ] [
        xs
        target
        j -1 prim +
        has-pair-inner
      ] if
    ] if
  };

: main
  (-- result:Bool^many)
  locals { target xs } {
    xs target 0
    has-pair-outer
  };
```

### task: count-distinct
```firth
: count-distinct-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i seen count } {
    i xs prim seq-int.len prim < [
      xs xs i prim seq-int.at seen i -1 prim +
      has-in-seen [
        xs
        i 1 prim +
        seen
        count
        count-distinct-outer
      ] [
        xs
        i 1 prim +
        seen xs i prim seq-int.at prim seq-int.push
        count 1 prim +
        count-distinct-outer
      ] if
    ] [
      count
    ] if
  };

: has-in-seen
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target j } {
    j 0 prim < [
      false
    ] [
      xs j prim seq-int.at target prim = [
        true
      ] [
        xs
        target
        j -1 prim +
        has-in-seen
      ] if
    ] if
  };

: main
  (-- result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty 0
    count-distinct-outer
  };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          xs
          ys
          i 1 prim +
          j
          result xs i prim seq-int.at prim seq-int.push
          merge-loop
        ] [
          xs
          ys
          i
          j 1 prim +
          result ys j prim seq-int.at prim seq-int.push
          merge-loop
        ] if
      ] [
        xs
        ys
        i 1 prim +
        j
        result xs i prim seq-int.at prim seq-int.push
        merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        xs
        ys
        i
        j 1 prim +
        result ys j prim seq-int.at prim seq-int.push
        merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { ys xs } {
    xs ys 0 0 prim seq-int.empty
    merge-loop
  };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result prim seq-int.len 0 prim = [ { 0 } ] [ result ] if
    ] [
      n 0 prim < [
        result
      ] [
        n 10 prim mod result prim seq-int.push
        n 10 prim div
        digits-loop
      ] if
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { n } {
    n prim seq-int.empty
    digits-loop
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [
      n 2 prim = [ true ] [
        n 2 prim mod 0 prim = [ false ] [
          n 3 is-prime-check
        ] if
      ] if
    ] if
  };

: is-prime-check
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim < [
      n i prim mod 0 prim = [ false ] [
        n i 2 prim + is-prime-check
      ] if
    ] [
      true
    ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    i n prim < [
      i is-prime [
        n
        i 1 prim +
        result i prim seq-int.push
        primes-loop
      ] [
        n
        i 1 prim +
        result
        primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty
    primes-loop
  };
```

### task: histogram
```firth
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i result } {
    i xs prim seq-int.len prim < [
      xs
      k
      i 1 prim +
      xs i prim seq-int.at dup
      result prim seq-int.at
      1 prim +
      prim seq-int.set
      histogram-loop
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { k xs } {
    xs k 0 prim seq-int.empty
    histogram-loop
  };
```

### task: sort
```firth
: insert-sorted
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i 0 prim = [
      sorted x prim seq-int.push
    ] [
      sorted i -1 prim + prim seq-int.at x prim < [
        sorted x prim seq-int.push
      ] [
        x sorted i -1 prim +
        insert-sorted
        i -1 prim + prim seq-int.at prim seq-int.set
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at result result prim seq-int.len
      insert-sorted
      sort-loop
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty
    sort-loop
  };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim < [
      balance txs i prim seq-int.at prim +
      dup 0 prim < [
        drop
        balance
        rejected 1 prim +
      ] [
        swap drop
        rejected
      ] if
      i 1 prim +
      ledger-loop
    ] [
      balance rejected
    ] if
  };

: main
  (-- balance:Int^many rejected:Int^many)
  locals { txs start } {
    start txs 0 0
    ledger-loop
  };
```

### task: allocate-batch
```firth
: allocate-one
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item qty whole } {
    stock item prim seq-int.at
    qty prim - dup 0 prim < [
      drop qty 0 prim = [ 2 ] [ whole [ 3 ] [ 1 ] if ] if
      qty stock item prim seq-int.at prim - prim seq-int.set
      stock
    ] [
      0 prim = [ stock qty item prim seq-int.at prim - prim seq-int.set 0 ] [
        0
      ] if
    ] if
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim < [
      stock items i prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at allocate-one
      i 1 prim +
      allocated prim seq-int.push
      reasons prim seq-int.push
      allocate-loop
    ] [
      stock allocated reasons
    ] if
  };

: main
  (-- stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty
    allocate-loop
  };
```
