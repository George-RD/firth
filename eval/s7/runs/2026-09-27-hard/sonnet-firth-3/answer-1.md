### task: sort3
```firth
: sort2
  (forall ρ; ρ x:Int^many y:Int^many -- ρ lo:Int^many hi:Int^many)
  locals { x y } { x y prim < [ x y ] [ y x ] if };

: sort3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  sort2 [ sort2 ] dip sort2;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  sort3;
```

### task: median3
```firth
: sort2
  (forall ρ; ρ x:Int^many y:Int^many -- ρ lo:Int^many hi:Int^many)
  locals { x y } { x y prim < [ x y ] [ y x ] if };

: sort3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  sort2 [ sort2 ] dip sort2;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  sort3 drop swap drop;
```

### task: triangle-kind
```firth
: sort2
  (forall ρ; ρ x:Int^many y:Int^many -- ρ lo:Int^many hi:Int^many)
  locals { x y } { x y prim < [ x y ] [ y x ] if };

: sort3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  sort2 [ sort2 ] dip sort2;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  sort3
  locals { lo mid hi } {
    hi lo mid prim + prim <
    [ lo mid prim =
      [ mid hi prim = [ 1 ] [ 2 ] if ]
      [ mid hi prim = [ 2 ] [ 3 ] if ]
      if
    ]
    [ 0 ]
    if
  };
```

### task: divmod
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q2:Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [ q a ]
    [ a b prim - b q 1 prim + divmod-loop ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  0 divmod-loop;
```

### task: isqrt
```firth
: isqrt-loop
  (forall ρ; ρ n:Int^many r:Int^many -- ρ r2:Int^many)
  locals { n r } {
    n r 1 prim + dup prim * prim <
    [ r ]
    [ n r 1 prim + isqrt-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 isqrt-loop;
```

### task: is-prime
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q2:Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [ q a ]
    [ a b prim - b q 1 prim + divmod-loop ]
    if
  };

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  0 divmod-loop;

: mod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  divmod swap drop;

: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ r:Bool^many)
  locals { n d } {
    n d dup prim * prim <
    [ 0 0 prim = ]
    [ n d mod 0 prim =
      [ 0 1 prim = ]
      [ n d 1 prim + is-prime-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  locals { n } {
    n 2 prim <
    [ 0 1 prim = ]
    [ n 2 is-prime-loop ]
    if
  };
```

### task: digit-sum
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q2:Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [ q a ]
    [ a b prim - b q 1 prim + divmod-loop ]
    if
  };

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  0 divmod-loop;

: digit-sum-loop
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  locals { n acc } {
    n 0 prim =
    [ acc ]
    [ n 10 divmod acc prim + digit-sum-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 digit-sum-loop;
```

### task: lcm
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q2:Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [ q a ]
    [ a b prim - b q 1 prim + divmod-loop ]
    if
  };

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  0 divmod-loop;

: mod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  divmod swap drop;

: gcd
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    b 0 prim =
    [ a ]
    [ b a b mod gcd ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    a b gcd a b prim * swap divmod drop
  };
```

### task: allocate
```firth
: main
  (forall ρ; ρ remaining:Int^many requested:Int^many whole:Bool^many -- ρ left:Int^many allocated:Int^many reason:Int^many)
  locals { remaining requested whole } {
    remaining requested prim <
    [ remaining 0 prim =
      [ 0 0 2 ]
      [ whole
        [ remaining 0 3 ]
        [ 0 remaining 1 ]
        if
      ]
      if
    ]
    [ remaining requested prim - requested 0 ]
    if
  };
```
