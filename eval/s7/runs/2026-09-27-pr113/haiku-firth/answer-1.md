### task: triple
```firth
: main
  ( -- r:Int^many )
  3 prim *;
```

### task: sum3
```firth
: main
  ( -- r:Int^many )
  prim + prim +;
```

### task: times10
```firth
: main
  ( -- r:Int^many )
  10 prim *;
```

### task: affine
```firth
: main
  ( -- r:Int^many )
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
  [ [ true ] [ false ] if ] [ drop false ] if;
```

### task: xor
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  swap [ [ false ] [ true ] if ] [ ] if;
```

### task: majority
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ m:Bool^many)
  locals { p q r } {
    p [
      q [ true ] [ r ] if
    ] [
      q [ r ] [ false ] if
    ] if
  };
```

### task: count-true
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ n:Int^many)
  locals { p q r } {
    p [ 1 ] [ 0 ] if
    q [ 1 ] [ 0 ] if prim +
    r [ 1 ] [ 0 ] if prim +
  };
```

### task: max
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ b ] [ a ] if };
```

### task: min3
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)
  locals { a b c } {
    a b prim < [ a c prim < [ a ] [ c ] if ] [ b c prim < [ b ] [ c ] if ] if
  };
```

### task: abs-diff
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ b a prim - ] [ a b prim - ] if };
```

### task: clamp
```firth
: main
  (forall ρ; ρ x:Int^many lo:Int^many hi:Int^many -- ρ r:Int^many)
  locals { x lo hi } { x lo prim < [ lo ] [ x hi prim < [ x ] [ hi ] if ] if };
```

### task: is-even
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  0;
```
NOTE: Cannot determine if an integer is even with only +, -, *, <, = primitives and no division or modulo operator.

### task: sum-to
```firth
: sum-to-helper
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  n 0 prim = [ acc ] [ n 1 prim - dup n prim + acc prim + sum-to-helper ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 sum-to-helper;
```

### task: factorial
```firth
: fact-helper
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  n 0 prim = [ acc ] [ n 1 prim - dup acc n prim * fact-helper ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  1 fact-helper;
```

### task: fib
```firth
: fib-helper
  (forall ρ; ρ n:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  n 0 prim = [ a ] [ n 1 prim - b a b prim + fib-helper ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 1 fib-helper;
```

### task: gcd
```firth
: gcd-helper
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  b 0 prim = [ a ] [ b a b prim - prim - gcd-helper ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  gcd-helper;
```
NOTE: This implements gcd using subtraction (Euclid's algorithm with subtraction instead of modulo).

### task: power
```firth
: power-helper
  (forall ρ; ρ base:Int^many exp:Int^many acc:Int^many -- ρ r:Int^many)
  exp 0 prim = [ acc ] [ exp 1 prim - acc base prim * power-helper ] if;

: main
  (forall ρ; ρ base:Int^many exp:Int^many -- ρ r:Int^many)
  1 power-helper;
```
