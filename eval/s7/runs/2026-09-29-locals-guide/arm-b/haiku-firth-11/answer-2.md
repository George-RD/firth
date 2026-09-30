### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs idx acc } {
    xs prim seq-int.len idx prim =
    [ acc ]
    [ xs idx prim seq-int.at locals { x } { xs idx 1 prim + acc x prim + sum-loop } ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs idx max } {
    xs prim seq-int.len idx prim =
    [ max ]
    [ xs idx prim seq-int.at locals { x } {
      max x prim <
      [ xs idx 1 prim + x max-loop ]
      [ xs idx 1 prim + max max-loop ]
      if
    } ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs k idx acc } {
    xs prim seq-int.len idx prim =
    [ acc ]
    [ xs idx prim seq-int.at locals { x } {
      x k prim <
      [ xs k idx 1 prim + acc 1 prim + count-loop ]
      [ xs k idx 1 prim + acc count-loop ]
      if
    } ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { xs x 0 index-loop };

: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs x idx } {
    xs prim seq-int.len idx prim =
    [ -1 ]
    [ xs idx prim seq-int.at locals { elem } {
      elem x prim =
      [ idx ]
      [ xs x idx 1 prim + index-loop ]
      if
    } ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx } {
    idx 0 prim =
    [ result ]
    [ xs idx 1 prim - prim seq-int.at locals { elem } {
      result elem prim seq-int.push locals { new-result } {
        new-result xs idx 1 prim - reverse-loop
      }
    } ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many acc:Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result acc xs idx } {
    xs prim seq-int.len idx prim =
    [ result ]
    [ xs idx prim seq-int.at locals { x } {
      acc x prim + locals { new-acc } {
        result new-acc prim seq-int.push locals { new-result } {
          new-result new-acc xs idx 1 prim + prefix-loop
        }
      }
    } ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx } {
    xs prim seq-int.len idx prim =
    [ result ]
    [ xs idx prim seq-int.at locals { x } {
      x 0 prim <
      [ result xs idx 1 prim + keep-loop ]
      [ result x prim seq-int.push xs idx 1 prim + keep-loop ]
      if
    } ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ 1 1 prim = ]
    [ xs 0 prim seq-int.at xs 1 prim seq-int.at is-sorted-loop ]
    if
  };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs prev idx } {
    xs prim seq-int.len idx prim =
    [ 1 1 prim = ]
    [ xs idx prim seq-int.at locals { curr } {
      prev curr prim <
      [ xs curr idx 1 prim + is-sorted-loop ]
      [ prev curr prim =
        [ xs curr idx 1 prim + is-sorted-loop ]
        [ 1 0 prim = ]
        if
      ]
      if
    } ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many idx:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys idx acc } {
    xs prim seq-int.len idx prim =
    [ acc ]
    [ xs idx prim seq-int.at locals { x } {
      ys idx prim seq-int.at locals { y } {
        x y prim * locals { prod } {
          xs ys idx 1 prim + acc prod prim + dot-loop
        }
      }
    } ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { flags 0 all-true-loop };

: all-true-loop
  (forall ρ; ρ flags:Seq Bool^many idx:Int^many -- ρ result:Bool^many)
  locals { flags idx } {
    flags prim seq-bool.len idx prim =
    [ 1 1 prim = ]
    [ flags idx prim seq-bool.at
      [ flags idx 1 prim + all-true-loop ]
      [ 1 0 prim = ]
      if
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 prim seq-int.at 1 xs 1 prim seq-int.at longest-loop ]
    if
  };

: longest-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many run:Int^many max:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs prev run max idx } {
    xs prim seq-int.len idx prim =
    [ max run prim < [ run ] [ max ] if ]
    [ xs idx prim seq-int.at locals { curr } {
      prev curr prim =
      [ xs curr run 1 prim + max idx 1 prim + longest-loop ]
      [ max run prim < [ run locals { new-max } { xs curr 1 new-max idx 1 prim + longest-loop } ] [ xs curr 1 max idx 1 prim + longest-loop ] if ]
      if
    } ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs target 0 has-pair-loop };

: has-pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    xs prim seq-int.len i prim =
    [ 1 0 prim = ]
    [ xs i prim seq-int.at locals { x } {
      xs target x i 1 prim + check-pair
      [ 1 1 prim = ]
      [ xs target i 1 prim + has-pair-loop ]
      if
    } ]
    if
  };

: check-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many x:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target x j } {
    xs prim seq-int.len j prim =
    [ 1 0 prim = ]
    [ xs j prim seq-int.at locals { y } {
      x y prim + target prim =
      [ 1 1 prim = ]
      [ xs target x j 1 prim + check-pair ]
      if
    } ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { prim seq-int.empty xs 0 collect-loop };

: collect-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { seen xs idx } {
    xs prim seq-int.len idx prim =
    [ seen prim seq-int.len ]
    [ xs idx prim seq-int.at locals { x } {
      seen x find-element
      [ seen xs idx 1 prim + collect-loop ]
      [ seen x prim seq-int.push xs idx 1 prim + collect-loop ]
      if
    } ]
    if
  };

: find-element
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Bool^many)
  locals { xs x } { xs x 0 find-loop };

: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs x idx } {
    xs prim seq-int.len idx prim =
    [ 1 0 prim = ]
    [ xs idx prim seq-int.at locals { elem } {
      elem x prim =
      [ 1 1 prim = ]
      [ xs x idx 1 prim + find-loop ]
      if
    } ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { result xs ys i j } {
    xs prim seq-int.len i prim =
    [ ys j ys prim seq-int.len copy-remaining result ]
    [ ys prim seq-int.len j prim =
      [ xs i xs prim seq-int.len copy-remaining result ]
      [ xs i prim seq-int.at locals { x } {
        ys j prim seq-int.at locals { y } {
          x y prim <
          [ result x prim seq-int.push xs ys i 1 prim + j merge-loop ]
          [ result y prim seq-int.push xs ys i j 1 prim + merge-loop ]
          if
        }
      } ]
      if
    ]
    if
  };

: copy-remaining
  (forall ρ; ρ xs:Seq Int^many i:Int^many end:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i end result } {
    i end prim =
    [ result ]
    [ xs i prim seq-int.at locals { x } {
      result x prim seq-int.push locals { new-result } {
        new-result xs i 1 prim + end copy-remaining
      }
    } ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ digits:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { digits n } {
    n 0 prim =
    [ digits ]
    [ n 10 prim mod locals { d } {
      digits d prim seq-int.push locals { new-digits } {
        new-digits n 10 prim div digits-loop
      }
    } ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 2 prim <
    [ prim seq-int.empty ]
    [ prim seq-int.empty 2 n primes-loop ]
    if
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many cand:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result cand n } {
    cand n prim <
    [ cand is-prime
      [ result cand prim seq-int.push locals { new-result } {
        new-result cand 1 prim + n primes-loop
      } ]
      [ result cand 1 prim + n primes-loop ]
      if
    ]
    [ cand n prim =
      [ result cand prim seq-int.push ]
      [ result ]
      if
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ 1 0 prim = ]
    [ n 2 prim =
      [ 1 1 prim = ]
      [ n 2 prim mod 0 prim = [ 1 0 prim = ] [ 3 n check-prime ] if ]
      if
    ]
    if
  };

: check-prime
  (forall ρ; ρ i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { i n } {
    i i prim * n prim < prim not
    [ 1 1 prim = ]
    [ n i prim mod 0 prim =
      [ 1 0 prim = ]
      [ i 2 prim + n check-prime ]
      if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k init-histogram xs 0 histogram-loop
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result i k } {
    i k prim =
    [ result ]
    [ result 0 prim seq-int.push locals { new-result } {
      new-result i 1 prim + k init-histogram
    } ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx } {
    xs prim seq-int.len idx prim =
    [ result ]
    [ xs idx prim seq-int.at locals { x } {
      result x prim seq-int.at locals { count } {
        result x count 1 prim + prim seq-int.set locals { new-result } {
          new-result xs idx 1 prim + histogram-loop
        }
      }
    } ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 sort-loop };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    xs prim seq-int.len 1 prim - i prim =
    [ xs ]
    [ xs i find-min locals { min-idx } {
      min-idx i swap-elements locals { new-xs } {
        new-xs i 1 prim + sort-loop
      }
    } ]
    if
  };

: find-min
  (forall ρ; ρ xs:Seq Int^many start:Int^many -- ρ result:Int^many)
  locals { xs start } { xs start start find-min-loop };

: find-min-loop
  (forall ρ; ρ xs:Seq Int^many start:Int^many min-idx:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs start min-idx idx } {
    xs prim seq-int.len idx prim =
    [ min-idx ]
    [ xs idx prim seq-int.at locals { x } {
      xs min-idx prim seq-int.at locals { min-val } {
        x min-val prim <
        [ xs start idx idx 1 prim + find-min-loop ]
        [ xs start min-idx idx 1 prim + find-min-loop ]
        if
      }
    } ]
    if
  };

: swap-elements
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs i j } {
    xs i prim seq-int.at locals { xi } {
      xs j prim seq-int.at locals { xj } {
        xs i xj prim seq-int.set locals { temp } {
          temp j xi prim seq-int.set
        }
      }
    }
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs idx } {
    txs prim seq-int.len idx prim =
    [ balance rejected ]
    [ txs idx prim seq-int.at locals { tx } {
      balance tx prim + locals { new-balance } {
        new-balance 0 prim <
        [ balance rejected 1 prim + txs idx 1 prim + ledger-loop ]
        [ new-balance rejected txs idx 1 prim + ledger-loop ]
        if
      }
    } ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole idx } {
    items prim seq-int.len idx prim =
    [ stock allocated reasons ]
    [ items idx prim seq-int.at locals { item } {
      stock item prim seq-int.at locals { r } {
        qtys idx prim seq-int.at locals { qty } {
          whole idx prim seq-bool.at locals { must-fill } {
            qty r prim < prim not
            [ stock qty prim seq-int.push allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { s1 a1 r1 } {
              s1 item r qty prim - prim seq-int.set locals { s2 } {
                s2 a1 r1 items qtys whole idx 1 prim + allocate-loop
              }
            } ]
            [ r 0 prim =
              [ stock allocated reasons 2 prim seq-int.push items qtys whole idx 1 prim + allocate-loop ]
              [ must-fill
                [ stock allocated reasons 3 prim seq-int.push items qtys whole idx 1 prim + allocate-loop ]
                [ stock r prim seq-int.push allocated r prim seq-int.push reasons 1 prim seq-int.push locals { s3 a3 r3 } {
                  s3 item 0 prim seq-int.set locals { s4 } {
                    s4 a3 r3 items qtys whole idx 1 prim + allocate-loop
                  }
                } ]
                if
              ]
              if
            ]
            if
          }
        }
      }
    } ]
    if
  };
```
