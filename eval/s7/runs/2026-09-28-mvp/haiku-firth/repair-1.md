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
  0 0 xs sum-loop;

: sum-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    [ i xs prim seq-int.len prim = ]
    [ acc ]
    [ 
      i 1 prim +
      xs i prim seq-int.at acc prim +
      xs
      sum-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at xs 1 max-loop;

: max-loop
  (forall ρ; ρ i:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs i max } {
    [ i xs prim seq-int.len prim = ]
    [ max ]
    [
      i 1 prim +
      xs i prim seq-int.at max
      [ xs i prim seq-int.at max prim < ]
      [ max ]
      [ xs i prim seq-int.at ]
      if
      xs
      max-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 xs count-helper;

: count-helper
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { k xs i count } {
    [ i xs prim seq-int.len prim = ]
    [ count ]
    [
      i 1 prim +
      [ xs i prim seq-int.at k prim < ]
      [ count 1 prim + ]
      [ count ]
      if
      xs
      k
      count-helper
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  -1 0 xs find-index;

: find-index
  (forall ρ; ρ i:Int^many result:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs i result } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      [ result -1 prim = ]
      [
        [ xs i prim seq-int.at x prim = ]
        [ i ]
        [ -1 ]
        if
        i 1 prim +
        xs
        x
        find-index
      ]
      [ result i 1 prim + xs x find-index ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty 0 xs reverse-helper;

: reverse-helper
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim +
      xs
      reverse-helper
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 xs prefix-loop;

: prefix-loop
  (forall ρ; ρ i:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs result sum i } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      xs i prim seq-int.at sum prim +
      result prim seq-int.push
      i 1 prim +
      xs
      prefix-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 xs keep-positive-loop;

: keep-positive-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim = ]
    [ result ]
    [
      [ xs i prim seq-int.at 0 prim < ]
      [ result ]
      [ xs i prim seq-int.at result prim seq-int.push ]
      if
      i 1 prim +
      xs
      keep-positive-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  true 0 xs is-sorted-loop;

: is-sorted-loop
  (forall ρ; ρ i:Int^many is-sorted:Bool^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs i is-sorted } {
    [ i xs prim seq-int.len 1 prim - prim = ]
    [ is-sorted ]
    [
      [ is-sorted prim not ]
      [ is-sorted ]
      [
        [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < ]
        [ false ]
        [ true ]
        if
      ]
      if
      i 1 prim +
      xs
      is-sorted-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 xs ys dot-loop;

: dot-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs i acc } {
    [ i xs prim seq-int.len prim = ]
    [ acc ]
    [
      i 1 prim +
      xs i prim seq-int.at ys i prim seq-int.at prim * acc prim +
      xs
      ys
      dot-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true 0 flags all-true-loop;

: all-true-loop
  (forall ρ; ρ i:Int^many result:Bool^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags i result } {
    [ i flags prim seq-bool.len prim = ]
    [ result ]
    [
      [ result prim not ]
      [ false ]
      [ flags i prim seq-bool.at ]
      if
      i 1 prim +
      flags
      all-true-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 1 0 xs longest-run-loop;

: longest-run-loop
  (forall ρ; ρ i:Int^many current:Int^many max:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { xs max current i } {
    [ i xs prim seq-int.len prim = ]
    [
      [ current max prim < ]
      [ max ]
      [ current ]
      if
    ]
    [
      [ i 0 prim = ]
      [
        i 1 prim +
        1
        1
        xs
        longest-run-loop
      ]
      [
        [ xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim = ]
        [
          i 1 prim +
          current 1 prim +
          max
          xs
          longest-run-loop
        ]
        [
          i 1 prim +
          1
          [ current max prim < ] [ max ] [ current ] if
          xs
          longest-run-loop
        ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false 0 xs target has-pair-sum-outer;

: has-pair-sum-outer
  (forall ρ; ρ i:Int^many found:Bool^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs i found } {
    [ i xs prim seq-int.len prim = ]
    [ found ]
    [
      [ found ]
      [ found i 1 prim + xs target has-pair-sum-outer ]
      [
        xs i prim seq-int.at target prim - 0 i 1 prim + xs has-pair-sum-inner
      ]
      if
    ]
    if
  };

: has-pair-sum-inner
  (forall ρ; ρ j:Int^many result:Bool^many xs:Seq Int^many complement:Int^many i:Int^many -- ρ found:Bool^many)
  locals { i complement xs j result } {
    [ j xs prim seq-int.len prim = ]
    [ result ]
    [
      [ result ]
      [ result i 1 prim + xs complement has-pair-sum-outer ]
      [
        [ xs j prim seq-int.at complement prim = ]
        [ true i 1 prim + xs complement has-pair-sum-outer ]
        [ j 1 prim + result xs complement i has-pair-sum-inner ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 xs count-distinct-loop;

: count-distinct-loop
  (forall ρ; ρ i:Int^many seen:Seq Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { xs seen i } {
    [ i xs prim seq-int.len prim = ]
    [ seen prim seq-int.len ]
    [
      xs i prim seq-int.at seen contains-element
      [ seen ]
      [ xs i prim seq-int.at seen prim seq-int.push ]
      if
      i 1 prim +
      xs
      count-distinct-loop
    ]
    if
  };

: contains-element
  (forall ρ; ρ seen:Seq Int^many elem:Int^many -- ρ result:Seq Int^many)
  false swap 0 swap contains-loop drop;

: contains-loop
  (forall ρ; ρ i:Int^many found:Bool^many seen:Seq Int^many elem:Int^many -- ρ result:Bool^many)
  locals { elem seen i found } {
    [ i seen prim seq-int.len prim = ]
    [ found ]
    [
      [ found ]
      [ found i 1 prim + seen elem contains-loop ]
      [
        [ seen i prim seq-int.at elem prim = ]
        [ true i 1 prim + seen elem contains-loop ]
        [ i 1 prim + false seen elem contains-loop ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 xs ys merge-loop;

: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs result i j } {
    [ i xs prim seq-int.len prim = ]
    [
      [ j ys prim seq-int.len prim = ]
      [ result ]
      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + xs ys merge-loop ]
      if
    ]
    [
      [ j ys prim seq-int.len prim = ]
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys merge-loop ]
      [
        [ xs i prim seq-int.at ys j prim seq-int.at prim < ]
        [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys merge-loop ]
        [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys merge-loop ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  [ n 0 prim = ]
  [ prim seq-int.empty 0 prim seq-int.push ]
  [ prim seq-int.empty n extract-digits ]
  if;

: extract-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    [ n 0 prim = ]
    [ result ]
    [
      n 10 prim *
      n 10 prim / prim -
      result prim seq-int.push
      n 10 prim /
      extract-digits
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `n` is not a defined word, primitive or local.
actual: n
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 n primes-loop;

: primes-loop
  (forall ρ; ρ i:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n result i } {
    [ i n prim < prim not ]
    [ result ]
    [
      i is-prime
      [ i result prim seq-int.push ]
      [ result ]
      if
      i 1 prim +
      n
      primes-loop
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  [ n 2 prim < ]
  [ false ]
  [
    [ n 2 prim = ]
    [ true ]
    [
      [ n 2 prim % 0 prim = ]
      [ false ]
      [ 2 n check-prime ]
      if
    ]
    if
  ]
  if;

: check-prime
  (forall ρ; ρ d:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    [ d d prim * n prim < prim not ]
    [ true ]
    [
      [ n d prim % 0 prim = ]
      [ false ]
      [ d 2 prim + n check-prime ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `n` is not a defined word, primitive or local.
actual: n
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty 0 0 k init-histogram;

: init-histogram
  (forall ρ; ρ i:Int^many result:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k result i } {
    [ i k prim = ]
    [ result ]
    [ 0 result prim seq-int.push i 1 prim + k init-histogram ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `k` is not a defined word, primitive or local.
actual: k
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs bubble-sort;

: bubble-sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 xs prim seq-int.len bubble-pass;

: bubble-pass
  (forall ρ; ρ n:Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { i xs n } {
    [ n 0 prim = ]
    [ xs ]
    [
      [ i xs prim seq-int.len 1 prim - prim = ]
      [ xs n 1 prim - bubble-pass ]
      [
        [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < ]
        [ i 1 prim + xs n bubble-pass ]
        [ 
          xs i prim seq-int.at
          xs i 1 prim + prim seq-int.at
          swap-elements
          i 1 prim +
          n
          bubble-pass
        ]
        if
      ]
      if
    ]
    if
  };

: swap-elements
  (forall ρ; ρ val2:Int^many val1:Int^many xs:Seq Int^many i:Int^many -- ρ swapped:Seq Int^many)
  xs val1 prim seq-int.push val2 prim seq-int.push;

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 start txs ledger-loop;

: ledger-loop
  (forall ρ; ρ i:Int^many rejected:Int^many balance:Int^many txs:Seq Int^many start:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs balance rejected i } {
    [ i txs prim seq-int.len prim = ]
    [ balance rejected ]
    [
      [ balance txs i prim seq-int.at prim + 0 prim < ]
      [ balance i 1 prim + rejected 1 prim + txs start ledger-loop ]
      [ balance txs i prim seq-int.at prim + i 1 prim + rejected txs start ledger-loop ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `start` is not a defined word, primitive or local.
actual: start
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 stock items qtys whole allocate-orders;

: allocate-orders
  (forall ρ; ρ j:Int^many whole:Seq Bool^many qtys:Seq Int^many items:Seq Int^many stock:Seq Int^many reasons:Seq Int^many allocated:Seq Int^many stock-left:Seq Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock reasons allocated stock-left j } {
    [ j qtys prim seq-int.len prim = ]
    [ stock-left allocated reasons ]
    [
      items j prim seq-int.at
      stock-left
      qtys j prim seq-int.at
      whole j prim seq-bool.at
      allocate-one-order
      swap
      swap
      j 1 prim +
      whole
      qtys
      items
      stock
      allocate-orders
    ]
    if
  };

: allocate-one-order
  (forall ρ; ρ want-whole:Bool^many qty:Int^many stock-seq:Seq Int^many item:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-seq:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { want-whole qty stock-seq item reasons allocated } {
    stock-seq item prim seq-int.at
    locals { avail } {
      [ qty avail prim = ]
      [ qty 0 prim seq-int.push avail qty prim - prim seq-int.push ]
      [
        [ avail 0 prim = ]
        [ 0 2 prim seq-int.push ]
        [
          [ want-whole ]
          [ 0 3 prim seq-int.push ]
          [ avail 1 prim seq-int.push ]
          if
        ]
        if
      ]
      if
      locals { alloc reason } {
        stock-seq item alloc update-stock
        allocated alloc prim seq-int.push
        reasons reason prim seq-int.push
      }
    }
  };

: update-stock
  (forall ρ; ρ alloc:Int^many item:Int^many stock-seq:Seq Int^many -- ρ updated:Seq Int^many)
  prim seq-int.empty swap 0 swap stock-seq update-stock-loop;

: update-stock-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many stock-seq:Seq Int^many item:Int^many alloc:Int^many -- ρ updated:Seq Int^many)
  locals { alloc item stock-seq result i } {
    [ i stock-seq prim seq-int.len prim = ]
    [ result ]
    [
      [ i item prim = ]
      [ stock-seq i prim seq-int.at alloc prim - result prim seq-int.push ]
      [ stock-seq i prim seq-int.at result prim seq-int.push ]
      if
      i 1 prim +
      stock-seq
      update-stock-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `stock` is not a defined word, primitive or local.
actual: stock
hint: Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. A definition looks like `: name (forall \u03c1; \u03c1 n:Int^many -- \u03c1 r:Int^many) body;`.
