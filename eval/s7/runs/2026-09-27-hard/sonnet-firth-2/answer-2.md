### task: sort3
```firth
: cmpswap
  (forall ρ; ρ x:Int y:Int -- ρ lo:Int hi:Int)
  swap dup [ swap ] dip swap dup [ swap ] dip prim < [ ] [ swap ] if;

: main
  (forall ρ; ρ a:Int b:Int c:Int -- ρ lo:Int mid:Int hi:Int)
  [ cmpswap ] dip
  cmpswap
  [ cmpswap ] dip;
```

### task: triangle-kind
```firth
: cmpswap
  (forall ρ; ρ x:Int y:Int -- ρ lo:Int hi:Int)
  swap dup [ swap ] dip swap dup [ swap ] dip prim < [ ] [ swap ] if;

: order3
  (forall ρ; ρ a:Int b:Int c:Int -- ρ lo:Int mid:Int hi:Int)
  [ cmpswap ] dip
  cmpswap
  [ cmpswap ] dip;

: classify
  (forall ρ; ρ lo:Int mid:Int hi:Int -- ρ kind:Int)
  locals { lo mid hi } {
    mid hi prim =
    lo mid prim =
    lo hi prim =
    [ drop drop 1 ]
    [
      [ drop 2 ]
      [ [ 2 ] [ 3 ] if ]
      if
    ]
    if
  };

: finish
  (forall ρ; ρ lo:Int mid:Int hi:Int -- ρ kind:Int)
  locals { lo mid hi } {
    lo mid hi
    hi lo mid prim + prim <
    lo 0 prim =
    [ drop drop drop drop 0 ]
    [
      [ classify ]
      [ drop drop drop 0 ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ a:Int b:Int c:Int -- ρ kind:Int)
  order3 finish;
```
