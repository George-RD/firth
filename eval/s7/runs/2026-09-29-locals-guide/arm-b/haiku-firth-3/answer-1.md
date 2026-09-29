### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    xs prim seq-int.len locals { len } {
      i len prim = [ acc ] [ xs i prim seq-int.at locals { val } { xs i 1 prim + acc val prim + loop } ] if
    }
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at locals { max } {
      xs max 1 loop
    }
  };

: loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs max i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ max ] [ xs i prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if xs i 1 prim + loop } ] if
    }
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k i cnt } {
    xs prim seq-int.len locals { len } {
      i len prim = [ cnt ] [ xs i prim seq-int.at locals { val } { val k prim < [ cnt 1 prim + ] [ cnt ] if xs i 1 prim + loop } ] if
    }
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ -1 ] [ xs i prim seq-int.at locals { val } { val x prim = [ i ] [ xs x i 1 prim + loop ] if } ] if
    }
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len loop };

: loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim = [ result ] [ xs i 1 prim - prim seq-int.at locals { val } { result val prim seq-int.push i 1 prim - loop } ] if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 loop };

: loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ result ] [ xs i prim seq-int.at locals { val } { sum val prim + locals { newsum } { result newsum prim seq-int.push xs newsum i 1 prim + loop } } ] if
    }
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 loop };

: loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ result ] [ xs i prim seq-int.at locals { val } { val 0 prim < [ result xs i 1 prim + loop ] [ result val prim seq-int.push xs i 1 prim + loop ] if } ] if
    }
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim = [ true ] [ xs 0 true loop ] if } };

: loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many ok:Bool^many -- ρ result:Bool^many)
  locals { xs i ok } {
    ok [ xs prim seq-int.len 1 prim - locals { last } { i last prim = [ true ] [ xs i prim seq-int.at locals { a } { xs i 1 prim + prim seq-int.at locals { b } { a b prim < [ xs i 1 prim + loop ] [ false ] if } } ] if } ] ] [ false ] if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 xs ys 0 loop };

: loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs ys i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ acc ] [ xs i prim seq-int.at locals { x } { ys i prim seq-int.at locals { y } { x y prim * locals { prod } { acc prod prim + xs ys i 1 prim + loop } } } ] if
    }
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-bool.len locals { len } { len 0 prim = [ true ] [ flags 0 true loop ] if } };

: loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many ok:Bool^many -- ρ result:Bool^many)
  locals { flags i ok } {
    ok [ flags prim seq-bool.len locals { len } { i len prim = [ true ] [ flags i prim seq-bool.at [ flags i 1 prim + loop ] [ false ] if ] if } ] ] [ false ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim = [ 0 ] [ 0 xs 0 1 loop ] if } };

: loop
  (forall ρ; ρ maxlen:Int^many xs:Seq Int^many i:Int^many runlen:Int^many -- ρ result:Int^many)
  locals { maxlen xs i runlen } {
    xs prim seq-int.len locals { len } {
      i len prim = [ maxlen runlen prim < [ runlen ] [ maxlen ] if ] [ xs i prim seq-int.at locals { val } { xs i 1 prim + prim seq-int.at locals { next } { val next prim = [ xs i 1 prim + runlen 1 prim + loop ] [ maxlen runlen prim < [ runlen ] [ maxlen ] if xs i 1 prim + 1 loop ] if } } ] if
    }
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ false ] [ xs i prim seq-int.at locals { x } { xs target x prim - i inner-loop } ] if
    }
  };

: inner-loop
  (forall ρ; ρ xs:Seq Int^many needed:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs needed i } {
    xs prim seq-int.len locals { len } {
      i 1 prim + locals { j } {
        j len prim = [ xs needed i 1 prim + loop ] [ xs j prim seq-int.at locals { y } { y needed prim = [ true ] [ xs needed i inner-loop ] if } ] if
      }
    }
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty xs 0 loop };

: loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { seen xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ seen prim seq-int.len ] [ xs i prim seq-int.at locals { val } { val seen 0 find-in-seq [ seen val prim seq-int.push xs i 1 prim + loop ] [ xs i 1 prim + loop ] if } ] if
    }
  };

: find-in-seq
  (forall ρ; ρ val:Int^many seen:Seq Int^many i:Int^many -- ρ found:Bool^many)
  locals { val seen i } {
    seen prim seq-int.len locals { len } {
      i len prim = [ false ] [ seen i prim seq-int.at locals { x } { x val prim = [ true ] [ val seen i 1 prim + find-in-seq ] if } ] if
    }
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs 0 ys 0 loop };

: loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many xi:Int^many ys:Seq Int^many yi:Int^many -- ρ final:Seq Int^many)
  locals { result xs xi ys yi } {
    xs prim seq-int.len locals { xlen } {
      ys prim seq-int.len locals { ylen } {
        xi xlen prim = [ result ys yi append-rest ] [
          yi ylen prim = [ result xs xi append-rest ] [
            xs xi prim seq-int.at locals { xval } {
              ys yi prim seq-int.at locals { yval } {
                xval yval prim < [ result xval prim seq-int.push xs xi 1 prim + ys yi loop ] [ result yval prim seq-int.push xs xi ys yi 1 prim + loop ] if
              }
            }
          ] if
        ] if
      }
    }
  };

: append-rest
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result seq i } {
    seq prim seq-int.len locals { len } {
      i len prim = [ result ] [ result seq i prim seq-int.at prim seq-int.push seq i 1 prim + append-rest ] if
    }
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n digit-loop ] if };

: digit-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim = [ result ] [ n 10 prim mod locals { d } { result d prim seq-int.push n 10 prim div digit-loop } ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim < [ prim seq-int.empty ] [ prim seq-int.empty 2 n loop ] if };

: loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result i n } {
    i n prim = [ result ] [ i is-prime [ result i prim seq-int.push i 1 prim + n loop ] [ i 1 prim + n loop ] if ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [ n 2 prim = [ true ] [ n 2 check-prime ] if ] if
  };

: check-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ prime:Bool^many)
  locals { n i } {
    i i prim * locals { isq } {
      isq n prim < [ n i prim mod 0 prim = [ false ] [ n i 2 prim + check-prime ] if ] [ true ] if
    }
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 prim seq-int.empty k init-histogram xs 0 loop };

: init-histogram
  (forall ρ; ρ i:Int^many counts:Seq Int^many k:Int^many -- ρ initialized:Seq Int^many)
  locals { i counts k } {
    i k prim = [ counts ] [ counts 0 prim seq-int.push i 1 prim + k init-histogram ] if
  };

: loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ counts ] [ xs i prim seq-int.at locals { val } { counts val prim seq-int.at locals { cnt } { counts val cnt 1 prim + prim seq-int.set xs i 1 prim + loop } } ] if
    }
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ xs ] [ xs i insert-sort ] if
    }
  };

: insert-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i 0 prim = [ xs i 1 prim + loop ] [ xs i prim seq-int.at locals { x } { xs i 1 prim - prim seq-int.at locals { y } { x y prim < [ xs i 1 prim - x prim seq-int.set xs i 1 prim - loop ] [ xs i 1 prim + loop ] if } } ] if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 loop };

: loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    txs prim seq-int.len locals { len } {
      i len prim = [ balance rejected ] [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { newbal } { newbal 0 prim < [ balance rejected 1 prim + txs i 1 prim + loop ] [ newbal rejected txs i 1 prim + loop ] if } } ] if
    }
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 loop };

: loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    items prim seq-int.len locals { len } {
      i len prim = [ stock allocated reasons ] [
        items i prim seq-int.at locals { item } {
          stock item prim seq-int.at locals { r } {
            qtys i prim seq-int.at locals { q } {
              whole i prim seq-bool.at locals { w } {
                q r prim < [ stock allocated q prim seq-int.push reasons 0 prim seq-int.push item r prim seq-int.set i 1 prim + loop ] [
                  r 0 prim = [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push i 1 prim + loop ] [
                    w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push i 1 prim + loop ] [
                      stock allocated r prim seq-int.push reasons 1 prim seq-int.push item 0 prim seq-int.set i 1 prim + loop
                    ] if
                  ] if
                ] if
              }
            }
          }
        }
      ] if
    }
  };
```
