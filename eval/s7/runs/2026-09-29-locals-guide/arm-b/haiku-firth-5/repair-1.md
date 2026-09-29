Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at acc prim +
      locals { new_acc } {
        xs i 1 prim + new_acc sum-loop
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 7, column 19
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max_val:Int^many -- ρ result:Int^many)
  locals { xs i max_val } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        x max_val prim <
        [ xs i 1 prim + max_val max-loop ]
        [ xs i 1 prim + x max-loop ]
        if
      }
    ]
    [ max_val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-loop };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 46
message: Unexpected `_`, expected `:`.
expected: :
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
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs k i acc } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        x k prim <
        [ acc 1 prim + ]
        [ acc ]
        if
      }
      locals { new_acc } {
        xs k i 1 prim + new_acc count-loop
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 13, column 19
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at
      result prim seq-int.push
      locals { new_result } {
        xs i 1 prim - new_result reverse-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    locals { start_i } {
      xs start_i prim seq-int.empty reverse-loop
    }
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 9, column 19
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        x acc prim +
        locals { new_acc } {
          result new_acc prim seq-int.push
          locals { new_result } {
            xs i 1 prim + new_acc new_result prefix-loop
          }
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 9, column 21
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        0 x prim <
        [
          result x prim seq-int.push
          locals { new_result } {
            xs i 1 prim + new_result keep-loop
          }
        ]
        [
          xs i 1 prim + result keep-loop
        ]
        if
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 11, column 23
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      locals { x y } {
        x y prim *
        acc prim +
        locals { new_acc } {
          xs ys i 1 prim + new_acc dot-loop
        }
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 11, column 21
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
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max_run:Int^many curr_run:Int^many last_val:Int^many -- ρ result:Int^many)
  locals { xs i max_run curr_run last_val } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem last_val prim =
        [
          curr_run 1 prim +
          locals { new_curr_run } {
            new_curr_run max_run prim <
            [ xs i 1 prim + max_run new_curr_run elem run-loop ]
            [ xs i 1 prim + new_curr_run new_curr_run elem run-loop ]
            if
          }
        ]
        [
          curr_run max_run prim <
          [ xs i 1 prim + max_run 1 elem run-loop ]
          [ xs i 1 prim + curr_run 1 elem run-loop ]
          if
        ]
        if
      }
    ]
    [
      curr_run max_run prim <
      [ max_run ]
      [ curr_run ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len
    locals { len } {
      len 0 prim =
      [ 0 ]
      [ xs 1 0 1 xs 0 prim seq-int.at run-loop ]
      if
    }
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 46
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem x prim =
        [ true ]
        [ xs x i 1 prim + contains-loop ]
        if
      }
    ]
    [ false ]
    if
  };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        xs x 0 contains-loop
        [
          xs i 1 prim + count distinct-loop
        ]
        [
          xs i 1 prim + count 1 prim + distinct-loop
        ]
        if
      }
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 distinct-loop };

```
On the example, it returned [0] instead of [3]

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        locals { x y } {
          x y prim <
          [
            result x prim seq-int.push
            locals { new_result } {
              xs ys i 1 prim + j new_result merge-loop
            }
          ]
          [
            result y prim seq-int.push
            locals { new_result } {
              xs ys i j 1 prim + new_result merge-loop
            }
          ]
          if
        }
      ]
      [
        i xs prim seq-int.len prim <
        [
          result xs i prim seq-int.at prim seq-int.push
          locals { new_result } {
            xs ys i 1 prim + j new_result merge-loop
          }
        ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        locals { new_result } {
          xs ys i j 1 prim + new_result merge-loop
        }
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 14, column 25
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
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result prim seq-int.push
      locals { new_result } {
        n 10 prim div new_result digit-loop
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at
      result prim seq-int.push
      locals { new_result } {
        xs i 1 prim - new_result reverse-digits
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [
      n prim seq-int.empty digit-loop
      locals { reversed_digits } {
        reversed_digits prim seq-int.len 1 prim -
        locals { start_i } {
          reversed_digits start_i prim seq-int.empty reverse-digits
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 9, column 19
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
: check-divisors
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [ n d 2 prim + check-divisors ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        n 2 prim mod 0 prim =
        [ false ]
        [ n 3 check-divisors ]
        if
      ]
      if
    ]
    if
  };

: prime-loop
  (forall ρ; ρ n:Int^many candidate:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n candidate result } {
    candidate n prim <
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
        locals { new_result } {
          n candidate 1 prim + new_result prime-loop
        }
      ]
      [
        n candidate 1 prim + result prime-loop
      ]
      if
    ]
    [
      candidate n prim =
      [
        n is-prime
        [
          result n prim seq-int.push
        ]
        [ result ]
        if
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty prime-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 42, column 21
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
: init-zeros
  (forall ρ; ρ k:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { k result } {
    k 0 prim =
    [ result ]
    [
      result 0 prim seq-int.push
      locals { new_result } {
        k 1 prim - new_result init-zeros
      }
    ]
    if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        counts val prim seq-int.at 1 prim +
        locals { new_count } {
          counts val new_count prim seq-int.set
          locals { new_counts } {
            xs k i 1 prim + new_counts histogram-loop
          }
        }
      }
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k prim seq-int.empty init-zeros
    locals { initial_counts } {
      xs k 0 initial_counts histogram-loop
    }
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 8, column 19
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
: insert-at
  (forall ρ; ρ sorted:Seq Int^many x:Int^many pos:Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { sorted x pos idx result } {
    idx sorted prim seq-int.len prim <
    [
      idx pos prim =
      [
        result x prim seq-int.push
        locals { new_result } {
          sorted x pos idx 1 prim + new_result insert-at
        }
      ]
      [
        sorted idx prim seq-int.at
        locals { elem } {
          result elem prim seq-int.push
          locals { new_result } {
            sorted x pos idx 1 prim + new_result insert-at
          }
        }
      ]
      if
    ]
    [
      pos sorted prim seq-int.len prim =
      [
        result x prim seq-int.push
      ]
      [ result ]
      if
    ]
    if
  };

: insert-sorted
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at
      locals { elem } {
        x elem prim <
        [
          sorted x i 0 prim seq-int.empty insert-at
        ]
        [
          x sorted i 1 prim + insert-sorted
        ]
        if
      }
    ]
    [
      sorted x prim seq-int.push
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        x sorted 0 insert-sorted
        locals { new_sorted } {
          xs i 1 prim + new_sorted sort-loop
        }
      }
    ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 9, column 21
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
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ final_balance:Int^many rejected_count:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim <
        [
          balance txs i 1 prim + rejected 1 prim + ledger-loop
        ]
        [
          balance tx prim +
          locals { new_balance } {
            new_balance txs i 1 prim + rejected ledger-loop
          }
        ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-loop };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 89
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
: allocate-order
  (forall ρ; ρ stock:Seq Int^many item_idx:Int^many qty:Int^many whole:Bool^many
    -- ρ new_stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item_idx qty whole } {
    stock item_idx prim seq-int.at
    locals { r } {
      qty r prim <
      [
        stock item_idx r qty prim - prim seq-int.set
        locals { s1 } {
          s1 qty 0
        }
      ]
      [
        r 0 prim =
        [
          stock 0 2
        ]
        [
          whole
          [
            stock 0 3
          ]
          [
            stock r prim seq-int.at r prim seq-int.set
            locals { s2 } {
              s2 r 1
            }
          ]
          if
        ]
        if
      ]
      if
    }
  };

: allocate-batch-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
    j:Int^many allocated_seq:Seq Int^many reason_seq:Seq Int^many -- ρ final_stock:Seq Int^many final_alloc:Seq Int^many final_reasons:Seq Int^many)
  locals { stock items qtys whole j allocated_seq reason_seq } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      qtys j prim seq-int.at
      whole j prim seq-bool.at
      allocate-order
      locals { reason new_allocated new_stock } {
        allocated_seq new_allocated prim seq-int.push
        locals { new_allocated_seq } {
          reason_seq reason prim seq-int.push
          locals { new_reason_seq } {
            new_stock items qtys whole j 1 prim + new_allocated_seq new_reason_seq allocate-batch-loop
          }
        }
      }
    ]
    [ stock allocated_seq reason_seq ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-batch-loop
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 39
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
