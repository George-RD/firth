### task: sort3
```firth
: main
  (forall ρ; ρ a:Int b:Int c:Int -- ρ lo:Int mid:Int hi:Int)
  locals { a b c } {
    a b prim <
    [
      b c prim <
      [ a b c ]
      [
        a c prim <
        [ a c b ]
        [ c a b ]
        if
      ]
      if
    ]
    [
      a c prim <
      [ b a c ]
      [
        b c prim <
        [ b c a ]
        [ c b a ]
        if
      ]
      if
    ]
    if
  };
```

### task: median3
```firth
: main
  (forall ρ; ρ a:Int b:Int c:Int -- ρ m:Int)
  locals { a b c } {
    a b prim <
    [
      b c prim <
      [ b ]
      [
        a c prim <
        [ c ]
        [ a ]
        if
      ]
      if
    ]
    [
      a c prim <
      [ a ]
      [
        b c prim <
        [ c ]
        [ b ]
        if
      ]
      if
    ]
    if
  };
```

### task: triangle-kind
```firth
: order3
  (forall ρ; ρ a:Int b:Int c:Int -- ρ lo:Int mid:Int hi:Int)
  locals { a b c } {
    a b prim <
    [
      b c prim <
      [ a b c ]
      [
        a c prim <
        [ a c b ]
        [ c a b ]
        if
      ]
      if
    ]
    [
      a c prim <
      [ b a c ]
      [
        b c prim <
        [ b c a ]
        [ c b a ]
        if
      ]
      if
    ]
    if
  };

: classify
  (forall ρ; ρ lo:Int mid:Int hi:Int -- ρ kind:Int)
  locals { lo mid hi } {
    lo hi prim =
    [ 1 ]
    [
      lo mid prim =
      [ 2 ]
      [
        mid hi prim =
        [ 2 ]
        [ 3 ]
        if
      ]
      if
    ]
    if
  };

: finish
  (forall ρ; ρ lo:Int mid:Int hi:Int -- ρ kind:Int)
  locals { lo mid hi } {
    lo 0 prim =
    [ 0 ]
    [
      hi lo mid prim + prim <
      [ lo mid hi classify ]
      [ 0 ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ a:Int b:Int c:Int -- ρ kind:Int)
  order3 finish;
```

### task: divmod
```firth
: divmod-loop
  (forall ρ; ρ a:Int b:Int q:Int -- ρ q2:Int r:Int)
  locals { a b q } {
    a b prim <
    [ q a ]
    [
      a b prim -
      b
      q 1 prim +
      divmod-loop
    ]
    if
  };

: main
  (forall ρ; ρ a:Int b:Int -- ρ q:Int r:Int)
  0 divmod-loop;
```

### task: isqrt
```firth
: isqrt-loop
  (forall ρ; ρ n:Int r:Int -- ρ result:Int)
  locals { n r } {
    n
    r 1 prim +
    dup prim *
    prim <
    [ r ]
    [ n r 1 prim + isqrt-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ r:Int)
  0 isqrt-loop;
```

### task: is-prime
```firth
: true-val
  (forall ρ; ρ -- ρ b:Bool)
  0 0 prim =;

: false-val
  (forall ρ; ρ -- ρ b:Bool)
  1 0 prim =;

: remainder
  (forall ρ; ρ a:Int b:Int -- ρ r:Int)
  locals { a b } {
    a b prim <
    [ a ]
    [ a b prim - b remainder ]
    if
  };

: trial
  (forall ρ; ρ n:Int d:Int -- ρ result:Bool)
  locals { n d } {
    n d d prim * prim <
    [ true-val ]
    [
      n d remainder 0 prim =
      [ false-val ]
      [ n d 1 prim + trial ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ result:Bool)
  locals { n } {
    n 2 prim <
    [ false-val ]
    [ n 2 trial ]
    if
  };
```

### task: digit-sum
```firth
: divmod10-loop
  (forall ρ; ρ a:Int q:Int -- ρ q2:Int r:Int)
  locals { a q } {
    a 10 prim <
    [ q a ]
    [
      a 10 prim -
      q 1 prim +
      divmod10-loop
    ]
    if
  };

: digitsum-loop
  (forall ρ; ρ n:Int acc:Int -- ρ result:Int)
  locals { n acc } {
    n 0 prim =
    [ acc ]
    [
      n 0 divmod10-loop
      acc
      prim +
      digitsum-loop
    ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ r:Int)
  0 digitsum-loop;
```

### task: lcm
```firth
: remainder
  (forall ρ; ρ a:Int b:Int -- ρ r:Int)
  locals { a b } {
    a b prim <
    [ a ]
    [ a b prim - b remainder ]
    if
  };

: gcd
  (forall ρ; ρ a:Int b:Int -- ρ g:Int)
  locals { a b } {
    b 0 prim =
    [ a ]
    [ b a b remainder gcd ]
    if
  };

: quotient-loop
  (forall ρ; ρ a:Int b:Int q:Int -- ρ result:Int)
  locals { a b q } {
    a b prim <
    [ q ]
    [ a b prim - b q 1 prim + quotient-loop ]
    if
  };

: quotient
  (forall ρ; ρ a:Int b:Int -- ρ q:Int)
  0 quotient-loop;

: main
  (forall ρ; ρ a:Int b:Int -- ρ r:Int)
  locals { a b } {
    a b gcd
    a
    swap
    quotient
    b
    prim *
  };
```

### task: allocate
```firth
: main
  (forall ρ; ρ remaining:Int requested:Int whole:Bool -- ρ left:Int allocated:Int reason:Int)
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
      remaining requested prim -
      requested
      0
    ]
    if
  };
```
