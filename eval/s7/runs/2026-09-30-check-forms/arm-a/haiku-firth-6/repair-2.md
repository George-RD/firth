Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs i sum } {
    i xs prim seq-int.len prim >=
    [ sum ]
    [ xs i prim seq-int.at sum prim + i 1 prim + xs sum-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 sum-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-helper
at: line 6, column 53
message: `sum-helper` in `sum-helper` takes xs:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxval:Int^many -- ρ result:Int^many)
  locals { xs i maxval } {
    i xs prim seq-int.len prim >=
    [ maxval ]
    [ xs i prim seq-int.at maxval prim > [ xs i prim seq-int.at i 1 prim + xs max-helper ] [ maxval i 1 prim + xs max-helper ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-helper };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: max-helper
at: line 6, column 79
message: `max-helper` in `max-helper` takes xs:Seq Int, i:Int, maxval:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `i 1 prim +` are for `i` and `maxval`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim >=
    [ count ]
    [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if xs k i 1 prim + count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 count-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-loop
at: line 6, column 85
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: These are the values `count-loop` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` and `i 1 prim +` are for `i` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 5
message: `count-loop` in `main` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int. `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: ρ Seq Int Int Int
hint: `count-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many found:Bool^many -- ρ result:Int^many)
  locals { xs x i found } {
    found
    [ i ]
    [
      i xs prim seq-int.len prim >=
      [ -1 ]
      [ xs i prim seq-int.at x prim = 
        [ i ]
        [ xs x i 1 prim + find-loop ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { xs x 0 false find-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 12, column 9
message: In the false branch of the `if` in `find-loop` whose true branch is `[ i ]`, `find-loop` needs 4 values (xs:Seq Int, x:Int, i:Int, found:Bool), but the branch has pushed only 3 values before it (`xs`, `x` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int, found:Bool. The branch already pushes `xs`, `x` and the result of `prim +`, in the place of the first 3 (xs:Seq Int, x:Int, i:Int). Push the last one (found:Bool) after them by writing the local of that name, `found`: write `xs x i 1 prim + found find-loop` in place of `xs x i 1 prim + find-loop` on line 11. With that edit `find-loop` checks. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs result i } {
    i 0 prim <
    [ result ]
    [ xs i prim seq-int.at result prim seq-int.push xs i 1 prim - reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 6, column 35
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 6. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many sum:Int^many -- ρ sums:Seq Int^many)
  locals { xs result i sum } {
    i xs prim seq-int.len prim >=
    [ result ]
    [ xs i prim seq-int.at sum prim + result prim seq-int.push xs i 1 prim + prefix-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 prefix-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 7, column 5
message: In the false branch of the `if` in `prefix-loop` whose true branch is `[ result ]`, `prefix-loop` needs 4 values (xs:Seq Int, result:Seq Int, i:Int, sum:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, i:Int, sum:Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `result`), `xs` and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `sum` for the input it does not push: write `xs xs i prim seq-int.at sum prim + result prim seq-int.push i 1 prim + sum prefix-loop` in place of `xs i prim seq-int.at sum prim + result prim seq-int.push xs i 1 prim + prefix-loop` on line 6. With that edit, the next error in `prefix-loop` is at line 6, column 49. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim >=
    [ result ]
    [ xs i prim seq-int.at dup 0 prim > [ result prim seq-int.push ] [ drop ] if xs result i 1 prim + filter-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 filter-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 6, column 79
message: The two branches of the `if` in `filter-loop` whose true branch is `[ result prim seq-int.push ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim >=
    [ sum ]
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + xs ys i 1 prim + dot-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-loop;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-loop
at: line 6, column 84
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many currun:Int^many maxrun:Int^many lastval:Int^many -- ρ length:Int^many)
  locals { xs i currun maxrun lastval } {
    i xs prim seq-int.len prim >=
    [ currun maxrun prim > [ currun ] [ maxrun ] if ]
    [ xs i prim seq-int.at dup lastval prim = 
      [ drop xs i 1 prim + currun 1 prim + maxrun lastval run-loop ]
      [ swap drop xs i 1 prim + 1 maxrun lastval run-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim <= [ 0 ] [ xs 0 0 0 xs 0 prim seq-int.at run-loop ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 11, column 5
message: The false branch of `if` in `run-loop` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ, but the false branch takes .. Int.
expected: .. Int
actual: ρ
hint: The false branch takes more values than are there. Push them before the condition, or take them as parameters in the signature. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many seen:Seq Int^many -- ρ count:Int^many)
  locals { xs i count seen } {
    i xs prim seq-int.len prim >=
    [ count ]
    [ xs i prim seq-int.at dup 0 seen [ xs swap prim seq-int.at prim = ] dip [ [ xs i prim seq-int.at seen prim seq-int.push ] dip count 1 prim + ] [ ] if xs i 1 prim + count-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 0 count-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 6, column 153
message: The two branches of the `if` in `count-loop` whose true branch is `[ [ xs i prim seq-int.at seen prim ...` leave different numbers of values. The true branch takes the result of `prim =` from below the `if` and leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `prim =` and the result of `prim +`; the false branch leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.push` and the result of `prim =` are left below the result of `prim +`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 26
message: `count-loop` in `main` takes xs:Seq Int, i:Int, count:Int, seen:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `count-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    i xs prim seq-int.len prim >= [ j ys prim seq-int.len prim >= ]
    [ result ]
    [ xs i prim seq-int.at ys j prim seq-int.at prim <= 
      [ xs i prim seq-int.at result prim seq-int.push xs ys i 1 prim + j merge-loop ]
      [ ys j prim seq-int.at result prim seq-int.push xs ys i j 1 prim + merge-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 merge-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 7, column 37
message: `prim seq-int.push` in `merge-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t136 ?t135 Int ?t137
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 7. With that edit, the next error in `merge-loop` is at line 7, column 74.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 26
message: `merge-loop` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `merge-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    [ result ]
    [ result n 10 prim mod prim seq-int.push n 10 prim div digit-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n digit-loop ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digit-loop
at: line 6, column 60
message: `digit-loop` in `digit-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div` on line 6. With that edit `digit-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 62
message: `digit-loop` in `main` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int) and `n` (Int). `main` calls `digit-loop`, which has an error of its own; this report assumes `digit-loop` keeps its stack effect.
expected: .. Int Seq Int
actual: .. Seq Int ?t6
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `n prim seq-int.empty` in place of `prim seq-int.empty n` on line 12. With that edit `main` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-helper
  (forall ρ; ρ n:Int^many i:Int^many -- ρ isprime:Bool^many)
  locals { n i } {
    i i prim * n prim >
    [ true ]
    [ n i prim mod 0 prim = [ false ] [ n i 1 prim + is-prime-helper ] if ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ isprime:Bool^many)
  locals { n } { n 2 prim < [ false ] [ n 2 is-prime-helper ] if };

: prime-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim >
    [ result ]
    [ i is-prime [ i result prim seq-int.push ] [ result ] if n i 1 prim + prime-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 prime-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: prime-loop
at: line 19, column 29
message: `prim seq-int.push` in `prime-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result i` in place of `i result` on line 19. With that edit, the next error in `prime-loop` is at line 19, column 76.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 25, column 24
message: `prime-loop` in `main` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `n` (Int), the result of `prim seq-int.empty` (Seq Int) and `2` (Int). `main` calls `prime-loop`, which has an error of its own; this report assumes `prime-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int Int
hint: The top value, `2` (Int), is not what `prime-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: hist-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim >=
    [ counts ]
    [ xs i prim seq-int.at counts [ prim seq-int.at 1 prim + ] dip prim seq-int.set xs k i 1 prim + hist-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 [ prim seq-int.push ] dip k xs k 0 hist-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: hist-loop
at: line 7, column 5
message: In the false branch of the `if` in `hist-loop` whose true branch is `[ counts ]`, `prim seq-int.at` (inside a quotation in that branch) needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.at`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes the result of `prim seq-int.at`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it, for example by writing the locals that hold it. If `prim seq-int.at` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 12, column 44
message: `prim seq-int.push` in `main` takes 2 values (the sequence (Seq Int) and the value pushed (Int)), bottom to top, but only 1 value is on the stack before it: the result of `prim seq-int.empty` (Seq Int).
hint: Push the missing value before `prim seq-int.push`. The locals here, `xs` and `k`, are not values on the stack: writing a local's name pushes its value.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: is-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ true ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [ xs i 1 prim + is-sorted ] [ false ] if ]
    if
  };

: bubble-once
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ xs:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ xs ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim > 
      [ xs i 1 prim + prim seq-int.at xs i prim seq-int.set xs i prim seq-int.at xs i 1 prim + prim seq-int.set i 1 prim + bubble-once ]
      [ xs i 1 prim + bubble-once ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 is-sorted [ xs ] [ xs 0 bubble-once sort-loop ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  sort-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: bubble-once
at: line 18, column 7
message: The two branches of the `if` in `bubble-once` whose true branch is `[ xs i 1 prim + prim seq-int.at ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `bubble-once`; the false branch leaves the result of `bubble-once`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `bubble-once`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ final:Int^many count:Int^many)
  locals { start txs i balance rejected } {
    i txs prim seq-int.len prim >=
    [ balance rejected ]
    [ txs i prim seq-int.at balance prim + dup 0 prim < 
      [ drop txs i 1 prim + balance rejected 1 prim + ledger-loop ]
      [ txs i 1 prim + balance swap rejected ledger-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 9, column 7
message: In the true branch `[ drop txs i 1 prim + balance ...` of the `if` in `ledger-loop`, `ledger-loop` needs 5 values (start:Int, txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 4 values before it (`txs`, the result of `prim +`, `balance` and the result of `prim +`). Earlier in the branch, the result of `prim +` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: start:Int, txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes `txs`, the result of `prim +`, `balance` and the result of `prim +`, in the place of the last 4 (txs:Seq Int, i:Int, balance:Int, rejected:Int). Push the first one (start:Int) before them by writing the local of that name, `start`: write `start txs i 1 prim + balance rejected 1 prim + ledger-loop` in place of `txs i 1 prim + balance rejected 1 prim + ledger-loop` on line 7. With that edit `ledger-loop` checks. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 7
message: `ledger-loop` in `main` needs Int Seq Int Int Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int Int. `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Seq Int Int Int Int
actual: ρ Int Seq Int Int Int
hint: `ledger-loop` takes 5 values but only 4 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i qtys prim seq-int.len prim >=
    [ stock allocated reasons ]
    [ items i prim seq-int.at stock [ prim seq-int.at ] dip [ qtys i prim seq-int.at stock [ prim seq-int.at ] dip prim <= ]
      [ qtys i prim seq-int.at allocated prim seq-int.push 0 reasons prim seq-int.push stock items i prim seq-int.at qtys i prim seq-int.at prim seq-int.set i 1 prim + allocated reasons allocate-loop ]
      [ stock [ prim seq-int.at ] dip 0 prim = 
        [ 0 allocated prim seq-int.push 2 reasons prim seq-int.push stock items qtys whole i 1 prim + allocated reasons allocate-loop ]
        [ whole i prim seq-bool.at 
          [ 0 allocated prim seq-int.push 3 reasons prim seq-int.push stock items qtys whole i 1 prim + allocated reasons allocate-loop ]
          [ stock [ prim seq-int.at ] dip allocated prim seq-int.push 1 reasons prim seq-int.push stock items i prim seq-int.at prim seq-int.set i 1 prim + allocated reasons allocate-loop ]
          if
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 allocate-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 13, column 11
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch pushes 5 values, and the false branch takes 3 values from the stack below the `if` and leaves 3 values. The false branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 24, column 43
message: `allocate-loop` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `allocate-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
