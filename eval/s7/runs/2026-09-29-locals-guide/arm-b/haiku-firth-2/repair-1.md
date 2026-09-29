Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { acc xs idx } {
    idx xs prim seq-int.len prim < [
      acc idx xs prim seq-int.at prim + xs idx 1 prim + sum-loop
    ] [
      acc
    ] if
  };

: main
  ( xs:Seq Int^many -- total:Int^many )
  locals { xs } {
    0 0 xs sum-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: sum-loop
at: line 5, column 18
message: `prim seq-int.at` in `sum-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `sum-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 14, column 12
message: `sum-loop` in `main` takes acc:Int, xs:Seq Int, idx:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int) and `xs` (Seq Int). `main` calls `sum-loop`, which has an error of its own; this report assumes `sum-loop` keeps its stack effect.
expected: .. Int Seq Int Int
actual: Int Int Seq Int
hint: These are the values `sum-loop` takes, in another order. To push them in its order, write `0 xs 0` in place of `0 0 xs`. With that edit `main` checks.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { max xs idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at locals { x } {
        x max prim < [
          x xs idx 1 prim + max-loop
        ] [
          max xs idx 1 prim + max-loop
        ] if
      }
    ] [
      max
    ] if
  };

: main
  ( xs:Seq Int^many -- largest:Int^many )
  locals { xs } {
    0 xs prim seq-int.at xs 0 1 prim + max-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: max-loop
at: line 5, column 14
message: `prim seq-int.at` in `max-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `max-loop` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 20, column 10
message: `prim seq-int.at` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: Seq Int Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs 0` in place of `0 xs`. With that edit `main` checks. That edit was checked assuming `max-loop`, which has an error of its own, keeps its stack effect.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ cnt:Int^many xs:Seq Int^many k:Int^many idx:Int^many -- ρ result:Int^many)
  locals { cnt xs k idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at k prim < [
        cnt 1 prim + xs k idx 1 prim + count-loop
      ] [
        cnt xs k idx 1 prim + count-loop
      ] if
    ] [
      cnt
    ] if
  };

: main
  ( xs:Seq Int^many k:Int^many -- count:Int^many )
  locals { xs k } {
    0 xs k 0 count-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: count-loop
at: line 5, column 14
message: `prim seq-int.at` in `count-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `count-loop` checks.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs x idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at x prim = [
        idx
      ] [
        xs x idx 1 prim + find-loop
      ] if
    ] [
      -1
    ] if
  };

: main
  ( xs:Seq Int^many x:Int^many -- index:Int^many )
  locals { xs x } {
    xs x 0 find-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: find-loop
at: line 5, column 14
message: `prim seq-int.at` in `find-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `find-loop` checks.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ res:Seq Int^many)
  locals { result xs idx } {
    idx 0 prim < [
      result idx xs prim seq-int.at prim seq-int.push xs idx 1 prim - reverse-helper
    ] [
      result
    ] if
  };

: main
  ( xs:Seq Int^many -- reversed:Seq Int^many )
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-helper
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 5, column 21
message: `prim seq-int.at` in `reverse-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `reverse-helper` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many sum:Int^many idx:Int^many -- ρ res:Seq Int^many)
  locals { result xs sum idx } {
    idx xs prim seq-int.len prim < [
      sum idx xs prim seq-int.at prim + locals { newsum } {
        result newsum prim seq-int.push xs newsum idx 1 prim + prefix-loop
      }
    ] [
      result
    ] if
  };

: main
  ( xs:Seq Int^many -- sums:Seq Int^many )
  locals { xs } {
    prim seq-int.empty xs 0 0 prefix-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 5, column 18
message: `prim seq-int.at` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `prefix-loop` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ res:Seq Int^many)
  locals { result xs idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at locals { x } {
        x 0 prim < [
          result xs idx 1 prim + filter-loop
        ] [
          result x prim seq-int.push xs idx 1 prim + filter-loop
        ] if
      }
    ] [
      result
    ] if
  };

: main
  ( xs:Seq Int^many -- positives:Seq Int^many )
  locals { xs } {
    prim seq-int.empty xs 0 filter-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: filter-loop
at: line 5, column 14
message: `prim seq-int.at` in `filter-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `filter-loop` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim < [
      idx xs prim seq-int.at idx 1 prim + xs prim seq-int.at prim < [
        false
      ] [
        xs idx 1 prim + check-loop
      ] if
    ] [
      true
    ] if
  };

: main
  ( xs:Seq Int^many -- sorted:Bool^many )
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      xs 0 check-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: check-loop
at: line 5, column 14
message: `prim seq-int.at` in `check-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit, the next error in `check-loop` is at line 5, column 46.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { sum xs ys idx } {
    idx xs prim seq-int.len prim < [
      sum idx xs prim seq-int.at idx ys prim seq-int.at prim * prim + xs ys idx 1 prim + dot-loop
    ] [
      sum
    ] if
  };

: main
  ( xs:Seq Int^many ys:Seq Int^many -- product:Int^many )
  locals { xs ys } {
    0 xs ys 0 dot-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: dot-loop
at: line 5, column 18
message: `prim seq-int.at` in `dot-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit, the next error in `dot-loop` is at line 5, column 41.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all-loop
  (forall ρ; ρ xs:Seq Bool^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-bool.len prim < [
      idx xs prim seq-bool.at [
        xs idx 1 prim + check-all-loop
      ] [
        false
      ] if
    ] [
      true
    ] if
  };

: main
  ( flags:Seq Bool^many -- all:Bool^many )
  locals { flags } {
    flags prim seq-bool.len 0 prim = [
      true
    ] [
      flags 0 check-all-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: check-all-loop
at: line 5, column 14
message: `prim seq-bool.at` in `check-all-loop` takes Seq Bool, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int Seq Bool
hint: These are the values `prim seq-bool.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `check-all-loop` checks.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ current:Int^many max-run:Int^many xs:Seq Int^many idx:Int^many -- ρ result:Int^many)
  locals { current max-run xs idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at idx 1 prim + xs prim seq-int.at prim = [
        current 1 prim + xs idx 1 prim + count-run
      ] [
        current max-run prim < [
          max-run xs idx 1 prim + count-run
        ] [
          current xs idx 1 prim + count-run
        ] if
      ]
    ] [
      current max-run prim < [
        max-run
      ] [
        current
      ] if
    ] if
  };

: main
  ( xs:Seq Int^many -- length:Int^many )
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      1 0 xs 0 count-run
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-run
at: line 20, column 7
message: The two branches of the `if` in `count-run` whose true branch is `[ idx xs prim seq-int.at idx 1 prim ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim =`, the quotation `[ current 1 prim + xs idx 1 ...` and the quotation `[ current max-run prim < [ max-run xs ...`; the false branch leaves the result of an `if`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim =` and the quotation `[ current 1 prim + xs idx 1 ...` are left below the quotation `[ current max-run prim < [ max-run xs ...`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      i 1 prim + xs prim seq-int.len prim < [
        i 1 prim + xs target i find-pair-inner
      ] [
        xs target i 1 prim + find-pair
      ] if
    ] [
      false
    ] if
  };

: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim < [
      i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [
        true
      ] [
        xs target i j 1 prim + find-pair-inner
      ] if
    ] [
      xs target i 1 prim + find-pair
    ] if
  };

: main
  ( xs:Seq Int^many target:Int^many -- found:Bool^many )
  locals { xs target } {
    xs target 0 find-pair
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: find-pair
at: line 6, column 32
message: `find-pair-inner` in `find-pair` takes xs:Seq Int, target:Int, i:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `target` (Int) and `i` (Int). `find-pair` calls `find-pair-inner`, which has an error of its own; this report assumes `find-pair-inner` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: .. Int ?t46 ?t45 Int
hint: These are the values `find-pair-inner` takes, in another order. To push them in its order, write `xs target i i 1 prim +` in place of `i 1 prim + xs target i`. With that edit `find-pair` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: find-pair-inner
at: line 19, column 12
message: `prim seq-int.at` in `find-pair-inner` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `find-pair-inner` is at line 19, column 33. That edit was checked assuming `find-pair`, which has an error of its own, keeps its stack effect.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many count:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs count idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at xs idx 1 prim + idx xs prim seq-int.at count-contains
    ] [
      count
    ] if
  };

: count-contains
  (forall ρ; ρ xs:Seq Int^many count:Int^many check-idx:Int^many x:Int^many next-idx:Int^many -- ρ result:Int^many)
  locals { xs count check-idx x next-idx } {
    check-idx next-idx prim < [
      check-idx xs prim seq-int.at x prim = [
        xs count next-idx count-helper
      ] [
        xs count check-idx 1 prim + x next-idx count-contains
      ] if
    ] [
      xs count 1 prim + next-idx count-helper
    ] if
  };

: main
  ( xs:Seq Int^many -- count:Int^many )
  locals { xs } {
    xs 0 0 count-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-helper
at: line 8, column 7
message: In the true branch `[ idx xs prim seq-int.at xs idx 1 ...` of the `if` in `count-helper`, `count-contains` needs 5 values (xs:Seq Int, count:Int, check-idx:Int, x:Int, next-idx:Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.at`, `xs`, the result of `prim +` and the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-helper` calls `count-contains`, which has an error of its own; this report assumes `count-contains` keeps its stack effect.
hint: Make the branch push, just before `count-contains`, exactly the values it takes, in this order: xs:Seq Int, count:Int, check-idx:Int, x:Int, next-idx:Int. The branch already pushes the result of `prim seq-int.at`, `xs`, the result of `prim +` and the result of `prim seq-int.at`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `count-contains` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: count-contains
at: line 15, column 20
message: `prim seq-int.at` in `count-contains` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `check-idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs check-idx` in place of `check-idx xs`. With that edit `count-contains` checks. That edit was checked assuming `count-helper`, which has an error of its own, keeps its stack effect.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ res:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        i xs prim seq-int.at j ys prim seq-int.at prim < [
          result i xs prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [
          result j ys prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
        ] if
      ] [
        i xs prim seq-int.at result prim seq-int.push xs ys i 1 prim + j merge-loop
      ]
    ] [
      j ys prim seq-int.len prim < [
        j ys prim seq-int.at result prim seq-int.push xs ys i j 1 prim + merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  ( xs:Seq Int^many ys:Seq Int^many -- merged:Seq Int^many )
  locals { xs ys } {
    prim seq-int.empty xs ys 0 0 merge-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 20, column 7
message: The two branches of the `if` in `merge-loop` whose true branch is `[ j ys prim seq-int.len prim < [ ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim <`, the quotation `[ i xs prim seq-int.at j ys prim ...` and the quotation `[ i xs prim seq-int.at result prim seq-int.push ...`; the false branch leaves the result of an `if`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim <` and the quotation `[ i xs prim seq-int.at j ys prim ...` are left below the quotation `[ i xs prim seq-int.at result prim seq-int.push ...`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result n } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod result prim seq-int.push n 10 prim div digit-loop
    ] if
  };

: reverse-seq
  (forall ρ; ρ result:Seq Int^many source:Seq Int^many idx:Int^many -- ρ res:Seq Int^many)
  locals { result source idx } {
    idx 0 prim < [
      result idx source prim seq-int.at prim seq-int.push source idx 1 prim - reverse-seq
    ] [
      result
    ] if
  };

: main
  ( n:Int^many -- digits:Seq Int^many )
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n 0 prim < [
        prim seq-int.empty n 0 prim - digit-loop
      ] [
        prim seq-int.empty n digit-loop
      ] if locals { digits } {
        prim seq-int.empty digits digits prim seq-int.len 1 prim - reverse-seq
      }
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 7, column 28
message: `prim seq-int.push` in `digit-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `digit-loop` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-seq
at: line 15, column 25
message: `prim seq-int.at` in `reverse-seq` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `source` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `source idx` in place of `idx source`. With that edit `reverse-seq` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: sieve-mark
  (forall ρ; ρ marked:Seq Bool^many p:Int^many idx:Int^many n:Int^many -- ρ res:Seq Bool^many)
  locals { marked p idx n } {
    idx n prim <= [
      marked idx true prim seq-bool.set p idx prim + n sieve-mark
    ] [
      marked
    ] if
  };

: sieve-loop
  (forall ρ; ρ marked:Seq Bool^many p:Int^many n:Int^many -- ρ res:Seq Bool^many)
  locals { marked p n } {
    p p prim * n prim <= [
      p marked prim seq-bool.at [
        marked p p prim * n sieve-mark p 1 prim + n sieve-loop
      ] [
        marked p 1 prim + n sieve-loop
      ] if
    ] [
      marked
    ] if
  };

: collect-primes
  (forall ρ; ρ result:Seq Int^many marked:Seq Bool^many idx:Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result marked idx n } {
    idx n prim <= [
      idx marked prim seq-bool.at [
        result idx prim seq-int.push marked idx 1 prim + n collect-primes
      ] [
        result marked idx 1 prim + n collect-primes
      ] if
    ] [
      result
    ] if
  };

: main
  ( n:Int^many -- primes:Seq Int^many )
  locals { n } {
    n 1 prim < [
      prim seq-int.empty
    ] [
      prim seq-bool.empty n 1 prim + locals { marked-init } {
        0 marked-init 0 locals { marked } {
          1 marked 0 prim + marked prim seq-bool.set 2 n sieve-loop locals { marked-sieved } {
            prim seq-int.empty marked-sieved 2 n collect-primes
          }
        }
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 4, column 17
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many idx:Int^many -- ρ res:Seq Int^many)
  locals { result k idx } {
    idx k prim < [
      result 0 prim seq-int.push k idx 1 prim + init-histogram
    ] [
      result
    ] if
  };

: count-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { counts xs idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at locals { v } {
        counts v prim seq-int.at 1 prim + v counts prim seq-int.set xs idx 1 prim + count-loop
      }
    ] [
      counts
    ] if
  };

: main
  ( xs:Seq Int^many k:Int^many -- counts:Seq Int^many )
  locals { xs k } {
    prim seq-int.empty k 0 init-histogram locals { counts } {
      counts xs 0 count-loop
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: count-loop
at: line 15, column 14
message: `prim seq-int.at` in `count-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit, the next error in `count-loop` is at line 16, column 52.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ result:Seq Int^many x:Int^many idx:Int^many -- ρ res:Seq Int^many)
  locals { result x idx } {
    idx 0 prim = [
      result x prim seq-int.push
    ] [
      idx 1 prim - result prim seq-int.at x prim < [
        result x prim seq-int.push
      ] [
        result idx result prim seq-int.at prim seq-int.push x idx 1 prim - insert-sorted
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ sorted:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { sorted xs idx } {
    idx xs prim seq-int.len prim < [
      sorted idx xs prim seq-int.at sorted prim seq-int.len insert-sorted xs idx 1 prim + sort-loop
    ] [
      sorted
    ] if
  };

: main
  ( xs:Seq Int^many -- sorted:Seq Int^many )
  locals { xs } {
    prim seq-int.empty xs 0 sort-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: insert-sorted
at: line 7, column 27
message: `prim seq-int.at` in `insert-sorted` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t39 ?t38 Int ?t39
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `result idx 1 prim -` in place of `idx 1 prim - result`. With that edit, the next error in `insert-sorted` is at line 10, column 27.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: sort-loop
at: line 19, column 21
message: `prim seq-int.at` in `sort-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `sort-loop` checks. That edit was checked assuming `insert-sorted`, which has an error of its own, keeps its stack effect.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: process-txn
  (forall ρ; ρ balance:Int^many rejected:Int^many xs:Seq Int^many idx:Int^many -- ρ bal:Int^many rej:Int^many)
  locals { balance rejected xs idx } {
    idx xs prim seq-int.len prim < [
      balance idx xs prim seq-int.at prim + locals { new-balance } {
        new-balance 0 prim < [
          balance rejected 1 prim + xs idx 1 prim + process-txn
        ] [
          new-balance rejected xs idx 1 prim + process-txn
        ] if
      }
    ] [
      balance rejected
    ] if
  };

: main
  ( start:Int^many txs:Seq Int^many -- balance:Int^many rejected:Int^many )
  locals { start txs } {
    start 0 txs 0 process-txn
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: process-txn
at: line 5, column 22
message: `prim seq-int.at` in `process-txn` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs idx` in place of `idx xs`. With that edit `process-txn` checks.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many item:Int^many qty:Int^many need-all:Bool^many order-idx:Int^many -- ρ stk:Seq Int^many alloc:Seq Int^many reas:Seq Int^many)
  locals { stock allocated reasons item qty need-all order-idx } {
    item stock prim seq-int.at locals { available } {
      qty available prim <= [
        stock item qty prim - prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push order-idx 1 prim + allocate-next
      ] [
        available 0 prim = [
          stock allocated reasons 2 prim seq-int.push order-idx 1 prim + allocate-next
        ] [
          need-all [
            stock allocated reasons 3 prim seq-int.push order-idx 1 prim + allocate-next
          ] [
            stock item available prim - prim seq-int.set allocated available prim seq-int.push reasons 1 prim seq-int.push order-idx 1 prim + allocate-next
          ] if
        ] if
      ] if
    }
  };

: allocate-next
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order-idx:Int^many items:Seq Int^many qtys:Seq Int^many wholes:Seq Bool^many -- ρ stk:Seq Int^many alloc:Seq Int^many reas:Seq Int^many)
  locals { stock allocated reasons order-idx items qtys wholes } {
    order-idx qtys prim seq-int.len prim < [
      stock order-idx items prim seq-int.at order-idx qtys prim seq-int.at order-idx wholes prim seq-bool.at order-idx 1 prim + allocate-order
    ] [
      stock allocated reasons
    ] if
  };

: main
  ( stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many )
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-next
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 5, column 27
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
