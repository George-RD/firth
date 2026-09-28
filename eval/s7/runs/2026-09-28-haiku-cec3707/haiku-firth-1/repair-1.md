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
  0 swap 0 sum-loop;

: sum-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many -- ρ result:Int^many)
  locals { i xs sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      i 1 prim + xs swap swap sum-loop
    ]
    [
      sum
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `sum-loop` in `sum-loop` needs Int Seq Int Int on top of the stack, but the stack before it is .. Int Int Seq Int.
expected: .. Int Seq Int Int
actual: .. Int Int Seq Int
hint: The top value is Seq Int but `sum-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    1 xs xs 0 prim seq-int.at max-loop
  };

: max-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup max prim <
      [ drop max ]
      [ swap drop ]
      if
      i 1 prim + xs swap swap max-loop
    ]
    [
      max
    ]
    if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.untracked-local', 'severity': 'error', 'message_key': 'diagnostic.u

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
    0 xs 0 count-loop k
  };

: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many k:Int^many)
  locals { count xs i k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup k prim <
      [ drop count 1 prim + ]
      [ drop count ]
      if
      i 1 prim + xs swap swap count-loop k
    ]
    [
      count k
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
message: `main` declares that it leaves \u03c1 Int but its body leaves \u03c1 Int Int Int.
expected: \u03c1 Int
actual: \u03c1 Int Int Int

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
    prim seq-int.empty 0 xs reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim + swap xs reverse-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `reverse-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t19.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t19
hint: The top value is ?t19 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 0 0 xs prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      dup result prim seq-int.push
      i 1 prim + swap swap xs prefix-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `prefix-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int Int ?t25.
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t25
hint: The top value is ?t25 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 0 xs filter-positive
  };

: filter-positive
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup 0 prim <
      [ drop ]
      [ result prim seq-int.push ]
      if
      i 1 prim + swap xs filter-positive
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.untracked-local', 'severity': 'error', 'message_key': 'diagnostic.u

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
    [ 1 xs true check-sorted ]
    if
  };

: check-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many ok:Bool^many -- ρ result:Bool^many)
  locals { i xs ok } {
    ok prim not
    [ false ]
    [
      i xs prim seq-int.len prim <
      [
        xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim <
        [ false i 1 prim + xs check-sorted ]
        [ i 1 prim + xs true check-sorted ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `check-sorted` in `check-sorted` needs Int Seq Int Bool on top of the stack, but the stack before it is .. Bool Int ?t46.
expected: .. Int Seq Int Bool
actual: .. Bool Int ?t46
hint: The top value is ?t46 but `check-sorted` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    0 flags true check-all-true
  };

: check-all-true
  (forall ρ; ρ i:Int^many flags:Seq Bool^many ok:Bool^many -- ρ result:Bool^many)
  locals { i flags ok } {
    ok prim not
    [ false ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at prim not
        [ false i 1 prim + flags check-all-true ]
        [ i 1 prim + flags true check-all-true ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `check-all-true` in `check-all-true` needs Int Seq Bool Bool on top of the stack, but the stack before it is .. Bool Int ?t40.
expected: .. Int Seq Bool Bool
actual: .. Bool Int ?t40
hint: The top value is ?t40 but `check-all-true` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [
    locals { xs } {
      xs 0 prim seq-int.at 1 0 1 xs longest-run-loop
    }
  ]
  if;

: longest-run-loop
  (forall ρ; ρ prev:Int^many current:Int^many max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { prev current max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup prev prim =
      [ drop current 1 prim + ]
      [ swap drop 1 ]
      if
      dup max [ prim < ] dip
      [ ]
      [ swap drop ]
      if
      i 1 prim + xs swap swap swap longest-run-loop
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `xs` is not a defined word, primitive or local.
actual: xs

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
    0 xs target false check-pair-sum
  };

: check-pair-sum
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { i xs target found } {
    found prim not
    [ i 1 prim + xs target check-pair-sum-j ]
    [ true ]
    if
  };

: check-pair-sum-j
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      0 xs target i false check-j-loop
    ]
    [ false ]
    if
  };

: check-j-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { j xs target i found } {
    found prim not
    [
      j xs prim seq-int.len prim <
      [
        j i prim =
        [ j 1 prim + xs target i found check-j-loop ]
        [
          xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
          [ true j 1 prim + xs target i check-pair-sum ]
          [ j 1 prim + xs target i false check-j-loop ]
          if
        ]
        if
      ]
      [ i 1 prim + xs target check-pair-sum ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
message: `compose` in `check-j-loop` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Seq Int Int Int Int Bool [ .. -- .. Int Seq Int Int Int ] [ .. Int Seq Int Int Bool -- .. Bool Bool ]. Expected Int, found Bool.
expected: Int
actual: Bool

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
    prim seq-int.empty 0 xs count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0 seen find-in-seq
      0 prim <
      [
        seen prim seq-int.push
        i 1 prim + xs count-distinct-loop
      ]
      [
        i 1 prim + xs count-distinct-loop
      ]
      if
    ]
    [ seen prim seq-int.len ]
    if
  };

: find-in-seq
  (forall ρ; ρ j:Int^many seen:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { j seen x } {
    j seen prim seq-int.len prim <
    [
      seen j prim seq-int.at x prim =
      [ j ]
      [ j 1 prim + seen x find-in-seq ]
      if
    ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `find-in-seq` in `count-distinct-loop` needs Int Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t19 Int Int ?t19.
expected: .. Int Seq Int Int
actual: .. Seq Int Int ?t19 Int Int ?t19
hint: The top value is ?t19 but `find-in-seq` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 0 0 xs ys merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j xs ys merge-loop ]
      [ ys j prim seq-int.at result prim seq-int.push i j 1 prim + xs ys merge-loop ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim + j xs ys merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at result prim seq-int.push
          i j 1 prim + xs ys merge-loop
        ]
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
message: `prim seq-int.push` in `merge-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t107 ?t106 Int ?t108.
expected: .. Seq Int Int
actual: .. Seq Int Int ?t107 ?t106 Int ?t108
hint: The top value is ?t108 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ prim seq-int.empty n extract-digits ]
    if
  };

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod result prim seq-int.push
      n 10 prim div swap extract-digits
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `extract-digits` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t18.
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: The top value is ?t18 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 2 n collect-primes
  };

: collect-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
        candidate 1 prim + n collect-primes
      ]
      [
        candidate 1 prim + n collect-primes
      ]
      if
    ]
    [ result ]
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
        2 n check-divisor
      ]
      if
    ]
    if
  };

: check-divisor
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [
        d 1 prim + n check-divisor
      ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.occurs-check
message: `if` in `collect-primes` failed the check firth.type.occurs-check; the stack before it is .. Seq Int Bool [ .. Seq Int -- .. Seq Int Seq Int ] [ .. Seq Int -- .. Seq Int ]. Expected .. Seq Int, found ...
expected: .. Seq Int
actual: ..

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
    prim seq-int.empty 0 k init-histogram xs 0 build-histogram
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ final:Seq Int^many xs:Seq Int^many x:Int^many)
  locals { result i k xs x } {
    i k prim <
    [ 0 result prim seq-int.push i 1 prim + k init-histogram xs x ]
    [ result xs x ]
    if
  };

: build-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      0 result increment-histogram
      i 1 prim + xs build-histogram
    ]
    [ result ]
    if
  };

: increment-histogram
  (forall ρ; ρ idx:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { idx result val } {
    idx result prim seq-int.len prim <
    [
      idx val prim =
      [ result idx prim seq-int.at 1 prim + result idx prim seq-int.at 1 prim + swap-at-idx val ]
      [ idx 1 prim + result val increment-histogram ]
      if
    ]
    [ result ]
    if
  };

: swap-at-idx
  (forall ρ; ρ result:Seq Int^many idx:Int^many new-val:Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result idx new-val val } {
    idx 0 prim =
    [
      new-val result prim seq-int.push
      1 result val build-rest
    ]
    [
      result 0 prim seq-int.at prim seq-int.empty prim seq-int.push
      idx 1 prim - result new-val val swap-at-idx
    ]
    if
  };

: build-rest
  (forall ρ; ρ i:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { i result val } {
    i val prim seq-int.len prim <
    [
      result val i prim seq-int.at prim seq-int.push
      i 1 prim + result val build-rest
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

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
    prim seq-int.empty xs 0 insertion-sort
  };

: insertion-sort
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result insert-into-sorted
      i 1 prim + xs sort-next
    ]
    [ result ]
    if
  };

: sort-next
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result insert-into-sorted
      i 1 prim + xs insertion-sort
    ]
    [ result ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { result val } {
    result prim seq-int.len 0 prim =
    [
      result val prim seq-int.push
    ]
    [
      0 val result 0 insert-find-position
    ]
    if
  };

: insert-find-position
  (forall ρ; ρ j:Int^many val:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { j val result } {
    j result prim seq-int.len prim <
    [
      result j prim seq-int.at val prim <
      [
        0 result prim seq-int.empty j insert-copy-until val result insert-copy-rest
      ]
      [
        j 1 prim + val result insert-find-position
      ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };

: insert-copy-until
  (forall ρ; ρ i:Int^many result:Seq Int^many new-result:Seq Int^many j:Int^many -- ρ final:Seq Int^many val:Int^many)
  locals { i result new-result j val } {
    i j prim <
    [
      result i prim seq-int.at new-result prim seq-int.push
      i 1 prim + result new-result j insert-copy-until val
    ]
    [ new-result val ]
    if
  };

: insert-copy-rest
  (forall ρ; ρ new-result:Seq Int^many j:Int^many result:Seq Int^many val:Int^many -- ρ final:Seq Int^many)
  locals { new-result j result val } {
    j result prim seq-int.len prim <
    [
      new-result val prim seq-int.push
      new-result j result insert-copy-rest val
    ]
    [ new-result val prim seq-int.push ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `insert-into-sorted` in `insertion-sort` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t20.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: The top value is ?t20 but `insert-into-sorted` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    start 0 0 txs process-ledger
  };

: process-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      dup balance prim + 0 prim <
      [ drop rejected 1 prim + ]
      [ balance prim + rejected ]
      if
      i 1 prim + txs process-ledger
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.untracked-local', 'severity': 'error', 'message_key': 'diagnostic.u

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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole process-batch
  };

: process-batch
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      stock allocated reasons allocate-item
      i 1 prim + items qtys whole process-batch
    ]
    [ stock allocated reasons ]
    if
  };

: allocate-item
  (forall ρ; ρ item:Int^many qty:Int^many fill-whole:Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ new-stock:Seq Int^many new-allocated:Seq Int^many new-reasons:Seq Int^many)
  locals { item qty fill-whole stock allocated reasons } {
    stock item prim seq-int.at
    dup qty prim <
    [
      0 prim =
      [ 0 allocated prim seq-int.push reasons 2 prim seq-int.push ]
      [
        fill-whole
        [ 0 allocated prim seq-int.push reasons 3 prim seq-int.push ]
        [ dup allocated prim seq-int.push reasons 1 prim seq-int.push ]
        if
      ]
      if
    ]
    [ qty allocated prim seq-int.push reasons 0 prim seq-int.push ]
    if
    stock item prim seq-int.at qty prim - item update-stock
  };

: update-stock
  (forall ρ; ρ new-val:Int^many item:Int^many stock:Seq Int^many -- ρ updated:Seq Int^many)
  locals { new-val item stock } {
    item 0 prim =
    [ prim seq-int.empty new-val prim seq-int.push 1 stock copy-rest-stock ]
    [ stock 0 prim seq-int.at prim seq-int.empty prim seq-int.push item 1 prim - new-val stock update-stock ]
    if
  };

: copy-rest-stock
  (forall ρ; ρ i:Int^many stock:Seq Int^many new-stock:Seq Int^many -- ρ final:Seq Int^many)
  locals { i stock new-stock } {
    i stock prim seq-int.len prim <
    [
      new-stock stock i prim seq-int.at prim seq-int.push
      i 1 prim + stock new-stock copy-rest-stock
    ]
    [ new-stock ]
    if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.untracked-local', 'severity': 'error', 'message_key': 'diagnostic.u
