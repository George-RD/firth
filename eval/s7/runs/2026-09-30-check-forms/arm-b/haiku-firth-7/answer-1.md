### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 sum-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many total:Int^many -- ρ total:Int^many)
  locals { xs index total } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at total prim + locals { newsum } {
        xs index 1 prim + newsum sum-loop
      }
    ] [
      total
    ] if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs xs 0 prim seq-int.at 1 find-max-loop };

: find-max-loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many index:Int^many -- ρ largest:Int^many)
  locals { xs max index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at locals { val } {
        val max prim > [
          val
        ] [
          max
        ] if
        locals { newmax } {
          xs newmax index 1 prim + find-max-loop
        }
      }
    ] [
      max
    ] if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop-below };

: count-loop-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many count:Int^many -- ρ count:Int^many)
  locals { xs k index count } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at locals { val } {
        val k prim < [
          count 1 prim +
        ] [
          count
        ] if
        locals { newcount } {
          xs k index 1 prim + newcount count-loop-below
        }
      }
    ] [
      count
    ] if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 search-index };

: search-index
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        xs x i 1 prim + search-index
      ] if
    ] [
      -1
    ] if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many acc:Seq Int^many index:Int^many -- ρ acc:Seq Int^many)
  locals { xs acc index } {
    index 0 prim >= [
      xs index prim seq-int.at locals { val } {
        acc val prim seq-int.push locals { newacc } {
          xs newacc index 1 prim - reverse-loop
        }
      }
    ] [
      acc
    ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ xs:Seq Int^many acc:Seq Int^many sum:Int^many index:Int^many -- ρ acc:Seq Int^many)
  locals { xs acc sum index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at locals { val } {
        sum val prim + locals { newsum } {
          acc newsum prim seq-int.push locals { newacc } {
            xs newacc newsum index 1 prim + prefix-loop
          }
        }
      }
    ] [
      acc
    ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 filter-positive };

: filter-positive
  (forall ρ; ρ xs:Seq Int^many acc:Seq Int^many index:Int^many -- ρ acc:Seq Int^many)
  locals { xs acc index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at locals { val } {
        val 0 prim > [
          acc val prim seq-int.push
        ] [
          acc
        ] if
        locals { newacc } {
          xs newacc index 1 prim + filter-positive
        }
      }
    ] [
      acc
    ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 check-sorted };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at locals { curr } {
        xs i 1 prim + prim seq-int.at locals { next } {
          curr next prim <= [
            xs i 1 prim + check-sorted
          ] [
            false
          ] if
        }
      }
    ] [
      true
    ] if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-product };

: dot-product
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many index:Int^many -- ρ sum:Int^many)
  locals { xs ys sum index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at locals { xval } {
        ys index prim seq-int.at locals { yval } {
          xval yval prim * locals { prod } {
            sum prod prim + locals { newsum } {
              xs ys newsum index 1 prim + dot-product
            }
          }
        }
      }
    ] [
      sum
    ] if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 check-all-true };

: check-all-true
  (forall ρ; ρ flags:Seq Bool^many index:Int^many -- ρ all:Bool^many)
  locals { flags index } {
    index flags prim seq-bool.len prim < [
      flags index prim seq-bool.at [
        flags index 1 prim + check-all-true
      ] [
        false
      ] if
    ] [
      true
    ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 0 1 0 find-longest };

: find-longest
  (forall ρ; ρ xs:Seq Int^many index:Int^many max-run:Int^many current-run:Int^many prev:Int^many -- ρ length:Int^many)
  locals { xs index max-run current-run prev } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at locals { curr } {
        curr prev prim = [
          current-run 1 prim +
        ] [
          1
        ] if
        locals { newrun } {
          newrun max-run prim > [
            newrun
          ] [
            max-run
          ] if
          locals { newmax } {
            xs index 1 prim + newmax newrun curr find-longest
          }
        }
      }
    ] [
      max-run
    ] if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 find-pair };

: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { xi } {
        xs target xi i 1 prim + find-pair-inner
      }
    ] [
      false
    ] if
  };

: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many xi:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target xi j } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at locals { xj } {
        xi xj prim + target prim = [
          true
        ] [
          xs target xi j 1 prim + find-pair-inner
        ] if
      }
    ] [
      xs target xs prim seq-int.len find-pair
    ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs prim seq-int.empty 0 count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many index:Int^many -- ρ count:Int^many)
  locals { xs seen index } {
    index xs prim seq-int.len prim < [
      xs index prim seq-int.at locals { val } {
        val seen check-contains [
          xs seen index 1 prim + count-distinct-loop
        ] [
          seen val prim seq-int.push locals { newseen } {
            xs newseen index 1 prim + count-distinct-loop
          }
        ] if
      }
    ] [
      seen prim seq-int.len
    ] if
  };

: check-contains
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { val seq } { val seq 0 check-contains-loop };

: check-contains-loop
  (forall ρ; ρ val:Int^many seq:Seq Int^many i:Int^many -- ρ found:Bool^many)
  locals { val seq i } {
    i seq prim seq-int.len prim < [
      seq i prim seq-int.at val prim = [
        true
      ] [
        val seq i 1 prim + check-contains-loop
      ] if
    ] [
      false
    ] if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many acc:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys acc i j } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [
      xs i prim seq-int.at locals { xi } {
        ys j prim seq-int.at locals { yj } {
          xi yj prim <= [
            acc xi prim seq-int.push locals { newacc } {
              xs ys newacc i 1 prim + j merge-loop
            }
          ] [
            acc yj prim seq-int.push locals { newacc } {
              xs ys newacc i j 1 prim + merge-loop
            }
          ] if
        }
      }
    ] [
      i xs prim seq-int.len prim < [
        xs i prim seq-int.at locals { val } {
          acc val prim seq-int.push locals { newacc } {
            xs ys newacc i 1 prim + j merge-loop
          }
        }
      ] [
        j ys prim seq-int.len prim < [
          ys j prim seq-int.at locals { val } {
            acc val prim seq-int.push locals { newacc } {
              xs ys newacc i j 1 prim + merge-loop
            }
          }
        ] [
          acc
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
    n 0 prim = [
      { 0 }
    ] [
      n 0 prim < [
        n 0 prim - prim seq-int.empty extract-digits
      ] [
        n prim seq-int.empty extract-digits
      ] if
    ] if
  };

: extract-digits
  (forall ρ; ρ n:Int^many acc:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n acc } {
    n 0 prim > [
      n 10 prim mod locals { digit } {
        acc digit prim seq-int.push locals { newacc } {
          n 10 prim div newacc extract-digits
        }
      }
    ] [
      acc
    ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n prim seq-int.empty 2 find-primes };

: find-primes
  (forall ρ; ρ n:Int^many acc:Seq Int^many candidate:Int^many -- ρ primes:Seq Int^many)
  locals { n acc candidate } {
    candidate n prim <= [
      candidate is-prime [
        acc candidate prim seq-int.push locals { newacc } {
          n newacc candidate 1 prim + find-primes
        }
      ] [
        n acc candidate 1 prim + find-primes
      ] if
    ] [
      acc
    ] if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim < [
      false
    ] [
      num 2 prim = [
        true
      ] [
        num 2 check-prime-loop
      ] if
    ] if
  };

: check-prime-loop
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim <= [
      num divisor prim mod 0 prim = [
        false
      ] [
        num divisor 1 prim + check-prime-loop
      ] if
    ] [
      true
    ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    xs k prim seq-int.empty 0 build-histogram
  };

: build-histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many zero:Int^many -- ρ counts:Seq Int^many)
  locals { xs k counts zero } {
    zero k prim < [
      counts 0 prim seq-int.push locals { newcounts } {
        xs k newcounts zero 1 prim + build-histogram
      }
    ] [
      xs counts 0 count-into
    ] if
  };

: count-into
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { xs counts i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at 1 prim + locals { newval } {
          counts v newval prim seq-int.set locals { newcounts } {
            xs newcounts i 1 prim + count-into
          }
        }
      }
    ] [
      counts
    ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs xs 0 xs prim seq-int.len 1 prim - insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many arr:Seq Int^many start:Int^many end:Int^many -- ρ sorted:Seq Int^many)
  locals { xs arr start end } {
    start end prim <= [
      xs arr start 1 prim + end insertion-sort locals { sorted } {
        sorted start insert-element
      }
    ] [
      arr
    ] if
  };

: insert-element
  (forall ρ; ρ sorted:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { sorted i } {
    i 0 prim > [
      sorted i prim seq-int.at locals { curr } {
        sorted i 1 prim - prim seq-int.at locals { prev } {
          curr prev prim < [
            sorted i prev prim seq-int.set locals { swapped } {
              swapped i 1 prim - insert-element
            }
          ] [
            sorted
          ] if
        }
      }
    ] [
      sorted
    ] if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs start 0 0 process-transactions };

: process-transactions
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many index:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs balance rejected index } {
    index txs prim seq-int.len prim < [
      txs index prim seq-int.at locals { tx } {
        balance tx prim + 0 prim >= [
          txs balance tx prim + index 1 prim + rejected process-transactions
        ] [
          txs balance index 1 prim + rejected 1 prim + process-transactions
        ] if
      }
    ] [
      balance rejected
    ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole stock prim seq-int.empty prim seq-int.empty 0 allocate-orders
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many curr-stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole curr-stock allocated reasons order } {
    order items prim seq-int.len prim < [
      items order prim seq-int.at locals { item } {
        qtys order prim seq-int.at locals { qty } {
          whole order prim seq-bool.at locals { must-fill } {
            curr-stock item prim seq-int.at locals { available } {
              qty available prim <= [
                allocated qty prim seq-int.push locals { new-allocated } {
                  curr-stock item qty prim seq-int.set locals { new-stock } {
                    stock items qtys whole new-stock new-allocated reasons 0 prim seq-int.push order 1 prim + allocate-orders
                  }
                }
              ] [
                available 0 prim = [
                  allocated 0 prim seq-int.push locals { new-allocated } {
                    stock items qtys whole curr-stock new-allocated reasons 2 prim seq-int.push order 1 prim + allocate-orders
                  }
                ] [
                  must-fill [
                    allocated 0 prim seq-int.push locals { new-allocated } {
                      stock items qtys whole curr-stock new-allocated reasons 3 prim seq-int.push order 1 prim + allocate-orders
                    }
                  ] [
                    allocated available prim seq-int.push locals { new-allocated } {
                      curr-stock item 0 prim seq-int.set locals { new-stock } {
                        stock items qtys whole new-stock new-allocated reasons 1 prim seq-int.push order 1 prim + allocate-orders
                      }
                    }
                  ] if
                ] if
              ] if
            }
          }
        }
      }
    ] [
      curr-stock allocated reasons
    ] if
  };
```
