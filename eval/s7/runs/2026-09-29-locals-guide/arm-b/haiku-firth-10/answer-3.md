### task: reverse
```firth
: reverse-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { acc xs i } {
    i 0 prim =
    [ acc ]
    [ acc xs i 1 prim - prim seq-int.at prim seq-int.push locals { new-acc } { new-acc xs i 1 prim - reverse-helper } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-helper };
```

### task: is-sorted
```firth
: sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim =
    [ true ]
    [ xs i 1 prim + prim seq-int.at xs i prim seq-int.at prim < [ false ] [ xs i 1 prim + sorted-helper ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs prim seq-int.len 1 prim < [ true ] [ xs 0 sorted-helper ] if };
```

### task: longest-run
```firth
: run-helper
  (forall ρ; ρ len:Int^many last:Int^many xs:Seq Int^many i:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { len last xs i max-len } {
    i xs prim seq-int.len prim =
    [ len max-len prim < [ len ] [ max-len ] if ]
    [ xs i prim seq-int.at locals { val } { val last prim = [ len 1 prim + locals { new-len } { new-len val xs i 1 prim + new-len max-len prim < [ max-len ] [ new-len ] if run-helper } ] [ 1 val xs i 1 prim + max-len 1 prim < [ max-len ] [ 1 ] if run-helper ] if } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ 1 xs 0 xs 0 prim seq-int.at 0 run-helper ] if };
```

### task: count-distinct
```firth
: count-distinct-helper
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    i xs prim seq-int.len prim =
    [ count ]
    [ xs i prim seq-int.at locals { val } { val i find-earlier [ count xs i 1 prim + count-distinct-helper ] [ count 1 prim + xs i 1 prim + count-distinct-helper ] if } ]
    if
  };

: find-earlier
  (forall ρ; ρ val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { val i } {
    i 0 prim =
    [ false ]
    [ val i 1 prim - ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 xs 0 count-distinct-helper };
```

### task: digits
```firth
: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ result n 10 prim mod prim seq-int.push n 10 prim div digits-helper ]
    if
  };

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-seq-helper };

: reverse-seq-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { acc xs i } {
    i 0 prim =
    [ acc ]
    [ acc xs i 1 prim - prim seq-int.at prim seq-int.push locals { new-acc } { new-acc xs i 1 prim - reverse-seq-helper } ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { 
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digits-helper reverse-seq ]
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim <
    [ n i prim mod 0 prim = [ false ] [ n i 1 prim + is-prime ] if ]
    [ true ]
    if
  };

: primes-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many current:Int^many -- ρ final:Seq Int^many)
  locals { result n current } {
    current n prim < [ current n prim < [ true ] [ false ] if ] [ false ] if [ false ] [ current 2 prim < [ result current 1 prim + n primes-helper ] [ current 2 is-prime [ result current prim seq-int.push current 1 prim + n primes-helper ] [ result current 1 prim + n primes-helper ] if ] if ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty n 2 primes-helper };
```

### task: histogram
```firth
: histogram-helper
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim =
    [ counts ]
    [ xs i prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + locals { new-val } { counts v new-val prim seq-int.set xs i 1 prim + histogram-helper } } ]
    if
  };

: init-counts
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k } {
    i k prim =
    [ counts ]
    [ counts 0 prim seq-int.push locals { new-counts } { new-counts i 1 prim + k init-counts } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k init-counts xs 0 histogram-helper };
```

### task: sort
```firth
: insertion-sort
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim =
    [ result ]
    [ xs i prim seq-int.at locals { x } { x result 0 insert-into xs i 1 prim + insertion-sort } ]
    if
  };

: insert-into
  (forall ρ; ρ x:Int^many result:Seq Int^many pos:Int^many -- ρ final:Seq Int^many)
  locals { x result pos } {
    pos result prim seq-int.len prim =
    [ result x prim seq-int.push ]
    [ result pos prim seq-int.at x prim < [ result x prim seq-int.push ] [ result pos prim seq-int.at result pos result pos prim seq-int.at prim seq-int.set x result pos 1 prim + insert-into ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 insertion-sort };
```

### task: allocate-batch
```firth
: allocate-one
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    items j prim seq-int.at locals { item } {
      stock item prim seq-int.at locals { r } {
        qtys j prim seq-int.at locals { qty } {
          qty r prim <
          [ r 0 prim =
            [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock items qtys whole j allocate-continue ]
            [ whole j prim seq-bool.at
              [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock items qtys whole j allocate-continue ]
              [ allocated r prim seq-int.push reasons 1 prim seq-int.push stock 0 item prim seq-int.set items qtys whole j allocate-continue ]
              if
            ]
            if
          ]
          [ qty r prim =
            [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock qty item prim seq-int.set items qtys whole j allocate-continue ]
            [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock qty item prim seq-int.set items qtys whole j allocate-continue ]
            if
          ]
          if
        }
      }
    }
  };

: allocate-continue
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    j 1 prim + qtys prim seq-int.len prim < [ stock allocated reasons items qtys whole j 1 prim + allocate-loop ] [ stock allocated reasons ] if
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    j qtys prim seq-int.len prim =
    [ stock allocated reasons ]
    [ stock allocated reasons items qtys whole j allocate-one ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-loop };
```
