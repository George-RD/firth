### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { 0 0 len xs loop-sum } };

: loop-sum
  (forall ρ; ρ acc:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc i len xs } { i len prim < [ xs i prim seq-int.at locals { val } { acc val prim + locals { new-acc } { new-acc i 1 prim + len xs loop-sum } } ] [ acc ] if };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { xs 0 prim seq-int.at locals { first } { first 1 len xs loop-max } } };

: loop-max
  (forall ρ; ρ max:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i len xs } { i len prim < [ xs i prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if locals { new-max } { new-max i 1 prim + len xs loop-max } } ] [ max ] if };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs loop-keep-pos };

: loop-keep-pos
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { 0 val prim < [ result val prim seq-int.push ] [ result ] if locals { new-result } { new-result i 1 prim + xs loop-keep-pos } } ] [ result ] if };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target loop-pair-i };

: loop-pair-i
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } { i xs prim seq-int.len prim < [ i 1 prim + 0 xs target loop-pair-j ] [ false ] if };

: loop-pair-j
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } { j xs prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { xs j prim seq-int.at locals { y } { x y prim + target prim = [ true ] [ j 1 prim + i xs target loop-pair-j ] if } } ] [ i xs target loop-pair-i ] if };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs loop-distinct };

: loop-distinct
  (forall ρ; ρ seen:Seq Int^many count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen count i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { val } { 0 val seen count i xs loop-find-in-seen } ] [ count ] if };

: loop-find-in-seen
  (forall ρ; ρ j:Int^many val:Int^many seen:Seq Int^many count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { j val seen count i xs } { j seen prim seq-int.len prim < [ seen j prim seq-int.at locals { s } { s val prim = [ i 1 prim + count 1 prim + seen val prim seq-int.push xs loop-distinct ] [ j 1 prim + val seen count i xs loop-find-in-seen ] if } ] [ i 1 prim + count seen xs loop-distinct ] if };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n loop-digits ] if };

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
  locals { i n } { i i prim * n prim < [ n i prim mod 0 prim = [ false ] [ i 1 prim + n loop-check-prime ] if ] [ i i prim * n prim = [ n i prim mod 0 prim = [ false ] [ true ] if ] [ true ] if ] if };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k xs loop-init-hist };

: loop-init-hist
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many xs:Seq Int^many -- ρ next:Seq Int^many)
  locals { result i k xs } { i k prim < [ result 0 prim seq-int.push locals { new-result } { new-result i 1 prim + k xs loop-init-hist } ] [ result xs 0 loop-count-hist ] if };

: loop-count-hist
  (forall ρ; ρ result:Seq Int^many j:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result j xs } { j xs prim seq-int.len prim < [ xs j prim seq-int.at locals { val } { result val prim seq-int.at locals { count } { result val count 1 prim + prim seq-int.set locals { new-result } { new-result j 1 prim + xs loop-count-hist } } } ] [ result ] if };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len loop-sort-outer };

: loop-sort-outer
  (forall ρ; ρ arr:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { arr n } { n 1 prim - locals { i } { i 0 prim < [ arr ] [ arr i loop-sort-inner n ] if } };

: loop-sort-inner
  (forall ρ; ρ arr:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { arr i n } { i 0 prim < [ arr ] [ arr i prim seq-int.at locals { val } { arr i 1 prim - prim seq-int.at locals { prev } { val prev prim < [ arr i val prim seq-int.set locals { new-arr } { new-arr i 1 prim - n loop-sort-inner } ] [ arr ] if } } ] if };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 stock items qtys whole loop-alloc };

: loop-alloc
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons order items qtys whole } { order items prim seq-int.len prim < [ items order prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys order prim seq-int.at locals { q } { whole order prim seq-bool.at locals { w } { q r prim < [ stock allocated 0 prim seq-int.push reasons 0 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ r 0 prim = [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] [ stock item r prim seq-int.set allocated r prim seq-int.push reasons 1 prim seq-int.push order 1 prim + items qtys whole loop-alloc ] if ] if ] if } } } ] [ stock allocated reasons ] if };
```
