### task: reverse
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [ result ]
    [
      i 1 prim -
      xs
      result xs i 1 prim - prim seq-int.at prim seq-int.push
      loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    xs
    prim seq-int.empty
    loop
  };
```

### task: prefix-sums
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs sum result } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at sum prim +
      result
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 xs 0 prim seq-int.empty loop };
```

### task: keep-positive
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      0 xs i prim seq-int.at prim <
      [ result xs i prim seq-int.at prim seq-int.push ]
      [ result ]
      if
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { 0 xs prim seq-int.empty loop };
```

### task: is-sorted
```firth
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sorted:Bool^many -- ρ sorted:Bool^many)
  locals { i xs sorted } {
    sorted prim not
    [ false ]
    [
      i 1 prim + xs prim seq-int.len prim <
      [
        xs i 1 prim + prim seq-int.at xs i prim seq-int.at prim <
        [ false ]
        [ i 1 prim + xs true loop ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 xs true loop ]
    if
  };
```

### task: count-distinct
```firth
: inner-loop
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many found:Bool^many -- ρ found:Bool^many)
  locals { j i xs found } {
    found
    [ true ]
    [
      j i prim <
      [
        xs i prim seq-int.at xs j prim seq-int.at prim =
        [ true ]
        [ j 1 prim + i xs false inner-loop ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: outer-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many count:Int^many -- ρ count:Int^many)
  locals { i xs count } {
    i xs prim seq-int.len prim <
    [
      0 i xs false inner-loop
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim +
      xs
      outer-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 outer-loop };
```

### task: digits
```firth
: loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim div
      result n 10 prim mod prim seq-int.push
      loop
    ]
    if
  };

: reverse-loop
  (forall ρ; ρ i:Int^many digits:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i digits result } {
    i 0 prim <
    [ result ]
    [
      i 1 prim -
      digits
      result digits i 1 prim - prim seq-int.at prim seq-int.push
      reverse-loop
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [
      n 0 prim <
      [ 
        n 0 prim -
        prim seq-int.empty
        loop
      ]
      [
        n
        prim seq-int.empty
        loop
      ]
      if
      prim seq-int.len
      prim seq-int.empty
      reverse-loop
    ]
    if
  };
```

### task: histogram
```firth
: build-init
  (forall ρ; ρ i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i k counts } {
    i k prim <
    [
      i 1 prim +
      k
      counts 0 prim seq-int.push
      build-init
    ]
    [ counts ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at
      counts xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      loop
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0
    k
    prim seq-int.empty
    build-init
    0 xs loop
  };
```

### task: sort
```firth
: insert
  (forall ρ; ρ x:Int^many i:Int^many arr:Seq Int^many -- ρ arr:Seq Int^many)
  locals { x i arr } {
    i 0 prim <
    [ arr x prim seq-int.push ]
    [
      arr i prim seq-int.at x prim <
      [
        x
        i 1 prim -
        arr
        insert
      ]
      [ arr x prim seq-int.push ]
      if
    ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at
      result prim seq-int.len 1 prim -
      result
      insert
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { 0 xs prim seq-int.empty loop };
```

### task: allocate-batch
```firth
: allocate-item
  (forall ρ; ρ item-idx:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many -- ρ allocated:Int^many reason:Int^many stock:Seq Int^many)
  locals { item-idx qty whole stock } {
    stock item-idx prim seq-int.at qty prim <
    [ qty 0 stock item-idx qty prim - prim seq-int.set ]
    [
      stock item-idx prim seq-int.at 0 prim =
      [ 0 2 stock ]
      [
        whole
        [ 0 3 stock ]
        [ stock item-idx prim seq-int.at 0 stock item-idx 0 prim seq-int.set 1 stock ]
        if
      ]
      if
    ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many)
  locals { i items qtys whole stock allocated reasons } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      stock
      allocate-item
      reasons
      allocated
      loop
    ]
    [ allocated reasons stock ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0
    items
    qtys
    whole
    stock
    prim seq-int.empty
    prim seq-int.empty
    loop
  };
```

