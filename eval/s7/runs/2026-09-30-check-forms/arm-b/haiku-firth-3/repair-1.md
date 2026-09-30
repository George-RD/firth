Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: find-min-index
  (forall ρ; ρ xs:Seq Int^many i:Int^many min-idx:Int^many -- ρ result:Int^many)
  locals { xs i min-idx } {
    i xs prim seq-int.len prim >=
    [ min-idx ]
    [
      xs i prim seq-int.at xs min-idx prim seq-int.at prim <
      [
        xs i 1 prim + i find-min-index
      ]
      [
        xs i 1 prim + min-idx find-min-index
      ]
      if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      xs i 1 prim + i find-min-index
      locals { min-idx } {
        xs min-idx prim seq-int.at
        locals { min-val } {
          result min-val prim seq-int.push
          locals { new-result } {
            xs i 1 prim + new-result sort-loop
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, it returned [[1, 1, 2]] instead of [[1, 2, 3]]
