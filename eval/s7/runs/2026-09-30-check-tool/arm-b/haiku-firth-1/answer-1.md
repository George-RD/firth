### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i sum len } {
    i len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        xs i 1 prim + new-sum len sum-loop
      }
    ]
    [
      sum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 0 xs prim seq-int.len sum-loop
  };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i len max } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        val max prim <
        [
          xs i 1 prim + len val max-loop
        ]
        [
          xs i 1 prim + len max max-loop
        ]
        if
      }
    ]
    [
      max
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    locals { first } {
      xs 1 xs prim seq-int.len first max-loop
    }
  };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many k:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i len k count } {
    i len prim <
    [
      xs i prim seq-int.at k prim <
      [
        count 1 prim +
        locals { new-count } {
          xs i 1 prim + len k new-count count-loop
        }
      ]
      [
        xs i 1 prim + len k count count-loop
      ]
      if
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    xs 0 xs prim seq-int.len k 0 count-loop
  };
```

### task: index-of
```firth
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs x i len } {
    i len prim <
    [
      xs i prim seq-int.at x prim =
      [
        i
      ]
      [
        xs x i 1 prim + len find-loop
      ]
      if
    ]
    [
      -1
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } {
    xs x 0 xs prim seq-int.len find-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      xs i prim seq-int.at result prim seq-int.push
      locals { new-result } {
        xs i 1 prim - new-result reverse-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many sum:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs i len sum result } {
    i len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        result new-sum prim seq-int.push
        locals { new-result } {
          xs i 1 prim + len new-sum new-result prefix-loop
        }
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len 0 prim seq-int.empty prefix-loop
  };
```

### task: keep-positive
```firth
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs i len result } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        val 0 prim <
        [
          xs i 1 prim + len result keep-loop
        ]
        [
          result val prim seq-int.push
          locals { new-result } {
            xs i 1 prim + len new-result keep-loop
          }
        ]
        if
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len prim seq-int.empty keep-loop
  };
```

### task: is-sorted
```firth
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs i len } {
    i 1 prim - len prim <
    [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim <
      [
        xs i 1 prim + len sorted-loop
      ]
      [
        false
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len
    locals { len } {
      len 1 prim <
      [
        true
      ]
      [
        xs 1 len sorted-loop
      ]
      if
    }
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many len:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i len sum } {
    i len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      sum prim +
      locals { new-sum } {
        xs ys i 1 prim + len new-sum dot-loop
      }
    ]
    [
      sum
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    xs ys 0 xs prim seq-int.len 0 dot-loop
  };
```

### task: all-true
```firth
: all-true-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { flags i len } {
    i len prim <
    [
      flags i prim seq-bool.at
      [
        flags i 1 prim + len all-true-loop
      ]
      [
        false
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } {
    flags 0 flags prim seq-bool.len all-true-loop
  };
```

### task: longest-run
```firth
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many current-run:Int^many max-run:Int^many last-val:Int^many -- ρ result:Int^many)
  locals { xs i len current-run max-run last-val } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        val last-val prim =
        [
          current-run 1 prim +
          locals { new-run } {
            new-run max-run prim <
            [
              xs i 1 prim + len new-run max-run val run-loop
            ]
            [
              xs i 1 prim + len new-run new-run val run-loop
            ]
            if
          }
        ]
        [
          current-run max-run prim <
          [
            xs i 1 prim + len 1 max-run val run-loop
          ]
          [
            xs i 1 prim + len 1 current-run val run-loop
          ]
          if
        ]
        if
      }
    ]
    [
      current-run max-run prim <
      [
        max-run
      ]
      [
        current-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len
    locals { len } {
      len 0 prim =
      [
        0
      ]
      [
        xs 0 prim seq-int.at
        locals { first } {
          xs 1 len 1 0 first run-loop
        }
      ]
      if
    }
  };
```

### task: has-pair-sum
```firth
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many len:Int^many needed:Int^many -- ρ result:Bool^many)
  locals { xs target i j len needed } {
    j len prim <
    [
      i j prim =
      [
        xs target i j 1 prim + len needed inner-loop
      ]
      [
        xs j prim seq-int.at needed prim =
        [
          true
        ]
        [
          xs target i j 1 prim + len needed inner-loop
        ]
        if
      ]
      if
    ]
    [
      xs target i 1 prim + len outer-loop
    ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs target i len } {
    i len prim <
    [
      xs i prim seq-int.at target prim -
      locals { needed } {
        xs target i i 1 prim + len needed inner-loop
      }
    ]
    [
      false
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    xs target 0 xs prim seq-int.len outer-loop
  };
```

### task: count-distinct
```firth
: check-exists
  (forall ρ; ρ checked:Seq Int^many val:Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { checked val i len } {
    i len prim <
    [
      checked i prim seq-int.at val prim =
      [
        true
      ]
      [
        checked val i 1 prim + len check-exists
      ]
      if
    ]
    [
      false
    ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many checked:Seq Int^many i:Int^many len:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs checked i len count } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        checked val 0 checked prim seq-int.len check-exists
        [
          xs checked i 1 prim + len count count-loop
        ]
        [
          count 1 prim +
          locals { new-count } {
            checked val prim seq-int.push
            locals { new-checked } {
              xs new-checked i 1 prim + len new-count count-loop
            }
          }
        ]
        if
      }
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 xs prim seq-int.len 0 count-loop
  };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many xs-len:Int^many ys-len:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs ys i j xs-len ys-len result } {
    i xs-len prim <
    [
      j ys-len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push
          locals { new-result } {
            xs ys i 1 prim + j xs-len ys-len new-result merge-loop
          }
        ]
        [
          result ys j prim seq-int.at prim seq-int.push
          locals { new-result } {
            xs ys i j 1 prim + xs-len ys-len new-result merge-loop
          }
        ]
        if
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        locals { new-result } {
          xs ys i 1 prim + j xs-len ys-len new-result merge-loop
        }
      ]
      if
    ]
    [
      j ys-len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        locals { new-result } {
          xs ys i j 1 prim + xs-len ys-len new-result merge-loop
        }
      ]
      [
        result
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 xs prim seq-int.len ys prim seq-int.len prim seq-int.empty merge-loop
  };
```

### task: digits
```firth
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod
      locals { digit } {
        result digit prim seq-int.push
        locals { new-result } {
          n 10 prim div new-result digit-loop
        }
      }
    ]
    if
  };

: reverse-loop
  (forall ρ; ρ digits:Seq Int^many i:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { digits i result } {
    i 0 prim <
    [
      digits i prim seq-int.at result prim seq-int.push
      locals { new-result } {
        digits i 1 prim - new-result reverse-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ]
    [
      n prim seq-int.empty digit-loop
      locals { digits } {
        digits digits prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
      }
    ]
    if
  };
```

### task: primes-up-to
```firth
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        n d 1 prim + is-prime-check
      ]
      if
    ]
    [
      true
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ i:Int^many n:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { i n result } {
    i n 1 prim + prim <
    [
      i 2 prim <
      [
        i 1 prim + sieve-loop
      ]
      [
        i 2 is-prime-check
        [
          result i prim seq-int.push
          locals { new-result } {
            i 1 prim + new-result sieve-loop
          }
        ]
        [
          i 1 prim + sieve-loop
        ]
        if
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty sieve-loop
  };
```

### task: histogram
```firth
: init-hist
  (forall ρ; ρ k:Int^many i:Int^many hist:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i hist } {
    i k prim <
    [
      hist 0 prim seq-int.push
      locals { new-hist } {
        k i 1 prim + new-hist init-hist
      }
    ]
    [
      hist
    ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many hist:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i len hist } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        hist val prim seq-int.at 1 prim +
        locals { new-count } {
          hist val new-count prim seq-int.set
          locals { new-hist } {
            xs i 1 prim + len new-hist count-loop
          }
        }
      }
    ]
    [
      hist
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-hist
    locals { hist } {
      xs 0 xs prim seq-int.len hist count-loop
    }
  };
```

### task: sort
```firth
: insert-sorted
  (forall ρ; ρ val:Int^many result:Seq Int^many i:Int^many len:Int^many -- ρ result-seq:Seq Int^many)
  locals { val result i len } {
    i len prim <
    [
      result i prim seq-int.at val prim <
      [
        result i val prim seq-int.set
        locals { new-result } {
          val new-result i 1 prim + len insert-sorted
        }
      ]
      [
        result i prim seq-int.at
        locals { item } {
          result i item prim seq-int.set
          locals { new-result } {
            val new-result i 1 prim + len insert-sorted
          }
        }
      ]
      if
    ]
    [
      result val prim seq-int.push
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs i len result } {
    i len prim <
    [
      xs i prim seq-int.at result 0 result prim seq-int.len insert-sorted
      locals { new-result } {
        xs i 1 prim + len new-result sort-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len prim seq-int.empty sort-loop
  };
```

### task: ledger
```firth
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many len:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs i len balance rejected } {
    i len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim +
        locals { new-balance } {
          new-balance 0 prim <
          [
            txs i 1 prim + len balance rejected 1 prim + ledger-loop
          ]
          [
            txs i 1 prim + len new-balance rejected ledger-loop
          ]
          if
        }
      }
    ]
    [
      balance rejected
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs 0 txs prim seq-int.len start 0 ledger-loop
  };
```

### task: allocate-batch
```firth
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many len:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i len allocated reasons } {
    i len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          r qtys i prim seq-int.at prim <
          [
            r 0 prim =
            [
              stock item 0 prim seq-int.set
              allocated qtys i prim seq-int.at prim seq-int.push
              reasons 0 prim seq-int.push
              i 1 prim + allocate-loop
            ]
            [
              whole i prim seq-bool.at
              [
                allocated 0 prim seq-int.push
                reasons 3 prim seq-int.push
                i 1 prim + allocate-loop
              ]
              [
                stock item 0 prim seq-int.set
                allocated r prim seq-int.push
                reasons 1 prim seq-int.push
                i 1 prim + allocate-loop
              ]
              if
            ]
            if
          ]
          [
            stock item r qtys i prim seq-int.at prim - prim seq-int.set
            allocated qtys i prim seq-int.at prim seq-int.push
            reasons 0 prim seq-int.push
            i 1 prim + allocate-loop
          ]
          if
        }
      }
    ]
    [
      stock allocated reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len
    allocate-loop
  };
```
