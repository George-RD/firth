### task: digits
```firth
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim >
    [
      result n 10 prim mod prim seq-int.push
      locals { result } {
        n 10 prim div result digits-loop
      }
    ]
    [
      result
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many digits:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i digits result } {
    i 0 prim >=
    [
      result digits i prim seq-int.at prim seq-int.push
      locals { result } { i 1 prim - result digits reverse-digits }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ]
    [
      n prim seq-int.empty digits-loop
      locals { digits } {
        digits prim seq-int.len 1 prim - prim seq-int.empty digits reverse-digits
      }
    ]
    if
  };
```

### task: histogram
```firth
: histogram-loop
  (forall ρ; ρ i:Int^many histogram:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i histogram xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup histogram swap prim seq-int.at 1 prim +
      locals { value index } {
        histogram index value prim seq-int.set
        locals { histogram } { i 1 prim + histogram xs histogram-loop }
      }
    ]
    [
      histogram
    ]
    if
  };

: init-hist-loop
  (forall ρ; ρ k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k result } {
    k 0 prim >
    [
      result 0 prim seq-int.push
      locals { result } { k 1 prim - result init-hist-loop }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    0 k prim seq-int.empty init-hist-loop xs histogram-loop
  };
```

### task: sort
```firth
: find-min-loop
  (forall ρ; ρ j:Int^many min-idx:Int^many min-val:Int^many xs:Seq Int^many -- ρ min-idx:Int^many)
  locals { j min-idx min-val xs } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at min-val prim <
      [
        j j xs j prim seq-int.at xs find-min-loop
      ]
      [
        min-idx j 1 prim + min-val xs find-min-loop
      ]
      if
    ]
    [
      min-idx
    ]
    if
  };

: find-min
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ min-idx:Int^many)
  locals { i xs } {
    i 1 prim + i xs i prim seq-int.at xs find-min-loop
  };

: sort-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [
      i xs find-min
      xs swap prim seq-int.at
      result swap prim seq-int.push
      locals { result } { i 1 prim + result xs sort-loop }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    0 prim seq-int.empty xs sort-loop
  };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ i:Int^many balance:Int^many rejected:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { i balance rejected txs } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + dup 0 prim >=
      [
        locals { balance } { i 1 prim + balance rejected txs ledger-loop }
      ]
      [
        drop i 1 prim + balance rejected 1 prim + txs ledger-loop
      ]
      if
    ]
    [
      balance rejected
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    0 start 0 txs ledger-loop
  };
```

### task: allocate-batch
```firth
: allocate-loop
  (forall ρ; ρ o:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { o stock allocated reasons items qtys whole } {
    o qtys prim seq-int.len prim <
    [
      allocated 0 prim seq-int.push
      reasons 0 prim seq-int.push
      locals { allocated reasons } { o 1 prim + stock allocated reasons items qtys whole allocate-loop }
    ]
    [
      stock allocated reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0 stock prim seq-int.empty prim seq-int.empty items qtys whole allocate-loop
  };
```
