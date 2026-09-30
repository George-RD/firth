### task: sort
```firth
: find-next-min
  (forall ρ; ρ xs:Seq Int^many threshold:Int^many i:Int^many current-min:Int^many -- ρ result:Int^many)
  locals { xs threshold i current-min } {
    i xs prim seq-int.len prim >=
    [ current-min ]
    [
      xs i prim seq-int.at
      locals { elem } {
        elem threshold prim >
        [
          elem current-min prim <
          [
            xs threshold i 1 prim + elem find-next-min
          ]
          [
            xs threshold i 1 prim + current-min find-next-min
          ]
          if
        ]
        [
          xs threshold i 1 prim + current-min find-next-min
        ]
        if
      }
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many threshold:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs threshold result } {
    threshold xs prim seq-int.len prim >=
    [ result ]
    [
      xs threshold 0 9223372036854775807 find-next-min
      locals { next-val } {
        result next-val prim seq-int.push
        locals { new-result } {
          xs next-val new-result sort-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs -9223372036854775808 prim seq-int.empty sort-loop
  };
```
