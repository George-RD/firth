### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap dup 1 prim - swap xs swap prim seq-int.at prim + swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    [ xs prim seq-int.len 1 prim - ] call
    [ dup 0 prim = [ drop ] [ dup xs swap prim seq-int.at swap 2 swap prim - [ prim > [ swap ] [ drop ] if ] dip 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap dup 1 prim - swap xs swap prim seq-int.at k prim < [ 1 prim + ] [ ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop -1 ] [ dup xs swap prim seq-int.at x prim = [ swap drop ] [ swap 1 prim + swap 1 prim - ] if ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    [ xs prim seq-int.len 1 prim - ] call
    [ dup 0 prim < [ drop ] [ swap xs swap prim seq-int.at prim seq-int.push swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap swap xs swap prim seq-int.at prim + dup swap prim seq-int.push swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop drop ] call ] call
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ dup xs swap prim seq-int.at dup 0 prim < [ drop drop ] [ prim seq-int.push ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    true
    [ xs prim seq-int.len 1 prim - ] call
    [ dup 0 prim = [ drop ] [ xs swap dup prim seq-int.at xs swap 1 prim + prim seq-int.at prim < [ drop false ] [ 1 prim - ] if ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ swap dup 1 prim - swap xs swap prim seq-int.at ys swap prim seq-int.at prim * prim + swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true
    [ flags prim seq-bool.len ] call
    [ dup 0 prim = [ drop ] [ flags swap prim seq-bool.at [ drop false ] [ ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [ 0 ] [ 1 1 1 [ xs prim seq-int.len 1 prim - ] call [ dup 0 prim = [ drop ] [ xs swap dup prim seq-int.at xs swap 1 prim + prim seq-int.at prim = [ swap 1 prim + swap dup swap [ prim > [ swap ] [ drop ] if ] dip 1 prim - ] [ swap drop 1 swap 1 prim - ] if ] if ] compose [ dup 0 prim < [ drop drop drop ] call ] call ] if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ xs swap dup prim seq-int.at target swap prim - [ xs prim seq-int.len ] call [ dup 0 prim = [ drop ] [ xs swap prim seq-int.at prim = [ drop true ] [ 1 prim - ] if ] if ] compose [ dup 0 prim < [ drop ] call ] call [ drop true ] [ 1 prim - ] if ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ xs swap prim seq-int.at dup [ dup prim seq-int.len ] call [ dup 0 prim = [ drop false ] [ dup xs swap prim seq-int.at prim = [ drop true ] [ 1 prim - ] if ] if ] compose [ dup 0 prim < [ drop ] call ] call [ prim seq-int.push ] [ drop ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
    prim seq-int.len
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0 0
    [ xs prim seq-int.len ys prim seq-int.len prim + ] call
    [ dup 0 prim = [ drop drop drop ] [ dup swap dup 0 prim = [ drop xs swap prim seq-int.at prim seq-int.push swap 1 prim + ] [ dup xs prim seq-int.len prim = [ drop ys swap prim seq-int.at prim seq-int.push 1 prim + ] [ xs swap prim seq-int.at ys swap prim seq-int.at [ prim < ] dip [ prim seq-int.push swap 1 prim + ] [ prim seq-int.push 1 prim + ] if ] if ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [ { 0 } ] [ prim seq-int.empty n [ dup 0 prim = [ drop ] [ dup 10 prim mod prim seq-int.push swap 10 prim div swap ] if ] compose [ dup 0 prim < [ drop ] call ] call [ dup prim seq-int.len 1 prim - ] call [ dup 0 prim < [ drop ] [ prim seq-int.len 1 prim - swap dup prim seq-int.at swap prim seq-int.len 1 prim - prim seq-int.at swap 0 swap prim seq-int.set dup prim seq-int.len 1 prim - prim seq-int.set 1 prim - ] if ] compose [ dup 0 prim < [ drop ] call ] call ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    2
    [ n 1 prim + ] call
    [ dup 0 prim = [ drop ] [ dup dup 1 prim - [ 1 0 swap [ dup 1 prim = [ drop ] [ dup 2 prim < [ swap drop 1 swap 1 prim - ] [ dup 2 prim * swap prim > [ swap 1 swap 1 prim - ] [ drop 0 ] if ] if ] if ] compose [ dup 0 prim < [ drop ] call ] call ] [ prim seq-int.push ] [ drop ] if swap 1 prim + ] if ] compose [ dup 0 prim < [ drop ] call ] call
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    [ k 0 ] call [ prim seq-int.empty prim seq-int.push ] compose [ dup 0 prim < [ drop ] call ] call
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ xs swap prim seq-int.at dup prim seq-int.at 1 prim + swap prim seq-int.set swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs
    [ xs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ dup 1 prim - [ 0 swap ] call [ dup 0 prim = [ drop drop ] [ dup swap dup prim seq-int.at dup 1 prim + prim seq-int.at [ prim > ] dip [ dup prim seq-int.at swap 1 prim + prim seq-int.at swap 0 swap prim seq-int.set dup 1 prim + prim seq-int.set ] [ drop ] if 1 prim + ] if ] compose [ dup 0 prim < [ drop ] call ] call 1 prim - ] if ] compose
    [ dup 0 prim < [ drop ] call ] call
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0
    [ txs prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ txs swap prim seq-int.at dup swap dup prim + 0 prim < [ drop 1 prim + ] [ prim + ] if swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop drop ] call ] call
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty
    [ qtys prim seq-int.len ] call
    [ dup 0 prim = [ drop ] [ dup 1 prim - items swap prim seq-int.at stock swap prim seq-int.at dup qtys swap prim seq-int.at dup [ prim < ] dip [ swap 0 prim = [ drop drop 2 ] [ whole swap prim seq-bool.at [ drop drop 3 ] [ swap prim seq-int.push swap 1 ] if ] if ] [ swap prim seq-int.push 0 ] if swap prim seq-int.push swap 1 prim - ] if ] compose
    [ dup 0 prim < [ drop drop drop ] call ] call
  };
```
