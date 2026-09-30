### task: sort
```firth
: insert-in-order
  (forall ρ; ρ elem:Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { elem result i } {
    i result prim seq-int.len prim >=
    [ result elem prim seq-int.push ]
    [
      result i prim seq-int.at elem prim <=
      [
        result i elem prim seq-int.set
        locals { after-set } {
          elem after-set i 1 prim + insert-in-order
        }
      ]
      [
        elem result i 1 prim + insert-in-order
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
      xs i prim seq-int.at result 0 insert-in-order
      locals { new-result } {
        xs i 1 prim + new-result sort-loop
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };
```
