Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { max xs i curr } {
        curr max prim <
        [ max ]
        [ curr ]
        if
      }
      xs
      i 1 prim +
      seq-max-loop
    ]
    [
      max
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    xs
    0
    seq-max-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 20, column 5
message: In the true branch `[ xs i prim seq-int.at locals { max ...` of the `if` in `seq-max-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      xs
      i 1 prim -
      reverse-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    xs prim seq-int.len 1 prim -
    reverse-loop
  };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      result prim seq-int.push
      xs
      i 1 prim +
      prefix-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    0
    prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 15, column 5
message: In the true branch `[ sum xs i prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (result:Seq Int, sum:Int, xs:Seq Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, sum:Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { result xs i curr } {
        curr 0 prim <
        [ result ]
        [ result curr prim seq-int.push ]
        if
      }
      xs
      i 1 prim +
      filter-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    0
    filter-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 20, column 5
message: In the true branch `[ xs i prim seq-int.at locals { result ...` of the `if` in `filter-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        prim seq-bool.false
      ]
      [
        xs
        i 1 prim +
        sorted-loop
      ]
      if
    ]
    [
      prim seq-bool.true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ prim seq-bool.true ]
    [
      xs
      0
      sorted-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 8, column 14
message: Unexpected `seq-bool.false`, expected `primitive name`.
expected: primitive name
actual: seq-bool.false
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        flags
        i 1 prim +
        all-loop
      ]
      [ prim seq-bool.false ]
      if
    ]
    [ prim seq-bool.true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags
    0
    all-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 12, column 14
message: Unexpected `seq-bool.false`, expected `primitive name`.
expected: primitive name
actual: seq-bool.false
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ max:Int^many curr-len:Int^many xs:Seq Int^many i:Int^many -- ρ length:Int^many)
  locals { max curr-len xs i } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        xs
        i 1 prim +
        max
        1
        run-loop
      ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          curr-len 1 prim +
          locals { max curr-len xs i new-len } {
            new-len max prim <
            [ max ]
            [ new-len ]
            if
          }
          xs
          i 1 prim +
          new-len
          run-loop
        ]
        [
          xs
          i 1 prim +
          max
          1
          run-loop
        ]
        if
      ]
      if
    ]
    [
      curr-len max prim <
      [ max ]
      [ curr-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [
      xs
      1
      0
      0
      run-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 26, column 11
message: `new-len` is not a defined word, primitive or local.
actual: new-len
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [
        xs
        target
        i
        j 1 prim +
        pair-inner
      ]
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ prim seq-bool.true ]
        [
          xs
          target
          i
          j 1 prim +
          pair-inner
        ]
        if
      ]
      if
    ]
    [
      xs
      target
      i 1 prim +
      i 2 prim +
      pair-inner
    ]
    if
  };

: pair-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs
      target
      i
      i 1 prim +
      pair-inner
    ]
    [ prim seq-bool.false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs
    target
    0
    pair-outer
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 16, column 16
message: Unexpected `seq-bool.true`, expected `primitive name`.
expected: primitive name
actual: seq-bool.true
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains
  (forall ρ; ρ val:Int^many seen:Seq Int^many i:Int^many -- ρ is-present:Bool^many)
  locals { val seen i } {
    i seen prim seq-int.len prim <
    [
      seen i prim seq-int.at val prim =
      [ prim seq-bool.true ]
      [
        val
        seen
        i 1 prim +
        contains
      ]
      if
    ]
    [ prim seq-bool.false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ count:Int^many seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ distinct:Int^many)
  locals { count seen xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { count seen xs i curr } {
        curr
        seen
        0
        contains
        [
          count
          seen
          xs
          i 1 prim +
          count-distinct-loop
        ]
        [
          count 1 prim +
          seen curr prim seq-int.push
          xs
          i 1 prim +
          count-distinct-loop
        ]
        if
      }
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0
    prim seq-int.empty
    xs
    0
    count-distinct-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 7, column 14
message: Unexpected `seq-bool.true`, expected `primitive name`.
expected: primitive name
actual: seq-bool.true
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ]
    if
  };

: reverse-seq
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result seq i } {
    i 0 prim <
    [
      result seq i prim seq-int.at prim seq-int.push
      seq
      i 1 prim -
      reverse-seq
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty
      n
      digits-loop
      prim seq-int.empty
      swap
      swap prim seq-int.len 1 prim -
      reverse-seq
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 44, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ { 0 } ]`, `reverse-seq` needs 3 values (result:Seq Int, seq:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `digits-loop` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-seq`, exactly the values it takes, in this order: result:Seq Int, seq:Seq Int, i:Int. The branch already pushes the result of `digits-loop` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-helper
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ prim seq-bool.false ]
      [
        n
        d 1 prim +
        is-prime-helper
      ]
      if
    ]
    [ prim seq-bool.true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ prim seq-bool.false ]
    [ n 2 is-prime-helper ]
    if
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many i:Int^many -- ρ primes:Seq Int^many)
  locals { result n i } {
    i n prim <
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      n
      i 1 prim +
      primes-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    n
    2
    primes-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 7, column 14
message: Unexpected `seq-bool.false`, expected `primitive name`.
expected: primitive name
actual: seq-bool.false
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: hist-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ histogram:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { counts xs i v } {
        counts v prim seq-int.at 1 prim + 
        counts v prim seq-int.set
      }
      xs
      i 1 prim +
      hist-loop
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ k prim seq-int.push 0 prim seq-int.push ] call
    xs
    0
    hist-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 18, column 5
message: In the true branch `[ xs i prim seq-int.at locals { counts ...` of the `if` in `hist-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ inserted:Seq Int^many)
  locals { result val i } {
    i 0 prim <
    [
      result i 1 prim + prim seq-int.at val prim <
      [
        result i val prim seq-int.set
        val
        result
        i 1 prim -
        insert-loop
      ]
      [
        result
      ]
      if
    ]
    [
      result val prim seq-int.set
    ]
    if
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { result xs i v } {
        result v prim seq-int.push
        result
        v
        result prim seq-int.len 2 prim -
        insert-loop
      }
      xs
      i 1 prim +
      insertion-sort-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    0
    insertion-sort-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 17, column 7
message: The two branches of the `if` in `insert-loop` whose true branch is `[ result i val prim seq-int.set val result ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim +
      locals { balance rejected txs i new-bal } {
        new-bal 0 prim <
        [
          balance
          rejected 1 prim +
          txs
          i 1 prim +
          ledger-loop
        ]
        [
          new-bal
          rejected
          txs
          i 1 prim +
          ledger-loop
        ]
        if
      }
    ]
    [
      balance
      rejected
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    txs
    0
    ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 30, column 5
message: In the true branch `[ balance txs i prim seq-int.at prim + ...` of the `if` in `ledger-loop`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole i } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { stock allocated reasons items qtys whole i item } {
        stock item prim seq-int.at
        locals { stock allocated reasons items qtys whole i item curr-stock } {
          qtys i prim seq-int.at curr-stock prim <
          [
            curr-stock 0 prim =
            [
              stock item 0 prim seq-int.set
              allocated 0 prim seq-int.push
              reasons 2 prim seq-int.push
              stock
              allocated
              reasons
              items
              qtys
              whole
              i 1 prim +
              allocate-loop
            ]
            [
              whole i prim seq-bool.at
              [
                stock item 0 prim seq-int.set
                allocated 0 prim seq-int.push
                reasons 3 prim seq-int.push
                stock
                allocated
                reasons
                items
                qtys
                whole
                i 1 prim +
                allocate-loop
              ]
              [
                stock item 0 prim seq-int.set
                allocated curr-stock prim seq-int.push
                reasons 1 prim seq-int.push
                stock
                allocated
                reasons
                items
                qtys
                whole
                i 1 prim +
                allocate-loop
              ]
              if
            ]
            if
          ]
          [
            stock item qtys i prim seq-int.at prim seq-int.set
            allocated qtys i prim seq-int.at prim seq-int.push
            reasons 0 prim seq-int.push
            stock
            allocated
            reasons
            items
            qtys
            whole
            i 1 prim +
            allocate-loop
          ]
          if
        }
      }
    ]
    [
      stock
      allocated
      reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    items
    qtys
    whole
    0
    allocate-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 80, column 5
message: In the true branch `[ items i prim seq-int.at locals { stock ...` of the `if` in `allocate-loop`, `locals` needs 8 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 7 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.
