Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  ( -- total:Int^many )
  locals { xs } {
    0 [ xs 0 helper-sum ] call
  };

: helper-sum
  (forall ρ; ρ acc:Int^many idx:Int^many -- ρ result:Int^many)
  locals { idx acc xs } {
    xs idx prim seq-int.len prim <
    [ xs idx prim seq-int.at acc prim + idx 1 prim + helper-sum ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  ( -- largest:Int^many )
  locals { xs } {
    xs 0 prim seq-int.at
    1 xs prim seq-int.len helper-max
  };

: helper-max
  (forall ρ; ρ idx:Int^many len:Int^many current:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { current len idx xs } {
    idx len prim <
    [ xs idx prim seq-int.at dup current prim < [ drop current ] [ swap drop ] if
      idx 1 prim + len current xs helper-max ]
    [ current ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } {
    0 0 [ xs k helper-count ] call
  };

: helper-count
  (forall ρ; ρ acc:Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs k idx acc } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v k prim <
        [ acc 1 prim + ]
        [ acc ]
        if
      }
      idx 1 prim + acc k xs helper-count
    ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `helper-count` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } {
    0 [ xs x -1 helper-index ] call
  };

: helper-index
  (forall ρ; ρ idx:Int^many x:Int^many notfound:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { notfound x idx xs } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at x prim =
      [ idx ]
      [ idx 1 prim + x notfound xs helper-index ]
      if
    ]
    [ notfound ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `helper-index` in `main` needs Int Int Int Seq Int on top of the stack, but the stack before it is .. Int Int Int Int.
expected: .. Int Int Int Seq Int
actual: .. ?t10 ?t9 Int
hint: `helper-index` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  ( -- reversed:Seq Int^many )
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - [ xs swap helper-reverse ] call
  };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim <
    [ result ]
    [
      xs idx prim seq-int.at result prim seq-int.push
      idx 1 prim - xs result helper-reverse
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  ( -- sums:Seq Int^many )
  locals { xs } {
    prim seq-int.empty 0 0 [ xs helper-prefix ] call
  };

: helper-prefix
  (forall ρ; ρ result:Seq Int^many acc:Int^many idx:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs idx acc result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at acc prim + locals { newsum } {
        result newsum prim seq-int.push
        idx 1 prim + newsum xs helper-prefix
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  ( -- positives:Seq Int^many )
  locals { xs } {
    prim seq-int.empty 0 [ xs helper-keep ] call
  };

: helper-keep
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v 0 prim <
        [ result ]
        [ result v prim seq-int.push ]
        if
      }
      idx 1 prim + xs helper-keep
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  ( -- sorted:Bool^many )
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 true [ xs helper-issorted ] call ]
    if
  };

: helper-issorted
  (forall ρ; ρ idx:Int^many acc:Bool^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs acc idx } {
    acc prim not
    [
      false
    ]
    [
      idx xs prim seq-int.len 1 prim - prim <
      [
        xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
        [ idx 1 prim + false xs helper-issorted ]
        [ idx 1 prim + acc xs helper-issorted ]
        if
      ]
      [ acc ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs } {
    0 0 [ xs ys helper-dot ] call
  };

: helper-dot
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { ys xs idx acc } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim +
      idx 1 prim + xs ys helper-dot
    ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.len` in `helper-dot` needs Seq Int on top of the stack, but the stack before it is ρ Int Int Seq Int Seq Int Seq Int Int.
expected: .. Seq Int
actual: ρ Int Int Seq Int Seq Int Seq Int Int
hint: The top value is Int but `prim seq-int.len` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  ( -- all:Bool^many )
  locals { flags } {
    flags prim seq-bool.len 0 prim =
    [ true ]
    [ 0 true [ flags helper-alltrue ] call ]
    if
  };

: helper-alltrue
  (forall ρ; ρ idx:Int^many acc:Bool^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags acc idx } {
    idx flags prim seq-bool.len prim <
    [
      flags idx prim seq-bool.at acc prim and
      idx 1 prim + flags helper-alltrue
    ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  ( -- length:Int^many )
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [
      xs 0 prim seq-int.at 1 1 0 [ xs helper-longrun ] call
    ]
    if
  };

: helper-longrun
  (forall ρ; ρ maxlen:Int^many curlen:Int^many prev:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs idx prev curlen maxlen } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v prev prim =
        [ curlen 1 prim + ]
        [ 1 ]
        if
        locals { newlen } {
          newlen maxlen prim <
          [ maxlen ]
          [ newlen ]
          if
          locals { newmax } {
            idx 1 prim + v newlen newmax xs helper-longrun
          }
        }
      }
    ]
    [ maxlen ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } {
    0 [ xs target false helper-pair ] call
  };

: helper-pair
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many acc:Bool^many -- ρ result:Bool^many)
  locals { acc target xs i } {
    acc
    [ true ]
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + [ xs target i helper-pair-inner ] call
        i xs target helper-pair
      ]
      [ false ]
      if
    ]
    if
  };

: helper-pair-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + i xs target helper-pair-inner ]
      if
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int [ .. Int -- .. Int Int Seq Int ] [ .. Int Seq Int Int -- .. Bool ]. Expected Int, found Seq Int.
expected: Int
actual: Seq Int

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  ( -- count:Int^many )
  locals { xs } {
    prim seq-int.empty 0 [ xs helper-distinct ] call
  };

: helper-distinct
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { seen xs idx count } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        [ v seen helper-find ] call
        [ count 1 prim + seen v prim seq-int.push ]
        [ count seen ]
        if
      }
      idx 1 prim + xs helper-distinct
    ]
    [ count ]
    if
  };

: helper-find
  (forall ρ; ρ v:Int^many seen:Seq Int^many -- ρ found:Bool^many)
  locals { seen v } {
    0 [ v seen helper-find-loop ] call
  };

: helper-find-loop
  (forall ρ; ρ i:Int^many v:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { seen v i } {
    i seen prim seq-int.len prim <
    [
      seen i prim seq-int.at v prim =
      [ true ]
      [ i 1 prim + v seen helper-find-loop ]
      if
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } {
    prim seq-int.empty 0 0 [ xs ys helper-merge ] call
  };

: helper-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ out:Seq Int^many)
  locals { ys xs j i result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim + j xs ys helper-merge
      ]
      [
        result ys j prim seq-int.at prim seq-int.push
        i j 1 prim + xs ys helper-merge
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys helper-merge ]
      [ j ys prim seq-int.len prim <
        [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys helper-merge ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.len` in `helper-merge` needs Seq Int on top of the stack, but the stack before it is ρ Seq Int Int Int Seq Int Seq Int Seq Int Int.
expected: .. Seq Int
actual: ρ Seq Int Int Int Seq Int Seq Int Seq Int Int
hint: The top value is Int but `prim seq-int.len` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  ( -- digits:Seq Int^many )
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [
      n 0 prim <
      [ n 0 prim - [ helper-digits-loop ] call ]
      [ n [ helper-digits-loop ] call ]
      if
    ]
    if
  };

: helper-digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ out:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result swap prim seq-int.push
      n 10 prim div
      helper-digits-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  ( -- primes:Seq Int^many )
  locals { n } {
    prim seq-int.empty 2 [ n helper-primes ] call
  };

: helper-primes
  (forall ρ; ρ result:Seq Int^many num:Int^many n:Int^many -- ρ out:Seq Int^many)
  locals { n num result } {
    num n prim <
    [
      [ num helper-is-prime ] call
      [ result num prim seq-int.push ]
      [ result ]
      if
      num 1 prim + n helper-primes
    ]
    [ result ]
    if
  };

: helper-is-prime
  (forall ρ; ρ num:Int^many -- ρ is:Bool^many)
  locals { num } {
    num 2 prim <
    [ false ]
    [
      num 2 prim =
      [ true ]
      [ num 2 prim mod 0 prim = [ false ] [ 2 [ num helper-check-prime ] call ] if ]
      if
    ]
    if
  };

: helper-check-prime
  (forall ρ; ρ i:Int^many num:Int^many -- ρ result:Bool^many)
  locals { num i } {
    i i prim * num prim <
    [
      num i prim mod 0 prim =
      [ false ]
      [ i 2 prim + num helper-check-prime ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } {
    prim seq-int.empty
    [ 0 k prim seq-int.push ] call
    0 [ xs k helper-histogram ] call
  };

: helper-histogram
  (forall ρ; ρ result:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs k idx result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        result v prim seq-int.at 1 prim + v result prim seq-int.set
      }
      idx 1 prim + xs k helper-histogram
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. Int ?t8.
expected: .. Seq Int Int
actual: .. Int ?t8
hint: The top value is ?t8 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  ( -- sorted:Seq Int^many )
  locals { xs } {
    xs 0 [ xs helper-insertion-sort ] call
  };

: helper-insertion-sort
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at result 0 i [ xs helper-insert ] call
      i 1 prim + xs helper-insertion-sort
    ]
    [ result ]
    if
  };

: helper-insert
  (forall ρ; ρ j:Int^many i:Int^many val:Int^many result:Seq Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs result val i j } {
    j 0 prim <
    [ result val prim seq-int.push ]
    [
      result j prim seq-int.at val prim <
      [ result j prim seq-int.at result prim seq-int.push j 1 prim - i val result xs helper-insert ]
      [ result val prim seq-int.push ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } {
    start 0 0 [ txs helper-ledger ] call
  };

: helper-ledger
  (forall ρ; ρ rejected:Int^many balance:Int^many idx:Int^many txs:Seq Int^many -- ρ b:Int^many r:Int^many)
  locals { txs idx balance rejected } {
    idx txs prim seq-int.len prim <
    [
      txs idx prim seq-int.at locals { tx } {
        balance tx prim + 0 prim <
        [ rejected 1 prim + balance idx txs helper-ledger ]
        [ balance tx prim + rejected idx txs helper-ledger ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Int Int Int [ .. Int Int Int -- .. Int Int Int Int ] [ .. Int Int Int Seq Int -- .. Int Int ]. Expected Int, found Seq Int.
expected: Int
actual: Seq Int

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 [ items qtys whole helper-allocate ] call
  };

: helper-allocate
  (forall ρ; ρ reasons:Seq Int^many allocated:Seq Int^many stock:Seq Int^many idx:Int^many whole:Seq Bool^many qtys:Seq Int^many items:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { items qtys whole idx allocated reasons stock } {
    idx items prim seq-int.len prim <
    [
      items idx prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { r } {
          qtys idx prim seq-int.at locals { q } {
            q r prim <
            [
              stock item prim seq-int.at q prim - item stock prim seq-int.set locals { newstock } {
                allocated q prim seq-int.push
                reasons 0 prim seq-int.push
                idx 1 prim + items qtys whole newstock allocated reasons helper-allocate
              }
            ]
            [
              r 0 prim =
              [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                idx 1 prim + items qtys whole stock allocated reasons helper-allocate
              ]
              [
                whole idx prim seq-bool.at
                [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  idx 1 prim + items qtys whole stock allocated reasons helper-allocate
                ]
                [
                  stock item prim seq-int.at 0 item stock prim seq-int.set locals { newstock } {
                    allocated r prim seq-int.push
                    reasons 1 prim seq-int.push
                    idx 1 prim + items qtys whole newstock allocated reasons helper-allocate
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
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `helper-allocate` leave different numbers of values: the true branch pushes 5 values, and the false branch pushes 6 values. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.
