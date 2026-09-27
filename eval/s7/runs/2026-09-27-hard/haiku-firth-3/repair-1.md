Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sort3
Leave a, b and c sorted so the smallest is at the bottom and the largest on top.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: lo: Int, mid: Int, hi: Int.
Example: stack [3, 1, 2] becomes [1, 2, 3].

Your answer:
```
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
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block needs more values than the stack holds at `quotation`.
hint: `locals { a b }` takes two values from the top of the stack; make sure they are there.

## triangle-kind
Classify side lengths a, b, c: return 0 if they cannot form a triangle with positive area (a zero side, or the two shorter sides sum to no more than the longest), 1 if equilateral, 2 if isosceles, 3 if scalene.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: kind: Int.
Example: stack [3, 4, 5] becomes [3].

Your answer:
```
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
On the example, the run failed:
{"error": "toolchain: /home/user/firth-113/.lake/build/bin/firthElaborate did not answer within 60s", "status": "error"}

## digit-sum
Return the sum of the decimal digits of n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [42] becomes [6].

Your answer:
```
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
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `digit-sum-loop` leave different stacks.
expected: \u03c1
actual: \u03c1 Int
hint: Both branches must leave the same number and types of values. Expected \u03c1, found \u03c1 Int.
