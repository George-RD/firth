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
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [
      acc xs i prim seq-int.at prim +
      i 1 prim +
      xs
      sum-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-loop
at: line 9, column 7
message: `sum-loop` in `sum-loop` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `acc xs i prim seq-int.at prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxval:Int^many -- ρ result:Int^many)
  locals { xs i maxval } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup maxval prim <
      [ maxval ]
      [ drop maxval ]
      if
      i 1 prim +
      xs
      max-loop
    ]
    [ maxval ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 10, column 7
message: The two branches of the `if` in `max-loop` whose true branch is `[ maxval ]` leave different numbers of values. The true branch leaves `maxval`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves `maxval`.
hint: The false branch takes the result of `prim seq-int.at` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k i cnt } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        cnt 1 prim +
      ]
      [ cnt ]
      if
      i 1 prim +
      xs k
      count-loop
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: count-loop
at: line 14, column 7
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, i:Int, cnt:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `k` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: These are the values `count-loop` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if` and `i 1 prim +` are for `i` and `cnt`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      result xs i prim seq-int.at
      prim seq-int.push
      i 1 prim -
      xs
      reverse-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop };

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
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      dup
      result swap prim seq-int.push
      i 1 prim +
      xs
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 11, column 7
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Int Seq Int Int Seq Int
hint: The third value from the top, the result of `prim seq-int.push` (Seq Int), is not what `prefix-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 prim <
      [
        drop
        xs i 1 prim + result filter-loop
      ]
      [
        result prim seq-int.push
        xs i 1 prim + 
        filter-loop
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty filter-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: filter-loop
at: line 13, column 16
message: `prim seq-int.push` in `filter-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <
      [ false ]
      [
        xs i 1 prim +
        check-loop
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 check-loop };

```
On the example, it returned [False] instead of [True]

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
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      xs ys i 1 prim +
      dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-loop
at: line 11, column 7
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many curlen:Int^many maxlen:Int^many -- ρ length:Int^many)
  locals { xs i curlen maxlen } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim =
      [
        curlen 1 prim +
        i 1 prim +
        xs
        run-loop
      ]
      [
        curlen maxlen prim <
        [ maxlen ]
        [ curlen ]
        if
        i 1 prim +
        xs 1
        run-loop
      ]
      if
    ]
    [
      curlen maxlen prim <
      [ maxlen ]
      [ curlen ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 0 0 run-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 24, column 7
message: In the true branch `[ curlen 1 prim + i 1 prim ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, i:Int, curlen:Int, maxlen:Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, curlen:Int, maxlen:Int. The branch already pushes, bottom to top, the result of `prim +` (from `curlen`), the result of `prim +` (from `i`) and `xs`, which by their names are for inputs in another order. Push each in its input's place, and write the local `maxlen` for the input it does not push: write `xs i 1 prim + curlen 1 prim + maxlen run-loop` in place of `curlen 1 prim + i 1 prim + xs run-loop` on line 10. With that edit, the next error in `run-loop` is at line 19, column 9. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at target prim =
      [ true ]
      [
        xs target j 1 prim +
        check-pair-inner
      ]
      if
    ]
    [ false ]
    if
  };

: check-pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at target prim -
      xs target i 1 prim +
      check-pair-inner
      [ true ]
      [
        xs target i 1 prim +
        check-pair-loop
      ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 check-pair-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-pair-loop
at: line 34, column 5
message: The two branches of the `if` in `check-pair-loop` whose true branch is `[ xs i prim seq-int.at target prim - ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim -` and the result of an `if`; the false branch leaves `false`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim -` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains
  (forall ρ; ρ seq:Seq Int^many val:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { seq val idx } {
    idx seq prim seq-int.len prim <
    [
      seq idx prim seq-int.at val prim =
      [ true ]
      [
        seq val idx 1 prim +
        contains
      ]
      if
    ]
    [ false ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many -- ρ count:Int^many)
  locals { xs i cnt } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs 0
      contains
      [
        i 1 prim +
        xs
        count-loop
      ]
      [
        cnt 1 prim +
        i 1 prim +
        xs
        count-loop
      ]
      if
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 count-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 37, column 7
message: In the true branch `[ i 1 prim + xs count-loop ]` of the `if` in `count-loop`, `count-loop` needs 3 values (xs:Seq Int, i:Int, cnt:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, cnt:Int. The branch already pushes, bottom to top, the result of `prim +` (from `i`) and `xs`, which by their names are for inputs in another order. Push each in its input's place, and write the local `cnt` for the input it does not push: write `xs i 1 prim + cnt count-loop` in place of `i 1 prim + xs count-loop` on line 27. With that edit, the next error in `count-loop` is at line 25, column 7. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim = [
      j ys prim seq-int.len prim < [
        result ys j prim seq-int.at prim seq-int.push
        xs ys i j 1 prim +
        merge-loop
      ]
      [ result ]
      if
    ]
    [
      j ys prim seq-int.len prim = [
        result xs i prim seq-int.at prim seq-int.push
        xs ys i 1 prim + j
        merge-loop
      ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push
          xs ys i 1 prim + j
          merge-loop
        ]
        [
          result ys j prim seq-int.at prim seq-int.push
          xs ys i j 1 prim +
          merge-loop
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-loop
at: line 8, column 9
message: `merge-loop` in `merge-loop` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), `i` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int ?t93 Seq Int ?t92 Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys i j 1 prim + result ys j prim seq-int.at prim seq-int.push` in place of `result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim +` on line 6. With that edit, the next error in `merge-loop` is at line 16, column 9.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      locals { n } {
        n result digits-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n prim seq-int.empty digits-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: digits-loop
at: line 14, column 5
message: The two branches of the `if` in `digits-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `digits-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `digits-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ num:Int^many divval:Int^many -- ρ result:Bool^many)
  locals { num divval } {
    divval divval prim * num prim < [
      num divval prim mod 0 prim = [ false ]
      [ num divval 1 prim + is-prime-check ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim < [ false ]
    [ num 2 is-prime-check ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim < [
      i is-prime [
        result i prim seq-int.push
      ]
      [ result ]
      if
      i 1 prim +
      n
      primes-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: primes-loop
at: line 32, column 7
message: `primes-loop` in `primes-loop` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), the result of `prim +` (Int) and `n` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t23
hint: These are the values `primes-loop` takes, in another order. To push them in its order, write `n i 1 prim + i is-prime [ result i prim seq-int.push ] [ result ] if` in place of `i is-prime [ result i prim seq-int.push ] [ result ] if i 1 prim + n` on line 25. With that edit `primes-loop` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-histogram
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ hist:Seq Int^many)
  locals { k i result } {
    i k prim < [
      result 0 prim seq-int.push
      k i 1 prim + result 0 prim seq-int.push init-histogram
    ]
    [ result ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many hist:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs i hist } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at
      dup hist swap prim seq-int.at
      1 prim +
      hist swap swap prim seq-int.set
      xs i 1 prim + hist count-loop
    ]
    [ hist ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 
    k 0 prim seq-int.empty init-histogram
    locals { hist } {
      xs 0 hist count-loop
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: init-histogram
at: line 9, column 5
message: The two branches of the `if` in `init-histogram` whose true branch is `[ result 0 prim seq-int.push k i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `init-histogram`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `init-histogram`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 23, column 5
message: The two branches of the `if` in `count-loop` whose true branch is `[ xs i prim seq-int.at dup hist swap ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `count-loop`; the false branch leaves `hist`.
hint: The result of `prim seq-int.set` is a new value of `hist`, but `count-loop` is then handed `hist` as it was before, so the new value is left below. If `count-loop` should get the new value, bind it to the name `hist` for the call: write `prim seq-int.set locals { hist } { xs i 1 prim + hist count-loop }` in place of `prim seq-int.set xs i 1 prim + hist count-loop` on line 19. With that edit, the next error in `count-loop` is at line 19, column 22. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int^many val:Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { sorted val idx } {
    idx sorted prim seq-int.len prim < [
      sorted idx prim seq-int.at val prim <
      [
        sorted idx val prim seq-int.set
        idx 1 prim +
        sorted insert-sorted
      ]
      [
        idx 1 prim +
        sorted val
        insert-sorted
      ]
      if
    ]
    [
      sorted val prim seq-int.push
    ]
    if
  };

: insert-loop
  (forall ρ; ρ xs:Seq Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs sorted i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at
      sorted 0
      insert-sorted
      locals { sorted } {
        xs sorted i 1 prim +
        insert-loop
      }
    ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 insert-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: insert-sorted
at: line 9, column 16
message: `insert-sorted` in `insert-sorted` takes sorted:Seq Int, val:Int, idx:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), the result of `prim +` (Int) and `sorted` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Seq Int
hint: The top value, `sorted` (Seq Int), is not what `insert-sorted` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: insert-loop
at: line 30, column 7
message: `insert-sorted` in `insert-loop` takes sorted:Seq Int, val:Int, idx:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `sorted` (Seq Int) and `0` (Int). `insert-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int ?t22 Int
hint: These are the values `insert-sorted` takes, in another order. By their names and types, `sorted` is for `sorted`. Of the values of one type, `xs i prim seq-int.at` and `0` are for `val` and `idx`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ finbal:Int^many rejcount:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at
      balance prim +
      dup 0 prim < [
        drop balance
        rejected 1 prim +
      ]
      [ 
        locals { balance } {
          balance txs i 1 prim + rejected ledger-loop
        }
      ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ finbal:Int^many rejcount:Int^many)
  locals { balance txs } { balance txs 0 0 ledger-loop };

```
On the example, it returned [15, 1] instead of [4, 1]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stockleft:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole idx allocated reasons } {
    idx qtys prim seq-int.len prim < [
      items idx prim seq-int.at
      stock prim seq-int.at
      qtys idx prim seq-int.at
      whole idx prim seq-bool.at
      \ allocation logic placeholder
      idx 1 prim +
      stock items qtys whole
      allocate-loop
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stockleft:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 15, column 5
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ items idx prim seq-int.at stock prim seq-int.at ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: the result of `prim seq-int.at`, the output `stockleft` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`; the false branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the output `stockleft` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
