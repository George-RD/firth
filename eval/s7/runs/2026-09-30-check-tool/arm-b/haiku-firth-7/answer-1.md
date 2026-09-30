### task: seq-sum
```firth
: sumloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    [ i xs prim seq-int.len prim < ]
    [ xs i prim seq-int.at acc prim + locals { xs i newacc } { xs i 1 prim + newacc sumloop } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sumloop };
```

### task: seq-max
```firth
: maxloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    [ i xs prim seq-int.len prim < prim not ] [ max ] [ xs i prim seq-int.at max prim < [ max ] [ xs i prim seq-int.at ] if locals { xs i newm } { xs i 1 prim + newm maxloop } ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at maxloop };
```

### task: count-below
```firth
: countloop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    [ i xs prim seq-int.len prim < prim not ] [ count ] [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if locals { xs k i c } { xs k i 1 prim + c countloop } ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 countloop };
```

### task: index-of
```firth
: indexloop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many found:Int^many -- ρ result:Int^many)
  locals { xs x i found } {
    [ found 0 prim < prim not ] [ found ] [ xs i prim seq-int.at x prim = [ i ] [ xs x i 1 prim + found indexloop ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 -1 indexloop };
```

### task: reverse
```firth
: revloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ rev:Seq Int^many)
  locals { xs i result } {
    [ i 0 prim < prim not ] [ result ] [ xs i prim seq-int.at prim seq-int.push i 1 prim - xs revloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty revloop };
```

### task: prefix-sums
```firth
: prefixloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    [ i xs prim seq-int.len prim < prim not ] [ result ] [ xs i prim seq-int.at sum prim + dup locals { xs i ns } { result ns prim seq-int.push i 1 prim + xs prefixloop } ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty 0 prefixloop };
```

### task: keep-positive
```firth
: posloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim < prim not ] [ result ] [ xs i prim seq-int.at dup 0 prim < [ drop result ] [ prim seq-int.push ] if i 1 prim + xs posloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty posloop };
```

### task: is-sorted
```firth
: sortloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    [ i xs prim seq-int.len 1 prim - prim < prim not ] [ true ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not [ i 1 prim + xs sortloop ] [ false ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { [ xs prim seq-int.len 1 prim < ] [ true ] [ 0 xs sortloop ] if };
```

### task: dot
```firth
: dotloop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    [ i xs prim seq-int.len prim < prim not ] [ sum ] [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + xs ys dotloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dotloop };
```

### task: all-true
```firth
: allloop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many result:Bool^many -- ρ all:Bool^many)
  locals { flags i result } {
    [ result prim not ] [ false ] [ [ i flags prim seq-int.len prim < prim not ] [ result ] [ flags i prim seq-int.at result prim and i 1 prim + flags allloop ] if ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { [ flags prim seq-int.len 0 prim = ] [ true ] [ flags 0 true allloop ] if };
```

### task: longest-run
```firth
: runloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many curval:Int^many curlen:Int^many maxlen:Int^many -- ρ length:Int^many)
  locals { xs i curval curlen maxlen } {
    [ i xs prim seq-int.len 1 prim - prim < prim not ] [ [ curlen maxlen prim < ] [ maxlen ] [ curlen ] if ] [ xs i 1 prim + prim seq-int.at dup curval prim = [ drop curval curlen 1 prim + i 1 prim + xs runloop ] [ [ curlen maxlen prim < ] [ maxlen ] [ curlen ] if locals { xs i nm } { i 1 prim + xs nm runloop } ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { [ xs prim seq-int.len 0 prim = ] [ 0 ] [ xs 1 xs 0 prim seq-int.at 1 1 runloop ] if };
```

### task: has-pair-sum
```firth
: innerloop
  (forall ρ; ρ xs:Seq Int^many needed:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs needed j } {
    [ j xs prim seq-int.len prim < prim not ] [ false ] [ xs j prim seq-int.at needed prim = [ true ] [ j 1 prim + xs needed innerloop ] if ] if
  };

: outerloop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    [ i xs prim seq-int.len prim < prim not ] [ false ] [ xs i prim seq-int.at target prim - i 1 prim + xs innerloop [ true ] [ i 1 prim + xs target outerloop ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 outerloop };
```

### task: count-distinct
```firth
: checkloop
  (forall ρ; ρ xs:Seq Int^many v:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs v j } {
    [ j xs prim seq-int.len prim < prim not ] [ false ] [ xs j prim seq-int.at v prim = [ true ] [ j 1 prim + xs v checkloop ] if ] if
  };

: distinctloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    [ i xs prim seq-int.len prim < prim not ] [ count ] [ xs i prim seq-int.at 0 xs checkloop [ count 1 prim + ] [ count ] if i 1 prim + xs distinctloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 distinctloop };
```

### task: merge-sorted
```firth
: appendloop
  (forall ρ; ρ src:Seq Int^many idx:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { src idx result } {
    [ idx src prim seq-int.len prim < prim not ] [ result ] [ src idx prim seq-int.at prim seq-int.push idx 1 prim + src appendloop ] if
  };

: mergeloop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    [ i xs prim seq-int.len prim < prim not ] [ result j ys appendloop ] [ [ j ys prim seq-int.len prim < prim not ] [ result i xs appendloop ] [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys mergeloop ] [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys mergeloop ] if ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty mergeloop };
```

### task: digits
```firth
: digitloop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    [ n 0 prim = ] [ result ] [ n 10 prim mod result swap prim seq-int.push n 10 prim div digitloop ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { [ n 0 prim = ] [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n digitloop ] if };
```

### task: primes-up-to
```firth
: checkprime
  (forall ρ; ρ c:Int^many d:Int^many -- ρ result:Bool^many)
  locals { c d } {
    [ d c prim < prim not ] [ true ] [ [ c d prim mod 0 prim = ] [ false ] [ d 1 prim + c checkprime ] if ] if
  };

: primeloop
  (forall ρ; ρ cand:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { cand n result } {
    [ cand n prim < prim not ] [ result ] [ 2 cand checkprime [ result cand prim seq-int.push ] [ result ] if cand 1 prim + n result primeloop ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { [ n 2 prim < ] [ prim seq-int.empty ] [ 2 n prim seq-int.empty primeloop ] if };
```

### task: histogram
```firth
: initloop
  (forall ρ; ρ v:Int^many k:Int^many result:Seq Int^many -- ρ inited:Seq Int^many)
  locals { v k result } {
    [ v k prim < prim not ] [ result ] [ result 0 prim seq-int.push v 1 prim + k result initloop ] if
  };

: countloop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ counted:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim < prim not ] [ result ] [ xs i prim seq-int.at dup result swap prim seq-int.at 1 prim + prim seq-int.set i 1 prim + xs result countloop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 k prim seq-int.empty initloop 0 xs countloop };
```

### task: sort
```firth
: bubbleinner
  (forall ρ; ρ sorted:Seq Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { sorted j } {
    [ j 0 prim < prim not ] [ sorted ] [ sorted j prim seq-int.at sorted j 1 prim - prim seq-int.at prim < [ sorted j 1 prim - prim seq-int.at sorted j prim seq-int.set j 1 prim - sorted swap prim seq-int.set j 1 prim - bubbleinner ] [ j 1 prim - bubbleinner ] if ] if
  };

: bubbleouter
  (forall ρ; ρ sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted i } {
    [ i 0 prim < prim not ] [ sorted ] [ sorted i 1 prim + bubbleinner i 1 prim - bubbleouter ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - bubbleouter };
```

### task: ledger
```firth
: ledgerloop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance2:Int^many rejected2:Int^many)
  locals { txs i balance rejected } {
    [ i txs prim seq-int.len prim < prim not ] [ balance rejected ] [ txs i prim seq-int.at balance prim + 0 prim < [ balance rejected 1 prim + i 1 prim + txs ledgerloop ] [ balance txs i prim seq-int.at prim + rejected i 1 prim + txs ledgerloop ] if ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs 0 start 0 ledgerloop };
```

### task: allocate-batch
```firth
: allocloop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
             j:Int^many sleft:Seq Int^many alloc:Seq Int^many reas:Seq Int^many
             -- ρ sl:Seq Int^many al:Seq Int^many re:Seq Int^many)
  locals { stock items qtys whole j sleft alloc reas } {
    [ j qtys prim seq-int.len prim < prim not ] 
    [ sleft alloc reas ] 
    [ items j prim seq-int.at sleft swap prim seq-int.at qtys j prim seq-int.at locals { stock items qtys whole j sleft alloc reas item r qty } {
        [ qty r prim < ]
        [ sleft item r qty prim - prim seq-int.set alloc qty prim seq-int.push reas 0 prim seq-int.push ]
        [ [ r 0 prim = ]
          [ alloc 0 prim seq-int.push reas 2 prim seq-int.push ]
          [ [ whole j prim seq-int.at ]
            [ alloc 0 prim seq-int.push reas 3 prim seq-int.push ]
            [ sleft item 0 prim seq-int.set alloc r prim seq-int.push reas 1 prim seq-int.push ]
            if
          ]
          if
        ]
        if
        j 1 prim + stock items qtys whole allocloop
      }
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
             -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0 prim seq-int.empty prim seq-int.empty prim seq-int.empty stock items qtys whole allocloop
  };
```
