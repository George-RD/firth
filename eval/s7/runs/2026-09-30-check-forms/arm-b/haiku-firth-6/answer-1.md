### task: seq-sum
```firth
: seq-sum
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs sum-helper };

: sum-helper
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs } {
    i xs prim seq-int.len prim >=
    [ acc ]
    [ acc xs i prim seq-int.at prim + i 1 prim + xs sum-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  seq-sum;
```

### task: seq-max
```firth
: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1 xs max-helper
  };

: max-helper
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim >=
    [ max ]
    [
      xs i prim seq-int.at max prim > 
      [ xs i prim seq-int.at ]
      [ max ]
      if
      i 1 prim + xs max-helper
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  seq-max;
```

### task: count-below
```firth
: count-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k count-helper };

: count-helper
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i xs k } {
    i xs prim seq-int.len prim >=
    [ count ]
    [
      count
      xs i prim seq-int.at k prim < [ 1 prim + ] [ ] if
      i 1 prim + xs k count-helper
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  count-below;
```

### task: index-of
```firth
: index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x index-helper };

: index-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim >=
    [ -1 ]
    [
      xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs x index-helper ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  index-of;
```

### task: reverse
```firth
: reverse
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - xs rev-helper
  };

: rev-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    [ result ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim - xs rev-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  reverse;
```

### task: prefix-sums
```firth
: prefix-sums
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-helper };

: prefix-helper
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      sum xs i prim seq-int.at prim +
      locals { newsum } {
        result newsum prim seq-int.push
        newsum i 1 prim + xs prefix-helper
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prefix-sums;
```

### task: keep-positive
```firth
: keep-positive
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-pos-helper };

: keep-pos-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      xs i prim seq-int.at 0 prim >
      [ result xs i prim seq-int.at prim seq-int.push ]
      [ result ]
      if
      i 1 prim + xs keep-pos-helper
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  keep-positive;
```

### task: is-sorted
```firth
: is-sorted
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ true ]
    [ 0 xs is-sorted-helper ]
    if
  };

: is-sorted-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <=
      [ i 1 prim + xs is-sorted-helper ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  is-sorted;
```

### task: dot
```firth
: dot
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-helper };

: dot-helper
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim >=
    [ sum ]
    [
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      i 1 prim + xs ys dot-helper
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  dot;
```

### task: all-true
```firth
: all-true
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-bool.len 0 prim =
    [ true ]
    [ 0 flags all-true-helper ]
    if
  };

: all-true-helper
  (forall ρ; ρ i:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { i flags } {
    i flags prim seq-bool.len prim >=
    [ true ]
    [
      flags i prim seq-bool.at
      [ i 1 prim + flags all-true-helper ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  all-true;
```

### task: longest-run
```firth
: longest-run
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 prim seq-int.at 1 1 1 xs longest-run-helper ]
    if
  };

: longest-run-helper
  (forall ρ; ρ max:Int^many run-len:Int^many run-val:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max run-len run-val i xs } {
    i xs prim seq-int.len prim >=
    [
      run-len max prim >
      [ run-len ]
      [ max ]
      if
    ]
    [
      xs i prim seq-int.at run-val prim =
      [
        run-len 1 prim + locals { newlen } {
          newlen max prim > [ newlen ] [ max ] if
          locals { newmax } {
            newmax newlen run-val i 1 prim + xs longest-run-helper
          }
        }
      ]
      [
        run-len max prim > 
        [ run-len ]
        [ max ]
        if
        locals { newmax } {
          newmax 1 xs i prim seq-int.at i 1 prim + xs longest-run-helper
        }
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  longest-run;
```

### task: has-pair-sum
```firth
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target has-pair-helper };

: has-pair-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim >=
    [ false ]
    [
      i 1 prim + xs target check-pair
      [ true ]
      [ i 1 prim + xs target has-pair-helper ]
      if
    ]
    if
  };

: check-pair
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim >=
    [ false ]
    [
      j 2 prim - locals { idx } {
        xs idx prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ j 1 prim + xs target check-pair ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  has-pair-sum;
```

### task: count-distinct
```firth
: count-distinct
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 xs count-dist-helper };

: count-dist-helper
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim >=
    [ seen prim seq-int.len ]
    [
      xs i prim seq-int.at locals { val } {
        0 seen val find-in-seq
        [ seen i 1 prim + xs count-dist-helper ]
        [ seen val prim seq-int.push i 1 prim + xs count-dist-helper ]
        if
      }
    ]
    if
  };

: find-in-seq
  (forall ρ; ρ idx:Int^many seen:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { idx seen val } {
    idx seen prim seq-int.len prim >=
    [ false ]
    [
      seen idx prim seq-int.at val prim =
      [ true ]
      [ idx 1 prim + seen val find-in-seq ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  count-distinct;
```

### task: merge-sorted
```firth
: merge-sorted
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-helper };

: merge-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim >=
    [
      j ys prim seq-int.len prim >=
      [ result ]
      [ result ys j prim seq-int.at prim seq-int.push j 1 prim + ys merge-finish ]
      if
    ]
    [
      j ys prim seq-int.len prim >=
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs merge-finish-xs ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <=
        [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys merge-helper ]
        [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys merge-helper ]
        if
      ]
      if
    ]
    if
  };

: merge-finish-xs
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim >=
    [ result ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs merge-finish-xs ]
    if
  };

: merge-finish
  (forall ρ; ρ result:Seq Int^many j:Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result j ys } {
    j ys prim seq-int.len prim >=
    [ result ]
    [ result ys j prim seq-int.at prim seq-int.push j 1 prim + ys merge-finish ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  merge-sorted;
```

### task: digits
```firth
: digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      n 0 prim <
      [ n 0 prim - digits-helper ]
      [ n digits-helper ]
      if
    ]
    if
  };

: digits-helper
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty ]
    [
      n 10 prim mod locals { digit } {
        n 10 prim div digits-helper digit prim seq-int.push
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  digits;
```

### task: primes-up-to
```firth
: primes-up-to
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim <
    [ prim seq-int.empty ]
    [ prim seq-int.empty 2 n sieve-helper ]
    if
  };

: sieve-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result i n } {
    i n prim > 
    [ result ]
    [
      i is-prime
      [ result i prim seq-int.push i 1 prim + n sieve-helper ]
      [ result i 1 prim + n sieve-helper ]
      if
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        n 2 prim mod 0 prim =
        [ false ]
        [ 3 n check-divisor ]
        if
      ]
      if
    ]
    if
  };

: check-divisor
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim >
    [ true ]
    [
      n d prim mod 0 prim =
      [ false ]
      [ d 2 prim + n check-divisor ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  primes-up-to;
```

### task: histogram
```firth
: histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k histogram-init locals { counts } { counts 0 xs histogram-helper } };

: histogram-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result i k } {
    i k prim >=
    [ result ]
    [ result 0 prim seq-int.push i 1 prim + k histogram-init ]
    if
  };

: histogram-helper
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { counts i xs } {
    i xs prim seq-int.len prim >=
    [ counts ]
    [
      xs i prim seq-int.at locals { val } {
        counts val counts val prim seq-int.at 1 prim + prim seq-int.set
        i 1 prim + xs histogram-helper
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  histogram;
```

### task: sort
```firth
: sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs sort-insertion };

: sort-insertion
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs insert-all };

: insert-all
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim >=
    [ result ]
    [ result xs i prim seq-int.at insert-sorted i 1 prim + xs insert-all ]
    if
  };

: insert-sorted
  (forall ρ; ρ result:Seq Int^many x:Int^many -- ρ result:Seq Int^many)
  locals { result x } {
    result prim seq-int.len 0 prim =
    [ result x prim seq-int.push ]
    [ 0 result x insert-pos ]
    if
  };

: insert-pos
  (forall ρ; ρ i:Int^many result:Seq Int^many x:Int^many -- ρ result:Seq Int^many)
  locals { i result x } {
    i result prim seq-int.len prim >=
    [ result x prim seq-int.push ]
    [
      result i prim seq-int.at x prim >
      [ prim seq-int.empty 0 result x i insert-elem ]
      [ i 1 prim + result x insert-pos ]
      if
    ]
    if
  };

: insert-elem
  (forall ρ; ρ new:Seq Int^many j:Int^many result:Seq Int^many x:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { new j result x pos } {
    j pos prim >=
    [ new x prim seq-int.push j result insert-rest ]
    [
      new result j prim seq-int.at prim seq-int.push
      j 1 prim + result x pos insert-elem
    ]
    if
  };

: insert-rest
  (forall ρ; ρ new:Seq Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { new j result } {
    j result prim seq-int.len prim >=
    [ new ]
    [ new result j prim seq-int.at prim seq-int.push j 1 prim + result insert-rest ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  sort;
```

### task: ledger
```firth
: ledger
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs ledger-helper };

: ledger-helper
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim >=
    [ balance rejected ]
    [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim <
        [ balance rejected 1 prim + i 1 prim + txs ledger-helper ]
        [ balance tx prim + rejected i 1 prim + txs ledger-helper ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  ledger;
```

### task: allocate-batch
```firth
: allocate-batch
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim >=
    [ stock allocated reasons ]
    [
      items j prim seq-int.at locals { item-id } {
        stock item-id prim seq-int.at locals { current-stock } {
          qtys j prim seq-int.at locals { needed } {
            whole j prim seq-bool.at locals { must-fill } {
              needed current-stock prim <=
              [
                stock item-id needed current-stock prim - prim seq-int.set
                locals { newstock } {
                  newstock allocated needed prim seq-int.push reasons 0 prim seq-int.push j 1 prim + items qtys whole allocate-loop
                }
              ]
              [
                current-stock 0 prim =
                [ stock allocated reasons 2 prim seq-int.push j 1 prim + items qtys whole allocate-loop ]
                [
                  must-fill
                  [ stock allocated reasons 3 prim seq-int.push j 1 prim + items qtys whole allocate-loop ]
                  [
                    stock item-id 0 prim seq-int.set
                    locals { newstock } {
                      newstock allocated current-stock prim seq-int.push reasons 1 prim seq-int.push j 1 prim + items qtys whole allocate-loop
                    }
                  ]
                  if
                ]
                if
              ]
              if
            }
          }
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  allocate-batch;
```
