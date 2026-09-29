### task: seq-max
```firth
: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      max xs i prim seq-int.at prim <
      [
        xs i prim seq-int.at
      ]
      [
        max
      ]
      if
      i 1 prim +
      xs
      max-loop
    ]
    [
      max
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs max-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      i -1 prim +
      xs
      reverse-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs
    reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ result:Seq Int^many acc:Int^many i:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result acc i xs } {
    i xs prim seq-int.len prim <
    [
      acc xs i prim seq-int.at prim +
      locals { new-acc } {
        result new-acc prim seq-int.push
        new-acc i 1 prim + xs
        prefix-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-loop
  };
```

### task: keep-positive
```firth
: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        0 elem prim <
        [
          result elem prim seq-int.push
        ]
        [
          result
        ]
        if
      }
      i 1 prim +
      xs
      keep-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs keep-loop
  };
```

### task: is-sorted
```firth
: check-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <
      [
        false
      ]
      [
        i 1 prim + xs check-loop
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [
      true
    ]
    [
      0 xs check-loop
    ]
    if
  };
```

### task: longest-run
```firth
: run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        1 1 i 1 prim + xs run-loop
      ]
      [
        xs i prim seq-int.at
        xs i 1 prim - prim seq-int.at
        prim =
        [
          current-run 1 prim +
          locals { new-run } {
            max-run new-run prim <
            [
              new-run max-run
            ]
            [
              max-run
            ]
            if
            new-run i 1 prim + xs run-loop
          }
        ]
        [
          max-run current-run prim <
          [
            current-run
          ]
          [
            max-run
          ]
          if
          1 i 1 prim + xs run-loop
        ]
        if
      ]
      if
    ]
    [
      max-run current-run prim <
      [
        current-run
      ]
      [
        max-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      0 0 0 xs run-loop
    ]
    if
  };
```

### task: count-distinct
```firth
: check-earlier
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many x:Int^many -- ρ found:Bool^many)
  locals { j i xs x } {
    j i prim <
    [
      xs j prim seq-int.at x prim =
      [
        true
      ]
      [
        j 1 prim + i xs x check-earlier
      ]
      if
    ]
    [
      false
    ]
    if
  };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ counted:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        0 i xs val check-earlier
        [
          count
        ]
        [
          count 1 prim +
        ]
        if
      }
      i 1 prim +
      xs
      count-loop
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 0 xs count-loop
  };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [
      result
    ]
    [
      result n 10 prim mod prim seq-int.push
      locals { new-result } {
        n 10 prim div digits-loop
        new-result
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n 0 prim < [ n -1 prim * ] [ n ] if
      locals { abs-n } {
        prim seq-int.empty abs-n digits-loop
      }
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime-check
  (forall ρ; ρ d:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        d 1 prim + n is-prime-check
      ]
      if
    ]
    [
      true
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  n 2 prim <
  [
    false
  ]
  [
    n 2 prim =
    [
      true
    ]
    [
      n 2 prim mod 0 prim =
      [
        false
      ]
      [
        2 n is-prime-check
      ]
      if
    ]
    if
  ]
  if;

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <=
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      i 1 prim +
      n
      primes-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n primes-loop
  };
```

### task: histogram
```firth
: hist-loop
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { counts i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        counts val prim seq-int.at 1 prim +
        locals { new-val } {
          counts val new-val prim seq-int.set
          locals { new-counts } {
            new-counts i 1 prim + xs hist-loop
          }
        }
      }
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    locals { counts } {
      0
      [
        counts 0 prim seq-int.push
        1 prim +
      ]
      [ dup k prim < ]
      if
      locals { filled } {
        filled 0 xs hist-loop
      }
    }
  };
```

### task: sort
```firth
: insert-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.len
      locals { elem j } {
        elem
        [
          j 0 prim >
          result j 1 prim - prim seq-int.at elem prim <
          prim and
        ]
        [
          result j result j 1 prim - prim seq-int.at prim seq-int.set
          j 1 prim -
        ]
        if
        result j elem prim seq-int.set
        i 1 prim +
        xs
        insert-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs insert-loop
  };
```

### task: allocate-batch
```firth
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim <=
            [
              stock item r qty prim - prim seq-int.set
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
                  stock item 0 prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
            locals { new-reasons } {
              locals { new-allocated } {
                locals { new-stock } {
                  new-stock i 1 prim + items qtys whole allocate-loop
                }
              }
            }
          }
        }
      }
    ]
    [
      stock allocated reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-loop
  };
```
