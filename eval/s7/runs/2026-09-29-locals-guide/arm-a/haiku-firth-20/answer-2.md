### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs max-loop };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      max xs i prim seq-int.at prim <
      [ xs i prim seq-int.at ]
      [ max ]
      if
      i 1 prim +
      xs
      max-loop
    ]
    [ max ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result len xs } {
    len 0 prim <
    [ result ]
    [
      result xs len 1 prim - prim seq-int.at prim seq-int.push
      len 1 prim -
      xs
      reverse-loop
    ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      swap
      prim seq-int.push
      i 1 prim +
      xs
      prefix-loop
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs filter-loop };

: filter-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      0 xs i prim seq-int.at prim <
      [ result xs i prim seq-int.at prim seq-int.push ]
      [ result ]
      if
      i 1 prim +
      xs
      filter-loop
    ]
    [ result ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ 1 ]
    [ 1 1 xs is-sorted-check ]
    if
  };

: is-sorted-check
  (forall ρ; ρ ok:Bool^many i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { ok i xs } {
    ok
    [
      i xs prim seq-int.len prim <
      [
        xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim <
        [ i 1 prim + xs is-sorted-check ]
        [ 0 i xs is-sorted-check ]
        if
      ]
      [ 1 ]
      if
    ]
    [ 0 ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { 1 0 flags check-all-true };

: check-all-true
  (forall ρ; ρ is-all:Bool^many i:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { is-all i flags } {
    is-all
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
        [ i 1 prim + flags check-all-true ]
        [ 0 i flags drop drop check-all-true ]
        if
      ]
      [ 1 ]
      if
    ]
    [ 0 ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 1 0 xs longest-run-loop ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-len:Int^many curr-len:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-len curr-len i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
      [
        curr-len 1 prim +
        max-len curr-len 1 prim + max-len prim <
        [ curr-len 1 prim + ]
        [ max-len ]
        if
        i 1 prim +
        xs
        longest-run-loop
      ]
      [
        max-len curr-len max-len prim <
        [ curr-len ]
        [ max-len ]
        if
        1
        i 1 prim +
        xs
        longest-run-loop
      ]
      if
    ]
    [ max-len curr-len max-len prim < [ curr-len ] [ max-len ] if ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { 0 xs target find-pair };

: find-pair
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      i 1 prim + xs target find-pair-inner
    ]
    [ 0 ]
    if
  };

: find-pair-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim <
    [
      xs j 1 prim - prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        1
      ]
      [
        j 1 prim +
        xs
        target
        find-pair-inner
      ]
      if
    ]
    [ 0 ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { prim seq-int.empty 0 xs count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at seen is-in-seq
      [ seen i 1 prim + xs count-distinct-loop ]
      [ seen xs i prim seq-int.at prim seq-int.push i 1 prim + xs count-distinct-loop ]
      if
    ]
    [ seen prim seq-int.len ]
    if
  };

: is-in-seq
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { val seq } { 0 seq val check-in };

: check-in
  (forall ρ; ρ i:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { i seq val } {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at val prim =
      [ 1 ]
      [ i 1 prim + seq val check-in ]
      if
    ]
    [ 0 ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n extract-digits ]
    if
  };

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      extract-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n find-primes };

: find-primes
  (forall ρ; ρ result:Seq Int^many num:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { result num limit } {
    num limit prim <
    [
      num is-prime
      [ result num prim seq-int.push ]
      [ result ]
      if
      num 1 prim +
      limit
      find-primes
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim <
    [ 0 ]
    [
      num 2 prim =
      [ 1 ]
      [
        num 2 prim mod 0 prim =
        [ 0 ]
        [ num 3 check-prime-divisors ]
        if
      ]
      if
    ]
    if
  };

: check-prime-divisors
  (forall ρ; ρ num:Int^many div:Int^many -- ρ result:Bool^many)
  locals { num div } {
    div div prim * num prim < prim not
    [ 1 ]
    [
      num div prim mod 0 prim =
      [ 0 ]
      [ num div 2 prim + check-prime-divisors ]
      if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { k make-empty-histogram 0 xs k histogram-loop };

: make-empty-histogram
  (forall ρ; ρ k:Int^many -- ρ result:Seq Int^many)
  locals { k } {
    prim seq-int.empty 0 k histogram-init
  };

: histogram-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result i k } {
    i k prim <
    [ result 0 prim seq-int.push i 1 prim + k histogram-init ]
    [ result ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result i xs k } {
    i xs prim seq-int.len prim <
    [
      result
      xs i prim seq-int.at
      result xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      i 1 prim +
      xs
      k
      histogram-loop
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at i find-position-and-insert
      i 1 prim +
      insertion-sort-loop
    ]
    [ xs ]
    if
  };

: find-position-and-insert
  (forall ρ; ρ xs:Seq Int^many val:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { xs val pos } {
    pos 0 prim =
    [ xs val 0 prim seq-int.set ]
    [
      xs pos 1 prim - prim seq-int.at val prim <
      [ xs val pos 1 prim - find-position-and-insert ]
      [ xs val pos prim seq-int.set ]
      if
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs process-transactions };

: process-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + dup
      balance txs i prim seq-int.at prim + 0 prim <
      [
        drop
        balance
        rejected 1 prim +
        i 1 prim +
        txs
        process-transactions
      ]
      [
        balance
        rejected
        i 1 prim +
        txs
        process-transactions
      ]
      if
    ]
    [ balance rejected ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 stock items qtys whole allocate-orders
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many stock-orig:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons j stock-orig items qtys whole } {
    j qtys prim seq-int.len prim <
    [
      items j prim seq-int.at
      stock items j prim seq-int.at prim seq-int.at
      qtys j prim seq-int.at
      whole j prim seq-bool.at
      allocate-single-order
      stock
      allocated
      reasons
      j 1 prim +
      stock-orig items qtys whole
      allocate-orders
    ]
    [ stock allocated reasons ]
    if
  };

: allocate-single-order
  (forall ρ; ρ item:Int^many curr-stock:Int^many qty:Int^many whole-flag:Bool^many -- ρ allocated-qty:Int^many reason:Int^many)
  locals { item curr-stock qty whole-flag } {
    qty curr-stock prim <
    [ qty 0 ]
    [
      curr-stock 0 prim =
      [ 0 2 ]
      [
        whole-flag
        [ 0 3 ]
        [ curr-stock 1 ]
        if
      ]
      if
    ]
    if
  };
```
