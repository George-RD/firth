### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len
    1 prim -
    xs
    prim seq-int.empty
    loop-reverse
  };

: loop-reverse
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [
      result
      xs i prim seq-int.at
      prim seq-int.push
      i 1 prim -
      xs
      loop-reverse
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 0 prim seq-int.empty xs loop-prefix };

: loop-prefix
  (forall ρ; ρ sum:Int^many i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { sum i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      sum prim +
      dup
      locals { new-sum } {
        result new-sum prim seq-int.push
        new-sum
        i 1 prim +
        xs
        loop-prefix
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
  locals { xs } { 0 prim seq-int.empty xs loop-keep };

: loop-keep
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem 0 prim <
        [ result ]
        [ result elem prim seq-int.push ]
        if
      }
      i 1 prim +
      xs
      loop-keep
    ]
    [ result ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs loop-count-dist };

: loop-count-dist
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      0 i xs
      [ xs prim seq-int.at i prim < loop-find-dup ]
      [
        count 1 prim +
        i 1 prim +
        xs
        loop-count-dist
      ]
      [
        drop
        i 1 prim +
        xs
        loop-count-dist
      ]
      if
    ]
    [ count ]
    if
  };

: loop-find-dup
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many -- ρ is-dup:Bool^many)
  locals { j i xs } {
    j i prim <
    [
      xs j prim seq-int.at
      xs i prim seq-int.at
      prim =
      [ true ]
      [ j 1 prim + i xs loop-find-dup ]
      if
    ]
    [ false ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { 0 0 prim seq-int.empty xs ys loop-merge };

: loop-merge
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i j result xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          result
          xs i prim seq-int.at
          prim seq-int.push
          i 1 prim +
          j
          xs ys
          loop-merge
        ]
        [
          result
          ys j prim seq-int.at
          prim seq-int.push
          j 1 prim +
          i
          xs ys
          loop-merge
        ]
        if
      ]
      [
        result
        xs i prim seq-int.at
        prim seq-int.push
        i 1 prim +
        j
        xs ys
        loop-merge
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result
        ys j prim seq-int.at
        prim seq-int.push
        j 1 prim +
        i
        xs ys
        loop-merge
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
    n 0 prim =
    [ { 0 } ]
    [ n prim seq-int.empty loop-digits-collect ]
    if
  };

: loop-digits-collect
  (forall ρ; ρ num:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { num result } {
    num 0 prim =
    [
      result prim seq-int.len
      1 prim -
      result
      prim seq-int.empty
      loop-reverse-helper
    ]
    [
      result
      num 10 prim mod
      prim seq-int.push
      num 10 prim div
      result
      loop-digits-collect
    ]
    if
  };

: loop-reverse-helper
  (forall ρ; ρ i:Int^many seq:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i seq result } {
    i 0 prim <
    [
      result
      seq i prim seq-int.at
      prim seq-int.push
      i 1 prim -
      seq
      loop-reverse-helper
    ]
    [ result ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        2 n loop-check-prime
      ]
      if
    ]
    if
  };

: loop-check-prime
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod
      0 prim =
      [ false ]
      [ d 1 prim + n loop-check-prime ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { 2 prim seq-int.empty n loop-primes };

: loop-primes
  (forall ρ; ρ i:Int^many result:Seq Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { i result n } {
    i n prim <
    [
      i is-prime
      [
        result i prim seq-int.push
        i 1 prim +
        n
        loop-primes
      ]
      [
        i 1 prim +
        result
        n
        loop-primes
      ]
      if
    ]
    [ result ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0 k prim seq-int.empty xs
    loop-init-hist
  };

: loop-init-hist
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result xs } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      result xs
      loop-init-hist
    ]
    [
      result 0 xs
      loop-histogram
    ]
    if
  };

: loop-histogram
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      result
      xs i prim seq-int.at
      dup
      locals { v } {
        result v prim seq-int.at
        1 prim +
        prim seq-int.set
      }
      i 1 prim +
      xs
      loop-histogram
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 loop-sort };

: loop-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i } {
    i arr prim seq-int.len prim <
    [
      i arr loop-insert
      i 1 prim +
      loop-sort
    ]
    [ arr ]
    if
  };

: loop-insert
  (forall ρ; ρ i:Int^many arr:Seq Int^many -- ρ result:Seq Int^many)
  locals { i arr } {
    i 0 prim <
    [ arr ]
    [
      arr i 1 prim - prim seq-int.at
      arr i prim seq-int.at
      prim <
      [
        arr i prim seq-int.at
        arr i 1 prim - prim seq-int.set
        locals { arr1 } {
          arr1 i 1 prim - prim seq-int.at
          arr1 i prim seq-int.set
          locals { arr2 } {
            i 1 prim -
            arr2
            loop-insert
          }
        }
      ]
      [ arr ]
      if
    ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { 0 prim seq-int.empty prim seq-int.empty prim seq-int.empty stock items qtys whole loop-alloc };

: loop-alloc
  (forall ρ; ρ i:Int^many allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { i allocated reasons stock items qtys whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim <
            [
              stock item qty r prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
            ]
            [
              r 0 prim =
              [
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ]
              [
                whole i prim seq-bool.at
                [
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ]
                [
                  stock item 0 r prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
      i 1 prim +
      allocated
      reasons
      stock items qtys whole
      loop-alloc
    ]
    [ stock allocated reasons ]
    if
  };
```
