### task: digits
```firth
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim >
    [ n 10 prim div result n 10 prim mod prim seq-int.push digit-loop ]
    [ result ]
    if
  };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim >=
    [ xs idx 1 prim - result xs idx prim seq-int.at prim seq-int.push reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ n prim seq-int.empty digit-loop dup prim seq-int.len 1 prim - prim seq-int.empty reverse-loop ]
    if
  };
```

### task: histogram
```firth
: count-value
  (forall ρ; ρ xs:Seq Int^many val:Int^many idx:Int^many cnt:Int^many -- ρ cnt:Int^many)
  locals { xs val idx cnt } {
    idx xs prim seq-int.len prim <
    [ xs val idx 1 prim + xs idx prim seq-int.at val prim = [ cnt 1 prim + ] [ cnt ] if count-value ]
    [ cnt ]
    if
  };

: hist-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k idx result } {
    idx k prim <
    [ xs idx 0 0 count-value result swap prim seq-int.push xs swap k swap idx 1 prim + swap hist-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    xs k 0 prim seq-int.empty hist-loop
  };
```

### task: sort
```firth
: insert-loop
  (forall ρ; ρ result:Seq Int^many val:Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result val idx } {
    idx 0 prim >=
    [ result idx prim seq-int.at val prim <=
      [ result val idx 1 prim + insert-loop ]
      [ result idx val prim seq-int.set ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [ result xs idx prim seq-int.at 0 insert-loop xs idx 1 prim + swap sort-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };
```

### task: allocate-batch
```firth
: alloc-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many oidx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole oidx allocated reasons } {
    oidx qtys prim seq-int.len prim <
    [
      stock items oidx prim seq-int.at prim seq-int.at qtys oidx prim seq-int.at prim <=
      [
        stock items oidx prim seq-int.at dup qtys oidx prim seq-int.at prim - prim seq-int.set
        locals { stock } {
          stock items qtys whole oidx 1 prim + allocated qtys oidx prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push alloc-loop
        }
      ]
      [
        stock items oidx prim seq-int.at prim seq-int.at 0 prim =
        [
          stock items qtys whole oidx 1 prim + allocated 0 prim seq-int.push reasons 2 prim seq-int.push alloc-loop
        ]
        [
          whole oidx prim seq-bool.at
          [
            stock items qtys whole oidx 1 prim + allocated 0 prim seq-int.push reasons 3 prim seq-int.push alloc-loop
          ]
          [
            stock items oidx prim seq-int.at prim seq-int.at
            stock items oidx prim seq-int.at 0 prim seq-int.set
            locals { old-val stock } {
              stock items qtys whole oidx 1 prim + allocated old-val prim seq-int.push reasons 1 prim seq-int.push alloc-loop
            }
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty alloc-loop
  };
```
