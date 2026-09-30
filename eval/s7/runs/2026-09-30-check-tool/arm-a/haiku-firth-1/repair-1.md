Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i acc len } {
    [ i len prim < ] [
      acc xs i prim seq-int.at prim + xs i 1 prim + len sum-loop
    ] [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { xs 0 0 xs prim seq-int.len sum-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-loop
at: line 5, column 57
message: `sum-loop` in `sum-loop` takes xs:Seq Int, i:Int, acc:Int, len:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), the result of `prim +` (Int) and `len` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int ?t42
hint: These are the values `sum-loop` takes, in another order. By their names and types, `xs` is for `xs` and `len` is for `len`. Of the values of one type, `acc xs i prim seq-int.at prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many mx:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i mx len } {
    [ i len prim < ] [
      xs i prim seq-int.at mx prim <
      [
        xs i 1 prim + xs i prim seq-int.at len max-loop
      ] [
        xs i 1 prim + mx len max-loop
      ] if
    ] [
      mx
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at xs prim seq-int.len max-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: max-loop
at: line 13, column 7
message: `if` in `max-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many count:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i k count len } {
    [ i len prim < ] [
      xs i prim seq-int.at k prim <
      [
        xs i 1 prim + k count 1 prim + len count-loop
      ] [
        xs i 1 prim + k count len count-loop
      ] if
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs 0 k 0 xs prim seq-int.len count-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: count-loop
at: line 13, column 7
message: `if` in `count-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
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
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs x i len } {
    [ i len prim < ] [
      xs i prim seq-int.at x prim =
      [
        i
      ] [
        xs x i 1 prim + len index-loop
      ] if
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x 0 xs prim seq-int.len index-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: index-loop
at: line 13, column 7
message: `if` in `index-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i 0 prim < ] [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.push xs i 1 prim - reverse-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: reverse-loop
at: line 7, column 67
message: `reverse-loop` in `reverse-loop` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim -` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `reverse-loop` takes, in another order. To push them in its order, write `xs i 1 prim - result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs i 1 prim -` on line 7. With that edit, the next error in `reverse-loop` is at line 8, column 7.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  [ i xs prim seq-int.len prim < ] [
    sum xs i prim seq-int.at prim + dup locals { new-sum } {
      result new-sum prim seq-int.push locals { new-result } {
        xs i 1 prim + new-sum new-result prefix-helper
      }
    }
  ] [
    result
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-helper };

```
On the example, the run failed:
code: firth.name.unresolved
word: prefix-helper
at: line 3, column 5
message: `i` is not a defined word, primitive or local.
actual: i
hint: `i` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs i sum result } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at 0 prim <
      [
        result xs i prim seq-int.at prim seq-int.push xs i 1 prim + keep-loop
      ] [
        xs i 1 prim + result keep-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: keep-loop
at: line 7, column 69
message: `keep-loop` in `keep-loop` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `keep-loop` takes, in another order. To push them in its order, write `xs i 1 prim + result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs i 1 prim +` on line 7. With that edit, the next error in `keep-loop` is at line 13, column 7.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ sorted:Bool^many)
  locals { xs i len } {
    [ i len 1 prim - prim < ] [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ] [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
        [ xs i 1 prim + is-sorted-loop ] [ false ] if
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 xs prim seq-int.len is-sorted-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-sorted-loop
at: line 8, column 52
message: In the true branch `[ xs i 1 prim + is-sorted-loop ]` of the `if` in `is-sorted-loop`, `is-sorted-loop` needs 3 values (xs:Seq Int, i:Int, len:Int), but the branch has pushed only 2 values before it (`xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, len:Int. The branch already pushes `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    [ i xs prim seq-int.len prim < ] [
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim + xs ys i 1 prim + dot-loop
    ] [
      sum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-loop
at: line 5, column 84
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    [ i flags prim seq-bool.len prim < ] [
      flags i prim seq-bool.at
      [ flags i 1 prim + all-true-loop ] [ false ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-true-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: all-true-loop
at: line 9, column 7
message: `if` in `all-true-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
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
: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-run max-run } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at current-val prim =
      [
        xs i 1 prim + xs i prim seq-int.at current-run 1 prim + max-run longest-loop
      ] [
        current-run max-run prim <
        [ xs i 1 prim + xs i prim seq-int.at 1 current-run longest-loop ] [
          xs i 1 prim + xs i prim seq-int.at 1 max-run longest-loop
        ] if
      ] if
    ] [
      current-run max-run prim < [ max-run ] [ current-run ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    [ xs prim seq-int.len 0 prim = ] [ 0 ] [
      xs 1 xs 0 prim seq-int.at 1 0 longest-loop
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: longest-loop
at: line 16, column 7
message: `if` in `longest-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.expected-bool
word: main
at: line 24, column 7
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ]. `main` calls `longest-loop`, which has an error of its own; this report assumes `longest-loop` keeps its stack effect.
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
  (forall ρ; ρ xs:Seq Int^many complement:Int^many j:Int^many len:Int^many -- ρ found:Bool^many)
  locals { xs complement j len } {
    [ j len prim < ] [
      xs j prim seq-int.at complement prim =
      [ true ] [ xs complement j 1 prim + len inner-loop ] if
    ] [
      false
    ] if
  };

: pair-sum-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at target prim - xs i 1 prim + xs prim seq-int.len inner-loop
      [ true ] [
        xs target i 1 prim + pair-sum-loop
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pair-sum-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: inner-loop
at: line 9, column 7
message: `if` in `inner-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.word-input-mismatch
word: pair-sum-loop
at: line 16, column 76
message: `inner-loop` in `pair-sum-loop` takes xs:Seq Int, complement:Int, j:Int, len:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `xs` (Seq Int), the result of `prim +` (Int) and the result of `prim seq-int.len` (Int). `pair-sum-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: .. Seq Int Int Int Int Seq Int Int Int
hint: These are the values `inner-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at target prim -`, `i 1 prim +` and `xs prim seq-int.len` are for `complement`, `j` and `len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: seen-check
  (forall ρ; ρ xs:Seq Int^many val:Int^many j:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs val j i } {
    [ j i prim < ] [
      xs j prim seq-int.at val prim =
      [ true ] [ xs val j 1 prim + i seen-check ] if
    ] [
      false
    ] if
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    [ i xs prim seq-int.len prim < ] [
      xs xs i prim seq-int.at 0 i seen-check
      [ xs i 1 prim + count count-distinct-loop ] [
        xs i 1 prim + count 1 prim + count-distinct-loop
      ] if
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 count-distinct-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: seen-check
at: line 9, column 7
message: `if` in `seen-check` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.expected-bool
word: count-distinct-loop
at: line 22, column 7
message: `if` in `count-distinct-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    [ i xs prim seq-int.len prim < ] [
      [ j ys prim seq-int.len prim < ] [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [
          result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
        ] if
      ] [
        result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
      ] if
    ] [
      [ j ys prim seq-int.len prim < ] [
        result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-loop
at: line 8, column 76
message: `merge-loop` in `merge-loop` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), the result of `prim +` (Int) and `j` (Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int Seq Int Int Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j` on line 8. With that edit, the next error in `merge-loop` is at line 10, column 76.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i 0 prim < ] [
      result
    ] [
      result xs i prim seq-int.at prim seq-int.push xs i 1 prim - reverse-loop
    ] if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    [ n 0 prim = ] [
      result
    ] [
      result n 10 prim mod prim seq-int.push n 10 prim div digits-loop
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    [ n 0 prim = ] [
      { 0 }
    ] [
      n prim seq-int.empty digits-loop locals { temp } {
        temp temp prim seq-int.len 1 prim - reverse-loop
      }
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: reverse-loop
at: line 7, column 67
message: `reverse-loop` in `reverse-loop` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim -` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `reverse-loop` takes, in another order. To push them in its order, write `xs i 1 prim - result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs i 1 prim -` on line 7. With that edit, the next error in `reverse-loop` is at line 8, column 7.

error 2 of 3
code: firth.type.word-input-mismatch
word: digits-loop
at: line 17, column 60
message: `digits-loop` in `digits-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div` on line 17. With that edit, the next error in `digits-loop` is at line 18, column 7.

error 3 of 3
code: firth.type.branch-mismatch
word: main
at: line 30, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ { 0 } ]`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (`temp` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `digits-loop` and `reverse-loop`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes `temp` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    [ d d prim * n prim < ] [
      n d prim mod 0 prim =
      [ false ] [ n d 1 prim + is-prime-loop ] if
    ] [
      true
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    [ n 2 prim < ] [ false ] [ n 2 is-prime-loop ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    [ i n prim < ] [
      i is-prime
      [
        result i prim seq-int.push n i 1 prim + primes-loop
      ] [
        n i 1 prim + result primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-loop };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.expected-bool
word: is-prime-loop
at: line 9, column 7
message: `if` in `is-prime-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 3
code: firth.type.expected-bool
word: is-prime
at: line 15, column 52
message: `if` in `is-prime` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ]. `is-prime` calls `is-prime-loop`, which has an error of its own; this report assumes `is-prime-loop` keeps its stack effect.
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 3
code: firth.type.word-input-mismatch
word: primes-loop
at: line 24, column 49
message: `primes-loop` in `primes-loop` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `n` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t54 Int
hint: These are the values `primes-loop` takes, in another order. To push them in its order, write `n i 1 prim + result i prim seq-int.push` in place of `result i prim seq-int.push n i 1 prim +` on line 24. With that edit, the next error in `primes-loop` is at line 30, column 7. That edit was checked assuming `is-prime`, which has an error of its own, keeps its stack effect.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: build-zeros
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i result } {
    [ i k prim < ] [
      result 0 prim seq-int.push k i 1 prim + build-zeros
    ] [
      result
    ] if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i counts } {
    [ i xs prim seq-int.len prim < ] [
      xs i prim seq-int.at locals { val } {
        counts val prim seq-int.at 1 prim + locals { new-count } {
          counts val new-count prim seq-int.set xs i 1 prim + histogram-loop
        }
      }
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { k 0 prim seq-int.empty build-zeros locals { counts } { xs 0 counts histogram-loop } };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: build-zeros
at: line 5, column 47
message: `build-zeros` in `build-zeros` takes k:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t35 Int
hint: These are the values `build-zeros` takes, in another order. To push them in its order, write `k i 1 prim + result 0 prim seq-int.push` in place of `result 0 prim seq-int.push k i 1 prim +` on line 5. With that edit, the next error in `build-zeros` is at line 8, column 7.

error 2 of 2
code: firth.type.word-input-mismatch
word: histogram-loop
at: line 17, column 63
message: `histogram-loop` in `histogram-loop` takes xs:Seq Int, i:Int, counts:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Int Seq Int Int Seq Int Seq Int Int
hint: These are the values `histogram-loop` takes, in another order. To push them in its order, write `xs i 1 prim + counts val new-count prim seq-int.set` in place of `counts val new-count prim seq-int.set xs i 1 prim +` on line 17. With that edit, the next error in `histogram-loop` is at line 22, column 7.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int^many i:Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { sorted i val } {
    [ i 0 prim < ] [
      sorted val prim seq-int.push
    ] [
      sorted i prim seq-int.at val prim <
      [
        sorted i prim seq-int.at prim seq-int.push sorted i 1 prim - val insert-sorted
      ] [
        sorted val prim seq-int.push
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim < ] [
      result result prim seq-int.len 1 prim - xs i prim seq-int.at insert-sorted xs i 1 prim + sort-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: insert-sorted
at: line 9, column 34
message: `prim seq-int.push` in `insert-sorted` takes 2 values (the sequence (Seq Int) and the value pushed (Int)), bottom to top, but only 1 value is on the stack before it: the result of `prim seq-int.at` (Int).
hint: Push the missing value before `prim seq-int.push`. The locals here, `sorted`, `i` and `val`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.word-input-mismatch
word: sort-loop
at: line 20, column 96
message: `sort-loop` in `sort-loop` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `insert-sorted` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int). `sort-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `sort-loop` takes, in another order. To push them in its order, write `xs i 1 prim + result result prim seq-int.len 1 prim - xs i prim seq-int.at insert-sorted` in place of `result result prim seq-int.len 1 prim - xs i prim seq-int.at insert-sorted xs i 1 prim +` on line 20. With that edit, the next error in `sort-loop` is at line 23, column 7.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ final-balance:Int^many rejected:Int^many)
  locals { txs i balance rejected } {
    [ i txs prim seq-int.len prim < ] [
      balance txs i prim seq-int.at prim + 0 prim <
      [
        txs i 1 prim + balance rejected 1 prim + ledger-loop
      ] [
        txs i 1 prim + balance txs i prim seq-int.at prim + rejected ledger-loop
      ] if
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many rejected:Int^many)
  locals { start txs } { txs 0 start 0 ledger-loop };

```
On the example, the run failed:
code: firth.type.expected-bool
word: ledger-loop
at: line 13, column 7
message: `if` in `ledger-loop` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Int Int ] [ .. -- .. Int Int ].
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
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    [ i qtys prim seq-int.len prim < ] [
      items i prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { available } {
          qtys i prim seq-int.at available prim <
          [
            available 0 prim =
            [
              stock allocated reasons 0 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
            ] [
              whole i prim seq-bool.at
              [
                stock allocated reasons 3 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
              ] [
                stock item available prim seq-int.set allocated qtys i prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
              ] if
            ] if
          ] [
            qtys i prim seq-int.at available prim =
            [
              stock item 0 prim seq-int.set allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
            ] [
              stock item available prim seq-int.set allocated available prim seq-int.push reasons 1 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
            ] if
          ] if
        }
      }
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 32, column 7
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ items i prim seq-int.at locals { item ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: the result of an `if`, the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`; the false branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`.
hint: The true branch leaves 1 value more than the false branch: the result of an `if` is left below the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
