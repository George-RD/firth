### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many acc:Int^many -- ρ result:Int^many)
  locals { i xs acc } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        i 1 prim + xs acc val prim + sum-loop
      }
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 xs 0 sum-loop
  };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        max val prim < [
          val
        ] [
          max
        ] if locals { new_max } {
          i 1 prim + xs new_max max-loop
        }
      }
    ] [
      max
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at locals { first } {
      1 xs first max-loop
    }
  };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many k:Int^many count:Int^many -- ρ result:Int^many)
  locals { i xs k count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        val k prim < [
          count 1 prim +
        ] [
          count
        ] if locals { new_count } {
          i 1 prim + xs k new_count count-loop
        }
      }
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    0 xs k 0 count-loop
  };
```

### task: index-of
```firth
: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        val x prim = [
          i
        ] [
          i 1 prim + xs x index-loop
        ] if
      }
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } {
    0 xs x index-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim < [
      xs i prim seq-int.at locals { val } {
        result val prim seq-int.push locals { new_result } {
          i 1 prim - xs new_result reverse-loop
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - xs prim seq-int.empty reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { i xs sum result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        sum val prim + locals { new_sum } {
          result new_sum prim seq-int.push locals { new_result } {
            i 1 prim + xs new_sum new_result prefix-loop
          }
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    0 xs 0 prim seq-int.empty prefix-loop
  };
```

### task: keep-positive
```firth
: keep-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        val 0 prim < [
          i 1 prim + xs result keep-loop
        ] [
          result val prim seq-int.push locals { new_result } {
            i 1 prim + xs new_result keep-loop
          }
        ] if
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    0 xs prim seq-int.empty keep-loop
  };
```

### task: is-sorted
```firth
: check-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at locals { curr } {
        xs i 1 prim + prim seq-int.at locals { next } {
          curr next prim < [
            i 1 prim + xs check-loop
          ] [
            curr next prim = [
              i 1 prim + xs check-loop
            ] [
              false
            ] if
          ] if
        }
      }
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    0 xs check-loop
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many ys:Seq Int^many acc:Int^many -- ρ product:Int^many)
  locals { i xs ys acc } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { x } {
        ys i prim seq-int.at locals { y } {
          x y prim * locals { prod } {
            acc prod prim + locals { new_acc } {
              i 1 prim + xs ys new_acc dot-loop
            }
          }
        }
      }
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 xs ys 0 dot-loop
  };
```

### task: all-true
```firth
: check-all-loop
  (forall ρ; ρ i:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { i flags } {
    i flags prim seq-bool.len prim < [
      flags i prim seq-bool.at [
        i 1 prim + flags check-all-loop
      ] [
        false
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    0 flags check-all-loop
  };
```

### task: longest-run
```firth
: count-run
  (forall ρ; ρ i:Int^many xs:Seq Int^many curr_len:Int^many max_len:Int^many -- ρ length:Int^many)
  locals { i xs curr_len max_len } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { curr } {
        xs i 1 prim + prim seq-int.at locals { next } {
          curr next prim = [
            curr_len 1 prim + locals { new_curr_len } {
              i 1 prim + xs new_curr_len max_len count-run
            }
          ] [
            curr_len max_len prim < [
              max_len
            ] [
              curr_len
            ] if locals { new_max_len } {
              i 1 prim + xs 1 new_max_len count-run
            }
          ] if
        }
      }
    ] [
      curr_len max_len prim < [
        max_len
      ] [
        curr_len
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      1 xs 1 0 count-run
    ] if
  };
```

### task: has-pair-sum
```firth
: check-pair
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i j xs target } {
    j xs prim seq-int.len prim < [
      i j prim = [
        i 1 prim + j 1 prim + xs target check-pair
      ] [
        xs i prim seq-int.at locals { a } {
          xs j prim seq-int.at locals { b } {
            a b prim + target prim = [
              true
            ] [
              j 1 prim + xs prim seq-int.len i 1 prim + prim < [
                i 1 prim + j 1 prim + xs target check-pair
              ] [
                i 1 prim + xs prim seq-int.len 1 prim - prim < [
                  i 1 prim + i 2 prim + xs target check-pair
                ] [
                  false
                ] if
              ] if
            ] if
          }
        }
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0 1 xs target check-pair
  };
```

### task: count-distinct
```firth
: count-distinct-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many count:Int^many -- ρ distinct:Int^many)
  locals { i xs count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        i 1 prim + xs count count-distinct-loop
      }
    ] [
      count
    ] if
  };

: is-in-result
  (forall ρ; ρ i:Int^many val:Int^many xs:Seq Int^many -- ρ found:Bool^many)
  locals { i val xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { curr } {
        curr val prim = [
          true
        ] [
          i 1 prim + val xs is-in-result
        ] if
      }
    ] [
      false
    ] if
  };

: count-unique-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ distinct:Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        0 val result is-in-result [
          i 1 prim + xs result count-unique-loop
        ] [
          result val prim seq-int.push locals { new_result } {
            i 1 prim + xs new_result count-unique-loop
          }
        ] if
      }
    ] [
      result prim seq-int.len
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 xs prim seq-int.empty count-unique-loop
  };
```

### task: merge-sorted
```firth
: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i j xs ys result } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at locals { x } {
          ys j prim seq-int.at locals { y } {
            x y prim < [
              result x prim seq-int.push locals { new_result } {
                i 1 prim + j xs ys new_result merge-loop
              }
            ] [
              result y prim seq-int.push locals { new_result } {
                i j 1 prim + xs ys new_result merge-loop
              }
            ] if
          }
        }
      ] [
        i xs prim seq-int.len prim < [
          xs i prim seq-int.at locals { x } {
            result x prim seq-int.push locals { new_result } {
              i 1 prim + j xs ys new_result merge-loop
            }
          }
        ] [
          result
        ] if
      ] if
    ] [
      j ys prim seq-int.len prim < [
        ys j prim seq-int.at locals { y } {
          result y prim seq-int.push locals { new_result } {
            i j 1 prim + xs ys new_result merge-loop
          }
        }
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    0 0 xs ys prim seq-int.empty merge-loop
  };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { d } {
        n 10 prim div locals { n_div } {
          result d prim seq-int.push locals { new_result } {
            n_div new_result digits-loop
          }
        }
      }
    ] if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many digits_seq:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i digits_seq result } {
    i 0 prim < [
      digits_seq i prim seq-int.at locals { d } {
        result d prim seq-int.push locals { new_result } {
          i 1 prim - digits_seq new_result reverse-digits
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty digits-loop locals { raw_digits } {
        raw_digits prim seq-int.len 1 prim - raw_digits prim seq-int.empty reverse-digits
      }
    ] if
  };
```

### task: primes-up-to
```firth
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim < [
      n d prim mod 0 prim = [
        false
      ] [
        d 1 prim + n is-prime-check
      ] if
    ] [
      true
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [
      false
    ] [
      2 n is-prime-check
    ] if
  };

: collect-primes
  (forall ρ; ρ i:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { i n result } {
    i n prim < [
      i is-prime [
        result i prim seq-int.push locals { new_result } {
          i 1 prim + n new_result collect-primes
        }
      ] [
        i 1 prim + n result collect-primes
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty collect-primes
  };
```

### task: histogram
```firth
: histogram-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many k:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs k counts } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at locals { curr_count } {
          counts v curr_count 1 prim + prim seq-int.set locals { new_counts } {
            i 1 prim + xs k new_counts histogram-loop
          }
        }
      }
    ] [
      counts
    ] if
  };

: make-histogram
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i counts } {
    i k prim < [
      counts 0 prim seq-int.push locals { new_counts } {
        k i 1 prim + new_counts make-histogram
      }
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty make-histogram locals { initial_counts } {
      0 xs k initial_counts histogram-loop
    }
  };
```

### task: sort
```firth
: insert
  (forall ρ; ρ val:Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { val i result } {
    i 0 prim = [
      result val prim seq-int.push
    ] [
      result i 1 prim - prim seq-int.at locals { curr } {
        curr val prim < [
          result val prim seq-int.push
        ] [
          i 1 prim - val result insert
        ] if
      }
    ] if
  };

: sort-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        result prim seq-int.len locals { len } {
          len val result insert locals { new_result } {
            i 1 prim + xs new_result sort-loop
          }
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    0 xs prim seq-int.empty sort-loop
  };
```

### task: ledger
```firth
: process-txs
  (forall ρ; ρ i:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many -- ρ balance_final:Int^many rejected_final:Int^many)
  locals { i txs balance rejected } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim < [
          i 1 prim + txs balance rejected 1 prim + process-txs
        ] [
          i 1 prim + txs balance tx prim + rejected process-txs
        ] if
      }
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    0 txs start 0 process-txs
  };
```

### task: allocate-batch
```firth
: allocate-one
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock_final:Seq Int^many allocated_final:Seq Int^many reasons_final:Seq Int^many)
  locals { stock items qtys whole j allocated reasons } {
    j qtys prim seq-int.len prim < [
      items j prim seq-int.at locals { item_idx } {
        qtys j prim seq-int.at locals { qty } {
          stock item_idx prim seq-int.at locals { r } {
            whole j prim seq-bool.at [
              qty r prim < [
                stock item_idx r qty prim - prim seq-int.set locals { new_stock } {
                  allocated qty prim seq-int.push locals { new_allocated } {
                    reasons 1 prim seq-int.push locals { new_reasons } {
                      new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                    }
                  }
                }
              ] [
                qty r prim = [
                  stock item_idx 0 prim seq-int.set locals { new_stock } {
                    allocated qty prim seq-int.push locals { new_allocated } {
                      reasons 0 prim seq-int.push locals { new_reasons } {
                        new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  }
                ] [
                  r 0 prim = [
                    allocated 0 prim seq-int.push locals { new_allocated } {
                      reasons 2 prim seq-int.push locals { new_reasons } {
                        stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  ] [
                    allocated 0 prim seq-int.push locals { new_allocated } {
                      reasons 3 prim seq-int.push locals { new_reasons } {
                        stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  ] if
                ] if
              ] if
            ] [
              qty r prim < [
                stock item_idx r qty prim - prim seq-int.set locals { new_stock } {
                  allocated qty prim seq-int.push locals { new_allocated } {
                    reasons 0 prim seq-int.push locals { new_reasons } {
                      new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                    }
                  }
                }
              ] [
                r 0 prim = [
                  allocated 0 prim seq-int.push locals { new_allocated } {
                    reasons 2 prim seq-int.push locals { new_reasons } {
                      stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                    }
                  }
                ] [
                  stock item_idx 0 prim seq-int.set locals { new_stock } {
                    allocated r prim seq-int.push locals { new_allocated } {
                      reasons 1 prim seq-int.push locals { new_reasons } {
                        new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  }
                ] if
              ] if
            ] if
          }
        }
      }
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_final:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-one
  };
```
