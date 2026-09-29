### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { 0 0 xs len loop-sum } };

: loop-sum
  (forall ρ; ρ acc:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc i len xs } { i len prim < [ xs i prim seq-int.at locals { val } { acc val prim + locals { new-acc } { new-acc i 1 prim + len xs loop-sum } } ] [ acc ] if };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at locals { first } { first 1 xs prim seq-int.len loop-max } };

: loop-max
  (forall ρ; ρ max:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i len xs } { i len prim < [ xs i prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if locals { new-max } { new-max i 1 prim + len xs loop-max } } ] [ max ] if };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs prim seq-int.len locals { len } { 0 0 len xs k loop-count-below } };

: loop-count-below
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i len xs k } { i len prim < [ xs i prim seq-int.at locals { val } { val k prim < [ count 1 prim + ] [ count ] if locals { new-count } { new-count i 1 prim + len xs k loop-count-below } } ] [ count ] if };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs prim seq-int.len locals { len } { 0 len xs x loop-index-of } };

: loop-index-of
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i len xs x } { i len prim < [ xs i prim seq-int.at locals { val } { val x prim = [ i ] [ i 1 prim + len xs x loop-index-of ] if } ] [ -1 ] if };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - xs loop-reverse };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } { i 0 prim < [ result ] [ xs i prim seq-int.at locals { val } { result val prim seq-int.push locals { new-result } { new-result i 1 prim - xs loop-reverse } } ] if };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs loop-prefix };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many acc:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result acc i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { acc val prim + locals { new-acc } { result new-acc prim seq-int.push locals { new-result } { new-result new-acc i 1 prim + xs loop-prefix } } } ] [ result ] if };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs loop-keep-pos };

: loop-keep-pos
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { val 0 prim < [ result ] [ result val prim seq-int.push ] if locals { new-result } { new-result i 1 prim + xs loop-keep-pos } } ] [ result ] if };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 1 prim < [ true ] [ 0 len xs loop-is-sorted ] if } };

: loop-is-sorted
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i len xs } { i 1 prim - locals { prev-i } { prev-i 0 prim < [ true ] [ xs prev-i prim seq-int.at locals { prev } { xs i prim seq-int.at locals { curr } { prev curr prim < [ false ] [ i 1 prim + len xs loop-is-sorted ] if } } ] if } };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys loop-dot };

: loop-dot
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs ys } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { ys i prim seq-int.at locals { y } { x y prim * locals { prod } { acc prod prim + locals { new-acc } { new-acc i 1 prim + xs ys loop-dot } } } } ] [ acc ] if };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-bool.len locals { len } { true 0 len flags loop-all-true } };

: loop-all-true
  (forall ρ; ρ result:Bool^many i:Int^many len:Int^many flags:Seq Bool^many -- ρ final:Bool^many)
  locals { result i len flags } { i len prim < [ flags i prim seq-bool.at locals { flag } { result flag prim and locals { new-result } { new-result i 1 prim + len flags loop-all-true } } ] [ result ] if };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim < [ 0 ] [ 1 1 1 xs loop-longest ] if } };

: loop-longest
  (forall ρ; ρ max-len:Int^many curr-len:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-len curr-len i xs } { i xs prim seq-int.len prim < [ xs i 1 prim - prim seq-int.at locals { prev } { xs i prim seq-int.at locals { curr } { prev curr prim = [ curr-len 1 prim + ] [ 1 ] if locals { new-len } { max-len new-len prim < [ new-len ] [ max-len ] if locals { new-max } { new-max new-len i 1 prim + xs loop-longest } } } } ] [ max-len ] if };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target loop-pair-outer };

: loop-pair-outer
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } { i xs prim seq-int.len prim < [ i 1 prim + loop-pair-inner-j xs target ] [ false ] if };

: loop-pair-inner-j
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } { j xs prim seq-int.len prim < [ xs j prim seq-int.at locals { y } { xs i 1 prim - prim seq-int.at locals { x } { x y prim + target prim = [ true ] [ j 1 prim + i xs target loop-pair-inner-j ] if } } ] [ i 1 prim + xs target loop-pair-outer ] if };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs loop-distinct };

: loop-distinct
  (forall ρ; ρ seen:Seq Int^many count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen count i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { 0 val seen loop-find-in-seen } ] [ count ] if };

: loop-find-in-seen
  (forall ρ; ρ j:Int^many val:Int^many seen:Seq Int^many i:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { j val seen i count xs } { j seen prim seq-int.len prim < [ seen j prim seq-int.at locals { s } { s val prim = [ i 1 prim + count 1 prim + seen val prim seq-int.push xs loop-distinct ] [ j 1 prim + val seen i count xs loop-find-in-seen ] if } ] [ i 1 prim + count xs loop-distinct ] if };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } { i xs prim seq-int.len prim < [ j ys prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { ys j prim seq-int.at locals { y } { x y prim < [ result x prim seq-int.push locals { new-result } { new-result i 1 prim + j xs ys loop-merge } ] [ result y prim seq-int.push locals { new-result } { new-result i j 1 prim + xs ys loop-merge } ] if } } ] [ result xs i prim seq-int.at prim seq-int.push locals { new-result } { new-result i 1 prim + j xs ys loop-merge } ] if ] [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push locals { new-result } { new-result i j 1 prim + xs ys loop-merge } ] [ result ] if ] if };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ 0 prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n loop-digits ] if };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } { n 10 prim mod locals { digit } { result digit prim seq-int.push locals { new-result } { n 10 prim div locals { new-n } { new-n 0 prim = [ new-result ] [ new-result new-n loop-digits ] if } } } };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result i n } { i n prim < [ i is-prime [ result i prim seq-int.push ] [ result ] if locals { new-result } { new-result i 1 prim + n loop-primes } ] [ result ] if };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ 2 n loop-check-prime ] if };

: loop-check-prime
  (forall ρ; ρ i:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { i n } { i i prim * n prim < [ n i prim mod 0 prim = [ false ] [ i 1 prim + n loop-check-prime ] if ] [ true ] if };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 k xs loop-build-hist };

: loop-build-hist
  (forall ρ; ρ i:Int^many k:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k xs } { i k prim < [ prim seq-int.empty 0 xs i loop-count-val ] [ prim seq-int.empty ] if };

: loop-count-val
  (forall ρ; ρ result:Seq Int^many count:Int^many xs:Seq Int^many v:Int^many -- ρ final:Seq Int^many)
  locals { result count xs v } { count xs prim seq-int.len prim < [ xs count prim seq-int.at locals { x } { x v prim = [ result 1 prim seq-int.push ] [ result ] if locals { new-result } { new-result count 1 prim + xs v loop-count-val } } ] [ result ] if };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len loop-sort };

: loop-sort
  (forall ρ; ρ arr:Seq Int^many start:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { arr start len } { start 1 prim - start len arr loop-sort-inner };

: loop-sort-inner
  (forall ρ; ρ i:Int^many start:Int^many len:Int^many arr:Seq Int^many -- ρ result:Seq Int^many)
  locals { i start len arr } { i 0 prim < [ arr ] [ arr i prim seq-int.at locals { val } { arr i 1 prim - prim seq-int.at locals { prev } { val prev prim < [ arr i val prim seq-int.set locals { new-arr } { new-arr i 1 prim - start len new-arr loop-sort-inner } ] [ arr ] if } } ] if };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 start txs loop-ledger };

: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i start txs } { i txs prim seq-int.len prim < [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { new-bal } { new-bal 0 prim < [ balance rejected 1 prim + i 1 prim + start txs loop-ledger ] [ new-bal rejected i 1 prim + start txs loop-ledger ] if } } ] [ balance rejected ] if };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 stock items qtys whole loop-alloc };

: loop-alloc
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons order items qtys whole } { order items prim seq-int.len prim < [ items order prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys order prim seq-int.at locals { q } { whole order prim seq-bool.at locals { w } { q r prim < [ stock allocated 0 prim seq-int.push reasons 0 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ r 0 prim = [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ stock item r prim seq-int.set locals { new-stock } { new-stock allocated r prim seq-int.push reasons 1 prim seq-int.push order 1 prim + items qtys whole loop-alloc } ] if ] if ] if } } } ] [ stock allocated reasons ] if };
```
