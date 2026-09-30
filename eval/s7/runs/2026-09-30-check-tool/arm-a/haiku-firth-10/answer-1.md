### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs call sum-helper };

: sum-helper
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      1 i prim +
      xs
      call sum-helper
    ]
    [ sum ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1
    xs
    call max-helper
  };

: max-helper
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max
      locals { elem prev-max } {
        prev-max elem prim <
        [ elem ]
        [ prev-max ]
        if
      }
      i 1 prim +
      xs
      call max-helper
    ]
    [ max ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0
    0
    xs
    k
    call count-loop
  };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i xs k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem k prim <
        [ count 1 prim + ]
        [ count ]
        if
      }
      i 1 prim +
      xs
      k
      call count-loop
    ]
    [ count ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0
    xs
    x
    call index-loop
  };

: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ final-index:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [
        i
      ]
      [
        i 1 prim +
        xs
        x
        call index-loop
      ]
      if
    ]
    [ -1 ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    call reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    prim not
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      xs
      call reverse-loop
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    0
    xs
    call prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ prefix-sums:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        new-sum
        result prim seq-int.push
        new-sum
        i 1 prim +
        xs
        call prefix-loop
      }
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    call filter-loop
  };

: filter-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        0 elem prim <
        [
          elem
          result prim seq-int.push
        ]
        [ result ]
        if
      }
      i 1 prim +
      xs
      call filter-loop
    ]
    [ result ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    1
    0
    xs
    call is-sorted-loop
  };

: is-sorted-loop
  (forall ρ; ρ is-sorted:Bool^many i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { is-sorted i xs } {
    is-sorted prim not
    [
      0
    ]
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        xs i prim seq-int.at
        xs i 1 prim + prim seq-int.at
        prim <
        prim not
        [
          1
          i 1 prim +
          xs
          call is-sorted-loop
        ]
        [ 0 ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0
    0
    xs
    ys
    call dot-product
  };

: dot-product
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      xs
      ys
      call dot-product
    ]
    [ sum ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    1
    0
    flags
    call all-true-loop
  };

: all-true-loop
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result i flags } {
    result prim not
    [
      0
    ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
        [
          1
          i 1 prim +
          flags
          call all-true-loop
        ]
        [ 0 ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len
    [
      0
    ]
    [
      0
      1
      0
      xs
      call longest-run-loop
    ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim =
      [
        current-run 1 prim +
        i 1 prim +
        xs
        call longest-run-loop
      ]
      [
        max-run current-run
        locals { m r } {
          m r prim <
          [ r ]
          [ m ]
          if
        }
        1
        i 1 prim +
        xs
        call longest-run-loop
      ]
      if
    ]
    [
      max-run current-run
      locals { m r } {
        m r prim <
        [ r ]
        [ m ]
        if
      }
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0
    xs
    target
    call pair-sum-loop
  };

: pair-sum-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      target
      i
      call check-pairs
    ]
    [ 0 ]
    if
  };

: check-pairs
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j xs target i } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs j prim seq-int.at
      prim +
      target prim =
      [
        1
      ]
      [
        j 1 prim +
        xs
        target
        i
        call check-pairs
      ]
      if
    ]
    [
      i 1 prim +
      xs
      target
      call pair-sum-loop
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0
    0
    xs
    call count-distinct-main
  };

: count-distinct-main
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        0
        xs
        elem
        i
        call check-if-new
      }
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      i 1 prim +
      xs
      call count-distinct-main
    ]
    [ count ]
    if
  };

: check-if-new
  (forall ρ; ρ j:Int^many xs:Seq Int^many elem:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j xs elem i } {
    j i prim <
    [
      xs j prim seq-int.at elem prim =
      [
        1
      ]
      [
        j 1 prim +
        xs
        elem
        i
        call check-if-new
      ]
      if
    ]
    [ 0 ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0
    0
    xs
    ys
    call merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          xs i prim seq-int.at
          result prim seq-int.push
          i 1 prim +
          j
        ]
        [
          ys j prim seq-int.at
          result prim seq-int.push
          i
          j 1 prim +
        ]
        if
        xs
        ys
        call merge-loop
      ]
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        j
        xs
        ys
        call merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at
        result prim seq-int.push
        i
        j 1 prim +
        xs
        ys
        call merge-loop
      ]
      [ result ]
      if
    ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    n
    call extract-digits-reverse
    call reverse-digits
  };

: extract-digits-reverse
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      call extract-digits-reverse
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    call reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    prim not
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      xs
      call reverse-loop
    ]
    [ result ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    2
    n
    call find-primes-loop
  };

: find-primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <
    [
      i
      call is-prime
      [
        i
        result prim seq-int.push
      ]
      [ result ]
      if
      i 1 prim +
      n
      call find-primes-loop
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim <
    [
      0
    ]
    [
      num 2 prim =
      [
        1
      ]
      [
        num 2 prim mod 0 prim =
        [
          0
        ]
        [
          2
          num
          call check-divisors
        ]
        if
      ]
      if
    ]
    if
  };

: check-divisors
  (forall ρ; ρ i:Int^many num:Int^many -- ρ prime:Bool^many)
  locals { i num } {
    i i prim * num prim <
    [
      num i prim mod 0 prim =
      [
        0
      ]
      [
        i 2 prim +
        num
        call check-divisors
      ]
      if
    ]
    [ 1 ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    k
    xs
    call init-and-fill-histogram
  };

: init-and-fill-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many xs:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { result i k xs } {
    i k prim <
    [
      0
      result prim seq-int.push
      i 1 prim +
      k
      xs
      call init-and-fill-histogram
    ]
    [
      result
      0
      xs
      k
      call fill-histogram
    ]
    if
  };

: fill-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { result i xs k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        result val prim seq-int.at
        1 prim +
        result val prim seq-int.set
      }
      i 1 prim +
      xs
      k
      call fill-histogram
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    call insertion-sort-loop
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result
      0
      call insert-into-sorted
      i 1 prim +
      xs
      call insertion-sort-loop
    ]
    [ result ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ elem:Int^many result:Seq Int^many pos:Int^many -- ρ inserted:Seq Int^many)
  locals { elem result pos } {
    pos result prim seq-int.len prim <
    [
      result pos prim seq-int.at elem prim <
      [
        elem
        result pos prim seq-int.set
      ]
      [
        pos 1 prim +
        call insert-into-sorted
      ]
      if
    ]
    [
      elem
      result prim seq-int.push
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    0
    txs
    call ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim <
        [
          balance
          rejected 1 prim +
        ]
        [
          balance tx prim +
          rejected
        ]
        if
      }
      i 1 prim +
      txs
      call ledger-loop
    ]
    [ balance rejected ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    items
    qtys
    whole
    call allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-list:Seq Int^many reason-list:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { available } {
          qtys j prim seq-int.at available prim <
          [
            available 0 prim =
            [
              0
              2
            ]
            [
              whole j prim seq-bool.at
              [
                0
                3
              ]
              [
                available
                1
              ]
              if
            ]
            if
          ]
          [
            qtys j prim seq-int.at
            0
          ]
          if
          locals { alloc-qty reason } {
            alloc-qty
            allocated prim seq-int.push
            reason
            reasons prim seq-int.push
            available alloc-qty prim -
            stock item prim seq-int.set
            j 1 prim +
            items
            qtys
            whole
            call allocate-loop
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };
```
