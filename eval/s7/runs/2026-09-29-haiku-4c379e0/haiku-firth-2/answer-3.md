### task: seq-sum
```firth
: sum-from
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at
      xs i 1 prim + sum-from
      prim +
    ] [
      0
    ] if
  };

: main
  ( -- result:Int^many)
  locals { xs } {
    xs 0 sum-from
  };
```

### task: seq-max
```firth
: max-from
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim -1 prim + prim < [
      xs i prim seq-int.at
      xs i 1 prim + max-from
      [ prim < ] [ drop ] if
    ] [
      xs i prim seq-int.at
    ] if
  };

: main
  ( -- result:Int^many)
  locals { xs } {
    xs 0 max-from
  };
```

### task: count-below
```firth
: count-from
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k i } {
    i xs prim seq-int.len prim < [
      xs k i 1 prim + count-from
      xs i prim seq-int.at k prim < [ 1 prim + ] [ ] if
    ] [
      0
    ] if
  };

: main
  (-- result:Int^many)
  locals { k xs } {
    xs k 0 count-from
  };
```

### task: index-of
```firth
: find-from
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        xs x i 1 prim + find-from
      ] if
    ] [
      -1
    ] if
  };

: main
  (-- result:Int^many)
  locals { x xs } {
    xs x 0 find-from
  };
```

### task: reverse
```firth
: reverse-from
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [
      result
    ] [
      xs i prim seq-int.at result prim seq-int.push
      xs i -1 prim + result reverse-from
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len -1 prim + prim seq-int.empty reverse-from
  };
```

### task: prefix-sums
```firth
: prefix-from
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim +
      dup result prim seq-int.push
      xs i 1 prim + (copy of sum at top)
      prefix-from
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-from
  };
```

### task: keep-positive
```firth
: keep-from
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup prim 0 prim < prim not [
        result prim seq-int.push
      ] [
        drop result
      ] if
      xs i 1 prim + result keep-from
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty keep-from
  };
```

### task: is-sorted
```firth
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len -1 prim + prim < [
      xs i -1 prim + prim seq-int.at xs i prim seq-int.at prim < [
        false
      ] [
        xs i 1 prim + check-sorted
      ] if
    ] [
      true
    ] if
  };

: main
  (-- result:Bool^many)
  locals { xs } {
    xs 0 check-sorted
  };
```

### task: dot
```firth
: dot-from
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs ys i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      xs ys i 1 prim + dot-from
      prim +
    ] [
      0
    ] if
  };

: main
  (-- result:Int^many)
  locals { ys xs } {
    xs ys 0 dot-from
  };
```

### task: all-true
```firth
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim < [
      flags i prim seq-bool.at [
        flags i 1 prim + check-all
      ] [
        false
      ] if
    ] [
      true
    ] if
  };

: main
  (-- result:Bool^many)
  locals { flags } {
    flags 0 check-all
  };
```

### task: longest-run
```firth
: find-longest
  (forall ρ; ρ xs:Seq Int^many i:Int^many current:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i current max } {
    i xs prim seq-int.len prim < [
      i prim 0 prim = [
        xs 1 1 0 find-longest
      ] [
        xs i -1 prim + prim seq-int.at xs i prim seq-int.at prim = [
          xs i 1 prim + current 1 prim + max find-longest
        ] [
          xs i 1 prim + 1 current max [ prim < ] [ drop ] if find-longest
        ] if
      ] if
    ] [
      current max [ prim < ] [ drop ] if
    ] if
  };

: main
  (-- result:Int^many)
  locals { xs } {
    xs 0 0 0 find-longest
  };
```

### task: has-pair-sum
```firth
: search-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target j } {
    j 0 prim < [
      false
    ] [
      xs j prim seq-int.at xs j -1 prim + prim seq-int.at prim + target prim = [
        true
      ] [
        xs target j -1 prim + search-inner
      ] if
    ] if
  };

: search-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs target i -1 prim + search-inner [
        true
      ] [
        xs target i 1 prim + search-outer
      ] if
    ] [
      false
    ] if
  };

: main
  (-- result:Bool^many)
  locals { target xs } {
    xs target 0 search-outer
  };
```

### task: count-distinct
```firth
: check-seen
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target j } {
    j 0 prim < [
      false
    ] [
      xs j prim seq-int.at target prim = [
        true
      ] [
        xs target j -1 prim + check-seen
      ] if
    ] if
  };

: count-values
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i seen count } {
    i xs prim seq-int.len prim < [
      xs xs i prim seq-int.at seen i -1 prim + check-seen [
        xs i 1 prim + seen count count-values
      ] [
        xs i 1 prim + seen xs i prim seq-int.at prim seq-int.push count 1 prim + count-values
      ] if
    ] [
      count
    ] if
  };

: main
  (-- result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty 0 count-values
  };
```

### task: merge-sorted
```firth
: merge-step
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result xs i prim seq-int.at prim seq-int.push
          xs ys i 1 prim + j result merge-step
        ] [
          result ys j prim seq-int.at prim seq-int.push
          xs ys i j 1 prim + result merge-step
        ] if
      ] [
        result xs i prim seq-int.at prim seq-int.push
        xs ys i 1 prim + j result merge-step
      ] if
    ] [
      j ys prim seq-int.len prim < [
        result ys j prim seq-int.at prim seq-int.push
        xs ys i j 1 prim + result merge-step
      ] [
        result
      ] if
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { ys xs } {
    xs ys 0 0 prim seq-int.empty merge-step
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
        result n 10 prim mod prim seq-int.push
        n 10 prim div digits-loop
      ] if
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { n } {
    n prim seq-int.empty digits-loop
  };
```

### task: primes-up-to
```firth
: is-divisible
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim < [
      n i prim mod 0 prim = [
        true
      ] [
        n i 2 prim + is-divisible
      ] if
    ] [
      false
    ] if
  };

: is-prime-check
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim < [
      false
    ] [
      n 2 prim = [
        true
      ] [
        n 2 prim mod 0 prim = [
          false
        ] [
          n 3 is-divisible prim not
        ] if
      ] if
    ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    i n prim < [
      i is-prime-check [
        result i prim seq-int.push
        n i 1 prim + result primes-loop
      ] [
        n i 1 prim + result primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty primes-loop
  };
```

### task: histogram
```firth
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i result } {
    i xs prim seq-int.len prim < [
      xs k i 1 prim + result
      xs i prim seq-int.at dup result prim seq-int.at 1 prim + prim seq-int.set
      histogram-loop
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { k xs } {
    xs k 0 prim seq-int.empty histogram-loop
  };
```

### task: sort
```firth
: insert-in-sorted
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i 0 prim = [
      sorted x prim seq-int.push
    ] [
      sorted i -1 prim + prim seq-int.at x prim < [
        sorted x prim seq-int.push
      ] [
        sorted i -1 prim + prim seq-int.at
        x sorted i -1 prim + insert-in-sorted
        i -1 prim + prim seq-int.at prim seq-int.set
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at result result prim seq-int.len
      insert-in-sorted
      xs i 1 prim + result sort-loop
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim < [
      balance txs i prim seq-int.at prim + dup prim 0 prim < [
        drop balance rejected 1 prim + i 1 prim + ledger-loop
      ] [
        balance rejected i 1 prim + ledger-loop
      ] if
    ] [
      balance rejected
    ] if
  };

: main
  (-- balance:Int^many rejected:Int^many)
  locals { txs start } {
    start txs 0 0 ledger-loop
  };
```

### task: allocate-batch
```firth
: allocate-item
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item qty whole } {
    stock item prim seq-int.at qty prim <= [
      stock item qty prim - prim seq-int.set qty 0
    ] [
      stock item prim seq-int.at prim 0 prim = [
        stock 0 2
      ] [
        whole [
          stock 0 3
        ] [
          stock item prim seq-int.at dup
          stock item 0 prim seq-int.set
          1
        ] if
      ] if
    ] if
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim < [
      stock items i prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at allocate-item
      allocated prim seq-int.push
      reasons prim seq-int.push
      stock items qtys whole i 1 prim + allocated reasons allocate-loop
    ] [
      stock allocated reasons
    ] if
  };

: main
  (-- stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };
```
