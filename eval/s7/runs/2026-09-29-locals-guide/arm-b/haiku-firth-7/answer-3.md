### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - prim seq-int.empty xs build-reverse
  };

: build-reverse
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { i result xs } {
    i 0 prim <
    [ result ]
    [ i 1 prim - result xs i prim seq-int.at prim seq-int.push xs build-reverse ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs keep-positive-helper
  };

: keep-positive-helper
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim =
    [ result ]
    [ xs index prim seq-int.at locals { x } {
        0 x prim <
        [ result x prim seq-int.push index 1 prim + xs keep-positive-helper ]
        [ result index 1 prim + xs keep-positive-helper ]
        if
      }
    ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    0 xs is-sorted-helper
  };

: is-sorted-helper
  (forall ρ; ρ index:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { index xs } {
    index xs prim seq-int.len 1 prim - prim =
    [ true ]
    [ xs index prim seq-int.at xs index 1 prim + prim seq-int.at
      locals { curr next } {
        curr next prim <
        [ true index 1 prim + xs is-sorted-helper ]
        [ curr next prim =
          [ true index 1 prim + xs is-sorted-helper ]
          [ false ]
          if
        ]
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
    0 xs target outer-loop
  };

: outer-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len 1 prim - prim =
    [ false ]
    [ xs i prim seq-int.at i 1 prim + xs target inner-loop
      [ true ]
      [ i 1 prim + xs target outer-loop ]
      if
    ]
    if
  };

: inner-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many xi:Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs xi target } {
    j xs prim seq-int.len prim =
    [ false ]
    [ xs j prim seq-int.at locals { xj } {
        xi xj prim + target prim =
        [ true ]
        [ j 1 prim + xs xi target inner-loop ]
        if
      }
    ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-sorted-helper
  };

: merge-sorted-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim =
    [ j ys prim seq-int.len prim =
      [ result ]
      [ result ys j prim seq-int.at prim seq-int.push j 1 prim + xs ys merge-sorted-helper ]
      if
    ]
    [ j ys prim seq-int.len prim =
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys merge-sorted-helper ]
      [ xs i prim seq-int.at ys j prim seq-int.at
        locals { x y } {
          x y prim <
          [ result x prim seq-int.push i 1 prim + j xs ys merge-sorted-helper ]
          [ result y prim seq-int.push i j 1 prim + xs ys merge-sorted-helper ]
          if
        }
      ]
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
    [ prim seq-int.empty n collect-digits reverse-digits ]
    if
  };

: collect-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod locals { digit } {
        result digit prim seq-int.push
        n 10 prim div collect-digits
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - prim seq-int.empty xs build-reverse
  };

: build-reverse
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { i result xs } {
    i 0 prim <
    [ result ]
    [ i 1 prim - result xs i prim seq-int.at prim seq-int.push xs build-reverse ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n primes-up-to-helper
  };

: primes-up-to-helper
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { primes candidate n } {
    candidate n prim <
    [ candidate 2 is-prime
      [ primes candidate prim seq-int.push candidate 1 prim + n primes-up-to-helper ]
      [ primes candidate 1 prim + n primes-up-to-helper ]
      if
    ]
    [ primes ]
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [ true ]
    [ candidate divisor prim mod 0 prim =
      [ false ]
      [ candidate divisor 1 prim + is-prime ]
      if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0 xs 0 k make-zeros histogram-helper
  };

: make-zeros
  (forall ρ; ρ i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i k prim =
    [ prim seq-int.empty ]
    [ prim seq-int.empty 0 prim seq-int.push i 1 prim + k make-zeros ]
    if
  };

: histogram-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim =
    [ counts ]
    [ xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at 1 prim + locals { new-count } {
          counts v new-count prim seq-int.set
          i 1 prim + xs histogram-helper
        }
      }
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len sort-outer
  };

: sort-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len prim =
    [ xs ]
    [ xs i len sort-inner ]
    if
  };

: sort-inner
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len 1 prim - prim =
    [ xs i 1 prim + len sort-outer ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at
      locals { curr next } {
        curr next prim <
        [ xs i 1 prim + len sort-inner ]
        [ xs i next prim seq-int.set i curr prim seq-int.set
          i 1 prim + len sort-inner
        ]
        if
      }
    ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-batch-helper
  };

: allocate-batch-helper
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated order items qtys whole } {
    order items prim seq-int.len prim =
    [ stock allocated prim seq-int.empty ]
    [ items order prim seq-int.at locals { item-idx } {
        qtys order prim seq-int.at locals { qty } {
          whole order prim seq-bool.at locals { need-whole } {
            stock item-idx prim seq-int.at locals { current-stock } {
              qty current-stock prim =
              [ stock item-idx qty prim - prim seq-int.set
                allocated qty prim seq-int.push
                prim seq-int.empty 0 prim seq-int.push
                order 1 prim + items qtys whole allocate-batch-helper
              ]
              [ current-stock 0 prim =
                [ allocated 0 prim seq-int.push
                  prim seq-int.empty 2 prim seq-int.push
                  order 1 prim + items qtys whole allocate-batch-helper
                ]
                [ need-whole
                  [ allocated 0 prim seq-int.push
                    prim seq-int.empty 3 prim seq-int.push
                    order 1 prim + items qtys whole allocate-batch-helper
                  ]
                  [ stock item-idx 0 prim seq-int.set
                    allocated current-stock prim seq-int.push
                    prim seq-int.empty 1 prim seq-int.push
                    order 1 prim + items qtys whole allocate-batch-helper
                  ]
                  if
                ]
                if
              ]
              if
            }
          }
        }
      }
    ]
    if
  };
```
