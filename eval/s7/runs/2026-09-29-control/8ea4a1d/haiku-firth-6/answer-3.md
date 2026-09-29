### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - xs loop-reverse
  };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result index xs } {
    index 0 prim < prim not
    [
      result xs index prim seq-int.at prim seq-int.push
      index 1 prim -
      xs
      loop-reverse
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs loop-prefix
  };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many index:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at sum prim +
      dup result swap prim seq-int.push
      index 1 prim +
      xs
      loop-prefix
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs loop-keep-positive
  };

: loop-keep-positive
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      dup 0 prim <
      [
        drop result
      ]
      [
        dup 0 prim < prim not
        [
          result swap prim seq-int.push
        ]
        [
          drop result
        ]
        if
      ]
      if
      index 1 prim +
      xs
      loop-keep-positive
    ]
    [ result ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    true 0 xs loop-is-sorted
  };

: loop-is-sorted
  (forall ρ; ρ is-sorted:Bool^many index:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { is-sorted index xs } {
    is-sorted
    [
      index 1 prim + xs prim seq-int.len prim < 
      [
        xs index 1 prim + prim seq-int.at xs index prim seq-int.at prim <
        [ false ]
        [ true ]
        if
        index 1 prim +
        xs
        loop-is-sorted
      ]
      [ is-sorted ]
      if
    ]
    [ is-sorted ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false 0 xs target loop-has-pair
  };

: loop-has-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { found i xs target } {
    found prim not
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + i xs target loop-inner-pair
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: loop-inner-pair
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true i xs target loop-has-pair
      ]
      [
        j 1 prim +
        i xs target
        loop-inner-pair
      ]
      if
    ]
    [
      false i 1 prim + xs target loop-has-pair
    ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    prim seq-int.empty n 0 loop-digits
  };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many index:Int^many -- ρ digits:Seq Int^many)
  locals { result n index } {
    n 0 prim =
    [
      result prim seq-int.len 0 prim =
      [
        prim seq-int.empty 0 prim seq-int.push
      ]
      [ result prim seq-int.empty 0 swap loop-reverse-digits ]
      if
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div index 1 prim +
      loop-digits
    ]
    if
  };

: loop-reverse-digits
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      result xs index prim seq-int.at prim seq-int.push
      index 1 prim +
      xs
      loop-reverse-digits
    ]
    [ result ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n loop-primes
  };

: loop-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [
      candidate 2 swap is-prime
      [
        result candidate prim seq-int.push candidate 1 prim + n loop-primes
      ]
      [
        result candidate 1 prim + n loop-primes
      ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [
      candidate divisor prim mod 0 prim =
      [
        false
      ]
      [
        candidate divisor 1 prim + is-prime
      ]
      if
    ]
    [ true ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 loop-sort
  };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      i 0 i xs find-min-from
      xs swap i prim seq-int.set
      i 1 prim +
      loop-sort
    ]
    [ xs ]
    if
  };

: find-min-from
  (forall ρ; ρ min-idx:Int^many j:Int^many xs:Seq Int^many -- ρ min-val:Int^many)
  locals { min-idx j xs } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at xs min-idx prim seq-int.at prim <
      [ j ]
      [ min-idx ]
      if
      j 1 prim +
      xs
      find-min-from
    ]
    [ xs min-idx prim seq-int.at ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole loop-allocate
  };

: loop-allocate
  (forall ρ; ρ stock:Seq Int^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock stock-left allocated reasons order items qtys whole } {
    order qtys prim seq-int.len prim <
    [
      items order prim seq-int.at stock prim seq-int.at
      qtys order prim seq-int.at
      dup swap prim <
      [
        allocated swap prim seq-int.push
        reasons 0 prim seq-int.push
        items order prim seq-int.at swap stock prim seq-int.set
        stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
      ]
      [
        drop dup 0 prim =
        [
          drop allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
        ]
        [
          whole order prim seq-bool.at
          [
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
          ]
          [
            allocated swap prim seq-int.push
            reasons 1 prim seq-int.push
            items order prim seq-int.at 0 stock prim seq-int.set
            stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock-left allocated reasons ]
    if
  };
```
