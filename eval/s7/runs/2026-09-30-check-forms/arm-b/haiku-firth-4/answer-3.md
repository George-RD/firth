### task: longest-run
```firth
: runloop (forall ρ; ρ xs:Seq Int^many i:Int^many cr:Int^many mr:Int^many -- ρ length:Int^many) locals { xs i cr mr } { i xs prim seq-int.len 1 prim - prim >= [ cr mr prim > [ cr ] [ mr ] if ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [ xs i 1 prim + cr 1 prim + mr runloop ] [ cr mr prim > [ xs i 1 prim + 1 cr runloop ] [ xs i 1 prim + 1 mr runloop ] if ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many) locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 0 1 0 runloop ] if };
```
