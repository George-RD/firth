Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs prim seq-int.len xs keep-loop
  };

: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        v 0 prim <
        [ result ]
        [ result v prim seq-int.push ]
        if
        locals { new-result } {
          new-result i 1 prim + len xs keep-loop
        }
      }
    ]
    [ result ]
    if
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 1 prim <
      [ true ]
      [ true 0 len xs check-sorted ]
      if
    }
  };

: check-sorted
  (forall ρ; ρ ok:Bool^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { ok i len xs } {
    i len 1 prim - prim <
    [ ok
      [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < ]
      [ false ]
      if
      locals { is-ok } {
        is-ok i 1 prim + len xs check-sorted
      }
    ]
    [ ok ]
    if
  };

```
On the example, it returned [False] instead of [True]

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false 0 xs prim seq-int.len xs target check-pairs
  };

: check-pairs
  (forall ρ; ρ found:Bool^many i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i len xs target } {
    found
    [ true ]
    [ i len prim <
      [ i 1 prim + i len xs target check-inner ]
      [ false ]
      if
    ]
    if
  };

: check-inner
  (forall ρ; ρ j:Int^many i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i len xs target } {
    j len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + i len xs target check-inner ]
      if
    ]
    [ false ]
    if
  };

```
On the example, it returned [False] instead of [True]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n check-primes
  };

: check-primes
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { primes candidate limit } {
    candidate limit prim <
    [ candidate is-prime
      [ primes candidate prim seq-int.push ]
      [ primes ]
      if
      locals { new-primes } {
        new-primes candidate 1 prim + limit check-primes
      }
    ]
    [ primes ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 prim =
      [ true ]
      [ n 2 prim mod 0 prim =
        [ false ]
        [ true 2 n check-divisor ]
        if
      ]
      if
    ]
    if
  };

: check-divisor
  (forall ρ; ρ is-prime:Bool^many d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { is-prime d n } {
    is-prime prim not
    [ false ]
    [ d d prim * n prim <
      [ n d prim mod 0 prim =
        [ false ]
        [ true d 2 prim + n check-divisor ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

```
On the example, it returned [[2, 3, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k build-histogram locals { initial-counts } {
      0 xs prim seq-int.len xs k initial-counts count-occurrences
    }
  };

: build-histogram
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k } {
    i k prim <
    [ counts 0 prim seq-int.push locals { new-counts } {
        new-counts i 1 prim + k build-histogram
      }
    ]
    [ counts ]
    if
  };

: count-occurrences
  (forall ρ; ρ counts:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i len xs k } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at 1 prim + locals { new-count } {
          counts v new-count prim seq-int.set locals { new-counts } {
            new-counts i 1 prim + len xs k count-occurrences
          }
        }
      }
    ]
    [ counts ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 5, column 49
message: `count-occurrences` in `main` takes counts:Seq Int, i:Int, len:Int, xs:Seq Int, k:Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `prim seq-int.len` (Int), `xs` (Seq Int), `k` (Int) and `initial-counts` (Seq Int).
expected: .. Seq Int Int Int Seq Int Int
actual: ρ Seq Int Int Int Int Seq Int Int Seq Int
hint: These are the values `count-occurrences` takes, in another order. By their names and types, `initial-counts` is for `counts`, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `0` and `xs prim seq-int.len` are for `i` and `len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len insertion-sort
  };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        xs v i insert-into-sorted locals { new-xs } {
          new-xs i 1 prim + len insertion-sort
        }
      }
    ]
    [ xs ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ xs:Seq Int^many v:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { xs v pos } {
    pos 0 prim =
    [ xs ]
    [ xs pos 1 prim - prim seq-int.at v prim <
      [ xs pos 1 prim - prim seq-int.at xs pos prim seq-int.set locals { new-xs } {
          new-xs v pos 1 prim - insert-into-sorted
        }
      ]
      [ xs pos v prim seq-int.set ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: insert-into-sorted
at: line 27, column 48
message: `prim seq-int.set` in `insert-into-sorted` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `pos` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t54 Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `xs` is for `Seq Int`. Of the values of one type, `xs pos 1 prim - prim seq-int.at` and `pos` are for `Int` and `Int`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len items qtys whole allocate
  };

: allocate
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons j len items qtys whole } {
    j len prim <
    [ items j prim seq-int.at locals { item-idx } {
        qtys j prim seq-int.at locals { qty } {
          stock item-idx prim seq-int.at locals { curr-stock } {
            qty curr-stock prim <
            [ stock item-idx curr-stock qty prim - prim seq-int.set locals { new-stock } {
                new-stock allocated qty prim seq-int.push reasons 0 prim seq-int.push
              }
            ]
            [ curr-stock 0 prim =
              [ stock allocated prim seq-int.push reasons 2 prim seq-int.push ]
              [ whole j prim seq-bool.at
                [ stock allocated prim seq-int.push reasons 3 prim seq-int.push ]
                [ stock item-idx 0 prim seq-int.set locals { new-stock } {
                    new-stock allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push
                  }
                ]
                if
              ]
              if
            ]
            if
            locals { updated-stock updated-allocated updated-reasons } {
              updated-stock updated-allocated updated-reasons j 1 prim + len items qtys whole allocate
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate
at: line 27, column 17
message: The two branches of the `if` in `allocate` whose true branch is `[ stock allocated prim seq-int.push reasons 3 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: `new-stock`, the result of `prim seq-int.push` and the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: `new-stock` is left below the result of `prim seq-int.push` and the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
