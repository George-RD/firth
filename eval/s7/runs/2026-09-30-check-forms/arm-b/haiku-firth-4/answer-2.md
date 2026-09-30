### task: longest-run
```firth
: runloop (forall ρ; ρ xs:Seq Int^many i:Int^many cr:Int^many mr:Int^many -- ρ length:Int^many) locals { xs i cr mr } { i xs prim seq-int.len 1 prim - prim >= [ mr cr prim > [ cr ] [ mr ] if ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [ xs i 1 prim + cr 1 prim + mr runloop ] [ mr cr prim > [ xs i 1 prim + 1 cr runloop ] [ xs i 1 prim + 1 mr runloop ] if ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many) locals { xs } { xs prim seq-int.len 1 prim <= [ xs prim seq-int.len 0 prim = [ 0 ] [ 1 ] if ] [ xs 0 1 0 runloop ] if };
```

### task: count-distinct
```firth
: checkbefore (forall ρ; ρ xs:Seq Int^many v:Int^many j:Int^many -- ρ found:Bool^many) locals { xs v j } { j 0 prim <= [ false ] [ xs j 1 prim - prim seq-int.at v prim = [ true ] [ xs v j 1 prim - checkbefore ] if ] if };

: uniqloop (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many -- ρ result:Int^many) locals { xs i cnt } { i xs prim seq-int.len prim >= [ cnt ] [ xs xs i prim seq-int.at i checkbefore prim not [ xs i 1 prim + cnt 1 prim + uniqloop ] [ xs i 1 prim + cnt uniqloop ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many) locals { xs } { xs 0 0 uniqloop };
```

### task: digits
```firth
: dgtloop (forall ρ; ρ n:Int^many d:Seq Int^many -- ρ result:Seq Int^many) locals { n d } { n 0 prim = [ d ] [ d n 10 prim mod prim seq-int.push locals { nd } { n 10 prim div nd dgtloop } ] if };

: reverseseq (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many) locals { xs i result } { i 0 prim < [ result ] [ result xs i prim seq-int.at prim seq-int.push locals { nr } { xs i 1 prim - nr reverseseq } ] if };

: main (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many) locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ n prim seq-int.empty dgtloop locals { d } { d d prim seq-int.len 1 prim - prim seq-int.empty reverseseq } ] if };
```

### task: sort
```firth
: insertloop (forall ρ; ρ a:Seq Int^many j:Int^many -- ρ sorted:Seq Int^many) locals { a j } { j 0 prim <= [ a ] [ a j prim seq-int.at a j 1 prim - prim seq-int.at prim < [ a j 1 prim - prim seq-int.at locals { pv } { a j prim seq-int.at locals { cv } { a j pv prim seq-int.set locals { a1 } { a1 j 1 prim - cv prim seq-int.set locals { a2 } { a2 j 1 prim - insertloop } } } } ] [ a ] if ] if };

: sortloop (forall ρ; ρ a:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many) locals { a i } { i a prim seq-int.len prim >= [ a ] [ a i insertloop locals { asrt } { asrt i 1 prim + sortloop } ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many) locals { xs } { xs 1 sortloop };
```

### task: allocate-batch
```firth
: allocloop (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stkl:Seq Int^many allcd:Seq Int^many rsns:Seq Int^many) locals { stock items qtys whole idx alloc reasons } { idx qtys prim seq-int.len prim >= [ stock alloc reasons ] [ items idx prim seq-int.at locals { item } { qtys idx prim seq-int.at locals { qty } { stock item prim seq-int.at locals { avail } { whole idx prim seq-bool.at locals { mf } { qty avail prim <= [ avail qty prim - locals { newavail } { stock item newavail prim seq-int.set locals { ns } { ns items qtys whole idx 1 prim + alloc qty prim seq-int.push reasons 0 prim seq-int.push allocloop } } ] [ avail 0 prim = [ stock items qtys whole idx 1 prim + alloc 0 prim seq-int.push reasons 2 prim seq-int.push allocloop ] [ mf [ stock items qtys whole idx 1 prim + alloc 0 prim seq-int.push reasons 3 prim seq-int.push allocloop ] [ stock item 0 prim seq-int.set locals { ns } { ns items qtys whole idx 1 prim + alloc avail prim seq-int.push reasons 1 prim seq-int.push allocloop } ] if ] if ] if } } } } ] if };

: main (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stockleft:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many) locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocloop };
```
