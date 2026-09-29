Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many s:Int^many -- ρ result:Int^many)
  locals { xs i s } {
    xs prim seq-int.len i prim < [
      s xs i prim seq-int.at prim +
      i 1 prim + xs swap
      sum-acc
    ] [
      s
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-acc;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-acc
at: line 7, column 7
message: `sum-acc` in `sum-acc` takes xs:Seq Int, i:Int, s:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `sum-acc` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `s xs i prim seq-int.at prim +` and `i 1 prim +` are for `i` and `s`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many m:Int^many -- ρ result:Int^many)
  locals { xs i m } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at m prim < [ xs i prim seq-int.at ] [ m ] if
      i 1 prim + xs swap
      max-acc
    ] [
      m
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs
    max-acc
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: max-acc
at: line 7, column 7
message: `max-acc` in `max-acc` takes xs:Seq Int, i:Int, m:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `max-acc` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at m prim < [ xs i prim seq-int.at ] [ m ] if` and `i 1 prim +` are for `i` and `m`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 5
message: `max-acc` in `main` takes xs:Seq Int, i:Int, m:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `1` (Int) and `xs` (Seq Int). `main` calls `max-acc`, which has an error of its own; this report assumes `max-acc` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: These are the values `max-acc` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `m`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many c:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs i c k } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at k prim < [ c 1 prim + ] [ c ] if
      i 1 prim + xs swap k swap
      count-acc
    ] [
      c
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs 0 0 k count-acc
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: count-acc
at: line 7, column 7
message: `count-acc` in `count-acc` takes xs:Seq Int, i:Int, c:Int, k:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: These are the values `count-acc` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ c 1 prim + ] [ c ] if` and `i 1 prim +` are for `i` and `c`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs i x } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at x prim = [
        i
      ] [
        i 1 prim + xs swap x swap
        find-acc
      ] if
    ] [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs 0 x find-acc
  };

```
On the example, it returned [-1] instead of [1]

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i r } {
    i 0 prim < [
      xs i prim seq-int.at r prim seq-int.push
      i -1 prim + xs swap r swap
      reverse-loop
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - prim seq-int.empty xs
    reverse-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 10, column 7
message: The two branches of the `if` in `reverse-loop` whose true branch is `[ xs i prim seq-int.at r prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-loop`; the false branch leaves `r`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `reverse-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 5
message: `reverse-loop` in `main` takes xs:Seq Int, i:Int, r:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), the result of `prim seq-int.empty` (Seq Int) and `xs` (Seq Int). `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int Seq Int
hint: These are the values `reverse-loop` takes, in another order. To push them in its order, write `xs xs prim seq-int.len 1 prim - prim seq-int.empty` in place of `xs prim seq-int.len 1 prim - prim seq-int.empty xs`. With that edit `main` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many s:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i s r } {
    xs prim seq-int.len i prim < [
      s xs i prim seq-int.at prim +
      r swap prim seq-int.push
      i 1 prim + xs swap swap
      prefix-acc
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-acc
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-acc
at: line 11, column 7
message: In the true branch `[ s xs i prim seq-int.at prim + ...` of the `if` in `prefix-acc`, `prefix-acc` needs 4 values (xs:Seq Int, i:Int, s:Int, r:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-acc`, exactly the values it takes, in this order: xs:Seq Int, i:Int, s:Int, r:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-acc` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-acc
  (forall ρ; ρ xs:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i r } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at dup 0 prim < prim not [
        r swap prim seq-int.push
      ] [
        drop r
      ] if
      i 1 prim +
      filter-acc
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-acc
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-acc
at: line 14, column 7
message: In the true branch `[ xs i prim seq-int.at dup 0 prim ...` of the `if` in `filter-acc`, `filter-acc` needs 3 values (xs:Seq Int, i:Int, r:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-acc`, exactly the values it takes, in this order: xs:Seq Int, i:Int, r:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (r:Seq Int) after them, for example by writing the locals that hold it. If `filter-acc` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-acc
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many s:Int^many -- ρ result:Int^many)
  locals { xs ys i s } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at ys i prim seq-int.at prim * s prim +
      i 1 prim + xs swap ys swap swap
      dot-acc
    ] [
      s
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-acc
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-acc
at: line 7, column 7
message: `dot-acc` in `dot-acc` takes xs:Seq Int, ys:Seq Int, i:Int, s:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), the result of `prim +` (Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Int Seq Int
hint: These are the values `dot-acc` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * s prim +` and `i 1 prim +` are for `i` and `s`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    flags prim seq-bool.len i prim < [
      flags i prim seq-bool.at prim not [
        false
      ] [
        i 1 prim + flags swap
        check-all
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-bool.len 0 prim = [
      true
    ] [
      flags 0
      check-all
    ] if
  };

```
On the example, it returned [True] instead of [False]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cur:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i cur max } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim = [
        cur 1 prim + i 1 prim + xs swap swap
        run-loop
      ] [
        cur max prim < [ max ] [ cur ] if
        1 i 1 prim +
        xs swap swap
        run-loop
      ] if
    ] [
      cur max prim < [ max ] [ cur ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 0 1 0
      run-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 13, column 9
message: In the true branch `[ cur 1 prim + i 1 prim ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, i:Int, cur:Int, max:Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, cur:Int, max:Int. The branch already pushes the result of `prim +`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ j:Int^many xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs i target } {
    xs prim seq-int.len j prim < [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [
        true
      ] [
        j 1 prim +
        inner-loop xs i target
      ] if
    ] [
      false
    ] if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs i target } {
    xs prim seq-int.len i prim < [
      i 1 prim + xs i target inner-loop [
        true
      ] [
        i 1 prim +
        outer-loop xs swap target swap
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs 0 target outer-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: inner-loop
at: line 13, column 7
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 2 of 2
code: firth.type.stack-underflow
word: outer-loop
at: line 28, column 7
message: `if` needs more values than the stack holds here. `outer-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-seen
  (forall ρ; ρ v:Int^many xs:Seq Int^many start:Int^many -- ρ result:Bool^many)
  locals { v xs start } {
    xs prim seq-int.len start prim < [
      xs start prim seq-int.at v prim = [
        true
      ] [
        start 1 prim +
        check-seen v xs swap
      ] if
    ] [
      false
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs i } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at 0 check-seen xs i [
        1 prim +
      ] [
      ] if
      i 1 prim +
      count-loop
    ] [
      0
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0
    count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: check-seen
at: line 13, column 7
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: count-loop
at: line 20, column 30
message: The quotation run by `dip` in `count-loop` does not accept the stack below it (.. Int Seq Int Int Int Int [ .. Int Seq Int Seq Int Int -- .. Bool Seq Int ]). `count-loop` calls `check-seen`, which has an error of its own; this report assumes `check-seen` keeps its stack effect.
expected: Seq Int
actual: Int
hint: Check what the quotation body consumes against the values available under it.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j r } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [
      xs i prim seq-int.at ys j prim seq-int.at prim < [
        r xs i prim seq-int.at prim seq-int.push
        i 1 prim + xs swap ys swap j swap
        merge-loop
      ] [
        r ys j prim seq-int.at prim seq-int.push
        xs swap ys swap i swap j 1 prim +
        merge-loop
      ] if
    ] [
      i xs prim seq-int.len prim < [
        r xs i prim seq-int.at prim seq-int.push
        i 1 prim + xs swap ys swap j swap
        merge-loop
      ] [
        j ys prim seq-int.len prim < [
          r ys j prim seq-int.at prim seq-int.push
          xs swap ys swap i swap j 1 prim +
          merge-loop
        ] [
          r
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-loop
at: line 8, column 9
message: `merge-loop` in `merge-loop` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, r:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), `j` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int ?t111 ?t110 Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys i 1 prim + j r xs i prim seq-int.at prim seq-int.push` in place of `r xs i prim seq-int.at prim seq-int.push i 1 prim + xs swap ys swap j swap`. With that edit, the next error in `merge-loop` is at line 10, column 9.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { n r } {
    n 0 prim = [
      r
    ] [
      r n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ] if
  };

: reverse-digits
  (forall ρ; ρ d:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { d i r } {
    i 0 prim < [
      d i prim seq-int.at r prim seq-int.push
      i -1 prim +
      d swap r swap
      reverse-digits
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty digits-loop
      dup prim seq-int.len 1 prim -
      prim seq-int.empty
      reverse-digits
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digits-loop
at: line 9, column 7
message: `digits-loop` in `digits-loop` takes n:Int, r:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `n 10 prim div r n 10 prim mod prim seq-int.push` in place of `r n 10 prim mod prim seq-int.push n 10 prim div`. With that edit `digits-loop` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-digits
at: line 23, column 7
message: The two branches of the `if` in `reverse-digits` whose true branch is `[ d i prim seq-int.at r prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-digits`; the false branch leaves `r`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `reverse-digits`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    n 2 prim < [
      false
    ] [
      d d prim * n prim < [
        n d prim mod 0 prim = [
          false
        ] [
          d 1 prim +
          n swap
          is-prime
        ] if
      ] [
        true
      ] if
    ] if
  };

: collect-primes
  (forall ρ; ρ n:Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i r } {
    i n prim < [
      i 2 is-prime [
        r i prim seq-int.push
      ] [
        r
      ] if
      i 1 prim +
      n swap
      collect-primes
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty collect-primes
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: collect-primes
at: line 32, column 7
message: `collect-primes` in `collect-primes` takes n:Int, i:Int, r:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), `n` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t23 Int
hint: These are the values `collect-primes` takes, in another order. To push them in its order, write `n i 1 prim + i 2 is-prime [ r i prim seq-int.push ] [ r ] if` in place of `i 2 is-prime [ r i prim seq-int.push ] [ r ] if i 1 prim + n swap`. With that edit `collect-primes` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ k:Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i r } {
    i k prim < [
      r 0 prim seq-int.push
      i 1 prim +
      k swap
      init-counts
    ] [
      r
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i counts } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts swap prim seq-int.set
      i 1 prim +
      xs swap swap
      count-loop
    ] [
      counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-counts
    xs 0 swap count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: init-counts
at: line 8, column 7
message: `init-counts` in `init-counts` takes k:Int, i:Int, r:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t23 Int
hint: These are the values `init-counts` takes, in another order. To push them in its order, write `k i 1 prim + r 0 prim seq-int.push` in place of `r 0 prim seq-int.push i 1 prim + k swap`. With that edit `init-counts` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: count-loop
at: line 18, column 81
message: `prim seq-int.set` in `count-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `counts` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Seq Int Int
hint: The second value from the top, `counts` (Seq Int), is not what `prim seq-int.set` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-at
  (forall ρ; ρ r:Seq Int^many v:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { r v i } {
    r v prim seq-int.push i r prim seq-int.len 1 prim - shift-loop r
  };

: shift-loop
  (forall ρ; ρ i:Int^many r:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { i r len } {
    i len prim < [
      r i prim seq-int.at r i 1 prim - prim seq-int.set
      i 1 prim +
      r swap
      shift-loop
    ] [
      r
    ] if
  };

: insert-sorted
  (forall ρ; ρ v:Int^many r:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { v r i } {
    i r prim seq-int.len prim < [
      r i prim seq-int.at v prim < [
        r v i insert-at
      ] [
        i 1 prim +
        v swap r swap
        insert-sorted
      ] if
    ] [
      r v prim seq-int.push
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many r:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i r } {
    xs prim seq-int.len i prim < [
      xs i prim seq-int.at r 0 insert-sorted
      i 1 prim +
      xs swap swap
      sort-loop
    ] [
      r
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: insert-at
at: line 4, column 57
message: `shift-loop` in `insert-at` takes i:Int, r:Seq Int, len:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `i` (Int) and the result of `prim -` (Int). `insert-at` calls `shift-loop`, which has an error of its own; this report assumes `shift-loop` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Seq Int Seq Int Int Int
hint: The second value from the top, `i` (Int), is not what `shift-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: shift-loop
at: line 11, column 40
message: `prim seq-int.set` in `shift-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `r` (Seq Int) and the result of `prim -` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `r` is for `Seq Int`. Of the values of one type, `r i prim seq-int.at` and `i 1 prim -` are for `Int` and `Int`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many bal:Int^many rej:Int^many -- ρ result1:Int^many result2:Int^many)
  locals { txs i bal rej } {
    txs prim seq-int.len i prim < [
      bal txs i prim seq-int.at prim + dup 0 prim < [
        drop bal rej 1 prim + txs swap i swap
        ledger-loop
      ] [
        i 1 prim + txs swap rej swap
        ledger-loop
      ] if
    ] [
      bal rej
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs 0 start 0 ledger-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ledger-loop
at: line 7, column 9
message: `ledger-loop` in `ledger-loop` takes txs:Seq Int, i:Int, bal:Int, rej:Int, bottom to top, but here it gets, bottom to top, `bal` (Int), `txs` (Seq Int), `i` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: These are the values `ledger-loop` takes, in another order. To push them in its order, write `txs i bal rej 1 prim +` in place of `bal rej 1 prim + txs swap i swap`. With that edit, the next error in `ledger-loop` is at line 9, column 9.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many alloc:Seq Int^many reasons:Seq Int^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons_out:Seq Int^many)
  locals { stock items qtys whole i alloc reasons } {
    items prim seq-int.len i prim < [
      items i prim seq-int.at stock swap prim seq-int.at
      locals { item_idx current_stock } {
        current_stock qtys i prim seq-int.at prim < prim not [
          alloc qtys i prim seq-int.at prim seq-int.push
          reasons 0 prim seq-int.push
          stock item_idx qtys i prim seq-int.at prim seq-int.set drop
          i 1 prim + stock swap items swap qtys swap whole swap alloc swap reasons swap
          allocate-loop
        ] [
          current_stock 0 prim = [
            alloc 0 prim seq-int.push
            reasons 2 prim seq-int.push
            i 1 prim + stock swap items swap qtys swap whole swap alloc swap reasons swap
            allocate-loop
          ] [
            whole i prim seq-bool.at [
              alloc 0 prim seq-int.push
              reasons 3 prim seq-int.push
              i 1 prim + stock swap items swap qtys swap whole swap alloc swap reasons swap
              allocate-loop
            ] [
              alloc current_stock prim seq-int.push
              reasons 1 prim seq-int.push
              stock item_idx 0 prim seq-int.set drop
              i 1 prim + stock swap items swap qtys swap whole swap alloc swap reasons swap
              allocate-loop
            ] if
          ] if
        ] if
      }
    ] [
      stock alloc reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 153
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
