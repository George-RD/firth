Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i sum len } {
    i len prim < [
      xs i prim seq-int.at locals { val } {
        sum val prim + locals { new-sum } {
          xs new-sum i 1 prim + len sum-loop
        }
      }
    ] [ sum ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 xs prim seq-int.len sum-loop
  };

```
On the example, it returned [1] instead of [15]

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i max len } {
    i len prim < [
      xs i prim seq-int.at locals { val } {
        max val prim < [
          val
        ] [ max ] if locals { new-max } {
          xs new-max i 1 prim + len max-loop
        }
      }
    ] [ max ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs xs 0 prim seq-int.at 1 xs prim seq-int.len max-loop
  };

```
On the example, it returned [1] instead of [9]

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs k i count len } {
    i len prim < [
      xs i prim seq-int.at locals { val } {
        val k prim < [
          count 1 prim +
        ] [ count ] if locals { new-count } {
          xs k new-count i 1 prim + len count-loop
        }
      }
    ] [ count ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 xs prim seq-int.len count-loop
  };

```
On the example, it returned [4] instead of [2]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many len:Int^many -- ρ result2:Seq Int^many)
  locals { xs i result len } {
    i len prim < [
      xs i prim seq-int.at locals { val } {
        val 0 prim < [
          result
        ] [
          result val prim seq-int.push
        ] if locals { new-result } {
          xs i 1 prim + new-result len keep-loop
        }
      }
    ] [ result ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty xs prim seq-int.len keep-loop
  };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs i len } {
    i 1 prim - len prim < [
      xs i prim seq-int.at locals { curr } {
        xs i 1 prim - prim seq-int.at locals { prev } {
          prev curr prim < prev curr prim = prim or [
            xs i 1 prim + len sorted-loop
          ] [ false ] if
        }
      }
    ] [ true ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 1 prim < [ true ] [ xs 1 len sorted-loop ] if
    }
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 2, 5]}}, {'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 2, 5]}}, {'kind': 'literal', 'lit

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs ys i sum len } {
    i len prim < [
      xs i prim seq-int.at locals { x } {
        ys i prim seq-int.at locals { y } {
          x y prim * locals { prod } {
            sum prod prim + locals { new-sum } {
              xs ys new-sum i 1 prim + len dot-loop
            }
          }
        }
      }
    ] [ sum ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 xs prim seq-int.len dot-loop
  };

```
On the example, it returned [1] instead of [32]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many curr-run:Int^many max-run:Int^many prev:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i curr-run max-run prev len } {
    i len prim < [
      xs i prim seq-int.at locals { val } {
        val prev prim = [
          curr-run 1 prim + locals { new-curr } {
            new-curr max-run prim < [ max-run ] [ new-curr ] if locals { new-max } {
              xs i 1 prim + new-curr new-max val len run-loop
            }
          }
        ] [
          curr-run 1 prim + max-run prim < [ max-run ] [ curr-run 1 prim + ] if locals { new-max } {
            xs i 1 prim + 1 new-max val len run-loop
          }
        ] if
      }
    ] [
      curr-run max-run prim <  [ max-run ] [ curr-run ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 0 prim < [ 0 ] [
        len 0 prim = [ 0 ] [
          xs 1 1 0 xs 0 prim seq-int.at len run-loop
        ] if
      ] if
    }
  };

```
On the example, it returned [4] instead of [3]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-seen
  (forall ρ; ρ seen:Seq Int^many idx:Int^many val:Int^many -- ρ result:Bool^many)
  locals { seen idx val } {
    idx 0 prim < [
      false
    ] [
      seen idx prim seq-int.at locals { s } {
        s val prim = [
          true
        ] [
          seen idx 1 prim - val check-seen
        ] if
      }
    ] if
  };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many count:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs seen i count len } {
    i len prim < [
      xs i prim seq-int.at locals { val } {
        seen i 1 prim - val check-seen [
          xs seen i 1 prim + count len distinct-loop
        ] [
          seen val prim seq-int.push locals { new-seen } {
            xs new-seen i 1 prim + count 1 prim + len distinct-loop
          }
        ] if
      }
    ] [ count ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 0 xs prim seq-int.len distinct-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3, 1, 3, 2, 1]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'typ

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim < [
      n d prim mod 0 prim = [
        false
      ] [
        n d 1 prim + is-prime
      ] if
    ] [ true ] if
  };

: prime-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result2:Seq Int^many)
  locals { n i result } {
    i n prim < [
      i 2 prim < [
        n i 1 prim + result prime-loop
      ] [
        i 2 is-prime [
          result i prim seq-int.push locals { new-result } {
            n i 1 prim + new-result prime-loop
          }
        ] [
          n i 1 prim + result prime-loop
        ] if
      ] if
    ] [ result ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty prime-loop
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int^many val:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted val i } {
    i 0 prim = [
      sorted val prim seq-int.push
    ] [
      sorted i 1 prim - prim seq-int.at locals { elem } {
        elem val prim < [
          sorted val prim seq-int.push
        ] [
          sorted i elem prim seq-int.set locals { new-sorted } {
            new-sorted val i 1 prim - insert-sorted
          }
        ] if
      }
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many sorted:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs sorted i len } {
    i len prim < [
      xs i prim seq-int.at locals { val } {
        sorted val sorted prim seq-int.len insert-sorted locals { new-sorted } {
          xs new-sorted i 1 prim + len sort-loop
        }
      }
    ] [ sorted ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 xs prim seq-int.len sort-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3, 1, 2]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type': 's

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many len:Int^many -- ρ stock2:Seq Int^many alloc2:Seq Int^many reasons2:Seq Int^many)
  locals { stock items qtys whole i allocated reasons len } {
    i len prim < [
      items i prim seq-int.at locals { item } {
        qtys i prim seq-int.at locals { qty } {
          whole i prim seq-bool.at locals { w } {
            stock item prim seq-int.at locals { r } {
              qty r prim < [
                stock item qty prim - prim seq-int.set locals { new-stock } {
                  new-stock items qtys whole i 1 prim + allocated qty prim seq-int.push reasons 0 prim seq-int.push len allocate-loop
                }
              ] [
                r 0 prim = [
                  stock items qtys whole i 1 prim + allocated 0 prim seq-int.push reasons 2 prim seq-int.push len allocate-loop
                ] [
                  w [
                    stock items qtys whole i 1 prim + allocated 0 prim seq-int.push reasons 3 prim seq-int.push len allocate-loop
                  ] [
                    stock item 0 prim seq-int.set locals { new-stock } {
                      new-stock items qtys whole i 1 prim + allocated r prim seq-int.push reasons 1 prim seq-int.push len allocate-loop
                    }
                  ] if
                ] if
              ] if
            }
          }
        }
      }
    ] [ stock allocated reasons ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty items prim seq-int.len allocate-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 25, column 17
message: In the true branch `[ stock item qty prim - prim seq-int.set ...` of the `if` in `allocate-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (`stock` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes `stock` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
