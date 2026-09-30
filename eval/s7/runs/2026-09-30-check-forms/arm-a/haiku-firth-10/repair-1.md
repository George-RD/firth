Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ total:Int^many)
  locals { xs i acc } {
    xs prim seq-int.len i prim >=
    [ acc ]
    [
      xs i prim seq-int.at acc prim +
      i 1 prim +
      locals { new-acc new-i } {
        xs new-i new-acc sum-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };

```
On the example, it returned [0] instead of [15]

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs i max } {
    xs prim seq-int.len i prim >=
    [ max ]
    [
      xs i prim seq-int.at
      max prim <
      [ max ] [ xs i prim seq-int.at ] if
      i 1 prim +
      locals { new-max new-i } {
        xs new-i new-max max-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1 xs swap max-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 22, column 15
message: `max-loop` in `main` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `1` (Int).
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ count:Int^many)
  locals { xs k i cnt } {
    xs prim seq-int.len i prim >=
    [ cnt ]
    [
      xs i prim seq-int.at k prim <
      [ cnt 1 prim + ] [ cnt ] if
      i 1 prim +
      locals { new-cnt new-i } {
        xs k new-i new-cnt count-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };

```
On the example, it returned [0] instead of [2]

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    xs prim seq-int.len i prim >=
    [ -1 ]
    [
      xs i prim seq-int.at x prim =
      [ i ] [ i 1 prim + xs x find-loop ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x 0 find-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: find-loop
at: line 8, column 31
message: `find-loop` in `find-loop` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `x` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t60 ?t59
hint: These are the values `find-loop` takes, in another order. To push them in its order, write `xs x i 1 prim +` in place of `i 1 prim + xs x` on line 8. With that edit `find-loop` checks.

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
    [ result ]
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      locals { new-i new-result } {
        xs new-i new-result reverse-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 8, column 14
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 7. With that edit, the next error in `reverse-loop` is at line 10, column 29.

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
    xs prim seq-int.len i prim >=
    [ result ]
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        result new-sum prim seq-int.push
        i 1 prim +
        locals { new-i new-result } {
          xs new-i new-sum new-result prefix-loop
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 12, column 39
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `new-i` (Seq Int), `new-sum` (Int) and `new-result` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Int Seq Int Int Seq Int Seq Int Int Int
hint: These are the values `prefix-loop` takes, in another order. By their names and types, `xs` is for `xs` and `new-i` is for `result`. Of the values of one type, `new-sum` and `new-result` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    xs prim seq-int.len i prim >=
    [ result ]
    [
      xs i prim seq-int.at
      locals { v } {
        v 0 prim >
        [ result v prim seq-int.push ] [ result ] if
        i 1 prim +
        locals { new-i new-result } {
          xs new-i new-result filter-loop
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: filter-loop
at: line 13, column 31
message: `filter-loop` in `filter-loop` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `new-i` (Seq Int) and `new-result` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Int Seq Int Seq Int Seq Int Int
hint: These are the values `filter-loop` takes, in another order. To push them in its order, write `xs new-result new-i` in place of `xs new-i new-result` on line 13. With that edit `filter-loop` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-check
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    xs prim seq-int.len i prim >=
    [ true ]
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <=
      [ i 1 prim + xs sorted-check ] [ false ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ true ] [ xs 0 sorted-check ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sorted-check
at: line 10, column 23
message: `sorted-check` in `sorted-check` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t35
hint: These are the values `sorted-check` takes, in another order. To push them in its order, write `xs i 1 prim +` in place of `i 1 prim + xs` on line 10. With that edit `sorted-check` checks.

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
    xs prim seq-int.len i prim >=
    [ sum ]
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      locals { new-sum new-i } {
        xs ys new-i new-sum dot-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };

```
On the example, it returned [0] instead of [32]

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true-check
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    flags prim seq-bool.len i prim >=
    [ true ]
    [
      flags i prim seq-bool.at
      [ i 1 prim + flags all-true-check ] [ false ] if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-bool.len 0 prim =
    [ true ] [ flags 0 all-true-check ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: all-true-check
at: line 8, column 26
message: `all-true-check` in `all-true-check` takes flags:Seq Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int ?t29
hint: These are the values `all-true-check` takes, in another order. To push them in its order, write `flags i 1 prim +` in place of `i 1 prim + flags` on line 8. With that edit `all-true-check` checks.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many run-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { xs i run-len max-len } {
    xs prim seq-int.len i prim >=
    [ max-len ]
    [
      xs i prim seq-int.at
      xs i 1 prim - prim seq-int.at
      prim =
      [ run-len 1 prim + ] [ 1 ] if
      locals { new-run-len } {
        new-run-len max-len prim >
        [ new-run-len ] [ max-len ] if
        locals { new-max-len } {
          i 1 prim +
          locals { new-i } {
            xs new-i new-run-len new-max-len run-loop
          }
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ] [ xs 1 1 1 run-loop ] if
  };

```
On the example, it returned [1] instead of [3]

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
    xs prim seq-int.len i prim >=
    [ false ]
    [
      xs i prim seq-int.at
      locals { v } {
        target v prim -
        locals { needed } {
          i 1 prim +
          [ false ] [ false ] if
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: check-pairs
at: line 12, column 31
message: `if` in `check-pairs` needs a Bool condition under its two quotations, but the stack before it is .. Int Int Int Int [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: Int
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 20, column 3
message: `main` declares that it leaves ρ Bool but its body leaves ρ Seq Int Int Int.
expected: ρ Bool
actual: ρ Seq Int Int Int
hint: The body leaves 2 extra values on top (Int Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0;

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Int but its body leaves ρ Seq Int Int.
expected: ρ Int
actual: ρ Seq Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

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
    xs prim seq-int.len i prim >=
    [
      j prim seq-int.len j prim <
      [ result ys j prim seq-int.at prim seq-int.push j 1 prim + ys swap merge-loop ] [ result ] if
    ]
    [
      ys prim seq-int.len j prim >=
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs swap merge-loop ]
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <=
        [ result xs i prim seq-int.at prim seq-int.push i 1 prim + ] 
        [ result ys j prim seq-int.at prim seq-int.push j 1 prim + ]
        if
        locals { new-one new-idx } {
          xs ys new-idx new-idx result merge-loop
        }
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  0;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 7, column 98
message: The two branches of `if` in `merge-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 29, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int Int.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int Int
hint: The body leaves 2 extra values on top (Seq Int Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

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
      result swap prim seq-int.push
      n 10 prim div
      locals { new-n new-result } {
        new-n new-result digits-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ 0 prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digits-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digits-loop
at: line 11, column 26
message: `digits-loop` in `digits-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `new-n` (Seq Int) and `new-result` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `new-result new-n` in place of `new-n new-result` on line 11. With that edit `digits-loop` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 23, column 5
message: The two branches of the `if` in `main` whose true branch is `[ 0 prim seq-int.empty 0 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `0` and the result of `prim seq-int.push`; the false branch leaves the result of `digits-loop`. `main` calls `digits-loop`, which has an error of its own; this report assumes `digits-loop` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: `0` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty;

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Int Seq Int.
expected: ρ Seq Int
actual: ρ Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty;

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Int Seq Int.
expected: ρ Seq Int
actual: ρ Seq Int Int Seq Int
hint: The body leaves 2 extra values on top (Int Seq Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  start 0;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 3
message: `start` is not a defined word, primitive or local.
actual: start
hint: `start` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty;

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int
hint: The body leaves 4 extra values on top (Seq Bool Seq Int Seq Int Seq Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.
