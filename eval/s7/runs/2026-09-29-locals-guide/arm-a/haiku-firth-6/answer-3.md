### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { 0 xs prim seq-int.len xs is-sorted-loop };

: is-sorted-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i len xs } {
    i len 1 prim - prim <
    [
      xs i 1 prim + prim seq-int.at
      xs i prim seq-int.at
      locals { next-elem curr-elem } {
        curr-elem next-elem prim <
        [
          i 1 prim +
          len
          xs
          is-sorted-loop
        ]
        [ false ]
        if
      }
    ]
    [ true ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len
    locals { len } {
      len 0 prim =
      [ 0 ]
      [
        xs 0 prim seq-int.at
        1
        1
        1
        xs
        len
        longest-run-loop
      ]
      if
    }
  };

: longest-run-loop
  (forall ρ; ρ prev:Int^many run-len:Int^many max-len:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { prev run-len max-len i xs len } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem prev prim =
        [
          run-len 1 prim +
          locals { new-run } {
            new-run max-len prim <
            [ new-run ]
            [ max-len ]
            if
            locals { new-max } {
              elem new-run new-max i 1 prim + xs len longest-run-loop
            }
          }
        ]
        [
          run-len max-len prim <
          [ run-len ]
          [ max-len ]
          if
          locals { new-max } {
            elem 1 new-max i 1 prim + xs len longest-run-loop
          }
        ]
        if
      }
    ]
    [ max-len ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len xs target check-pairs };

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ output:Bool^many)
  locals { i len xs target } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { first } {
        i 1 prim +
        len
        xs
        target
        first
        i
        check-inner
      }
    ]
    [ false ]
    if
  };

: check-inner
  (forall ρ; ρ j:Int^many len:Int^many xs:Seq Int^many target:Int^many first:Int^many i:Int^many -- ρ output:Bool^many)
  locals { j len xs target first i } {
    j len prim <
    [
      xs j prim seq-int.at
      first prim +
      target prim =
      [
        true
      ]
      [
        j 1 prim +
        len
        xs
        target
        first
        i
        check-inner
      ]
      if
    ]
    [
      i 1 prim +
      len
      xs
      target
      check-pairs
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ output:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
      ]
      [ result ]
      if
      candidate 1 prim +
      n
      primes-loop
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim <
    [ false ]
    [
      num 2 prim =
      [ true ]
      [
        num 2 prim mod
        0 prim =
        [ false ]
        [
          3
          num
          is-prime-check
        ]
        if
      ]
      if
    ]
    if
  };

: is-prime-check
  (forall ρ; ρ i:Int^many num:Int^many -- ρ prime:Bool^many)
  locals { i num } {
    num i i prim * prim <
    prim not
    [
      num i prim mod
      0 prim =
      [ false ]
      [
        i 2 prim +
        num
        is-prime-check
      ]
      if
    ]
    [ true ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k xs histogram-init };

: histogram-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { result i k xs } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      xs
      histogram-init
    ]
    [
      0 result xs k histogram-fill
    ]
    if
  };

: histogram-fill
  (forall ρ; ρ elem-idx:Int^many result:Seq Int^many xs:Seq Int^many k:Int^many -- ρ output:Seq Int^many)
  locals { elem-idx result xs k } {
    elem-idx xs prim seq-int.len prim <
    [
      xs elem-idx prim seq-int.at
      locals { elem } {
        result elem prim seq-int.at
        locals { count } {
          result elem count 1 prim + prim seq-int.set
          locals { new-result } {
            elem-idx 1 prim +
            new-result
            xs
            k
            histogram-fill
          }
        }
      }
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len 0 sort-pass };

: sort-pass
  (forall ρ; ρ seq:Seq Int^many pass:Int^many len:Int^many swapped:Int^many -- ρ result:Seq Int^many)
  locals { seq pass len swapped } {
    swapped 0 prim =
    [ seq ]
    [
      0 seq len sort-bubble
    ]
    if
  };

: sort-bubble
  (forall ρ; ρ i:Int^many seq:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { i seq len } {
    i len 1 prim - prim <
    [
      seq i prim seq-int.at
      seq i 1 prim + prim seq-int.at
      locals { next curr } {
        curr next prim <
        prim not
        [
          seq i next prim seq-int.set
          locals { seq-after-first } {
            seq-after-first i 1 prim + curr prim seq-int.set
            locals { seq-final } {
              i 1 prim +
              seq-final
              len
              sort-bubble
            }
          }
        ]
        [
          i 1 prim +
          seq
          len
          sort-bubble
        ]
        if
      }
    ]
    [ seq ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len items qtys whole allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons order len items qtys whole } {
    order len prim <
    [
      items order prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { current-stock } {
          qtys order prim seq-int.at
          locals { qty } {
            qty current-stock prim <
            [
              qty 0 prim =
              [ qty 2 ]
              [ qty 0 ]
              if
            ]
            [
              current-stock 0 prim =
              [ 0 2 ]
              [
                whole order prim seq-bool.at
                [
                  0 3
                ]
                [ current-stock 1 ]
                if
              ]
              if
            ]
            if
            locals { alloc reason } {
              stock item current-stock alloc prim - prim seq-int.set
              locals { new-stock } {
                allocated alloc prim seq-int.push
                locals { new-allocated } {
                  reasons reason prim seq-int.push
                  locals { new-reasons } {
                    new-stock
                    new-allocated
                    new-reasons
                    order 1 prim +
                    len
                    items
                    qtys
                    whole
                    allocate-loop
                  }
                }
              }
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };
```
