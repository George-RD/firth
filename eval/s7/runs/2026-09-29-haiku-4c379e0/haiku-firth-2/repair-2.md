Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at acc prim +
      sum-acc
    ] [
      acc
    ] if
  };

: main
  ( -- result:Int^many)
  locals { xs } {
    xs 0 0
    sum-acc
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 16, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-val
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [ b ] [ a ] if
  };

: max-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at max max-val
      max-acc
    ] [
      max
    ] if
  };

: main
  ( -- result:Int^many)
  locals { xs } {
    xs 0 xs 0 prim seq-int.at
    max-acc
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 22, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-acc
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim < [
      xs
      k
      i 1 prim +
      xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if
      count-acc
    ] [
      count
    ] if
  };

: main
  (-- result:Int^many)
  locals { k xs } {
    xs k 0 0
    count-acc
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 17, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        xs
        x
        i 1 prim +
        index-loop
      ] if
    ] [
      -1
    ] if
  };

: main
  (-- result:Int^many)
  locals { x xs } {
    xs x 0
    index-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 20, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [
      result
    ] [
      xs
      i -1 prim +
      xs i prim seq-int.at result prim seq-int.push
      reverse-acc
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len -1 prim + prim seq-int.empty
    reverse-acc
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 16, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at sum prim +
      dup
      result prim seq-int.push
      prefix-acc
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty
    prefix-acc
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 18, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at dup 0 prim < prim not [
        result prim seq-int.push
      ] [
        drop result
      ] if
      keep-positive-acc
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty
    keep-positive-acc
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 20, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len -1 prim + prim < [
      xs i -1 prim + prim seq-int.at xs i prim seq-int.at prim < [
        false
      ] [
        xs
        i 1 prim +
        is-sorted-loop
      ] if
    ] [
      true
    ] if
  };

: main
  (-- result:Bool^many)
  locals { xs } {
    xs 0
    is-sorted-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 19, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: max-val
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [ b ] [ a ] if
  };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim < [
      xs
      ys
      i 1 prim +
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      dot-loop
    ] [
      sum
    ] if
  };

: main
  (-- result:Int^many)
  locals { ys xs } {
    xs ys 0 0
    dot-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 23, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim < [
      flags i prim seq-bool.at prim not [
        false
      ] [
        flags
        i 1 prim +
        all-true-loop
      ] if
    ] [
      true
    ] if
  };

: main
  (-- result:Bool^many)
  locals { flags } {
    flags 0
    all-true-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 19, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: max-val
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [ b ] [ a ] if
  };

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i current-run max-run } {
    i xs prim seq-int.len prim < [
      i 0 prim = [
        xs
        i 1 prim +
        1
        0
        longest-run-loop
      ] [
        xs i -1 prim + prim seq-int.at xs i prim seq-int.at prim = [
          xs
          i 1 prim +
          current-run 1 prim +
          max-run
          longest-run-loop
        ] [
          xs
          i 1 prim +
          1
          current-run max-run max-val
          longest-run-loop
        ] if
      ] if
    ] [
      current-run max-run max-val
    ] if
  };

: main
  (-- result:Int^many)
  locals { xs } {
    xs 0 0 0
    longest-run-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 39, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [
      xs target i -1 prim +
      has-pair-inner [
        true
      ] [
        xs
        target
        i 1 prim +
        has-pair-outer
      ] if
    ] [
      false
    ] if
  };

: has-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target j } {
    j 0 prim < [
      false
    ] [
      xs j prim seq-int.at xs j -1 prim + prim seq-int.at prim + target prim = [
        true
      ] [
        xs
        target
        j -1 prim +
        has-pair-inner
      ] if
    ] if
  };

: main
  (-- result:Bool^many)
  locals { target xs } {
    xs target 0
    has-pair-outer
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 38, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i seen count } {
    i xs prim seq-int.len prim < [
      xs xs i prim seq-int.at seen i -1 prim +
      has-in-seen [
        xs
        i 1 prim +
        seen
        count
        count-distinct-outer
      ] [
        xs
        i 1 prim +
        seen xs i prim seq-int.at prim seq-int.push
        count 1 prim +
        count-distinct-outer
      ] if
    ] [
      count
    ] if
  };

: has-in-seen
  (forall ρ; ρ xs:Seq Int^many target:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target j } {
    j 0 prim < [
      false
    ] [
      xs j prim seq-int.at target prim = [
        true
      ] [
        xs
        target
        j -1 prim +
        has-in-seen
      ] if
    ] if
  };

: main
  (-- result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty 0
    count-distinct-outer
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 21, column 7
message: The two branches of the `if` in `count-distinct-outer` whose true branch is `[ xs xs i prim seq-int.at seen i ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `count-distinct-outer`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `count-distinct-outer`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          xs
          ys
          i 1 prim +
          j
          result xs i prim seq-int.at prim seq-int.push
          merge-loop
        ] [
          xs
          ys
          i
          j 1 prim +
          result ys j prim seq-int.at prim seq-int.push
          merge-loop
        ] if
      ] [
        xs
        ys
        i 1 prim +
        j
        result xs i prim seq-int.at prim seq-int.push
        merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        xs
        ys
        i
        j 1 prim +
        result ys j prim seq-int.at prim seq-int.push
        merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { ys xs } {
    xs ys 0 0 prim seq-int.empty
    merge-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 45, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

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
    n 0 prim = [
      result prim seq-int.len 0 prim = [ { 0 } ] [ result ] if
    ] [
      n 0 prim < [
        result
      ] [
        n 10 prim mod result prim seq-int.push
        n 10 prim div
        digits-loop
      ] if
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { n } {
    n prim seq-int.empty
    digits-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 19, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [
      n 2 prim = [ true ] [
        n 2 prim mod 0 prim = [ false ] [
          n 3 is-prime-check
        ] if
      ] if
    ] if
  };

: is-prime-check
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim < [
      n i prim mod 0 prim = [ false ] [
        n i 2 prim + is-prime-check
      ] if
    ] [
      true
    ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    i n prim < [
      i is-prime [
        n
        i 1 prim +
        result i prim seq-int.push
        primes-loop
      ] [
        n
        i 1 prim +
        result
        primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty
    primes-loop
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
at: line 47, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i result } {
    i xs prim seq-int.len prim < [
      xs
      k
      i 1 prim +
      xs i prim seq-int.at dup
      result prim seq-int.at
      1 prim +
      prim seq-int.set
      histogram-loop
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { k xs } {
    xs k 0 prim seq-int.empty
    histogram-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 15, column 7
message: The two branches of `if` in `histogram-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i 0 prim = [
      sorted x prim seq-int.push
    ] [
      sorted i -1 prim + prim seq-int.at x prim < [
        sorted x prim seq-int.push
      ] [
        x sorted i -1 prim +
        insert-sorted
        i -1 prim + prim seq-int.at prim seq-int.set
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim < [
      xs
      i 1 prim +
      xs i prim seq-int.at result result prim seq-int.len
      insert-sorted
      sort-loop
    ] [
      result
    ] if
  };

: main
  (-- result:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty
    sort-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 9
message: In the false branch of the `if` in `insert-sorted` whose true branch is `[ sorted x prim seq-int.push ]`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.at`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim < [
      balance txs i prim seq-int.at prim +
      dup 0 prim < [
        drop
        balance
        rejected 1 prim +
      ] [
        swap drop
        rejected
      ] if
      i 1 prim +
      ledger-loop
    ] [
      balance rejected
    ] if
  };

: main
  (-- balance:Int^many rejected:Int^many)
  locals { txs start } {
    start txs 0 0
    ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 9
message: In the false branch of the `if` in `ledger-loop` whose true branch is `[ drop balance rejected 1 prim + ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim +` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item qty whole } {
    stock item prim seq-int.at
    qty prim - dup 0 prim < [
      drop qty 0 prim = [ 2 ] [ whole [ 3 ] [ 1 ] if ] if
      qty stock item prim seq-int.at prim - prim seq-int.set
      stock
    ] [
      0 prim = [ stock qty item prim seq-int.at prim - prim seq-int.set 0 ] [
        0
      ] if
    ] if
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim < [
      stock items i prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at allocate-one
      i 1 prim +
      allocated prim seq-int.push
      reasons prim seq-int.push
      allocate-loop
    ] [
      stock allocated reasons
    ] if
  };

: main
  (-- stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty
    allocate-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 9
message: The two branches of `if` in `allocate-one` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 2 values, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
