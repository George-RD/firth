### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k i cnt } {
    xs prim seq-int.len locals { len } {
      i len prim = [ cnt ] [ xs i prim seq-int.at locals { val } { val k prim < [ cnt 1 prim + ] [ cnt ] if locals { newcnt } { xs k i 1 prim + newcnt loop } } ] if
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
    ok [ xs prim seq-int.len 1 prim - locals { last } { i last prim = [ true ] [ xs i prim seq-int.at locals { a } { xs i 1 prim + prim seq-int.at locals { b } { a b prim < [ false ] [ xs i 1 prim + true loop ] if } } ] if } ] [ false ] if
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
    ok [ flags prim seq-bool.len locals { len } { i len prim = [ true ] [ flags i prim seq-bool.at locals { f } { f [ flags i 1 prim + true loop ] [ false ] if } ] if } ] [ false ] if
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
      i 1 prim + locals { j } {
        j len prim = [ maxlen runlen prim < [ runlen ] [ maxlen ] if ] [ xs i prim seq-int.at locals { val } { xs j prim seq-int.at locals { next } { val next prim = [ maxlen xs i 1 prim + runlen 1 prim + j loop ] [ maxlen runlen prim < [ runlen ] [ maxlen ] if xs j 1 prim + 1 loop ] if } } ] if
      }
    }
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target xs xs prim seq-int.len 0 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many orig:Seq Int^many len:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target orig len i j } {
    i len prim = [ false ] [ i 1 prim + locals { ni } { ni len prim = [ xs target orig len i 1 prim + 0 loop ] [ orig i prim seq-int.at locals { x } { orig ni prim seq-int.at locals { y } { x y prim + locals { sum } { target sum prim = [ true ] [ xs target orig len i j ni prim + loop ] if } } } ] if } ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { 
    n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ 
      prim seq-int.empty n digit-loop locals { reversed } {
        prim seq-int.empty reversed reversed prim seq-int.len reverse-helper
      }
    ] if 
  };

: digit-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim = [ result ] [ n 10 prim mod locals { d } { result d prim seq-int.push n 10 prim div digit-loop } ] if
  };

: reverse-helper
  (forall ρ; ρ reversed:Seq Int^many original:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { reversed original i } {
    i 0 prim = [ reversed ] [ original i 1 prim - prim seq-int.at locals { val } { reversed val prim seq-int.push original i 1 prim - reverse-helper } ] if
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
    i n prim = [ result ] [ i is-prime [ result i prim seq-int.push i 1 prim + n loop ] [ result i 1 prim + n loop ] if ] if
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
  locals { xs k } { xs k loop };

: loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty k 0 init-histogram xs 0 count-loop
  };

: init-histogram
  (forall ρ; ρ counts:Seq Int^many k:Int^many i:Int^many -- ρ initialized:Seq Int^many)
  locals { counts k i } {
    i k prim = [ counts ] [ counts 0 prim seq-int.push i 1 prim + k init-histogram ] if
  };

: count-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ counts ] [ xs i prim seq-int.at locals { val } { counts val prim seq-int.at locals { cnt } { counts val cnt 1 prim + prim seq-int.set xs i 1 prim + count-loop } } ] if
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
    i 0 prim = [ xs i 1 prim + loop ] [ xs i 1 prim - prim seq-int.at locals { y } { xs i prim seq-int.at locals { x } { x y prim < [ xs i 1 prim - y prim seq-int.set xs i x prim seq-int.set i 1 prim - insert-sort ] [ xs i 1 prim + loop ] if } } ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole loop };

: loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    items prim seq-int.len locals { len } {
      i len prim = [ stock allocated reasons ] [
        items i prim seq-int.at locals { item } {
          stock item prim seq-int.at locals { r } {
            qtys i prim seq-int.at locals { q } {
              whole i prim seq-bool.at locals { w } {
                q r prim < [ stock allocated q prim seq-int.push reasons 0 prim seq-int.push stock item r prim seq-int.set allocated reasons i 1 prim + items qtys whole loop ] [
                  r 0 prim = [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock allocated reasons i 1 prim + items qtys whole loop ] [
                    w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock allocated reasons i 1 prim + items qtys whole loop ] [
                      stock allocated r prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set allocated reasons i 1 prim + items qtys whole loop
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
