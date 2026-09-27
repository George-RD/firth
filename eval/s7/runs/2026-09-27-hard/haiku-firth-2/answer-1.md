### task: sort3
```firth
: sort3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [
        b c prim <
        [ a b c ] [ a c b ]
        if
      ]
      [
        c a b
      ]
      if
    ]
    [
      b c prim <
      [
        a c prim <
        [ b a c ] [ b c a ]
        if
      ]
      [
        c b a
      ]
      if
    ]
    if
  };
```

### task: median3
```firth
: median3
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  sort3
  drop
  swap
  drop;
```

### task: triangle-kind
```firth
: triangle-kind
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
  locals { a b c } {
    a 0 prim =
    [
      0
    ]
    [
      b 0 prim =
      [
        0
      ]
      [
        c 0 prim =
        [
          0
        ]
        [
          a b c sort3
          locals { lo mid hi } {
            lo mid prim +
            hi prim <
            [
              0
            ]
            [
              a b prim =
              [
                b c prim =
                [ 1 ] [ 2 ]
                if
              ]
              [
                a c prim =
                [ 2 ]
                [
                  b c prim =
                  [ 2 ] [ 3 ]
                  if
                ]
                if
              ]
              if
            ]
            if
          }
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
: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    0 a b divmod-helper
  };

: divmod-helper
  (forall ρ; ρ q:Int^many r:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { q r b } {
    r b prim <
    [
      q r
    ]
    [
      q 1 prim +
      r b prim -
      b
      divmod-helper
    ]
    if
  };
```

### task: isqrt
```firth
: isqrt
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 n isqrt-helper;

: isqrt-helper
  (forall ρ; ρ r:Int^many n:Int^many -- ρ r:Int^many)
  locals { r n } {
    r 1 prim +
    dup dup prim *
    n prim <
    [
      n isqrt-helper
    ]
    [
      drop drop r
    ]
    if
  };
```

### task: is-prime
```firth
: is-prime
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  locals { n } {
    n 2 prim <
    [
      0
    ]
    [
      n 2 prim =
      [ 1 ]
      [
        n 2 prim -
        dup 1 prim +
        n is-prime-check
      ]
      if
    ]
    if
  };

: is-prime-check
  (forall ρ; ρ candidate:Int^many limit:Int^many n:Int^many -- ρ r:Bool^many)
  locals { candidate limit n } {
    candidate limit prim <
    [
      1
    ]
    [
      n candidate prim =
      [
        0
      ]
      [
        n candidate prim -
        0 prim =
        [
          0
        ]
        [
          candidate 1 prim +
          limit
          n
          is-prime-check
        ]
        if
      ]
      if
    ]
    if
  };
```

### task: digit-sum
```firth
: digit-sum
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 n digit-sum-helper;

: digit-sum-helper
  (forall ρ; ρ sum:Int^many n:Int^many -- ρ r:Int^many)
  locals { sum n } {
    n 0 prim =
    [
      sum
    ]
    [
      n 10 prim -
      0 prim =
      [
        sum n prim +
      ]
      [
        n 10 prim -
        sum n prim - prim +
        n 10 prim -
        digit-sum-helper
      ]
      if
    ]
    if
  };
```

### task: lcm
```firth
: lcm
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    a b gcd
    a b prim *
    swap
    prim -
    0 prim =
    [
      a b prim *
    ]
    [
      a b prim * swap prim -
    ]
    if
  };

: gcd
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    b 0 prim =
    [ a ]
    [
      a b prim =
      [ b ]
      [
        b a b prim - gcd
      ]
      if
    ]
    if
  };
```

### task: allocate
```firth
: allocate
  (forall ρ; ρ remaining:Int^many requested:Int^many whole:Bool^many -- ρ left:Int^many allocated:Int^many reason:Int^many)
  locals { remaining requested whole } {
    requested remaining prim <
    [
      requested 0 prim =
      [
        remaining requested prim - requested 0
      ]
      [
        remaining requested prim - requested 0
      ]
      if
    ]
    [
      remaining 0 prim =
      [
        remaining 0 2
      ]
      [
        whole
        [
          remaining 0 3
        ]
        [
          0 remaining 1
        ]
        if
      ]
      if
    ]
    if
  };
```
