Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i xs } {
    i 0 prim <
    prim not
    [
      xs i prim seq-int.at
      acc prim seq-int.push
      i 1 prim -
      xs reverse-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    xs reverse-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 8, column 11
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `acc` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t17
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `acc xs i prim seq-int.at` in place of `xs i prim seq-int.at acc` on line 7. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ acc:Seq Int^many sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc sum i len xs } {
    i len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        acc new-sum prim seq-int.push
        i 1 prim +
        len xs new-sum prefix-loop
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    0
    xs prim seq-int.len
    xs prefix-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 10, column 24
message: `prefix-loop` in `prefix-loop` takes acc:Seq Int, sum:Int, i:Int, len:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int), `len` (Int), `xs` (Seq Int) and `new-sum` (Int).
expected: .. Seq Int Int Int Int Seq Int
actual: .. Seq Int Int Seq Int ?t36 Seq Int Int ?t36 Seq Int Int
hint: These are the values `prefix-loop` takes, in another order. By their names and types, `acc new-sum prim seq-int.push` is for `acc`, `len` is for `len` and `xs` is for `xs`. Of the values of one type, `i 1 prim +` and `new-sum` are for `sum` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ acc:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i len xs } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem 0 prim <
        prim not
        [
          acc elem prim seq-int.push
        ]
        [ acc ]
        if
      }
      i 1 prim +
      len xs keep-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs prim seq-int.len
    xs keep-loop
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
: check-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i len xs } {
    i len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <
      [
        i 1 prim +
        len xs check-loop
      ]
      [
        0 1 prim =
      ]
      if
    ]
    [
      0 0 prim =
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    0
    xs prim seq-int.len
    xs check-loop
  };

```
On the example, it returned [False] instead of [True]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ max-run:Int^many curr-run:Int^many curr-val:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-run curr-run curr-val i len xs } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem curr-val prim =
        [
          curr-run 1 prim +
          locals { new-run } {
            new-run max-run prim <
            [
              max-run new-run curr-val
            ]
            [
              new-run new-run curr-val
            ]
            if
            locals { updated-max new-curr-val } {
              i 1 prim +
              len xs updated-max new-curr-val run-loop
            }
          }
        ]
        [
          curr-run max-run prim <
          [
            max-run elem
          ]
          [
            curr-run elem
          ]
          if
          locals { updated-max new-val } {
            1
            i 1 prim +
            len xs updated-max new-val run-loop
          }
        ]
        if
      }
    ]
    [
      curr-run max-run prim <
      [
        max-run
      ]
      [
        curr-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len
    0
    [
      1
      xs 0 prim seq-int.at
      1
      xs prim seq-int.len
      xs run-loop
    ]
    [
      0
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: run-loop
at: line 22, column 47
message: `run-loop` in `run-loop` takes max-run:Int, curr-run:Int, curr-val:Int, i:Int, len:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `len` (Int), `xs` (Seq Int), `updated-max` (Int) and `new-curr-val` (Int).
expected: .. Int Int Int Int Int Seq Int
actual: .. Int Int Int Seq Int Int Int
hint: The top value, `new-curr-val` (Int), is not what `run-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 72, column 5
message: The two branches of the `if` in `main` whose true branch is `[ 1 xs 0 prim seq-int.at 1 xs ...` leave different numbers of values. The true branch takes the result of `prim seq-int.len` from below the `if` and leaves the result of `run-loop`; the false branch leaves `0`. `main` calls `run-loop`, which has an error of its own; this report assumes `run-loop` keeps its stack effect.
hint: The true branch takes the result of `prim seq-int.len` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ i:Int^many j:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i j len xs target } {
    j len prim <
    [
      xs i prim seq-int.at
      xs j prim seq-int.at
      prim +
      target prim =
      [
        0 0 prim =
      ]
      [
        i j len xs target inner-loop
      ]
      if
    ]
    [
      0 1 prim =
    ]
    if
  };

: pair-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target } {
    i len prim <
    [
      i 1 prim +
      len xs target inner-loop
      [
        i len xs target pair-loop
      ]
      [ 0 0 prim = ]
      if
    ]
    [
      0 1 prim =
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    0
    xs prim seq-int.len
    xs target pair-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-loop
at: line 40, column 5
message: In the true branch `[ i 1 prim + len xs target ...` of the `if` in `pair-loop`, `inner-loop` needs 5 values (i:Int, j:Int, len:Int, xs:Seq Int, target:Int), but the branch has pushed only 4 values before it (the result of `prim +`, `len`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: i:Int, j:Int, len:Int, xs:Seq Int, target:Int. The branch already pushes the result of `prim +`, `len`, `xs` and `target`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    prim not
    [
      n 10 prim mod
      result swap prim seq-int.push
      n 10 prim div
      digit-loop
    ]
    [ result ]
    if
  };

: reverse-digits
  (forall ρ; ρ acc:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc i xs } {
    i 0 prim <
    prim not
    [
      xs i prim seq-int.at
      acc prim seq-int.push
      i 1 prim -
      xs reverse-digits
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty
      0 prim seq-int.push
    ]
    [
      prim seq-int.empty
      n digit-loop
      locals { digits } {
        prim seq-int.empty
        digits prim seq-int.len 1 prim -
        digits reverse-digits
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 23, column 11
message: `prim seq-int.push` in `reverse-digits` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `acc` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t17
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `acc xs i prim seq-int.at` in place of `xs i prim seq-int.at acc` on line 22. With that edit `reverse-digits` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: mark-multiples
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many i:Int^many n:Int^many -- ρ marked:Seq Bool^many)
  locals { sieve p i n } {
    i n prim <
    [
      sieve i 0 0 prim = prim seq-bool.set
      i p prim +
      n sieve mark-multiples
    ]
    [ sieve ]
    if
  };

: sieve-loop
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many n:Int^many -- ρ marked:Seq Bool^many)
  locals { sieve p n } {
    p p prim * n prim <
    [
      sieve p prim seq-bool.at
      [
        p p prim * sieve mark-multiples
        locals { new-sieve } {
          p 1 prim +
          n new-sieve sieve-loop
        }
      ]
      [
        p 1 prim +
        n sieve sieve-loop
      ]
      if
    ]
    [ sieve ]
    if
  };

: collect-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many sieve:Seq Bool^many -- ρ primes:Seq Int^many)
  locals { result i n sieve } {
    i n prim <
    [
      sieve i prim seq-bool.at
      [
        result i prim seq-int.push
      ]
      [ result ]
      if
      i 1 prim +
      n sieve collect-primes
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 2 prim <
    [
      prim seq-int.empty
    ]
    [
      prim seq-bool.empty 0 0 prim = prim seq-bool.push 0 0 prim = prim seq-bool.push
      2
      [
        2
        n sieve-loop
        locals { marked-sieve } {
          prim seq-int.empty
          2
          n marked-sieve collect-primes
        }
      ]
      [ prim seq-int.empty ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: mark-multiples
at: line 8, column 15
message: `mark-multiples` in `mark-multiples` takes sieve:Seq Bool, p:Int, i:Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-bool.set` (Seq Bool), the result of `prim +` (Int), `n` (Int) and `sieve` (Seq Bool).
expected: .. Seq Bool Int Int Int
actual: .. Seq Bool Int ?t30 Seq Bool
hint: The top value, `sieve` (Seq Bool), is not what `mark-multiples` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: sieve-loop
at: line 31, column 7
message: In the true branch `[ p p prim * sieve mark-multiples locals ...` of the `if` in `sieve-loop`, `mark-multiples` needs 4 values (sieve:Seq Bool, p:Int, i:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim *` and `sieve`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `sieve-loop` calls `mark-multiples`, which has an error of its own; this report assumes `mark-multiples` keeps its stack effect.
hint: Make the branch push, just before `mark-multiples`, exactly the values it takes, in this order: sieve:Seq Bool, p:Int, i:Int, n:Int. The branch already pushes the result of `prim *` and `sieve`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `mark-multiples` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: main
at: line 75, column 7
message: The two branches of the `if` in `main` whose true branch is `[ 2 n sieve-loop locals { marked-sieve } ...` leave different numbers of values. The true branch takes the result of `prim seq-bool.push` from below the `if` and leaves the result of `collect-primes`; the false branch leaves the result of `prim seq-int.empty`. `main` calls `sieve-loop`, which has an error of its own; this report assumes `sieve-loop` keeps its stack effect.
hint: The true branch takes the result of `prim seq-bool.push` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-elem
  (forall ρ; ρ result:Seq Int^many i:Int^many elem:Int^many -- ρ sorted:Seq Int^many)
  locals { result i elem } {
    i 0 prim <
    prim not
    [
      i 0 prim =
      [
        result 0 elem prim seq-int.set
      ]
      [
        result i 1 prim - prim seq-int.at
        locals { prev } {
          prev elem prim <
          [
            result i elem prim seq-int.set
          ]
          [
            result i prev prim seq-int.set
            i 1 prim -
            elem insert-elem
          ]
          if
        }
      ]
      if
    ]
    [ result 0 elem prim seq-int.set ]
    if
  };

: sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      locals { with-elem } {
        i prim seq-int.len 1 prim -
        with-elem elem insert-elem
        locals { inserted } {
          i 1 prim +
          len xs inserted sort-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs prim seq-int.len
    xs sort-loop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: sort-loop
at: line 41, column 19
message: `elem` is not a defined word, primitive or local.
actual: elem
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many len:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i len txs } {
    i len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim +
        locals { new-balance } {
          new-balance 0 prim <
          [
            i 1 prim +
            len txs balance rejected 1 prim + ledger-loop
          ]
          [
            i 1 prim +
            len txs new-balance rejected ledger-loop
          ]
          if
        }
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    0
    txs prim seq-int.len
    txs ledger-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ledger-loop
at: line 13, column 47
message: `ledger-loop` in `ledger-loop` takes balance:Int, rejected:Int, i:Int, len:Int, txs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `len` (Int), `txs` (Seq Int), `balance` (Int) and the result of `prim +` (Int).
expected: .. Int Int Int Int Seq Int
actual: .. Int ?t98 ?t97 ?t96 Int
hint: These are the values `ledger-loop` takes, in another order. By their names and types, `balance` is for `balance`, `len` is for `len` and `txs` is for `txs`. Of the values of one type, `i 1 prim +` and `rejected 1 prim +` are for `rejected` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: batch-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i len items qtys whole } {
    i len prim <
    [
      items i prim seq-int.at
      locals { item-idx } {
        qtys i prim seq-int.at
        locals { qty } {
          stock item-idx prim seq-int.at
          locals { avail } {
            qty avail prim <
            [
              stock item-idx qty prim - prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
            ]
            [
              avail 0 prim =
              [
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ]
              [
                whole i prim seq-bool.at
                [
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ]
                [
                  stock item-idx 0 prim seq-int.set
                  allocated avail prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
            locals { new-stock new-allocated new-reasons } {
              i 1 prim +
              len items qtys whole batch-loop
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
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    items prim seq-int.len
    items qtys whole batch-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: batch-loop
at: line 41, column 13
message: In the true branch `[ stock item-idx qty prim - prim seq-int.set ...` of the `if` in `batch-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (`stock` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes `stock` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
