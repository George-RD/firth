### task: longest-run
```firth
: count-run
  (forall ρ; ρ xs:Seq Int^many i:Int^many val:Int^many run-len:Int^many -- ρ len:Int^many)
  locals { xs i val run-len } {
    i 1 prim + xs prim seq-int.len prim >=
    [ run-len ]
    [ xs i 1 prim + prim seq-int.at val prim =
      [ xs i 1 prim + val run-len 1 prim + count-run ]
      [ run-len ]
      if
    ]
    if
  };

: find-longest
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs i max-run } {
    i xs prim seq-int.len prim >=
    [ max-run ]
    [ xs i prim seq-int.at locals { val } {
      xs i val 1 count-run locals { run-len } {
        run-len max-run prim >
        [ xs i 1 prim + run-len find-longest ]
        [ xs i 1 prim + max-run find-longest ]
        if
      }
    } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim <=
    [ 0 ]
    [ xs 0 0 find-longest ]
    if
  };
```

### task: digits
```firth
: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many temp:Seq Int^many -- ρ digs:Seq Int^many)
  locals { result i temp } {
    i 0 prim <=
    [ temp ]
    [ temp result i 1 prim - prim seq-int.at prim seq-int.push locals { new-temp } {
      result i 1 prim - new-temp reverse-digits
    } ]
    if
  };

: digits-loop
  (forall ρ; ρ n:Int^many digits:Seq Int^many -- ρ digs:Seq Int^many)
  locals { n digits } {
    n 0 prim <=
    [ digits digits prim seq-int.len prim seq-int.empty reverse-digits ]
    [ digits n 10 prim mod prim seq-int.push locals { new-digits } {
      n 10 prim div new-digits digits-loop
    } ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim <=
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digits-loop ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ prime:Bool^many)
  locals { n i } {
    i i prim * n prim >
    [ true ]
    [ n i prim mod 0 prim =
      [ false ]
      [ n i 2 prim + is-prime ]
      if
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ n:Int^many i:Int^many primes:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i primes } {
    i n prim > 
    [ primes ]
    [ i 2 prim >=
      [ i 2 is-prime
        [ n i 1 prim + primes i prim seq-int.push sieve-loop ]
        [ n i 1 prim + primes sieve-loop ]
        if
      ]
      [ n i 1 prim + primes sieve-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty sieve-loop
  };
```

### task: histogram
```firth
: init-histogram
  (forall ρ; ρ k:Int^many i:Int^many hist:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i hist } {
    i k prim >=
    [ hist ]
    [ k i 1 prim + hist 0 prim seq-int.push init-histogram ]
    if
  };

: count-histogram
  (forall ρ; ρ xs:Seq Int^many hist:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs hist i } {
    i xs prim seq-int.len prim >=
    [ hist ]
    [ xs i prim seq-int.at locals { val } {
      hist val prim seq-int.at 1 prim + locals { new-val } {
        hist val new-val prim seq-int.set locals { new-hist } {
          xs new-hist i 1 prim + count-histogram
        }
      }
    } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-histogram xs swap 0 count-histogram
  };
```

### task: sort
```firth
: min-index-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many min-i:Int^many -- ρ idx:Int^many)
  locals { xs i min-i } {
    i xs prim seq-int.len prim >=
    [ min-i ]
    [ xs i prim seq-int.at xs min-i prim seq-int.at prim <
      [ xs i 1 prim + i min-index-loop ]
      [ xs i 1 prim + min-i min-index-loop ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim >=
    [ xs ]
    [ xs i i min-index-loop locals { min-idx } {
      xs min-idx prim seq-int.at xs i prim seq-int.at locals { val-i val-min } {
        xs i val-min prim seq-int.set locals { xs1 } {
          xs1 min-idx val-i prim seq-int.set locals { xs2 } {
            xs2 i 1 prim + sort-loop
          }
        }
      }
    } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 sort-loop
  };
```

### task: allocate-batch
```firth
: allocate-item
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i qtys prim seq-int.len prim >=
    [ stock allocated reasons ]
    [ items i prim seq-int.at stock swap prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      locals { item-stock qty needs-whole } {
        qty item-stock prim <=
        [ allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { allocated1 reasons1 } {
            stock items i prim seq-int.at qty prim seq-int.set items qtys whole i 1 prim + allocated1 reasons1 allocate-item
          }
        ]
        [ item-stock 0 prim =
          [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push locals { reasons1 allocated1 } {
            stock items qtys whole i 1 prim + allocated1 reasons1 allocate-item
          } ]
          [ needs-whole
            [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push locals { reasons1 allocated1 } {
              stock items qtys whole i 1 prim + allocated1 reasons1 allocate-item
            } ]
            [ allocated item-stock prim seq-int.push reasons 1 prim seq-int.push locals { allocated1 reasons1 } {
                stock items i prim seq-int.at 0 prim seq-int.set items qtys whole i 1 prim + allocated1 reasons1 allocate-item
              }
            ]
            if
          ]
          if
        ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-item
  };
```
