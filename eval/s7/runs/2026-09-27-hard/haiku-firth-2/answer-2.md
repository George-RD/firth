### task: sort3
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  dup dup
  2 1 roll dup
  prim <
  [
    dup dup dup prim <
    [
      roll roll prim <
      [ roll ] [ roll roll roll ] if
    ]
    [
      roll roll roll
    ]
    if
  ]
  [
    roll roll prim <
    [
      dup dup roll prim <
      [ roll roll ] [ roll roll roll ] if
    ]
    [
      roll roll roll
    ]
    if
  ]
  if;
```

### task: median3
```firth
: sort-median
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ mid:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [
        b c prim <
        [ b ] [ c ]
        if
      ]
      [
        a
      ]
      if
    ]
    [
      b c prim <
      [
        a c prim <
        [ a ] [ c ]
        if
      ]
      [
        b
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  sort-median;
```

### task: triangle-kind
```firth
: sort-3
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

: main
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
          a b c sort-3
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
: divmod-loop
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
      divmod-loop
    ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    0 a b divmod-loop
  };
```

### task: isqrt
```firth
: isqrt-loop
  (forall ρ; ρ r:Int^many n:Int^many -- ρ r:Int^many)
  locals { r n } {
    r 1 prim +
    dup dup prim *
    n prim <
    [
      n isqrt-loop
    ]
    [
      drop r
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  locals { n } {
    0 n isqrt-loop
  };
```

### task: is-prime
```firth
: is-prime-check
  (forall ρ; ρ c:Int^many l:Int^many n:Int^many -- ρ r:Bool^many)
  locals { c l n } {
    c l prim <
    [
      1
    ]
    [
      n c prim -
      0 prim =
      [
        0
      ]
      [
        c 1 prim +
        l
        n
        is-prime-check
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  locals { n } {
    n 2 prim <
    [
      0
    ]
    [
      n 2 prim =
      [
        1
      ]
      [
        n 2 prim -
        dup 1 prim +
        n
        is-prime-check
      ]
      if
    ]
    if
  };
```

### task: digit-sum
```firth
: digit-sum-loop
  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)
  locals { s n } {
    n 0 prim =
    [
      s
    ]
    [
      n 10 prim -
      0 prim =
      [
        s n prim +
      ]
      [
        s n prim - prim +
        n 10 prim -
        digit-sum-loop
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  locals { n } {
    0 n digit-sum-loop
  };
```

### task: lcm
```firth
: gcd
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    b 0 prim =
    [
      a
    ]
    [
      a b prim =
      [
        b
      ]
      [
        b a b prim - gcd
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    a b gcd
    locals { g } {
      a b prim *
      g prim -
      0 prim =
      [
        a b prim *
      ]
      [
        a b prim *
      ]
      if
    }
  };
```

### task: allocate
```firth
: main
  (forall ρ; ρ remaining:Int^many requested:Int^many whole:Bool^many -- ρ left:Int^many allocated:Int^many reason:Int^many)
  locals { remaining requested whole } {
    requested remaining prim <
    [
      remaining requested prim -
      requested
      0
    ]
    [
      remaining 0 prim =
      [
        remaining
        0
        2
      ]
      [
        whole
        [
          remaining
          0
          3
        ]
        [
          remaining
          0
          1
        ]
        if
      ]
      if
    ]
    if
  };
```
