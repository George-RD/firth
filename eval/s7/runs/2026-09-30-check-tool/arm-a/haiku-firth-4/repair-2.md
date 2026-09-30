Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max-val prim <
      [ xs i 1 prim + xs i prim seq-int.at max-loop ]
      [ xs i 1 prim + max-val max-loop ]
      if
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 xs 0 prim seq-int.at max-loop
  };

```
On the example, it returned [2] instead of [9]

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i k count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [ xs i 1 prim + k count 1 prim + count-loop ]
      [ xs i 1 prim + k count count-loop ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 count-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 17, column 5
message: `count-loop` in `main` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int.
expected: .. Seq Int Int Int Int
actual: ρ Seq Int Int Int
hint: `count-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      xs i 1 prim - xs i prim seq-int.at result prim seq-int.push reverse-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 6, column 49
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 6. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      result prim seq-int.push
      xs i 1 prim + 
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 12, column 5
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `result`), `xs` and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `sum` for the input it does not push: write `xs i 1 prim + sum xs i prim seq-int.at sum prim + result prim seq-int.push prefix-loop` in place of `xs i prim seq-int.at sum prim + result prim seq-int.push xs i 1 prim + prefix-loop` on line 6. With that edit, the next error in `prefix-loop` is at line 6, column 64. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [ xs i 1 prim + result filter-loop ]
      [ xs i 1 prim + xs i prim seq-int.at result prim seq-int.push filter-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty filter-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: filter-loop
at: line 8, column 51
message: `prim seq-int.push` in `filter-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t80
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 8. With that edit `filter-loop` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + check-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  0 check-loop;

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
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-len max-len } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at current-val prim =
      [
        xs i 1 prim + current-val current-len 1 prim + max-len run-loop
      ]
      [
        current-len max-len prim <
        [ xs i 1 prim + xs i prim seq-int.at 1 current-len run-loop ]
        [ xs i 1 prim + xs i prim seq-int.at 1 max-len run-loop ]
        if
      ]
      if
    ]
    [
      current-len max-len prim <
      [ max-len ]
      [ current-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 xs 0 prim seq-int.at 1 0 run-loop ]
    if
  };

```
On the example, it returned [1] instead of [3]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: search-count
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target i found } {
    i 0 prim <
    [
      i 1 prim - xs prim seq-int.at target prim =
      [ true ]
      [ xs target i 1 prim - search-count ]
      if
    ]
    [ false ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i search-count
      [ xs i 1 prim + count 1 prim + count-loop ]
      [ xs i 1 prim + count count-loop ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 count-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: search-count
at: line 9, column 7
message: In the false branch of the `if` in `search-count` whose true branch is `[ true ]`, `search-count` needs 4 values (xs:Seq Int, target:Int, i:Int, found:Bool), but the branch has pushed only 3 values before it (`xs`, `target` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `search-count`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, found:Bool. The branch already pushes `xs`, `target` and the result of `prim -`, in the place of the first 3 (xs:Seq Int, target:Int, i:Int). Push the last one (found:Bool) after them by writing the local of that name, `found`: write `xs target i 1 prim - found search-count` in place of `xs target i 1 prim - search-count` on line 8. With that edit, the next error in `search-count` is at line 6, column 21. If `search-count` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 26, column 5
message: In the true branch `[ xs i prim seq-int.at xs i search-count ...` of the `if` in `count-loop`, `search-count` needs 4 values (xs:Seq Int, target:Int, i:Int, found:Bool), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, `xs` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-loop` calls `search-count`, which has an error of its own; this report assumes `search-count` keeps its stack effect.
hint: Make the branch push, just before `search-count`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, found:Bool. The branch already pushes the result of `prim seq-int.at`, `xs` and `i`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `search-count` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        xs ys i 1 prim + j xs i prim seq-int.at result prim seq-int.push merge-loop
      ]
      [
        xs ys i j 1 prim + ys j prim seq-int.at result prim seq-int.push merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs ys i 1 prim + j xs i prim seq-int.at result prim seq-int.push
        [ 
          i xs prim seq-int.len prim <
          [
            xs ys i 1 prim + j xs i prim seq-int.at result prim seq-int.push merge-loop
          ]
          [ result ]
          if
        ]
        call
      ]
      [
        j ys prim seq-int.len prim <
        [
          xs ys i j 1 prim + ys j prim seq-int.at result prim seq-int.push
          [
            j ys prim seq-int.len prim <
            [
              xs ys i j 1 prim + ys j prim seq-int.at result prim seq-int.push merge-loop
            ]
            [ result ]
            if
          ]
          call
        ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  0 0 prim seq-int.empty merge-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 45, column 9
message: The two branches of the `if` in `merge-loop` whose true branch is `[ xs ys i j 1 prim + ...` leave different numbers of values. The true branch leaves 6 values, bottom to top: `xs`, `ys`, `i`, the result of `prim +`, the result of `prim seq-int.push` and the result of an `if`; the false branch leaves `result`.
hint: The true branch leaves 5 values more than the false branch: `xs`, `ys`, `i`, the result of `prim +` and the result of `prim seq-int.push` are left below the result of an `if`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result prim seq-int.len 0 prim =
      [
        prim seq-int.empty 0 prim seq-int.push
      ]
      [ result ]
      if
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div digit-loop
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many rev:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result i rev } {
    i 0 prim <
    [
      result i 1 prim - result prim seq-int.at rev prim seq-int.push i 1 prim - reverse-digits
    ]
    [ rev ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      prim seq-int.empty digit-loop
      dup prim seq-int.len 1 prim -
      prim seq-int.empty
      reverse-digits
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: digit-loop
at: line 15, column 21
message: `digit-loop` in `digit-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div` on line 14. With that edit `digit-loop` checks.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 25, column 32
message: `prim seq-int.at` in `reverse-digits` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, the result of `prim -` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t20 ?t22 Int ?t22
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `result i 1 prim -` in place of `i 1 prim - result` on line 25. With that edit, the next error in `reverse-digits` is at line 25, column 52.

error 3 of 3
code: firth.type.branch-mismatch
word: main
at: line 44, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ prim seq-int.empty 0 prim seq-int.push ]`, `digit-loop` needs 2 values (n:Int, result:Seq Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.empty`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `digit-loop` and `reverse-digits`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `digit-loop`, exactly the values it takes, in this order: n:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.empty`, in the place of the last one (result:Seq Int). Push the first one (n:Int) before it by writing the local of that name, `n`: write `n prim seq-int.empty digit-loop` in place of `prim seq-int.empty digit-loop` on line 39. With that edit `main` checks. If `digit-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [ n d 1 prim + is-prime-check ]
      if
    ]
    [ true ]
    if
  };

: sieve-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <
    [
      i 2 prim <
      [ n i 1 prim + result sieve-loop ]
      [
        i 2 is-prime-check
        [
          n i 1 prim + i result prim seq-int.push sieve-loop
        ]
        [ n i 1 prim + result sieve-loop ]
        if
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  2 prim seq-int.empty sieve-loop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sieve-loop
at: line 25, column 33
message: `prim seq-int.push` in `sieve-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t99 Int Int ?t97
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result i` in place of `i result` on line 25. With that edit `sieve-loop` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      xs k i 1 prim + xs i prim seq-int.at counts prim seq-int.at 1 prim + counts xs i prim seq-int.at prim seq-int.set histogram-loop
    ]
    [ counts ]
    if
  };

: init-counts
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i counts } {
    i k prim <
    [
      k i 1 prim + counts 0 prim seq-int.push init-counts
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty init-counts histogram-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 6, column 51
message: `prim seq-int.at` in `histogram-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t34 Seq Int ?t36 Int Int ?t34
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `counts xs i prim seq-int.at` in place of `xs i prim seq-int.at counts` on line 6. With that edit, the next error in `histogram-loop` is at line 6, column 104.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 25, column 36
message: `histogram-loop` in `main` takes 4 values (xs:Seq Int, k:Int, i:Int, counts:Seq Int), bottom to top, but only 2 values are on the stack before it, bottom to top: the input `xs` (Seq Int) and the result of `init-counts` (Seq Int). `main` calls `histogram-loop`, which has an error of its own; this report assumes `histogram-loop` keeps its stack effect.
hint: Push the 2 missing values before `histogram-loop`, or take them as inputs in the signature.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many x:Int^many -- ρ result:Seq Int^many)
  locals { result i x } {
    i 0 prim <
    i 1 prim - result prim seq-int.at x prim < prim or
    [
      result i x prim seq-int.set
    ]
    [
      i result prim seq-int.len prim <
      i 1 prim - result prim seq-int.at x prim < prim and
      [
        result i result i 1 prim - prim seq-int.at prim seq-int.set
        result i 1 prim - x insert-loop
      ]
      [ result i x prim seq-int.set ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      result i xs i prim seq-int.at insert-loop
      xs i 1 prim + result sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-loop
at: line 17, column 7
message: The two branches of the `if` in `insert-loop` whose true branch is `[ result i result i 1 prim - ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-loop`; the false branch leaves the result of `prim seq-int.set`.
hint: The result of `prim seq-int.set` is a new value of `result`, but `insert-loop` is then handed `result` as it was before, so the new value is left below. If `insert-loop` should get the new value, bind it to the name `result` for the call: write `prim seq-int.set locals { result } { result i 1 prim - x insert-loop }` in place of `prim seq-int.set result i 1 prim - x insert-loop` on line 13. With that edit, the next error in `insert-loop` is at line 5, column 23. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-loop
at: line 32, column 5
message: The two branches of the `if` in `sort-loop` whose true branch is `[ result xs i prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `insert-loop` and the result of `sort-loop`; the false branch leaves `result`. `sort-loop` calls `insert-loop`, which has an error of its own; this report assumes `insert-loop` keeps its stack effect.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.push` and the result of `insert-loop` are left below the result of `sort-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [
        txs i 1 prim + balance rejected 1 prim + ledger-loop
      ]
      [
        txs i 1 prim + balance txs i prim seq-int.at prim + rejected ledger-loop
      ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 ledger-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 21, column 5
message: `ledger-loop` in `main` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int.
expected: .. Seq Int Int Int Int
actual: ρ Int Seq Int Int
hint: `ledger-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [
      stock items qtys whole i 1 prim +
      items i prim seq-int.at stock prim seq-int.at qtys i prim seq-int.at prim <
      [
        qtys i prim seq-int.at allocated prim seq-int.push
        stock items i prim seq-int.at qtys i prim seq-int.at prim seq-int.set
        reasons 0 prim seq-int.push
        allocate-loop
      ]
      [
        items i prim seq-int.at stock prim seq-int.at 0 prim =
        [
          0 allocated prim seq-int.push
          reasons 2 prim seq-int.push
          allocate-loop
        ]
        [
          whole i prim seq-bool.at
          [
            0 allocated prim seq-int.push
            reasons 3 prim seq-int.push
            allocate-loop
          ]
          [
            items i prim seq-int.at stock prim seq-int.at
            allocated prim seq-int.push
            stock items i prim seq-int.at 0 prim seq-int.set
            reasons 1 prim seq-int.push
            allocate-loop
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  0 prim seq-int.empty prim seq-int.empty allocate-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 35, column 11
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ 0 allocated prim seq-int.push reasons 3 prim ...` leave different numbers of values. The true branch takes the result of `prim +`, `whole`, `qtys`, `items` and `stock` from below the `if` and leaves 3 values, bottom to top: the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`; the false branch takes the result of `prim +`, `whole`, `qtys` and `items` from below the `if` and leaves 3 values, bottom to top: the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`.
hint: The true branch takes `stock` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.
