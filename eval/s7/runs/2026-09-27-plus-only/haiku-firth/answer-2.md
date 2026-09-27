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
  [ [ false ] [ true ] if ] [ ] if;
```

### task: majority
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ m:Bool^many)
  [ [ drop true ] [ ] if ] [ [ ] [ drop false ] if ] if;
```

### task: count-true
```firth
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if
  [ 1 ] [ 0 ] if
  [ 1 ] [ 0 ] if
  prim + prim +;
```
