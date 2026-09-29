### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs } {
    [ xs i prim seq-int.at acc prim + i 1 prim + xs sum-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs max-loop };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    [ xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if i 1 prim + xs max-loop ]
    [ max ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc i xs k } {
    [ xs i prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if i 1 prim + xs k count-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x find-loop };

: find-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    [ xs i prim seq-int.at x prim = [ i ] [ i 1 prim + xs x find-loop ] if ]
    [ -1 ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs rev-loop };

: rev-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i xs } {
    [ xs i prim seq-int.at acc prim seq-int.push i 1 prim + xs rev-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs ps-loop };

: ps-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    [ xs i prim seq-int.at sum prim + result swap prim seq-int.push i 1 prim + xs ps-loop ]
    [ result ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs kp-loop };

: kp-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i xs } {
    [ xs i prim seq-int.at 0 prim < [ acc i 1 prim + xs kp-loop ] [ xs i prim seq-int.at acc prim seq-int.push i 1 prim + xs kp-loop ] if ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { true 0 xs is-sort-loop };

: is-sort-loop
  (forall ρ; ρ ok:Bool^many i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { ok i xs } {
    [ ok [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [ i 1 prim + xs is-sort-loop ] if ] [ false ] if ]
    [ ok ]
    i xs prim seq-int.len 1 prim - prim <
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs ys } {
    [ xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + i 1 prim + xs ys dot-loop ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 flags at-loop };

: at-loop
  (forall ρ; ρ ok:Bool^many i:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { ok i flags } {
    [ ok [ flags i prim seq-bool.at [ i 1 prim + flags at-loop ] [ false ] if ] [ false ] if ]
    [ ok ]
    i flags prim seq-bool.len prim <
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 0 1 xs lr-loop };

: lr-loop
  (forall ρ; ρ maxlen:Int^many curlen:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { maxlen curlen i xs } {
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [ curlen 1 prim + ] [ 1 ] if maxlen prim < [ i 1 prim + xs lr-loop ] [ maxlen i 1 prim + xs lr-loop ] if ]
    [ maxlen curlen prim < [ curlen ] [ maxlen ] if ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 xs target hps-loop };

: hps-loop
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } {
    [ found [ 0 i 1 prim + xs target hps-inner ] [ false ] if ]
    [ found ]
    i xs prim seq-int.len prim <
    if
  };

: hps-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + i xs target hps-inner ] if ]
    [ j 1 prim + i xs target hps-loop ]
    j xs prim seq-int.len prim <
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 xs cd-loop };

: cd-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    [ xs i prim seq-int.at seen contains [ i 1 prim + xs cd-loop ] [ xs i prim seq-int.at seen prim seq-int.push i 1 prim + xs cd-loop ] if ]
    [ seen prim seq-int.len ]
    i xs prim seq-int.len prim <
    if
  };

: contains
  (forall ρ; ρ x:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { x seq } { false 0 x seq cont-loop };

: cont-loop
  (forall ρ; ρ found:Bool^many i:Int^many x:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { found i x seq } {
    [ seq i prim seq-int.at x prim = [ true ] [ found i 1 prim + x seq cont-loop ] if ]
    [ found ]
    i seq prim seq-int.len prim <
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys ms-loop };

: ms-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    [ i xs prim seq-int.len prim < [ j ys prim seq-int.len prim < [ xs i prim seq-int.at ys j prim seq-int.at prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys ms-loop ] [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys ms-loop ] if ] [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys ms-loop ] if ] [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys ms-loop ] if ]
    [ result ]
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim or prim not
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n dig-loop ] if };

: dig-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    [ n 10 prim mod result prim seq-int.push n 10 prim div dig-loop ]
    [ result ]
    n 0 prim =
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n prim-loop };

: prim-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result i n } {
    [ i is-prime [ i result prim seq-int.push ] [ result ] if i 1 prim + n prim-loop ]
    [ result ]
    i n prim <
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ true 2 n ip-loop ] if };

: ip-loop
  (forall ρ; ρ prime:Bool^many i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { prime i n } {
    [ n i prim mod 0 prim = [ false ] [ i 1 prim + n ip-loop ] if ]
    [ prime ]
    i i prim * n prim <
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 prim seq-int.empty [ ] dip 0 k hist-init xs hist-count };

: hist-init
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k } {
    [ counts 0 prim seq-int.push i 1 prim + k hist-init ]
    [ counts ]
    i k prim <
    if
  };

: hist-count
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts i xs } {
    [ xs i prim seq-int.at counts swap [ counts swap 1 prim + prim seq-int.set ] dip i 1 prim + xs hist-count ]
    [ counts ]
    i xs prim seq-int.len prim <
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 sort-outer };

: sort-outer
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { arr i } {
    [ 0 arr i sort-inner ]
    [ arr ]
    i arr prim seq-int.len 1 prim - prim <
    if
  };

: sort-inner
  (forall ρ; ρ j:Int^many arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { j arr i } {
    [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at prim < [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at arr prim seq-int.set j prim seq-int.at arr j prim seq-int.set j 1 prim + arr i sort-inner ] [ j 1 prim + arr i sort-inner ] if ]
    [ i 1 prim + arr sort-outer ]
    j arr prim seq-int.len i prim - 1 prim - prim <
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs led-loop };

: led-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    [ txs i prim seq-int.at balance prim + 0 prim < [ balance rejected 1 prim + i 1 prim + txs led-loop ] [ txs i prim seq-int.at balance prim + i 1 prim + txs led-loop rejected ] if ]
    [ balance rejected ]
    i txs prim seq-int.len prim <
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 stock items qtys whole alloc-loop };

: alloc-loop
  (forall ρ; ρ st:Seq Int^many alloc:Seq Int^many i:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ st-final:Seq Int^many alloc-final:Seq Int^many reasons:Seq Int^many)
  locals { st alloc i stock items qtys whole } {
    [ items i prim seq-int.at stock prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at alloc-item alloc prim seq-int.push st prim seq-int.set i 1 prim + stock items qtys whole alloc-loop ]
    [ st alloc prim seq-int.empty ]
    i qtys prim seq-int.len prim <
    if
  };

: alloc-item
  (forall ρ; ρ item:Int^many r:Int^many qty:Int^many whl:Bool^many -- ρ allocated:Int^many reason:Int^many)
  locals { item r qty whl } {
    [ qty r prim < [ whl [ 0 3 ] [ r 1 ] if ] [ qty 0 ] if ]
    [ r 0 prim = [ 0 2 ] [ qty r prim < [ 0 0 ] [ r prim < [ r 1 ] [ qty 0 ] if ] if ] if ]
    qty r prim <
    if
  };
```
