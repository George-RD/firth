Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: runloop (forall ρ; ρ xs:Seq Int^many i:Int^many cr:Int^many mr:Int^many -- ρ length:Int^many) locals { xs i cr mr } { i xs prim seq-int.len 1 prim - prim >= [ mr cr prim > [ cr ] [ mr ] if ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [ xs i 1 prim + cr 1 prim + mr runloop ] [ mr cr prim > [ xs i 1 prim + 1 cr runloop ] [ xs i 1 prim + 1 mr runloop ] if ] if ] if };

: main (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many) locals { xs } { xs prim seq-int.len 1 prim <= [ xs prim seq-int.len 0 prim = [ 0 ] [ 1 ] if ] [ xs 0 1 0 runloop ] if };

```
On the example, it returned [0] instead of [3]
