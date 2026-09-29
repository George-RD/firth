Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs i max } {
    i 1 prim + xs prim seq-int.len prim < [
      xs i 1 prim + xs i 1 prim + prim seq-int.at max prim < [
        xs i 2 prim + max-loop
      ] [
        xs i 2 prim + xs i 1 prim + prim seq-int.at max-loop
      ] if
    ] [
      max
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 13, column 9
message: The two branches of the `if` in `max-loop` whose true branch is `[ xs i 2 prim + max-loop ]` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves the result of `max-loop`; the false branch leaves the result of `max-loop`.
hint: The true branch takes the result of `prim +` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ count:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim < [
      xs k i prim seq-int.at k prim < [
        xs k i 1 prim + count 1 prim + count-loop
      ] [
        xs k i 1 prim + count count-loop
      ] if
    ] [
      count
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 16, column 7
message: The two branches of the `if` in `count-loop` whose true branch is `[ xs k i prim seq-int.at k prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `count-loop`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `count-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 0 prim = [ drop ] [ 1 prim - ] if rev-build
  };

: rev-build
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.push xs i 1 prim - rev-build
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 4, column 78
message: The two branches of the `if` in `main` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes `xs` from below the `if` and leaves nothing; the false branch takes `xs` from below the `if` and leaves the result of `prim -`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim -` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 ps-build };

: ps-build
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + dup result prim seq-int.push xs i 1 prim + ps-build
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: ps-build
at: line 9, column 50
message: `prim seq-int.push` in `ps-build` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t26
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    prim seq-int.empty xs 0 keep-loop
  };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup 0 prim < [
        drop result xs i 1 prim + keep-loop
      ] [
        swap result prim seq-int.push xs i 1 prim + keep-loop
      ] if
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: keep-loop
at: line 13, column 9
message: `compose` in `keep-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Int Bool [ .. ?t48 -- .. Seq Int ] [ .. Seq Int ?t88 -- .. Seq Int ?t88 Seq Int Seq Int Int ] [ .. Seq Int ?t88 Int Seq Int Int -- .. ?t88 Seq Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

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
    xs prim seq-int.len 1 prim < [
      true
    ] [
      xs 1 is-sorted-loop
    ] if
  };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim < [
        false
      ] [
        xs i 1 prim + is-sorted-loop
      ] if
    ] [
      true
    ] if
  };

```
On the example, it returned [False] instead of [True]

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim < [
      xs ys i prim seq-int.at ys i prim seq-int.at prim * sum prim + xs ys i 1 prim + dot-loop
    ] [
      sum
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 12, column 7
message: The two branches of the `if` in `dot-loop` whose true branch is `[ xs ys i prim seq-int.at ys i ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `dot-loop`; the false branch leaves `sum`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `dot-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs xs 0 prim seq-int.at 1 1 0 run-loop
    ] if
  };

: run-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many i:Int^many maxlen:Int^many runlen:Int^many -- ρ length:Int^many)
  locals { xs prev i maxlen runlen } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup prev prim = [
        runlen 1 prim + dup maxlen prim < [
          xs prev i 1 prim + maxlen runlen 1 prim + run-loop
        ] [
          xs prev i 1 prim + swap maxlen run-loop
        ] if
      ] [
        runlen maxlen prim < [
          xs swap i 1 prim + runlen maxlen run-loop
        ] [
          xs swap i 1 prim + maxlen 1 run-loop
        ] if
      ] if
    ] [
      runlen maxlen prim < [
        runlen
      ] [
        maxlen
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 20, column 11
message: The two branches of the `if` in `run-loop` whose true branch is `[ xs prev i 1 prim + maxlen ...` leave different numbers of values. The true branch leaves the result of `run-loop`; the false branch takes the result of `prim +` from below the `if` and leaves the result of `run-loop`.
hint: The false branch takes the result of `prim +` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 distinct-loop
  };

: distinct-loop
  (forall ρ; ρ dists:Seq Int^many xs:Seq Int^many i:Int^many -- ρ count:Int^many)
  locals { dists xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dists xs i prim seq-int.at is-in [
        dists xs i 1 prim + distinct-loop
      ] [
        dists xs i prim seq-int.at prim seq-int.push xs i 1 prim + distinct-loop
      ] if
    ] [
      dists prim seq-int.len
    ] if
  };

: is-in
  (forall ρ; ρ dists:Seq Int^many val:Int^many -- ρ found:Bool^many)
  locals { dists val } {
    dists 0 val find-val
  };

: find-val
  (forall ρ; ρ dists:Seq Int^many i:Int^many val:Int^many -- ρ found:Bool^many)
  locals { dists i val } {
    i dists prim seq-int.len prim < [
      dists i prim seq-int.at val prim = [
        true
      ] [
        dists i 1 prim + val find-val
      ] if
    ] [
      false
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-loop
at: line 18, column 7
message: The two branches of the `if` in `distinct-loop` whose true branch is `[ xs i prim seq-int.at dists xs i ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `distinct-loop`; the false branch leaves the result of `prim seq-int.len`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `distinct-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n prim seq-int.empty digit-loop
    ] if
  };

: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim < [
      result
    ] [
      n 10 prim mod result prim seq-int.push n 10 prim div digit-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 17, column 28
message: `prim seq-int.push` in `digit-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit, the next error in `digit-loop` is at line 17, column 60.

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
    n 1 prim < [
      prim seq-int.empty
    ] [
      prim seq-int.empty 2 n prime-loop
    ] if
  };

: prime-loop
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { primes candidate limit } {
    candidate limit prim < [
      candidate is-prime [
        primes candidate prim seq-int.push candidate 1 prim + limit prime-loop
      ] [
        primes candidate 1 prim + limit prime-loop
      ] if
    ] [
      candidate limit prim = [
        candidate is-prime [
          primes candidate prim seq-int.push
        ] [
          primes
        ] if
      ] [
        primes
      ] if
    ] if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim < [
      false
    ] [
      num 2 prim = [
        true
      ] [
        num 2 check-divisor
      ] if
    ] if
  };

: check-divisor
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim < [
      num divisor prim mod 0 prim = [
        false
      ] [
        num divisor 2 prim + check-divisor
      ] if
    ] [
      true
    ] if
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

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
    prim seq-int.empty k 0 init-histogram xs 0 hist-loop
  };

: init-histogram
  (forall ρ; ρ counts:Seq Int^many remaining:Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { counts remaining i } {
    i remaining prim < [
      counts 0 prim seq-int.push i 1 prim + init-histogram
    ] [
      counts
    ] if
  };

: hist-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set
      xs i 1 prim + hist-loop
    ] [
      counts
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: init-histogram
at: line 14, column 7
message: In the true branch `[ counts 0 prim seq-int.push i 1 prim ...` of the `if` in `init-histogram`, `init-histogram` needs 3 values (counts:Seq Int, remaining:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-histogram`, exactly the values it takes, in this order: counts:Seq Int, remaining:Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `init-histogram` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: hist-loop
at: line 21, column 81
message: `prim seq-int.set` in `hist-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `counts` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Seq Int Int
hint: The second value from the top, `counts` (Seq Int), is not what `prim seq-int.set` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs sort-insertion
  };

: sort-insertion
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs xs 0 1 insert-step
  };

: insert-step
  (forall ρ; ρ xs:Seq Int^many orig:Seq Int^many sorted:Int^many unsorted:Int^many -- ρ sorted:Seq Int^many)
  locals { xs orig sorted unsorted } {
    unsorted xs prim seq-int.len prim < [
      xs xs unsorted prim seq-int.at xs sorted 0 find-insert-pos prim seq-int.set orig sorted 1 prim + unsorted 1 prim + insert-step
    ] [
      xs
    ] if
  };

: find-insert-pos
  (forall ρ; ρ xs:Seq Int^many val:Int^many pos:Int^many -- ρ xs:Seq Int^many)
  locals { xs val pos } {
    pos 0 prim < [
      xs
    ] [
      xs pos prim seq-int.at val prim < [
        xs val pos find-insert-pos
      ] [
        xs
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: insert-step
at: line 17, column 66
message: `prim seq-int.set` in `insert-step` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), the result of `prim seq-int.at` (Int) and the result of `find-insert-pos` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int ?t30 Seq Int Int Seq Int
hint: The top value, the result of `find-insert-pos` (Seq Int), is not what `prim seq-int.set` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at balance prim + dup 0 prim < [
        drop balance rejected 1 prim + txs i 1 prim + ledger-loop
      ] [
        swap balance rejected txs i 1 prim + ledger-loop
      ] if
    ] [
      balance rejected
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 13, column 9
message: In the false branch of the `if` in `ledger-loop` whose true branch is `[ drop balance rejected 1 prim + txs ...`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim +` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-orders
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons order items qtys whole } {
    order qtys prim seq-int.len prim < [
      items order prim seq-int.at stock items order prim seq-int.at prim seq-int.at qtys order prim seq-int.at whole order prim seq-bool.at stock alloc reasons order items qtys whole process-order
    ] [
      stock alloc reasons
    ] if
  };

: process-order
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many item:Int^many current-stock:Int^many qty:Int^many w:Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons order items qtys whole item current-stock qty w } {
    qty current-stock prim < [
      current-stock 0 prim = [
        alloc 0 prim seq-int.push reasons 2 prim seq-int.push stock item current-stock prim seq-int.set order 1 prim + items qtys whole allocate-orders
      ] [
        w [
          alloc 0 prim seq-int.push reasons 3 prim seq-int.push stock item current-stock prim seq-int.set order 1 prim + items qtys whole allocate-orders
        ] [
          alloc current-stock prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set order 1 prim + items qtys whole allocate-orders
        ] if
      ] if
    ] [
      alloc qty prim seq-int.push reasons 0 prim seq-int.push stock item current-stock qty prim - prim seq-int.set order 1 prim + items qtys whole allocate-orders
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: allocate-orders
at: line 11, column 184
message: `process-order` in `allocate-orders` takes stock:Seq Int, alloc:Seq Int, reasons:Seq Int, order:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, item:Int, current-stock:Int, qty:Int, w:Bool, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), the result of `prim seq-int.at` (Int), the result of `prim seq-int.at` (Int), the result of `prim seq-bool.at` (Bool), `stock` (Seq Int), `alloc` (Seq Int), `reasons` (Seq Int), `order` (Int), `items` (Seq Int), `qtys` (Seq Int) and `whole` (Seq Bool).
expected: .. Seq Int Seq Int Seq Int Int Seq Int Seq Int Seq Bool Int Int Int Bool
actual: .. Int Int Int Bool Seq Int ?t57 ?t56 Int Seq Int Seq Int Seq Bool
hint: These are the values `process-order` takes, in another order. By their names and types, `stock` is for `stock`, `alloc` is for `alloc`, `reasons` is for `reasons`, `order` is for `order`, `items` is for `items`, `qtys` is for `qtys`, `whole` is for `whole` and `whole order prim seq-bool.at` is for `w`. Of the values of one type, `items order prim seq-int.at`, `stock items order prim seq-int.at prim seq-int.at` and `qtys order prim seq-int.at` are for `item`, `current-stock` and `qty`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.
