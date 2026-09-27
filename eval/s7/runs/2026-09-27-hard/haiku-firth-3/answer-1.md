### task: sort3
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [
        b c prim <
        [
          a b c
        ]
        [
          a c b
        ]
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
        [
          b a c
        ]
        [
          b c a
        ]
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
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ m:Int^many)
  locals { a b c } {
    a b prim <
    [
      a c prim <
      [
        b c prim <
        [
          b
        ]
        [
          c
        ]
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
        [
          a
        ]
        [
          c
        ]
        if
      ]
      [
        b
      ]
      if
    ]
    if
  };
```

### task: triangle-kind
```firth
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
          a b prim <
          [
            a c prim <
            [
              b c prim <
              [
                a b prim + c prim <
                [
                  0
                ]
                [
                  a b prim =
                  [
                    b c prim =
                    [
                      1
                    ]
                    [
                      2
                    ]
                    if
                  ]
                  [
                    a c prim =
                    [
                      2
                    ]
                    [
                      b c prim =
                      [
                        2
                      ]
                      [
                        3
                      ]
                      if
                    ]
                    if
                  ]
                  if
                ]
                if
              ]
              [
                a c prim + b prim <
                [
                  0
                ]
                [
                  a b prim =
                  [
                    b c prim =
                    [
                      1
                    ]
                    [
                      2
                    ]
                    if
                  ]
                  [
                    a c prim =
                    [
                      2
                    ]
                    [
                      b c prim =
                      [
                        2
                      ]
                      [
                        3
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
            [
              b c prim <
              [
                c b prim + a prim <
                [
                  0
                ]
                [
                  a b prim =
                  [
                    b c prim =
                    [
                      1
                    ]
                    [
                      2
                    ]
                    if
                  ]
                  [
                    a c prim =
                    [
                      2
                    ]
                    [
                      b c prim =
                      [
                        2
                      ]
                      [
                        3
                      ]
                      if
                    ]
                    if
                  ]
                  if
                ]
                if
              ]
              [
                c b prim + a prim <
                [
                  0
                ]
                [
                  a b prim =
                  [
                    b c prim =
                    [
                      1
                    ]
                    [
                      2
                    ]
                    if
                  ]
                  [
                    a c prim =
                    [
                      2
                    ]
                    [
                      b c prim =
                      [
                        2
                      ]
                      [
                        3
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
          [
            b c prim <
            [
              b a prim + c prim <
              [
                0
              ]
              [
                a b prim =
                [
                  b c prim =
                  [
                    1
                  ]
                  [
                    2
                  ]
                  if
                ]
                [
                  a c prim =
                  [
                    2
                  ]
                  [
                    b c prim =
                    [
                      2
                    ]
                    [
                      3
                    ]
                    if
                  ]
                  if
                ]
                if
              ]
              if
            ]
            [
              c b prim + a prim <
              [
                0
              ]
              [
                a b prim =
                [
                  b c prim =
                  [
                    1
                  ]
                  [
                    2
                  ]
                  if
                ]
                [
                  a c prim =
                  [
                    2
                  ]
                  [
                    b c prim =
                    [
                      2
                    ]
                    [
                      3
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
    ]
    if
  };
```

### task: divmod
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [
      q a
    ]
    [
      a b prim - b q 1 prim + divmod-loop
    ]
    if
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    a b 0 divmod-loop
  };
```

### task: isqrt
```firth
: isqrt-loop
  (forall ρ; ρ n:Int^many r:Int^many -- ρ result:Int^many)
  locals { n r } {
    r 1 prim + dup prim * n prim <
    [
      n r 1 prim + isqrt-loop
    ]
    [
      r
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Int^many)
  locals { n } {
    n 0 isqrt-loop
  };
```

### task: is-prime
```firth
: mod-helper
  (forall ρ; ρ n:Int^many d:Int^many -- ρ remainder:Int^many)
  locals { n d } {
    n d prim <
    [
      n
    ]
    [
      n d prim - d mod-helper
    ]
    if
  };

: check-divisors
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d dup prim * n prim <
    [
      n d mod-helper 0 prim =
      [
        true
      ]
      [
        n d 1 prim + check-divisors
      ]
      if
    ]
    [
      false
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [
      false
    ]
    [
      n 2 check-divisors
      [
        false
      ]
      [
        true
      ]
      if
    ]
    if
  };
```

### task: digit-sum
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [
      q a
    ]
    [
      a b prim - b q 1 prim + divmod-loop
    ]
    if
  };

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    a b 0 divmod-loop
  };

: digit-sum-loop
  (forall ρ; ρ n:Int^many sum:Int^many -- ρ result:Int^many)
  locals { n sum } {
    n 0 prim =
    [
      sum
    ]
    [
      n 10 divmod sum prim + n 10 divmod drop 0 prim + digit-sum-loop
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Int^many)
  locals { n } {
    n 0 digit-sum-loop
  };
```

### task: lcm
```firth
: mod-helper
  (forall ρ; ρ n:Int^many d:Int^many -- ρ remainder:Int^many)
  locals { n d } {
    n d prim <
    [
      n
    ]
    [
      n d prim - d mod-helper
    ]
    if
  };

: gcd-loop
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    b 0 prim =
    [
      a
    ]
    [
      b a b mod-helper gcd-loop
    ]
    if
  };

: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b q } {
    a b prim <
    [
      q a
    ]
    [
      a b prim - b q 1 prim + divmod-loop
    ]
    if
  };

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  locals { a b } {
    a b 0 divmod-loop
  };

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim * a b gcd-loop divmod drop
  };
```

### task: allocate
```firth
: main
  (forall ρ; ρ remaining:Int^many requested:Int^many whole:Bool^many -- ρ left:Int^many allocated:Int^many reason:Int^many)
  locals { remaining requested whole } {
    requested remaining prim <
    [
      remaining requested prim - requested 0
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
