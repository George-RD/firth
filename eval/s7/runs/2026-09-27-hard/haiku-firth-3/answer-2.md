### task: sort3
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ lo:Int^many mid:Int^many hi:Int^many)
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
  ;
```

### task: triangle-kind
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ kind:Int^many)
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
      if
    ]
    if
  ]
  if
  ;
```

### task: digit-sum
```firth
: divmod-loop
  (forall ρ; ρ a:Int^many b:Int^many q:Int^many -- ρ q:Int^many r:Int^many)
  a b prim <
  [
    q a
  ]
  [
    a b prim - b q 1 prim + divmod-loop
  ]
  if
  ;

: divmod
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many r:Int^many)
  a b 0 divmod-loop
  ;

: digit-sum-loop
  (forall ρ; ρ n:Int^many sum:Int^many -- ρ result:Int^many)
  n 0 prim =
  [
    sum
  ]
  [
    n 10 divmod swap sum prim + swap n prim - 10 prim * prim - digit-sum-loop
  ]
  if
  ;

: main
  (forall ρ; ρ n:Int^many -- ρ result:Int^many)
  n 0 digit-sum-loop
  ;
```
