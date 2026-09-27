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
  dup dup dup dup dup dup dup dup dup
  prim + prim + prim + prim + prim + prim + prim + prim + prim +;
```

### task: affine
```firth
: main
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  dup dup dup prim + prim + prim + 7 prim +;
```

### task: pair-sum
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ b:Int^many s:Int^many)
  dup [ swap ] dip prim +;
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
  [ ] [ drop false ] if;
```

### task: xor
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  [ not ] [ ] if;

: not
  (forall ρ; ρ p:Bool^many -- ρ r:Bool^many)
  [ false ] [ true ] if;
```

### task: majority
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ m:Bool^many)
  [ swap ] dip swap
  [ or ] [ and ] if;

: and
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  [ ] [ drop false ] if;

: or
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  [ drop true ] [ ] if;
```

### task: count-true
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ n:Int^many)
  bool-to-int
  [ bool-to-int ] dip
  prim +
  [ bool-to-int ] dip
  prim +;

: bool-to-int
  (forall ρ; ρ p:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if;
```

### task: max
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many c:Int^many)
  [ dup ] dip swap;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim > [ drop ] [ swap drop ] if;
```
NOTE: the only primitive in the supported execution profile is `prim +`; there is no documented comparison primitive such as `prim >`, so this cannot compile or run on the portable runner as written.

### task: min3
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many c:Int^many)
  [ dup ] dip swap;

: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim < [ drop ] [ swap drop ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)
  [ min2 ] dip min2;
```
NOTE: this relies on `prim <`, which is not in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: abs-diff
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many c:Int^many)
  [ dup ] dip swap;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim > [ prim - ] [ swap prim - ] if;
```
NOTE: this relies on `prim -` and `prim >`, neither of which is in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: clamp
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many c:Int^many)
  [ dup ] dip swap;

: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim > [ drop ] [ swap drop ] if;

: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  over over prim < [ drop ] [ swap drop ] if;

: main
  (forall ρ; ρ x:Int^many lo:Int^many hi:Int^many -- ρ r:Int^many)
  [ swap ] dip swap min2 max2;
```
NOTE: this relies on `prim >` and `prim <`, neither of which is in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: is-even
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  2 prim mod 0 prim =;
```
NOTE: this relies on `prim mod` and `prim =`, neither of which is in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: sum-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop 0 ]
  [ dup 1 prim - main swap prim + ]
  if;
```
NOTE: this relies on `prim -` and `prim =`, neither of which is in the documented supported primitive profile (only `prim +` is listed); it also recurses to a depth of `n`, which may exceed the 256-administrative-frame recursion limit for larger inputs. It cannot execute on the portable runner as written.

### task: factorial
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop 1 ]
  [ dup 1 prim - main swap prim * ]
  if;
```
NOTE: this relies on `prim -`, `prim =`, and `prim *`, none of which is in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: fib
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop 0 ]
  [ dup 1 prim =
    [ drop 1 ]
    [ dup 1 prim - main
      swap 2 prim - main
      prim + ]
    if ]
  if;
```
NOTE: this relies on `prim -` and `prim =`, neither of which is in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: gcd
```firth
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop ]
  [ dup [ prim mod ] dip swap main ]
  if;
```
NOTE: this relies on `prim mod` and `prim =`, neither of which is in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: power
```firth
: over
  (forall ρ; ρ a:Int^many b:Int^many -- ρ a:Int^many b:Int^many c:Int^many)
  [ dup ] dip swap;

: main
  (forall ρ; ρ base:Int^many exp:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop drop 1 ]
  [ over [ 1 prim - ] dip [ main ] dip prim * ]
  if;
```
NOTE: this relies on `prim -`, `prim =`, and `prim *`, none of which is in the documented supported primitive profile (only `prim +` is listed), so it cannot execute on the portable runner.

### task: collatz-steps
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 swap collatz-loop;

: collatz-loop
  (forall ρ; ρ acc:Int^many n:Int^many -- ρ r:Int^many)
  dup 1 prim =
  [ drop ]
  [ dup 2 prim mod 0 prim =
    [ 2 prim / ]
    [ 3 prim * 1 prim + ]
    if
    swap 1 prim + swap
    collatz-loop ]
  if;
```
NOTE: this relies on `prim mod`, `prim /`, `prim *`, and `prim =`, none of which is in the documented supported primitive profile (only `prim +` is listed), and its recursion depth is unbounded in `n`, which the finite fuel/frame limits may not accommodate; it cannot execute on the portable runner as written.
