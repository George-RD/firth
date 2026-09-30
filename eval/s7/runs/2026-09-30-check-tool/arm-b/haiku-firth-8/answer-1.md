### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    0 0 xs sum-loop
  };

: sum-loop
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + locals { sum } {
        i 1 prim + sum xs sum-loop
      }
    ] [ sum ] if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs max-loop
  };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at max prim < [
        xs i prim seq-int.at locals { max } {
          i 1 prim + max xs max-loop
        }
      ] [
        i 1 prim + max xs max-loop
      ] if
    ] [ max ] if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 0 xs k count-loop
  };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count i xs k } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at k prim < [
        count 1 prim + locals { count } {
          i 1 prim + count xs k count-loop
        }
      ] [
        i 1 prim + count xs k count-loop
      ] if
    ] [ count ] if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0 xs x find-index
  };

: find-index
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        i 1 prim + xs x find-index
      ] if
    ] [ -1 ] if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim < [
      result xs xs prim seq-int.len 1 prim - i prim - prim seq-int.at
      prim seq-int.push locals { result } {
        result i 1 prim + xs reverse-loop
      }
    ] [ result ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + locals { sum } {
        result sum prim seq-int.push locals { result } {
          result sum i 1 prim + xs prefix-loop
        }
      }
    ] [ result ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs filter-positive
  };

: filter-positive
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup 0 prim < [
        drop result i 1 prim + xs filter-positive
      ] [
        result swap prim seq-int.push locals { result } {
          result i 1 prim + xs filter-positive
        }
      ] if
    ] [ result ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      true 0 xs check-sorted
    ] if
  };

: check-sorted
  (forall ρ; ρ result:Bool^many i:Int^many xs:Seq Int^many -- ρ final:Bool^many)
  locals { result i xs } {
    result [
      i 1 prim + xs prim seq-int.len prim < [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
        i 1 prim + xs check-sorted
      ] [ true ] if
    ] [ false ] if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0 xs ys dot-product
  };

: dot-product
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs ys } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + locals { sum } {
        i 1 prim + sum xs ys dot-product
      }
    ] [ sum ] if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true 0 flags check-all-true
  };

: check-all-true
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ final:Bool^many)
  locals { result i flags } {
    result [
      i flags prim seq-bool.len prim < [
        flags i prim seq-bool.at
        i 1 prim + flags check-all-true
      ] [ true ] if
    ] [ false ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [ 0 ] [
      1 1 1 xs xs 0 prim seq-int.at longest-run-helper
    ] if
  };

: longest-run-helper
  (forall ρ; ρ curr:Int^many max:Int^many idx:Int^many xs:Seq Int^many prev:Int^many -- ρ result:Int^many)
  locals { curr max idx xs prev } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at prev prim = [
        curr 1 prim + max idx 1 prim + xs xs idx prim seq-int.at longest-run-helper
      ] [
        curr max prim < [ max ] [ curr ] if locals { max } {
          1 max idx 1 prim + xs xs idx prim seq-int.at longest-run-helper
        }
      ] if
    ] [
      curr max prim < [ max ] [ curr ] if
    ] if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false 0 xs target find-pair
  };

: find-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } {
    found prim not [
      i xs prim seq-int.len prim < [
        xs i prim seq-int.at target prim -
        i 1 prim + xs target check-for-complement
      ] [ false ] if
    ] [ true ] if
  };

: check-for-complement
  (forall ρ; ρ needed:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { needed i xs target } {
    false i 1 prim + xs needed has-value
  };

: has-value
  (forall ρ; ρ found:Bool^many j:Int^many xs:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { found j xs val } {
    found prim not [
      j xs prim seq-int.len prim < [
        xs j prim seq-int.at val prim = [
          true
        ] [
          found j 1 prim + xs val has-value
        ] if
      ] [ false ] if
    ] [ true ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at false 0 seen is-in-seen [
        seen i 1 prim + xs count-distinct-loop
      ] [
        seen xs i prim seq-int.at prim seq-int.push locals { seen } {
          seen i 1 prim + xs count-distinct-loop
        }
      ] if
    ] [ seen prim seq-int.len ] if
  };

: is-in-seen
  (forall ρ; ρ val:Int^many found:Bool^many j:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { val found j seen } {
    found [ true ] [
      j seen prim seq-int.len prim < [
        seen j prim seq-int.at val prim = [
          true
        ] [
          val found j 1 prim + seen is-in-seen
        ] if
      ] [ false ] if
    ] if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-helper
  };

: merge-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [
      xs i prim seq-int.at ys j prim seq-int.at prim < [
        result xs i prim seq-int.at prim seq-int.push locals { result } {
          result i 1 prim + j xs ys merge-helper
        }
      ] [
        result ys j prim seq-int.at prim seq-int.push locals { result } {
          result i j 1 prim + xs ys merge-helper
        }
      ] if
    ] [
      i xs prim seq-int.len prim < [
        result xs i prim seq-int.at prim seq-int.push locals { result } {
          result i 1 prim + j xs ys merge-helper
        }
      ] [
        j ys prim seq-int.len prim < [
          result ys j prim seq-int.at prim seq-int.push locals { result } {
            result i j 1 prim + xs ys merge-helper
          }
        ] [
          result
        ] if
      ] if
    ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [ { 0 } ] [
      prim seq-int.empty n extract-digits-loop
    ] if
  };

: extract-digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim = [
      result
    ] [
      result n 10 prim mod prim seq-int.push locals { result } {
        result n 10 prim div extract-digits-loop
      }
    ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n find-primes
  };

: find-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ final:Seq Int^many)
  locals { result candidate limit } {
    candidate limit prim < [
      candidate is-prime [
        result candidate prim seq-int.push locals { result } {
          result candidate 1 prim + limit find-primes
        }
      ] [
        result candidate 1 prim + limit find-primes
      ] if
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [
      n 2 prim = [ true ] [
        n 2 prim mod 0 prim = [ false ] [
          true 3 n check-divisors
        ] if
      ] if
    ] if
  };

: check-divisors
  (forall ρ; ρ prime:Bool^many d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { prime d n } {
    prime [
      d d prim * n prim < [
        n d prim mod 0 prim = [
          false
        ] [
          prime d 2 prim + n check-divisors
        ] if
      ] [ true ] if
    ] [ false ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k init-histogram locals { result } {
      0 result xs histogram-fill
    }
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ final:Seq Int^many)
  locals { result i k } {
    i k prim < [
      result 0 prim seq-int.push locals { result } {
        result i 1 prim + k init-histogram
      }
    ] [ result ] if
  };

: histogram-fill
  (forall ρ; ρ i:Int^many counts:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i counts xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { idx } {
        counts idx counts idx prim seq-int.at 1 prim + prim seq-int.set locals { counts } {
          i 1 prim + counts xs histogram-fill
        }
      }
    ] [ counts ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs insertion-sort
  };

: insertion-sort
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim < [
      result xs i prim seq-int.at insert-into locals { result } {
        result i 1 prim + xs insertion-sort
      }
    ] [ result ] if
  };

: insert-into
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result val } {
    result prim seq-int.len 0 prim = [
      result val prim seq-int.push
    ] [
      result val 0 insert-find-position
    ] if
  };

: insert-find-position
  (forall ρ; ρ result:Seq Int^many val:Int^many j:Int^many -- ρ final:Seq Int^many)
  locals { result val j } {
    j result prim seq-int.len prim < [
      result j prim seq-int.at val prim < [
        result val j prim seq-int.set
      ] [
        result result j prim seq-int.at prim seq-int.push j 1 prim + val insert-find-position
      ] if
    ] [
      result val prim seq-int.push
    ] if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs process-transactions
  };

: process-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at balance prim + dup 0 prim < [
        drop balance rejected 1 prim + i 1 prim + txs process-transactions
      ] [
        locals { new-balance } {
          new-balance rejected i 1 prim + txs process-transactions
        }
      ] if
    ] [ balance rejected ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0 stock prim seq-int.empty prim seq-int.empty stock items qtys whole allocate-loop
  };

: allocate-loop
  (forall ρ; ρ i:Int^many stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many stock-orig:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-alloc:Seq Int^many final-reasons:Seq Int^many)
  locals { i stock alloc reasons stock-orig items qtys whole } {
    i items prim seq-int.len prim < [
      items i prim seq-int.at locals { item-idx } {
        stock item-idx prim seq-int.at qtys i prim seq-int.at locals { curr-stock qty } {
          qty curr-stock prim < [
            curr-stock 0 prim = [
              alloc 0 prim seq-int.push reasons 2 prim seq-int.push locals { alloc reasons } {
                i 1 prim + stock alloc reasons stock-orig items qtys whole allocate-loop
              }
            ] [
              whole i prim seq-bool.at [
                alloc 0 prim seq-int.push reasons 3 prim seq-int.push locals { alloc reasons } {
                  i 1 prim + stock alloc reasons stock-orig items qtys whole allocate-loop
                }
              ] [
                alloc curr-stock prim seq-int.push reasons 1 prim seq-int.push locals { alloc reasons } {
                  stock item-idx 0 prim seq-int.set locals { stock } {
                    i 1 prim + stock alloc reasons stock-orig items qtys whole allocate-loop
                  }
                }
              ] if
            ] if
          ] [
            alloc qty prim seq-int.push reasons 0 prim seq-int.push locals { alloc reasons } {
              stock item-idx qty prim seq-int.set locals { stock } {
                i 1 prim + stock alloc reasons stock-orig items qtys whole allocate-loop
              }
            }
          ] if
        }
      }
    ] [ stock alloc reasons ] if
  };
```
