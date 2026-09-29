### task: reverse
```firth
: rev-help
  (forall ρ; ρ i:Int^many n:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i n xs result } {
    i n prim < [
      n i prim - 1 prim - locals { idx } {
        xs idx prim seq-int.at locals { val } {
          result val prim seq-int.push locals { new-result } {
            i 1 prim + n xs new-result rev-help
          }
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    0 xs prim seq-int.len xs prim seq-int.empty rev-help
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
          val 0 prim = [
            i 1 prim + xs result keep-loop
          ] [
            result val prim seq-int.push locals { new-result } {
              i 1 prim + xs new-result keep-loop
            }
          ] if
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

### task: longest-run
```firth
: count-run
  (forall ρ; ρ i:Int^many xs:Seq Int^many curr-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { i xs curr-len max-len } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at locals { curr } {
        xs i 1 prim + prim seq-int.at locals { next } {
          curr next prim = [
            curr-len 1 prim + locals { new-curr-len } {
              i 1 prim + xs new-curr-len max-len count-run
            }
          ] [
            curr-len max-len prim < [
              max-len
            ] [
              curr-len
            ] if locals { new-max-len } {
              i 1 prim + xs 1 new-max-len count-run
            }
          ] if
        }
      }
    ] [
      curr-len max-len prim < [
        max-len
      ] [
        curr-len
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
: check-pairs
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i j xs target } {
    j xs prim seq-int.len prim < [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [
        true
      ] [
        j 1 prim + xs prim seq-int.len prim < [
          i j 1 prim + xs target check-pairs
        ] [
          i 1 prim + i 2 prim + xs prim seq-int.len prim < [
            i 1 prim + i 2 prim + xs target check-pairs
          ] [
            false
          ] if
        ] if
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0 1 xs target check-pairs
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
        n 10 prim div locals { n-div } {
          result d prim seq-int.push locals { new-result } {
            n-div new-result digits-loop
          }
        }
      }
    ] if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many len:Int^many digits-seq:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i len digits-seq result } {
    i len prim < [
      len i prim - 1 prim - locals { idx } {
        digits-seq idx prim seq-int.at locals { d } {
          result d prim seq-int.push locals { new-result } {
            i 1 prim + len digits-seq new-result reverse-digits
          }
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
      n prim seq-int.empty digits-loop locals { raw-digits } {
        0 raw-digits prim seq-int.len raw-digits prim seq-int.empty reverse-digits
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
      d d prim * n prim = [
        false
      ] [
        true
      ] if
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
        result i prim seq-int.push locals { new-result } {
          i 1 prim + n new-result collect-primes
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
          curr val prim = [
            result val prim seq-int.push
          ] [
            i 1 prim - val result insert
          ] if
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
          len val result insert locals { new-result } {
            i 1 prim + xs new-result sort-loop
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
