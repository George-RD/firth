Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  ( -- result:Int^many )
  { 4 5 6 } locals { xs } { 0 xs 0 sum-helper };

: sum-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { acc xs idx } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at locals { val } {
        acc val prim + xs idx 1 prim + sum-helper
      }
    ] [
      acc
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  ( -- result:Int^many )
  { 3 9 2 } locals { xs } { xs 1 max-helper };

: max-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs idx } {
    idx xs prim seq-int.len prim = [
      xs 0 prim seq-int.at
    ] [
      xs idx prim seq-int.at locals { cur } {
        xs idx 1 prim + max-helper locals { rest } {
          cur rest prim < [ rest ] [ cur ] if
        }
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  ( -- result:Int^many )
  { 1 5 2 8 } 4 locals { xs k } { 0 xs 0 k count-below-helper };

: count-below-helper
  (forall ρ; ρ count:Int^many xs:Seq Int^many idx:Int^many k:Int^many -- ρ result:Int^many)
  locals { count xs idx k } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at locals { val } {
        val k prim < [
          count 1 prim + xs idx 1 prim + k count-below-helper
        ] [
          count xs idx 1 prim + k count-below-helper
        ] if
      }
    ] [
      count
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  ( -- result:Int^many )
  { 7 3 9 3 } 3 locals { xs x } { xs 0 x index-of-helper };

: index-of-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs idx x } {
    idx xs prim seq-int.len prim < prim not [
      -1
    ] [
      xs idx prim seq-int.at locals { val } {
        val x prim = [
          idx
        ] [
          xs idx 1 prim + x index-of-helper
        ] if
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  { 1 2 3 } prim seq-int.empty locals { xs acc } { acc xs xs prim seq-int.len 1 prim - reverse-helper };

: reverse-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { acc xs idx } {
    idx 0 prim < [
      acc
    ] [
      xs idx prim seq-int.at locals { val } { acc val prim seq-int.push xs idx 1 prim - reverse-helper }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  { 1 2 3 } prim seq-int.empty locals { xs acc } { acc xs 0 0 prefix-helper };

: prefix-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many idx:Int^many sum:Int^many -- ρ result:Seq Int^many)
  locals { acc xs idx sum } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at locals { val } {
        sum val prim + locals { newsum } {
          acc newsum prim seq-int.push xs idx 1 prim + newsum prefix-helper
        }
      }
    ] [
      acc
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  { 3 -1 0 4 } prim seq-int.empty locals { xs acc } { acc xs 0 keep-positive-helper };

: keep-positive-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { acc xs idx } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at locals { val } {
        val 0 prim < [
          acc xs idx 1 prim + keep-positive-helper
        ] [
          acc val prim seq-int.push xs idx 1 prim + keep-positive-helper
        ] if
      }
    ] [
      acc
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  ( -- result:Bool^many )
  { 1 2 2 5 } locals { xs } { xs 0 is-sorted-helper };

: is-sorted-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim < prim not [
      true
    ] [
      xs idx prim seq-int.at locals { cur } {
        xs idx 1 prim + prim seq-int.at locals { next } {
          cur next prim < prim not [
            xs idx 1 prim + is-sorted-helper
          ] [
            false
          ] if
        }
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  ( -- result:Int^many )
  { 1 2 3 } { 4 5 6 } locals { xs ys } { 0 xs ys 0 dot-helper };

: dot-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many ys:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { acc xs ys idx } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at locals { x } {
        ys idx prim seq-int.at locals { y } {
          x y prim * locals { prod } {
            acc prod prim + xs ys idx 1 prim + dot-helper
          }
        }
      }
    ] [
      acc
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  ( -- result:Bool^many )
  { true true false } locals { flags } { flags 0 all-true-helper };

: all-true-helper
  (forall ρ; ρ flags:Seq Bool^many idx:Int^many -- ρ result:Bool^many)
  locals { flags idx } {
    idx flags prim seq-bool.len prim < prim not [
      true
    ] [
      flags idx prim seq-bool.at [
        flags idx 1 prim + all-true-helper
      ] [
        false
      ] if
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  ( -- result:Int^many )
  { 1 1 2 2 2 1 } locals { xs } { 0 0 0 xs 0 longest-run-helper };

: longest-run-helper
  (forall ρ; ρ max:Int^many cur:Int^many last:Int^many xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { max cur last xs idx } {
    idx xs prim seq-int.len prim < prim not [
      max cur prim < [ cur ] [ max ] if
    ] [
      xs idx prim seq-int.at locals { val } {
        val last prim = [
          cur 1 prim + locals { newcur } {
            newcur max prim < [ max ] [ newcur ] if locals { newmax } {
              newmax newcur val xs idx 1 prim + longest-run-helper
            }
          }
        ] [
          max cur prim < [ cur ] [ max ] if locals { newmax } {
            newmax 1 val xs idx 1 prim + longest-run-helper
          }
        ] if
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  ( -- result:Bool^many )
  { 1 4 6 2 } 8 locals { xs target } { xs target 0 has-pair-sum-helper };

: has-pair-sum-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < prim not [
      false
    ] [
      xs i prim seq-int.at locals { xi } {
        xi i 1 prim + xs target check-pair-helper [
          true
        ] [
          xs target i 1 prim + has-pair-sum-helper
        ] if
      }
    ] if
  };

: check-pair-helper
  (forall ρ; ρ xi:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xi j xs target } {
    j xs prim seq-int.len prim < prim not [
      false
    ] [
      xs j prim seq-int.at locals { xj } {
        xi xj prim + target prim = [
          true
        ] [
          xi j 1 prim + xs target check-pair-helper
        ] if
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  ( -- result:Int^many )
  { 3 1 3 2 1 } locals { xs } { 0 xs 0 count-distinct-helper };

: count-distinct-helper
  (forall ρ; ρ count:Int^many xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { count xs idx } {
    idx xs prim seq-int.len prim < prim not [
      count
    ] [
      xs idx prim seq-int.at locals { val } {
        idx 1 prim + xs val is-in-rest [
          count xs idx 1 prim + count-distinct-helper
        ] [
          count 1 prim + xs idx 1 prim + count-distinct-helper
        ] if
      }
    ] if
  };

: is-in-rest
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim < prim not [
      false
    ] [
      xs j prim seq-int.at locals { val } {
        val target prim = [
          true
        ] [
          j 1 prim + xs target is-in-rest
        ] if
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  { 1 4 9 } { 2 3 10 } locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-sorted-helper };

: merge-sorted-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { acc xs ys i j } {
    i xs prim seq-int.len prim < prim not [
      j ys prim seq-int.len prim < prim not [
        acc
      ] [
        ys j prim seq-int.at locals { y } {
          acc y prim seq-int.push xs ys i j 1 prim + merge-sorted-helper
        }
      ] if
    ] [
      j ys prim seq-int.len prim < prim not [
        xs i prim seq-int.at locals { x } {
          acc x prim seq-int.push xs ys i 1 prim + j merge-sorted-helper
        }
      ] [
        xs i prim seq-int.at locals { x } {
          ys j prim seq-int.at locals { y } {
            x y swap prim < prim not [
              acc x prim seq-int.push xs ys i 1 prim + j merge-sorted-helper
            ] [
              acc y prim seq-int.push xs ys i j 1 prim + merge-sorted-helper
            ] if
          }
        }
      ] if
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  305 locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n digits-helper ] if };

: digits-helper
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { acc n } {
    n 0 prim = [
      acc
    ] [
      n 10 prim mod locals { digit } {
        n 10 prim div locals { rest } {
          acc digit prim seq-int.push rest digits-helper
        }
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  10 locals { n } { prim seq-int.empty 2 n primes-up-to-helper };

: primes-up-to-helper
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not [
      result
    ] [
      candidate is-prime [
        result candidate prim seq-int.push candidate 1 prim + n primes-up-to-helper
      ] [
        result candidate 1 prim + n primes-up-to-helper
      ] if
    ] if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many -- ρ result:Bool^many)
  locals { candidate } {
    candidate 2 prim < [
      false
    ] [
      candidate 2 prim = [
        true
      ] [
        candidate 2 is-prime-helper
      ] if
    ] if
  };

: is-prime-helper
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim < prim not [
      true
    ] [
      candidate divisor prim mod 0 prim = [
        false
      ] [
        candidate divisor 1 prim + is-prime-helper
      ] if
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  { 0 2 2 1 2 } 3 locals { xs k } { prim seq-int.empty k 0 build-histogram xs 0 populate-histogram };

: build-histogram
  (forall ρ; ρ counts:Seq Int^many k:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts k i } {
    i k prim < [
      counts 0 prim seq-int.push k i 1 prim + build-histogram
    ] [
      counts
    ] if
  };

: populate-histogram
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { counts xs idx } {
    idx xs prim seq-int.len prim < prim not [
      counts
    ] [
      xs idx prim seq-int.at locals { val } {
        counts val prim seq-int.at locals { cur } {
          counts val cur 1 prim + prim seq-int.set xs idx 1 prim + populate-histogram
        }
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  ( -- result:Seq Int^many )
  { 3 1 2 } locals { xs } { prim seq-int.empty xs 0 sort-helper };

: sort-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx } {
    idx xs prim seq-int.len prim < prim not [
      result
    ] [
      xs idx prim seq-int.at locals { val } {
        result val insert-into xs idx 1 prim + sort-helper
      }
    ] if
  };

: insert-into
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { result val } {
    result 0 val insert-into-helper
  };

: insert-into-helper
  (forall ρ; ρ result:Seq Int^many idx:Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { result idx val } {
    idx result prim seq-int.len prim < prim not [
      result val prim seq-int.push
    ] [
      result idx prim seq-int.at locals { cur } {
        val cur prim < prim not [
          result val prim seq-int.push
        ] [
          result cur prim seq-int.push locals { result } { result idx 1 prim + val insert-into-helper }
        ] if
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  ( -- balance:Int^many rejected:Int^many )
  10 { 5 -20 -15 4 } locals { start txs } { start 0 txs 0 ledger-helper };

: ledger-helper
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs idx } {
    idx txs prim seq-int.len prim < prim not [
      balance rejected
    ] [
      txs idx prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim < [
            balance rejected 1 prim + txs idx 1 prim + ledger-helper
          ] [
            new-balance rejected txs idx 1 prim + ledger-helper
          ] if
        }
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  ( -- stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many )
  { 10 3 } { 0 1 0 1 } { 4 5 7 1 } { false true false false } locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-helper
  };

: allocate-helper
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole order } {
    order items prim seq-int.len prim < prim not [
      stock allocated reasons
    ] [
      items order prim seq-int.at locals { item } {
        qtys order prim seq-int.at locals { qty } {
          whole order prim seq-bool.at locals { need-full } {
            stock item prim seq-int.at locals { available } {
              qty available prim < [
                stock item qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push items qtys whole order 1 prim + allocate-helper
              ] [
                available 0 prim = [
                  stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push items qtys whole order 1 prim + allocate-helper
                ] [
                  need-full [
                    stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push items qtys whole order 1 prim + allocate-helper
                  ] [
                    stock item 0 prim seq-int.set allocated available prim seq-int.push reasons 1 prim seq-int.push items qtys whole order 1 prim + allocate-helper
                  ] if
                ] if
              ] if
            }
          }
        }
      }
    ] if
  };

```
On the example, the run failed:
{"error": "entry main: initial stack does not match its declared input count", "status": "error"}
