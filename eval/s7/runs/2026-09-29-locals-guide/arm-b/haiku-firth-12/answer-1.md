### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    0 0 xs prim seq-int.len sum-loop xs
  };

: sum-loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ total:Int^many)
  locals { acc idx len xs } {
    idx len prim =
    [ acc ]
    [ idx xs prim seq-int.at
      locals { acc idx len xs elem } {
        (acc elem prim +) (idx 1 prim +) len xs sum-loop
      }
    ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    0 xs prim seq-int.at 1 xs prim seq-int.len find-max xs
  };

: find-max
  (forall ρ; ρ max:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max idx len xs } {
    idx len prim =
    [ max ]
    [ idx xs prim seq-int.at
      locals { max idx len xs elem } {
        elem max prim <
        [ max (idx 1 prim +) len xs find-max ]
        [ elem (idx 1 prim +) len xs find-max ]
        if
      }
    ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 0 xs prim seq-int.len count-loop xs k
  };

: count-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ total:Int^many)
  locals { count idx len xs k } {
    idx len prim =
    [ count ]
    [ idx xs prim seq-int.at
      locals { count idx len xs k elem } {
        elem k prim <
        [ (count 1 prim +) (idx 1 prim +) len xs k count-loop ]
        [ count (idx 1 prim +) len xs k count-loop ]
        if
      }
    ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0 xs prim seq-int.len search-index xs x
  };

: search-index
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { idx len xs x } {
    idx len prim =
    [ -1 ]
    [ idx xs prim seq-int.at
      locals { idx len xs x elem } {
        elem x prim =
        [ idx ]
        [ (idx 1 prim +) len xs x search-index ]
        if
      }
    ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop xs
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result idx xs } {
    idx 0 prim <
    [ result ]
    [ idx xs prim seq-int.at
      locals { result idx xs elem } {
        result elem prim seq-int.push locals { result idx xs } {
          result (idx 1 prim -) xs reverse-loop
        }
      }
    ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop xs
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum idx len xs } {
    idx len prim =
    [ result ]
    [ idx xs prim seq-int.at
      locals { result sum idx len xs elem } {
        (sum elem prim +) locals { result sum idx len xs } {
          result sum prim seq-int.push locals { result sum idx len xs } {
            result sum (idx 1 prim +) len xs prefix-loop
          }
        }
      }
    ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs prim seq-int.len filter-positive xs
  };

: filter-positive
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result idx len xs } {
    idx len prim =
    [ result ]
    [ idx xs prim seq-int.at
      locals { result idx len xs elem } {
        elem 0 prim <
        [ result (idx 1 prim +) len xs filter-positive ]
        [ result elem prim seq-int.push locals { result idx len xs } {
            result (idx 1 prim +) len xs filter-positive
          }
        ]
        if
      }
    ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 xs prim seq-int.len 1 prim - check-sorted xs ]
    if
  };

: check-sorted
  (forall ρ; ρ idx:Int^many max_idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { idx max_idx xs } {
    idx max_idx prim =
    [ true ]
    [ idx xs prim seq-int.at (idx 1 prim +) xs prim seq-int.at
      locals { idx max_idx xs curr next } {
        curr next prim <
        [ true ]
        [ curr next prim = ]
        if
        [ (idx 1 prim +) max_idx xs check-sorted ]
        [ false ]
        if
      }
    ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0 xs prim seq-int.len dot-product xs ys
  };

: dot-product
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum idx len xs ys } {
    idx len prim =
    [ sum ]
    [ idx xs prim seq-int.at idx ys prim seq-int.at
      locals { sum idx len xs ys x y } {
        (sum (x y prim * prim +)) (idx 1 prim +) len xs ys dot-product
      }
    ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    0 flags prim seq-int.len check-all flags
  };

: check-all
  (forall ρ; ρ idx:Int^many len:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { idx len flags } {
    idx len prim =
    [ true ]
    [ idx flags prim seq-int.at
      [ (idx 1 prim +) len flags check-all ]
      [ false ]
      if
    ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 xs prim seq-int.at 1 1 xs prim seq-int.len longest xs ]
    if
  };

: longest
  (forall ρ; ρ maxlen:Int^many prev:Int^many curlen:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { maxlen prev curlen idx len xs } {
    idx len prim =
    [ curlen maxlen prim < [ maxlen ] [ curlen ] if ]
    [ idx xs prim seq-int.at
      locals { maxlen prev curlen idx len xs curr } {
        curr prev prim =
        [ maxlen prev (curlen 1 prim +) (idx 1 prim +) len xs longest ]
        [ (curlen maxlen prim < [ maxlen ] [ curlen ] if) curr 1 (idx 1 prim +) len xs longest ]
        if
      }
    ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0 xs prim seq-int.len outer xs target
  };

: outer
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i len xs target } {
    i len prim =
    [ false ]
    [ (i 1 prim +) len inner xs target i ]
    if
  };

: inner
  (forall ρ; ρ j:Int^many len:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j len xs target i } {
    j len prim =
    [ (i 1 prim +) len outer xs target ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs prim seq-int.len count-uniq xs
  };

: count-uniq
  (forall ρ; ρ seen:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen idx len xs } {
    idx len prim =
    [ seen prim seq-int.len ]
    [ idx xs prim seq-int.at
      locals { seen idx len xs elem } {
        0 seen prim seq-int.len check-in-seen elem seen
        [ seen (idx 1 prim +) len xs count-uniq ]
        [ seen elem prim seq-int.push locals { seen idx len xs } {
            seen (idx 1 prim +) len xs count-uniq
          }
        ]
        if
      }
    ]
    if
  };

: check-in-seen
  (forall ρ; ρ idx:Int^many len:Int^many x:Int^many seen:Seq Int^many -- ρ found:Bool^many)
  locals { idx len x seen } {
    idx len prim =
    [ false ]
    [ idx seen prim seq-int.at
      locals { idx len x seen elem } {
        elem x prim =
        [ true ]
        [ (idx 1 prim +) len x seen check-in-seen ]
        if
      }
    ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge xs ys
  };

: merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xlen ylen xs ys } {
    i xlen prim =
    [ result j ylen add-remaining ys ]
    [ j ylen prim =
      [ result i xlen add-remaining xs ]
      [ i xs prim seq-int.at j ys prim seq-int.at
        locals { result i j xlen ylen xs ys x y } {
          x y prim <
          [ result x prim seq-int.push locals { result i j xlen ylen xs ys } {
              result (i 1 prim +) j xlen ylen xs ys merge
            }
          ]
          [ result y prim seq-int.push locals { result i j xlen ylen xs ys } {
              result i (j 1 prim +) xlen ylen xs ys merge
            }
          ]
          if
        }
      ]
      if
    ]
    if
  };

: add-remaining
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many seq:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result idx len seq } {
    idx len prim =
    [ result ]
    [ idx seq prim seq-int.at
      locals { result idx len seq elem } {
        result elem prim seq-int.push locals { result idx len seq } {
          result (idx 1 prim +) len seq add-remaining
        }
      }
    ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-extract ]
    if
  };

: digits-extract
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod
      locals { result n digit } {
        result digit prim seq-int.push locals { result n } {
          result (n 10 prim div) digits-extract
        }
      }
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n sieve
  };

: sieve
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate limit } {
    candidate limit prim <
    [ candidate is-prime
      [ result candidate prim seq-int.push ]
      [ result ]
      if
      locals { result candidate limit } {
        result (candidate 1 prim +) limit sieve
      }
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ 2 n trial-divide ]
    if
  };

: trial-divide
  (forall ρ; ρ d:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [ true ]
    [ n d prim mod 0 prim =
      [ false ]
      [ (d 1 prim +) n trial-divide ]
      if
    ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k make-zeros 0 xs prim seq-int.len add-counts xs
  };

: make-zeros
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ zeros:Seq Int^many)
  locals { result k } {
    result prim seq-int.len k prim =
    [ result ]
    [ result 0 prim seq-int.push locals { result k } { result k make-zeros } ]
    if
  };

: add-counts
  (forall ρ; ρ counts:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { counts idx len xs } {
    idx len prim =
    [ counts ]
    [ idx xs prim seq-int.at
      locals { counts idx len xs x } {
        x counts prim seq-int.at 1 prim +
        locals { counts idx len xs x newval } {
          counts x newval prim seq-int.set locals { counts idx len xs } {
            counts (idx 1 prim +) len xs add-counts
          }
        }
      }
    ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len insertion-sort
  };

: insertion-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many len:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i len } {
    i len prim =
    [ arr ]
    [ arr i insert-item locals { arr i len } {
        arr (i 1 prim +) len insertion-sort
      }
    ]
    if
  };

: insert-item
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ arr:Seq Int^many)
  locals { arr i } {
    i 0 prim =
    [ arr ]
    [ (i 1 prim -) arr prim seq-int.at i arr prim seq-int.at
      locals { arr i prev curr } {
        prev curr prim <
        [ arr ]
        [ arr i prev prim seq-int.set locals { arr i } {
            arr (i 1 prim -) insert-item
          }
        ]
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
    start 0 0 txs prim seq-int.len process-txs txs
  };

: process-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected idx len txs } {
    idx len prim =
    [ balance rejected ]
    [ idx txs prim seq-int.at
      locals { balance rejected idx len txs tx } {
        (balance tx prim +) 0 prim <
        [ balance (rejected 1 prim +) (idx 1 prim +) len txs process-txs ]
        [ (balance tx prim +) rejected (idx 1 prim +) len txs process-txs ]
        if
      }
    ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len batch-allocate stock items qtys whole
  };

: batch-allocate
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order_idx:Int^many len:Int^many orig_stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons order_idx len orig_stock items qtys whole } {
    order_idx len prim =
    [ stock allocated reasons ]
    [ order_idx items prim seq-int.at order_idx qtys prim seq-int.at order_idx whole prim seq-int.at
      locals { stock allocated reasons order_idx len orig_stock items qtys whole item_idx qty must_whole } {
        item_idx stock prim seq-int.at
        locals { stock allocated reasons order_idx len orig_stock items qtys whole item_idx qty must_whole available } {
          qty available prim <
          [ available 0 prim =
            [ stock 0 prim seq-int.push allocated 0 prim seq-int.push reasons 2 prim seq-int.push ]
            [ must_whole
              [ stock 0 prim seq-int.push allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]
              [ stock available prim seq-int.set stock available prim seq-int.push allocated available prim seq-int.push reasons 1 prim seq-int.push ]
              if
            ]
            if
          ]
          [ stock (available qty prim -) prim seq-int.set stock qty prim seq-int.push allocated qty prim seq-int.push reasons 0 prim seq-int.push ]
          if
          locals { stock allocated reasons order_idx len orig_stock items qtys whole } {
            stock allocated reasons (order_idx 1 prim +) len orig_stock items qtys whole batch-allocate
          }
        }
      }
    ]
    if
  };
```
