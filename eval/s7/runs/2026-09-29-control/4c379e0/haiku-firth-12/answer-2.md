### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ xs:Seq Int i:Int acc:Int -- ρ result:Int)
  locals { xs i acc }
  {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { new-acc } { xs i 1 prim + new-acc sum-loop } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  0 0 sum-loop;
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ xs:Seq Int i:Int current-max:Int -- ρ result:Int)
  locals { xs i current-max }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at current-max
      locals { val cur-max }
      { val cur-max prim < [ cur-max ] [ val ] if }
      locals { new-max }
      { xs i 1 prim + new-max max-loop }
    ]
    [ current-max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  locals { xs } { xs 0 prim seq-int.at 1 max-loop };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ xs:Seq Int k:Int i:Int count:Int -- ρ result:Int)
  locals { xs k i count }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [ xs k i 1 prim + count 1 prim + count-loop ]
      [ xs k i 1 prim + count count-loop ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int k:Int -- ρ result:Int)
  locals { xs k } { xs k 0 0 count-loop };
```

### task: index-of
```firth
: index-loop
  (forall ρ; ρ xs:Seq Int x:Int i:Int -- ρ result:Int)
  locals { xs x i }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [ i ]
      [ xs x i 1 prim + index-loop ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int x:Int -- ρ result:Int)
  locals { xs x } { xs x 0 index-loop };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i result }
  {
    i 0 prim <
    [ xs i 1 prim + prim - locals { new-i } { xs new-i xs new-i prim seq-int.at prim seq-int.push result prim seq-int.push reverse-loop } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs }
  {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ xs:Seq Int i:Int sum:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i sum result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim + 
      locals { new-sum }
      { xs i 1 prim + new-sum result new-sum prim seq-int.push prefix-loop }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };
```

### task: keep-positive
```firth
: filter-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [ xs i 1 prim + result filter-loop ]
      [ xs i 1 prim + xs i prim seq-int.at prim seq-int.push result prim seq-int.push filter-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs } { xs 0 prim seq-int.empty filter-loop };
```

### task: is-sorted
```firth
: check-loop
  (forall ρ; ρ xs:Seq Int i:Int -- ρ result:Bool)
  locals { xs i }
  {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + check-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Bool)
  locals { xs }
  {
    xs prim seq-int.len 1 prim <=
    [ true ]
    [ xs 0 check-loop ]
    if
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ xs:Seq Int ys:Seq Int i:Int sum:Int -- ρ result:Int)
  locals { xs ys i sum }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      sum prim +
      locals { new-sum }
      { xs ys i 1 prim + new-sum dot-loop }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int ys:Seq Int -- ρ result:Int)
  locals { xs ys } { xs ys 0 0 dot-loop };
```

### task: all-true
```firth
: check-all-loop
  (forall ρ; ρ flags:Seq Bool i:Int -- ρ result:Bool)
  locals { flags i }
  {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at prim not
      [ false ]
      [ flags i 1 prim + check-all-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool -- ρ result:Bool)
  locals { flags } { flags 0 check-all-loop };
```

### task: longest-run
```firth
: run-loop
  (forall ρ; ρ xs:Seq Int i:Int val:Int len:Int max-len:Int -- ρ result:Int)
  locals { xs i val len max-len }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at val prim =
      [
        len 1 prim +
        locals { new-len }
        {
          new-len max-len prim < [ new-len ] [ max-len ] if
          locals { new-max }
          { xs i 1 prim + val new-len new-max run-loop }
        }
      ]
      [
        max-len len prim < [ len ] [ max-len ] if
        locals { new-max }
        { xs i 1 prim + xs i prim seq-int.at 1 new-max run-loop }
      ]
      if
    ]
    [ max-len len prim < [ len ] [ max-len ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  locals { xs }
  {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 xs 0 prim seq-int.at 1 0 run-loop ]
    if
  };
```

### task: has-pair-sum
```firth
: inner-loop
  (forall ρ; ρ xs:Seq Int target:Int i:Int j:Int -- ρ result:Bool)
  locals { xs target i j }
  {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [ xs target i j 1 prim + inner-loop ]
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ xs target i j 1 prim + inner-loop ]
        if
      ]
      if
    ]
    [ false ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int target:Int i:Int -- ρ result:Bool)
  locals { xs target i }
  {
    i xs prim seq-int.len prim <
    [
      xs target i 0 inner-loop
      [ true ]
      [ xs target i 1 prim + outer-loop ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int target:Int -- ρ result:Bool)
  locals { xs target } { xs target 0 outer-loop };
```

### task: count-distinct
```firth
: is-in-result
  (forall ρ; ρ result:Seq Int val:Int i:Int -- ρ result:Bool)
  locals { result val i }
  {
    i result prim seq-int.len prim <
    [
      result i prim seq-int.at val prim =
      [ true ]
      [ result val i 1 prim + is-in-result ]
      if
    ]
    [ false ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Int)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at 0 is-in-result
      [ xs i 1 prim + result count-loop ]
      [ xs i 1 prim + xs i prim seq-int.at prim seq-int.push result prim seq-int.push count-loop ]
      if
    ]
    [ result prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  locals { xs } { xs 0 prim seq-int.empty count-loop };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ xs:Seq Int ys:Seq Int i:Int j:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs ys i j result }
  {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          xs ys i 1 prim + j xs i prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop
        ]
        [
          xs ys i j 1 prim + ys j prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop
        ]
        if
      ]
      [
        xs ys i xs prim seq-int.len prim <
        [ xs ys i 1 prim + j xs i prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop ]
        [ result ]
        if
      ]
      if
    ]
    [
      xs ys i j ys prim seq-int.len prim <
      [ xs ys i j 1 prim + ys j prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int ys:Seq Int -- ρ result:Seq Int)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ n:Int result:Seq Int -- ρ result:Seq Int)
  locals { n result }
  {
    n 0 prim =
    [ result ]
    [ result n 10 prim mod prim seq-int.push locals { new-result } { n 10 prim div new-result digits-loop } ]
    if
  };

: reverse-result
  (forall ρ; ρ result:Seq Int i:Int reversed:Seq Int -- ρ result:Seq Int)
  locals { result i reversed }
  {
    i 0 prim <
    [ result i 1 prim - locals { new-i } { result new-i result new-i prim seq-int.at prim seq-int.push reversed prim seq-int.push reverse-result } ]
    [ reversed ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ result:Seq Int)
  locals { n }
  {
    n 0 prim =
    [ { 0 } ]
    [
      n prim seq-int.empty digits-loop
      locals { temp }
      { temp temp prim seq-int.len 1 prim - prim seq-int.empty reverse-result }
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ num:Int divisor:Int -- ρ result:Bool)
  locals { num divisor }
  {
    divisor divisor prim * num prim <=
    [
      num divisor prim mod 0 prim =
      [ false ]
      [ num divisor 1 prim - is-prime ]
      if
    ]
    [ true ]
    if
  };

: collect-loop
  (forall ρ; ρ n:Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { n i result }
  {
    i n prim <=
    [
      i 2 is-prime
      [ n i result 1 prim + prim seq-int.push collect-loop ]
      [ n i result 1 prim + collect-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ result:Seq Int)
  locals { n } { n 2 prim seq-int.empty collect-loop };
```

### task: histogram
```firth
: init-counts
  (forall ρ; ρ k:Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { k i result }
  {
    i k prim <
    [ k i 1 prim + 0 prim seq-int.push result prim seq-int.push init-counts ]
    [ result ]
    if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int k:Int i:Int counts:Seq Int -- ρ result:Seq Int)
  locals { xs k i counts }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val }
      {
        counts val prim seq-int.at 1 prim + locals { new-count } { counts val new-count prim seq-int.set locals { new-counts } { xs k i 1 prim + new-counts histogram-loop } }
      }
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int k:Int -- ρ result:Seq Int)
  locals { xs k } { k 0 prim seq-int.empty init-counts locals { init } { xs k 0 init histogram-loop } };
```

### task: sort
```firth
: insert-sorted
  (forall ρ; ρ sorted:Seq Int val:Int i:Int -- ρ result:Seq Int)
  locals { sorted val i }
  {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at val prim <
      [ sorted val sorted i prim seq-int.at prim seq-int.set i 1 prim - insert-sorted ]
      [ sorted val prim seq-int.set ]
      if
    ]
    [ sorted val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int i:Int sorted:Seq Int -- ρ result:Seq Int)
  locals { xs i sorted }
  {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sorted 0 insert-sorted locals { new-sorted } { xs i 1 prim + new-sorted sort-loop } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };
```

### task: ledger
```firth
: txn-loop
  (forall ρ; ρ txs:Seq Int i:Int balance:Int rejected:Int -- ρ balance:Int rejected:Int)
  locals { txs i balance rejected }
  {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [ txs i 1 prim + balance rejected 1 prim + txn-loop ]
      [ txs i 1 prim + balance txs i prim seq-int.at prim + rejected txn-loop ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int txs:Seq Int -- ρ balance:Int rejected:Int)
  locals { start txs } { txs 0 start 0 txn-loop };
```

### task: allocate-batch
```firth
: allocate-one
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool order:Int allocated:Seq Int reasons:Seq Int -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  locals { stock items qtys whole order allocated reasons }
  {
    order items prim seq-int.len prim <
    [
      items order prim seq-int.at
      locals { item-idx }
      {
        stock item-idx prim seq-int.at
        locals { avail }
        {
          qtys order prim seq-int.at avail prim <=
          [
            stock item-idx avail qtys order prim seq-int.at prim - prim seq-int.set
            stock items qtys whole order 1 prim + qtys order prim seq-int.at prim seq-int.push allocated prim seq-int.push 0 prim seq-int.push reasons prim seq-int.push allocate-one
          ]
          [
            avail 0 prim =
            [
              stock items qtys whole order 1 prim + 0 prim seq-int.push allocated prim seq-int.push 2 prim seq-int.push reasons prim seq-int.push allocate-one
            ]
            [
              whole order prim seq-bool.at
              [
                stock items qtys whole order 1 prim + 0 prim seq-int.push allocated prim seq-int.push 3 prim seq-int.push reasons prim seq-int.push allocate-one
              ]
              [
                stock item-idx 0 prim seq-int.set
                stock items qtys whole order 1 prim + avail prim seq-int.push allocated prim seq-int.push 1 prim seq-int.push reasons prim seq-int.push allocate-one
              ]
              if
            ]
            if
          ]
          if
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-one };
```
