### task: seq-sum
```firth
: sumaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { nacc } { xs i 1 prim + nacc sumaux } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sumaux };
```

### task: seq-max
```firth
: maxaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem max prim < [ max ] [ elem ] if locals { nmax } { xs i 1 prim + nmax maxaux } } ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at maxaux };
```

### task: count-below
```firth
: countaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many acc:Int^many -- ρ count:Int^many)
  locals { xs i k acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem k prim < [ acc 1 prim + ] [ acc ] if locals { nacc } { xs i 1 prim + k nacc countaux } } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs 0 k 0 countaux };
```

### task: reverse
```firth
: reverseaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push locals { nresult } { xs i 1 prim - nresult reverseaux } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverseaux };
```

### task: prefix-sums
```firth
: prefixaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { nacc } { nacc result prim seq-int.push locals { nresult } { xs i 1 prim + nacc nresult prefixaux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefixaux };
```

### task: keep-positive
```firth
: keepaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem 0 prim < [ result ] [ result elem prim seq-int.push ] if locals { nresult } { xs i 1 prim + nresult keepaux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keepaux };
```

### task: is-sorted
```firth
: sortedaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ xs i 1 prim + sortedaux ] [ 1 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sortedaux };
```

### task: dot
```firth
: dotaux
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + locals { nacc } { xs ys i 1 prim + nacc dotaux } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dotaux };
```

### task: all-true
```firth
: allaux
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at [ flags i 1 prim + allaux ] [ 0 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 allaux };
```

### task: longest-run
```firth
: runaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many current:Int^many max:Int^many -- ρ length:Int^many)
  locals { xs i current max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem xs i 1 prim + prim seq-int.at prim = [ current 1 prim + locals { ncurrent } { xs i 1 prim + ncurrent max runaux } ] [ current 1 prim + locals { nmax } { max current 1 prim + prim < [ current 1 prim + ] [ nmax ] if locals { nextmax } { xs i 1 prim + 1 nextmax runaux } } ] if } ]
    [ max current prim < [ current ] [ max ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 1 0 runaux };
```

### task: has-pair-sum
```firth
: pairinneraux
  (forall ρ; ρ xs:Seq Int^many target:Int^many a:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target a j } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at a prim + target prim = [ 1 ] [ j 1 prim + xs target a pairinneraux ] if ]
    [ 0 ]
    if
  };

: pairaux
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { a } { xs target a i 1 prim + pairinneraux [ xs target i 1 prim + pairaux ] [ 1 ] if } ]
    [ 0 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pairaux };
```

### task: count-distinct
```firth
: distinctcount
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ count:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { seen elem prim seq-int.push locals { nseen } { xs i 1 prim + nseen distinctcount } } ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty distinctcount };
```

### task: merge-sorted
```firth
: mergeaux
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim < [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push locals { nresult } { xs ys i 1 prim + j nresult mergeaux } ] [ result ys j prim seq-int.at prim seq-int.push locals { nresult } { xs ys i j 1 prim + nresult mergeaux } ] if ] [ result xs i prim seq-int.at prim seq-int.push locals { nresult } { xs ys i 1 prim + j nresult mergeaux } ] if ]
    [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push locals { nresult } { xs ys i j 1 prim + nresult mergeaux } ] [ result ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty mergeaux };
```

### task: digits
```firth
: digitaux
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim <
    [ n prim not locals { pos } { pos 10 prim mod result prim seq-int.push locals { nresult } { pos 10 prim div nresult digitaux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digitaux ]
    if
  };
```

### task: primes-up-to
```firth
: isprime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ 0 ]
    [ n 2 prim = [ 1 ] [ 2 locals { d } { [ d d prim * n prim < ] [ n d prim mod 0 prim = [ 0 ] [ d 1 prim + ] if ] compose call prim not ] if ] if ]
    if
  };

: primesaux
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n current result } {
    current n prim <
    [ current isprime [ result current prim seq-int.push locals { nresult } { n current 1 prim + nresult primesaux } ] [ n current 1 prim + result primesaux ] if ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primesaux };
```

### task: histogram
```firth
: histogramaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs i k counts } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { idx } { idx counts idx prim seq-int.at 1 prim + prim seq-int.set locals { ncounts } { xs i 1 prim + k ncounts histogramaux } } ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty locals { counts } {
      [ counts prim seq-int.len k prim < ] [ counts 0 prim seq-int.push ] compose call
      xs 0 k counts histogramaux
    }
  };
```

### task: sort
```firth
: insertaux
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i sorted prim seq-int.len prim <
    [ sorted i prim seq-int.at x prim < [ sorted i x prim seq-int.set locals { nsorted } { x nsorted i 1 prim + insertaux } ] [ x sorted i insertaux ] if ]
    [ sorted x prim seq-int.push ]
    if
  };

: sortaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sorted 0 insertaux locals { nsorted } { xs i 1 prim + nsorted sortaux } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sortaux };
```

### task: ledger
```firth
: ledgeraux
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { nbalance } { nbalance 0 prim < [ balance i 1 prim + rejected ledgeraux ] [ nbalance i 1 prim + rejected ledgeraux ] if } } ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledgeraux };
```

### task: allocate-batch
```firth
: allocateaux
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at locals { item } { stock item prim seq-int.at locals { curstock } { qtys i prim seq-int.at locals { qty } { whole i prim seq-bool.at locals { w } { qty curstock prim < [ curstock 0 prim = [ stock allocated qty prim seq-int.push reasons 2 prim seq-int.push locals { a r } { a r i 1 prim + allocateaux } ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ stock item curstock prim seq-int.set allocated curstock prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] [ stock item curstock qty prim - prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { s a r } { s a r i 1 prim + allocateaux } ] if } } } } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocateaux };
```
