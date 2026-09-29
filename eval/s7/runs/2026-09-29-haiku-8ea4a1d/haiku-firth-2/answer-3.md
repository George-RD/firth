### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 1 xs 0 prim seq-int.at max-loop
  };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          max val prim < [
            xs i 1 prim + val max-loop
          ] [
            xs i 1 prim + max max-loop
          ] if
        }
      ] [ max ] if
    }
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - rev-loop
  };

: rev-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result
    ] [
      xs i prim seq-int.at locals { val } {
        result val prim seq-int.push xs i 1 prim - rev-loop
      }
    ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs 0 prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result sum xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          sum val prim + locals { newsum } {
            result newsum prim seq-int.push newsum xs i 1 prim + prefix-loop
          }
        }
      ] [ result ] if
    }
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 keep-loop
  };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          val 0 prim < [
            result xs i 1 prim + keep-loop
          ] [
            result val prim seq-int.push xs i 1 prim + keep-loop
          ] if
        }
      ] [ result ] if
    }
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 1 prim < [ true ] [ xs 1 check-sorted ] if
    }
  };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i 1 prim - prim seq-int.at locals { prev } {
          xs i prim seq-int.at locals { curr } {
            prev curr prim < [
              xs i 1 prim + check-sorted
            ] [
              prev curr prim = [
                xs i 1 prim + check-sorted
              ] [
                false
              ] if
            ] if
          }
        }
      ] [ true ] if
    }
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 0 prim < [ 0 ] [ xs xs 0 prim seq-int.at 1 1 1 longest-run-loop ] if
    }
  };

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many cur-run:Int^many max-run:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs prev cur-run max-run i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          val prev prim = [
            cur-run 1 prim + locals { newrun } {
              max-run newrun prim < [
                xs prev newrun newrun i 1 prim + longest-run-loop
              ] [
                xs prev newrun max-run i 1 prim + longest-run-loop
              ] if
            }
          ] [
            cur-run 1 prim + locals { newrun } {
              max-run newrun prim < [
                xs val newrun newrun i 1 prim + longest-run-loop
              ] [
                xs val newrun max-run i 1 prim + longest-run-loop
              ] if
            }
          ] if
        }
      ] [
        max-run cur-run prim < [ cur-run ] [ max-run ] if
      ] if
    }
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 has-pair-loop
  };

: has-pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { x } {
          xs target x i 1 prim + check-pair
        }
      ] [ false ] if
    }
  };

: check-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many x:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target x j } {
    xs prim seq-int.len locals { len } {
      j len prim < [
        xs j prim seq-int.at locals { y } {
          x y prim + target prim = [ true ] [ xs target x j 1 prim + check-pair ] if
        }
      ] [ xs target j 1 prim + has-pair-loop ] if
    }
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 xs 0 count-dist-loop
  };

: count-dist-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          xs val i check-seen-before [
            count xs i 1 prim + count-dist-loop
          ] [
            count 1 prim + xs i 1 prim + count-dist-loop
          ] if
        }
      ] [ count ] if
    }
  };

: check-seen-before
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs val j } {
    j 0 prim < [ false ] [ xs j 1 prim - prim seq-int.at locals { x } { x val prim = [ true ] [ xs val j 1 prim - check-seen-before ] if } ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty digits-loop
    ] if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { d } {
        result d prim seq-int.push n 10 prim div digits-loop
      }
    ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n check-primes-up
  };

: check-primes-up
  (forall ρ; ρ result:Seq Int^many p:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result p n } {
    p n prim < [
      p is-prime [
        result p prim seq-int.push p 1 prim + n check-primes-up
      ] [
        result p 1 prim + n check-primes-up
      ] if
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ p:Int^many -- ρ result:Bool^many)
  locals { p } {
    p 2 prim < [ false ] [ p 2 check-prime-divisor ] if
  };

: check-prime-divisor
  (forall ρ; ρ p:Int^many d:Int^many -- ρ result:Bool^many)
  locals { p d } {
    d d prim * p prim < [
      p d prim mod 0 prim = [
        false
      ] [
        p d 1 prim + check-prime-divisor
      ] if
    ] [ true ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 insertion-sort
  };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { v } {
          xs i v find-insert-pos
        }
      ] [ xs ] if
    }
  };

: find-insert-pos
  (forall ρ; ρ xs:Seq Int^many j:Int^many v:Int^many -- ρ sorted:Seq Int^many)
  locals { xs j v } {
    j 0 prim < [
      xs v 0 prim seq-int.set xs 1 insertion-sort
    ] [
      xs j 1 prim - prim seq-int.at locals { prev } {
        prev v prim < [
          xs v j prim seq-int.set xs j 1 prim + insertion-sort
        ] [
          xs j 1 prim - find-insert-pos
        ] if
      }
    ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole i } {
    items prim seq-int.len locals { len } {
      i len prim < [
        items i prim seq-int.at locals { item } {
          qtys i prim seq-int.at locals { qty } {
            whole i prim seq-bool.at locals { w } {
              stock item prim seq-int.at locals { r } {
                qty r prim < [
                  stock item qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                ] [
                  r 0 prim = [
                    stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                  ] [
                    w [
                      stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                    ] [
                      stock item 0 prim seq-int.set allocated r prim seq-int.push reasons 1 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                    ] if
                  ] if
                ] if
              }
            }
          }
        }
      ] [ stock allocated reasons ] if
    }
  };
```
