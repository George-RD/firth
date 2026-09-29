### task: seq-sum
```firth
: sum-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { new_acc } { xs i 1 prim + new_acc sum-aux } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-aux };
```

### task: seq-max
```firth
: max-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem max prim < [ max ] [ elem ] if locals { new_max } { xs i 1 prim + new_max max-aux } } ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-aux };
```

### task: count-below
```firth
: count-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many acc:Int^many -- ρ count:Int^many)
  locals { xs i k acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem k prim < [ acc 1 prim + ] [ acc ] if locals { new_acc } { xs i 1 prim + k new_acc count-aux } } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs 0 k 0 count-aux };
```

### task: index-of
```firth
: index-aux
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem x prim = [ i ] [ xs x i 1 prim + index-aux ] if } ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 index-aux };
```

### task: reverse
```firth
: reverse-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push locals { new_result } { xs i 1 prim - new_result reverse-aux } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-aux };
```

### task: prefix-sums
```firth
: prefix-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { new_acc } { new_acc result prim seq-int.push locals { new_result } { xs i 1 prim + new_acc new_result prefix-aux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-aux };
```

### task: keep-positive
```firth
: keep-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem 0 prim < [ result ] [ result elem prim seq-int.push ] if locals { new_result } { xs i 1 prim + new_result keep-aux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-aux };
```

### task: is-sorted
```firth
: sorted-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ xs i 1 prim + sorted-aux ] [ 0 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sorted-aux };
```

### task: dot
```firth
: dot-aux
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + locals { new_acc } { xs ys i 1 prim + new_acc dot-aux } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-aux };
```

### task: all-true
```firth
: all-aux
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at [ i 1 prim + flags all-aux ] [ 0 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-aux };
```

### task: longest-run
```firth
: run-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many current:Int^many max:Int^many -- ρ length:Int^many)
  locals { xs i current max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem xs i 1 prim + prim seq-int.at prim = [ current 1 prim + locals { new_current } { xs i 1 prim + new_current max run-aux } ] [ current 1 prim + locals { new_max } { max current 1 prim + prim < [ current 1 prim + ] [ new_max ] if locals { next_max } { xs i 1 prim + 1 next_max run-aux } } ] if } ]
    [ max current prim < [ current ] [ max ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 1 0 run-aux };
```

### task: has-pair-sum
```firth
: pair-aux
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { a } { i 1 prim + locals { j } { [ j xs prim seq-int.len prim < [ xs j prim seq-int.at a prim + target prim = [ 1 ] [ j 1 prim + ] if ] [ 0 ] if ] [ j 1 prim + ] compose call [ pair-aux ] [ 0 ] if } } ]
    [ 0 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pair-aux };
```

### task: count-distinct
```firth
: distinct-count
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ count:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { 0 locals { j found } { [ j seen prim seq-int.len prim < [ seen j prim seq-int.at elem prim = [ 1 ] [ j 1 prim + ] if ] [ found ] if ] [ j 1 prim + ] compose call prim not [ seen elem prim seq-int.push locals { new_seen } { xs i 1 prim + new_seen distinct-count } ] [ xs i 1 prim + seen distinct-count ] if } } ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty distinct-count };
```

### task: merge-sorted
```firth
: merge-aux
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim < [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push locals { new_result } { xs ys i 1 prim + j new_result merge-aux } ] [ result ys j prim seq-int.at prim seq-int.push locals { new_result } { xs ys i j 1 prim + new_result merge-aux } ] if ] [ result xs i prim seq-int.at prim seq-int.push locals { new_result } { xs ys i 1 prim + j new_result merge-aux } ] if ]
    [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push locals { new_result } { xs ys i j 1 prim + new_result merge-aux } ] [ result ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-aux };
```

### task: digits
```firth
: digit-aux
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim <
    [ n prim not locals { pos } { pos 10 prim mod result prim seq-int.push locals { new_result } { pos 10 prim div new_result digit-aux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digit-aux ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ 0 ]
    [ n 2 prim = [ 1 ] [ 2 locals { d } { [ d d prim * n prim < ] [ n d prim mod 0 prim = [ 0 ] [ d 1 prim + ] if ] compose call prim not ] if ] if
    if
  };

: primes-aux
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n current result } {
    current n prim <
    [ current is-prime [ result current prim seq-int.push locals { new_result } { n current 1 prim + new_result primes-aux } ] [ n current 1 prim + result primes-aux ] if ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-aux };
```

### task: histogram
```firth
: histogram-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs i k counts } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { idx } { idx counts idx prim seq-int.at 1 prim + prim seq-int.set locals { new_counts } { xs i 1 prim + k new_counts histogram-aux } } ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty locals { counts } {
      [ counts prim seq-int.len k prim < ] [ counts 0 prim seq-int.push ] compose call
      xs 0 k counts histogram-aux
    }
  };
```

### task: sort
```firth
: insert-aux
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i sorted prim seq-int.len prim <
    [ sorted i prim seq-int.at x prim < [ sorted i x prim seq-int.set locals { new_sorted } { x new_sorted i 1 prim + insert-aux } ] [ x sorted i insert-aux ] if ]
    [ sorted x prim seq-int.push ]
    if
  };

: sort-aux
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sorted 0 insert-aux locals { new_sorted } { xs i 1 prim + new_sorted sort-aux } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-aux };
```

### task: ledger
```firth
: ledger-aux
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { new_balance } { new_balance 0 prim < [ balance i 1 prim + rejected ledger-aux ] [ new_balance i 1 prim + rejected ledger-aux ] if } } ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-aux };
```

### task: allocate-batch
```firth
: allocate-aux
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at locals { item } { stock item prim seq-int.at locals { current_stock } { qtys i prim seq-int.at locals { qty } { whole i prim seq-bool.at locals { w } { qty current_stock prim < [ current_stock 0 prim = [ stock allocated qty prim seq-int.push reasons 2 prim seq-int.push locals { a r } { a r i 1 prim + allocate-aux } ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ stock item current_stock prim seq-int.set allocated current_stock prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] [ stock item current_stock qty prim - prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { s a r } { s a r i 1 prim + allocate-aux } ] if } } } } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-aux };
```
