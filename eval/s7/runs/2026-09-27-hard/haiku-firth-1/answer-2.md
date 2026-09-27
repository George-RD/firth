### task: sort3
```firth
: sort3-abc
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } { a b c };

: sort3-acb
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } { c a b };

: sort3-bac
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } { b a c };

: sort3-cba
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } { c b a };

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [ sort3-abc ]
      [ sort3-acb ]
      if
    ]
    [
      b c prim <
      [ sort3-bac ]
      [ sort3-cba ]
      if
    ]
    if
  };
```

### task: median3
```firth
: median3-b
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  locals { a b c } { b };

: median3-a
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  locals { a b c } { a };

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [ median3-b ]
      [ median3-a ]
      if
    ]
    [
      b c prim <
      [ median3-a ]
      [ median3-b ]
      if
    ]
    if
  };
```

### task: triangle-kind
```firth
: triangle-zero
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  locals { a b c } { 0 };

: triangle-one
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  locals { a b c } { 1 };

: triangle-two
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  locals { a b c } { 2 };

: triangle-three
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  locals { a b c } { 3 };

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  locals { a b c } {
    a 0 prim =
    [ triangle-zero ]
    [
      b 0 prim =
      [ triangle-zero ]
      [
        c 0 prim =
        [ triangle-zero ]
        [
          a b prim + c swap prim <
          [ triangle-zero ]
          [
            b c prim + a swap prim <
            [ triangle-zero ]
            [
              c a prim + b swap prim <
              [ triangle-zero ]
              [
                a b prim =
                [
                  b c prim =
                  [ triangle-one ]
                  [ triangle-two ]
                  if
                ]
                [
                  b c prim =
                  [ triangle-two ]
                  [
                    c a prim =
                    [ triangle-two ]
                    [ triangle-three ]
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

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    a b 0 divmod-helper
  };

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

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    a b 0 divmod-helper
  };

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

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    a b 0 divmod-helper
  };

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
