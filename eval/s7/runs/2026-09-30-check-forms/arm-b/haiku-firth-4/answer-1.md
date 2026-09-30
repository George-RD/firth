### task: seq-sum
```firth
: sumloop (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many) locals { xs i acc } { i xs prim seq-int.len prim >= [ acc ] [ xs i prim seq-int.at acc prim + locals { nacc } { xs i 1 prim + nacc sumloop } ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many) locals { xs } { xs 0 0 sumloop };
```

### task: seq-max
```firth
: maxloop (forall ρ; ρ xs:Seq Int^many i:Int^many m:Int^many -- ρ result:Int^many) locals { xs i m } { i xs prim seq-int.len prim >= [ m ] [ xs i prim seq-int.at locals { curr } { curr m prim > [ xs i 1 prim + curr maxloop ] [ xs i 1 prim + m maxloop ] if } ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many) locals { xs } { xs 1 xs 0 prim seq-int.at maxloop };
```

### task: count-below
```firth
: cntloop (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many) locals { xs k i cnt } { i xs prim seq-int.len prim >= [ cnt ] [ xs i prim seq-int.at k prim < [ xs k i 1 prim + cnt 1 prim + cntloop ] [ xs k i 1 prim + cnt cntloop ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many) locals { xs k } { xs k 0 0 cntloop };
```

### task: index-of
```firth
: idxloop (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many result:Int^many -- ρ index:Int^many) locals { xs x i result } { result -1 prim = [ i xs prim seq-int.len prim >= [ -1 ] [ xs i prim seq-int.at x prim = [ i ] [ xs x i 1 prim + -1 idxloop ] if ] if ] [ result ] if };

: main (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many) locals { xs x } { xs x 0 -1 idxloop };
```

### task: reverse
```firth
: revloop (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many) locals { xs i result } { i 0 prim < [ result ] [ result xs i prim seq-int.at prim seq-int.push locals { nr } { xs i 1 prim - nr revloop } ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many) locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty revloop };
```

### task: prefix-sums
```firth
: pfxloop (forall ρ; ρ xs:Seq Int^many i:Int^many s:Int^many result:Seq Int^many -- ρ sums:Seq Int^many) locals { xs i s result } { i xs prim seq-int.len prim >= [ result ] [ xs i prim seq-int.at s prim + locals { ns } { result ns prim seq-int.push locals { nr } { xs i 1 prim + ns nr pfxloop } } ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many) locals { xs } { xs 0 0 prim seq-int.empty pfxloop };
```

### task: keep-positive
```firth
: filtloop (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many) locals { xs i result } { i xs prim seq-int.len prim >= [ result ] [ xs i prim seq-int.at 0 prim > [ result xs i prim seq-int.at prim seq-int.push locals { nr } { xs i 1 prim + nr filtloop } ] [ xs i 1 prim + result filtloop ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many) locals { xs } { xs 0 prim seq-int.empty filtloop };
```

### task: is-sorted
```firth
: srtloop (forall ρ; ρ xs:Seq Int^many i:Int^many ok:Bool^many -- ρ sorted:Bool^many) locals { xs i ok } { ok prim not [ false ] [ i xs prim seq-int.len 1 prim - prim >= [ true ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim > [ false ] [ xs i 1 prim + true srtloop ] if ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many) locals { xs } { xs prim seq-int.len 1 prim <= [ true ] [ xs 0 true srtloop ] if };
```

### task: dot
```firth
: dotloop (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many s:Int^many -- ρ product:Int^many) locals { xs ys i s } { i xs prim seq-int.len prim >= [ s ] [ xs i prim seq-int.at ys i prim seq-int.at prim * s prim + locals { ns } { xs ys i 1 prim + ns dotloop } ] if };

: main (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many) locals { xs ys } { xs ys 0 0 dotloop };
```

### task: all-true
```firth
: allloop (forall ρ; ρ flags:Seq Bool^many i:Int^many ok:Bool^many -- ρ all:Bool^many) locals { flags i ok } { ok prim not [ false ] [ i flags prim seq-bool.len prim >= [ true ] [ flags i prim seq-bool.at [ flags i 1 prim + true allloop ] [ false ] if ] if ] if };

: main (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many) locals { flags } { flags prim seq-bool.len 0 prim = [ true ] [ flags 0 true allloop ] if };
```

### task: longest-run
```firth
: runloop (forall ρ; ρ xs:Seq Int^many i:Int^many cr:Int^many mr:Int^many -- ρ length:Int^many) locals { xs i cr mr } { i xs prim seq-int.len prim >= [ mr cr prim > [ cr ] [ mr ] if ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [ xs i 1 prim + cr 1 prim + mr runloop ] [ mr cr prim > [ xs i 1 prim + 1 cr runloop ] [ xs i 1 prim + 1 mr runloop ] if ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many) locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 1 1 0 runloop ] if };
```

### task: has-pair-sum
```firth
: inloop (forall ρ; ρ xs:Seq Int^many t:Int^many i:Int^many j:Int^many -- ρ found:Bool^many) locals { xs t i j } { j xs prim seq-int.len prim >= [ false ] [ xs i prim seq-int.at xs j prim seq-int.at prim + t prim = [ true ] [ xs t i j 1 prim + inloop ] if ] if };

: outloop (forall ρ; ρ xs:Seq Int^many t:Int^many i:Int^many -- ρ found:Bool^many) locals { xs t i } { i xs prim seq-int.len prim >= [ false ] [ xs t i i 1 prim + inloop [ true ] [ xs t i 1 prim + outloop ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many) locals { xs target } { xs target 0 outloop };
```

### task: count-distinct
```firth
: seenloop (forall ρ; ρ xs:Seq Int^many v:Int^many j:Int^many -- ρ found:Bool^many) locals { xs v j } { j xs prim seq-int.len prim >= [ false ] [ xs j prim seq-int.at v prim = [ true ] [ xs v j 1 prim + seenloop ] if ] if };

: uniqloop (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many -- ρ result:Int^many) locals { xs i cnt } { i xs prim seq-int.len prim >= [ cnt ] [ xs xs i prim seq-int.at 0 seenloop [ xs i 1 prim + cnt 1 prim + uniqloop ] [ xs i 1 prim + cnt uniqloop ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many) locals { xs } { xs 0 0 uniqloop };
```

### task: merge-sorted
```firth
: mrgloop (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many) locals { xs ys i j result } { i xs prim seq-int.len prim >= [ j ys prim seq-int.len prim >= [ result ] [ result ys j prim seq-int.at prim seq-int.push locals { nr } { xs ys i j 1 prim + nr mrgloop } ] if ] [ j ys prim seq-int.len prim >= [ result xs i prim seq-int.at prim seq-int.push locals { nr } { xs ys i 1 prim + j nr mrgloop } ] [ xs i prim seq-int.at ys j prim seq-int.at prim <= [ result xs i prim seq-int.at prim seq-int.push locals { nr } { xs ys i 1 prim + j nr mrgloop } ] [ result ys j prim seq-int.at prim seq-int.push locals { nr } { xs ys i j 1 prim + nr mrgloop } ] if ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many) locals { xs ys } { xs ys 0 0 prim seq-int.empty mrgloop };
```

### task: digits
```firth
: dgtloop (forall ρ; ρ n:Int^many d:Seq Int^many -- ρ result:Seq Int^many) locals { n d } { n 0 prim = [ d ] [ d n 10 prim mod prim seq-int.push locals { nd } { n 10 prim div nd dgtloop } ] if };

: main (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many) locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ n prim seq-int.empty dgtloop ] if };
```

### task: primes-up-to
```firth
: divtest (forall ρ; ρ n:Int^many d:Int^many -- ρ divisible:Bool^many) locals { n d } { d d prim * n prim > [ false ] [ n d prim mod 0 prim = [ true ] [ n d 1 prim + divtest ] if ] if };

: isprime (forall ρ; ρ n:Int^many -- ρ result:Bool^many) locals { n } { n 2 prim <= [ n 2 prim = ] [ n 2 divtest prim not ] if };

: collect (forall ρ; ρ n:Int^many c:Int^many result:Seq Int^many -- ρ primes:Seq Int^many) locals { n c result } { c n prim > [ result ] [ c isprime [ result c prim seq-int.push locals { nr } { n c 1 prim + nr collect } ] [ n c 1 prim + result collect ] if ] if };

: main (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many) locals { n } { n 2 prim <= [ prim seq-int.empty ] [ n 2 prim seq-int.empty collect ] if };
```

### task: histogram
```firth
: inithloop (forall ρ; ρ k:Int^many idx:Int^many c:Seq Int^many -- ρ result:Seq Int^many) locals { k idx c } { idx k prim >= [ c ] [ c 0 prim seq-int.push locals { nc } { k idx 1 prim + nc inithloop } ] if };

: tallyloop (forall ρ; ρ xs:Seq Int^many c:Seq Int^many i:Int^many -- ρ result:Seq Int^many) locals { xs c i } { i xs prim seq-int.len prim >= [ c ] [ xs i prim seq-int.at locals { v } { c v prim seq-int.at 1 prim + locals { newval } { c v newval prim seq-int.set locals { nc } { xs nc i 1 prim + tallyloop } } } ] if };

: main (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many) locals { xs k } { k 0 prim seq-int.empty inithloop locals { init } { xs init 0 tallyloop } };
```

### task: sort
```firth
: insertloop (forall ρ; ρ a:Seq Int^many j:Int^many -- ρ sorted:Seq Int^many) locals { a j } { j 0 prim <= [ a ] [ a j prim seq-int.at a j 1 prim - prim seq-int.at prim <= [ a ] [ a j 1 prim - prim seq-int.at locals { pv } { a j prim seq-int.at locals { cv } { a j pv prim seq-int.set locals { a1 } { a1 j 1 prim - cv prim seq-int.set locals { a2 } { a2 j 1 prim - insertloop } } } } ] if ] if };

: sortloop (forall ρ; ρ a:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many) locals { a i } { i a prim seq-int.len prim >= [ a ] [ a i insertloop locals { asrt } { asrt i 1 prim + sortloop } ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many) locals { xs } { xs 1 sortloop };
```

### task: ledger
```firth
: txloop (forall ρ; ρ txs:Seq Int^many idx:Int^many b:Int^many rej:Int^many -- ρ bal:Int^many rjct:Int^many) locals { txs idx b rej } { idx txs prim seq-int.len prim >= [ b rej ] [ txs idx prim seq-int.at locals { tx } { b tx prim + 0 prim >= [ txs idx 1 prim + b tx prim + rej txloop ] [ txs idx 1 prim + b rej 1 prim + txloop ] if } ] if };

: main (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many) locals { start txs } { txs 0 start 0 txloop };
```

### task: allocate-batch
```firth
: allocloop (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stkl:Seq Int^many allcd:Seq Int^many rsns:Seq Int^many) locals { stock items qtys whole idx alloc reasons } { idx qtys prim seq-int.len prim >= [ stock alloc reasons ] [ items idx prim seq-int.at locals { item } { qtys idx prim seq-int.at locals { qty } { stock item prim seq-int.at locals { avail } { whole idx prim seq-bool.at locals { mf } { qty avail prim <= [ stock item qty prim seq-int.set locals { ns } { ns items qtys whole idx 1 prim + alloc qty prim seq-int.push reasons 0 prim seq-int.push allocloop } ] [ avail 0 prim = [ stock items qtys whole idx 1 prim + alloc 0 prim seq-int.push reasons 2 prim seq-int.push allocloop ] [ mf [ stock items qtys whole idx 1 prim + alloc 0 prim seq-int.push reasons 3 prim seq-int.push allocloop ] [ stock item 0 prim seq-int.set locals { ns } { ns items qtys whole idx 1 prim + alloc avail prim seq-int.push reasons 1 prim seq-int.push allocloop } ] if ] if ] if } } } } ] if };

: main (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stockleft:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many) locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocloop };
```
