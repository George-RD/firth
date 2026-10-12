### task: sokoban
```firth
: sk-cell
  (forall ρ; ρ cells:Seq(Int)^many width:Int^many r:Int^many c:Int^many -- ρ v:Int^many)
  locals { cells width r c } { cells r width prim * c prim + prim seq-int.at };

: sk-wall?
  (forall ρ; ρ cells:Seq(Int)^many width:Int^many r:Int^many c:Int^many -- ρ b:Bool^many)
  locals { cells width r c } { cells width r c sk-cell 1 prim = };

: main
  (forall ρ; ρ width:Int^many height:Int^many cells:Seq(Int)^many player:Int^many boxes:Seq(Int)^many moves:Seq(Int)^many -- ρ player:Int^many boxes:Seq(Int)^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  locals { width height cells player boxes moves } { 0 0 0 0 0 0 0 0 0 0 0 0 0 };
