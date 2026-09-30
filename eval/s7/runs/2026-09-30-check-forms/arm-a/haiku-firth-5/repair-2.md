Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs index max-val } {
    index xs prim seq-int.len prim >=
    [ max-val ]
    [ xs index 1 prim +
      [ xs index prim seq-int.at max-val prim > ]
      [ xs index prim seq-int.at ]
      [ max-val ]
      if
      max-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs xs prim seq-int.at 1 max-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: max-loop
at: line 10, column 7
message: `if` in `max-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 18, column 11
message: `prim seq-int.at` in `main` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `xs` (Seq Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: ρ Seq Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k index count } {
    index xs prim seq-int.len prim >=
    [ count ]
    [ xs k
      index 1 prim +
      [ xs index prim seq-int.at k prim < ]
      [ count 1 prim + ]
      [ count ]
      if
      count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: count-loop
at: line 11, column 7
message: `if` in `count-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int Int [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: search-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs x index } {
    index xs prim seq-int.len prim >=
    [ -1 ]
    [ [ xs index prim seq-int.at x prim = ]
      [ index ]
      [ xs x index 1 prim + search-loop ]
      if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } {
    xs x 0 search-loop
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: search-loop
at: line 9, column 7
message: `if` in `search-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs index result } {
    index 0 prim <
    [ result ]
    [ xs
      index 1 prim -
      result xs index prim seq-int.at prim seq-int.push
      reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 3]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 2}}, {'kind': 'literal', 'literal': {'type': 's

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs index sum result } {
    index xs prim seq-int.len prim >=
    [ result ]
    [ xs
      index 1 prim +
      sum xs index prim seq-int.at prim +
      result sum prim seq-int.push
      prefix-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-loop
  };

```
On the example, it returned [[0, 1, 3]] instead of [[1, 3, 6]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs index result } {
    index xs prim seq-int.len prim >=
    [ result ]
    [ xs
      index 1 prim +
      [ xs index prim seq-int.at 0 prim > ]
      [ result xs index prim seq-int.at prim seq-int.push ]
      [ result ]
      if
      filter-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-loop
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: filter-loop
at: line 11, column 7
message: `if` in `filter-loop` needs a Bool condition under its two quotations, but the stack before it is .. Seq Int Int [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many -- ρ sorted:Bool^many)
  locals { xs index } {
    index xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [ [ xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim > ]
      [ false ]
      [ xs index 1 prim + check-loop ]
      if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 check-loop
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: check-loop
at: line 9, column 7
message: `if` in `check-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all-loop
  (forall ρ; ρ flags:Seq Bool^many index:Int^many -- ρ all:Bool^many)
  locals { flags index } {
    index flags prim seq-bool.len prim >=
    [ true ]
    [ [ flags index prim seq-bool.at prim not ]
      [ false ]
      [ flags index 1 prim + check-all-loop ]
      if ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags 0 check-all-loop
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: check-all-loop
at: line 9, column 7
message: `if` in `check-all-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
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
: run-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many current-run:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs index current-run max-run } {
    index xs prim seq-int.len prim >=
    [ [ current-run max-run prim > ] [ current-run ] [ max-run ] if ]
    [ [ index 1 prim > [ xs index prim seq-int.at xs index 1 prim - prim seq-int.at prim = ] [ false ] if ]
      [ xs index 1 prim + current-run 1 prim + max-run run-loop ]
      [ xs index 1 prim + 1 [ current-run max-run prim > ] [ current-run ] [ max-run ] if run-loop ]
      if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs 1 1 0 run-loop
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: run-loop
at: line 5, column 66
message: `if` in `run-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim >=
    [ xs i 1 prim + target inner-loop2 ]
    [ [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = ]
      [ true ]
      [ xs target i j 1 prim + inner-loop ]
      if ]
    if
  };

: inner-loop2
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim >=
    [ false ]
    [ xs target i i 1 prim + inner-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 inner-loop2
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: inner-loop
at: line 9, column 7
message: `if` in `inner-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
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
: count-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs index count } {
    index xs prim seq-int.len prim >=
    [ count ]
    [ xs
      index 1 prim +
      count
      count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 0 count-loop
  };

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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    [ i xs prim seq-int.len prim >= ] [ j ys prim seq-int.len prim >= ] if
    [ j ys prim seq-int.len prim >= ]
    [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop ]
    [ [ i xs prim seq-int.len prim >= ]
      [ result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop ]
      [ [ xs i prim seq-int.at ys j prim seq-int.at prim <= ]
        [ result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop ]
        [ result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop ]
        if ]
      if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: merge-loop
at: line 4, column 73
message: The quotation run by `dip` in `merge-loop` does not accept the stack below it (ρ Seq Int Seq Int Int Int [ .. -- .. Bool ] [ .. -- .. Bool ] Seq Int [ .. Bool ?t52 ?t49 ?t46 ?t43 [ .. -- .. ] [ .. -- .. ] -- .. ?t52 ?t49 ?t46 ?t43 ]).
expected: .. Bool
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many digits:Seq Int^many -- ρ result:Seq Int^many)
  locals { n digits } {
    n 0 prim =
    [ digits ]
    [ digits n 10 prim mod prim seq-int.push n 10 prim div digit-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n prim seq-int.empty digit-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: digit-loop
at: line 6, column 60
message: `digit-loop` in `digit-loop` takes n:Int, digits:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `n 10 prim div digits n 10 prim mod prim seq-int.push` in place of `digits n 10 prim mod prim seq-int.push n 10 prim div` on line 6. With that edit `digit-loop` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim <
    [ false ]
    [ num 2 prim =
      [ true ]
      [ num 2 check-prime-loop ]
      if ]
    if
  };

: check-prime-loop
  (forall ρ; ρ num:Int^many div:Int^many -- ρ result:Bool^many)
  locals { num div } {
    div div prim * num prim >
    [ true ]
    [ [ num div prim mod 0 prim = ]
      [ false ]
      [ num div 1 prim + check-prime-loop ]
      if ]
    if
  };

: collect-loop
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n current result } {
    current n prim > 
    [ result ]
    [ [ current is-prime ]
      [ result current prim seq-int.push n current 1 prim + collect-loop ]
      [ n current 1 prim + result collect-loop ]
      if ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty collect-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: check-prime-loop
at: line 21, column 7
message: `if` in `check-prime-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.word-input-mismatch
word: collect-loop
at: line 31, column 61
message: `collect-loop` in `collect-loop` takes n:Int, current:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `n` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t54 Int
hint: These are the values `collect-loop` takes, in another order. To push them in its order, write `n current 1 prim + result current prim seq-int.push` in place of `result current prim seq-int.push n current 1 prim +` on line 31. With that edit, the next error in `collect-loop` is at line 33, column 7.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k index counts } {
    index xs prim seq-int.len prim >=
    [ counts ]
    [ xs k
      index 1 prim +
      counts xs index prim seq-int.at prim dup prim seq-int.at 1 prim + prim seq-int.set
      count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0 prim seq-int.empty prim dup prim dup [ k 1 prim - ] [ 0 prim seq-int.push ] if xs k 0 count-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 8, column 44
message: Unexpected `dup`, expected `primitive name`.
expected: primitive name
actual: dup
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ val:Int^many sorted:Seq Int^many index:Int^many -- ρ result:Seq Int^many)
  locals { val sorted index } {
    index sorted prim seq-int.len prim >=
    [ sorted val prim seq-int.push ]
    [ [ sorted index prim seq-int.at val prim > ]
      [ sorted index val prim seq-int.set val index 1 prim + insert-loop ]
      [ sorted val prim seq-int.push ]
      if ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs index sorted } {
    index xs prim seq-int.len prim >=
    [ sorted ]
    [ xs index prim seq-int.at sorted 0 insert-loop xs index 1 prim + sort-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: insert-loop
at: line 7, column 62
message: `insert-loop` in `insert-loop` takes val:Int, sorted:Seq Int, index:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), `val` (Int) and the result of `prim +` (Int).
expected: .. Int Seq Int Int
actual: .. Seq Int Int Int
hint: These are the values `insert-loop` takes, in another order. To push them in its order, write `val sorted index val prim seq-int.set index 1 prim +` in place of `sorted index val prim seq-int.set val index 1 prim +` on line 7. With that edit, the next error in `insert-loop` is at line 9, column 7.

error 2 of 2
code: firth.type.word-input-mismatch
word: sort-loop
at: line 18, column 71
message: `sort-loop` in `sort-loop` takes xs:Seq Int, index:Int, sorted:Seq Int, bottom to top, but here it gets, bottom to top, the result of `insert-loop` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int). `sort-loop` calls `insert-loop`, which has an error of its own; this report assumes `insert-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `sort-loop` takes, in another order. To push them in its order, write `xs index 1 prim + xs index prim seq-int.at sorted 0 insert-loop` in place of `xs index prim seq-int.at sorted 0 insert-loop xs index 1 prim +` on line 18. With that edit `sort-loop` checks.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: apply-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many index:Int^many balance:Int^many rejected:Int^many -- ρ final-balance:Int^many rejected-count:Int^many)
  locals { start txs index balance rejected } {
    index txs prim seq-int.len prim >=
    [ balance rejected ]
    [ [ balance txs index prim seq-int.at prim + 0 prim < ]
      [ start txs index 1 prim + balance rejected 1 prim + apply-loop ]
      [ start txs index 1 prim + balance txs index prim seq-int.at prim + rejected apply-loop ]
      if ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start txs 0 start 0 apply-loop
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: apply-loop
at: line 9, column 7
message: `if` in `apply-loop` needs a Bool condition under its two quotations, but the stack before it is .. [ .. -- .. Bool ] [ .. -- .. Int Int ] [ .. -- .. Int Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated-seq:Seq Int^many reasons-seq:Seq Int^many -- ρ out-stock:Seq Int^many out-allocated:Seq Int^many out-reasons:Seq Int^many)
  locals { stock items qtys whole order-idx allocated-seq reasons-seq } {
    order-idx qtys prim seq-int.len prim >=
    [ stock allocated-seq reasons-seq ]
    [ stock items order-idx prim seq-int.at prim seq-int.at qtys order-idx prim seq-int.at prim >= 
      [ stock items order-idx prim seq-int.at qtys order-idx prim seq-int.at prim seq-int.set qtys order-idx prim seq-int.at prim seq-int.push reasons-seq 0 prim seq-int.push stock items qtys whole order-idx 1 prim + allocated-seq process-order ]
      [ stock items order-idx prim seq-int.at prim seq-int.at 0 prim =
        [ allocated-seq 0 prim seq-int.push reasons-seq 2 prim seq-int.push stock items qtys whole order-idx 1 prim + process-order ]
        [ whole order-idx prim seq-bool.at
          [ allocated-seq 0 prim seq-int.push reasons-seq 3 prim seq-int.push stock items qtys whole order-idx 1 prim + process-order ]
          [ stock items order-idx prim seq-int.at stock items order-idx prim seq-int.at prim seq-int.at prim seq-int.set allocated-seq stock items order-idx prim seq-int.at prim seq-int.at prim seq-int.push reasons-seq 1 prim seq-int.push stock items qtys whole order-idx 1 prim + process-order ]
          if ]
        if ]
      if ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty process-order
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: process-order
at: line 13, column 11
message: The two branches of the `if` in `process-order` whose true branch is `[ allocated-seq 0 prim seq-int.push reasons-seq 3 prim ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the output `out-stock` of `process-order`, the output `out-allocated` of `process-order` and the output `out-reasons` of `process-order`; the false branch leaves 4 values, bottom to top: the result of `prim seq-int.set`, the output `out-stock` of `process-order`, the output `out-allocated` of `process-order` and the output `out-reasons` of `process-order`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the output `out-stock` of `process-order`, the output `out-allocated` of `process-order` and the output `out-reasons` of `process-order`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
