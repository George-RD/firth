Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sort3
Leave a, b and c sorted so the smallest is at the bottom and the largest on top.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: lo: Int, mid: Int, hi: Int.
Example: stack [3, 1, 2] becomes [1, 2, 3].

Your answer:
```
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
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block needs more values than the stack holds at `quotation`.
hint: `locals { a b }` takes two values from the top of the stack; make sure they are there.

## median3
Return the middle value of a, b and c.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: m: Int.
Example: stack [9, 1, 5] becomes [5].

Your answer:
```
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
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## triangle-kind
Classify side lengths a, b, c: return 0 if they cannot form a triangle with positive area (a zero side, or the two shorter sides sum to no more than the longest), 1 if equilateral, 2 if isosceles, 3 if scalene.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: kind: Int.
Example: stack [3, 4, 5] becomes [3].

Your answer:
```
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
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## divmod
Return the quotient and then the remainder of a divided by b (b is at least 1).
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: q: Int, r: Int.
Example: stack [17, 5] becomes [3, 2].

Your answer:
```
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
On the example, the run failed:
code: firth.syntax.overlong-character
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## isqrt
Return the largest r with r * r <= n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [10] becomes [3].

Your answer:
```
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
On the example, the run failed:
code: firth.syntax.overlong-character
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## is-prime
Return true when n is a prime number.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [7] becomes [true].

Your answer:
```
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
On the example, the run failed:
code: firth.name.unresolved
message: `divmod` is not a defined word, primitive or local.
actual: divmod
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## digit-sum
Return the sum of the decimal digits of n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [42] becomes [6].

Your answer:
```
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
On the example, the run failed:
code: firth.name.unresolved
message: `divmod` is not a defined word, primitive or local.
actual: divmod
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## lcm
Return the least common multiple of a and b (both at least 1).
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4, 6] becomes [12].

Your answer:
```
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
On the example, the run failed:
code: firth.name.unresolved
message: `divmod` is not a defined word, primitive or local.
actual: divmod
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.
