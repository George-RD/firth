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
  locals { xs i acc }
  i xs prim seq-int.len prim <
  [ xs i prim seq-int.at acc prim + i 1 prim + sum-loop ]
  [ acc ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 sum-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { elem } {
      max-val elem prim <
      [ elem i 1 prim + max-loop ]
      [ max-val i 1 prim + max-loop ]
      if
    }
  ]
  [ max-val ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    locals { first } {
      xs 1 first max-loop
    }
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs i k cnt }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { elem } {
      elem k prim <
      [ cnt 1 prim + i 1 prim + count-loop ]
      [ cnt i 1 prim + count-loop ]
      if
    }
  ]
  [ cnt ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 0 count-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { elem } {
      elem x prim =
      [ i ]
      [ i 1 prim + find-loop ]
      if
    }
  ]
  [ -1 ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  0 find-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result }
  i 0 prim <
  [
    xs i prim seq-int.at
    locals { elem } {
      result elem prim seq-int.push
      i -1 prim + reverse-loop
    }
  ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { elem } {
      sum elem prim +
      locals { new-sum } {
        result new-sum prim seq-int.push
        i 1 prim + new-sum prefix-loop
      }
    }
  ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  0 0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { elem } {
      elem 0 prim <
      [ result i 1 prim + filter-loop ]
      [ result elem prim seq-int.push i 1 prim + filter-loop ]
      if
    }
  ]
  [ result ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  0 prim seq-int.empty filter-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i }
  i xs prim seq-int.len 1 prim - prim <
  [
    xs i prim seq-int.at
    locals { curr } {
      xs i 1 prim + prim seq-int.at
      locals { next } {
        curr next prim <
        [ i 1 prim + check-loop ]
        [ false ]
        if
      }
    }
  ]
  [ true ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 check-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { x } {
      ys i prim seq-int.at
      locals { y } {
        x y prim *
        sum prim +
        i 1 prim + dot-loop
      }
    }
  ]
  [ sum ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i }
  i flags prim seq-bool.len prim <
  [
    flags i prim seq-bool.at prim not
    [ false ]
    [ i 1 prim + check-all ]
    if
  ]
  [ true ]
  if;

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 check-all;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many curr-val:Int^many curr-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { xs i curr-val curr-len max-len }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { elem } {
      elem curr-val prim =
      [
        curr-len 1 prim +
        locals { new-len } {
          new-len max-len prim <
          [ i 1 prim + elem new-len max-len run-loop ]
          [ i 1 prim + elem new-len new-len run-loop ]
          if
        }
      ]
      [
        curr-len max-len prim <
        [ i 1 prim + elem 1 max-len run-loop ]
        [ i 1 prim + elem 1 curr-len run-loop ]
        if
      ]
      if
    }
  ]
  [ max-len ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs xs prim seq-int.len 0 prim =
  [ 0 ]
  [ xs 1 xs 0 prim seq-int.at 1 0 run-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-check
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j }
  i xs prim seq-int.len prim <
  [
    j xs prim seq-int.len prim <
    [
      i j prim =
      [ j 1 prim + pair-check ]
      [
        xs i prim seq-int.at
        locals { xi } {
          xs j prim seq-int.at
          locals { xj } {
            xi xj prim +
            locals { sum } {
              sum target prim =
              [ true ]
              [ j 1 prim + pair-check ]
              if
            }
          }
        }
      ]
      if
    ]
    [ i 1 prim + 0 pair-check ]
  ]
  [ false ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 0 pair-check;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ count:Int^many)
  locals { xs i count }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { val } {
      val 0 is-new
      [ i 1 prim + count 1 prim + count-loop ]
      [ i 1 prim + count-loop ]
      if
    }
  ]
  [ count ]
  if;

: is-new
  (forall ρ; ρ xs:Seq Int^many val:Int^many idx:Int^many -- ρ new:Bool^many)
  locals { xs val idx }
  idx xs prim seq-int.len prim <
  [
    xs idx prim seq-int.at val prim =
    [ false ]
    [ idx 1 prim + is-new ]
    if
  ]
  [ true ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 count-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result }
  i xs prim seq-int.len prim <
  [
    j ys prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        ys j prim seq-int.at
        locals { y } {
          x y prim <
          [ result x prim seq-int.push i 1 prim + merge-loop ]
          [ result y prim seq-int.push j 1 prim + merge-loop ]
          if
        }
      }
    ]
    [
      i xs prim seq-int.len prim <
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + merge-loop ]
      [ result ]
      if
    ]
  ]
  [
    j ys prim seq-int.len prim <
    [ result ys j prim seq-int.at prim seq-int.push j 1 prim + merge-loop ]
    [ result ]
    if
  ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  0 0 prim seq-int.empty merge-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many digits:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n digits }
  n 0 prim =
  [ digits ]
  [
    n 10 prim mod
    locals { d } {
      digits d prim seq-int.push
      n 10 prim div digit-loop
    }
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty
      locals { empty } {
        n digit-loop
        locals { d-rev } {
          d-rev d-rev prim seq-int.len 1 prim - 0 [ swap prim seq-int.at ] reverse-digits
        }
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ digits:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { digits i result }
  i 0 prim <
  [ result digits i prim seq-int.at prim seq-int.push i -1 prim + reverse-digits ]
  [ result ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `n`, expected `{`.
expected: {
actual: n
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  n 2 prim <
  [ false ]
  [
    2 is-prime-loop
  ]
  if;

: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d }
  d d prim * n prim <
  [
    n d prim mod 0 prim =
    [ false ]
    [ d 1 prim + is-prime-loop ]
    if
  ]
  [ true ]
  if;

: count-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result }
  i n prim <
  [
    i is-prime
    [ result i prim seq-int.push i 1 prim + count-loop ]
    [ i 1 prim + count-loop ]
    if
  ]
  [ result ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  2 prim seq-int.empty count-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 13, column 3
message: Unexpected `d`, expected `{`.
expected: {
actual: d
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { xs k counts i }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { val } {
      counts val prim seq-int.at
      locals { c } {
        counts val c 1 prim + prim seq-int.set
        i 1 prim + count-loop
      }
    }
  ]
  [ counts ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k } {
    prim seq-int.empty
    locals { init } {
      0 init-histogram
    }
  };

: init-histogram
  (forall ρ; ρ i:Int^many counts:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { i counts k }
  i k prim <
  [ counts 0 prim seq-int.push i 1 prim + init-histogram ]
  [ counts 0 count-loop ]
  if;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i }
  i xs prim seq-int.len prim <
  [
    xs i prim seq-int.at
    locals { val } {
      i insert-at
    }
  ]
  [ xs ]
  if;

: insert-at
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many -- ρ xs:Seq Int^many)
  locals { xs val j }
  j 0 prim =
  [ xs val prim seq-int.push ]
  [
    xs j 1 prim - prim seq-int.at
    locals { prev } {
      prev val prim <
      [ xs val prim seq-int.push ]
      [
        xs j xs j 1 prim - prim seq-int.at prim seq-int.set
        j 1 prim - insert-at
      ]
      if
    }
  ]
  if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty 0 insertion-sort;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: transaction-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int rejected:Int)
  locals { balance txs i rejected }
  i txs prim seq-int.len prim <
  [
    txs i prim seq-int.at
    locals { tx } {
      balance tx prim + 0 prim <
      [ balance i 1 prim + rejected 1 prim + transaction-loop ]
      [ balance tx prim + i 1 prim + rejected transaction-loop ]
      if
    }
  ]
  [ balance rejected ]
  if;

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int rejected:Int)
  0 transaction-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `i`, expected `{`.
expected: {
actual: i
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: batch-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  locals { stock items qtys whole j allocated reasons }
  j qtys prim seq-int.len prim <
  [
    items j prim seq-int.at
    locals { item-idx } {
      stock item-idx prim seq-int.at
      locals { r } {
        qtys j prim seq-int.at
        locals { q } {
          whole j prim seq-bool.at
          locals { w } {
            q r prim <
            [
              allocated q prim seq-int.push
              reasons 0 prim seq-int.push
              stock item-idx r q prim - prim seq-int.set
              j 1 prim + batch-loop
            ]
            [
              r 0 prim =
              [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                j 1 prim + batch-loop
              ]
              [
                w
                [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  j 1 prim + batch-loop
                ]
                [
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                  stock item-idx 0 prim seq-int.set
                  j 1 prim + batch-loop
                ]
                if
              ]
              if
            ]
          }
        }
      }
    }
  ]
  [ stock allocated reasons ]
  if;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  0 prim seq-int.empty prim seq-int.empty batch-loop;

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 4, column 3
message: Unexpected `j`, expected `{`.
expected: {
actual: j
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
