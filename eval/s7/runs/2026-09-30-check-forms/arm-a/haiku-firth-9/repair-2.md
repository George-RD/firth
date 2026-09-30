Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: seq-sum
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 swap 0 xs prim seq-int.len sum-loop;

: sum-loop
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at sum prim + locals { new_sum } {
        idx 1 prim + locals { new_idx } {
          new_idx new_sum len xs sum-loop
        }
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  seq-sum;

```
On the example, the run failed:
code: firth.syntax.expected-name
at: line 10, column 53
message: Unexpected `_`, expected `name`.
expected: name
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  dup 0 prim seq-int.at swap 1 max-iter;

: max-iter
  (forall ρ; ρ current:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { current idx xs } {
    xs prim seq-int.len idx prim >=
    [ current ]
    [
      xs idx prim seq-int.at current prim > locals { is-greater } {
        is-greater [ xs idx prim seq-int.at ] [ current ] if locals { new-current } {
          idx 1 prim + new-current new-current xs max-iter
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  seq-max;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: seq-max
at: line 3, column 32
message: `max-iter` in `seq-max` takes current:Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), the input `xs` (Seq Int) and `1` (Int). `seq-max` calls `max-iter`, which has an error of its own; this report assumes `max-iter` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int Int
hint: The top value, `1` (Int), is not what `max-iter` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: max-iter
at: line 17, column 5
message: The two branches of the `if` in `max-iter` whose true branch is `[ current ]` leave different numbers of values. The true branch leaves `current`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `max-iter`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of `max-iter`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 0 xs prim seq-int.len count-loop;

: count-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx len xs k } {
    idx len prim <
    [
      xs idx prim seq-int.at k prim < locals { is-below } {
        is-below [ count 1 prim + ] [ count ] if locals { new-count } {
          idx 1 prim + new-count new-count len xs k count-loop
        }
      }
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  count-below;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: count-below
at: line 3, column 12
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: count-loop
at: line 17, column 5
message: The two branches of the `if` in `count-loop` whose true branch is `[ xs idx prim seq-int.at k prim < ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `count-loop`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `count-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 xs prim seq-int.len find-loop;

: find-loop
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx len xs x } {
    idx len prim <
    [
      xs idx prim seq-int.at x prim = locals { found } {
        found [ idx ] [ idx 1 prim + found find-loop ] if
      }
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  index-of;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: index-of
at: line 3, column 10
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: find-loop
at: line 11, column 56
message: In the false branch of the `if` in `find-loop` whose true branch is `[ idx ]`, `find-loop` needs 4 values (idx:Int, len:Int, xs:Seq Int, x:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `found`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: idx:Int, len:Int, xs:Seq Int, x:Int. The branch already pushes the result of `prim +` and `found`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty swap dup prim seq-int.len 1 prim - reverse-loop;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx xs } {
    idx 0 prim >=
    [
      xs idx prim seq-int.at result prim seq-int.push locals { new-result } {
        idx 1 prim - new-result new-result xs reverse-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  reverse;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: reverse
at: line 3, column 57
message: `reverse-loop` in `reverse` takes result:Seq Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), the input `xs` (Seq Int) and the result of `prim -` (Int). `reverse` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: The top value, the result of `prim -` (Int), is not what `reverse-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 15, column 5
message: The two branches of the `if` in `reverse-loop` whose true branch is `[ xs idx prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim -` and the result of `reverse-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim -` is left below the result of `reverse-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-sums
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at sum prim + locals { new-sum } {
        result new-sum prim seq-int.push locals { new-result } {
          idx 1 prim + new-result new-sum new-sum len xs prefix-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  prefix-sums;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: prefix-sums
at: line 3, column 26
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: prefix-loop
at: line 17, column 5
message: The two branches of the `if` in `prefix-loop` whose true branch is `[ xs idx prim seq-int.at sum prim + ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prefix-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `prefix-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 xs prim seq-int.len filter-pos;

: filter-pos
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at dup 0 prim > locals { is-positive } {
        is-positive [ result swap prim seq-int.push ] [ drop result ] if locals { new-result } {
          idx 1 prim + new-result new-result len xs filter-pos
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  keep-positive;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: keep-positive
at: line 3, column 24
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: filter-pos
at: line 17, column 5
message: The two branches of the `if` in `filter-pos` whose true branch is `[ xs idx prim seq-int.at dup 0 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `filter-pos`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `filter-pos`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  dup prim seq-int.len dup 1 prim <= [ drop drop true ] [ 1 prim - check-sorted ] if;

: check-sorted
  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs len idx } {
    idx len prim >=
    [ true ]
    [
      xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <= locals { is-le } {
        is-le [ idx 1 prim + check-sorted ] [ false ] if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  is-sorted;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-sorted
at: line 3, column 83
message: In the false branch of the `if` in `is-sorted` whose true branch is `[ drop drop true ]`, `check-sorted` needs 3 values (xs:Seq Int, len:Int, idx:Int), but the branch has pushed only 1 value before it (the result of `prim -`). Earlier in the branch, the result of `prim seq-int.len` was already taken from below the `if`. It would take the input `xs` from below the `if`, and 1 value more that is not there: the word's inputs are used up, and what lies below them belongs to the caller. `is-sorted` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
hint: Make the branch push, just before `check-sorted`, exactly the values it takes, in this order: xs:Seq Int, len:Int, idx:Int. The branch already pushes the result of `prim -`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: check-sorted
at: line 12, column 55
message: In the true branch `[ idx 1 prim + check-sorted ]` of the `if` in `check-sorted`, `check-sorted` needs 3 values (xs:Seq Int, len:Int, idx:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-sorted`, exactly the values it takes, in this order: xs:Seq Int, len:Int, idx:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  swap 0 0 xs prim seq-int.len dot-loop;

: dot-loop
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs ys } {
    idx len prim <
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + locals { new-sum } {
        idx 1 prim + new-sum new-sum len xs ys dot-loop
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  dot;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: dot
at: line 3, column 12
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: dot-loop
at: line 15, column 5
message: The two branches of the `if` in `dot-loop` whose true branch is `[ xs idx prim seq-int.at ys idx prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `dot-loop`; the false branch leaves `sum`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `dot-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 flags prim seq-bool.len check-all;

: check-all
  (forall ρ; ρ idx:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { idx len flags } {
    idx len prim >=
    [ true ]
    [
      flags idx prim seq-bool.at [ idx 1 prim + check-all ] [ false ] if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  all-true;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: all-true
at: line 3, column 5
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: check-all
at: line 11, column 71
message: In the true branch `[ idx 1 prim + check-all ]` of the `if` in `check-all`, `check-all` needs 3 values (idx:Int, len:Int, flags:Seq Bool), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all`, exactly the values it takes, in this order: idx:Int, len:Int, flags:Seq Bool. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-all` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  dup prim seq-int.len 0 prim = [ drop 0 ] [ 1 1 find-longest ] if;

: find-longest
  (forall ρ; ρ current:Int^many max:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { current max idx xs } {
    xs prim seq-int.len idx prim >=
    [ max current prim > [ current ] [ max ] if ]
    [
      xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim = locals { same } {
        same [ current 1 prim + ] [ 1 ] if locals { new-current } {
          new-current max prim > [ new-current ] [ max ] if locals { new-max } {
            idx 1 prim + new-current new-max idx xs find-longest
          }
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  longest-run;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: longest-run
at: line 3, column 65
message: In the false branch of the `if` in `longest-run` whose true branch is `[ drop 0 ]`, `find-longest` needs 4 values (current:Int, max:Int, idx:Int, xs:Seq Int), but the branch has pushed only 2 values before it (`1` and `1`). It would take the input `xs` from below the `if`, and 1 value more that is not there: the word's inputs are used up, and what lies below them belongs to the caller. `longest-run` calls `find-longest`, which has an error of its own; this report assumes `find-longest` keeps its stack effect.
hint: Make the branch push, just before `find-longest`, exactly the values it takes, in this order: current:Int, max:Int, idx:Int, xs:Seq Int. The branch already pushes `1` and `1`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-longest` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: find-longest
at: line 19, column 5
message: The two branches of the `if` in `find-longest` whose true branch is `[ max current prim > [ current ] ...` leave different numbers of values. The true branch leaves the result of an `if`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `find-longest`.
hint: The result of `prim +` is a new value of `idx`, but `find-longest` is then handed `idx` as it was before, so the new value is left below. If `find-longest` should get the new value, bind it to the name `idx` for the call: write `prim + locals { idx } { new-current new-max idx xs find-longest }` in place of `prim + new-current new-max idx xs find-longest` on line 14. With that edit `find-longest` checks. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 xs prim seq-int.len check-pairs;

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target } {
    i len prim >=
    [ false ]
    [
      i 1 prim + locals { j } {
        i j len xs target inner-loop
      }
    ]
    if
  };

: inner-loop
  (forall ρ; ρ i:Int^many j:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i j len xs target } {
    j len prim >=
    [ i 1 prim + len xs target check-pairs ]
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim = locals { match } {
        match [ true ] [ j 1 prim + inner-loop ] if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  has-pair-sum;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: has-pair-sum
at: line 3, column 10
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: inner-loop
at: line 25, column 50
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ true ]`, `inner-loop` needs 5 values (i:Int, j:Int, len:Int, xs:Seq Int, target:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 4 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: i:Int, j:Int, len:Int, xs:Seq Int, target:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 4 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 xs prim seq-int.len count-dist;

: count-dist
  (forall ρ; ρ seen:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen idx len xs } {
    idx len prim >=
    [ seen prim seq-int.len ]
    [
      xs idx prim seq-int.at dup seen is-in locals { found } {
        found [ drop ] [ seen swap prim seq-int.push ] if locals { new-seen } {
          idx 1 prim + new-seen new-seen len xs count-dist
        }
      }
    ]
    if
  };

: is-in
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  0 seq prim seq-int.len check-in;

: check-in
  (forall ρ; ρ idx:Int^many len:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { idx len seq val } {
    idx len prim >=
    [ false ]
    [
      seq idx prim seq-int.at val prim = [ true ] [ idx 1 prim + check-in ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  count-distinct;

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.name.unresolved
word: count-distinct
at: line 3, column 24
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 4
code: firth.type.branch-mismatch
word: count-dist
at: line 12, column 56
message: The two branches of the `if` in `count-dist` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves nothing; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.push`. `count-dist` calls `is-in`, which has an error of its own; this report assumes `is-in` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 4
code: firth.name.unresolved
word: is-in
at: line 22, column 5
message: `seq` is not a defined word, primitive or local.
actual: seq
hint: `seq` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { val seq } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 4 of 4
code: firth.type.branch-mismatch
word: check-in
at: line 30, column 77
message: In the false branch of the `if` in `check-in` whose true branch is `[ true ]`, `check-in` needs 4 values (idx:Int, len:Int, seq:Seq Int, val:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-in`, exactly the values it takes, in this order: idx:Int, len:Int, seq:Seq Int, val:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `check-in` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-sorted
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  swap prim seq-int.empty swap 0 0 xs prim seq-int.len ys prim seq-int.len merge-loop;

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xlen ylen xs ys } {
    i xlen prim >=
    [
      j ylen prim < [ ys j prim seq-int.at result prim seq-int.push locals { r } { j 1 prim + r j ylen xs ys merge-loop } ] [ result ] if
    ]
    [
      j ylen prim >= 
      [ xs i prim seq-int.at result prim seq-int.push locals { r } { i 1 prim + r i j xlen ylen xs ys merge-loop } ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <= locals { xs-le } {
          xs-le 
          [ xs i prim seq-int.at result prim seq-int.push locals { r } { i 1 prim + r i j xlen ylen xs ys merge-loop } ]
          [ ys j prim seq-int.at result prim seq-int.push locals { r } { j 1 prim + r i j xlen ylen xs ys merge-loop } ]
          if
        }
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  merge-sorted;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: merge-sorted
at: line 3, column 36
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 10, column 136
message: In the true branch `[ ys j prim seq-int.at result prim seq-int.push ...` of the `if` in `merge-loop`, `merge-loop` needs 7 values (result:Seq Int, i:Int, j:Int, xlen:Int, ylen:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 6 values before it (the result of `prim +`, `r`, `j`, `ylen`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, j:Int, xlen:Int, ylen:Int, xs:Seq Int, ys:Seq Int. The branch already pushes the result of `prim +`, `r`, `j`, `ylen`, `xs` and `ys`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim = [ drop { 0 } ] [ prim seq-int.empty swap extract-digits ] if;

: extract-digits
  (forall ρ; ρ result:Seq Int^many num:Int^many -- ρ final:Seq Int^many)
  locals { result num } {
    num 0 prim <=
    [ result ]
    [
      num 10 prim mod result prim seq-int.push locals { new-result } {
        new-result new-result num 10 prim div extract-digits
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  digits;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: extract-digits
at: line 15, column 5
message: The two branches of the `if` in `extract-digits` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: `new-result` and the result of `extract-digits`.
hint: The false branch leaves 1 value more than the true branch: `new-result` is left below the result of `extract-digits`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: primes-up-to
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty swap 2 sieve-primes;

: sieve-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <=
    [
      candidate is-prime locals { prime } {
        prime [ result candidate prim seq-int.push locals { r } { r candidate 1 prim + n sieve-primes } ]
        [ candidate 1 prim + sieve-primes ]
        if
      }
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim < [ false ]
    [ num 2 prim = [ true ]
      [ num 2 prim mod 0 prim = [ false ] [ 2 check-divisors ] if ]
      if ]
    if
  };

: check-divisors
  (forall ρ; ρ divisor:Int^many num:Int^many -- ρ result:Bool^many)
  locals { divisor num } {
    divisor divisor prim * num prim > [ true ]
    [ num divisor prim mod 0 prim = [ false ] [ divisor 1 prim + check-divisors ] if ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  primes-up-to;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: sieve-primes
at: line 13, column 9
message: In the false branch of the `if` in `sieve-primes` whose true branch is `[ result candidate prim seq-int.push locals { r ...`, `sieve-primes` needs 3 values (result:Seq Int, candidate:Int, n:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `sieve-primes` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `sieve-primes`, exactly the values it takes, in this order: result:Seq Int, candidate:Int, n:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `sieve-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: is-prime
at: line 25, column 64
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `check-divisors` needs 2 values (divisor:Int, num:Int), but the branch has pushed only 1 value before it (`2`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `is-prime` calls `check-divisors`, which has an error of its own; this report assumes `check-divisors` keeps its stack effect.
hint: Make the branch push, just before `check-divisors`, exactly the values it takes, in this order: divisor:Int, num:Int. The branch already pushes `2`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `check-divisors` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: check-divisors
at: line 34, column 83
message: In the false branch of the `if` in `check-divisors` whose true branch is `[ false ]`, `check-divisors` needs 2 values (divisor:Int, num:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-divisors`, exactly the values it takes, in this order: divisor:Int, num:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `check-divisors` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  swap prim seq-int.empty 0 k build-counts;

: build-counts
  (forall ρ; ρ result:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx k xs } {
    idx k prim >=
    [ result ]
    [
      0 idx xs count-value-eq locals { count } {
        result count prim seq-int.push locals { new-result } {
          idx 1 prim + new-result new-result k xs build-counts
        }
      }
    ]
    if
  };

: count-value-eq
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx xs } {
    0 xs prim seq-int.len count-matches
  };

: count-matches
  (forall ρ; ρ i:Int^many len:Int^many count:Int^many idx:Int^many xs:Seq Int^many -- ρ final:Int^many)
  locals { i len count idx xs } {
    i len prim >=
    [ count ]
    [
      xs i prim seq-int.at idx prim = [ count 1 prim + ] [ count ] if locals { new-count } {
        i 1 prim + new-count new-count idx xs count-matches
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  histogram;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved
word: histogram
at: line 3, column 29
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 3
code: firth.type.branch-mismatch
word: build-counts
at: line 17, column 5
message: The two branches of the `if` in `build-counts` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `build-counts`. `build-counts` calls `count-value-eq`, which has an error of its own; this report assumes `count-value-eq` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of `build-counts`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.stack-underflow
word: count-value-eq
at: line 23, column 27
message: `count-matches` in `count-value-eq` takes 5 values (i:Int, len:Int, count:Int, idx:Int, xs:Seq Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `0` (Int) and the result of `prim seq-int.len` (Int).
hint: Push the 3 missing values before `count-matches`. The locals here, `count`, `idx` and `xs`, are not values on the stack: writing a local's name pushes its value.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  dup dup prim seq-int.len 0 insertion-sort;

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs len i } {
    i len prim >=
    [ xs ]
    [
      xs i find-insertion-pos locals { j } {
        xs i j prim seq-int.at prim seq-int.set locals { new-xs } {
          i 1 prim + new-xs len i insertion-sort
        }
      }
    ]
    if
  };

: find-insertion-pos
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ position:Int^many)
  locals { xs i } {
    i 0 prim <= [ 0 ]
    [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim > [ i ] [ i 1 prim - xs find-insertion-pos ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  sort;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.declared-effect-mismatch
word: sort
at: line 2, column 3
message: `sort` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int. `sort` calls `insertion-sort`, which has an error of its own; this report assumes `insertion-sort` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: insertion-sort
at: line 12, column 16
message: `prim seq-int.at` in `insertion-sort` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `j` (Int). `insertion-sort` calls `find-insertion-pos`, which has an error of its own; this report assumes `find-insertion-pos` keeps its stack effect.
expected: .. Seq Int Int
actual: .. Seq Int Int ?t31 Seq Int Int Int
hint: The second value from the top, `i` (Int), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 3 of 3
code: firth.type.word-input-mismatch
word: find-insertion-pos
at: line 25, column 87
message: `find-insertion-pos` in `find-insertion-pos` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t39
hint: These are the values `find-insertion-pos` takes, in another order. To push them in its order, write `xs i 1 prim -` in place of `i 1 prim - xs` on line 25. With that edit `find-insertion-pos` checks.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap start 0 0 txs prim seq-int.len apply-txs;

: apply-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected idx len start txs } {
    idx len prim >=
    [ balance rejected ]
    [
      txs idx prim seq-int.at dup balance prim + 0 prim < locals { would-go-neg } {
        would-go-neg
        [ drop rejected 1 prim + locals { new-rejected } { idx 1 prim + balance new-rejected new-rejected len start txs apply-txs } ]
        [ balance prim + rejected locals { new-balance } { idx 1 prim + new-balance new-balance new-balance len start txs apply-txs } ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  ledger;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: ledger
at: line 3, column 8
message: `start` is not a defined word, primitive or local.
actual: start
hint: `start` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: apply-txs
at: line 15, column 9
message: The two branches of the `if` in `apply-txs` whose true branch is `[ drop rejected 1 prim + locals { ...` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves 3 values, bottom to top: the result of `prim +`, the output `final-balance` of `apply-txs` and the output `final-rejected` of `apply-txs`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves 4 values, bottom to top: the result of `prim +`, the result of `prim +`, the output `final-balance` of `apply-txs` and the output `final-rejected` of `apply-txs`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of `prim +`, the output `final-balance` of `apply-txs` and the output `final-rejected` of `apply-txs`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-batch
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  swap swap swap locals { stock items qtys whole } 
  { prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len process-orders };

: process-orders
  (forall ρ; ρ stock-left:Seq Int^many alloc-left:Seq Int^many reason-left:Seq Int^many idx:Int^many len:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-alloc:Seq Int^many final-reason:Seq Int^many)
  idx len prim >=
  [ stock-left alloc-left reason-left ]
  [ items idx prim seq-int.at dup stock swap prim seq-int.at locals { item r qty whole-flag } 
    { qtys idx prim seq-int.at dup r prim <= 
      [ r prim - stock-left prim seq-int.push alloc-left qty prim seq-int.push reason-left 0 prim seq-int.push ]
      [ r 0 prim = 
        [ 0 alloc-left prim seq-int.push reason-left 2 prim seq-int.push ]
        [ whole-flag [ 0 alloc-left prim seq-int.push reason-left 3 prim seq-int.push ]
          [ r stock-left prim seq-int.push alloc-left r prim seq-int.push reason-left 1 prim seq-int.push ]
          if ]
        if ]
      if
    idx 1 prim + process-orders ] ]
  if;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  allocate-batch;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 20, column 33
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
