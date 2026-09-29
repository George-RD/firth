### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ rev:Seq Int)
  locals { xs i result } {
    i 0 prim < [
      result
    ] [
      xs i prim seq-int.at locals { elem } {
        result elem prim seq-int.push locals { new-result } {
          xs i 1 prim - new-result reverse-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ reversed:Seq Int)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };
```

### task: keep-positive
```firth
: filter-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ positives:Seq Int)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { curr } {
      0 curr prim < [ result curr prim seq-int.push ] [ result ] if locals { new-result } {
        xs i 1 prim + new-result filter-loop
      }
    } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ positives:Seq Int)
  locals { xs } {
    xs 0 prim seq-int.empty filter-loop
  };
```

### task: is-sorted
```firth
: sorted-loop
  (forall ρ; ρ xs:Seq Int i:Int -- ρ result:Bool)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i 1 prim + prim seq-int.at xs i prim seq-int.at prim < [
        0 0 prim <
      ] [
        xs i 1 prim + sorted-loop
      ] if
    ] [
      0 0 prim =
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ sorted:Bool)
  locals { xs } {
    1 xs prim seq-int.len prim < [ xs 0 sorted-loop ] [ 0 0 prim = ] if
  };
```

### task: longest-run
```firth
: run-loop
  (forall ρ; ρ xs:Seq Int i:Int curr-val:Int curr-run:Int max-run:Int -- ρ length:Int)
  locals { xs i curr-val curr-run max-run } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { curr } {
      curr curr-val prim = [
        xs i 1 prim + curr-val curr-run 1 prim + max-run run-loop
      ] [
        curr-run max-run prim < [
          xs i 1 prim + curr 1 max-run run-loop
        ] [
          xs i 1 prim + curr 1 curr-run run-loop
        ] if
      ] if
    } ]
    [ curr-run max-run prim < [ max-run ] [ curr-run ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ length:Int)
  locals { xs } {
    xs prim seq-int.len 0 prim = [ 0 ] [ xs 1 xs 0 prim seq-int.at 1 0 run-loop ] if
  };
```

### task: primes-up-to
```firth
: mark-multiples
  (forall ρ; ρ sieve:Seq Bool p:Int j:Int n:Int -- ρ result:Seq Bool)
  locals { sieve p j n } {
    j n prim < [
      sieve j 0 prim seq-bool.set locals { new-sieve } {
        new-sieve p j p prim + n mark-multiples
      }
    ] [
      sieve
    ] if
  };

: sieve-main
  (forall ρ; ρ sieve:Seq Bool p:Int n:Int -- ρ result:Seq Bool)
  locals { sieve p n } {
    n p p prim * prim < [
      sieve
    ] [
      sieve p prim seq-bool.at [
        sieve p p p prim * n mark-multiples locals { new-sieve } {
          new-sieve p 1 prim + n sieve-main
        }
      ] [
        sieve p 1 prim + n sieve-main
      ] if
    ] if
  };

: collect-primes
  (forall ρ; ρ sieve:Seq Bool i:Int n:Int result:Seq Int -- ρ primes:Seq Int)
  locals { sieve i n result } {
    n i prim < [
      result
    ] [
      sieve i prim seq-bool.at [
        result i prim seq-int.push locals { new-result } {
          sieve i 1 prim + n new-result collect-primes
        }
      ] [
        sieve i 1 prim + n result collect-primes
      ] if
    ] if
  };

: main
  (forall ρ; ρ n:Int -- ρ primes:Seq Int)
  locals { n } {
    n 2 prim < [
      prim seq-int.empty
    ] [
      n 1 prim + 0 [ 0 0 prim = ] [ 0 0 prim < ] if prim seq-bool.push locals { sieve } {
        sieve 2 n sieve-main locals { marked } {
          marked 2 n prim seq-int.empty collect-primes
        }
      }
    ] if
  };
```

### task: sort
```firth
: insert-loop
  (forall ρ; ρ sorted:Seq Int i:Int val:Int -- ρ result:Seq Int)
  locals { sorted i val } {
    i sorted prim seq-int.len prim < [
      sorted i prim seq-int.at val prim < [
        sorted i val prim seq-int.set locals { new-sorted } {
          new-sorted val i 1 prim + insert-loop
        }
      ] [
        sorted i 1 prim + locals { new-i } {
          sorted new-i val insert-loop
        }
      ] if
    ] [
      sorted val prim seq-int.push
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int i:Int sorted:Seq Int -- ρ result:Seq Int)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { val } {
        sorted 0 val insert-loop locals { new-sorted } {
          xs i 1 prim + new-sorted sort-loop
        }
      }
    ] [
      sorted
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ sorted:Seq Int)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };
```

### task: allocate-batch
```firth
: allocate-loop
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool j:Int allocated:Seq Int reasons:Seq Int -- ρ result-stock:Seq Int alloc:Seq Int result-reasons:Seq Int)
  locals { stock items qtys whole j allocated reasons } {
    j items prim seq-int.len prim <
    [ items j prim seq-int.at locals { item } {
      stock item prim seq-int.at locals { r } {
        qtys j prim seq-int.at locals { q } {
          q r prim <= [
            stock item r q prim - prim seq-int.set locals { ns } {
              ns items qtys whole j 1 prim + allocated q prim seq-int.push reasons 0 prim seq-int.push allocate-loop
            }
          ] [
            r 0 prim = [
              stock items qtys whole j 1 prim + allocated 0 prim seq-int.push reasons 2 prim seq-int.push allocate-loop
            ] [
              whole j prim seq-bool.at [
                stock items qtys whole j 1 prim + allocated 0 prim seq-int.push reasons 3 prim seq-int.push allocate-loop
              ] [
                stock item 0 prim seq-int.set locals { ns } {
                  ns items qtys whole j 1 prim + allocated r prim seq-int.push reasons 1 prim seq-int.push allocate-loop
                }
              ] if
            ] if
          ] if
        }
      }
    } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool -- ρ result-stock:Seq Int alloc:Seq Int result-reasons:Seq Int)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };
```
