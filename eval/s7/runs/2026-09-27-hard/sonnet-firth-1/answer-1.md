### task: sort3
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: cas
  (forall ρ; ρ x:Int^many y:Int^many -- ρ lo:Int^many hi:Int^many)
  over over prim < [ ] [ swap ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  [ cas ] dip cas [ cas ] dip;
```

### task: median3
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: cas
  (forall ρ; ρ x:Int^many y:Int^many -- ρ lo:Int^many hi:Int^many)
  over over prim < [ ] [ swap ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  [ cas ] dip cas [ cas ] dip drop swap drop;
```

### task: triangle-kind
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: cas
  (forall ρ; ρ x:Int^many y:Int^many -- ρ lo:Int^many hi:Int^many)
  over over prim < [ ] [ swap ] if;

: sort3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  [ cas ] dip cas [ cas ] dip;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  sort3
  locals { lo mid hi }
  { hi lo mid prim + prim <
      [ lo mid prim =
          [ mid hi prim = [ 1 ] [ 2 ] if ]
          [ mid hi prim = [ 2 ] [ 3 ] if ]
        if ]
      [ 0 ]
    if };
```

### task: divmod
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b q }
  { a b prim <
      [ q a ]
      [ a b prim - b q 1 prim + divmod-loop ]
    if };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  0 divmod-loop;
```

### task: isqrt
```firth
: isqrt-loop
  (forall ρ; ρ n:Int^many r:Int^many -- ρ r:Int^many)
  locals { n r }
  { n r 1 prim + r 1 prim + prim * prim <
      [ r ]
      [ n r 1 prim + isqrt-loop ]
    if };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 isqrt-loop;
```

### task: is-prime
```firth
: mod
  (forall ρ; ρ n:Int^many d:Int^many -- ρ r:Int^many)
  locals { n d }
  { n d prim <
      [ n ]
      [ n d prim - d mod ]
    if };

: prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ r:Bool^many)
  locals { n d }
  { n d d prim * prim <
      [ true ]
      [ n d mod 0 prim =
          [ false ]
          [ n d 1 prim + prime-loop ]
        if ]
    if };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  locals { n }
  { n 2 prim <
      [ false ]
      [ n 2 prime-loop ]
    if };
```

### task: digit-sum
```firth
: dm10
  (forall ρ; ρ n:Int^many q:Int^many -- ρ q:Int^many r:Int^many)
  locals { n q }
  { n 10 prim <
      [ q n ]
      [ n 10 prim - q 1 prim + dm10 ]
    if };

: digit-sum-loop
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  locals { n acc }
  { n 10 prim <
      [ acc n prim + ]
      [ n 0 dm10 acc prim + digit-sum-loop ]
    if };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 digit-sum-loop;
```

### task: lcm
```firth
: mod
  (forall ρ; ρ n:Int^many d:Int^many -- ρ r:Int^many)
  locals { n d }
  { n d prim <
      [ n ]
      [ n d prim - d mod ]
    if };

: gcd
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b }
  { b 0 prim =
      [ a ]
      [ b a b mod gcd ]
    if };

: div
  (forall ρ; ρ n:Int^many d:Int^many q:Int^many -- ρ q:Int^many)
  locals { n d q }
  { n d prim <
      [ q ]
      [ n d prim - d q 1 prim + div ]
    if };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b }
  { a b prim * a b gcd 0 div };
```

### task: allocate
```firth
: main
  (forall ρ; ρ remaining:Int^many requested:Int^many whole:Bool^many -- ρ left:Int^many allocated:Int^many reason:Int^many)
  locals { remaining requested whole }
  { remaining requested prim <
      [ remaining 0 prim =
          [ 0 0 2 ]
          [ whole
              [ remaining 0 3 ]
              [ 0 remaining 1 ]
            if ]
        if ]
      [ remaining requested prim - requested 0 ]
    if };
```
