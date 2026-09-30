### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { 0 0 loop-sum } };

: loop-sum
  (forall ρ; ρ acc:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs len i acc } { i len prim < [ xs i prim seq-int.at locals { val } { acc val prim + locals { new-acc } { new-acc i 1 prim + len xs loop-sum } } ] [ acc ] if };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at locals { first } { first 1 loop-max first } };

: loop-max
  (forall ρ; ρ max:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs len i max } { i len prim < [ xs i prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if locals { new-max } { new-max i 1 prim + len xs loop-max } } ] [ max ] if };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } { xs prim seq-int.len locals { len } { 0 0 loop-count-below } };

: loop-count-below
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { k xs len i count } { i len prim < [ xs i prim seq-int.at locals { val } { val k prim < [ count 1 prim + ] [ count ] if locals { new-count } { new-count i 1 prim + len xs k loop-count-below } } ] [ count ] if };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } { xs prim seq-int.len locals { len } { 0 loop-index-of } };

: loop-index-of
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { x xs len i } { i len prim < [ xs i prim seq-int.at locals { val } { val x prim = [ i ] [ i 1 prim + len xs x loop-index-of ] if } ] [ -1 ] if };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - loop-reverse };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } { i 0 prim < [ ] [ xs i prim seq-int.at locals { val } { result val prim seq-int.push locals { new-result } { new-result i 1 prim - xs loop-reverse } } ] if };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 loop-prefix };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many acc:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i acc result } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { acc val prim + locals { new-acc } { result new-acc prim seq-int.push locals { new-result } { new-result new-acc i 1 prim + xs loop-prefix } } } ] [ result ] if };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 loop-keep-pos };

: loop-keep-pos
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { val 0 prim < [ result ] [ result val prim seq-int.push ] if locals { new-result } { new-result i 1 prim + xs loop-keep-pos } } ] [ result ] if };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 1 prim < [ true ] [ 0 loop-is-sorted true ] if } };

: loop-is-sorted
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs len i } { i 1 prim - locals { prev-i } { prev-i xs prim seq-int.len 1 prim - prim < [ xs prev-i prim seq-int.at locals { prev } { xs i prim seq-int.at locals { curr } { prev curr prim < [ false ] [ i 1 prim + len xs loop-is-sorted ] if } } } [ true ] if } };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs } { 0 0 loop-dot };

: loop-dot
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { ys xs i acc } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { ys i prim seq-int.at locals { y } { x y prim * locals { prod } { acc prod prim + locals { new-acc } { new-acc i 1 prim + xs ys loop-dot } } } } ] [ acc ] if };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-bool.len 0 loop-all-true true };

: loop-all-true
  (forall ρ; ρ result:Bool^many i:Int^many len:Int^many flags:Seq Bool^many -- ρ final:Bool^many)
  locals { flags len i result } { i len prim < [ flags i prim seq-bool.at locals { flag } { result flag prim and locals { new-result } { new-result i 1 prim + len flags loop-all-true } } ] [ result ] if };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim < [ 0 ] [ 1 1 1 loop-longest ] if };

: loop-longest
  (forall ρ; ρ max-len:Int^many curr-len:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i curr-len max-len } { i xs prim seq-int.len prim < [ xs i 1 prim - prim seq-int.at locals { prev } { xs i prim seq-int.at locals { curr } { prev curr prim = [ curr-len 1 prim + ] [ curr-len ] if locals { new-len } { max-len new-len prim < [ new-len ] [ max-len ] if locals { new-max } { new-max new-len i 1 prim + xs loop-longest } } } } ] [ max-len ] if };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } { 0 false loop-pair };

: loop-pair
  (forall ρ; ρ i:Int^many found:Bool^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs found i } { found [ i xs prim seq-int.len loop-pair-inner false ] [ i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { i 1 prim + loop-pair-inner-j false } ] [ false ] if ] if };

: loop-pair-inner-j
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs i j } { j xs prim seq-int.len prim < [ xs j prim seq-int.at locals { y } { xs i prim seq-int.at locals { x } { x y prim + target prim = [ true ] [ j 1 prim + i xs target loop-pair-inner-j ] if } } } [ false ] if };

: loop-pair-inner
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs len i } { i len prim < [ i 1 prim + loop-pair-inner xs target ] [ false ] if };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 0 loop-distinct };

: loop-distinct
  (forall ρ; ρ seen:Seq Int^many count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i count seen } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { 0 loop-find-in-seen false val seen } ] [ count ] if };

: loop-find-in-seen
  (forall ρ; ρ found:Bool^many j:Int^many val:Int^many seen:Seq Int^many i:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs count i seen val found j } { found [ i 1 prim + count xs loop-distinct ] [ j seen prim seq-int.len prim < [ seen j prim seq-int.at locals { s } { s val prim = [ i 1 prim + count 1 prim + seen val prim seq-int.push xs loop-distinct ] [ j 1 prim + val seen loop-find-in-seen ] if } ] [ i 1 prim + count xs loop-distinct ] if ] if };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } { prim seq-int.empty 0 0 loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { ys xs j i result } { i xs prim seq-int.len prim < [ j ys prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { ys j prim seq-int.at locals { y } { x y prim < [ result x prim seq-int.push locals { new-result } { new-result i 1 prim + j xs ys loop-merge } ] [ result y prim seq-int.push locals { new-result } { new-result i j 1 prim + xs ys loop-merge } ] if } } ] [ result xs i prim seq-int.at prim seq-int.push locals { new-result } { new-result i 1 prim + j xs ys loop-merge } ] if ] [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push locals { new-result } { new-result i j 1 prim + xs ys loop-merge } ] [ result ] if ] if };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim < [ 0 ] [ n ] if locals { abs-n } { abs-n 0 prim = [ 0 prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty abs-n loop-digits ] if } };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { n result } { n 10 prim mod locals { digit } { result digit prim seq-int.push locals { new-result } { n 10 prim div locals { new-n } { new-n 0 prim = [ new-result ] [ new-result new-n loop-digits ] if } } } };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { n i result } { i n prim < [ i is-prime [ result i prim seq-int.push ] [ result ] if locals { new-result } { new-result i 1 prim + n loop-primes } ] [ result ] if };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ 2 loop-check-prime ] if };

: loop-check-prime
  (forall ρ; ρ i:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { n i } { i i prim * n prim < [ n i prim mod 0 prim = [ false ] [ i 1 prim + n loop-check-prime ] if ] [ true ] if };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } { 0 loop-build-hist prim seq-int.empty };

: loop-build-hist
  (forall ρ; ρ i:Int^many k:Int^many xs:Seq Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { result xs k i } { i k prim < [ 0 result i 0 prim seq-int.push locals { new-result } { new-result i 1 prim + k xs loop-build-hist } ] [ result ] if };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len loop-sort };

: loop-sort
  (forall ρ; ρ arr:Seq Int^many start:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { len start arr } { start 1 prim - loop-sort-inner len arr };

: loop-sort-inner
  (forall ρ; ρ i:Int^many len:Int^many arr:Seq Int^many -- ρ result:Seq Int^many)
  locals { arr len i } { i 0 prim < [ arr ] [ arr i prim seq-int.at locals { val } { arr i 1 prim - prim seq-int.at locals { prev } { val prev prim < [ arr i prev prim seq-int.set locals { new-arr } { new-arr i 1 prim - val loop-sort-inner } ] [ arr ] if } } ] if };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } { start 0 0 loop-ledger };

: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { txs start i rejected balance } { i txs prim seq-int.len prim < [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { new-bal } { new-bal 0 prim < [ balance rejected 1 prim + i 1 prim + start txs loop-ledger ] [ new-bal rejected i 1 prim + start txs loop-ledger ] if } } ] [ balance rejected ] if };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } { stock prim seq-int.empty prim seq-int.empty 0 loop-alloc };

: loop-alloc
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { whole qtys items order reasons allocated stock } { order items prim seq-int.len prim < [ items order prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys order prim seq-int.at locals { q } { whole order prim seq-bool.at locals { w } { q r prim < [ stock allocated 0 prim seq-int.push reasons 0 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ r 0 prim = [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ stock item r prim seq-int.set locals { new-stock } { new-stock allocated r prim seq-int.push reasons 1 prim seq-int.push order 1 prim + items qtys whole loop-alloc } ] if ] if ] if } } } ] [ stock allocated reasons ] if };
```
