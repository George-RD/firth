Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at acc prim + locals { new-acc } {
        new-acc xs i 1 prim + sum-loop
      }
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 sum-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sum-loop
at: line 6, column 12
message: `prim seq-int.at` in `sum-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `sum-loop` checks.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ current-max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { current-max xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { elem } {
        [ current-max ]
        [ elem ]
        elem current-max prim <
        if
        xs i 1 prim + max-loop
      }
    ]
    [ current-max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 0 max-loop };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: max-loop
at: line 11, column 9
message: The local `xs` is used after `if` on line 10 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ result:Int^many)
  locals { count xs i k } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at k prim <
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      xs i 1 prim + k count-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 xs 0 k count-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: count-loop
at: line 6, column 12
message: `prim seq-int.at` in `count-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `count-loop` checks.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at x prim =
      [
        i
      ]
      [
        xs x i 1 prim + index-loop
      ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs x index-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: index-loop
at: line 6, column 12
message: `prim seq-int.at` in `index-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `index-loop` is at line 11, column 25.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs i } {
    i 0 prim <
    [
      i xs prim seq-int.at result prim seq-int.push locals { new-result } {
        new-result xs i 1 prim - reverse-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 6, column 12
message: `prim seq-int.at` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `reverse-loop` is at line 6, column 35.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ sum:Int^many result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { sum result xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at sum prim + locals { new-sum } {
        result new-sum prim seq-int.push locals { new-result } {
          new-sum new-result xs i 1 prim + prefix-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs 0 prefix-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 6, column 12
message: `prim seq-int.at` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `prefix-loop` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { elem } {
        elem 0 prim <
        [
          result
        ]
        [
          result elem prim seq-int.push
        ]
        if
        xs i 1 prim + keep-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: keep-loop
at: line 6, column 12
message: `prim seq-int.at` in `keep-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `keep-loop` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      i xs prim seq-int.at locals { curr } {
        i 1 prim + xs prim seq-int.at locals { next } {
          curr next prim <
          [
            xs i 1 prim + sorted-loop
          ]
          [
            next curr prim = [ xs i 1 prim + sorted-loop ] [ false ] if
          ]
          if
        }
      }
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sorted-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sorted-loop
at: line 6, column 12
message: `prim seq-int.at` in `sorted-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `sorted-loop` is at line 7, column 23.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ product:Int^many)
  locals { sum xs ys i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at i ys prim seq-int.at prim * sum prim + locals { new-sum } {
        new-sum xs ys i 1 prim + dot-loop
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 xs ys 0 dot-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: dot-loop
at: line 6, column 12
message: `prim seq-int.at` in `dot-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `dot-loop` is at line 6, column 33.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ result:Bool^many flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { result flags i } {
    i flags prim seq-bool.len prim <
    [
      i flags prim seq-bool.at
      [
        flags i 1 prim + all-loop
      ]
      [
        false
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true flags 0 all-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-loop
at: line 13, column 7
message: In the true branch `[ flags i 1 prim + all-loop ]` of the `if` in `all-loop`, `all-loop` needs 3 values (result:Bool, flags:Seq Bool, i:Int), but the branch has pushed only 2 values before it (`flags` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: result:Bool, flags:Seq Bool, i:Int. The branch already pushes `flags` and the result of `prim +`, in the place of the last 2 (flags:Seq Bool, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Bool) before them, for example by writing the locals that hold it. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ max-len:Int^many run-len:Int^many xs:Seq Int^many i:Int^many -- ρ length:Int^many)
  locals { max-len run-len xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { curr } {
        i 1 prim + xs prim seq-int.len prim <
        [
          i 1 prim + xs prim seq-int.at locals { next } {
            curr next prim =
            [
              max-len run-len 1 prim + locals { new-run } {
                [ new-run ] [ max-len ] new-run max-len prim < if xs new-run i 1 prim + run-loop
              }
            ]
            [
              [ run-len ] [ max-len ] run-len max-len prim < if 1 xs i 1 prim + run-loop
            ]
            if
          }
        ]
        [
          [ run-len ] [ max-len ] run-len max-len prim < if
        ]
        if
      }
    ]
    [ max-len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { 0 0 xs 0 run-loop };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: run-loop
at: line 13, column 67
message: The local `xs` is used after `if` on line 13 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-check
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } {
    i 1 prim + xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { xi } {
        i 1 prim + xs prim seq-int.len prim <
        [
          i 1 prim + xs prim seq-int.at locals { xj } {
            xi xj prim + target prim =
            [
              true
            ]
            [
              xs target i 1 prim + pair-check
            ]
            if
          }
        ]
        [
          xs target i 1 prim + pair-check
        ]
        if
      }
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs target pair-check };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: pair-check
at: line 6, column 12
message: `prim seq-int.at` in `pair-check` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `pair-check` is at line 9, column 25.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-check
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { elem } {
        0 locals { j } {
          [ j xs prim seq-int.len prim < ] [ j elem xs prim seq-int.at prim = prim not prim and ] [ true ] if
          [ j 1 prim + ] compose [ j ] compose prim or
        }
        [
          count 1 prim +
        ]
        [
          count
        ]
        if
        xs i 1 prim + distinct-check
      }
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 distinct-check };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-check
at: line 8, column 108
message: In the true branch `[ j elem xs prim seq-int.at prim = ...` of the `if` in `distinct-check`, `prim and` needs 2 values (Bool, Bool), but the branch has pushed only 1 value before it (the result of `prim not`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim and`, exactly the values it takes, in this order: Bool, Bool. The branch already pushes the result of `prim not`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim and` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        i xs prim seq-int.at j ys prim seq-int.at prim < 
        [
          result i xs prim seq-int.at prim seq-int.push locals { new-result } {
            new-result xs ys i 1 prim + j merge-loop
          }
        ]
        [
          result j ys prim seq-int.at prim seq-int.push locals { new-result } {
            new-result xs ys i j 1 prim + merge-loop
          }
        ]
        if
      ]
      [
        i xs prim seq-int.len prim <
        [
          result i xs prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result j ys prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 8, column 14
message: `prim seq-int.at` in `merge-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `merge-loop` is at line 8, column 35.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod locals { digit } {
        result digit prim seq-int.push locals { new-result } {
          n 10 prim div new-result digit-loop
        }
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many source:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result source i } {
    i 0 prim <
    [
      i source prim seq-int.at result prim seq-int.push locals { new-result } {
        new-result source i 1 prim - reverse-digits
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      prim seq-int.empty n digit-loop locals { rev-digits } {
        prim seq-int.empty rev-digits rev-digits prim seq-int.len 1 prim - reverse-digits
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digit-loop
at: line 11, column 36
message: `digit-loop` in `digit-loop` takes result:Seq Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim div` (Int) and `new-result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int Int Seq Int
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `new-result n 10 prim div` in place of `n 10 prim div new-result`. With that edit `digit-loop` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 23, column 16
message: `prim seq-int.at` in `reverse-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `source` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `source i` in place of `i source`. With that edit, the next error in `reverse-digits` is at line 23, column 39.

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
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        n 2 prim mod 0 prim =
        [ false ]
        [ true ]
        if
      ]
      if
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many i:Int^many -- ρ primes:Seq Int^many)
  locals { result n i } {
    i n prim <
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      i 1 prim + n sieve-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty n 2 sieve-loop };

```
On the example, it returned [[2]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { result xs i k } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at locals { val } {
        val result prim seq-int.at locals { count } {
          result val count 1 prim + prim seq-int.set xs i 1 prim + k histogram-loop
        }
      }
    ]
    [ result ]
    if
  };

: init-counts
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ initialized:Seq Int^many)
  locals { result i k } {
    i k prim <
    [
      result 0 prim seq-int.push i 1 prim + k init-counts
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k init-counts xs 0 k histogram-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 6, column 12
message: `prim seq-int.at` in `histogram-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `histogram-loop` is at line 7, column 20.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ elem:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { elem result } {
    result prim seq-int.len locals { len } {
      0 locals { i } {
        [ i len prim < ] [ elem result i prim seq-int.at prim < prim not ] [ true ] if
        [ i 1 prim + ]
        [ i ]
      }
    }
    locals { pos } {
      result pos elem prim seq-int.set
    }
  };

: sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      i xs prim seq-int.at insert-sorted xs i 1 prim + sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 sort-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: insert-sorted
at: line 6, column 85
message: `if` in `insert-sorted` needs a Bool condition under its two quotations, but the stack before it is ρ Int Seq Int Int Int [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-loop
at: line 24, column 5
message: In the true branch `[ i xs prim seq-int.at insert-sorted xs i ...` of the `if` in `sort-loop`, `insert-sorted` needs 2 values (elem:Int, result:Seq Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `sort-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: Make the branch push, just before `insert-sorted`, exactly the values it takes, in this order: elem:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.at`, in the place of the first one (elem:Int): keep it where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after it, for example by writing the locals that hold it. If `insert-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim <
    [
      i txs prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim <
          [
            balance txs i 1 prim + rejected 1 prim + ledger-loop
          ]
          [
            new-balance txs i 1 prim + rejected ledger-loop
          ]
          if
        }
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: ledger-loop
at: line 6, column 13
message: `prim seq-int.at` in `ledger-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `txs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `txs i` in place of `i txs`. With that edit, the next error in `ledger-loop` is at line 10, column 54.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { allocated reasons stock items qtys whole i } {
    i items prim seq-int.len prim <
    [
      i items prim seq-int.at locals { item } {
        i qtys prim seq-int.at locals { qty } {
          i whole prim seq-bool.at locals { whole-flag } {
            item stock prim seq-int.at locals { curr-stock } {
              qty curr-stock prim <
              [
                allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item qty prim seq-int.set items qtys whole i 1 prim + allocate-loop
              ]
              [
                qty curr-stock prim =
                [
                  allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item 0 prim seq-int.set items qtys whole i 1 prim + allocate-loop
                ]
                [
                  curr-stock 0 prim =
                  [
                    allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
                  ]
                  [
                    whole-flag
                    [
                      allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
                    ]
                    [
                      allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set items qtys whole i 1 prim + allocate-loop
                    ]
                    if
                  ]
                  if
                ]
                if
              ]
              if
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { prim seq-int.empty prim seq-int.empty stock items qtys whole 0 allocate-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: allocate-loop
at: line 6, column 15
message: `prim seq-int.at` in `allocate-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `items` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `items i` in place of `i items`. With that edit, the next error in `allocate-loop` is at line 7, column 16.
