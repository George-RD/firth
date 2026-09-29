### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sum:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc idx len xs } {
    [ acc ]
    [ xs idx prim seq-int.at acc prim + locals { new_acc } { new_acc idx 1 prim + len xs sum-loop } ]
    idx len prim < if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ max:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs prim seq-int.len max-loop };

: max-loop
  (forall ρ; ρ cur-max:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { cur-max idx len xs } {
    [ cur-max ]
    [ xs idx prim seq-int.at locals { v } { [ cur-max ] [ v ] v cur-max prim < if locals { new-max } { new-max idx 1 prim + len xs max-loop } } ]
    idx len prim < if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs prim seq-int.len count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc idx len xs k } {
    [ acc ]
    [ xs idx prim seq-int.at locals { v } { [ acc 1 prim + ] [ acc ] v k prim < if locals { new-acc } { new-acc idx 1 prim + len xs k count-loop } } ]
    idx len prim < if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ idx:Int^many)
  locals { xs x } { 0 xs prim seq-int.len find-idx };

: find-idx
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx len xs x } {
    [ -1 ]
    [ xs idx prim seq-int.at locals { v } { [ idx ] [ idx 1 prim + len xs x find-idx ] v x prim = if } ]
    idx len prim < if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ rev:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc idx xs } {
    [ acc ]
    [ xs idx prim seq-int.at acc prim seq-int.push locals { new-acc } { new-acc idx 1 prim - xs reverse-loop } ]
    idx 0 prim < if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop };

: prefix-loop
  (forall ρ; ρ acc:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc sum idx len xs } {
    [ acc ]
    [ xs idx prim seq-int.at sum prim + locals { new-sum } { acc new-sum prim seq-int.push new-sum idx 1 prim + len xs prefix-loop } ]
    idx len prim < if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len keep-loop };

: keep-loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc idx len xs } {
    [ acc ]
    [ xs idx prim seq-int.at locals { v } { [ acc v prim seq-int.push ] [ acc ] v 0 prim < if locals { new-acc } { new-acc idx 1 prim + len xs keep-loop } } ]
    idx len prim < if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    [ true ]
    [ 0 xs prim seq-int.len 1 prim - check-sorted-loop ]
    xs prim seq-int.len 1 prim <= if
  };

: check-sorted-loop
  (forall ρ; ρ idx:Int^many end-idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { idx end-idx xs } {
    [ true ]
    [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at locals { a b } { [ false ] [ idx 1 prim + end-idx xs check-sorted-loop ] a b prim < if } ]
    idx end-idx prim < if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs prim seq-int.len dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc idx len xs ys } {
    [ acc ]
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim + locals { new-acc } { new-acc idx 1 prim + len xs ys dot-loop } ]
    idx len prim < if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 flags prim seq-bool.len alltrue-loop };

: alltrue-loop
  (forall ρ; ρ acc:Bool^many idx:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { acc idx len flags } {
    [ acc ]
    [ flags idx prim seq-bool.at acc prim and locals { new-acc } { new-acc idx 1 prim + len flags alltrue-loop } ]
    idx len prim < if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    [ 0 ]
    [ xs 0 prim seq-int.at 1 1 1 longest-loop ]
    xs prim seq-int.len 1 prim > if
  };

: longest-loop
  (forall ρ; ρ max-len:Int^many prev-val:Int^many cur-len:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-len prev-val cur-len idx xs } {
    [ [ cur-len ] [ max-len ] cur-len max-len prim < if ]
    [ xs idx prim seq-int.at locals { v } { [ max-len prev-val 1 prim + idx 1 prim + xs longest-loop ] [ [ cur-len ] [ max-len ] cur-len max-len prim < if 1 idx 1 prim + xs longest-loop ] v prev-val prim = if } ]
    idx xs prim seq-int.len prim < if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 0 pair-sum-outer };

: pair-sum-outer
  (forall ρ; ρ found:Bool^many i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i j xs target } {
    [ found ]
    [ j 0 pair-sum-inner ]
    i xs prim seq-int.len 1 prim - prim < if
  };

: pair-sum-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    [ i 1 prim + xs prim seq-int.len pair-sum-outer ]
    [ xs i prim seq-int.at xs j prim seq-int.at prim + locals { sum } { [ true ] [ j 1 prim + i xs target pair-sum-inner ] sum target prim = if } ]
    j xs prim seq-int.len prim < if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len distinct-loop };

: distinct-loop
  (forall ρ; ρ seen:Seq Int^many count:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen count idx len xs } {
    [ [ count ] [ count 1 prim + ] 0 xs idx prim seq-int.at contains-check ]
    [ xs idx prim seq-int.at seen prim seq-int.push locals { new-seen } { new-seen count 1 prim + idx 1 prim + len xs distinct-loop } ]
    if
  };

: contains-check
  (forall ρ; ρ i:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { i val seen } {
    [ false ]
    [ seen i prim seq-int.at val prim = [ true ] [ i 1 prim + val seen contains-check ] if ]
    i seen prim seq-int.len prim < if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many lenx:Int^many leny:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j lenx leny xs ys } {
    [ result i lenx prim + j leny prim + [ xs merge-x-tail ] ]
    [ [ [ result xs i prim seq-int.at prim seq-int.push ] [ result ys j prim seq-int.at prim seq-int.push ] xs i prim seq-int.at ys j prim seq-int.at prim < if locals { r2 } { r2 i 1 prim + j lenx leny xs ys merge-loop } ] [ result j leny prim + [ ys merge-y-tail ] ] i lenx prim = if ]
    i lenx prim < j leny prim < prim and if
  };

: merge-x-tail
  (forall ρ; ρ sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ merged:Seq Int^many)
  locals { sum result xs } {
    [ result ] [ xs sum prim seq-int.at result prim seq-int.push sum 1 prim + [ xs merge-x-tail ] ] sum xs prim seq-int.len prim < if
  };

: merge-y-tail
  (forall ρ; ρ sum:Int^many result:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { sum result ys } {
    [ result ] [ ys sum prim seq-int.at result prim seq-int.push sum 1 prim + [ ys merge-y-tail ] ] sum ys prim seq-int.len prim < if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    [ prim seq-int.empty ]
    [ prim seq-int.empty n digits-extract ]
    n 0 prim = if
  };

: digits-extract
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    [ result prim seq-int.len 1 prim - [ result digits-reverse ] ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div [ digits-extract ] ]
    n 0 prim > if
  };

: digits-reverse
  (forall ρ; ρ idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx result } {
    [ prim seq-int.empty idx [ result reverse-one ] ]
  };

: reverse-one
  (forall ρ; ρ idx:Int^many acc:Seq Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx acc result } {
    [ acc ] [ result idx prim seq-int.at acc prim seq-int.push idx 1 prim - [ result reverse-one ] ] idx 0 prim < if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    [ prim seq-int.empty ]
    [ prim seq-int.empty 2 n sieve-candidate ]
    n 2 prim < if
  };

: sieve-candidate
  (forall ρ; ρ primes:Seq Int^many current:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { primes current n } {
    [ primes current prim seq-int.push current 1 prim + n sieve-candidate ]
    [ primes ]
    current n prim < if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k init-counts
  };

: init-counts
  (forall ρ; ρ acc:Seq Int^many i:Int^many k:Int^many -- ρ initialized:Seq Int^many)
  locals { acc i k } {
    [ acc 0 xs prim seq-int.len count-items ]
    [ acc 0 prim seq-int.push i 1 prim + k init-counts ]
    i k prim < if
  };

: count-items
  (forall ρ; ρ counts:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts idx len xs } {
    [ counts ] [ idx xs prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + counts v prim seq-int.set idx 1 prim + len xs count-items } ] idx len prim < if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 1 xs prim seq-int.len insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { xs i n } {
    [ xs ] [ xs i insert-element ] i n prim < if
  };

: insert-element
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    [ xs ] [ xs i 1 prim - locals { j } { xs i prim seq-int.at xs j prim seq-int.at locals { key prev } { [ xs j key prim seq-int.set i prev prim seq-int.set j [ xs insert-element ] ] [ xs ] key prev prim < if } } ]
    i 0 prim > if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs prim seq-int.len apply-txs };

: apply-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected idx len txs } {
    [ balance rejected ]
    [ txs idx prim seq-int.at locals { tx } { [ balance tx prim + rejected idx 1 prim + len txs apply-txs ] [ balance rejected 1 prim + idx 1 prim + len txs apply-txs ] balance tx prim + 0 prim < if } ]
    idx len prim < if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len allocate-order;

: allocate-order
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many end-idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons idx end-idx items qtys whole } {
    [ stock allocated reasons ]
    [ items idx prim seq-int.at locals { item } { qtys idx prim seq-int.at stock item prim seq-int.at locals { qty cur-stock } { [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item cur-stock qty prim - prim seq-int.set ] [ [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] [ [ allocated cur-stock prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set ] [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] whole idx prim seq-bool.at if ] cur-stock 0 prim = if ] qty cur-stock prim < if locals { new-stock new-allocated new-reasons } { new-stock new-allocated new-reasons idx 1 prim + end-idx items qtys whole allocate-order } } } ]
    idx end-idx prim < if
  };
```
