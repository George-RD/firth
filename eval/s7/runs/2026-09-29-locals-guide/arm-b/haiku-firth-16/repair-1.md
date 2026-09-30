Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        max val prim < [
          val
        ] [
          max
        ] if locals { new_max } {
          i 1 prim + xs new_max max-loop
        }
      }
    ] [
      max
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at locals { first } {
      1 xs first max-loop
    }
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 26
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many k:Int^many count:Int^many -- ρ result:Int^many)
  locals { i xs k count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        val k prim < [
          count 1 prim +
        ] [
          count
        ] if locals { new_count } {
          i 1 prim + xs k new_count count-loop
        }
      }
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    0 xs k 0 count-loop
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 26
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim < [
      xs i prim seq-int.at locals { val } {
        result val prim seq-int.push locals { new_result } {
          i 1 prim - xs new_result reverse-loop
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - xs prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 6, column 50
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { i xs sum result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        sum val prim + locals { new_sum } {
          result new_sum prim seq-int.push locals { new_result } {
            i 1 prim + xs new_sum new_result prefix-loop
          }
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    0 xs 0 prim seq-int.empty prefix-loop
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 6, column 36
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        val 0 prim < [
          i 1 prim + xs result keep-loop
        ] [
          result val prim seq-int.push locals { new_result } {
            i 1 prim + xs new_result keep-loop
          }
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
On the example, the run failed:
code: firth.syntax.expected-name
at: line 9, column 52
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many ys:Seq Int^many acc:Int^many -- ρ product:Int^many)
  locals { i xs ys acc } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { x } {
        ys i prim seq-int.at locals { y } {
          x y prim * locals { prod } {
            acc prod prim + locals { new_acc } {
              i 1 prim + xs ys new_acc dot-loop
            }
          }
        }
      }
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 xs ys 0 dot-loop
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 8, column 41
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ i:Int^many xs:Seq Int^many curr_len:Int^many max_len:Int^many -- ρ length:Int^many)
  locals { i xs curr_len max_len } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { curr } {
        xs i 1 prim + prim seq-int.at locals { next } {
          curr next prim = [
            curr_len 1 prim + locals { new_curr_len } {
              i 1 prim + xs new_curr_len max_len count-run
            }
          ] [
            curr_len max_len prim < [
              max_len
            ] [
              curr_len
            ] if locals { new_max_len } {
              i 1 prim + xs 1 new_max_len count-run
            }
          ] if
        }
      }
    ] [
      curr_len max_len prim < [
        max_len
      ] [
        curr_len
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
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 47
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-pair
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i j xs target } {
    j xs prim seq-int.len prim < [
      i j prim = [
        i 1 prim + j 1 prim + xs target check-pair
      ] [
        xs i prim seq-int.at locals { a } {
          xs j prim seq-int.at locals { b } {
            a b prim + target prim = [
              true
            ] [
              j 1 prim + xs prim seq-int.len i 1 prim + prim < [
                i 1 prim + j 1 prim + xs target check-pair
              ] [
                i 1 prim + xs prim seq-int.len 1 prim - prim < [
                  i 1 prim + i 2 prim + xs target check-pair
                ] [
                  false
                ] if
              ] if
            ] if
          }
        }
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0 1 xs target check-pair
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-pair
at: line 22, column 15
message: The two branches of the `if` in `check-pair` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many count:Int^many -- ρ distinct:Int^many)
  locals { i xs count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        i 1 prim + xs count count-distinct-loop
      }
    ] [
      count
    ] if
  };

: is-in-result
  (forall ρ; ρ i:Int^many val:Int^many xs:Seq Int^many -- ρ found:Bool^many)
  locals { i val xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { curr } {
        curr val prim = [
          true
        ] [
          i 1 prim + val xs is-in-result
        ] if
      }
    ] [
      false
    ] if
  };

: count-unique-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ distinct:Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        0 val result is-in-result [
          i 1 prim + xs result count-unique-loop
        ] [
          result val prim seq-int.push locals { new_result } {
            i 1 prim + xs new_result count-unique-loop
          }
        ] if
      }
    ] [
      result prim seq-int.len
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 xs prim seq-int.empty count-unique-loop
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 37, column 52
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i j xs ys result } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at locals { x } {
          ys j prim seq-int.at locals { y } {
            x y prim < [
              result x prim seq-int.push locals { new_result } {
                i 1 prim + j xs ys new_result merge-loop
              }
            ] [
              result y prim seq-int.push locals { new_result } {
                i j 1 prim + xs ys new_result merge-loop
              }
            ] if
          }
        }
      ] [
        i xs prim seq-int.len prim < [
          xs i prim seq-int.at locals { x } {
            result x prim seq-int.push locals { new_result } {
              i 1 prim + j xs ys new_result merge-loop
            }
          }
        ] [
          result
        ] if
      ] if
    ] [
      j ys prim seq-int.len prim < [
        ys j prim seq-int.at locals { y } {
          result y prim seq-int.push locals { new_result } {
            i j 1 prim + xs ys new_result merge-loop
          }
        }
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    0 0 xs ys prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 9, column 54
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { d } {
        n 10 prim div locals { n_div } {
          result d prim seq-int.push locals { new_result } {
            n_div new_result digits-loop
          }
        }
      }
    ] if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many digits_seq:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i digits_seq result } {
    i 0 prim < [
      digits_seq i prim seq-int.at locals { d } {
        result d prim seq-int.push locals { new_result } {
          i 1 prim - digits_seq new_result reverse-digits
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
      n prim seq-int.empty digits-loop locals { raw_digits } {
        raw_digits prim seq-int.len 1 prim - raw_digits prim seq-int.empty reverse-digits
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 8, column 33
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
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
      true
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
        result i prim seq-int.push locals { new_result } {
          i 1 prim + n new_result collect-primes
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
On the example, the run failed:
code: firth.syntax.expected-name
at: line 30, column 48
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many k:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs k counts } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at locals { curr_count } {
          counts v curr_count 1 prim + prim seq-int.set locals { new_counts } {
            i 1 prim + xs k new_counts histogram-loop
          }
        }
      }
    ] [
      counts
    ] if
  };

: make-histogram
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i counts } {
    i k prim < [
      counts 0 prim seq-int.push locals { new_counts } {
        k i 1 prim + new_counts make-histogram
      }
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty make-histogram locals { initial_counts } {
      0 xs k initial_counts histogram-loop
    }
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 6, column 47
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
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
          i 1 prim - val result insert
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
          len val result insert locals { new_result } {
            i 1 prim + xs new_result sort-loop
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
On the example, the run failed:
code: firth.syntax.expected-name
at: line 23, column 45
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: process-txs
  (forall ρ; ρ i:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many -- ρ balance_final:Int^many rejected_final:Int^many)
  locals { i txs balance rejected } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim < [
          i 1 prim + txs balance rejected 1 prim + process-txs
        ] [
          i 1 prim + txs balance tx prim + rejected process-txs
        ] if
      }
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    0 txs start 0 process-txs
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 91
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock_final:Seq Int^many allocated_final:Seq Int^many reasons_final:Seq Int^many)
  locals { stock items qtys whole j allocated reasons } {
    j qtys prim seq-int.len prim < [
      items j prim seq-int.at locals { item_idx } {
        qtys j prim seq-int.at locals { qty } {
          stock item_idx prim seq-int.at locals { r } {
            whole j prim seq-bool.at [
              qty r prim < [
                stock item_idx r qty prim - prim seq-int.set locals { new_stock } {
                  allocated qty prim seq-int.push locals { new_allocated } {
                    reasons 1 prim seq-int.push locals { new_reasons } {
                      new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                    }
                  }
                }
              ] [
                qty r prim = [
                  stock item_idx 0 prim seq-int.set locals { new_stock } {
                    allocated qty prim seq-int.push locals { new_allocated } {
                      reasons 0 prim seq-int.push locals { new_reasons } {
                        new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  }
                ] [
                  r 0 prim = [
                    allocated 0 prim seq-int.push locals { new_allocated } {
                      reasons 2 prim seq-int.push locals { new_reasons } {
                        stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  ] [
                    allocated 0 prim seq-int.push locals { new_allocated } {
                      reasons 3 prim seq-int.push locals { new_reasons } {
                        stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  ] if
                ] if
              ] if
            ] [
              qty r prim < [
                stock item_idx r qty prim - prim seq-int.set locals { new_stock } {
                  allocated qty prim seq-int.push locals { new_allocated } {
                    reasons 0 prim seq-int.push locals { new_reasons } {
                      new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                    }
                  }
                }
              ] [
                r 0 prim = [
                  allocated 0 prim seq-int.push locals { new_allocated } {
                    reasons 2 prim seq-int.push locals { new_reasons } {
                      stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                    }
                  }
                ] [
                  stock item_idx 0 prim seq-int.set locals { new_stock } {
                    allocated r prim seq-int.push locals { new_allocated } {
                      reasons 1 prim seq-int.push locals { new_reasons } {
                        new_stock items qtys whole j 1 prim + new_allocated new_reasons allocate-one
                      }
                    }
                  }
                ] if
              ] if
            ] if
          }
        }
      }
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_final:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-one
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 157
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
