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
  sort3
  drop
  swap
  drop;

```
On the example, the run failed:
code: firth.name.unresolved
message: `sort3` is not a defined word, primitive or local.
actual: sort3
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

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
On the example, the run failed:
code: firth.name.unresolved
message: `sort3` is not a defined word, primitive or local.
actual: sort3
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## divmod
Return the quotient and then the remainder of a divided by b (b is at least 1).
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: q: Int, r: Int.
Example: stack [17, 5] becomes [3, 2].

Your answer:
```
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
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## isqrt
Return the largest r with r * r <= n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [10] becomes [3].

Your answer:
```
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
On the example, the run failed:
code: firth.name.unresolved
message: `n` is not a defined word, primitive or local.
actual: n
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## is-prime
Return true when n is a prime number.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [7] becomes [true].

Your answer:
```
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
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
message: `compose` in `is-prime` failed the check firth.type.quotation-compose-mismatch; the stack before it is \u03c1 Bool [ .. -- .. Int ] [ .. -- .. Bool [ .. -- .. Int ] [ .. -- .. Int Int ] Int ] [ .. Bool [ .. -- .. Bool ] [ .. -- .. Int Int ] Int -- .. Bool ]. Expected Int, found Bool.
expected: Int
actual: Bool

## digit-sum
Return the sum of the decimal digits of n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [42] becomes [6].

Your answer:
```
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
On the example, the run failed:
code: firth.name.unresolved
message: `n` is not a defined word, primitive or local.
actual: n
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## lcm
Return the least common multiple of a and b (both at least 1).
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4, 6] becomes [12].

Your answer:
```
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
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `lcm` leave different stacks.
expected: \u03c1
actual: .. Int
hint: Both branches must leave the same number and types of values. Expected \u03c1, found .. Int.

## allocate
Allocate stock for one order. If requested <= remaining, allocate all of it (reason 0). Otherwise, if remaining is 0, allocate nothing (reason 2). Otherwise, if whole is true the order must be filled completely, so allocate nothing (reason 3); if whole is false allocate everything that remains (reason 1). Return the stock left, the quantity allocated and the reason code.
Inputs on the stack, bottom to top: remaining: Int, requested: Int, whole: Bool.
Outputs left on the stack, bottom to top: left: Int, allocated: Int, reason: Int.
Example: stack [10, 4, false] becomes [6, 4, 0].

Your answer:
```
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
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}
