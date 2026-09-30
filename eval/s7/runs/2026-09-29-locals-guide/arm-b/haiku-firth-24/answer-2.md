### task: index-of
```firth
: index-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs i len x } {
    i len prim = [
      0 1 prim -
    ] [
      xs i prim seq-int.at locals { val } {
        val x prim = [
          i
        ] [
          xs i 1 prim + len x index-loop
        ] if
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs 0 xs prim seq-int.len x index-loop
  };
```

### task: keep-positive
```firth
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { xs i len result } {
    i len prim = [
      result
    ] [
      xs i prim seq-int.at locals { val } {
        0 val prim < [
          xs i 1 prim + len result val prim seq-int.push keep-loop
        ] [
          xs i 1 prim + len result keep-loop
        ] if
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len prim seq-int.empty keep-loop
  };
```

### task: is-sorted
```firth
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs i len } {
    i 1 prim - len prim = [
      true
    ] [
      xs i prim seq-int.at locals { val } {
        xs i 1 prim - prim seq-int.at locals { prev } {
          val prev prim < [
            false
          ] [
            xs i 1 prim + len sorted-loop
          ] if
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 1 xs prim seq-int.len sorted-loop
  };
```

### task: count-distinct
```firth
: check-earlier
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs val j } {
    j 0 prim = [
      true
    ] [
      xs j 1 prim - prim seq-int.at val prim = [
        false
      ] [
        xs val j 1 prim - check-earlier
      ] if
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs i len cnt } {
    i len prim = [
      cnt
    ] [
      xs i prim seq-int.at locals { val } {
        xs val i check-earlier [
          xs i 1 prim + len cnt 1 prim + count-loop
        ] [
          xs i 1 prim + len cnt count-loop
        ] if
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len 0 count-loop
  };
```

### task: digits
```firth
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { d } {
        result d prim seq-int.push locals { new-result } {
          n 10 prim div new-result digits-loop
        }
      }
    ] if
  };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { xs i result } {
    i 0 prim = [
      result
    ] [
      xs i 1 prim - prim seq-int.at locals { val } {
        result val prim seq-int.push locals { new-result } {
          xs i 1 prim - new-result reverse-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n prim seq-int.empty digits-loop locals { digits } {
        digits digits prim seq-int.len reverse-loop
      }
    ] if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ p:Int^many i:Int^many -- ρ result:Bool^many)
  locals { p i } {
    i i prim * p prim < [
      p i prim mod 0 prim = [
        false
      ] [
        p i 1 prim + is-prime
      ] if
    ] [
      true
    ] if
  };

: check-prime
  (forall ρ; ρ p:Int^many -- ρ result:Bool^many)
  locals { p } {
    p 2 prim < [
      false
    ] [
      p 2 is-prime
    ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { n i result } {
    i n prim < [
      i check-prime [
        n i 1 prim + result i prim seq-int.push primes-loop
      ] [
        n i 1 prim + result primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty primes-loop
  };
```

### task: histogram
```firth
: init-histogram
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { k i result } {
    i k prim = [
      result
    ] [
      result 0 prim seq-int.push locals { new-result } {
        k i 1 prim + new-result init-histogram
      }
    ] if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many counts:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { xs i len counts } {
    i len prim = [
      counts
    ] [
      xs i prim seq-int.at locals { val } {
        counts val prim seq-int.at locals { cnt } {
          counts val cnt 1 prim + prim seq-int.set locals { new-counts } {
            xs i 1 prim + len new-counts histogram-loop
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty locals { init-counts } {
      xs 0 xs prim seq-int.len init-counts histogram-loop
    }
  };
```

### task: sort
```firth
: insert-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { xs i val } {
    i 0 prim = [
      xs 0 val prim seq-int.set
    ] [
      xs i 1 prim - prim seq-int.at locals { prev } {
        val prev prim < [
          xs i 1 prim - xs i prim seq-int.at prim seq-int.set locals { xs2 } {
            xs2 i 1 prim - val insert-loop
          }
        ] [
          xs i val prim seq-int.set
        ] if
      }
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len prim = [
      xs
    ] [
      xs i prim seq-int.at locals { val } {
        xs i val insert-loop locals { xs2 } {
          xs2 i 1 prim + len sort-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 1 xs prim seq-int.len sort-loop
  };
```

### task: allocate-batch
```firth
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many len:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-final:Seq Int^many allocated-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock items qtys whole i len allocated reasons } {
    i len prim = [
      stock allocated reasons
    ] [
      items i prim seq-int.at locals { item } {
        qtys i prim seq-int.at locals { qty } {
          whole i prim seq-bool.at locals { whole-flag } {
            stock item prim seq-int.at locals { avail } {
              qty avail prim < [
                stock item qty prim seq-int.set locals { stock2 } {
                  stock2 items qtys whole i 1 prim + len allocated qty prim seq-int.push reasons 0 prim seq-int.push allocate-loop
                }
              ] [
                avail 0 prim = [
                  stock items qtys whole i 1 prim + len allocated 0 prim seq-int.push reasons 2 prim seq-int.push allocate-loop
                ] [
                  whole-flag [
                    stock items qtys whole i 1 prim + len allocated 0 prim seq-int.push reasons 3 prim seq-int.push allocate-loop
                  ] [
                    stock item 0 prim seq-int.set locals { stock2 } {
                      stock2 items qtys whole i 1 prim + len allocated avail prim seq-int.push reasons 1 prim seq-int.push allocate-loop
                    }
                  ] if
                ] if
              ] if
            }
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 qtys prim seq-int.len prim seq-int.empty prim seq-int.empty allocate-loop
  };
```
