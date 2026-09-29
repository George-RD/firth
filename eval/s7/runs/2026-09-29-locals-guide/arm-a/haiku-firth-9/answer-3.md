### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs max-loop };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at max prim < [ max i 1 prim + xs max-loop ] [ xs i prim seq-int.at i 1 prim + xs max-loop ] if ]
    [ max ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - xs rev-loop };

: rev-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i xs } {
    i 0 prim <
    [ acc ]
    [ acc xs i prim seq-int.at prim seq-int.push i 1 prim - xs rev-loop ]
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
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sum prim + result swap prim seq-int.push sum i 1 prim + xs ps-loop result swap drop ]
    [ result ]
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
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at 0 prim < [ acc i 1 prim + xs kp-loop ] [ acc xs i prim seq-int.at prim seq-int.push i 1 prim + xs kp-loop ] if ]
    [ acc ]
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
    i xs prim seq-int.len 1 prim - prim <
    [ ok [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ ok i 1 prim + xs is-sort-loop ] [ i 1 prim + xs is-sort-loop false ] if ] [ i 1 prim + xs is-sort-loop ] if ]
    [ ok ]
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
    ok [ i flags prim seq-bool.len prim < [ flags i prim seq-bool.at [ i 1 prim + flags at-loop ] [ false ] if ] [ true ] if ] [ false ] if
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
    i xs prim seq-int.len prim <
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [ curlen 1 prim + maxlen prim < [ i 1 prim + xs lr-loop curlen 1 prim + maxlen ] [ i 1 prim + xs lr-loop maxlen ] if ] [ 1 maxlen prim < [ i 1 prim + xs lr-loop 1 maxlen ] [ i 1 prim + xs lr-loop maxlen ] if ] if ]
    [ maxlen curlen prim < [ curlen ] [ maxlen ] if ]
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
    i xs prim seq-int.len prim <
    [ found [ 0 i 1 prim + xs target hps-inner ] [ false ] if ]
    [ found ]
    if
  };

: hps-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + i xs target hps-inner ] if ]
    [ false i 1 prim + xs target hps-loop ]
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
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at seen contains [ seen i 1 prim + xs cd-loop ] [ seen xs i prim seq-int.at prim seq-int.push i 1 prim + xs cd-loop ] if ]
    [ seen prim seq-int.len ]
    if
  };

: contains
  (forall ρ; ρ x:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { x seq } { false 0 x seq cont-loop };

: cont-loop
  (forall ρ; ρ found:Bool^many i:Int^many x:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { found i x seq } {
    i seq prim seq-int.len prim <
    [ seq i prim seq-int.at x prim = [ true ] [ found i 1 prim + x seq cont-loop ] if ]
    [ found ]
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
    n 0 prim =
    [ result 0 result prim seq-int.len dig-reverse ]
    [ result n 10 prim mod prim seq-int.push n 10 prim div dig-loop ]
    if
  };

: dig-reverse
  (forall ρ; ρ result:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result i } {
    i 0 prim <
    [ result ]
    [ result swap [ result swap 1 prim - prim seq-int.at ] dip prim seq-int.push i 1 prim - dig-reverse ]
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
    i n prim <
    [ i 2 prim < [ result i 1 prim + n prim-loop ] [ i is-prime [ result i prim seq-int.push i 1 prim + n prim-loop ] [ result i 1 prim + n prim-loop ] if ] if ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ true 2 n ip-loop ] if };

: ip-loop
  (forall ρ; ρ prime:Bool^many i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { prime i n } {
    i i prim * n prim <
    [ n i prim mod 0 prim = [ false ] [ i 1 prim + n ip-loop prime ] if ]
    [ prime ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 k hist-init xs hist-count };

: hist-init
  (forall ρ; ρ i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i k prim <
    [ prim seq-int.empty 0 prim seq-int.push i 1 prim + k hist-init ]
    [ prim seq-int.empty ]
    if
  };

: hist-count
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts xs } {
    counts 0 xs prim seq-int.len hc-loop
  };

: hc-loop
  (forall ρ; ρ counts:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts i len xs } {
    i len prim <
    [ counts xs i prim seq-int.at prim seq-int.at counts swap 1 prim + prim seq-int.set i 1 prim + len xs hc-loop ]
    [ counts ]
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
    i arr prim seq-int.len 1 prim - prim <
    [ 0 arr i sort-inner ]
    [ arr ]
    if
  };

: sort-inner
  (forall ρ; ρ j:Int^many arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { j arr i } {
    j arr prim seq-int.len i prim - 1 prim - prim <
    [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at prim < [ arr j prim seq-int.at arr j 1 prim + prim seq-int.at arr prim seq-int.set j prim seq-int.at arr j prim seq-int.set j 1 prim + arr i sort-inner ] [ j 1 prim + arr i sort-inner ] if ]
    [ i 1 prim + arr sort-outer ]
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
    i qtys prim seq-int.len prim <
    [ items i prim seq-int.at stock prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at alloc-item prim seq-int.empty prim seq-int.empty alloc prim seq-int.push st prim seq-int.set i 1 prim + stock items qtys whole alloc-loop prim seq-int.empty prim seq-int.empty ]
    [ st alloc prim seq-int.empty ]
    if
  };

: alloc-item
  (forall ρ; ρ item:Int^many r:Int^many qty:Int^many whl:Bool^many -- ρ allocated:Int^many reason:Int^many)
  locals { item r qty whl } {
    qty r prim <
    [ r 0 prim = [ 0 2 ] [ whl [ 0 3 ] [ r 1 ] if ] if ]
    [ qty 0 ]
    if
  };
```
