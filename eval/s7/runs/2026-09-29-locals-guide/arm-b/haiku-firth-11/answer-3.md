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
      0 x prim <
      [ result x prim seq-int.push xs idx 1 prim + keep-loop ]
      [ result xs idx 1 prim + keep-loop ]
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
    [ xs xs 0 prim seq-int.at 1 is-sorted-loop ]
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

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs xs 0 prim seq-int.at 1 0 1 longest-loop ]
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
        xs i 1 prim + end new-result copy-remaining
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
    [ prim seq-int.empty n digits-loop prim seq-int.empty digits-reverse ]
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

: digits-reverse
  (forall ρ; ρ result:Seq Int^many digits:Seq Int^many -- ρ result:Seq Int^many)
  locals { result digits } {
    digits prim seq-int.len 0 prim =
    [ result ]
    [ result digits digits prim seq-int.len 1 prim - prim seq-int.at prim seq-int.push locals { new-result } {
      new-result digits prim seq-int.len 1 prim - digits-reverse
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
    cand n prim < prim not
    [ result ]
    [ cand is-prime
      [ result cand prim seq-int.push locals { new-result } {
        new-result cand 1 prim + n primes-loop
      } ]
      [ result cand 1 prim + n primes-loop ]
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
    i i prim * n prim <
    [ n i prim mod 0 prim =
      [ 1 0 prim = ]
      [ i 2 prim + n check-prime ]
      if
    ]
    [ 1 1 prim = ]
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
      xs min-idx i swap-elements locals { new-xs } {
        new-xs i 1 prim + sort-loop
      }
    } ]
    if
  };

: find-min
  (forall ρ; ρ xs:Seq Int^many start:Int^many -- ρ result:Int^many)
  locals { xs start } { xs start start start find-min-loop };

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
            [ stock item r qty prim - prim seq-int.set locals { s } {
              s allocated qty prim seq-int.push reasons 0 prim seq-int.push items qtys whole idx 1 prim + allocate-loop
            } ]
            [ r 0 prim =
              [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push items qtys whole idx 1 prim + allocate-loop ]
              [ must-fill
                [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push items qtys whole idx 1 prim + allocate-loop ]
                [ stock item 0 prim seq-int.set locals { s2 } {
                  s2 allocated r prim seq-int.push reasons 1 prim seq-int.push items qtys whole idx 1 prim + allocate-loop
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
