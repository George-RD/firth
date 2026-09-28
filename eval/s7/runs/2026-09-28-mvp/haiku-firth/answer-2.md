### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 xs sum-loop;

: sum-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs acc i } {
    [ i xs prim seq-int.len prim = ]
    [ acc ]
    [ 
      i 1 prim +
      xs i prim seq-int.at acc prim +
      xs
      sum-loop
    ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at 1 xs max-loop;

: max-loop
  (forall ρ; ρ i:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs max i } {
    [ i xs prim seq-int.len prim = ]
    [ max ]
    [
      [ xs i prim seq-int.at max prim < ]
      [ i 1 prim + max xs max-loop ]
      [ i 1 prim + xs i prim seq-int.at xs max-loop ]
      if
    ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 xs k count-helper;

: count-helper
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { k xs count i } {
    [ i xs prim seq-int.len prim = ]
    [ count ]
    [
      [ xs i prim seq-int.at k prim < ]
      [ i 1 prim + count 1 prim + xs k count-helper ]
      [ i 1 prim + count xs k count-helper ]
      if
    ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  -1 0 xs x find-index;

: find-index
  (forall ρ; ρ i:Int^many result:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs result i } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      [ result -1 prim = prim not ]
      [ result i 1 prim + xs x find-index ]
      [
        [ xs i prim seq-int.at x prim = ]
        [ i i 1 prim + xs x find-index ]
        [ i 1 prim + result xs x find-index ]
        if
      ]
      if
    ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty 0 xs reverse-helper;

: reverse-helper
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs result i } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      xs i prim seq-int.at result prim seq-int.push
      i 1 prim +
      xs
      reverse-helper
    ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 xs prefix-loop;

: prefix-loop
  (forall ρ; ρ i:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs result sum i } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      xs i prim seq-int.at sum prim +
      result prim seq-int.push
      i 1 prim +
      xs
      prefix-loop
    ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 xs keep-positive-loop;

: keep-positive-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs result i } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      [ xs i prim seq-int.at 0 prim < ]
      [ i 1 prim + result xs keep-positive-loop ]
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs keep-positive-loop ]
      if
    ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  true 0 xs is-sorted-loop;

: is-sorted-loop
  (forall ρ; ρ i:Int^many is-sorted:Bool^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs is-sorted i } {
    [ i xs prim seq-int.len 1 prim - prim = ]
    [ is-sorted ]
    [
      [ is-sorted prim not ]
      [ i 1 prim + false xs is-sorted-loop ]
      [
        [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < ]
        [ i 1 prim + false xs is-sorted-loop ]
        [ i 1 prim + true xs is-sorted-loop ]
        if
      ]
      if
    ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 xs ys dot-loop;

: dot-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs acc i } {
    [ i xs prim seq-int.len prim = ]
    [ acc ]
    [
      i 1 prim +
      xs i prim seq-int.at ys i prim seq-int.at prim * acc prim +
      xs
      ys
      dot-loop
    ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true 0 flags all-true-loop;

: all-true-loop
  (forall ρ; ρ i:Int^many result:Bool^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags result i } {
    [ i flags prim seq-bool.len prim = ]
    [ result ]
    [
      [ result prim not ]
      [ i 1 prim + false flags all-true-loop ]
      [ i 1 prim + flags i prim seq-bool.at flags all-true-loop ]
      if
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  [ xs prim seq-int.len 0 prim = ]
  [ 0 ]
  [ 0 1 0 xs longest-run-loop ]
  if;

: longest-run-loop
  (forall ρ; ρ i:Int^many current:Int^many max:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { xs max current i } {
    [ i xs prim seq-int.len prim = ]
    [
      [ current max prim < ]
      [ max ]
      [ current ]
      if
    ]
    [
      [ i 0 prim = ]
      [
        i 1 prim +
        1
        1
        xs
        longest-run-loop
      ]
      [
        [ xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim = ]
        [
          i 1 prim +
          current 1 prim +
          max
          xs
          longest-run-loop
        ]
        [
          i 1 prim +
          1
          [ current max prim < ] [ max ] [ current ] if
          xs
          longest-run-loop
        ]
        if
      ]
      if
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false 0 xs target has-pair-outer;

: has-pair-outer
  (forall ρ; ρ i:Int^many found:Bool^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs found i } {
    [ i xs prim seq-int.len prim = ]
    [ found ]
    [
      [ found ]
      [ i 1 prim + true xs target has-pair-outer ]
      [ xs i prim seq-int.at target prim - 0 i 1 prim + xs target has-pair-inner ]
      if
    ]
    if
  };

: has-pair-inner
  (forall ρ; ρ j:Int^many complement:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs i complement j } {
    [ j xs prim seq-int.len prim = ]
    [ false i 1 prim + xs target has-pair-outer ]
    [
      [ xs j prim seq-int.at complement prim = ]
      [ true i 1 prim + xs target has-pair-outer ]
      [ j 1 prim + complement i xs target has-pair-inner ]
      if
    ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 xs count-distinct-loop;

: count-distinct-loop
  (forall ρ; ρ i:Int^many seen:Seq Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { xs seen i } {
    [ i xs prim seq-int.len prim = ]
    [ seen prim seq-int.len ]
    [
      xs i prim seq-int.at 0 seen check-contains
      [ i 1 prim + seen xs count-distinct-loop ]
      [ xs i prim seq-int.at seen prim seq-int.push i 1 prim + xs count-distinct-loop ]
      if
    ]
    if
  };

: check-contains
  (forall ρ; ρ seen:Seq Int^many search:Int^many i:Int^many elem:Int^many -- ρ found:Bool^many)
  locals { elem search seen i } {
    [ i seen prim seq-int.len prim = ]
    [ false ]
    [
      [ seen i prim seq-int.at elem prim = ]
      [ true ]
      [ i 1 prim + search seen check-contains ]
      if
    ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 xs ys merge-loop;

: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs result j i } {
    [ i xs prim seq-int.len prim = ]
    [
      [ j ys prim seq-int.len prim = ]
      [ result ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + 0 xs ys merge-loop ]
      if
    ]
    [
      [ j ys prim seq-int.len prim = ]
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + 0 xs ys merge-loop ]
      [
        [ xs i prim seq-int.at ys j prim seq-int.at prim < ]
        [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys merge-loop ]
        [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys merge-loop ]
        if
      ]
      if
    ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  [ n 0 prim = ]
  [ prim seq-int.empty 0 prim seq-int.push ]
  [ prim seq-int.empty n extract-digits ]
  if;

: extract-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    [ n 0 prim = ]
    [ result ]
    [
      n 10 prim % result prim seq-int.push
      n 10 prim /
      extract-digits
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 n primes-loop;

: primes-loop
  (forall ρ; ρ i:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n result i } {
    [ i n prim < prim not ]
    [ result ]
    [
      i is-prime
      [ i result prim seq-int.push i 1 prim + n primes-loop ]
      [ i 1 prim + n primes-loop ]
      if
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  [ n 2 prim < ]
  [ false ]
  [
    [ n 2 prim = ]
    [ true ]
    [
      [ n 2 prim % 0 prim = ]
      [ false ]
      [ 2 n check-prime ]
      if
    ]
    if
  ]
  if;

: check-prime
  (forall ρ; ρ d:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    [ d d prim * n prim < prim not ]
    [ true ]
    [
      [ n d prim % 0 prim = ]
      [ false ]
      [ d 2 prim + n check-prime ]
      if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty 0 0 k xs histogram-init;

: histogram-init
  (forall ρ; ρ i:Int^many result:Seq Int^many k:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs k result i } {
    [ i k prim = ]
    [ result 0 xs histogram-count ]
    [ 0 result prim seq-int.push i 1 prim + k xs histogram-init ]
    if
  };

: histogram-count
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs result i } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      xs i prim seq-int.at result swap
      locals { idx result } {
        result idx prim seq-int.at 1 prim +
        result idx prim seq-int.at 1 prim + rebuild-seq
      }
      i 1 prim +
      xs
      histogram-count
    ]
    if
  };

: rebuild-seq
  (forall ρ; ρ new-val:Int^many result:Seq Int^many idx:Int^many i:Int^many -- ρ updated:Seq Int^many)
  locals { i idx result new-val } {
    [ i result prim seq-int.len prim = ]
    [ prim seq-int.empty ]
    [
      [ i idx prim = ]
      [ new-val prim seq-int.push i 1 prim + idx result new-val rebuild-seq ]
      [ result i prim seq-int.at prim seq-int.push i 1 prim + idx result new-val rebuild-seq ]
      if
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 xs prim seq-int.len bubble-pass;

: bubble-pass
  (forall ρ; ρ n:Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i n } {
    [ n 0 prim = ]
    [ xs ]
    [
      [ i xs prim seq-int.len 1 prim - prim = ]
      [ xs n 1 prim - 0 bubble-pass ]
      [
        [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < ]
        [ i 1 prim + xs n bubble-pass ]
        [ 
          xs i prim seq-int.at xs i 1 prim + prim seq-int.at
          i xs swap-at i 1 prim + xs n bubble-pass
        ]
        if
      ]
      if
    ]
    if
  };

: swap-at
  (forall ρ; ρ val2:Int^many val1:Int^many i:Int^many xs:Seq Int^many -- ρ swapped:Seq Int^many)
  prim seq-int.empty 0 swap-build-loop;

: swap-build-loop
  (forall ρ; ρ j:Int^many acc:Seq Int^many xs:Seq Int^many i:Int^many val1:Int^many val2:Int^many -- ρ swapped:Seq Int^many)
  locals { val2 val1 i xs acc j } {
    [ j xs prim seq-int.len prim = ]
    [ acc ]
    [
      [ j i prim = ]
      [ val1 acc prim seq-int.push j 1 prim + xs i val1 val2 swap-build-loop ]
      [
        [ j i 1 prim + prim = ]
        [ val2 acc prim seq-int.push j 1 prim + xs i val1 val2 swap-build-loop ]
        [ xs j prim seq-int.at acc prim seq-int.push j 1 prim + xs i val1 val2 swap-build-loop ]
        if
      ]
      if
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 start txs ledger-loop;

: ledger-loop
  (forall ρ; ρ i:Int^many rejected:Int^many balance:Int^many txs:Seq Int^many start:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs balance rejected i } {
    [ i txs prim seq-int.len prim = ]
    [ balance rejected ]
    [
      [ balance txs i prim seq-int.at prim + 0 prim < ]
      [ balance i 1 prim + rejected 1 prim + txs start ledger-loop ]
      [ balance txs i prim seq-int.at prim + i 1 prim + rejected txs start ledger-loop ]
      if
    ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 stock items qtys whole allocate-orders;

: allocate-orders
  (forall ρ; ρ j:Int^many whole:Seq Bool^many qtys:Seq Int^many items:Seq Int^many stock:Seq Int^many reasons:Seq Int^many allocated:Seq Int^many stock-left:Seq Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock stock-left allocated reasons j } {
    [ j qtys prim seq-int.len prim = ]
    [ stock-left allocated reasons ]
    [
      items j prim seq-int.at stock-left qtys j prim seq-int.at whole j prim seq-bool.at
      allocate-one j stock-left allocated reasons qtys items whole
    ]
    if
  };

: allocate-one
  (forall ρ; ρ whole-flag:Bool^many qty:Int^many idx:Int^many reasons:Seq Int^many allocated:Seq Int^many stock:Seq Int^many item:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock item prim seq-int.at
  locals { avail item stock reasons allocated j whole-flag qty idx } {
    [ qty avail prim = ]
    [ qty 0 avail qty prim - stock item allocated reasons j whole-flag qty idx finish-alloc ]
    [
      [ avail 0 prim = ]
      [ 0 2 stock item allocated reasons j whole-flag qty idx finish-alloc ]
      [
        [ whole-flag ]
        [ 0 3 stock item allocated reasons j whole-flag qty idx finish-alloc ]
        [ avail 1 stock item allocated reasons j whole-flag qty idx finish-alloc ]
        if
      ]
      if
    ]
    if
  };

: finish-alloc
  (forall ρ; ρ idx:Int^many qty:Int^many whole-flag:Bool^many j:Int^many reasons:Seq Int^many allocated:Seq Int^many item:Int^many stock:Seq Int^many reason:Int^many alloc:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { alloc reason stock item allocated reasons j whole-flag qty idx } {
    stock item alloc update-stock-at
    allocated alloc prim seq-int.push
    reasons reason prim seq-int.push
    j 1 prim + whole-flag qty item stock allocated reasons allocate-orders
  };

: update-stock-at
  (forall ρ; ρ alloc:Int^many idx:Int^many stock:Seq Int^many -- ρ updated:Seq Int^many)
  prim seq-int.empty 0 update-build;

: update-build
  (forall ρ; ρ i:Int^many result:Seq Int^many stock:Seq Int^many idx:Int^many alloc:Int^many -- ρ updated:Seq Int^many)
  locals { alloc idx stock result i } {
    [ i stock prim seq-int.len prim = ]
    [ result ]
    [
      [ i idx prim = ]
      [ stock i prim seq-int.at alloc prim - result prim seq-int.push i 1 prim + stock idx alloc update-build ]
      [ stock i prim seq-int.at result prim seq-int.push i 1 prim + stock idx alloc update-build ]
      if
    ]
    if
  };
```
