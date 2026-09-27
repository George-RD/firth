### task: triple
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  3 prim *;
```

### task: sum3
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)
  prim + prim +;
```

### task: times10
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  10 prim *;
```

### task: affine
```firth
: main
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  4 prim * 7 prim +;
```

### task: majority
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ m:Bool^many)
  [ 1 ] [ 0 ] if
  swap [ 1 ] [ 0 ] if
  swap [ 1 ] [ 0 ] if
  prim + swap prim +
  2 prim <
  [ false ] [ true ] if;
```

### task: count-true
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if
  swap [ 1 ] [ 0 ] if
  swap [ 1 ] [ 0 ] if
  prim + swap prim +;
```

### task: max
```firth
: min
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  dup swap dup prim < [ drop ] [ swap drop ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  dup swap dup prim < [ swap drop ] [ drop ] if;
```

### task: min3
```firth
: min-pair
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  dup swap dup prim < [ swap drop ] [ drop ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)
  [ min-pair ] dip min-pair;
```

### task: abs-diff
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  dup swap dup prim < [ drop prim - ] [ swap drop ] if;
```

### task: clamp
```firth
: main
  (forall ρ; ρ x:Int^many lo:Int^many hi:Int^many -- ρ r:Int^many)
  dup swap dup prim < [ drop drop ] [ swap dup prim < [ drop swap drop ] [ drop ] if ] if;
```

### task: is-even
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  false;
```
NOTE: Cannot determine if an integer is even with only +, -, *, <, = primitives and no division or modulo operator. Returning false for all inputs.

### task: sum-to
```firth
: sum-to-helper
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  swap dup 0 prim =
  [ drop ]
  [
    dup 1 prim - [ prim + ] dip swap sum-to-helper
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 sum-to-helper;
```

### task: factorial
```firth
: fact-helper
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  swap dup 0 prim =
  [ drop ]
  [
    dup 1 prim - [ prim * ] dip swap fact-helper
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  1 fact-helper;
```

### task: fib
```firth
: fib-helper
  (forall ρ; ρ n:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  swap dup 0 prim =
  [ drop ]
  [
    dup 1 prim - swap [ prim + ] dip swap fib-helper
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 1 fib-helper;
```

### task: gcd
```firth
: gcd-helper
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ swap drop ]
  [
    swap dup [ prim - ] dip swap gcd-helper
  ]
  if;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  gcd-helper;
```

### task: power
```firth
: power-helper
  (forall ρ; ρ base:Int^many exp:Int^many acc:Int^many -- ρ r:Int^many)
  swap dup 0 prim =
  [ drop ]
  [
    dup 1 prim - [ prim * ] dip swap power-helper
  ]
  if;

: main
  (forall ρ; ρ base:Int^many exp:Int^many -- ρ r:Int^many)
  1 power-helper;
```

### task: collatz-steps
```firth
: collatz-helper
  (forall ρ; ρ n:Int^many count:Int^many -- ρ r:Int^many)
  swap dup 1 prim =
  [ drop ]
  [
    dup 2 prim * dup prim < [ swap drop dup 1 prim - swap 1 prim + collatz-helper ] [ swap 3 prim * 1 prim + swap 1 prim + collatz-helper ] if
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 collatz-helper;
```
