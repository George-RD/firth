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
  [ swap ] dip swap [ or ] [ and ] if;
```
