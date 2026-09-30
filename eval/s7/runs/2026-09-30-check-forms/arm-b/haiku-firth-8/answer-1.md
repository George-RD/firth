### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0
  [
    dup swap prim seq-int.len prim <
  ]
  [
    dup prim seq-int.at swap 1 prim + swap
  ]
  call;
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  0 prim seq-int.at 1
  [
    dup swap prim seq-int.len prim <
  ]
  [
    dup prim seq-int.at swap prim > [ drop ] if
    swap 1 prim + swap
  ]
  call
  drop;
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at k prim <
      [ swap 1 prim + swap ] [] if
      swap 1 prim + swap
    ]
    call
    drop drop
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0 -1
    [
      dup prim >= xs prim seq-int.len prim < prim and
    ]
    [
      xs over prim seq-int.at x prim =
      [ swap drop ] [ swap 1 prim + swap ] if
    ]
    call
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim -
    [
      dup 0 prim >=
    ]
    [
      xs over prim seq-int.at swap prim seq-int.push swap 1 prim -
    ]
    call
    drop
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at swap prim +
      locals { new-sum result } {
        result new-sum prim seq-int.push new-sum swap
      }
    ]
    call
    drop drop
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at
      locals { val result xs i } {
        val 0 prim >
        [ result val prim seq-int.push ] [ result ] if
        i 1 prim + swap
      }
    ]
    call
    drop
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    true 0
    [
      dup xs prim seq-int.len 1 prim - prim < swap prim not prim and
    ]
    [
      xs over dup 1 prim + prim seq-int.at swap prim seq-int.at prim <=
      [ swap drop ] [ drop false ] if
      swap 1 prim + swap
    ]
    call
    swap drop
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs over prim seq-int.at ys over prim seq-int.at prim *
      swap prim + swap 1 prim + swap
    ]
    call
    drop
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true 0
    [
      dup flags prim seq-bool.len prim < swap prim not prim and
    ]
    [
      flags over prim seq-bool.at swap prim and swap 1 prim + swap
    ]
    call
    swap drop
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim >
    [
      xs 0 prim seq-int.at 1 1 1
      [
        dup xs prim seq-int.len prim <
      ]
      [
        xs over prim seq-int.at
        locals { curr max-run curr-run prev xs i } {
          curr prev prim =
          [ curr-run 1 prim + ] [ 1 ] if
          locals { new-curr max-run xs i } {
            new-curr max-run prim >
            [ new-curr ] [ max-run ] if
            new-curr curr i 1 prim + xs swap
          }
        }
      ]
      call
      drop drop drop drop
    ]
    [ 0 ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false 0
    [
      dup prim not xs prim seq-int.len prim < prim and
    ]
    [
      0
      [
        dup xs prim seq-int.len prim <
      ]
      [
        xs swap prim seq-int.at xs swap dup 1 prim + swap prim seq-int.at prim +
        target prim =
        [ swap drop xs prim seq-int.len ] [ 1 prim + ] if
      ]
      call
      drop swap
    ]
    call
    drop
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at
      locals { val xs i seen } {
        0
        [
          dup seen prim seq-int.len prim <
        ]
        [
          seen over prim seq-int.at val prim =
          [ seen prim seq-int.len ] [ 1 prim + ] if
        ]
        call
        drop
        locals { found seen val xs i } {
          found seen prim seq-int.len prim =
          [ seen val prim seq-int.push ] [ seen ] if
          i 1 prim + swap
        }
      }
    ]
    call
    drop prim seq-int.len
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0
    [
      dup xs prim seq-int.len prim < swap dup ys prim seq-int.len prim < prim and
    ]
    [
      xs swap dup prim seq-int.at ys swap dup prim seq-int.at prim <=
      [
        swap prim seq-int.push swap 1 prim + swap
      ]
      [
        swap prim seq-int.push swap 1 prim + swap
      ]
      if
    ]
    call
    drop drop
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty n prim not
      [
        dup 0 prim >
      ]
      [
        dup 10 prim mod swap prim seq-int.push swap 1 prim + swap
        dup 10 prim div
      ]
      call
      drop
      locals { result n } {
        prim seq-int.empty result prim seq-int.len 1 prim -
        [
          dup 0 prim >=
        ]
        [
          result over prim seq-int.at swap prim seq-int.push swap 1 prim -
        ]
        call
        drop
      }
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2
    [
      dup n prim <=
    ]
    [
      dup 2
      [
        dup dup prim * swap dup 1 prim + swap prim <= [ dup prim * swap dup 1 prim + swap prim <= ] prim and
      ]
      [
        dup swap prim mod 0 prim = [ prim seq-int.len 0 ] [ 1 prim + ] if
      ]
      call
      drop
      locals { is-prime result n } {
        is-prime 0 prim =
        [ result swap dup prim seq-int.push ] [ result swap ] if
        1 prim + swap
      }
    ]
    call
    drop
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0
    [
      dup k prim <
    ]
    [
      swap 0 prim seq-int.push swap 1 prim +
    ]
    call
    drop
    locals { counts xs } {
      0
      [
        dup xs prim seq-int.len prim <
      ]
      [
        xs over prim seq-int.at
        locals { v counts xs i } {
          counts v prim seq-int.at 1 prim + v counts prim seq-int.set
          i 1 prim +
        }
      ]
      call
      drop
    }
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0
    [
      dup xs prim seq-int.len 1 prim - prim <
    ]
    [
      swap
      [
        dup 0 prim >
      ]
      [
        dup 1 prim - dup
        locals { j i arr } {
          arr j prim seq-int.at arr j 1 prim + prim seq-int.at prim >
          [
            arr j prim seq-int.at arr j 1 prim + prim seq-int.at
            arr j 1 prim + prim seq-int.at arr j prim seq-int.set
            locals { temp arr } {
              arr j temp prim seq-int.set
            }
            j 1 prim -
          ]
          [ 0 ]
          if
        }
      ]
      call
      drop 1 prim + swap
    ]
    call
    drop
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0
    [
      dup txs prim seq-int.len prim <
    ]
    [
      txs over prim seq-int.at
      locals { tx balance rejected txs i } {
        balance tx prim + 0 prim >=
        [ balance tx prim + rejected ] [ balance rejected 1 prim + ] if
        i 1 prim + swap
      }
    ]
    call
    drop
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty 0
    [
      dup qtys prim seq-int.len prim <
    ]
    [
      items over prim seq-int.at
      locals { item stock allocated reasons qtys items whole j } {
        stock item prim seq-int.at
        locals { r stock allocated reasons } {
          qtys j prim seq-int.at r prim <=
          [
            qtys j prim seq-int.at stock item prim seq-int.at qtys j prim seq-int.at prim - item stock prim seq-int.set
            allocated qtys j prim seq-int.at prim seq-int.push
            reasons 0 prim seq-int.push
          ]
          [
            r 0 prim =
            [
              stock allocated reasons 2 prim seq-int.push
            ]
            [
              whole j prim seq-bool.at
              [
                stock allocated reasons 3 prim seq-int.push
              ]
              [
                stock item 0 item stock prim seq-int.set
                allocated r prim seq-int.push
                reasons 1 prim seq-int.push
              ]
              if
            ]
            if
          ]
          if
          stock allocated reasons j 1 prim + swap
        }
      }
    ]
    call
    drop
  };
```
