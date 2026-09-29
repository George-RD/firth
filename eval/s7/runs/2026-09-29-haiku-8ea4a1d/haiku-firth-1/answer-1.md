### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 [ xs ] locals { xs } {
    xs prim seq-int.len 0 [ drop ] [
      0 dup [ xs prim seq-int.len ] [
        locals { acc i } {
          [ i xs prim seq-int.at prim + ] locals { xs i acc } {
            acc xs i prim seq-int.at prim +
            i 1 prim +
            [ xs ] [ i ] [ acc ] compose
          } call
        } call
      ] compose
    ] if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at xs prim seq-int.len 1 [
      locals { xs max i } {
        xs i prim seq-int.at dup max prim < [ drop max ] [ swap drop ] if
        i 1 prim +
        [ xs ] [ max ] [ i ] compose
      }
    ] if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 xs prim seq-int.len [
      locals { xs k count i } {
        xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if
        i 1 prim +
        [ xs ] [ k ] [ count ] [ i ] compose
      }
    ] if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    -1 xs prim seq-int.len dup 0 prim = [
      drop
    ] [
      0 [
        locals { xs x idx i found } {
          found prim not [ xs i prim seq-int.at x prim = ] [ ] if [ idx ] [ i 1 prim + [ xs ] [ x ] [ i ] compose ] if
        }
      ] if
    ] if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len [
      locals { xs rev i } {
        xs i prim seq-int.at rev prim seq-int.push
        i 1 prim + [ xs ] [ rev ] [ i ] compose
      }
    ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs prim seq-int.len [
      locals { xs result sum i } {
        sum xs i prim seq-int.at prim +
        result sum prim seq-int.push
        i 1 prim + [ xs ] [ result ] [ sum ] [ i ] compose
      }
    ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len [
      locals { xs result i } {
        xs i prim seq-int.at dup 0 prim < [ drop result ] [ result prim seq-int.push ] if
        i 1 prim + [ xs ] [ result ] [ i ] compose
      }
    ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [ true ] [
      true xs prim seq-int.len 1 prim - [
        locals { xs sorted i } {
          sorted xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not prim and
          i 1 prim + [ xs ] [ sorted ] [ i ] compose
        }
      ] if
    ] if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 xs prim seq-int.len [
      locals { xs ys sum i } {
        sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
        i 1 prim + [ xs ] [ ys ] [ sum ] [ i ] compose
      }
    ] if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true flags prim seq-int.len [
      locals { flags all i } {
        all flags i prim seq-int.at prim and
        i 1 prim + [ flags ] [ all ] [ i ] compose
      }
    ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [ 0 ] [
      1 xs 0 prim seq-int.at 1 xs prim seq-int.len [
        locals { xs maxrun current lastval i } {
          xs i prim seq-int.at dup lastval prim = [ drop current 1 prim + ] [ swap drop 1 ] if
          dup maxrun prim < [ drop maxrun ] [ ] if
          i 1 prim + [ xs ] [ maxrun ] [ current ] [ lastval ] [ i ] compose
        }
      ] if
    ] if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false xs prim seq-int.len xs prim seq-int.len [
      locals { xs target found i j } {
        found prim not [ j xs prim seq-int.len prim < ] [ ] if [
          xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ found ] if
          j 1 prim +
        ] [ found i 1 prim + ] if [ xs ] [ target ] [ found ] [ i ] [ j ] compose
      }
    ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 xs prim seq-int.len [
      locals { xs count i } {
        prim seq-int.empty i [
          locals { xs seen j } {
            xs i prim seq-int.at xs j prim seq-int.at prim = [ true ] [ seen j 1 prim + ] if
            j 1 prim +
          }
        ] if [ count 1 prim + ] [ count ] if
        i 1 prim + [ xs ] [ count ] [ i ] compose
      }
    ] if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len [
      locals { xs ys result i j } {
        i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [
          xs i prim seq-int.at ys j prim seq-int.at prim < [
            result xs i prim seq-int.at prim seq-int.push
            i 1 prim +
          ] [
            result ys j prim seq-int.at prim seq-int.push
            j 1 prim +
          ] if
        ] [
          i xs prim seq-int.len prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + ] [ result ] if
          j ys prim seq-int.len prim < [ ys j prim seq-int.at result prim seq-int.push j 1 prim + ] [ result ] if
        ] if [ xs ] [ ys ] [ result ] [ i ] [ j ] compose
      }
    ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [ { 0 } ] [
      prim seq-int.empty n [
        locals { n result } {
          n 10 prim mod result prim seq-int.push
          n 10 prim div [ result ] [ n ] compose
        }
      ] if
    ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n [
      locals { n result candidate } {
        candidate prim seq-int.empty 2 candidate [
          locals { candidate divisor } {
            candidate divisor prim mod 0 prim = [ true ] [ divisor 1 prim + [ candidate ] compose ] if
          }
        ] if prim not [ result candidate prim seq-int.push ] [ result ] if
        candidate 1 prim + [ n ] [ result ] [ candidate ] compose
      }
    ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k 0 [
      locals { xs k counts i } {
        counts 0 prim seq-int.push
        i 1 prim +
      }
    ] if xs prim seq-int.len [
      locals { xs k counts i j } {
        xs j prim seq-int.at counts xs j prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
        j 1 prim + [ xs ] [ k ] [ counts ] [ i ] [ j ] compose
      }
    ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 0 [
      locals { xs sorted i j } {
        j i 1 prim + xs prim seq-int.len [
          locals { xs sorted i j } {
            sorted i prim seq-int.at sorted j prim seq-int.at prim < [
              sorted i prim seq-int.at sorted j prim seq-int.at sorted i prim seq-int.set sorted j prim seq-int.at sorted j prim seq-int.set
            ] [ sorted ]
            if j 1 prim +
          }
        ] if i 1 prim + [ xs ] [ sorted ] [ i ] [ j ] compose
      }
    ] if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 txs prim seq-int.len [
      locals { start txs balance rejected i } {
        txs i prim seq-int.at dup balance prim + dup 0 prim < [
          drop drop balance rejected 1 prim +
        ] [
          swap drop balance prim +
          i 1 prim +
        ] if [ start ] [ txs ] [ balance ] [ rejected ] [ i ] compose
      }
    ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len [
      locals { stock items qtys whole stock-left allocated reasons j } {
        items j prim seq-int.at locals { stock items qtys whole stock-left allocated reasons j item } {
          stock-left item prim seq-int.at locals { stock items qtys whole stock-left allocated reasons j item cur } {
            qtys j prim seq-int.at cur prim < [
              allocated qtys j prim seq-int.at prim seq-int.push
              reasons 0 prim seq-int.push
              stock-left item qtys j prim seq-int.at prim seq-int.set
            ] [
              cur 0 prim = [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ] [
                whole j prim seq-int.at [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ] [
                  allocated cur prim seq-int.push
                  reasons 1 prim seq-int.push
                  stock-left item 0 prim seq-int.set
                ] if
              ] if
            ] if j 1 prim +
          }
        } [ stock ] [ items ] [ qtys ] [ whole ] [ stock-left ] [ allocated ] [ reasons ] [ j ] compose
      }
    ] if
  };
```
