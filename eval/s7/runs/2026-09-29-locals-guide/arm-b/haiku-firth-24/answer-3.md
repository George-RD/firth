### task: is-sorted
```firth
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs i len } {
    i len prim = [
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
    xs prim seq-int.len locals { len } {
      len 1 prim < [
        true
      ] [
        xs 1 len sorted-loop
      ] if
    }
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
        digits digits prim seq-int.len prim seq-int.empty reverse-loop
      }
    ] if
  };
```

### task: primes-up-to
```firth
: is-prime
  (forall ρ; ρ p:Int^many i:Int^many -- ρ result:Bool^many)
  locals { p i } {
    p i i prim * prim < [
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
    k 0 prim seq-int.empty init-histogram locals { init-counts } {
      xs 0 xs prim seq-int.len init-counts histogram-loop
    }
  };
```

### task: sort
```firth
: find-min-index
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many min-idx:Int^many min-val:Int^many -- ρ result-idx:Int^many)
  locals { xs i len min-idx min-val } {
    i len prim = [
      min-idx
    ] [
      xs i prim seq-int.at locals { val } {
        val min-val prim < [
          xs i 1 prim + len i val find-min-index
        ] [
          xs i 1 prim + len min-idx min-val find-min-index
        ] if
      }
    ] if
  };

: selection-sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len prim = [
      xs
    ] [
      xs i len xs i prim seq-int.at find-min-index locals { min-idx } {
        xs i prim seq-int.at locals { elem-i } {
          xs min-idx prim seq-int.at locals { elem-min } {
            xs i elem-min prim seq-int.set locals { xs2 } {
              xs2 min-idx elem-i prim seq-int.set locals { xs3 } {
                xs3 i 1 prim + len selection-sort-loop
              }
            }
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len selection-sort-loop
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
                stock item prim seq-int.at locals { current } {
                  current qty prim - locals { new-val } {
                    stock item new-val prim seq-int.set locals { stock2 } {
                      stock2 items qtys whole i 1 prim + len allocated qty prim seq-int.push reasons 0 prim seq-int.push allocate-loop
                    }
                  }
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
