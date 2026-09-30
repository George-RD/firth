Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [ result ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim - xs reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs prim seq-int.len 1 prim - prim seq-int.empty xs reverse-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: reverse-loop
at: line 6, column 67
message: `reverse-loop` in `reverse-loop` takes i:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim -` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int
hint: These are the values `reverse-loop` takes, in another order. To push them in its order, write `i 1 prim - xs result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim - xs` on line 6. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-sums-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      acc xs i prim seq-int.at prim + 
      locals { new-acc } {
        result new-acc prim seq-int.push
        i 1 prim + new-acc xs prefix-sums-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty 0 xs prefix-sums-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: prefix-sums-loop
at: line 10, column 31
message: `prefix-sums-loop` in `prefix-sums-loop` takes i:Int, acc:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int), `new-acc` (Int) and `xs` (Seq Int).
expected: .. Int Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int Seq Int Int Int Seq Int
hint: These are the values `prefix-sums-loop` takes, in another order. By their names and types, `xs` is for `xs` and `result new-acc prim seq-int.push` is for `result`. Of the values of one type, `i 1 prim +` and `new-acc` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 18, column 45
message: `prefix-sums-loop` in `main` takes i:Int, acc:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `xs` (Seq Int). `main` calls `prefix-sums-loop`, which has an error of its own; this report assumes `prefix-sums-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int
actual: ρ Int Seq Int Int Seq Int
hint: These are the values `prefix-sums-loop` takes, in another order. To push them in its order, write `0 0 xs prim seq-int.empty` in place of `0 prim seq-int.empty 0 xs` on line 18. With that edit `main` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim >=
    [ result ]
    [
      xs i prim seq-int.at 0 prim >
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs keep-positive-loop ]
      [ result i 1 prim + xs keep-positive-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-positive-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: keep-positive-loop
at: line 8, column 69
message: `keep-positive-loop` in `keep-positive-loop` takes i:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int
hint: These are the values `keep-positive-loop` takes, in another order. To push them in its order, write `i 1 prim + xs result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim + xs` on line 8. With that edit, the next error in `keep-positive-loop` is at line 9, column 30.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 43
message: `keep-positive-loop` in `main` takes i:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `xs` (Seq Int). `main` calls `keep-positive-loop`, which has an error of its own; this report assumes `keep-positive-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: These are the values `keep-positive-loop` takes, in another order. To push them in its order, write `0 xs prim seq-int.empty` in place of `prim seq-int.empty 0 xs` on line 17. With that edit `main` checks.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-search
  (forall ρ; ρ i:Int^many val:Int^many seen:Seq Int^many -- ρ in-seen:Bool^many)
  locals { i val seen } {
    i seen prim seq-int.len prim >=
    [ false ]
    [
      seen i prim seq-int.at val prim =
      [ true ]
      [ i 1 prim + val seen count-distinct-search ]
      if
    ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many distinct:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs distinct } {
    i xs prim seq-int.len prim >=
    [ distinct ]
    [
      0 xs i prim seq-int.at distinct count-distinct-search
      [ distinct i 1 prim + xs count-distinct-loop ]
      [ distinct xs i prim seq-int.at prim seq-int.push i 1 prim + xs count-distinct-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { prim seq-int.empty 0 xs count-distinct-loop prim seq-int.len };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-distinct-loop
at: line 22, column 32
message: `count-distinct-loop` in `count-distinct-loop` takes i:Int, xs:Seq Int, distinct:Seq Int, bottom to top, but here it gets, bottom to top, `distinct` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. ?t62 Int ?t60
hint: These are the values `count-distinct-loop` takes, in another order. To push them in its order, write `i 1 prim + xs distinct` in place of `distinct i 1 prim + xs` on line 22. With that edit, the next error in `count-distinct-loop` is at line 23, column 71.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 31, column 43
message: `count-distinct-loop` in `main` takes i:Int, xs:Seq Int, distinct:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `xs` (Seq Int). `main` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: These are the values `count-distinct-loop` takes, in another order. To push them in its order, write `0 xs prim seq-int.empty` in place of `prim seq-int.empty 0 xs` on line 31. With that edit `main` checks.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-sorted-loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i j xs ys result } {
    i xs prim seq-int.len prim >=
    [
      j ys prim seq-int.len prim >=
      [ result ]
      [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys merge-sorted-loop ]
      if
    ]
    [
      j ys prim seq-int.len prim >=
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys merge-sorted-loop ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <=
        [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys merge-sorted-loop ]
        [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys merge-sorted-loop ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-sorted-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: merge-sorted-loop
at: line 8, column 74
message: `merge-sorted-loop` in `merge-sorted-loop` takes i:Int, j:Int, xs:Seq Int, ys:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `i` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Int Int Seq Int Seq Int Seq Int
actual: .. Seq Int ?t103 Int ?t102 Seq Int
hint: These are the values `merge-sorted-loop` takes, in another order. To push them in its order, write `i j 1 prim + xs ys result ys j prim seq-int.at prim seq-int.push` in place of `result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys` on line 8. With that edit, the next error in `merge-sorted-loop` is at line 13, column 74.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 27, column 51
message: `merge-sorted-loop` in `main` takes i:Int, j:Int, xs:Seq Int, ys:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `0` (Int), `0` (Int), `xs` (Seq Int) and `ys` (Seq Int). `main` calls `merge-sorted-loop`, which has an error of its own; this report assumes `merge-sorted-loop` keeps its stack effect.
expected: .. Int Int Seq Int Seq Int Seq Int
actual: ρ Seq Int Int Int Seq Int Seq Int
hint: These are the values `merge-sorted-loop` takes, in another order. To push them in its order, write `0 0 xs ys prim seq-int.empty` in place of `prim seq-int.empty 0 0 xs ys` on line 27. With that edit `main` checks.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      locals { digit } {
        result digit prim seq-int.push
        n 10 prim div result digits-loop
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many result:Seq Int^many rev:Seq Int^many -- ρ result:Seq Int^many)
  locals { i result rev } {
    i result prim seq-int.len prim >=
    [ rev ]
    [ rev result i prim seq-int.at prim seq-int.push i 1 prim + result reverse-digits ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digits-loop 0 swap prim seq-int.empty reverse-digits ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: digits-loop
at: line 13, column 5
message: The two branches of the `if` in `digits-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `digits-loop`.
hint: The result of `prim seq-int.push` is a new value of `result`, but `digits-loop` is then handed `result` as it was before, so the new value is left below. If `digits-loop` should get the new value, bind it to the name `result` for the call: write `prim seq-int.push locals { result } { n 10 prim div result digits-loop }` in place of `prim seq-int.push n 10 prim div result digits-loop` on line 9. With that edit `digits-loop` checks. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.word-input-mismatch
word: reverse-digits
at: line 21, column 72
message: `reverse-digits` in `reverse-digits` takes i:Int, result:Seq Int, rev:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int
hint: These are the values `reverse-digits` takes, in another order. To push them in its order, write `i 1 prim + result rev result i prim seq-int.at prim seq-int.push` in place of `rev result i prim seq-int.at prim seq-int.push i 1 prim + result` on line 21. With that edit `reverse-digits` checks.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 30, column 28
message: `digits-loop` in `main` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int) and `n` (Int). `main` calls `digits-loop`, which has an error of its own; this report assumes `digits-loop` keeps its stack effect.
expected: .. Int Seq Int
actual: .. Seq Int ?t6
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `n prim seq-int.empty` in place of `prim seq-int.empty n` on line 30. With that edit `main` checks. That edit was checked assuming `reverse-digits`, which has an error of its own, keeps its stack effect.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-loop
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim > 
    [ true ]
    [ n d prim mod 0 prim = [ false ] [ d 1 prim + n is-prime-loop ] if ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ 2 n is-prime-loop ]
    if
  };

: primes-loop
  (forall ρ; ρ i:Int^many limit:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i limit result } {
    i limit prim > 
    [ result ]
    [
      i is-prime
      [ result i prim seq-int.push i 1 prim + limit primes-loop ]
      [ i 1 prim + limit result primes-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: primes-loop
at: line 26, column 53
message: `primes-loop` in `primes-loop` takes i:Int, limit:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `limit` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t52
hint: These are the values `primes-loop` takes, in another order. To push them in its order, write `i 1 prim + limit result i prim seq-int.push` in place of `result i prim seq-int.push i 1 prim + limit` on line 26. With that edit `primes-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 35, column 41
message: `primes-loop` in `main` takes i:Int, limit:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `2` (Int) and `n` (Int). `main` calls `primes-loop`, which has an error of its own; this report assumes `primes-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Seq Int Int Int
hint: These are the values `primes-loop` takes, in another order. By their names and types, `prim seq-int.empty` is for `result`. Of the values of one type, `2` and `n` are for `i` and `limit`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-count-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim >=
    [ counts ]
    [
      xs i prim seq-int.at
      locals { item } {
        counts item prim seq-int.at 1 prim +
        locals { new-val } {
          counts item new-val prim seq-int.set
          i 1 prim + xs histogram-count-loop
        }
      }
    ]
    if
  };

: histogram-init-loop
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result } {
    i k prim >=
    [ result ]
    [ result 0 prim seq-int.push i 1 prim + k histogram-init-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { 
    prim seq-int.empty 0 k histogram-init-loop
    0 xs swap histogram-count-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: histogram-count-loop
at: line 12, column 25
message: `histogram-count-loop` in `histogram-count-loop` takes i:Int, xs:Seq Int, counts:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int Int Seq Int Int Seq Int
hint: These are the values `histogram-count-loop` takes, in another order. To push them in its order, write `i 1 prim + xs counts item new-val prim seq-int.set` in place of `counts item new-val prim seq-int.set i 1 prim + xs` on line 11. With that edit `histogram-count-loop` checks.

error 2 of 3
code: firth.type.word-input-mismatch
word: histogram-init-loop
at: line 24, column 47
message: `histogram-init-loop` in `histogram-init-loop` takes i:Int, k:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `k` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t30
hint: These are the values `histogram-init-loop` takes, in another order. To push them in its order, write `i 1 prim + k result 0 prim seq-int.push` in place of `result 0 prim seq-int.push i 1 prim + k` on line 24. With that edit `histogram-init-loop` checks.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 31, column 28
message: `histogram-init-loop` in `main` takes i:Int, k:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `k` (Int). `main` calls `histogram-init-loop`, which has an error of its own; this report assumes `histogram-init-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: .. Seq Int Int Int
hint: These are the values `histogram-init-loop` takes, in another order. To push them in its order, write `0 k prim seq-int.empty` in place of `prim seq-int.empty 0 k` on line 31. With that edit, the next error in `main` is at line 32, column 15. That edit was checked assuming `histogram-count-loop`, which has an error of its own, keeps its stack effect.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: simple-sort-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs } {
    i xs prim seq-int.len prim >=
    [ prim seq-int.empty ]
    [
      i 1 prim + xs simple-sort-loop
      locals { sorted-rest } {
        xs i prim seq-int.at
        locals { elem } {
          sorted-rest 0 elem sorted-rest prim seq-int.len simple-insert
        }
      }
    ]
    if
  };

: simple-insert
  (forall ρ; ρ sorted:Seq Int^many pos:Int^many elem:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { sorted pos elem len } {
    pos len prim >=
    [ sorted elem prim seq-int.push ]
    [
      sorted pos prim seq-int.at elem prim >
      [ sorted pos elem prim seq-int.set pos 1 prim + elem len simple-insert ]
      [ sorted elem prim seq-int.push ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 xs simple-sort-loop };

```
On the example, it returned [[1, 1, 3]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-batch-loop
  (forall ρ; ρ j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { j items qtys whole stock allocated reasons } {
    j items prim seq-int.len prim >=
    [ stock allocated reasons ]
    [
      items j prim seq-int.at
      locals { item } {
        qtys j prim seq-int.at
        locals { qty } {
          stock item prim seq-int.at
          locals { r } {
            qty r prim <=
            [
              stock item qty prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
              j 1 prim + items qtys whole stock allocated reasons allocate-batch-loop
            ]
            [
              r 0 prim =
              [
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                j 1 prim + items qtys whole stock allocated reasons allocate-batch-loop
              ]
              [
                whole j prim seq-bool.at
                [
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  j 1 prim + items qtys whole stock allocated reasons allocate-batch-loop
                ]
                [
                  stock item 0 prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                  j 1 prim + items qtys whole stock allocated reasons allocate-batch-loop
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
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { 0 stock items qtys whole prim seq-int.empty prim seq-int.empty allocate-batch-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-batch-loop
at: line 51, column 5
message: The two branches of the `if` in `allocate-batch-loop` whose true branch is `[ stock allocated reasons ]` leave different numbers of values. The true branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`; the false branch leaves 6 values, bottom to top: the result of an `if`, the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `stock` of `allocate-batch-loop`, the output `allocated` of `allocate-batch-loop` and the output `reasons` of `allocate-batch-loop`.
hint: The false branch leaves 3 values more than the true branch: the result of an `if`, the result of `prim seq-int.push` and the result of `prim seq-int.push` are left below the output `stock` of `allocate-batch-loop`, the output `allocated` of `allocate-batch-loop` and the output `reasons` of `allocate-batch-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 56, column 102
message: `allocate-batch-loop` in `main` takes j:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, stock:Seq Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), `stock` (Seq Int), `items` (Seq Int), `qtys` (Seq Int), `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `allocate-batch-loop`, which has an error of its own; this report assumes `allocate-batch-loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int
actual: ρ Int Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int
hint: These are the values `allocate-batch-loop` takes, in another order. To push them in its order, write `0 items qtys whole stock prim seq-int.empty prim seq-int.empty` in place of `0 stock items qtys whole prim seq-int.empty prim seq-int.empty` on line 56. With that edit `main` checks.
