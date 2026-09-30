### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 0 xs sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { acc i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at acc prim + locals { new-acc } { new-acc i 1 prim + seq sum-loop } ]
    [ acc ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ 0 xs prim seq-int.at ]
    [ 0 xs prim seq-int.at xs max-loop ]
    if
  };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { max i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val max prim <
        [ max i 1 prim + max-loop ]
        [ val i 1 prim + max-loop ]
        if
      }
    ]
    [ max ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { 0 0 xs k count-below-loop };

: count-below-loop
  (forall ρ; ρ count:Int^many i:Int^many seq:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i seq k } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val k prim <
        [ count 1 prim + i 1 prim + count-below-loop ]
        [ count i 1 prim + count-below-loop ]
        if
      }
    ]
    [ count ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { 0 xs x index-of-loop };

: index-of-loop
  (forall ρ; ρ i:Int^many seq:Seq Int^many target:Int^many -- ρ result:Int^many)
  locals { i seq target } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val target prim =
        [ i ]
        [ i 1 prim + index-of-loop ]
        if
      }
    ]
    [ -1 ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result seq i } {
    i 0 prim <
    [ 
      i prim - locals { idx } {
        idx seq prim seq-int.at locals { val } {
          result val prim seq-int.push seq i prim - reverse-loop
        }
      }
    ]
    [ result ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-sums-loop
  };

: prefix-sums-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many seq:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at sum prim + locals { new-sum } {
        result new-sum prim seq-int.push new-sum i 1 prim + seq prefix-sums-loop
      }
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs keep-positive-loop
  };

: keep-positive-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many seq:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        val 0 prim <
        [ result i 1 prim + keep-positive-loop ]
        [ val result prim seq-int.push i 1 prim + keep-positive-loop ]
        if
      }
    ]
    [ result ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <= [ true ] [ 0 xs is-sorted-loop ] if
  };

: is-sorted-loop
  (forall ρ; ρ i:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { i seq } {
    i seq prim seq-int.len 1 prim - prim <
    [ i seq prim seq-int.at i 1 prim + seq prim seq-int.at prim <= 
      [ i 1 prim + is-sorted-loop ] 
      [ false ] 
      if
    ]
    [ true ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    0 0 xs ys dot-loop
  };

: dot-loop
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at i ys prim seq-int.at prim * sum prim + 
      locals { new-sum } { new-sum i 1 prim + xs ys dot-loop } 
    ]
    [ sum ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } {
    0 flags all-true-loop
  };

: all-true-loop
  (forall ρ; ρ i:Int^many seq:Seq Bool^many -- ρ result:Bool^many)
  locals { i seq } {
    i seq prim seq-bool.len prim <
    [ i seq prim seq-bool.at 
      [ i 1 prim + all-true-loop ] 
      [ false ] 
      if 
    ]
    [ true ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 prim seq-int.at 1 1 0 xs longest-run-loop ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-run:Int^many prev-val:Int^many curr-run:Int^many curr-idx:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { max-run prev-val curr-run curr-idx seq } {
    curr-idx seq prim seq-int.len prim < [ 1 prim + ]
    [ curr-idx seq prim seq-int.at locals { val } {
        val prev-val prim =
        [ curr-run 1 prim + ]
        [ 1 ]
        if
        locals { new-run } {
          new-run max-run prim <
          [ new-run ]
          [ max-run ]
          if
          locals { updated-max } {
            val curr-idx 1 prim + new-run updated-max longest-run-loop
          }
        }
      }
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    0 xs target has-pair-sum-loop
  };

: has-pair-sum-loop
  (forall ρ; ρ i:Int^many seq:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i seq target } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        i 1 prim + seq target val has-pair-sum-inner
      }
    ]
    [ false ]
    if
  };

: has-pair-sum-inner
  (forall ρ; ρ j:Int^many seq:Seq Int^many target:Int^many val:Int^many -- ρ result:Bool^many)
  locals { j seq target val } {
    j seq prim seq-int.len prim <
    [ j seq prim seq-int.at val prim + target prim =
      [ true ]
      [ j 1 prim + seq target val has-pair-sum-inner ]
      if
    ]
    [ val seq target has-pair-sum-loop ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many seq:Seq Int^many -- ρ result:Int^many)
  locals { seen i seq } {
    i seq prim seq-int.len prim <
    [ i seq prim seq-int.at locals { val } {
        0 seen val is-in-seq
        [ seen i 1 prim + count-distinct-loop ]
        [ seen val prim seq-int.push i 1 prim + count-distinct-loop ]
        if
      }
    ]
    [ seen prim seq-int.len ]
    if
  };

: is-in-seq
  (forall ρ; ρ j:Int^many seq:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j seq target } {
    j seq prim seq-int.len prim <
    [ j seq prim seq-int.at target prim =
      [ true ]
      [ j 1 prim + is-in-seq ]
      if
    ]
    [ false ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-sorted-loop
  };

: merge-sorted-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim <
      [ i xs prim seq-int.at j ys prim seq-int.at prim <
        [ result i xs prim seq-int.at prim seq-int.push i 1 prim + j merge-sorted-loop ]
        [ result j ys prim seq-int.at prim seq-int.push i j 1 prim + merge-sorted-loop ]
        if
      ]
      [ result i xs prim seq-int.at prim seq-int.push i 1 prim + j merge-sorted-loop ]
      if
    ]
    [ result j ys prim seq-int.len prim <
      [ result j ys prim seq-int.at prim seq-int.push i j 1 prim + merge-sorted-loop ]
      [ result ]
      if
    ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ 0 prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many num:Int^many -- ρ result:Seq Int^many)
  locals { result num } {
    num 0 prim <
    [ num prim - ]
    [ num ]
    if
    locals { check-num } {
      check-num 0 prim <
      [ result ]
      [ check-num 10 prim mod locals { digit } {
          result digit prim seq-int.push check-num 10 prim div digits-loop
        }
      ]
      if
    }
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n sieve-loop
  };

: sieve-loop
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { primes candidate limit } {
    candidate limit prim <
    [ candidate primes is-prime-sieve
      [ primes candidate prim seq-int.push candidate 1 prim + sieve-loop ]
      [ candidate 1 prim + sieve-loop ]
      if
    ]
    [ primes ]
    if
  };

: is-prime-sieve
  (forall ρ; ρ candidate:Int^many primes:Seq Int^many -- ρ result:Bool^many)
  locals { candidate primes } {
    0 candidate primes test-divisors
  };

: test-divisors
  (forall ρ; ρ i:Int^many candidate:Int^many primes:Seq Int^many -- ρ result:Bool^many)
  locals { i candidate primes } {
    i primes prim seq-int.len prim <
    [ i primes prim seq-int.at locals { divisor } {
        divisor divisor prim * candidate prim <
        [ true ]
        [ candidate divisor prim mod 0 prim =
          [ false ]
          [ i 1 prim + test-divisors ]
          if
        ]
        if
      }
    ]
    [ true ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    0 k prim seq-int.empty init-histogram-counts xs histogram-loop
  };

: init-histogram-counts
  (forall ρ; ρ i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i k counts } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + init-histogram-counts ]
    [ counts ]
    if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at locals { val } {
        val counts prim seq-int.at 1 prim + counts val prim seq-int.set
        locals { new-counts } { i 1 prim + new-counts histogram-loop }
      }
    ]
    [ counts ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs 0 insertion-sort
  };

: insertion-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { arr i } {
    i arr prim seq-int.len prim <
    [ i arr prim seq-int.at locals { val } {
        arr val i insert-in-sorted i 1 prim + insertion-sort
      }
    ]
    [ arr ]
    if
  };

: insert-in-sorted
  (forall ρ; ρ arr:Seq Int^many val:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { arr val pos } {
    pos 0 prim <
    [ arr val pos prim seq-int.set ]
    [ pos 1 prim - arr prim seq-int.at locals { prev } {
        prev val prim <
        [ arr val pos prim seq-int.set ]
        [ arr prev pos prim seq-int.set pos 1 prim - insert-in-sorted ]
        if
      }
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [ i txs prim seq-int.at locals { tx } {
        balance tx prim + 0 prim <
        [ balance rejected 1 prim + i 1 prim + ledger-loop ]
        [ balance tx prim + rejected i 1 prim + ledger-loop ]
        if
      }
    ]
    [ balance rejected ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 stock items qtys whole allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order-idx:Int^many orig-stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons order-idx orig-stock items qtys whole } {
    order-idx items prim seq-int.len prim <
    [ order-idx items prim seq-int.at locals { item-idx } {
        item-idx stock prim seq-int.at locals { available } {
          order-idx qtys prim seq-int.at locals { requested } {
            requested available prim <
            [ available 0 prim =
              [ stock allocated reasons order-idx 1 prim + orig-stock items qtys whole allocate-loop-2 ]
              [ order-idx whole prim seq-bool.at
                [ stock allocated reasons order-idx 1 prim + orig-stock items qtys whole allocate-loop-2 ]
                [ stock available item-idx prim seq-int.set allocated available prim seq-int.push reasons 1 prim seq-int.push order-idx 1 prim + orig-stock allocate-loop ]
                if
              ]
              if
            ]
            [ stock requested item-idx prim seq-int.set allocated requested prim seq-int.push reasons 0 prim seq-int.push order-idx 1 prim + orig-stock allocate-loop ]
            if
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: allocate-loop-2
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order-idx:Int^many orig-stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons order-idx orig-stock items qtys whole } {
    allocated 0 prim seq-int.push reasons 2 prim seq-int.push order-idx 1 prim + orig-stock items qtys whole allocate-loop
  };
```
