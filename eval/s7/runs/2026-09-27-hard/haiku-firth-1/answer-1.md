### task: sort3
```firth
: sort3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [ a b c ]
      [ c a b ]
      if
    ]
    [
      b c prim <
      [ b a c ]
      [ c b a ]
      if
    ]
    if
  };
```

### task: median3
```firth
: median3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [ b ]
      [ a ]
      if
    ]
    [
      b c prim <
      [ a ]
      [ b ]
      if
    ]
    if
  };
```

### task: triangle-kind
```firth
: triangle-kind
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  locals { a b c } {
    a 0 prim =
    [ 0 ]
    [
      b 0 prim =
      [ 0 ]
      [
        c 0 prim =
        [ 0 ]
        [
          a b prim + c swap prim <
          [ 0 ]
          [
            b c prim + a swap prim <
            [ 0 ]
            [
              c a prim + b swap prim <
              [ 0 ]
              [
                a b prim =
                [
                  b c prim =
                  [ 1 ]
                  [ 2 ]
                  if
                ]
                [
                  b c prim =
                  [ 2 ]
                  [
                    c a prim =
                    [ 2 ]
                    [ 3 ]
                    if
                  ]
                  if
                ]
                if
              ]
              if
            ]
            if
          ]
          if
        ]
        if
      ]
      if
    ]
    if
  };
```

### task: divmod
```firth
: divmod-helper
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q':Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [
      q a
    ]
    [
      a b prim - b q 1 prim + divmod-helper
    ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    a b 0 divmod-helper
  };
```

### task: isqrt
```firth
: isqrt-helper
  (forall ρ; ρ n:Int^many r:Int^many -- ρ r':Int^many)
  locals { n r } {
    r 1 prim + dup prim * n 1 prim + prim <
    [
      n r 1 prim + isqrt-helper
    ]
    [
      r
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 isqrt-helper;
```

### task: is-prime
```firth
: is-prime-helper
  (forall ρ; ρ n:Int^many d:Int^many -- ρ r:Bool^many)
  locals { n d } {
    d dup prim * n prim <
    [
      true
    ]
    [
      n d divmod swap drop 0 prim =
      [
        false
      ]
      [
        n d 1 prim + is-prime-helper
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [ n 2 is-prime-helper ]
      if
    ]
    if
  };
```

### task: digit-sum
```firth
: digit-sum-helper
  (forall ρ; ρ n:Int^many sum:Int^many -- ρ r:Int^many)
  locals { n sum } {
    n 0 prim =
    [ sum ]
    [
      n 10 divmod
      locals { q r } {
        q r sum prim + digit-sum-helper
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 digit-sum-helper;
```

### task: lcm
```firth
: gcd
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    b 0 prim =
    [ a ]
    [
      a b divmod drop b gcd
    ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    a b prim * a b gcd divmod drop
  };
```

### task: allocate
```firth
: main
  (forall ρ; ρ remaining:Int^many requested:Int^many whole:Bool^many -- ρ left:Int^many allocated:Int^many reason:Int^many)
  locals { remaining requested whole } {
    remaining requested prim <
    [
      remaining 0 prim =
      [ 0 0 2 ]
      [
        whole
        [ remaining 0 3 ]
        [ 0 remaining 1 ]
        if
      ]
      if
    ]
    [
      remaining requested prim - requested 0
    ]
    if
  };
```
