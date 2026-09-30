Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs index result } {
    index 0 prim <
    [ xs index prim seq-int.at locals { elem } {
        result elem prim seq-int.push locals { new-result } {
          xs index 1 prim - new-result reverse-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs index result } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        x 0 prim <
        [ xs index 1 prim + result filter-loop ]
        [ result x prim seq-int.push locals { new-result } {
            xs index 1 prim + new-result filter-loop
          }
        ]
        if
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty filter-loop };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ xs:Seq Int^many index:Int^many curr-val:Int^many curr-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs index curr-val curr-len max-len } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        x curr-val prim =
        [ curr-len 1 prim + locals { new-len } {
            new-len max-len prim <
            [ xs index 1 prim + curr-val new-len max-len count-run ]
            [ xs index 1 prim + curr-val new-len new-len count-run ]
            if
          }
        ]
        [ xs index 1 prim + x 1 curr-len max-len count-run ]
        if
      }
    ]
    [ max-len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim <
    [ 0 ]
    [ xs 1 xs 0 prim seq-int.at 1 0 count-run ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-run
at: line 15, column 9
message: The two branches of the `if` in `count-run` whose true branch is `[ curr-len 1 prim + locals { new-len ...` leave different numbers of values. The true branch leaves the result of `count-run`; the false branch leaves 2 values, bottom to top: `xs` and the result of `count-run`.
hint: The false branch leaves 1 value more than the true branch: `xs` is left below the result of `count-run`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at locals { yj } {
        xs i prim seq-int.at locals { xi } {
          xi yj prim + locals { sum } {
            sum target prim =
            [ true ]
            [ xs target i j 1 prim + find-pair-inner ]
            if
          }
        }
      }
    ]
    [ false ]
    if
  };

: find-next-i
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs target i i 1 prim + find-pair-inner ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs target 0 find-next-i };

```
On the example, it returned [False] instead of [True]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod locals { d } {
        result d prim seq-int.push locals { new-result } {
          n 10 prim div locals { new-n } {
            new-n new-result digits-loop
          }
        }
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many index:Int^many output:Seq Int^many -- ρ final:Seq Int^many)
  locals { result index output } {
    index 0 prim <
    [ result index prim seq-int.at locals { d } {
        output d prim seq-int.push locals { new-output } {
          result index 1 prim - new-output reverse-digits
        }
      }
    ]
    [ output ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ output:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digits-loop locals { digits-seq } {
        digits-seq digits-seq prim seq-int.len 1 prim - prim seq-int.empty reverse-digits
      }
    ]
    if
  };

```
On the example, it returned [[]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * locals { i-sq } {
      i-sq n prim <
      [ n i prim mod 0 prim =
        [ false ]
        [ n i 1 prim + is-prime ]
        if
      ]
      [ true ]
      if
    }
  };

: sieve-loop
  (forall ρ; ρ n:Int^many candidate:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { n candidate result } {
    candidate n prim <
    [ candidate 2 prim <
      [ n candidate 1 prim + result sieve-loop ]
      [ candidate 2 is-prime
        [ n candidate 1 prim + result candidate prim seq-int.push sieve-loop ]
        [ n candidate 1 prim + result sieve-loop ]
        if
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ output:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty sieve-loop };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { x } {
        result x insert-into-sorted
      }
    ]
    [ result ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ result:Seq Int^many x:Int^many pos:Int^many -- ρ output:Seq Int^many)
  locals { result x pos } {
    pos result prim seq-int.len prim <
    [ result pos prim seq-int.at locals { elem } {
        x elem prim <
        [ result x prim seq-int.push ]
        [ result x pos 1 prim + insert-into-sorted ]
        if
      }
    ]
    [ result x prim seq-int.push ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty insertion-sort };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insertion-sort
at: line 10, column 5
message: In the true branch `[ xs i prim seq-int.at locals { x ...` of the `if` in `insertion-sort`, `insert-into-sorted` needs 3 values (result:Seq Int, x:Int, pos:Int), but the branch has pushed only 2 values before it (`result` and `x`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-into-sorted`, exactly the values it takes, in this order: result:Seq Int, x:Int, pos:Int. The branch already pushes `result` and `x`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `insert-into-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: process-transactions
  (forall ρ; ρ balance:Int^many txs:Seq Int^many index:Int^many rejected:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance txs index rejected } {
    index txs prim seq-int.len prim <
    [ txs index prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim <
          [ txs index 1 prim + balance rejected 1 prim + process-transactions ]
          [ txs index 1 prim + new-balance rejected process-transactions ]
          if
        }
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 process-transactions };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: process-transactions
at: line 8, column 58
message: `process-transactions` in `process-transactions` takes balance:Int, txs:Seq Int, index:Int, rejected:Int, bottom to top, but here it gets, bottom to top, `txs` (Seq Int), the result of `prim +` (Int), `balance` (Int) and the result of `prim +` (Int).
expected: .. Int Seq Int Int Int
actual: .. ?t79 Int ?t77 Int
hint: These are the values `process-transactions` takes, in another order. By their names and types, `balance` is for `balance` and `txs` is for `txs`. Of the values of one type, `index 1 prim +` and `rejected 1 prim +` are for `index` and `rejected`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-orders
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole order-idx allocated reasons } {
    order-idx qtys prim seq-int.len prim <
    [ qtys order-idx prim seq-int.at locals { qty } {
        items order-idx prim seq-int.at locals { item } {
          whole order-idx prim seq-bool.at locals { is-whole } {
            stock item prim seq-int.at locals { r } {
              qty r prim < locals { qty-fits } {
                qty-fits
                [ stock item qty prim seq-int.set locals { new-stock } {
                    new-stock items qtys whole order-idx 1 prim + allocated qty prim seq-int.push reasons 0 prim seq-int.push process-orders
                  }
                ]
                [ r 0 prim = 
                  [ stock items qtys whole order-idx 1 prim + allocated 0 prim seq-int.push reasons 2 prim seq-int.push process-orders ]
                  [ is-whole
                    [ stock items qtys whole order-idx 1 prim + allocated 0 prim seq-int.push reasons 3 prim seq-int.push process-orders ]
                    [ stock item 0 prim seq-int.set locals { new-stock } {
                        new-stock items qtys whole order-idx 1 prim + allocated r prim seq-int.push reasons 1 prim seq-int.push process-orders
                      }
                    ]
                    if
                  ]
                  if
                ]
                if
              }
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty process-orders };

```
On the example, it returned [[0, 1], [4, 0, 4, 1], [0, 3, 1, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
