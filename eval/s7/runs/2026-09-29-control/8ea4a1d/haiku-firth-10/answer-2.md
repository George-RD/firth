### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 sum-helper xs };

: sum-helper
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ total:Int^many)
  locals { acc i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at prim + locals { v } { v i 1 prim + sum-helper } ] [ acc ] if };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 max-helper xs };

: max-helper
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { v max prim < [ v ] [ max ] if i 1 prim + max-helper } ] [ max ] if };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs k count-helper };

: count-helper
  (forall ρ; ρ cnt:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { cnt i xs k } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { x } { x k prim < [ cnt 1 prim + ] [ cnt ] if i 1 prim + xs k count-helper } ] [ cnt ] if };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x index-helper };

: index-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { i xs x } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { v x prim = [ i ] [ i 1 prim + xs x index-helper ] if } ] [ -1 ] if };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len reverse-helper xs };

: reverse-helper
  (forall ρ; ρ acc:Seq Int^many len:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { acc len xs } { len 0 prim < [ acc ] [ len 1 prim - locals { i } { xs i prim seq-int.at prim seq-int.push acc i reverse-helper } ] if };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-helper };

: prefix-helper
  (forall ρ; ρ acc:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { acc sum i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { sum v prim + acc prim seq-int.push i 1 prim + sum v prim + xs prefix-helper } ] [ acc ] if };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-helper };

: keep-helper
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { acc i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { v 0 prim < [ acc ] [ acc v prim seq-int.push ] if i 1 prim + xs keep-helper } ] [ acc ] if };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 1 prim < [ 1 ] [ 1 1 xs len is-sorted-helper ] if } };

: is-sorted-helper
  (forall ρ; ρ ok:Bool^many i:Int^many xs:Seq Int^many len:Int^many -- ρ sorted:Bool^many)
  locals { ok i xs len } { ok prim not [ 0 ] [ i len prim < [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim < prim not [ i 1 prim + xs len is-sorted-helper ] [ 0 ] if ] [ 1 ] if ] if };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-helper };

: dot-helper
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { acc i xs ys } { i xs prim seq-int.len prim < [ xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + i 1 prim + xs ys dot-helper ] [ acc ] if };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 1 0 flags all-helper };

: all-helper
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result i flags } { result prim not [ 0 ] [ i flags prim seq-int.len prim < [ flags i prim seq-int.at result prim and i 1 prim + flags all-helper ] [ result ] if ] if };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim = [ 0 ] [ 0 1 1 0 xs len longest-helper ] if } };

: longest-helper
  (forall ρ; ρ maxrun:Int^many currun:Int^many i:Int^many lastval:Int^many xs:Seq Int^many len:Int^many -- ρ length:Int^many)
  locals { maxrun currun i lastval xs len } { i len prim < [ xs i prim seq-int.at locals { v } { v lastval prim = [ currun 1 prim + maxrun prim < [ v i 1 prim + xs len longest-helper ] [ maxrun currun i 1 prim + v xs len longest-helper ] if ] [ maxrun currun prim < [ currun v i 1 prim + xs len longest-helper ] [ maxrun 1 i 1 prim + v xs len longest-helper ] if ] if } ] [ maxrun currun prim < [ currun ] [ maxrun ] if ] if };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target has-pair-helper };

: has-pair-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } { i xs prim seq-int.len prim < [ xs i prim seq-int.at target prim - locals { needed } { i 1 prim + xs needed has-pair-inner } ] [ 0 ] if };

: has-pair-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many needed:Int^many -- ρ found:Bool^many)
  locals { j xs needed } { j xs prim seq-int.len prim < [ xs j prim seq-int.at locals { y } { y needed prim = [ 1 ] [ j 1 prim + xs needed has-pair-inner ] if } ] [ 0 ] if };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 xs count-distinct-helper };

: count-distinct-helper
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { 0 seen v is-in [ seen i 1 prim + xs count-distinct-helper ] [ seen v prim seq-int.push i 1 prim + xs count-distinct-helper ] if } ] [ seen prim seq-int.len ] if };

: is-in
  (forall ρ; ρ idx:Int^many seq:Seq Int^many val:Int^many -- ρ found:Bool^many)
  locals { idx seq val } { idx seq prim seq-int.len prim < [ seq idx prim seq-int.at val prim = [ 1 ] [ idx 1 prim + seq val is-in ] if ] [ 0 ] if };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys xs prim seq-int.len ys prim seq-int.len merge-helper };

: merge-helper
  (forall ρ; ρ acc:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many xlen:Int^many ylen:Int^many -- ρ merged:Seq Int^many)
  locals { acc i j xs ys xlen ylen } { i xlen prim < [ j ylen prim < [ xs i prim seq-int.at ys j prim seq-int.at prim < [ acc xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys xlen ylen merge-helper ] [ acc ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys xlen ylen merge-helper ] if ] [ acc xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys xlen ylen merge-helper ] if ] [ j ylen prim < [ acc ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys xlen ylen merge-helper ] [ acc ] if ] if };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ { } n digits-helper ] if };

: digits-helper
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { acc n } { n 0 prim < prim not [ n 10 prim mod acc prim seq-int.push n 10 prim div digits-helper ] [ acc ] if };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-helper };

: primes-helper
  (forall ρ; ρ acc:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { acc i n } { i n prim < [ i 2 is-prime [ acc i prim seq-int.push ] [ acc ] if i 1 prim + n primes-helper ] [ acc ] if };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ isprime:Bool^many)
  locals { num } { num 2 is-prime-test };

: is-prime-test
  (forall ρ; ρ num:Int^many div:Int^many -- ρ isprime:Bool^many)
  locals { num div } { div div prim * num prim < [ 1 ] [ num div prim mod 0 prim = [ 0 ] [ num div 1 prim + is-prime-test ] if ] if };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { k prim seq-int.empty 0 xs k hist-init };

: hist-init
  (forall ρ; ρ counts:Seq Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts idx xs k } { idx k prim < [ counts 0 prim seq-int.push idx 1 prim + xs k hist-init ] [ counts 0 xs hist-loop ] if };

: hist-loop
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts i xs } { i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + counts v prim seq-int.set i 1 prim + xs hist-loop } ] [ counts ] if };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 0 sort-outer };

: sort-outer
  (forall ρ; ρ arr:Seq Int^many len:Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { arr len i } { i len 1 prim - prim < [ arr i 1 prim + len sort-inner ] [ arr ] if };

: sort-inner
  (forall ρ; ρ arr:Seq Int^many j:Int^many len:Int^many -- ρ sorted:Seq Int^many)
  locals { arr j len } { j len prim < [ arr j 1 prim - prim seq-int.at arr j prim seq-int.at prim < [ arr j arr j 1 prim - prim seq-int.at prim seq-int.set arr j 1 prim - arr j prim seq-int.at prim seq-int.set ] [ arr ] if j 1 prim + len sort-inner ] [ arr ] if };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs ledger-helper };

: ledger-helper
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } { i txs prim seq-int.len prim < [ txs i prim seq-int.at balance prim + locals { newbal } { newbal 0 prim < [ balance rejected 1 prim + i 1 prim + txs ledger-helper ] [ newbal rejected i 1 prim + txs ledger-helper ] if } ] [ balance rejected ] if };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock { } { } 0 stock items qtys whole stock prim seq-int.len alloc-helper };

: alloc-helper
  (forall ρ; ρ cur-stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many n:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { cur-stock allocated reasons j stock items qtys whole n } { j n prim < [ items j prim seq-int.at cur-stock prim seq-int.at qtys j prim seq-int.at locals { item-idx } { locals { cur-val } { locals { qty } { cur-val qty prim < [ cur-val 0 prim = [ cur-stock allocated reasons 2 prim seq-int.push ] [ whole j prim seq-int.at [ cur-stock allocated reasons 3 prim seq-int.push ] [ cur-stock item-idx cur-val prim seq-int.set allocated cur-val prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] [ cur-stock item-idx qty prim - prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push ] if } } } j 1 prim + stock items qtys whole n alloc-helper ] [ cur-stock allocated reasons ] if };
```
