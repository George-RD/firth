Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ prime:Bool^many)
  locals { n i } {
    i i prim * n prim >
    [ true ]
    [ n i prim mod 0 prim =
      [ false ]
      [ n i 2 prim + is-prime ]
      if
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ n:Int^many i:Int^many primes:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i primes } {
    i n prim > 
    [ primes ]
    [ i 2 prim >=
      [ i 2 is-prime
        [ n i 1 prim + primes i prim seq-int.push sieve-loop ]
        [ n i 1 prim + primes sieve-loop ]
        if
      ]
      [ n i 1 prim + primes sieve-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty sieve-loop
  };

```
On the example, it returned [[2, 3, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: min-index-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many min-i:Int^many -- ρ idx:Int^many)
  locals { xs i min-i } {
    i xs prim seq-int.len prim >=
    [ min-i ]
    [ xs i prim seq-int.at xs min-i prim seq-int.at prim <
      [ xs i 1 prim + i min-index-loop ]
      [ xs i 1 prim + min-i min-index-loop ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim >=
    [ xs ]
    [ xs i i min-index-loop locals { min-idx } {
      xs min-idx prim seq-int.at xs i prim seq-int.at locals { val-i val-min } {
        xs i val-min prim seq-int.set locals { xs1 } {
          xs1 min-idx val-i prim seq-int.set locals { xs2 } {
            xs2 i 1 prim + sort-loop
          }
        }
      }
    } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 sort-loop
  };

```
On the example, it returned [[3, 1, 2]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-item
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i qtys prim seq-int.len prim >=
    [ stock allocated reasons ]
    [ items i prim seq-int.at stock swap prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      locals { item-stock qty needs-whole } {
        qty item-stock prim <=
        [ allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { allocated1 reasons1 } {
            stock items i prim seq-int.at qty prim seq-int.set items qtys whole i 1 prim + allocated1 reasons1 allocate-item
          }
        ]
        [ item-stock 0 prim =
          [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push locals { reasons1 allocated1 } {
            stock items qtys whole i 1 prim + allocated1 reasons1 allocate-item
          } ]
          [ needs-whole
            [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push locals { reasons1 allocated1 } {
              stock items qtys whole i 1 prim + allocated1 reasons1 allocate-item
            } ]
            [ allocated item-stock prim seq-int.push reasons 1 prim seq-int.push locals { allocated1 reasons1 } {
                stock items i prim seq-int.at 0 prim seq-int.set items qtys whole i 1 prim + allocated1 reasons1 allocate-item
              }
            ]
            if
          ]
          if
        ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-item
  };

```
On the example, it returned [[0, 1], [0, 3, 4, 1], [4, 0, 1, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
