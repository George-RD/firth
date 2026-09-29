Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs max i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup max prim < [
        drop max
      ] [
        swap drop
      ] if
      i 1 prim +
      max-loop
    ] [
      max
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs xs 0 prim seq-int.at 1 max-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 9, column 9
message: In the false branch of the `if` in `max-loop` whose true branch is `[ drop max ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim seq-int.at` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k count i } {
    i xs prim seq-int.len prim < [
      xs k count
      xs i prim seq-int.at k prim < [
        count 1 prim +
      ] [
        count
      ] if
      i 1 prim +
      count-loop
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 15, column 7
message: The two branches of the `if` in `count-loop` whose true branch is `[ xs k count xs i prim seq-int.at ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `count-loop`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `count-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x idx i } {
    idx -1 prim = [
      i xs prim seq-int.len prim < [
        xs x idx i
        xs i prim seq-int.at x prim = [
          drop drop drop i
        ] [
          swap drop idx
          i 1 prim +
          find-loop
        ] if
      ] [
        idx
      ] if
    ] [
      idx
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs x -1 0 find-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 16, column 9
message: The two branches of the `if` in `find-loop` whose true branch is `[ xs x idx i xs i prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of an `if`; the false branch leaves `idx`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many rev:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs rev i } {
    i xs prim seq-int.len prim < [
      rev xs i prim seq-int.at prim seq-int.push
      i 1 prim +
      reverse-loop
    ] [
      rev
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 reverse-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 10, column 7
message: In the true branch `[ rev xs i prim seq-int.at prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, rev:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, rev:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many sum:Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { xs result sum i } {
    i xs prim seq-int.len prim < [
      result
      sum xs i prim seq-int.at prim +
      dup result prim seq-int.push
      i 1 prim +
      prefix-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 0 prefix-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 7, column 18
message: `prim seq-int.push` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t35 Int Int ?t35
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup 0 prim < [
        drop result
      ] [
        result prim seq-int.push
      ] if
      i 1 prim +
      filter-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs prim seq-int.empty 0 filter-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 14, column 7
message: In the true branch `[ xs i prim seq-int.at dup 0 prim ...` of the `if` in `filter-loop`, `filter-loop` needs 3 values (xs:Seq Int, result:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-loop`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, i:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `filter-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many sorted:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { xs sorted i } {
    sorted prim not [
      i xs prim seq-int.len 1 prim - prim < [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not
        i 1 prim +
        sorted-loop
      ] [
        sorted
      ] if
    ] [
      sorted
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      xs true 0 sorted-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sorted-loop
at: line 11, column 9
message: In the true branch `[ xs i prim seq-int.at xs i 1 ...` of the `if` in `sorted-loop`, `sorted-loop` needs 3 values (xs:Seq Int, sorted:Bool, i:Int), but the branch has pushed only 2 values before it (the result of `prim not` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, sorted:Bool, i:Int. The branch already pushes the result of `prim not` and the result of `prim +`, in the place of the last 2 (sorted:Bool, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many i:Int^many -- ρ product:Int^many)
  locals { xs ys sum i } {
    i xs prim seq-int.len prim < [
      sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      i 1 prim +
      dot-loop
    ] [
      sum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 10, column 7
message: In the true branch `[ sum xs i prim seq-int.at ys i ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, sum:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, sum:Int, i:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (sum:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many all:Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags all i } {
    all [
      i flags prim seq-bool.len prim < [
        all flags i prim seq-bool.at prim and
        i 1 prim +
        all-loop
      ] [
        all
      ] if
    ] [
      all
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags true 0 all-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-loop
at: line 11, column 9
message: In the true branch `[ all flags i prim seq-bool.at prim and ...` of the `if` in `all-loop`, `all-loop` needs 3 values (flags:Seq Bool, all:Bool, i:Int), but the branch has pushed only 2 values before it (the result of `prim and` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: flags:Seq Bool, all:Bool, i:Int. The branch already pushes the result of `prim and` and the result of `prim +`, in the place of the last 2 (all:Bool, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before them, for example by writing the locals that hold it. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many maxrun:Int^many current:Int^many lastval:Int^many i:Int^many -- ρ length:Int^many)
  locals { xs maxrun current lastval i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at dup lastval prim = [
        drop current 1 prim +
      ] [
        swap drop 1
      ] if
      dup maxrun prim < [
        drop maxrun
      ] [
        swap drop
      ] if
      xs i prim seq-int.at
      i 1 prim +
      run-loop
    ] [
      maxrun
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 1 1 xs 0 prim seq-int.at 1 run-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 14, column 9
message: The two branches of `if` in `run-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The condition and the values the branches take from below the `if` are looked for where the locals `i` and `xs` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target found i j } {
    found prim not [
      j xs prim seq-int.len prim < [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [
          true
        ] [
          found
        ] if
        j 1 prim +
        pair-loop
      ] [
        i 1 prim + xs target false pair-loop
      ] if
    ] [
      found
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target false 0 0 pair-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-loop
at: line 15, column 9
message: In the true branch `[ xs i prim seq-int.at xs j prim ...` of the `if` in `pair-loop`, `pair-loop` needs 5 values (xs:Seq Int, target:Int, found:Bool, i:Int, j:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `pair-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, found:Bool, i:Int, j:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `pair-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-distinct
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ is-new:Bool^many)
  locals { xs i j } {
    j i prim < [
      xs i prim seq-int.at xs j prim seq-int.at prim = [
        false
      ] [
        i xs j 1 prim + check-distinct
      ] if
    ] [
      true
    ] if
  };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs count i } {
    i xs prim seq-int.len prim < [
      xs i 0 check-distinct [
        count 1 prim +
      ] [
        count
      ] if
      i 1 prim +
      distinct-loop
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 distinct-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: check-distinct
at: line 8, column 25
message: `check-distinct` in `check-distinct` takes xs:Seq Int, i:Int, j:Int, bottom to top, but here it gets, bottom to top, `i` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `check-distinct` takes, in another order. To push them in its order, write `xs i j 1 prim +` in place of `i xs j 1 prim +`. With that edit `check-distinct` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: distinct-loop
at: line 28, column 7
message: In the true branch `[ xs i 0 check-distinct [ count 1 ...` of the `if` in `distinct-loop`, `distinct-loop` needs 3 values (xs:Seq Int, count:Int, i:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `distinct-loop` calls `check-distinct`, which has an error of its own; this report assumes `check-distinct` keeps its stack effect.
hint: Make the branch push, just before `distinct-loop`, exactly the values it takes, in this order: xs:Seq Int, count:Int, i:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (count:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `distinct-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [
      xs i prim seq-int.at ys j prim seq-int.at prim < [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        merge-loop
      ] [
        result ys j prim seq-int.at prim seq-int.push
        j 1 prim +
        merge-loop
      ] if
    ] [
      i xs prim seq-int.len prim < [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim +
        merge-loop
      ] [
        j ys prim seq-int.len prim < [
          result ys j prim seq-int.at prim seq-int.push
          j 1 prim +
          merge-loop
        ] [
          result
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { xs ys prim seq-int.empty 0 0 merge-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 26, column 11
message: In the true branch `[ result ys j prim seq-int.at prim seq-int.push ...` of the `if` in `merge-loop`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    n 0 prim = [
      result
    ] [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n prim seq-int.empty digits-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: digits-loop
at: line 9, column 7
message: `digits-loop` in `digits-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div`. With that edit `digits-loop` checks.

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
    divisor candidate prim < [
      candidate divisor prim mod 0 prim = [
        false
      ] [
        candidate divisor 1 prim + is-prime
      ] if
    ] [
      true
    ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many candidate:Int^many -- ρ primes:Seq Int^many)
  locals { n result candidate } {
    candidate n prim < [
      candidate 2 is-prime [
        result candidate prim seq-int.push
      ] [
        result
      ] if
      candidate 1 prim +
      primes-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n prim seq-int.empty 2 primes-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: primes-loop
at: line 28, column 7
message: In the true branch `[ candidate 2 is-prime [ result candidate prim ...` of the `if` in `primes-loop`, `primes-loop` needs 3 values (n:Int, result:Seq Int, candidate:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `primes-loop`, exactly the values it takes, in this order: n:Int, result:Seq Int, candidate:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (result:Seq Int, candidate:Int): keep each where it has that type and replace it where it does not. Then push the first one (n:Int) before them, for example by writing the locals that hold it. If `primes-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs counts i } {
    i xs prim seq-int.len prim < [
      counts xs i prim seq-int.at
      counts xs i prim seq-int.at prim seq-int.at 1 prim +
      prim seq-int.set
      i 1 prim +
      histogram-loop
    ] [
      counts
    ] if
  };

: init-counts
  (forall ρ; ρ counts:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts k } {
    k 0 prim = [
      counts
    ] [
      counts 0 prim seq-int.push
      k 1 prim -
      init-counts
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty k init-counts xs 0 histogram-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: histogram-loop
at: line 12, column 7
message: In the true branch `[ counts xs i prim seq-int.at counts xs ...` of the `if` in `histogram-loop`, `histogram-loop` needs 3 values (xs:Seq Int, counts:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `histogram-loop`, exactly the values it takes, in this order: xs:Seq Int, counts:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `histogram-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubble-inner
  (forall ρ; ρ sorted:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { sorted i j } {
    j sorted prim seq-int.len prim < [
      sorted i prim seq-int.at sorted j prim seq-int.at prim < [
        sorted i prim seq-int.at sorted j prim seq-int.at
        sorted i sorted j prim seq-int.at prim seq-int.set
        sorted j prim seq-int.set
      ] [
        sorted
      ] if
      j 1 prim +
      bubble-inner
    ] [
      sorted
    ] if
  };

: bubble-outer
  (forall ρ; ρ sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted i } {
    i sorted prim seq-int.len prim < [
      sorted i i 1 prim + bubble-inner
      i 1 prim +
      bubble-outer
    ] [
      sorted
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 bubble-outer };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: bubble-inner
at: line 11, column 9
message: The two branches of the `if` in `bubble-inner` whose true branch is `[ sorted i prim seq-int.at sorted j prim ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-int.set`; the false branch leaves `sorted`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and the result of `prim seq-int.at` are left below the result of `prim seq-int.set`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ start:Int^many txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { start txs balance rejected i } {
    i txs prim seq-int.len prim < [
      balance txs i prim seq-int.at prim +
      dup 0 prim < [
        drop balance rejected 1 prim +
      ] [
        swap drop balance prim +
      ] if
      i 1 prim +
      ledger-loop
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs start 0 0 ledger-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 10, column 9
message: In the false branch of the `if` in `ledger-loop` whose true branch is `[ drop balance rejected 1 prim + ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim +` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many item:Int^many qty:Int^many j:Int^many -- ρ stock-new:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock qtys whole item qty j } {
    stock item prim seq-int.at locals { stock qtys whole item qty j cur } {
      qty cur prim < [
        stock item qty prim seq-int.set qty 0
      ] [
        cur 0 prim = [
          stock 0 2
        ] [
          whole j prim seq-bool.at [
            stock 0 3
          ] [
            stock item 0 prim seq-int.set cur 1
          ] if
        ] if
      ] if
    }
  };

: batch-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole allocated reasons j } {
    j items prim seq-int.len prim < [
      stock items j prim seq-int.at qtys j prim seq-int.at whole j allocate-order
      locals { stock alloc reason } {
        allocated alloc prim seq-int.push
        reasons reason prim seq-int.push
        j 1 prim +
        batch-loop
      }
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole prim seq-int.empty prim seq-int.empty 0 batch-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: allocate-order
at: line 4, column 41
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 2
code: firth.type.branch-mismatch
word: batch-loop
at: line 34, column 7
message: In the true branch `[ stock items j prim seq-int.at qtys j ...` of the `if` in `batch-loop`, `allocate-order` needs 6 values (stock:Seq Int, qtys:Seq Int, whole:Seq Bool, item:Int, qty:Int, j:Int), but the branch has pushed only 5 values before it (`stock`, the result of `prim seq-int.at`, the result of `prim seq-int.at`, `whole` and `j`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `batch-loop` calls `allocate-order`, which has an error of its own; this report assumes `allocate-order` keeps its stack effect.
hint: Make the branch push, just before `allocate-order`, exactly the values it takes, in this order: stock:Seq Int, qtys:Seq Int, whole:Seq Bool, item:Int, qty:Int, j:Int. The branch already pushes `stock`, the result of `prim seq-int.at`, the result of `prim seq-int.at`, `whole` and `j`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `allocate-order` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
