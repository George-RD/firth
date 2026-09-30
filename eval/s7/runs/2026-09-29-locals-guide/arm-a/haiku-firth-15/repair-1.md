Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at acc prim +
      i 1 prim +
      xs swap swap sum-loop
    ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-loop
at: line 12, column 20
message: `sum-loop` in `sum-loop` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at acc prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at max-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { xs i max-val elem } {
        elem max-val prim <
        [ max-val ]
        [ elem ]
        if
        i 1 prim +
        xs swap swap max-loop
      }
    ]
    [ max-val ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 21, column 5
message: In the true branch `[ xs i prim seq-int.at locals { xs ...` of the `if` in `max-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs 0 0 k count-loop };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs i cnt k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { xs i cnt k elem } {
        elem k prim <
        [ cnt 1 prim + ]
        [ cnt ]
        if
        i 1 prim +
        xs swap swap k count-loop
      }
    ]
    [ cnt ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 21, column 5
message: In the true branch `[ xs i prim seq-int.at locals { xs ...` of the `if` in `count-loop`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { xs 0 x index-loop };

: index-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs i x } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { xs i x elem } {
        elem x prim =
        [ i ]
        [
          i 1 prim +
          xs swap swap x index-loop
        ]
        if
      }
    ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: index-loop
at: line 22, column 5
message: In the true branch `[ xs i prim seq-int.at locals { xs ...` of the `if` in `index-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { result xs i elem } {
        result elem prim seq-int.push
        i 1 prim +
        xs swap swap reverse-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 18, column 5
message: In the true branch `[ xs i prim seq-int.at locals { result ...` of the `if` in `reverse-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Seq Int^many)
  locals { result xs i sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      locals { result xs i new-sum } {
        result new-sum prim seq-int.push
        i 1 prim +
        xs swap swap new-sum prefix-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 18, column 5
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { result xs i elem } {
        elem 0 prim <
        [ result ]
        [ result elem prim seq-int.push ]
        if
        i 1 prim +
        xs swap swap keep-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: keep-loop
at: line 21, column 5
message: In the true branch `[ xs i prim seq-int.at locals { result ...` of the `if` in `keep-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs 0 sorted-loop };

: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      locals { xs i curr next } {
        curr next prim < prim not
        [
          i 1 prim +
          xs swap sorted-loop
        ]
        [ false ]
        if
      }
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sorted-loop
at: line 23, column 5
message: In the true branch `[ xs i prim seq-int.at xs i 1 ...` of the `if` in `sorted-loop`, `locals` needs 4 values, but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim seq-int.at`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      acc prim +
      i 1 prim +
      xs ys swap swap dot-loop
    ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-loop
at: line 15, column 23
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * acc prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 1 longest-loop };

: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-len:Int^many run-len:Int^many -- ρ result:Int^many)
  locals { xs i max-len run-len } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      locals { xs i max-len run-len curr next } {
        curr next prim =
        [
          run-len 1 prim +
          locals { xs i max-len new-run } {
            new-run max-len prim <
            [ new-run ]
            [ max-len ]
            if
            i 1 prim +
            xs swap swap swap longest-loop
          }
        ]
        [
          run-len max-len prim <
          [ run-len ]
          [ max-len ]
          if
          i 1 prim +
          xs swap swap 1 longest-loop
        ]
        if
      }
    ]
    [ run-len max-len prim < [ run-len ] [ max-len ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: longest-loop
at: line 33, column 9
message: In the true branch `[ run-len 1 prim + locals { xs ...` of the `if` in `longest-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs 0 target find-pair };

: find-pair
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs i target } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { xs i target xi } {
        target xi prim -
        xs swap 0 find-match
      }
    ]
    [ false ]
    if
  };

: find-match
  (forall ρ; ρ xs:Seq Int^many needed:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs needed j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      locals { xs needed j elem } {
        elem needed prim =
        [ true ]
        [
          j 1 prim +
          xs swap needed find-match
        ]
        if
      }
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-pair
at: line 17, column 5
message: In the true branch `[ xs i prim seq-int.at locals { xs ...` of the `if` in `find-pair`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `find-pair` calls `find-match`, which has an error of its own; this report assumes `find-match` keeps its stack effect.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: find-match
at: line 37, column 5
message: In the true branch `[ xs j prim seq-int.at locals { xs ...` of the `if` in `find-match`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs i cnt } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { xs i cnt elem } {
        xs elem 0 is-already-seen
        [
          i 1 prim +
          xs swap cnt distinct-loop
        ]
        [
          cnt 1 prim +
          i 1 prim +
          xs swap swap distinct-loop
        ]
        if
      }
    ]
    [ cnt ]
    if
  };

: is-already-seen
  (forall ρ; ρ xs:Seq Int^many elem:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs elem j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      locals { xs elem j x } {
        x elem prim =
        [ true ]
        [
          j 1 prim +
          xs swap elem is-already-seen
        ]
        if
      }
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: distinct-loop
at: line 26, column 5
message: In the true branch `[ xs i prim seq-int.at locals { xs ...` of the `if` in `distinct-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `distinct-loop` calls `is-already-seen`, which has an error of its own; this report assumes `is-already-seen` keeps its stack effect.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: is-already-seen
at: line 46, column 5
message: In the true branch `[ xs j prim seq-int.at locals { xs ...` of the `if` in `is-already-seen`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        locals { result xs ys i j xi yj } {
          xi yj prim <
          [
            result xi prim seq-int.push
            i 1 prim +
            xs ys swap swap j merge-loop
          ]
          [
            result yj prim seq-int.push
            j 1 prim +
            xs ys swap i swap merge-loop
          ]
          if
        }
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        xs ys swap j merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        j 1 prim +
        xs ys result i swap merge-loop
      ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 34, column 7
message: In the true branch `[ xs i prim seq-int.at ys j prim ...` of the `if` in `merge-loop`, `locals` needs 7 values, but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim seq-int.at`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { n collect-digits prim seq-int.empty reverse-digits };

: collect-digits
  (forall ρ; ρ n:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { n xs } {
    n 0 prim =
    [
      xs prim seq-int.len 0 prim =
      [ prim seq-int.empty 0 prim seq-int.push ]
      [ xs ]
      if
    ]
    [
      n 10 prim mod
      xs swap prim seq-int.push
      n 10 prim div
      swap collect-digits
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs result } {
    xs prim seq-int.len 0 prim =
    [ result ]
    [
      xs 0 prim seq-int.at
      result swap prim seq-int.push
      xs 1 xs prim seq-int.len prim seq-int.at prim seq-int.set
      swap reverse-digits
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 20
message: `collect-digits` in `main` needs Int Seq Int on top of the stack, but the stack before it is ρ Int.
expected: .. Int Seq Int
actual: ρ Int
hint: `collect-digits` takes 2 values but only 1 value is available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-digits
at: line 35, column 5
message: The two branches of `if` in `reverse-digits` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n sieve-loop };

: sieve-loop
  (forall ρ; ρ primes:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { primes i n } {
    i n prim < prim not
    [ primes ]
    [
      primes i is-prime
      [
        primes i prim seq-int.push
        i 1 prim +
        swap n sieve-loop
      ]
      [
        i 1 prim +
        primes swap n sieve-loop
      ]
      if
    ]
    if
  };

: is-prime
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { primes candidate } { 0 primes candidate check-divisor };

: check-divisor
  (forall ρ; ρ j:Int^many primes:Seq Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { j primes candidate } {
    j primes prim seq-int.len prim <
    [
      primes j prim seq-int.at
      locals { j primes candidate div } {
        div div prim * candidate prim <
        [
          candidate div prim mod 0 prim =
          [ false ]
          [
            j 1 prim +
            primes swap candidate check-divisor
          ]
          if
        ]
        [ true ]
        if
      }
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: sieve-loop
at: line 15, column 16
message: `sieve-loop` in `sieve-loop` takes primes:Seq Int, i:Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int) and `n` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int ?t56
hint: These are the values `sieve-loop` takes, in another order. To push them in its order, write `primes i prim seq-int.push i 1 prim + n` in place of `primes i prim seq-int.push i 1 prim + swap n`. With that edit `sieve-loop` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: check-divisor
at: line 52, column 5
message: In the true branch `[ primes j prim seq-int.at locals { j ...` of the `if` in `check-divisor`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty k init-histogram xs 0 histogram-loop };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result k } {
    k 0 prim =
    [ result ]
    [
      result 0 prim seq-int.push
      k 1 prim -
      swap init-histogram
    ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { result xs i val } {
        result val prim seq-int.at 1 prim + prim seq-int.set
        i 1 prim +
        xs swap result histogram-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: init-histogram
at: line 13, column 12
message: `init-histogram` in `init-histogram` takes result:Seq Int, k:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int) and the result of `prim seq-int.push` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `init-histogram` takes, in another order. To push them in its order, write `result 0 prim seq-int.push k 1 prim -` in place of `result 0 prim seq-int.push k 1 prim - swap`. With that edit `init-histogram` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 31, column 5
message: In the true branch `[ xs i prim seq-int.at locals { result ...` of the `if` in `histogram-loop`, `locals` needs 4 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 sort-outer };

: sort-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i i sort-inner
    ]
    [ xs ]
    if
  };

: sort-inner
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs i j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at
      xs j 1 prim - prim seq-int.at
      locals { xs i j curr prev } {
        curr prev prim <
        [
          xs j 1 prim - curr prim seq-int.set
          xs j prev prim seq-int.set
        ]
        [ xs ]
        if
        j 1 prim +
        xs i swap sort-inner
      }
    ]
    [
      i 1 prim +
      xs swap sort-outer
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-inner
at: line 30, column 9
message: The two branches of the `if` in `sort-inner` whose true branch is `[ xs j 1 prim - curr prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `prim seq-int.set`; the false branch leaves `xs`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `prim seq-int.set`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      locals { balance txs i rejected tx } {
        balance tx prim + 0 prim <
        [
          i 1 prim +
          txs swap balance swap rejected 1 prim + ledger-loop
        ]
        [
          balance tx prim +
          i 1 prim +
          txs swap swap rejected ledger-loop
        ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 26, column 5
message: In the true branch `[ txs i prim seq-int.at locals { balance ...` of the `if` in `ledger-loop`, `locals` needs 5 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-batch-loop };

: allocate-batch-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      locals { stock allocated reasons j items qtys whole item } {
        stock item prim seq-int.at
        locals { stock allocated reasons j items qtys whole item curr-stock } {
          qtys j prim seq-int.at
          locals { stock allocated reasons j items qtys whole item curr-stock qty } {
            qty curr-stock prim <
            [
              stock item qty prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
              j 1 prim +
              swap swap items qtys whole allocate-batch-loop
            ]
            [
              curr-stock 0 prim =
              [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                j 1 prim +
                stock swap items qtys whole allocate-batch-loop
              ]
              [
                whole j prim seq-bool.at
                [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  j 1 prim +
                  stock swap items qtys whole allocate-batch-loop
                ]
                [
                  stock item 0 prim seq-int.set
                  allocated curr-stock prim seq-int.push
                  reasons 1 prim seq-int.push
                  j 1 prim +
                  swap swap items qtys whole allocate-batch-loop
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
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-batch-loop
at: line 57, column 5
message: In the true branch `[ items j prim seq-int.at locals { stock ...` of the `if` in `allocate-batch-loop`, `locals` needs 8 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 7 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.
