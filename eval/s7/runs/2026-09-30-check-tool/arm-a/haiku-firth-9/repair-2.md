Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim <
    [ 
      max-val xs i prim seq-int.at prim <
      [ xs i prim seq-int.at ]
      [ max-val ]
      if
      locals { new-max } {
        i 1 prim +
        xs new-max max-helper
      }
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 xs 0 prim seq-int.at max-helper
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: max-helper
at: line 12, column 20
message: `max-helper` in `max-helper` takes xs:Seq Int, i:Int, max-val:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `new-max` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Seq Int Int
hint: These are the values `max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `i 1 prim +` and `new-max` are for `i` and `max-val`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k i cnt } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at k prim <
      [ cnt 1 prim + ]
      [ cnt ]
      if
      locals { new-cnt } {
        i 1 prim +
        xs k new-cnt count-helper
      }
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 count-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: count-helper
at: line 12, column 22
message: `count-helper` in `count-helper` takes xs:Seq Int, k:Int, i:Int, cnt:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `k` (Int) and `new-cnt` (Int).
expected: .. Seq Int Int Int Int
actual: .. Seq Int Int Int Int Seq Int Int Int
hint: These are the values `count-helper` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `i 1 prim +` and `new-cnt` are for `i` and `cnt`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: search-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs x search-helper ]
      if
    ]
    [ 0 prim - 1 prim + ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  0 search-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: search-helper
at: line 12, column 5
message: In the false branch of the `if` in `search-helper` whose true branch is `[ xs i prim seq-int.at x prim = ...`, `prim -` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`0`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim -`, exactly the values it takes, in this order: Int, Int. The branch already pushes `0`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim -` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ i 1 prim + xs i xs prim seq-int.at prim seq-int.push result reverse-helper ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-helper
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 5, column 26
message: `prim seq-int.at` in `reverse-helper` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t19 Int ?t20 Int ?t20
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs` on line 5. With that edit, the next error in `reverse-helper` is at line 5, column 67.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        i 1 prim +
        xs new-sum result new-sum prim seq-int.push prefix-helper
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  0 0 prim seq-int.empty prefix-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-helper
at: line 9, column 53
message: `prefix-helper` in `prefix-helper` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `new-sum` (Int) and the result of `prim seq-int.push` (Seq Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Int Seq Int Int Seq Int Int Seq Int
hint: These are the values `prefix-helper` takes, in another order. By their names and types, `xs` is for `xs` and `result new-sum prim seq-int.push` is for `result`. Of the values of one type, `i 1 prim +` and `new-sum` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ filtered:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ 
      xs i prim seq-int.at 0 prim <
      [ i 1 prim + xs result filter-helper ]
      [ 
        i 1 prim +
        xs
        result xs i prim seq-int.at prim seq-int.push
        filter-helper
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  0 prim seq-int.empty filter-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: filter-helper
at: line 7, column 30
message: `filter-helper` in `filter-helper` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `result` (Seq Int).
expected: .. Seq Int Int Seq Int
actual: .. Int ?t49 ?t48
hint: These are the values `filter-helper` takes, in another order. To push them in its order, write `xs i 1 prim + result` in place of `i 1 prim + xs result` on line 7. With that edit, the next error in `filter-helper` is at line 12, column 9.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ i 1 prim + xs check-sorted ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 check-sorted;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-sorted
at: line 8, column 23
message: `check-sorted` in `check-sorted` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t35
hint: These are the values `check-sorted` takes, in another order. To push them in its order, write `xs i 1 prim +` in place of `i 1 prim + xs` on line 8. With that edit `check-sorted` checks.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      acc prim +
      locals { new-acc } {
        i 1 prim +
        xs ys new-acc dot-helper
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-helper
at: line 10, column 23
message: `dot-helper` in `dot-helper` takes xs:Seq Int, ys:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and `new-acc` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Seq Int Int Seq Int Int Seq Int Seq Int Int
hint: These are the values `dot-helper` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `i 1 prim +` and `new-acc` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        i 1 prim + flags check-all
      ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 check-all;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-all
at: line 8, column 26
message: `check-all` in `check-all` takes flags:Seq Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int ?t27
hint: These are the values `check-all` takes, in another order. To push them in its order, write `flags i 1 prim +` in place of `i 1 prim + flags` on line 8. With that edit `check-all` checks.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many run-len:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i run-len max-run } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
      [
        run-len 1 prim + locals { new-run } {
          i 1 prim + xs new-run max-run run-helper
        }
      ]
      [
        run-len max-run prim <
        [ max-run ]
        [ run-len ]
        if
        locals { new-max } {
          i 1 prim + xs 1 new-max run-helper
        }
      ]
      if
    ]
    [
      run-len max-run prim <
      [ max-run ]
      [ run-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 1 0 xs run-helper ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: run-helper
at: line 9, column 41
message: `run-helper` in `run-helper` takes xs:Seq Int, i:Int, run-len:Int, max-run:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `new-run` (Int) and `max-run` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int ?t81 ?t80 Int ?t81 Int ?t80
hint: These are the values `run-helper` takes, in another order. By their names and types, `xs` is for `xs` and `max-run` is for `max-run`. Of the values of one type, `i 1 prim +` and `new-run` are for `i` and `run-len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 37, column 16
message: `run-helper` in `main` takes xs:Seq Int, i:Int, run-len:Int, max-run:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `1` (Int), `0` (Int) and `xs` (Seq Int). `main` calls `run-helper`, which has an error of its own; this report assumes `run-helper` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: .. Int Int Int ?t8
hint: These are the values `run-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `0` and `1` are for `i`, `run-len` and `max-run`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-pairs
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      [ 
        xs prim seq-int.len prim <
        [
          xs i prim seq-int.at xs prim seq-int.at prim + target prim =
          [
            true
          ]
          [
            1 prim + [ xs prim seq-int.len prim < [ xs swap prim seq-int.at xs i prim seq-int.at prim + target prim = [ true ] [ 1 prim + ] if ] [ false ] if ] call
          ]
          if
        ]
        [ false ]
        if
      ] call
      [
        i 1 prim + xs target check-pairs
      ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 check-pairs;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-pairs
at: line 15, column 141
message: In the false branch of the `if` in `check-pairs` whose true branch is `[ true ]`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-unique
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i j count } {
    i xs prim seq-int.len prim <
    [
      j xs prim seq-int.len prim <
      [
        xs i prim seq-int.at xs j prim seq-int.at prim =
        [ j 1 prim + xs i xs count count-unique ]
        [ 
          j 1 prim + xs i xs count count-unique
        ]
        if
      ]
      [
        i 1 prim + i 1 prim + xs count 1 prim + count-unique
      ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 0 count-unique;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-unique
at: line 18, column 7
message: The two branches of the `if` in `count-unique` whose true branch is `[ xs i prim seq-int.at xs j prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `count-unique`; the false branch leaves the result of `count-unique`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `count-unique`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        i 1 prim + j xs ys result xs i prim seq-int.at prim seq-int.push merge-helper
      ]
      [
        i j 1 prim + xs ys result ys j prim seq-int.at prim seq-int.push merge-helper
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + j xs ys result xs i prim seq-int.at prim seq-int.push merge-helper
      ]
      [
        j ys prim seq-int.len prim <
        [
          i j 1 prim + xs ys result ys j prim seq-int.at prim seq-int.push merge-helper
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
  0 0 prim seq-int.empty merge-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-helper
at: line 8, column 74
message: `merge-helper` in `merge-helper` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `j` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim seq-int.push` (Seq Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Int ?t113 Seq Int ?t111 Seq Int
hint: These are the values `merge-helper` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `i 1 prim + j xs ys result xs i prim seq-int.at prim seq-int.push` on line 8. With that edit, the next error in `merge-helper` is at line 11, column 74.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result swap prim seq-int.push
      locals { new-result } {
        n 10 prim div new-result digits-helper
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  prim seq-int.empty digits-helper;

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [ true ]
    [
      candidate divisor prim mod 0 prim =
      [ false ]
      [ candidate divisor 1 prim + is-prime ]
      if
    ]
    if
  };

: collect-primes
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim < i 2 prim <
    prim or prim not
    [
      i 2 is-prime
      [ i 1 prim + i result i prim seq-int.push collect-primes ]
      [ i 1 prim + i result collect-primes ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  2 prim seq-int.empty collect-primes;

```
On the example, it returned [[]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        val counts prim seq-int.at
        counts val swap 1 prim + prim seq-int.set
        locals { new-counts } {
          i 1 prim + xs k new-counts histogram-helper
        }
      }
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ k 1 prim + dup prim seq-int.push swap 1 prim + dup k prim < [ ] [ drop ] if ]
    call
    locals { init-counts } {
      0 xs k init-counts histogram-helper
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-helper
at: line 8, column 20
message: `prim seq-int.at` in `histogram-helper` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `val` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t34 ?t33 Int Int ?t34
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `counts val` in place of `val counts` on line 8. With that edit, the next error in `histogram-helper` is at line 9, column 27.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 24, column 80
message: The two branches of `if` in `main` leave different numbers of values: the true branch leaves the stack as it is, and the false branch takes 1 value from the stack below the `if` and leaves nothing. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ result:Seq Int^many x:Int^many -- ρ sorted:Seq Int^many)
  locals { result x } {
    0
    [ 
      result prim seq-int.len prim <
      result swap prim seq-int.at x prim <
      prim and
      [ 
        result swap prim seq-int.at
        1 prim +
      ]
      [ false ]
      if
    ]
    call
    locals { idx } {
      result idx x prim seq-int.set
    }
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result insert-sorted
      locals { new-result } {
        i 1 prim + xs new-result sort-helper
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  0 prim seq-int.empty sort-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-sorted
at: line 14, column 7
message: The two branches of `if` in `insert-sorted` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: sort-helper
at: line 28, column 14
message: `insert-sorted` in `sort-helper` takes result:Seq Int, x:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int). `sort-helper` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t24
hint: These are the values `insert-sorted` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 27. With that edit, the next error in `sort-helper` is at line 29, column 34.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: apply-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim <
        [ 
          i 1 prim + txs balance rejected 1 prim + apply-transactions
        ]
        [
          i 1 prim + txs balance tx prim + rejected apply-transactions
        ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs apply-transactions
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: apply-transactions
at: line 10, column 52
message: `apply-transactions` in `apply-transactions` takes balance:Int, rejected:Int, i:Int, txs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `txs` (Seq Int), `balance` (Int) and the result of `prim +` (Int).
expected: .. Int Int Int Seq Int
actual: .. Int ?t72 ?t71 Int
hint: These are the values `apply-transactions` takes, in another order. By their names and types, `balance` is for `balance` and `txs` is for `txs`. Of the values of one type, `i 1 prim +` and `rejected 1 prim +` are for `rejected` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim < qty r prim = prim or
            [
              qty r prim <
              [
                stock item qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push
                locals { new-stock new-allocated new-reasons } {
                  i 1 prim + new-stock items qtys whole new-allocated new-reasons allocate-one
                }
              ]
              [
                stock item 0 prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push
                locals { new-stock new-allocated new-reasons } {
                  i 1 prim + new-stock items qtys whole new-allocated new-reasons allocate-one
                }
              ]
              if
            ]
            [
              whole i prim seq-bool.at
              [
                allocated 0 prim seq-int.push reasons 3 prim seq-int.push
                locals { new-allocated new-reasons } {
                  i 1 prim + stock items qtys whole new-allocated new-reasons allocate-one
                }
              ]
              [
                stock item r prim seq-int.set allocated r prim seq-int.push reasons 1 prim seq-int.push
                locals { new-stock new-allocated new-reasons } {
                  i 1 prim + new-stock items qtys whole new-allocated new-reasons allocate-one
                }
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

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  0 prim seq-int.empty prim seq-int.empty allocate-one;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: allocate-one
at: line 18, column 83
message: `allocate-one` in `allocate-one` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `new-stock` (Seq Int), `items` (Seq Int), `qtys` (Seq Int), `whole` (Seq Bool), `new-allocated` (Seq Int) and `new-reasons` (Seq Int).
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int
actual: .. Int ?t315 ?t314 ?t313 Int Seq Int ?t315 ?t314 ?t313 Seq Int Seq Int
hint: These are the values `allocate-one` takes, in another order. By their names and types, `items` is for `items`, `qtys` is for `qtys`, `whole` is for `whole` and `i 1 prim +` is for `i`. Of the values of one type, `new-stock`, `new-allocated` and `new-reasons` are for `stock`, `allocated` and `reasons`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.
