Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 swap locals { xs } { [ 0 xs prim seq-int.len ] [ drop 0 ] if [ xs prim seq-int.len ] call [ 0 ] call [ 1 ] call [ 0 dup ] call prim + };

: sum-helper
  (forall ρ; ρ xs:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs acc i } { 
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      acc prim +
      i 1 prim +
      sum-helper
    ]
    [
      acc
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-helper;

```
On the example, the run failed:
code: firth.name.duplicate-canonical
at: line 20, column 1
message: Unexpected `main`.
actual: main
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      dup max-val prim <
      [ drop max-val ]
      [ ]
      if
      i 1 prim +
      max-helper
    ]
    [
      max-val
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    0 xs prim seq-int.at
    1
    max-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 7
message: In the true branch `[ i xs prim seq-int.at dup max-val prim ...` of the `if` in `max-helper`, `max-helper` needs 3 values (xs:Seq Int, i:Int, max-val:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, max-val:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (i:Int, max-val:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many count:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k count i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      k prim <
      [ count 1 prim + ]
      [ count ]
      if
      i 1 prim +
      count-helper
    ]
    [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 count-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 7
message: In the true branch `[ i xs prim seq-int.at k prim < ...` of the `if` in `count-helper`, `count-helper` needs 4 values (xs:Seq Int, k:Int, count:Int, i:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-helper`, exactly the values it takes, in this order: xs:Seq Int, k:Int, count:Int, i:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      x prim =
      [ i ]
      [
        i 1 prim +
        find-helper
      ]
      if
    ]
    [
      -1
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  0 find-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 7
message: In the false branch of the `if` in `find-helper` whose true branch is `[ i ]`, `find-helper` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-helper`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    [ i 0 prim < prim not ]
    [
      i xs prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      reverse-helper
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    reverse-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 7
message: In the true branch `[ i xs prim seq-int.at result prim seq-int.push ...` of the `if` in `reverse-helper`, `reverse-helper` needs 3 values (xs:Seq Int, result:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-helper`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many acc:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result acc i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      acc prim +
      dup result prim seq-int.push
      i 1 prim +
      prefix-helper
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 prefix-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 7
message: In the true branch `[ i xs prim seq-int.at acc prim + ...` of the `if` in `prefix-helper`, `prefix-helper` needs 4 values (xs:Seq Int, result:Seq Int, acc:Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-helper`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, acc:Int, i:Int. The branch already pushes the result of `prim +`, the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      i 1 prim +
      keep-helper
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 keep-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 16, column 7
message: In the true branch `[ i xs prim seq-int.at dup 0 prim ...` of the `if` in `keep-helper`, `keep-helper` needs 3 values (xs:Seq Int, result:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `keep-helper`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, i:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `keep-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    [ i xs prim seq-int.len 1 prim - prim < ]
    [
      i xs prim seq-int.at
      i 1 prim + xs prim seq-int.at
      prim <
      prim not
      [ 
        i 1 prim +
        check-sorted
      ]
      [
        0 prim seq-bool.empty
      ]
      if
    ]
    [
      1 prim seq-bool.empty
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ true ]
    [ 0 check-sorted ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 27, column 33
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many i:Int^many -- ρ product:Int^many)
  locals { xs ys sum i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      i ys prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      dot-helper
    ]
    [
      sum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 15, column 7
message: In the true branch `[ i xs prim seq-int.at i ys prim ...` of the `if` in `dot-helper`, `dot-helper` needs 4 values (xs:Seq Int, ys:Seq Int, sum:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-helper`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, sum:Int, i:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (sum:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    [ i flags prim seq-bool.len prim < ]
    [
      i flags prim seq-bool.at
      [ 
        i 1 prim +
        all-helper
      ]
      [
        false
      ]
      if
    ]
    [
      true
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 all-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 14, column 7
message: In the true branch `[ i 1 prim + all-helper ]` of the `if` in `all-helper`, `all-helper` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-helper`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `all-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-length
  (forall ρ; ρ xs:Seq Int^many i:Int^many val:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i val len } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      val prim =
      [ 
        i 1 prim +
        val
        len 1 prim +
        run-length
      ]
      [
        len
      ]
      if
    ]
    [
      len
    ] if
  };

: longest-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i max-len } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      i 1 prim +
      run-length
      max-len prim <
      [ max-len ]
      [ dup ]
      if
      i 1 prim +
      longest-helper
    ]
    [
      max-len
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 0 longest-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 17, column 7
message: In the true branch `[ i 1 prim + val len 1 ...` of the `if` in `run-length`, `run-length` needs 4 values (xs:Seq Int, i:Int, val:Int, len:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `val` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-length`, exactly the values it takes, in this order: xs:Seq Int, i:Int, val:Int, len:Int. The branch already pushes the result of `prim +`, `val` and the result of `prim +`, in the place of the last 3 (i:Int, val:Int, len:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `run-length` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    [ j xs prim seq-int.len prim < ]
    [
      j i prim =
      [
        i 1 prim +
        find-pair
      ]
      [
        i xs prim seq-int.at
        j xs prim seq-int.at
        prim +
        target prim =
        [ true ]
        [
          j 1 prim +
          find-pair
        ]
        if
      ]
      if
    ]
    [
      false
    ] if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    [ i xs prim seq-int.len prim < ]
    [
      i 0 find-pair
      [ true ]
      [
        i 1 prim +
        outer-loop
      ]
      if
    ]
    [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 outer-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 21, column 9
message: In the false branch of the `if` in `find-pair` whose true branch is `[ true ]`, `find-pair` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-pair`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `find-pair` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in-result
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ found:Bool^many)
  locals { result val i } {
    [ i result prim seq-int.len prim < ]
    [
      i result prim seq-int.at
      val prim =
      [ true ]
      [
        i 1 prim +
        is-in-result
      ]
      if
    ]
    [
      false
    ] if
  };

: count-distinct-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      0 is-in-result
      [
        result
      ]
      [
        i xs prim seq-int.at
        result prim seq-int.push
      ]
      if
      i 1 prim +
      count-distinct-helper
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 count-distinct-helper prim seq-int.len;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 7
message: In the false branch of the `if` in `is-in-result` whose true branch is `[ true ]`, `is-in-result` needs 3 values (result:Seq Int, val:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-in-result`, exactly the values it takes, in this order: result:Seq Int, val:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `is-in-result` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs ys result i j } {
    [ i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and ]
    [
      i xs prim seq-int.at
      j ys prim seq-int.at
      prim <
      [
        i xs prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        j
        merge-helper
      ]
      [
        j ys prim seq-int.at
        result prim seq-int.push
        i
        j 1 prim +
        merge-helper
      ]
      if
    ]
    [
      [ i xs prim seq-int.len prim < ]
      [
        i xs prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        j
        merge-helper
      ]
      [
        [ j ys prim seq-int.len prim < ]
        [
          j ys prim seq-int.at
          result prim seq-int.push
          i
          j 1 prim +
          merge-helper
        ]
        [
          result
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 merge-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 45, column 11
message: In the true branch `[ j ys prim seq-int.at result prim seq-int.push ...` of the `if` in `merge-helper`, `merge-helper` needs 5 values (xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `i` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-helper`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int. The branch already pushes the result of `prim seq-int.push`, `i` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `merge-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    [ n 0 prim = ]
    [
      result
    ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      digits-helper
    ] if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    [ i 0 prim < prim not ]
    [
      i xs prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      reverse-digits
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    [ n 0 prim = ]
    [ { 0 } ]
    [
      prim seq-int.empty
      n digits-helper
      prim seq-int.len 1 prim -
      reverse-digits
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 28, column 7
message: In the true branch `[ i xs prim seq-int.at result prim seq-int.push ...` of the `if` in `reverse-digits`, `reverse-digits` needs 3 values (xs:Seq Int, result:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: xs:Seq Int, result:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    [ divisor divisor prim * num prim < ]
    [
      num divisor prim mod
      0 prim =
      [ false ]
      [
        num
        divisor 1 prim +
        is-prime
      ]
      if
    ]
    [
      true
    ] if
  };

: collect-primes
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n current result } {
    [ current n prim < ]
    [
      [ current 2 prim < ]
      [ 
        current 1 prim +
        collect-primes
      ]
      [
        current 2 is-prime
        [
          current result prim seq-int.push
        ]
        [
          result
        ]
        if
        current 1 prim +
        collect-primes
      ] if
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  2 prim seq-int.empty collect-primes;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 42, column 9
message: In the true branch `[ current 1 prim + collect-primes ]` of the `if` in `collect-primes`, `collect-primes` needs 3 values (n:Int, current:Int, result:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `collect-primes`, exactly the values it takes, in this order: n:Int, current:Int, result:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `collect-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many counts:Seq Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { xs k counts i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      dup
      counts swap prim seq-int.at
      1 prim +
      counts swap 2 prim swap prim seq-int.set
      i 1 prim +
      histogram-helper
    ]
    [
      counts
    ] if
  };

: make-zeros
  (forall ρ; ρ k:Int^many count:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k count result } {
    [ count k prim < ]
    [
      0 result prim seq-int.push
      count 1 prim +
      make-zeros
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    make-zeros
    0
    histogram-helper
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 10, column 26
message: Unexpected `swap`, expected `primitive name`.
expected: primitive name
actual: swap
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result val i } {
    [ i result prim seq-int.len prim < ]
    [
      i result prim seq-int.at
      val prim <
      [ i result prim seq-int.len prim swap prim seq-int.set ]
      [ 
        val
        i
        result prim seq-int.at
        prim seq-int.push
        i 1 prim +
        insert-sorted
      ]
      if
    ]
    [
      val result prim seq-int.push
    ] if
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    [ i xs prim seq-int.len prim < ]
    [
      i xs prim seq-int.at
      0
      insert-sorted
      i 1 prim +
      sort-helper
    ]
    [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty 0 sort-helper;

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 8, column 40
message: Unexpected `swap`, expected `primitive name`.
expected: primitive name
actual: swap
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-helper
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs i } {
    [ i txs prim seq-int.len prim < ]
    [
      i txs prim seq-int.at
      balance prim +
      dup 0 prim <
      [
        drop
        balance
        rejected 1 prim +
      ]
      [
        rejected
      ]
      if
      i 1 prim +
      ledger-helper
    ]
    [
      rejected
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 ledger-helper;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 18, column 11
message: `prim +` in `ledger-helper` needs Int Int on top of the stack, but the stack before it is .. Int Int Seq Int Int.
expected: .. Int Int
actual: .. Int Int Seq Int Int
hint: The second value from the top is Seq Int but `prim +` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole order-idx allocated reasons } {
    [ order-idx items prim seq-int.len prim < ]
    [
      order-idx items prim seq-int.at
      dup
      stock swap prim seq-int.at
      order-idx qtys prim seq-int.at
      dup
      swap prim <
      [
        0
        stock swap prim seq-int.set
        order-idx qtys prim seq-int.at
        allocated prim seq-int.push
        0 reasons prim seq-int.push
      ]
      [
        drop
        0 prim =
        [
          0 allocated prim seq-int.push
          2 reasons prim seq-int.push
        ]
        [
          order-idx whole prim seq-bool.at
          [
            0 allocated prim seq-int.push
            3 reasons prim seq-int.push
          ]
          [
            stock swap prim seq-int.at
            dup allocated prim seq-int.push
            1 reasons prim seq-int.push
            order-idx swap dup prim - stock swap prim seq-int.set
          ]
          if
        ]
        if
      ]
      if
      order-idx 1 prim +
      allocate-order
    ]
    [
      reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 allocate-order;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 42, column 7
message: The two branches of `if` in `allocate-order` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 3 values, and the false branch takes 3 values from the stack below the `if` and leaves 3 values. The condition and the values the branches take from below the `if` are looked for where the local `order-idx` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.
