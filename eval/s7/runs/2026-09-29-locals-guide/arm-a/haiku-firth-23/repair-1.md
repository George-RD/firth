Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    0 0
    [ xs prim seq-int.len ]
    [ locals { acc i } {
      acc i xs prim seq-int.at prim +
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 6, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int Int [ .. -- .. Int ] [ .. Int Int Seq Int -- .. Int Int Seq Int Seq Int ] [ .. Int Int Seq Int Int -- .. Int Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1
    [ xs prim seq-int.len ]
    [ locals { max i } {
      i xs prim seq-int.at
      max prim <
      [ i xs prim seq-int.at ]
      [ max ]
      if
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 7, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int Int [ .. -- .. Int ] [ .. Int Int Seq Int -- .. Int Int Seq Int Seq Int ] [ .. Int Int Seq Int Int -- .. Int Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 0
    [ xs prim seq-int.len ]
    [ locals { count i } {
      i xs prim seq-int.at k prim <
      [ count 1 prim + ]
      [ count ]
      if
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 6, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int Int [ .. -- .. Int ] [ .. Int Int Seq Int -- .. Int Int Seq Int Seq Int Int ] [ .. Int Int Seq Int Int Int -- .. Int Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    -1 0
    [ xs prim seq-int.len ]
    [ locals { result i } {
      result 0 prim <
      [ result ]
      [ i xs prim seq-int.at x prim =
        [ i ]
        [ result ]
        if
      ]
      if
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 9, column 7
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Int Int Bool [ .. -- .. Int ] [ .. -- .. Seq Int Int Int Int ] [ .. Seq Int Int Int Seq Int -- .. Seq Int ]. Expected Int, found Seq Int.
expected: Int
actual: Seq Int

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
    prim seq-int.empty
    xs prim seq-int.len
    [ locals { result i } {
      xs i 1 prim - prim seq-int.at
      result prim seq-int.push
      [ 1 prim - ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 8, column 14
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t12
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i 1 prim - prim seq-int.at` in place of `xs i 1 prim - prim seq-int.at result`. With that edit, the next error in `main` is at line 10, column 5.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0 0
    [ xs prim seq-int.len ]
    [ locals { result sum i } {
      sum i xs prim seq-int.at prim +
      result sum prim seq-int.push
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 7, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Int Int Int [ .. -- .. Int ] [ .. Seq Int Int Seq Int -- .. Seq Int Int Seq Int Seq Int ] [ .. Seq Int Int Seq Int Int -- .. Int Seq Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

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
    prim seq-int.empty
    0
    [ xs prim seq-int.len ]
    [ locals { result i } {
      i xs prim seq-int.at 0 prim <
      [ result ]
      [ result i xs prim seq-int.at prim seq-int.push ]
      if
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 7, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Int Int [ .. -- .. Int ] [ .. Int Seq Int Seq Int -- .. Int Seq Int Seq Int Seq Int ] [ .. Int Seq Int Seq Int Int -- .. Int Seq Int ]. Expected Seq Int, found Int.
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
    xs prim seq-int.len 1 prim <
    [ true ]
    [ true 0
      [ xs prim seq-int.len 1 prim - ]
      [ locals { sorted i } {
        sorted
        [ i xs prim seq-int.at i 1 prim + xs prim seq-int.at prim < prim not ]
        [ false ]
        if
        [ 1 prim + ] dip
      } ]
      call
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 17, column 5
message: The two branches of the `if` in `main` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0
    [ xs prim seq-int.len ]
    [ locals { acc i } {
      acc i xs prim seq-int.at i ys prim seq-int.at prim * prim +
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 6, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int Int [ .. -- .. Int ] [ .. Int Int Seq Int -- .. Int Int Seq Int Seq Int Seq Int ] [ .. Int Int Seq Int Int Int -- .. Int Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true 0
    [ flags prim seq-int.len ]
    [ locals { result i } {
      result
      [ i flags prim seq-int.at prim not ]
      [ false ]
      if
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 5, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Bool Bool Int [ .. -- .. Seq Bool ] [ .. Seq Int -- .. Int ]. Expected Seq Bool, found Seq Int.
expected: Seq Bool
actual: Seq Int

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
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 0 1 1
      [ xs prim seq-int.len ]
      [ locals { maxlen current i } {
        i xs prim seq-int.at i 1 prim - xs prim seq-int.at prim =
        [ current 1 prim + ]
        [ maxlen current prim <
          [ current ]
          [ maxlen ]
          if
          1
        ]
        if
        [ 1 prim + ] dip
      } ]
      call
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 17, column 9
message: The two branches of the `if` in `main` whose true branch is `[ current 1 prim + ]` leave different numbers of values. The true branch leaves the result of `prim +`; the false branch leaves 2 values, bottom to top: the result of an `if` and `1`.
hint: The false branch leaves 1 value more than the true branch: the result of an `if` is left below `1`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    false 0
    [ xs prim seq-int.len ]
    [ locals { found i } {
      found
      [ i 1 prim + [ xs prim seq-int.len ]
        [ locals { j } {
          i xs prim seq-int.at j xs prim seq-int.at prim + target prim =
          [ true ]
          [ [ 1 prim + ] dip ]
          if
        } ]
        call
      ]
      [ false ]
      if
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 13, column 11
message: The two branches of the `if` in `main` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch takes the result of `prim +` and `false` from below the `if` and leaves 2 values, bottom to top: the result of `prim +` and the result of `prim +`.
hint: The false branch takes `false` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty
    0
    [ xs prim seq-int.len ]
    [ locals { seen i } {
      i xs prim seq-int.at
      0 false
      [ seen prim seq-int.len ]
      [ locals { val found j } {
        found
        [ j seen prim seq-int.at val prim =
          [ true ]
          [ [ 1 prim + ] dip ]
          if
        ]
        [ false ]
        if
        [ 1 prim + ] dip
      } ]
      call
      [ seen val prim seq-int.push ]
      dip
      [ 1 prim + ] dip
    } ]
    call
    prim seq-int.len
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 23, column 14
message: `val` is not a defined word, primitive or local.
actual: val
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0 0
    [ xs prim seq-int.len ys prim seq-int.len prim + ]
    [ locals { result i j } {
      i xs prim seq-int.len prim <
      j ys prim seq-int.len prim < prim and prim not
      [ i xs prim seq-int.len prim =
        [ result j ys prim seq-int.at prim seq-int.push [ 1 prim + ] dip ]
        [ result i xs prim seq-int.at prim seq-int.push [ 1 prim + ] dip ]
        if
      ]
      [ i xs prim seq-int.at j ys prim seq-int.at prim <
        [ result i xs prim seq-int.at prim seq-int.push [ 1 prim + ] dip ]
        [ result j ys prim seq-int.at prim seq-int.push [ 1 prim + ] dip ]
        if
      ]
      if
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 12, column 9
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. Int -- .. Int Seq Int ] [ .. Int -- .. Int Seq Int Int Seq Int ] [ .. Int Seq Int Seq Int Int -- .. Int Seq Int ]. Expected Int, found Seq Int.
expected: Int
actual: Seq Int

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
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty swap
      [ n 0 prim < prim not ]
      [ locals { result x } {
        result x 10 prim mod prim seq-int.push swap
        x 10 prim div
      } ]
      call
      drop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 12, column 7
message: The quotation run by `call` in `main` does not accept the stack below it (.. Seq Int Seq Int [ .. -- .. Bool ] [ .. Seq Int Seq Int Int -- .. Seq Int Seq Int Int ]).
expected: Int
actual: [ .. -- .. Bool ]
hint: Check what the quotation body consumes against the values available under it.

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
    prim seq-int.empty
    2
    [ n ]
    [ locals { primes p } {
      primes
      0 true
      [ primes prim seq-int.len ]
      [ locals { is_prime i } {
        is_prime
        [ i primes prim seq-int.at p prim mod 0 prim = ]
        [ false ]
        if
        [ 1 prim + ] dip
      } ]
      call
      [ primes p prim seq-int.push ]
      dip
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 11, column 20
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
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ k ]
    [ locals { counts i } {
      counts 0 prim seq-int.push
      [ 1 prim + ] dip
    } ]
    call
    0
    [ xs prim seq-int.len ]
    [ locals { counts i } {
      i xs prim seq-int.at
      counts swap 1 prim + prim seq-int.set
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 8, column 16
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `counts` (Int) and `0` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, `counts` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs
    0
    [ xs prim seq-int.len ]
    [ locals { result i } {
      i 1 prim -
      0
      [ i ]
      [ locals { result j } {
        j result prim seq-int.at j 1 prim + result prim seq-int.at prim <
        [ result j 1 prim + result prim seq-int.at j result prim seq-int.at prim seq-int.set prim seq-int.set ]
        [ result ]
        if
        [ 1 prim + ] dip
      } ]
      call
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 15, column 9
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0
    [ txs prim seq-int.len ]
    [ locals { balance rejected i } {
      i txs prim seq-int.at
      balance prim + 0 prim <
      [ rejected 1 prim + ]
      [ balance i txs prim seq-int.at prim + ]
      if
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 6, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int Int Int [ .. -- .. Int ] [ .. Int Int Int Seq Int -- .. Int Int Int Seq Int Seq Int ] [ .. Int Int Int Seq Int Int -- .. Int Int ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

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
    stock prim seq-int.empty prim seq-int.empty
    0
    [ qtys prim seq-int.len ]
    [ locals { stock allocated reasons j } {
      j items prim seq-int.at
      j qtys prim seq-int.at
      stock j prim seq-int.at
      locals { item_idx qty current_stock } {
        qty current_stock prim <
        [ stock item_idx qty prim seq-int.set
          allocated qty prim seq-int.push
          reasons 0 prim seq-int.push
        ]
        [ current_stock 0 prim =
          [ stock
            allocated 0 prim seq-int.push
            reasons 2 prim seq-int.push
          ]
          [ j whole prim seq-int.at
            [ stock
              allocated 0 prim seq-int.push
              reasons 3 prim seq-int.push
            ]
            [ stock item_idx 0 prim seq-int.set
              allocated current_stock prim seq-int.push
              reasons 1 prim seq-int.push
            ]
            if
          ]
          if
        ]
        if
      }
      [ 1 prim + ] dip
    } ]
    call
  };

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 11, column 20
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
