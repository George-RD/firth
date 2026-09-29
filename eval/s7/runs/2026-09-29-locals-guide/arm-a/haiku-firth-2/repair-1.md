Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs i sum } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      i 1 prim +
      sum-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 11, column 5
message: In the true branch `[ sum xs i prim seq-int.at prim + ...` of the `if` in `sum-loop`, `sum-loop` needs 3 values (xs:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        elem max-val prim <
        [ max-val ]
        [ elem ]
        if
      }
      i 1 prim +
      max-loop
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 1 xs 0 prim seq-int.at max-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 16, column 5
message: In the true branch `[ xs i prim seq-int.at locals { elem ...` of the `if` in `max-loop`, `max-loop` needs 3 values (xs:Seq Int, i:Int, max-val:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, max-val:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (i:Int, max-val:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        elem k prim <
        [ count 1 prim + ]
        [ count ]
        if
      }
      i 1 prim +
      count-loop
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 16, column 5
message: In the true branch `[ xs i prim seq-int.at locals { elem ...` of the `if` in `count-loop`, `count-loop` needs 4 values (xs:Seq Int, k:Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, count:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        elem x prim =
        [ i ]
        [
          i 1 prim +
          find-loop
        ]
        if
      }
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x 0 find-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 13, column 9
message: In the false branch of the `if` in `find-loop` whose true branch is `[ i ]`, `find-loop` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: build-reverse
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      xs i prim seq-int.at locals { elem } {
        result elem prim seq-int.push
        i 1 prim -
        build-reverse
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty build-reverse
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: build-reverse
at: line 13, column 5
message: In the true branch `[ xs i prim seq-int.at locals { elem ...` of the `if` in `build-reverse`, `build-reverse` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `build-reverse`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `build-reverse` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim + locals { new-sum } {
        result new-sum prim seq-int.push
        i 1 prim +
        new-sum
        prefix-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 14, column 5
message: In the true branch `[ sum xs i prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `new-sum`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `new-sum`, in the place of the first 3 (xs:Seq Int, i:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        elem 0 prim <
        [ result ]
        [ result elem prim seq-int.push ]
        if
      }
      i 1 prim +
      filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 16, column 5
message: In the true branch `[ xs i prim seq-int.at locals { elem ...` of the `if` in `filter-loop`, `filter-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `filter-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at locals { cur } {
        xs i 1 prim + prim seq-int.at locals { next } {
          cur next prim <
          prim not
          [
            false
          ]
          [
            i 1 prim +
            check-loop
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
  locals { xs } {
    xs xs prim seq-int.len 0 prim =
    [
      true
    ]
    [
      xs xs prim seq-int.len 1 prim = 
      [
        true
      ]
      [
        xs 0 check-loop
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-loop
at: line 17, column 11
message: In the false branch of the `if` in `check-loop` whose true branch is `[ false ]`, `check-loop` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `check-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 42, column 5
message: The two branches of the `if` in `main` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch leaves 2 values, bottom to top: `xs` and the result of an `if`.
hint: The false branch leaves 1 value more than the true branch: `xs` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { x } {
        ys i prim seq-int.at locals { y } {
          x y prim * locals { prod } {
            sum prod prim +
            i 1 prim +
            dot-loop
          }
        }
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 17, column 5
message: In the true branch `[ xs i prim seq-int.at locals { x ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, sum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at
      [
        i 1 prim +
        check-all
      ]
      [
        false
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags flags prim seq-bool.len 0 prim =
    [
      true
    ]
    [
      flags 0 check-all
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-all
at: line 14, column 7
message: In the true branch `[ i 1 prim + check-all ]` of the `if` in `check-all`, `check-all` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `check-all` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 21, column 3
message: `main` declares that it leaves ρ Bool but its body leaves ρ Seq Bool Bool.
expected: ρ Bool
actual: ρ Seq Bool Bool
hint: The body leaves 1 extra value on top (Bool). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cur-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i cur-len max-len } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { cur } {
        xs i 1 prim - prim seq-int.at locals { prev } {
          cur prev prim =
          [
            cur-len 1 prim + locals { new-len } {
              new-len max-len prim <
              [ max-len ]
              [ new-len ]
              if
              i 1 prim +
              new-len
              run-loop
            }
          ]
          [
            cur-len max-len prim <
            prim not
            [
              cur-len
            ]
            [
              max-len
            ]
            if
            i 1 prim +
            1
            run-loop
          ]
          if
        }
      }
    ]
    [
      cur-len max-len prim <
      prim not
      [
        cur-len
      ]
      [
        max-len
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      xs xs prim seq-int.len 1 prim =
      [
        1
      ]
      [
        xs 1 1 0 run-loop
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 49, column 5
message: In the true branch `[ xs i prim seq-int.at locals { cur ...` of the `if` in `run-loop`, `run-loop` (inside a quotation in that branch) needs 4 values (xs:Seq Int, i:Int, cur-len:Int, max-len:Int), but the branch has pushed only 3 values before it (the result of an `if`, the result of `prim +` and `new-len` or `1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, cur-len:Int, max-len:Int. The branch already pushes the result of an `if`, the result of `prim +` and `new-len` or `1`, in the place of the last 3 (i:Int, cur-len:Int, max-len:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 69, column 5
message: The two branches of the `if` in `main` whose true branch is `[ 0 ]` leave different numbers of values. The true branch leaves `0`; the false branch leaves 2 values, bottom to top: `xs` and the result of an `if`.
hint: The false branch leaves 1 value more than the true branch: `xs` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [
        j 1 prim +
        find-pair-inner
      ]
      [
        xs i prim seq-int.at locals { a } {
          xs j prim seq-int.at locals { b } {
            a b prim + locals { sum } {
              sum target prim =
              [
                true
              ]
              [
                j 1 prim +
                find-pair-inner
              ]
              if
            }
          }
        }
      ]
      if
    ]
    [
      i 1 prim + locals { next-i } {
        next-i xs prim seq-int.len prim <
        [
          xs next-i next-i find-pair-inner
        ]
        [
          false
        ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 0 find-pair-inner
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-pair-inner
at: line 23, column 15
message: In the false branch of the `if` in `find-pair-inner` whose true branch is `[ true ]`, `find-pair-inner` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-pair-inner`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `find-pair-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in-seq
  (forall ρ; ρ seq:Seq Int^many val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { seq val i } {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at val prim =
      [
        true
      ]
      [
        i 1 prim +
        is-in-seq
      ]
      if
    ]
    [ false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many distinct:Seq Int^many -- ρ result:Int^many)
  locals { xs i distinct } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        distinct elem 0 is-in-seq
        [
          i 1 prim +
          distinct
          count-distinct-loop
        ]
        [
          distinct elem prim seq-int.push
          i 1 prim +
          count-distinct-loop
        ]
        if
      }
    ]
    [ distinct prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty count-distinct-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-in-seq
at: line 14, column 7
message: In the false branch of the `if` in `is-in-seq` whose true branch is `[ true ]`, `is-in-seq` needs 3 values (seq:Seq Int, val:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-in-seq`, exactly the values it takes, in this order: seq:Seq Int, val:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `is-in-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 41, column 5
message: In the true branch `[ xs i prim seq-int.at locals { elem ...` of the `if` in `count-distinct-loop`, `count-distinct-loop` (inside a quotation in that branch) needs 3 values (xs:Seq Int, i:Int, distinct:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` or the result of `prim seq-int.push` and `distinct` or the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `count-distinct-loop` calls `is-in-seq`, which has an error of its own; this report assumes `is-in-seq` keeps its stack effect.
hint: Make the branch push, just before `count-distinct-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, distinct:Seq Int. The branch already pushes the result of `prim +` or the result of `prim seq-int.push` and `distinct` or the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `count-distinct-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim <
    prim and
    [
      xs i prim seq-int.at locals { x } {
        ys j prim seq-int.at locals { y } {
          x y prim <
          [
            result x prim seq-int.push
            i 1 prim +
            merge-loop
          ]
          [
            result y prim seq-int.push
            j 1 prim +
            merge-loop
          ]
          if
        }
      }
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at locals { x } {
          result x prim seq-int.push
          i 1 prim +
          merge-loop
        }
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at locals { y } {
            result y prim seq-int.push
            j 1 prim +
            merge-loop
          }
        ]
        [
          result
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 46, column 9
message: In the true branch `[ ys j prim seq-int.at locals { y ...` of the `if` in `merge-loop`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: build-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod locals { digit } {
        n 10 prim div locals { rest } {
          rest digit prim seq-int.push result build-digits
        }
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ seq:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { seq result } {
    seq prim seq-int.len 0 prim =
    [
      result
    ]
    [
      seq seq prim seq-int.len 1 prim - prim seq-int.at locals { last } {
        seq seq prim seq-int.len 1 prim - prim seq-int.set prim seq-int.empty locals { rest } {
          result last prim seq-int.push
          rest result reverse-digits
        }
      }
    ]
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
      n prim seq-int.empty build-digits prim seq-int.empty reverse-digits
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: build-digits
at: line 11, column 22
message: `prim seq-int.push` in `build-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `rest` (Int) and `digit` (Int).
expected: .. Seq Int Int
actual: .. Int ?t19 Int Int Int
hint: The second value from the top, `rest` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-digits
at: line 33, column 5
message: In the false branch of the `if` in `reverse-digits` whose true branch is `[ result ]`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (`seq` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes `seq` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * locals { i-sq } {
      i-sq n prim <
      [
        n i prim mod 0 prim =
        [
          false
        ]
        [
          i 1 prim +
          is-prime
        ]
        if
      ]
      [
        true
      ]
      if
    }
  };

: sieve-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <
    prim not
    i 2 prim <
    prim or
    [
      result
    ]
    [
      i 2 is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      i 1 prim +
      sieve-loop
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim < 
    [
      prim seq-int.empty
    ]
    [
      n 2 prim seq-int.empty sieve-loop
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 15, column 9
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `is-prime` needs 2 values (n:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime`, exactly the values it takes, in this order: n:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: sieve-loop
at: line 46, column 5
message: In the false branch of the `if` in `sieve-loop` whose true branch is `[ result ]`, `sieve-loop` needs 3 values (n:Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `sieve-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `sieve-loop`, exactly the values it takes, in this order: n:Int, i:Int, result:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `sieve-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { val } {
        counts val prim seq-int.at locals { cur } {
          counts val cur 1 prim + prim seq-int.set
          i 1 prim +
          histogram-loop
        }
      }
    ]
    [ counts ]
    if
  };

: init-counts
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ initialized:Seq Int^many)
  locals { k i counts } {
    i k prim <
    [
      counts 0 prim seq-int.push
      i 1 prim +
      init-counts
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-counts
    xs k 0
    histogram-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: histogram-loop
at: line 15, column 5
message: In the true branch `[ xs i prim seq-int.at locals { val ...` of the `if` in `histogram-loop`, `histogram-loop` needs 4 values (xs:Seq Int, k:Int, i:Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `histogram-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, counts:Seq Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `histogram-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: init-counts
at: line 28, column 5
message: In the true branch `[ counts 0 prim seq-int.push i 1 prim ...` of the `if` in `init-counts`, `init-counts` needs 3 values (k:Int, i:Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-counts`, exactly the values it takes, in this order: k:Int, i:Int, counts:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `init-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 36, column 5
message: `histogram-loop` in `main` takes xs:Seq Int, k:Int, i:Int, counts:Seq Int, bottom to top, but here it gets, bottom to top, the result of `init-counts` (Seq Int), `xs` (Seq Int), `k` (Int) and `0` (Int). `main` calls `init-counts` and `histogram-loop`, which have errors of their own; this report assumes they keep their stack effects.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: These are the values `histogram-loop` takes, in another order. To push them in its order, write `xs k 0 k 0 prim seq-int.empty init-counts` in place of `k 0 prim seq-int.empty init-counts xs k 0`. With that edit `main` checks.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ seq:Seq Int^many elem:Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { seq elem i } {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at locals { cur } {
        elem cur prim <
        [
          seq i elem prim seq-int.set
          i 1 prim +
          seq cur
          insert-sorted
        ]
        [
          seq
          i 1 prim +
          elem
          insert-sorted
        ]
        if
      }
    ]
    [ seq elem prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at locals { elem } {
        sorted elem 0 insert-sorted
        i 1 prim +
        sort-loop
      }
    ]
    [ sorted ]
    if
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
code: firth.type.branch-mismatch
word: insert-sorted
at: line 20, column 9
message: The two branches of the `if` in `insert-sorted` whose true branch is `[ seq i elem prim seq-int.set i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-sorted`; the false branch leaves the result of `insert-sorted`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-sorted`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-loop
at: line 39, column 5
message: In the true branch `[ xs i prim seq-int.at locals { elem ...` of the `if` in `sort-loop`, `sort-loop` needs 3 values (xs:Seq Int, i:Int, sorted:Seq Int), but the branch has pushed only 2 values before it (the result of `insert-sorted` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `sort-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: Make the branch push, just before `sort-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sorted:Seq Int. The branch already pushes the result of `insert-sorted` and the result of `prim +`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (sorted:Seq Int) after them, for example by writing the locals that hold it. If `sort-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance-final:Int^many rejected-final:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim <
          [
            i 1 prim +
            balance
            rejected 1 prim +
            ledger-loop
          ]
          [
            i 1 prim +
            new-balance
            rejected
            ledger-loop
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
  locals { start txs } {
    txs start 0 0 ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 26, column 5
message: In the true branch `[ txs i prim seq-int.at locals { tx ...` of the `if` in `ledger-loop`, `ledger-loop` (inside a quotation in that branch) needs 4 values (txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `balance` or `new-balance` and the result of `prim +` or `rejected`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes the result of `prim +`, `balance` or `new-balance` and the result of `prim +` or `rejected`, in the place of the last 3 (i:Int, balance:Int, rejected:Int): keep each where it has that type and replace it where it does not. Then push the first one (txs:Seq Int) before them, for example by writing the locals that hold it. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many result-alloc:Seq Int^many result-reasons:Seq Int^many -- ρ stock-new:Seq Int^many allocated-new:Seq Int^many reasons-new:Seq Int^many)
  locals { stock item qty whole result-alloc result-reasons } {
    stock item prim seq-int.at locals { avail } {
      qty avail prim <
      prim not
      qty avail prim = prim or
      [
        stock item qty prim seq-int.set locals { stock-new } {
          result-alloc qty prim seq-int.push
          result-reasons 0 prim seq-int.push
          stock-new result-alloc result-reasons
        }
      ]
      [
        avail 0 prim =
        [
          stock
          result-alloc 0 prim seq-int.push
          result-reasons 2 prim seq-int.push
        ]
        [
          whole
          [
            stock
            result-alloc 0 prim seq-int.push
            result-reasons 3 prim seq-int.push
          ]
          [
            stock item 0 prim seq-int.set locals { stock-new } {
              result-alloc avail prim seq-int.push
              result-reasons 1 prim seq-int.push
              stock-new result-alloc result-reasons
            }
          ]
          if
        ]
        if
      ]
      if
    }
  };

: process-orders
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many result-alloc:Seq Int^many result-reasons:Seq Int^many -- ρ stock-final:Seq Int^many alloc-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock items qtys whole i result-alloc result-reasons } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at locals { item } {
        qtys i prim seq-int.at locals { qty } {
          whole i prim seq-bool.at locals { w } {
            stock item qty w result-alloc result-reasons allocate-order
            i 1 prim +
            process-orders
          }
        }
      }
    ]
    [ stock result-alloc result-reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty process-orders
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-order
at: line 36, column 11
message: The two branches of the `if` in `allocate-order` whose true branch is `[ stock result-alloc 0 prim seq-int.push result-reasons 3 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `stock`, the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 5 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push`, `stock-new`, `result-alloc` and `result-reasons`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim seq-int.push` and the result of `prim seq-int.push` are left below `stock-new`, `result-alloc` and `result-reasons`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: process-orders
at: line 60, column 5
message: In the true branch `[ items i prim seq-int.at locals { item ...` of the `if` in `process-orders`, `process-orders` needs 7 values (stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, result-alloc:Seq Int, result-reasons:Seq Int), but the branch has pushed only 4 values before it (the output `stock-new` of `allocate-order`, the output `allocated-new` of `allocate-order`, the output `reasons-new` of `allocate-order` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `process-orders` calls `allocate-order`, which has an error of its own; this report assumes `allocate-order` keeps its stack effect.
hint: Make the branch push, just before `process-orders`, exactly the values it takes, in this order: stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, result-alloc:Seq Int, result-reasons:Seq Int. The branch already pushes the output `stock-new` of `allocate-order`, the output `allocated-new` of `allocate-order`, the output `reasons-new` of `allocate-order` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `process-orders` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
