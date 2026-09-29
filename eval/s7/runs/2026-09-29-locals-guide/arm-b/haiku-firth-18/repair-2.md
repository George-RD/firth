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
  locals { xs } { xs 0 0 sum-helper };

: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ total:Int^many)
  locals { xs i acc }
  {
    [
      xs i prim seq-int.at acc prim + locals { new-acc }
      { xs i 1 prim + new-acc sum-helper }
    ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: sum-helper
at: line 15, column 5
message: `if` in `sum-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-helper };

: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc }
  {
    [
      xs i prim seq-int.at locals { v }
      { v acc prim < [ acc ] [ v ] if locals { m } { xs i 1 prim + m max-helper } }
    ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: max-helper
at: line 15, column 5
message: `if` in `max-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs 0 0 k count-helper };

: count-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs i acc k }
  {
    [
      xs i prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if locals { new-acc }
      { xs i 1 prim + new-acc k count-helper }
    ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: count-helper
at: line 15, column 5
message: `if` in `count-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 -1 index-helper };

: index-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many result:Int^many -- ρ final:Int^many)
  locals { xs x i result }
  {
    [
      result 0 prim < prim not [ xs i prim seq-int.at x prim = [ i ] [ result ] if ] [ result ] if locals { new-result }
      { xs x i 1 prim + new-result index-helper }
    ]
    [ result ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: index-helper
at: line 15, column 5
message: `if` in `index-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-helper };

: reverse-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i }
  {
    [
      xs i prim seq-int.at result prim seq-int.push locals { new-result }
      { new-result xs i 1 prim - reverse-helper }
    ]
    [ result ]
    i 0 prim < prim not
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 10, column 35
message: `prim seq-int.push` in `reverse-helper` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t14.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t14
hint: The top value is ?t14 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 0 prefix-helper };

: prefix-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many acc:Int^many -- ρ final:Seq Int^many)
  locals { result xs i acc }
  {
    [
      xs i prim seq-int.at acc prim + locals { new-acc }
      { result new-acc prim seq-int.push locals { new-result }
        { new-result xs i 1 prim + new-acc prefix-helper }
      }
    ]
    [ result ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: prefix-helper
at: line 17, column 5
message: `if` in `prefix-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-pos-helper };

: keep-pos-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i }
  {
    [
      xs i prim seq-int.at locals { v }
      { v 0 prim < [ result ] [ result v prim seq-int.push ] if locals { new-result }
        { new-result xs i 1 prim + keep-pos-helper }
      }
    ]
    [ result ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: keep-pos-helper
at: line 17, column 5
message: `if` in `keep-pos-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 true sort-check };

: sort-check
  (forall ρ; ρ xs:Seq Int^many i:Int^many is-sorted:Bool^many -- ρ result:Bool^many)
  locals { xs i is-sorted }
  {
    [
      is-sorted prim not [ false ] [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not ] if locals { new-sorted }
      { xs i 1 prim + new-sorted sort-check }
    ]
    [ is-sorted ]
    i 1 prim + xs prim seq-int.len prim < is-sorted prim and
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: sort-check
at: line 15, column 5
message: `if` in `sort-check` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-helper };

: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys i acc }
  {
    [
      xs i prim seq-int.at ys i prim seq-int.at prim * acc prim + locals { prod }
      { xs ys i 1 prim + prod dot-helper }
    ]
    [ acc ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: dot-helper
at: line 15, column 5
message: `if` in `dot-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 true all-true-helper };

: all-true-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many acc:Bool^many -- ρ result:Bool^many)
  locals { flags i acc }
  {
    [
      flags i prim seq-bool.at acc prim and locals { new-acc }
      { flags i 1 prim + new-acc all-true-helper }
    ]
    [ acc ]
    i flags prim seq-bool.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: all-true-helper
at: line 15, column 5
message: `if` in `all-true-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    xs prim seq-int.len 0 prim <
    [ 0 ]
    [ xs 1 1 1 longest-run-helper ]
    if
  };

: longest-run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i current-run max-run }
  {
    [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = 
      [ current-run 1 prim + ] 
      [ current-run max-run prim < [ current-run ] [ max-run ] if ]
      if
      locals { new-current } {
        current-run 1 prim + max-run prim < [ new-current ] [ max-run ] if locals { new-max }
        { xs i 1 prim + new-current new-max longest-run-helper }
      }
    ]
    [ max-run ]
    i xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: longest-run-helper
at: line 26, column 5
message: `if` in `longest-run-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int ] [ .. -- .. Int ] Bool.
expected: Bool
actual: [ .. -- .. Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs 0 target false pair-check };

: pair-check
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs i target found }
  {
    [
      found [ true ] [ xs target i 0 inner-check ] if locals { result }
      { xs i 1 prim + target result pair-check }
    ]
    [ found ]
    i 1 prim + xs prim seq-int.len prim <
    if
  };

: inner-check
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j }
  {
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ xs target i j 1 prim + inner-check ]
      if
    ]
    [ false ]
    j xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: pair-check
at: line 15, column 5
message: `if` in `pair-check` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.expected-bool
word: inner-check
at: line 30, column 5
message: `if` in `inner-check` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 distinct-helper };

: distinct-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count }
  {
    [
      xs i prim seq-int.at xs 0 xs i seen-before 
      [ count ]
      [ count 1 prim + ]
      if
      locals { new-count }
      { xs i 1 prim + new-count distinct-helper }
    ]
    [ count ]
    i xs prim seq-int.len prim <
    if
  };

: seen-before
  (forall ρ; ρ xs:Seq Int^many val:Int^many start:Int^many limit:Int^many -- ρ result:Bool^many)
  locals { xs val start limit }
  {
    [
      xs start prim seq-int.at val prim = [ true ] [ xs val start 1 prim + limit seen-before ] if
    ]
    [ false ]
    start limit prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: distinct-helper
at: line 10, column 38
message: `seen-before` in `distinct-helper` needs Seq Int Int Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t15 Int Seq Int Int Seq Int Int. `distinct-helper` calls `seen-before`, which has an error of its own; this report assumes `seen-before` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: .. Seq Int Int ?t15 Int Seq Int Int Seq Int Int
hint: The second value from the top is Seq Int but `seen-before` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 2
code: firth.type.expected-bool
word: seen-before
at: line 31, column 5
message: `if` in `seen-before` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-helper };

: merge-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ final:Seq Int^many)
  locals { result xs ys i j }
  {
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.len prim < prim not [ ys j prim seq-int.at result prim seq-int.push locals { r } { r xs ys i j 1 prim + merge-helper } ]
        [
          xs i prim seq-int.at ys j prim seq-int.at prim < 
          [ xs i prim seq-int.at result prim seq-int.push locals { r } { r xs ys i 1 prim + j merge-helper } ]
          [ ys j prim seq-int.at result prim seq-int.push locals { r } { r xs ys i j 1 prim + merge-helper } ]
          if
        ]
        if
      ]
      [
        i xs prim seq-int.len prim <
        [ xs i prim seq-int.at result prim seq-int.push locals { r } { r xs ys i 1 prim + j merge-helper } ]
        [ result ]
        if
      ]
      if
    ]
    [ result ]
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim or prim not
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: merge-helper
at: line 12, column 77
message: `prim seq-int.push` in `merge-helper` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t127 ?t126 Int ?t128.
expected: .. Seq Int Int
actual: .. Seq Int Int ?t127 ?t126 Int ?t128
hint: The top value is ?t128 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    [ prim seq-int.empty n digits-helper ]
    if
  };

: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n }
  {
    [
      n 10 prim mod result prim seq-int.push locals { r }
      { r n 10 prim div digits-helper }
    ]
    [ result ]
    n 0 prim = prim not
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digits-helper
at: line 15, column 28
message: `prim seq-int.push` in `digits-helper` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t8.
expected: .. Seq Int Int
actual: .. Int Int ?t8
hint: The top value is ?t8 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n is-prime-build };

: is-prime-build
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ final:Seq Int^many)
  locals { result candidate limit }
  {
    [
      candidate limit prim < [ candidate 2 candidate is-prime-check [ result candidate prim seq-int.push ] [ result ] if locals { r } { r candidate 1 prim + limit is-prime-build } ] [ result ] if
    ]
    [ result ]
    candidate limit prim <
    if
  };

: is-prime-check
  (forall ρ; ρ candidate:Int^many divisor:Int^many limit:Int^many -- ρ result:Bool^many)
  locals { candidate divisor limit }
  {
    [
      candidate divisor prim mod 0 prim = [ false ] [ divisor 1 prim + candidate limit is-prime-check ] if
    ]
    [ true ]
    divisor divisor prim * candidate prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: is-prime-build
at: line 14, column 5
message: `if` in `is-prime-build` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.expected-bool
word: is-prime-check
at: line 26, column 5
message: `if` in `is-prime-check` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] Bool.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k histogram-init };

: histogram-init
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k }
  {
    [
      counts 0 prim seq-int.push locals { c } { c i 1 prim + k histogram-init }
    ]
    [ counts ]
    i k prim <
    if
  };

: histogram
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ final:Seq Int^many)
  locals { counts xs idx }
  {
    [
      xs idx prim seq-int.at locals { v }
      { counts v prim seq-int.at 1 prim + locals { new-val }
        { counts v new-val prim seq-int.set locals { new-counts }
          { new-counts xs idx 1 prim + histogram }
        }
      }
    ]
    [ counts ]
    idx xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: histogram-init
at: line 14, column 5
message: `if` in `histogram-init` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.expected-bool
word: histogram
at: line 31, column 5
message: `if` in `histogram` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 sort-pass };

: sort-pass
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i }
  {
    [
      i xs prim seq-int.len 1 prim - prim < 
      [ xs i i 1 prim + sort-compare ]
      [ xs ]
      if
    ]
    [ xs ]
    i xs prim seq-int.len prim <
    if
  };

: sort-compare
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs i j }
  {
    [
      xs i prim seq-int.at xs j prim seq-int.at prim <
      prim not
      [ xs i prim seq-int.at xs j prim seq-int.at xs j prim seq-int.at xs i prim seq-int.at prim seq-int.set prim seq-int.set ]
      [ xs ]
      if
      locals { new-xs }
      { new-xs i 1 prim + sort-pass }
    ]
    [ xs ]
    j xs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: sort-pass
at: line 17, column 5
message: `if` in `sort-pass` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-compare
at: line 29, column 7
message: The two branches of `if` in `sort-compare` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The condition and the values the branches take from below the `if` are looked for where the local `i` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-helper };

: ledger-helper
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i }
  {
    [
      txs i prim seq-int.at balance prim + 0 prim <
      [ balance rejected 1 prim + ]
      [ balance txs i prim seq-int.at prim + rejected ]
      if
      locals { new-balance new-rejected }
      { new-balance new-rejected txs i 1 prim + ledger-helper }
    ]
    [ balance rejected ]
    i txs prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: ledger-helper
at: line 19, column 5
message: `if` in `ledger-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Int Int ] [ .. -- .. Int Int ] Bool.
expected: Bool
actual: [ .. -- .. Int Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 allocate-loop };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons order items qtys whole }
  {
    [
      items order prim seq-int.at locals { item-id }
      { stock item-id prim seq-int.at locals { current-stock }
        { 
          qtys order prim seq-int.at current-stock prim <
          [
            current-stock 0 prim =
            [ stock allocated reasons 2 prim seq-int.push ]
            [ whole order prim seq-bool.at [ stock allocated reasons 3 prim seq-int.push ] [ stock item-id current-stock prim seq-int.set allocated current-stock prim seq-int.push reasons 1 prim seq-int.push ] if ]
            if
          ]
          [ stock item-id current-stock qtys order prim seq-int.at prim - prim seq-int.set allocated qtys order prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push ]
          if
          locals { new-stock new-allocated new-reasons }
          { new-stock new-allocated new-reasons order 1 prim + items qtys whole allocate-loop }
        }
      }
    ]
    [ stock allocated reasons ]
    order items prim seq-int.len prim <
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 85
message: `allocate-loop` needs more values than the stack holds here. `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `allocate-loop` and in what order.

error 2 of 2
code: firth.type.expected-bool
word: allocate-loop
at: line 29, column 5
message: `if` in `allocate-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Seq Int Seq Int Seq Int ] [ .. -- .. Seq Int Seq Int Seq Int ] Bool.
expected: Bool
actual: [ .. -- .. Seq Int Seq Int Seq Int ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.
