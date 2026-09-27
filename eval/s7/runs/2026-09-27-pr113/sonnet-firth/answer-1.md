### task: triple
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  dup dup prim + prim +;
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

### task: pair-sum
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ b:Int^many s:Int^many)
  locals { a b } { b a b prim + };
```

### task: select
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many flag:Bool^many -- ρ r:Int^many)
  [ drop ] [ swap drop ] if;
```

### task: not
```firth
: main
  (forall ρ; ρ p:Bool^many -- ρ r:Bool^many)
  [ false ] [ true ] if;
```

### task: and
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  swap [ ] [ drop false ] if;
```

### task: xor
```firth
: not
  (forall ρ; ρ p:Bool^many -- ρ r:Bool^many)
  [ false ] [ true ] if;

: main
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  swap [ not ] [ ] if;
```

### task: majority
```firth
: and
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  swap [ ] [ drop false ] if;

: or
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  swap [ drop true ] [ ] if;

: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ m:Bool^many)
  locals { p q r } { p q and q r and or p r and or };
```

### task: count-true
```firth
: b-to-i
  (forall ρ; ρ b:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if;

: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ n:Int^many)
  locals { p q r } { p b-to-i q b-to-i r b-to-i prim + prim + };
```

### task: max
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim < [ swap drop ] [ drop ] if;
```

### task: min3
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: min
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim < [ drop ] [ swap drop ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)
  [ min ] dip min;
```

### task: abs-diff
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim - [ swap prim - ] dip prim +;
```

### task: clamp
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: max
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim < [ swap drop ] [ drop ] if;

: min
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim < [ drop ] [ swap drop ] if;

: main
  (forall ρ; ρ x:Int^many lo:Int^many hi:Int^many -- ρ r:Int^many)
  [ max ] dip min;
```

### task: is-even
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  dup 0 prim =
  [ drop true ]
  [ dup 1 prim = [ drop false ] [ 2 prim - main ] if ]
  if;
```

### task: sum-to
```firth
: sum-to-acc
  (forall ρ; ρ acc:Int^many n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop ]
  [ dup [ prim + ] dip 1 prim - sum-to-acc ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 swap sum-to-acc;
```

### task: factorial
```firth
: factorial-acc
  (forall ρ; ρ acc:Int^many n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop ]
  [ dup [ prim * ] dip 1 prim - factorial-acc ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  1 swap factorial-acc;
```

### task: fib
```firth
: fib-acc
  (forall ρ; ρ a:Int^many b:Int^many n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop drop ]
  [ [ swap [ dup ] dip prim + ] dip 1 prim - fib-acc ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  [ 0 1 ] dip fib-acc;
```

### task: gcd
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim =
  [ drop ]
  [ over over prim <
    [ over prim - main ]
    [ swap over prim - swap main ]
    if
  ]
  if;
```

### task: power
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many a:Int^many)
  swap dup [ swap ] dip;

: power-acc
  (forall ρ; ρ base:Int^many acc:Int^many exp:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop swap drop ]
  [ [ over prim * ] dip 1 prim - power-acc ]
  if;

: main
  (forall ρ; ρ base:Int^many exp:Int^many -- ρ r:Int^many)
  [ 1 ] dip power-acc;
```

### task: collatz-steps
```firth
: is-even
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  dup 0 prim =
  [ drop true ]
  [ dup 1 prim = [ drop false ] [ 2 prim - is-even ] if ]
  if;

: half-acc
  (forall ρ; ρ acc:Int^many n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop ]
  [ [ 1 prim + ] dip 2 prim - half-acc ]
  if;

: half
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  [ 0 ] dip half-acc;

: collatz-acc
  (forall ρ; ρ cnt:Int^many n:Int^many -- ρ r:Int^many)
  dup 1 prim =
  [ drop ]
  [ dup is-even
    [ half [ 1 prim + ] dip collatz-acc ]
    [ dup dup prim + prim + 1 prim + [ 1 prim + ] dip collatz-acc ]
    if
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  [ 0 ] dip collatz-acc;
```
NOTE: with only `prim +`, `prim -`, `prim *`, `prim <`, `prim =` available (no division/shift), halving is implemented by repeated subtraction of 2, which costs O(n) fuel per halving; for large n this may exceed the 4096-step fuel budget even though the logic itself is correct for the documented example (n=6 -> 8).
